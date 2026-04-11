TC5Mechanic = TC5Mechanic or {}
TC5Mechanic.Server = TC5Mechanic.Server or {}
TC5Mechanic.Server.History = TC5Mechanic.Server.History or {}
TC5Mechanic.Server.PendingRepairs = TC5Mechanic.Server.PendingRepairs or {}
TC5Mechanic.Server.PlayerViewCache = TC5Mechanic.Server.PlayerViewCache or {}

local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = 'Mechanic',
        message = message,
        type = notifyType or 'info'
    })
end

local function getPlayerJob(src)
    local ok, result = pcall(function()
        return exports['tc5_jobs']:GetPlayerJob(src)
    end)
    if not ok then return nil end
    return result
end

local function getInventory(src)
    local ok, result = pcall(function()
        return exports['tc5_inventory']:GetInventory(src)
    end)
    if not ok then return nil end
    return result
end

local function addItem(src, item, amount)
    local ok, result = pcall(function()
        return exports['tc5_inventory']:AddItem(src, item, amount)
    end)
    return ok, result
end

local function removeItem(src, item, amount)
    local ok, result = pcall(function()
        return exports['tc5_inventory']:RemoveItem(src, item, amount)
    end)
    return ok, result
end

local function hasItems(src, requirements)
    local inventory = getInventory(src)
    if not inventory or not inventory.items then
        return false
    end

    local counts = {}
    for _, item in pairs(inventory.items) do
        if item and item.name then
            counts[item.name] = (counts[item.name] or 0) + (tonumber(item.amount) or 0)
        end
    end

    for itemName, amount in pairs(requirements or {}) do
        if (counts[itemName] or 0) < (tonumber(amount) or 0) then
            return false, itemName
        end
    end

    return true
end

local function buildRequirementList(requirements)
    local rows = {}
    for itemName, amount in pairs(requirements or {}) do
        rows[#rows + 1] = { item = itemName, amount = amount }
    end
    table.sort(rows, function(a, b) return a.item < b.item end)
    return rows
end

local function getPlayerShop(src)
    local job = getPlayerJob(src)
    if not job or not job.name then return nil, nil, nil end
    local shopKey, shop = TC5Mechanic.GetShopByJob(job.name)
    return job, shopKey, shop
end

local function ensureMechanic(src, requireDuty)
    local job, shopKey, shop = getPlayerShop(src)
    if not job or not shop then
        return nil, nil, nil, 'not_mechanic'
    end
    if requireDuty and TC5Mechanic.Config.RequireDuty and job.onduty ~= true then
        return nil, nil, nil, 'off_duty'
    end
    return job, shopKey, shop
end

local function isNearShopLocation(src, shop, pointName, maxDistance)
    local ped = GetPlayerPed(src)
    if ped == 0 or not DoesEntityExist(ped) then return false end
    local coords = GetEntityCoords(ped)
    local target = shop and shop.locations and shop.locations[pointName]
    if not target then return false end
    return #(coords - target) <= (maxDistance or 3.0)
end

local function repairHistoryForPlate(plate)
    plate = tostring(plate or ''):upper()
    TC5Mechanic.Server.History[plate] = TC5Mechanic.Server.History[plate] or {}
    return TC5Mechanic.Server.History[plate]
end

local function buildBossRoster(shop)
    local roster = {}
    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        local playerName = GetPlayerName(playerId) or ('ID %s'):format(playerId)
        local targetJob = getPlayerJob(playerId)
        if targetJob and tostring(targetJob.name or '') == tostring(shop.job) then
            roster[#roster + 1] = {
                id = playerId,
                name = playerName,
                grade = tonumber(targetJob.grade) or 0,
                gradeLabel = targetJob.gradeLabel or tostring(targetJob.grade or 0),
                onduty = targetJob.onduty == true
            }
        end
    end
    table.sort(roster, function(a, b) return a.grade > b.grade end)
    return roster
end

local function openMenu(src, menuType)
    local job, shopKey, shop, err = ensureMechanic(src, menuType ~= 'boss')
    if not job or not shop then
        notify(src, err == 'off_duty' and 'You must be on duty.' or 'Mechanic access denied.', 'error')
        return
    end

    local payload = {
        menu = menuType,
        shopKey = shopKey,
        shopLabel = shop.label,
        accent = shop.accent or '#d63b3b',
        dutyRequired = TC5Mechanic.Config.RequireDuty,
        job = {
            name = job.name,
            grade = tonumber(job.grade) or 0,
            gradeLabel = job.gradeLabel or tostring(job.grade or 0),
            onduty = job.onduty == true
        }
    }

    if menuType == 'crafting' then
        if not isNearShopLocation(src, shop, 'crafting', 5.0) then
            notify(src, 'You must be at your crafting bench.', 'error')
            return
        end
        local recipes = {}
        for recipeId, recipe in pairs(TC5Mechanic.GetShopRecipes(shop)) do
            recipes[#recipes + 1] = {
                id = recipeId,
                label = recipe.label or recipeId,
                item = recipe.item or recipeId,
                amount = recipe.amount or 1,
                time = recipe.craftTime or 5000,
                materials = buildRequirementList(recipe.materials)
            }
        end
        table.sort(recipes, function(a, b) return a.label < b.label end)
        payload.recipes = recipes
    elseif menuType == 'repair' then
        if not isNearShopLocation(src, shop, 'repair', 6.0) then
            notify(src, 'You must be at a repair bay.', 'error')
            return
        end
        local repairs = {}
        for repairId, repair in pairs(TC5Mechanic.GetShopRepairs(shop)) do
            repairs[#repairs + 1] = {
                id = repairId,
                label = repair.label or repairId,
                item = repair.item,
                time = repair.time or 5000,
                minGrade = repair.minGrade or 0
            }
        end
        table.sort(repairs, function(a, b) return a.minGrade < b.minGrade end)
        payload.repairs = repairs
        payload.vehicle = TC5Mechanic.Server.PlayerViewCache[src] or nil
    elseif menuType == 'shop' then
        if not isNearShopLocation(src, shop, 'shop', 5.0) then
            notify(src, 'You must be at the mechanic shop counter.', 'error')
            return
        end
        local stock = {}
        for stockId, entry in pairs(TC5Mechanic.GetShopStock(shop)) do
            stock[#stock + 1] = {
                id = stockId,
                label = entry.label or stockId,
                item = entry.item or stockId,
                amount = entry.amount or 1,
                price = entry.price or 0
            }
        end
        table.sort(stock, function(a, b) return a.label < b.label end)
        payload.stock = stock
        payload.shopPurchasingEnabled = false
        payload.shopNotice = 'Purchasing is scaffolded but not wired to your economy because no TC5 money export was included in this resource set. Add your own charge logic in server/main.lua under purchaseStock.'
    elseif menuType == 'boss' then
        if not isNearShopLocation(src, shop, 'boss', 5.0) then
            notify(src, 'You must be at the boss menu location.', 'error')
            return
        end
        if not TC5Mechanic.IsBossGrade(shop, job.grade) then
            notify(src, 'You are not allowed to manage staff.', 'error')
            return
        end
        payload.roster = buildBossRoster(shop)
        payload.commands = {
            '/mech_hire [id]',
            '/mech_fire [id]',
            '/mech_promote [id]',
            '/mech_demote [id]'
        }
    end

    TriggerClientEvent('tc5_mechanicjob:client:openMenu', src, payload)
end

CreateThread(function()
    Wait(1000)
    for shopKey, shop in pairs(TC5Mechanic.GetShops()) do
        if shop.enabled ~= false then
            local ok, err = exports['tc5_jobs']:RegisterJob({
                name = shop.job,
                label = shop.label,
                defaultDuty = false,
                grades = TC5Mechanic.GetShopGrades(shop),
                metadata = {
                    department = 'mechanic',
                    shopKey = shopKey,
                    shopLabel = shop.label
                }
            })
            if ok then
                TC5Mechanic.Debug(('Registered job %s'):format(shop.job))
            else
                TC5Mechanic.Debug(('Failed to register %s: %s'):format(shop.job, tostring(err)))
            end
        end
    end
end)

RegisterNetEvent('tc5_mechanicjob:server:toggleDuty', function()
    local src = source
    local job, _, _, err = ensureMechanic(src, false)
    if not job then
        notify(src, err == 'not_mechanic' and 'You are not employed at a mechanic shop.' or 'Unable to toggle duty.', 'error')
        return
    end
    exports['tc5_jobs']:ToggleDuty(src)
    Wait(200)
    local refreshedJob = getPlayerJob(src)
    notify(src, ('Duty is now %s.'):format(refreshedJob and refreshedJob.onduty and 'on' or 'off'), 'success')
end)

RegisterNetEvent('tc5_mechanicjob:server:openMenu', function(menuType)
    openMenu(source, tostring(menuType or ''))
end)

RegisterNetEvent('tc5_mechanicjob:server:updateVehicleContext', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    local _, _, shop = ensureMechanic(src, true)
    if not shop then return end
    TC5Mechanic.Server.PlayerViewCache[src] = payload
end)

RegisterNetEvent('tc5_mechanicjob:server:craftPart', function(recipeId)
    local src = source
    local _, _, shop, err = ensureMechanic(src, true)
    if not shop then
        notify(src, err == 'off_duty' and 'You must be on duty.' or 'Mechanic access denied.', 'error')
        return
    end
    if not isNearShopLocation(src, shop, 'crafting', 5.0) then
        notify(src, 'You must be at your shop crafting bench.', 'error')
        return
    end

    local recipes = TC5Mechanic.GetShopRecipes(shop)
    local recipe = recipes and recipes[recipeId]
    if not recipe then
        notify(src, 'Invalid recipe.', 'error')
        return
    end

    local ok, missing = hasItems(src, recipe.materials)
    if not ok then
        notify(src, ('Missing material: %s'):format(missing or 'unknown'), 'error')
        return
    end

    for itemName, amount in pairs(recipe.materials or {}) do
        removeItem(src, itemName, amount)
    end

    addItem(src, recipe.item or recipeId, recipe.amount or 1)
    notify(src, ('Crafted %s x%s'):format(recipe.label or recipeId, recipe.amount or 1), 'success')
end)

RegisterNetEvent('tc5_mechanicjob:server:startRepair', function(data)
    local src = source
    data = type(data) == 'table' and data or {}

    local job, _, shop, err = ensureMechanic(src, true)
    if not job or not shop then
        notify(src, err == 'off_duty' and 'You must be on duty.' or 'Mechanic access denied.', 'error')
        return
    end
    if not isNearShopLocation(src, shop, 'repair', 8.0) then
        notify(src, 'You must be at your repair bay.', 'error')
        return
    end

    local repairs = TC5Mechanic.GetShopRepairs(shop)
    local repair = repairs and repairs[data.repairId]
    if not repair then
        notify(src, 'Invalid repair type.', 'error')
        return
    end

    if (tonumber(job.grade) or 0) < (tonumber(repair.minGrade) or 0) then
        notify(src, 'Your grade is too low for that repair.', 'error')
        return
    end

    local ok, missing = hasItems(src, { [repair.item] = 1 })
    if not ok then
        notify(src, ('Missing required item: %s'):format(missing or repair.item), 'error')
        return
    end

    local key = ('%s:%s:%s'):format(src, tostring(data.netId), tostring(data.repairId))
    TC5Mechanic.Server.PendingRepairs[key] = {
        src = src,
        repairId = data.repairId,
        netId = tonumber(data.netId) or 0,
        plate = tostring(data.plate or ''),
        label = repair.label,
        item = repair.item,
        time = repair.time or 5000,
        mechanic = GetPlayerName(src),
        shopLabel = shop.label,
        damageSnapshot = data.damage or {}
    }

    TriggerClientEvent('tc5_mechanicjob:client:repairApproved', src, {
        repairId = data.repairId,
        netId = tonumber(data.netId) or 0,
        plate = tostring(data.plate or ''),
        label = repair.label,
        time = repair.time or 5000
    })
end)

RegisterNetEvent('tc5_mechanicjob:server:repairComplete', function(data)
    local src = source
    data = type(data) == 'table' and data or {}
    local key = ('%s:%s:%s'):format(src, tostring(data.netId), tostring(data.repairId))
    local pending = TC5Mechanic.Server.PendingRepairs[key]
    if not pending then
        notify(src, 'Repair session not found.', 'error')
        return
    end

    removeItem(src, pending.item, 1)

    local history = repairHistoryForPlate(pending.plate)
    table.insert(history, 1, {
        label = pending.label,
        mechanic = pending.mechanic,
        shop = pending.shopLabel,
        time = os.date('%Y-%m-%d %H:%M:%S')
    })
    while #history > 10 do
        table.remove(history)
    end

    TC5Mechanic.Server.PendingRepairs[key] = nil
    notify(src, ('%s finished on %s'):format(pending.label, pending.plate), 'success')
    TriggerClientEvent('tc5_mechanicjob:client:updateHistory', src, pending.plate, history)
end)

RegisterNetEvent('tc5_mechanicjob:server:purchaseStock', function(stockId)
    local src = source
    local _, _, shop, err = ensureMechanic(src, true)
    if not shop then
        notify(src, err == 'off_duty' and 'You must be on duty.' or 'Mechanic access denied.', 'error')
        return
    end
    if not isNearShopLocation(src, shop, 'shop', 5.0) then
        notify(src, 'You must be at the mechanic shop counter.', 'error')
        return
    end

    local stock = TC5Mechanic.GetShopStock(shop)
    local entry = stock and stock[stockId]
    if not entry then
        notify(src, 'Invalid stock item.', 'error')
        return
    end

    notify(src, 'Stock purchasing is not yet wired to your economy export. Add charge logic inside server/main.lua and then remove this message.', 'error')
end)

local function bossAction(src, target, mode)
    local job, _, shop = ensureMechanic(src, false)
    if not job or not shop then
        notify(src, 'Mechanic boss access denied.', 'error')
        return
    end
    if not TC5Mechanic.IsBossGrade(shop, job.grade) then
        notify(src, 'You are not allowed to manage staff.', 'error')
        return
    end

    target = tonumber(target)
    if not target then
        notify(src, 'Invalid player id.', 'error')
        return
    end

    if mode == 'hire' then
        exports['tc5_jobs']:SetPlayerJob(target, shop.job, 0, false)
        notify(src, ('Hired player %s into %s'):format(target, shop.label), 'success')
        return
    end

    local targetJob = getPlayerJob(target)
    if not targetJob or tostring(targetJob.name or '') ~= tostring(shop.job) then
        notify(src, 'Target is not employed at your shop.', 'error')
        return
    end

    if mode == 'fire' then
        exports['tc5_jobs']:SetPlayerJob(target, 'unemployed', 0, true)
        notify(src, ('Fired player %s'):format(target), 'success')
    elseif mode == 'promote' then
        exports['tc5_jobs']:SetPlayerJob(target, shop.job, math.min((tonumber(targetJob.grade) or 0) + 1, 5), targetJob.onduty)
        notify(src, ('Promoted player %s'):format(target), 'success')
    elseif mode == 'demote' then
        exports['tc5_jobs']:SetPlayerJob(target, shop.job, math.max((tonumber(targetJob.grade) or 0) - 1, 0), targetJob.onduty)
        notify(src, ('Demoted player %s'):format(target), 'success')
    end
end

RegisterCommand('mech_hire', function(src, args) bossAction(src, args[1], 'hire') end, false)
RegisterCommand('mech_fire', function(src, args) bossAction(src, args[1], 'fire') end, false)
RegisterCommand('mech_promote', function(src, args) bossAction(src, args[1], 'promote') end, false)
RegisterCommand('mech_demote', function(src, args) bossAction(src, args[1], 'demote') end, false)

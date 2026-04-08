TC5Admin = TC5Admin or {}
TC5Admin.PendingVehicleSpawns = TC5Admin.PendingVehicleSpawns or {}
TC5Admin.AdminVehicleCatalog = TC5Admin.AdminVehicleCatalog or nil
TC5Admin.AdminItemCatalog = TC5Admin.AdminItemCatalog or nil

local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = 'TC5 Admin',
        message = message,
        type = notifyType or 'info'
    })
end

local function validTarget(target)
    target = tonumber(target)
    if not target then return nil end
    if GetPlayerPing(target) <= 0 then return nil end
    return target
end

local function ensurePerm(src, action)
    if not TC5Admin.HasPermission(src, action) then
        notify(src, ('No permission for %s'):format(action), 'error')
        return false
    end
    return true
end

local function getPlayerObj(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function getCharacterId(src)
    local ok, value = pcall(function()
        return exports['tc5_core']:GetCharacterId(src)
    end)
    if ok and value then return value end

    local player = getPlayerObj(src)
    if player and player.GetCharacterId then
        return player:GetCharacterId()
    end

    return nil
end

local function getCharacterName(src)
    local player = getPlayerObj(src)
    if player and player.GetCharacterName then
        return player:GetCharacterName() or GetPlayerName(src)
    end
    return GetPlayerName(src)
end

local function ensureVehicleTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_admin_spawned_vehicles (
            id INT NOT NULL AUTO_INCREMENT,
            char_id INT NULL,
            owner_name VARCHAR(100) NULL,
            plate VARCHAR(20) NOT NULL,
            model VARCHAR(60) NOT NULL,
            label VARCHAR(100) NOT NULL,
            category VARCHAR(50) NOT NULL,
            props LONGTEXT NULL,
            spawned_by INT NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY unique_plate (plate)
        )
    ]])
end

local function svgForClass(className)
    local palette = {
        sedan = '#d7d7d7',
        sports = '#ffffff',
        suv = '#efefef',
        truck = '#f3f3f3',
        van = '#f8f8f8',
        bike = '#ffffff',
        muscle = '#f1f1f1'
    }
    local color = palette[className] or '#ffffff'
    local svg

    if className == 'bike' then
        svg = ([[<svg xmlns="http://www.w3.org/2000/svg" width="480" height="240" viewBox="0 0 480 240"><rect width="480" height="240" fill="#121212"/><circle cx="125" cy="175" r="35" fill="none" stroke="%s" stroke-width="10"/><circle cx="325" cy="175" r="35" fill="none" stroke="%s" stroke-width="10"/><path d="M120 170 L185 120 L240 120 L300 170" stroke="%s" stroke-width="12" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M186 120 L155 90 M240 120 L275 85 M235 120 L210 160" stroke="%s" stroke-width="12" fill="none" stroke-linecap="round"/></svg>]]):format(color, color, color, color)
    else
        local roof = '110,120 165,85 295,85 350,120'
        local body = '70,150 115,120 365,120 410,150 395,178 90,178'
        if className == 'suv' then
            roof = '105,120 145,80 305,80 355,120'
            body = '60,150 108,120 372,120 420,150 404,182 78,182'
        elseif className == 'truck' then
            roof = '100,120 145,88 248,88 270,120'
            body = '55,150 108,120 272,120 345,120 410,150 398,182 74,182'
        elseif className == 'van' then
            roof = '95,120 120,92 315,92 360,120'
            body = '58,150 98,120 368,120 414,150 402,182 76,182'
        elseif className == 'muscle' then
            roof = '120,120 175,90 285,90 338,120'
            body = '68,150 118,120 360,120 412,150 395,178 92,178'
        end
        svg = ([[<svg xmlns="http://www.w3.org/2000/svg" width="480" height="240" viewBox="0 0 480 240"><rect width="480" height="240" fill="#121212"/><polygon points="%s" fill="%s"/><polygon points="%s" fill="%s"/><circle cx="140" cy="178" r="28" fill="#0f0f0f" stroke="#8f1212" stroke-width="10"/><circle cx="340" cy="178" r="28" fill="#0f0f0f" stroke="#8f1212" stroke-width="10"/><rect x="185" y="98" width="105" height="18" fill="#8f1212" opacity="0.6" rx="6"/></svg>]]):format(roof, color, body, color)
    end

    return ('data:image/svg+xml;utf8,%s'):format(svg:gsub('#', '%%23'):gsub('"', '\''))
end

local function getVehicleCatalog()
    if TC5Admin.AdminVehicleCatalog then
        return TC5Admin.AdminVehicleCatalog
    end

    local vehicles = {}
    for _, vehicle in ipairs(TC5Admin.Config.VehicleSpawner.Vehicles or {}) do
        vehicles[#vehicles + 1] = {
            model = tostring(vehicle.model),
            label = tostring(vehicle.label or vehicle.model),
            brand = tostring(vehicle.brand or 'Unknown'),
            category = tostring(vehicle.category or 'misc'),
            class = tostring(vehicle.class or 'sedan'),
            image = tostring(vehicle.image or svgForClass(vehicle.class))
        }
    end

    table.sort(vehicles, function(a, b)
        if a.category == b.category then
            return a.label < b.label
        end
        return a.category < b.category
    end)

    TC5Admin.AdminVehicleCatalog = vehicles
    return vehicles
end

local function getItemCatalog()
    if TC5Admin.AdminItemCatalog then
        return TC5Admin.AdminItemCatalog
    end

    local items = {}
    local externalCatalog = nil

    local exportAttempts = {
        function() return exports['tc5_inventory']:GetItemCatalog() end,
        function() return exports['tc5_inventory']:GetItems() end,
        function() return exports['tc5_inventory']:GetItemDefinitions() end,
        function() return exports['tc5_inventory']:GetSharedItems() end,
        function() return exports['tc5_inventory']:GetItemList() end
    }

    for _, attempt in ipairs(exportAttempts) do
        local ok, result = pcall(attempt)
        if ok and type(result) == 'table' and next(result) ~= nil then
            externalCatalog = result
            break
        end
    end

    local source = externalCatalog or _G.TC5Items or {}

    for itemName, def in pairs(source) do
        if type(def) == 'table' then
            items[#items + 1] = {
                name = tostring(itemName),
                label = tostring(def.label or itemName),
                description = tostring(def.description or ''),
                image = tostring(def.image or 'default.png'),
                weight = tonumber(def.weight) or 0,
                stack = def.stack == true
            }
        end
    end

    table.sort(items, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    TC5Admin.AdminItemCatalog = items
    return items
end

local function getCatalogEntry(modelName)
    modelName = tostring(modelName or ''):lower()
    for _, vehicle in ipairs(getVehicleCatalog()) do
        if vehicle.model == modelName then
            return vehicle
        end
    end
    return nil
end

local function randomAlphaNum(length)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local out = {}
    for i = 1, length do
        local index = math.random(1, #chars)
        out[i] = chars:sub(index, index)
    end
    return table.concat(out)
end

local function generatePlate()
    local attempts = 0
    while attempts < 20 do
        attempts = attempts + 1
        local plate = ('ADM%s'):format(randomAlphaNum(4))
        local row = MySQL.single.await('SELECT id FROM tc5_admin_spawned_vehicles WHERE plate = ? LIMIT 1', { plate })
        if not row then
            return plate
        end
    end
    return ('ADM%s'):format(os.time() % 100000)
end

local function tryGrantPermanentKeys(src, plate)
    if not TC5Admin.Config.VehicleSpawner.UsePermanentKeys then
        return false, 'disabled'
    end

    local attempts = {
        function() return exports['tc5_vehiclekeys']:GrantPermanentAccess(src, plate) end,
        function() return exports['tc5_vehiclekeys']:GiveKeys(src, plate) end,
        function() return exports['tc5_vehiclekeys']:SetOwner(src, plate) end
    }

    for _, attempt in ipairs(attempts) do
        local ok, a, b = pcall(attempt)
        if ok then
            if a == nil then
                return true, nil
            end
            if a == true then
                return true, b
            end
        end
    end

    return false, 'No supported permanent keys export found.'
end

local function tryGrantKeys(src, plate)
    local ok, msg = tryGrantPermanentKeys(src, plate)
    if ok then
        return true, 'permanent'
    end

    local mins = tonumber(TC5Admin.Config.VehicleSpawner.FallbackToTempKeysMinutes or 0) or 0
    if mins > 0 then
        local tempOk = pcall(function()
            return exports['tc5_vehiclekeys']:GrantTempAccess(src, plate, mins)
        end)
        if tempOk then
            return true, 'temporary'
        end
    end

    return false, msg
end

local function maybeSaveOwnedVehicle(charId, plate, propsJson)
    if not TC5Admin.Config.VehicleSpawner.SaveToOwnedVehicles then
        return true
    end
    if not charId then
        return false, 'character_missing'
    end

    local q = tostring(TC5Admin.Config.VehicleSpawner.OwnedVehiclesInsertQuery or '')
    if q == '' then
        return false, 'owned_vehicle_query_missing'
    end

    local ok, err = pcall(function()
        MySQL.insert.await(q, {
            charId,
            plate,
            propsJson,
            1,
            tostring(TC5Admin.Config.VehicleSpawner.DefaultGarage or 'admin_lot')
        })
    end)

    if not ok then
        return false, err
    end

    return true
end

local function getJobCatalog()
    local jobs = {}
    local defs = exports['tc5_jobs']:GetJobs() or {}

    for jobName, def in pairs(defs) do
        local grades = {}
        if def.grades then
            for grade, gradeData in pairs(def.grades) do
                grades[#grades + 1] = {
                    grade = tonumber(grade) or 0,
                    label = tostring((gradeData and gradeData.label) or ('Grade %s'):format(tostring(grade)))
                }
            end
            table.sort(grades, function(a, b)
                return a.grade < b.grade
            end)
        end

        jobs[#jobs + 1] = {
            name = tostring(def.name or jobName),
            label = tostring(def.label or def.name or jobName),
            grades = grades
        }
    end

    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)

    return jobs
end

TC5Admin.GetJobCatalog = getJobCatalog
TC5Admin.GetVehicleCatalog = getVehicleCatalog
TC5Admin.GetItemCatalog = getItemCatalog

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    math.randomseed(os.time())
    ensureVehicleTable()
    TC5Admin.AdminVehicleCatalog = nil
    TC5Admin.AdminItemCatalog = nil
end)

RegisterNetEvent('tc5_admintools:server:goto', function(target)
    local src = source
    if not ensurePerm(src, 'goto') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:gotoPlayer', src, target)
    TC5Admin.Log(src, 'GOTO', ('To %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:bring', function(target)
    local src = source
    if not ensurePerm(src, 'bring') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:bringPlayer', target, src)
    TC5Admin.Log(src, 'BRING', ('Brought %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:freeze', function(target, state)
    local src = source
    if not ensurePerm(src, state and 'freeze' or 'unfreeze') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:setFrozen', target, state == true)
    TC5Admin.Log(src, state and 'FREEZE' or 'UNFREEZE', ('Target %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:heal', function(target)
    local src = source
    if not ensurePerm(src, 'heal') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:heal', target)
    TC5Admin.Log(src, 'HEAL', ('Target %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:revive', function(target)
    local src = source
    if not ensurePerm(src, 'revive') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:revive', target)
    TC5Admin.Log(src, 'REVIVE', ('Target %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:kill', function(target)
    local src = source
    if not ensurePerm(src, 'kill') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:kill', target)
    TC5Admin.Log(src, 'KILL', ('Target %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:kick', function(target, reason)
    local src = source
    if not ensurePerm(src, 'kick') then return end
    target = validTarget(target)
    if not target then return end
    reason = tostring(reason or 'Kicked by staff')
    TC5Admin.Log(src, 'KICK', ('Target %s Reason: %s'):format(target, reason))
    DropPlayer(target, reason)
end)

RegisterNetEvent('tc5_admintools:server:spectate', function(target)
    local src = source
    if not ensurePerm(src, 'spectate') then return end
    target = validTarget(target)
    if not target then return end
    TriggerClientEvent('tc5_admintools:client:startSpectate', src, target)
    TC5Admin.Log(src, 'SPECTATE', ('Target %s'):format(target))
end)

RegisterNetEvent('tc5_admintools:server:stopSpectate', function()
    local src = source
    if not ensurePerm(src, 'spectate') then return end
    TriggerClientEvent('tc5_admintools:client:stopSpectate', src)
    TC5Admin.Log(src, 'STOP_SPECTATE', 'Stopped spectating')
end)

RegisterNetEvent('tc5_admintools:server:toggleNoclip', function()
    local src = source
    if not ensurePerm(src, 'noclip') then return end
    TriggerClientEvent('tc5_admintools:client:toggleNoclip', src)
    TC5Admin.Log(src, 'TOGGLE_NOCLIP', 'Toggled noclip')
end)

RegisterNetEvent('tc5_admintools:server:toggleGodmode', function()
    local src = source
    if not ensurePerm(src, 'godmode') then return end
    TriggerClientEvent('tc5_admintools:client:toggleGodmode', src)
    TC5Admin.Log(src, 'TOGGLE_GODMODE', 'Toggled godmode')
end)

RegisterNetEvent('tc5_admintools:server:toggleDevMode', function()
    local src = source
    if not ensurePerm(src, 'devmode') then return end

    TC5Admin.DevStates = TC5Admin.DevStates or {}
    TC5Admin.DevStates[src] = not TC5Admin.DevStates[src]

    TriggerClientEvent('tc5_admintools:client:setDevMode', src, TC5Admin.DevStates[src])
    TC5Admin.Log(src, 'TOGGLE_DEVMODE', TC5Admin.DevStates[src] and 'Enabled dev mode' or 'Disabled dev mode')
end)

RegisterNetEvent('tc5_admintools:server:spawnVehicle', function(model)
    local src = source
    if not ensurePerm(src, 'spawnVehicle') then return end
    TriggerClientEvent('tc5_admintools:client:spawnVehicle', src, tostring(model or 'adder'))
    TC5Admin.Log(src, 'SPAWN_VEHICLE', tostring(model or 'adder'))
end)

RegisterNetEvent('tc5_admintools:server:spawnRegisteredVehicle', function(modelName)
    local src = source
    if not ensurePerm(src, 'spawnRegisteredVehicle') then return end

    modelName = tostring(modelName or ''):lower()
    local entry = getCatalogEntry(modelName)
    if not entry then
        notify(src, 'That vehicle is not in the admin catalog.', 'error')
        return
    end

    local plate = generatePlate()
    local requestId = ('%s:%s:%s'):format(src, os.time(), math.random(1000, 9999))
    TC5Admin.PendingVehicleSpawns[requestId] = {
        src = src,
        plate = plate,
        model = entry.model,
        label = entry.label,
        category = entry.category,
        brand = entry.brand,
        createdAt = os.time()
    }

    TriggerClientEvent('tc5_admintools:client:spawnRegisteredVehicle', src, {
        requestId = requestId,
        plate = plate,
        model = entry.model,
        label = entry.label,
        category = entry.category,
        brand = entry.brand
    })
end)

RegisterNetEvent('tc5_admintools:server:vehicleSpawnedRecord', function(requestId, success, props)
    local src = source
    local pending = TC5Admin.PendingVehicleSpawns[tostring(requestId or '')]
    if not pending or pending.src ~= src then
        return
    end
    TC5Admin.PendingVehicleSpawns[tostring(requestId or '')] = nil

    if success ~= true then
        notify(src, 'Registered vehicle spawn failed.', 'error')
        return
    end

    local charId = getCharacterId(src)
    local ownerName = getCharacterName(src)
    local propsJson = json.encode(props or {})

    if TC5Admin.Config.VehicleSpawner.SaveToAdminTable then
        MySQL.insert.await([[INSERT INTO tc5_admin_spawned_vehicles (char_id, owner_name, plate, model, label, category, props, spawned_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)]], {
            charId,
            ownerName,
            pending.plate,
            pending.model,
            pending.label,
            pending.category,
            propsJson,
            src
        })
    end

    local ownedOk, ownedErr = maybeSaveOwnedVehicle(charId, pending.plate, propsJson)
    if not ownedOk then
        notify(src, ('Vehicle spawned but not written to owned table: %s'):format(tostring(ownedErr)), 'warning')
    end

    local keyOk, keyModeOrMsg = tryGrantKeys(src, pending.plate)
    if not keyOk then
        notify(src, ('Vehicle spawned, but key handout failed: %s'):format(tostring(keyModeOrMsg)), 'warning')
    end

    notify(src, ('Spawned %s [%s] and registered it%s.'):format(pending.label, pending.plate, keyOk and (' with ' .. tostring(keyModeOrMsg) .. ' keys') or ''), 'success')
    TC5Admin.Log(src, 'SPAWN_REGISTERED_VEHICLE', ('Model %s Plate %s Category %s'):format(pending.model, pending.plate, pending.category))
end)

RegisterNetEvent('tc5_admintools:server:deleteVehicle', function()
    local src = source
    if not ensurePerm(src, 'deleteVehicle') then return end
    TriggerClientEvent('tc5_admintools:client:deleteVehicle', src)
    TC5Admin.Log(src, 'DELETE_VEHICLE', 'Deleted vehicle')
end)

RegisterNetEvent('tc5_admintools:server:fixVehicle', function()
    local src = source
    if not ensurePerm(src, 'fixVehicle') then return end
    TriggerClientEvent('tc5_admintools:client:fixVehicle', src)
    TC5Admin.Log(src, 'FIX_VEHICLE', 'Fixed vehicle')
end)

RegisterNetEvent('tc5_admintools:server:cleanVehicle', function()
    local src = source
    if not ensurePerm(src, 'cleanVehicle') then return end
    TriggerClientEvent('tc5_admintools:client:cleanVehicle', src)
    TC5Admin.Log(src, 'CLEAN_VEHICLE', 'Cleaned vehicle')
end)

RegisterNetEvent('tc5_admintools:server:giveKeys', function(plate)
    local src = source
    if not ensurePerm(src, 'giveKeys') then return end

    plate = tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if plate == '' then
        notify(src, 'No nearby vehicle found.', 'error')
        return
    end

    local ok = pcall(function()
        return exports['tc5_vehiclekeys']:GrantTempAccess(src, plate, TC5Admin.Config.GiveKeysMinutes or 60)
    end)
    if not ok then
        notify(src, 'Failed to give keys.', 'error')
        return
    end

    notify(src, ('Temporary keys granted for %s.'):format(plate), 'success')
    TC5Admin.Log(src, 'GIVE_KEYS', ('Plate %s Minutes %s'):format(plate, tostring(TC5Admin.Config.GiveKeysMinutes or 60)))
end)

RegisterNetEvent('tc5_admintools:server:setCash', function(target, amount)
    local src = source
    if not ensurePerm(src, 'setCash') then return end
    target = validTarget(target)
    amount = tonumber(amount)
    if not target or not amount then return end
    local player = getPlayerObj(target)
    if not player or not player.GetCash or not player.RemoveCash or not player.AddCash then return end
    local current = player:GetCash()
    if current > amount then
        player:RemoveCash(current - amount)
    elseif amount > current then
        player:AddCash(amount - current)
    end
    if player.SaveCharacter then player:SaveCharacter() end
    TC5Admin.Log(src, 'SET_CASH', ('Target %s Amount %s'):format(target, amount))
end)

RegisterNetEvent('tc5_admintools:server:addCash', function(target, amount)
    local src = source
    if not ensurePerm(src, 'addCash') then return end
    target = validTarget(target)
    amount = tonumber(amount)
    if not target or not amount then return end
    local player = getPlayerObj(target)
    if not player or not player.AddCash then return end
    player:AddCash(amount)
    if player.SaveCharacter then player:SaveCharacter() end
    TC5Admin.Log(src, 'ADD_CASH', ('Target %s Amount %s'):format(target, amount))
end)

RegisterNetEvent('tc5_admintools:server:setBank', function(target, amount)
    local src = source
    if not ensurePerm(src, 'setBank') then return end
    target = validTarget(target)
    amount = tonumber(amount)
    if not target or not amount then return end
    local player = getPlayerObj(target)
    if not player or not player.GetBank or not player.RemoveBank or not player.AddBank then return end
    local current = player:GetBank()
    if current > amount then
        player:RemoveBank(current - amount)
    elseif amount > current then
        player:AddBank(amount - current)
    end
    if player.SaveCharacter then player:SaveCharacter() end
    TC5Admin.Log(src, 'SET_BANK', ('Target %s Amount %s'):format(target, amount))
end)

RegisterNetEvent('tc5_admintools:server:addBank', function(target, amount)
    local src = source
    if not ensurePerm(src, 'addBank') then return end
    target = validTarget(target)
    amount = tonumber(amount)
    if not target or not amount then return end
    local player = getPlayerObj(target)
    if not player or not player.AddBank then return end
    player:AddBank(amount)
    if player.SaveCharacter then player:SaveCharacter() end
    TC5Admin.Log(src, 'ADD_BANK', ('Target %s Amount %s'):format(target, amount))
end)

RegisterNetEvent('tc5_admintools:server:giveItem', function(target, itemName, amount)
    local src = source
    if not ensurePerm(src, 'giveItem') then return end
    target = validTarget(target)
    itemName = tostring(itemName or '')
    amount = tonumber(amount) or 1
    if not target or itemName == '' or amount <= 0 then return end
    if exports['tc5_inventory'] and exports['tc5_inventory'].AddItem then
        local ok, reason = exports['tc5_inventory']:AddItem(target, itemName, amount)
        if not ok then
            notify(src, ('Failed to give item: %s'):format(tostring(reason or 'unknown')), 'error')
            return
        end
        notify(src, ('Gave %s x%s to %s.'):format(itemName, amount, target), 'success')
        TC5Admin.Log(src, 'GIVE_ITEM', ('Target %s Item %s x%s'):format(target, itemName, amount))
    end
end)

RegisterNetEvent('tc5_admintools:server:removeItem', function(target, itemName, amount)
    local src = source
    if not ensurePerm(src, 'removeItem') then return end
    target = validTarget(target)
    itemName = tostring(itemName or '')
    amount = tonumber(amount) or 1
    if not target or itemName == '' or amount <= 0 then return end

    local inventory = exports['tc5_inventory'] and exports['tc5_inventory']:GetInventory(target)
    if not inventory or not inventory.items then
        notify(src, 'Target inventory not found.', 'error')
        return
    end

    local remaining = amount
    for slot, item in pairs(inventory.items) do
        if item and item.name == itemName and remaining > 0 then
            local take = math.min(remaining, tonumber(item.amount) or 0)
            if take > 0 then
                exports['tc5_inventory']:RemoveItem(target, itemName, take, tonumber(slot))
                remaining = remaining - take
            end
        end
    end

    if remaining == amount then
        notify(src, 'Item not found in target inventory.', 'error')
        return
    end

    notify(src, ('Removed %s x%s from %s.'):format(itemName, amount - remaining, target), 'success')
    TC5Admin.Log(src, 'REMOVE_ITEM', ('Target %s Item %s x%s'):format(target, itemName, amount - remaining))
end)

RegisterNetEvent('tc5_admintools:server:setJob', function(target, jobName, grade)
    local src = source
    if not ensurePerm(src, 'manageJobs') then return end

    target = validTarget(target)
    if not target then
        notify(src, 'Player is not online.', 'error')
        return
    end

    jobName = tostring(jobName or ''):lower()
    grade = tonumber(grade) or 0

    if jobName == '' then
        notify(src, 'Choose a job first.', 'error')
        return
    end

    local def = exports['tc5_jobs']:GetJobDefinition(jobName)
    if not def then
        notify(src, ('Unknown job: %s'):format(jobName), 'error')
        return
    end

    local ok, result = exports['tc5_jobs']:SetPlayerJob(target, jobName, grade, true)
    if not ok then
        notify(src, ('Failed to set job: %s'):format(tostring(result)), 'error')
        return
    end

    notify(src, ('Set player %s to %s (%s).'):format(target, result.label, result.gradeLabel), 'success')
    TC5Admin.Log(src, 'SET_JOB', ('Target %s Job %s Grade %s'):format(target, jobName, grade))

    TriggerClientEvent('tc5_admintools:client:updateJobs', src, {
        jobs = getJobCatalog(),
        players = TC5Admin.GetPlayers()
    })
    TriggerClientEvent('tc5_admintools:client:refreshMenu', src, {
        group = TC5Admin.GetPermissionGroup(src),
        permissions = TC5Admin.Permissions[TC5Admin.GetPermissionGroup(src) or ''] or {},
        players = TC5Admin.GetPlayers(),
        reports = TC5Admin.Reports or {},
        jobs = getJobCatalog(),
        vehicleCatalog = getVehicleCatalog(),
        vehicleCategories = TC5Admin.Config.VehicleSpawner.Categories or {},
        itemCatalog = getItemCatalog()
    })
end)

exports('GetJobCatalog', function()
    return getJobCatalog()
end)

exports('GetVehicleCatalog', function()
    return getVehicleCatalog()
end)

exports('GetItemCatalog', function()
    return getItemCatalog()
end)

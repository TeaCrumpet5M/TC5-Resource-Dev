local ActiveContracts = {}
local PlayerData = {}
local LastRequestAt = {}

local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = 'Tablet',
        message = message,
        type = notifyType or 'info'
    })
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function getPlayer(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function getInventory(src)
    return exports['tc5_inventory']:GetInventory(src)
end

local function hasItem(src, itemName)
    if not itemName or itemName == '' then
        return true
    end

    local inventory = getInventory(src)
    if not inventory or not inventory.items then
        return false
    end

    for _, item in pairs(inventory.items) do
        if item and item.name == itemName and (tonumber(item.amount) or 0) > 0 then
            return true
        end
    end

    return false
end

local function getPlayerState(charId)
    PlayerData[charId] = PlayerData[charId] or {
        rep = TC5Tablet.Config.Boosting.StartingRep or 0
    }

    return PlayerData[charId]
end

local function buildApps(src)
    local apps = {}

    for appId, app in pairs(TC5Tablet.Config.Apps or {}) do
        if hasItem(src, app.usbItem) then
            apps[#apps + 1] = {
                id = appId,
                label = app.label,
                icon = app.icon,
                accent = app.accent or '#ffffff'
            }
        end
    end

    table.sort(apps, function(a, b)
        return a.label < b.label
    end)

    return apps
end

local function buildBoostingContracts(charId)
    local state = getPlayerState(charId)
    local output = {
        rep = state.rep,
        contracts = {}
    }

    for tier, info in pairs(TC5Tablet.Config.Boosting.Tiers) do
        output.contracts[#output.contracts + 1] = {
            tier = tier,
            minRep = info.minRep,
            payout = info.payout,
            vehicleCount = #info.vehicles,
            unlocked = state.rep >= info.minRep
        }
    end

    table.sort(output.contracts, function(a, b)
        return a.minRep < b.minRep
    end)

    return output
end

local function createBoostingContract(charId)
    local state = getPlayerState(charId)
    local available = {}

    for tier, info in pairs(TC5Tablet.Config.Boosting.Tiers) do
        if state.rep >= info.minRep then
            available[#available + 1] = { tier = tier, info = info }
        end
    end

    if #available == 0 then
        return nil
    end

    local selected = available[math.random(1, #available)]
    local pickup = TC5Tablet.Config.Boosting.PickupLocations[math.random(1, #TC5Tablet.Config.Boosting.PickupLocations)]
    local dropoff = TC5Tablet.Config.Boosting.DropoffLocations[math.random(1, #TC5Tablet.Config.Boosting.DropoffLocations)]
    local vehicle = selected.info.vehicles[math.random(1, #selected.info.vehicles)]

    return {
        id = ('boost_%s_%s'):format(charId, os.time()),
        tier = selected.tier,
        payout = math.random(selected.info.payout.min, selected.info.payout.max),
        vehicle = vehicle,
        vehicleLabel = vehicle:gsub('^%l', string.upper),
        pickup = {
            x = pickup.x,
            y = pickup.y,
            z = pickup.z,
            w = pickup.w
        },
        dropoff = {
            x = dropoff.x,
            y = dropoff.y,
            z = dropoff.z
        }
    }
end

RegisterNetEvent('tc5_tablet:server:openTablet', function()
    local src = source
    local charId = getCharacterId(src)
    if not charId then
        return
    end

    if not hasItem(src, TC5Tablet.Config.TabletItem) then
        notify(src, 'You need a tablet in your inventory.', 'error')
        return
    end

    TriggerClientEvent('tc5_tablet:client:openTablet', src, {
        playerName = GetPlayerName(src),
        apps = buildApps(src),
        boosting = buildBoostingContracts(charId),
        activeContract = ActiveContracts[charId]
    })
end)

RegisterNetEvent('tc5_tablet:server:requestBoostingData', function()
    local src = source
    local charId = getCharacterId(src)
    if not charId then
        return
    end

    TriggerClientEvent('tc5_tablet:client:updateBoostingData', src, {
        boosting = buildBoostingContracts(charId),
        activeContract = ActiveContracts[charId]
    })
end)

RegisterNetEvent('tc5_tablet:server:startBoostContract', function()
    local src = source
    local charId = getCharacterId(src)
    if not charId then
        return
    end

    if not hasItem(src, TC5Tablet.Config.TabletItem) then
        notify(src, 'You need a tablet in your inventory.', 'error')
        return
    end

    local app = TC5Tablet.Config.Apps.boosting
    if not app or not hasItem(src, app.usbItem) then
        notify(src, 'Boosting USB not detected.', 'error')
        return
    end

    if ActiveContracts[charId] then
        notify(src, 'You already have an active boost contract.', 'error')
        return
    end

    local now = os.time()
    if LastRequestAt[charId] and (now - LastRequestAt[charId]) < (TC5Tablet.Config.Boosting.CooldownSeconds or 15) then
        notify(src, 'System cooling down. Try again in a moment.', 'error')
        return
    end
    LastRequestAt[charId] = now

    local contract = createBoostingContract(charId)
    if not contract then
        notify(src, 'No contracts are available for your rep level yet.', 'error')
        return
    end

    ActiveContracts[charId] = contract
    TriggerClientEvent('tc5_tablet:client:boostContractStarted', src, contract)
end)

RegisterNetEvent('tc5_tablet:server:completeBoostContract', function(contractId)
    local src = source
    local charId = getCharacterId(src)
    if not charId then
        return
    end

    local contract = ActiveContracts[charId]
    if not contract or contract.id ~= contractId then
        notify(src, 'No valid contract found.', 'error')
        return
    end

    local player = getPlayer(src)
    if not player or type(player.AddCash) ~= 'function' then
        notify(src, 'Unable to reward player cash.', 'error')
        return
    end

    player:AddCash(contract.payout)
    if type(player.SaveCharacter) == 'function' then
        player:SaveCharacter()
    end

    local state = getPlayerState(charId)
    state.rep = state.rep + 1
    ActiveContracts[charId] = nil

    TriggerClientEvent('tc5_tablet:client:boostContractCompleted', src, {
        payout = contract.payout,
        rep = state.rep,
        tier = contract.tier
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    local charId = getCharacterId(src)
    if charId then
        ActiveContracts[charId] = nil
    end
end)

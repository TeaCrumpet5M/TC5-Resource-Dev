local inventoryOpen = false
local worldDrops = {}
local spawnedDropObjects = {}

local DROP_MODEL = `xm_prop_x17_bag_01a`

local function notify(data)
    if exports['tc5_ui'] and exports['tc5_ui'].Notify then
        exports['tc5_ui']:Notify(data)
    end
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    inventoryOpen = state
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function requestModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end

local function deleteDropObject(dropId)
    local obj = spawnedDropObjects[dropId]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    spawnedDropObjects[dropId] = nil
end

local function spawnDropObject(dropId, coords)
    if spawnedDropObjects[dropId] and DoesEntityExist(spawnedDropObjects[dropId]) then
        return
    end

    requestModel(DROP_MODEL)

    local obj = CreateObject(DROP_MODEL, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    spawnedDropObjects[dropId] = obj
end

local function getNearbyVehicleStorage()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 4.0, 0, 71)
    if vehicle == 0 then
        return nil
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then
        return nil
    end

    local vehCoords = GetEntityCoords(vehicle)
    local dist = #(coords - vehCoords)

    if IsPedInAnyVehicle(ped, false) then
        return {
            type = 'glovebox',
            owner = plate
        }
    end

    if dist <= 3.5 then
        return {
            type = 'trunk',
            owner = plate
        }
    end

    return nil
end

local function getNearbyNamedStash()
    if not TC5NamedStashes then
        return nil
    end

    local coords = GetEntityCoords(PlayerPedId())

    for stashId, stash in pairs(TC5NamedStashes) do
        if stash.coords and #(coords - stash.coords) <= 2.0 then
            return {
                type = 'stash',
                owner = tostring(stashId)
            }
        end
    end

    return nil
end

local function getNearbyDrop()
    local coords = GetEntityCoords(PlayerPedId())

    for dropId, drop in pairs(worldDrops) do
        local dropCoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
        if #(coords - dropCoords) <= 2.0 then
            return {
                type = 'drop',
                owner = tostring(dropId)
            }
        end
    end

    return nil
end

local function getNearbySecondaryContext()
    local drop = getNearbyDrop()
    if drop then return drop end

    local stash = getNearbyNamedStash()
    if stash then return stash end

    local vehicleStorage = getNearbyVehicleStorage()
    if vehicleStorage then return vehicleStorage end

    return nil
end

RegisterCommand(TC5Inventory.Config.OpenCommand, function()
    if inventoryOpen then
        setFocus(false)
        send('close', {})
        return
    end

    local context = getNearbySecondaryContext()
    TriggerServerEvent('tc5_inventory:server:openInventory', context)
end, false)

RegisterNetEvent('tc5_inventory:client:toggleInventory', function()
    ExecuteCommand(TC5Inventory.Config.OpenCommand)
end)

RegisterNetEvent('tc5_inventory:client:forceOpenInventory', function(data)
    TriggerServerEvent('tc5_inventory:server:openInventory', data)
end)

RegisterNetEvent('tc5_inventory:client:openInventory', function(payload)
    setFocus(true)
    send('open', payload)
end)

RegisterNetEvent('tc5_inventory:client:refreshInventory', function()
    TriggerServerEvent('tc5_inventory:server:refreshInventory')
end)

RegisterNetEvent('tc5_inventory:client:refreshInventoryData', function(payload)
    send('refreshPlayer', payload)
end)

RegisterNetEvent('tc5_inventory:client:refreshOpenInventories', function(payload)
    send('refreshOpenInventories', payload)
end)

RegisterNetEvent('tc5_inventory:client:notify', function(data)
    notify(data)
end)

RegisterNetEvent('tc5_inventory:item:water', function(item)
    notify({
        title = 'Inventory',
        message = ('You drank %s.'):format(item.label),
        type = 'success'
    })
end)

RegisterNetEvent('tc5_inventory:client:addWorldDrop', function(drop)
    if not drop or not drop.id then return end

    worldDrops[drop.id] = drop
    spawnDropObject(drop.id, drop.coords)
end)

RegisterNetEvent('tc5_inventory:client:setWorldDrops', function(drops)
    for dropId, _ in pairs(spawnedDropObjects) do
        deleteDropObject(dropId)
    end

    worldDrops = {}

    for i = 1, #drops do
        local drop = drops[i]
        worldDrops[drop.id] = drop
        spawnDropObject(drop.id, drop.coords)
    end
end)

RegisterNetEvent('tc5_inventory:client:removeWorldDrop', function(dropId)
    worldDrops[dropId] = nil
    deleteDropObject(dropId)
end)

RegisterNUICallback('close', function(_, cb)
    setFocus(false)
    send('close', {})
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('tc5_inventory:server:useItem', data.slot)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())

    TriggerServerEvent('tc5_inventory:server:dropItem', data.slot, data.amount, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    })

    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('tc5_inventory:server:moveItem', data)
    cb('ok')
end)

RegisterNUICallback('buyShopItem', function(data, cb)
    TriggerServerEvent('tc5_inventory:server:buyItem', data.shopId, data.itemName or nil, data.slot, data.amount or 1)
    cb('ok')
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('tc5_inventory:server:requestWorldDrops')

    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())

        for dropId, drop in pairs(worldDrops) do
            local dropCoords = vector3(drop.coords.x, drop.coords.y, drop.coords.z)
            local dist = #(coords - dropCoords)

            if dist < 20.0 then
                sleep = 0

                if not spawnedDropObjects[dropId] or not DoesEntityExist(spawnedDropObjects[dropId]) then
                    spawnDropObject(dropId, drop.coords)
                end

                if dist < 1.5 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to search duffle bag')
                    EndTextCommandDisplayHelp(0, false, true, 1)

                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('tc5_inventory:server:openInventory', {
                            type = 'drop',
                            owner = tostring(dropId)
                        })
                    end
                end
            else
                if spawnedDropObjects[dropId] and DoesEntityExist(spawnedDropObjects[dropId]) then
                    deleteDropObject(dropId)
                end
            end
        end

        Wait(sleep)
    end
end)
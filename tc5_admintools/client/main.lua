local menuOpen = false
local devMode = false

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    menuOpen = state
end

local function getNearestVehiclePlate()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if vehicle == 0 then
        return nil
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then
        return nil
    end

    return plate
end

local function getPlayerTransform()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading,
        vector = ('vec4(%.4f, %.4f, %.4f, %.4f)'):format(coords.x, coords.y, coords.z, heading),
        plain = ('%.4f, %.4f, %.4f, %.4f'):format(coords.x, coords.y, coords.z, heading)
    }
end

local function collectVehicleProps(vehicle)
    if not vehicle or vehicle == 0 then return {} end
    return {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        colors = { GetVehicleColours(vehicle) },
        extras = {}
    }
end

RegisterCommand('admin', function()
    TriggerServerEvent('tc5_admintools:server:requestOpen')
end, false)

RegisterKeyMapping('admin', 'Open TC5 Admin Tools', 'keyboard', TC5Admin.Config.OpenKey)

RegisterCommand(TC5Admin.Config.DevModeCommand, function()
    TriggerServerEvent('tc5_admintools:server:toggleDevMode')
end, false)

RegisterNetEvent('tc5_admintools:client:openRequest', function()
    TriggerServerEvent('tc5_admintools:server:requestOpen')
end)

RegisterNetEvent('tc5_admintools:client:openMenu', function(payload)
    setFocus(true)
    SendNUIMessage({ action = 'open', data = payload })
end)

RegisterNetEvent('tc5_admintools:client:refreshMenu', function(payload)
    SendNUIMessage({ action = 'refresh', data = payload })
end)

RegisterNetEvent('tc5_admintools:client:updateJobs', function(payload)
    SendNUIMessage({ action = 'jobs', data = payload })
end)

RegisterNetEvent('tc5_admintools:client:updateVehicleCatalog', function(payload)
    SendNUIMessage({ action = 'vehicleCatalog', data = payload })
end)

RegisterNetEvent('tc5_admintools:client:gotoPlayer', function(target)
    local targetPlayer = GetPlayerFromServerId(target)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)
    if targetPed == 0 then return end
    local coords = GetEntityCoords(targetPed)
    SetEntityCoords(PlayerPedId(), coords.x + 1.0, coords.y + 1.0, coords.z)
end)

RegisterNetEvent('tc5_admintools:client:bringPlayer', function(adminSrc)
    local adminPlayer = GetPlayerFromServerId(adminSrc)
    if adminPlayer == -1 then return end
    local adminPed = GetPlayerPed(adminPlayer)
    if adminPed == 0 then return end
    local coords = GetEntityCoords(adminPed)
    SetEntityCoords(PlayerPedId(), coords.x + 1.0, coords.y + 1.0, coords.z)
end)

RegisterNetEvent('tc5_admintools:client:setFrozen', function(state)
    FreezeEntityPosition(PlayerPedId(), state == true)
end)

RegisterNetEvent('tc5_admintools:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

RegisterNetEvent('tc5_admintools:client:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('tc5_admintools:client:kill', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent('tc5_admintools:client:spawnVehicle', function(modelName)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = joaat(modelName)
    if not IsModelInCdimage(model) then
        exports.tc5_ui:Notify({
            title = 'TC5 Admin',
            message = ('Invalid vehicle model: %s'):format(tostring(modelName)),
            type = 'error'
        })
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local vehicle = CreateVehicle(model, coords.x + 2.0, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent('tc5_admintools:client:spawnRegisteredVehicle', function(data)
    local modelName = tostring((data and data.model) or '')
    local plate = tostring((data and data.plate) or '')
    local requestId = tostring((data and data.requestId) or '')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = joaat(modelName)

    if modelName == '' or requestId == '' then
        return
    end

    if not IsModelInCdimage(model) then
        exports.tc5_ui:Notify({
            title = 'TC5 Admin',
            message = ('Invalid vehicle model: %s'):format(modelName),
            type = 'error'
        })
        TriggerServerEvent('tc5_admintools:server:vehicleSpawnedRecord', requestId, false, nil)
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(ped), true, false)
    if vehicle == 0 then
        exports.tc5_ui:Notify({
            title = 'TC5 Admin',
            message = 'Vehicle failed to spawn.',
            type = 'error'
        })
        TriggerServerEvent('tc5_admintools:server:vehicleSpawnedRecord', requestId, false, nil)
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)

    Wait(200)
    local props = collectVehicleProps(vehicle)
    props.plate = plate
    props.label = data.label
    props.category = data.category
    props.brand = data.brand
    props.modelName = modelName

    TriggerServerEvent('tc5_admintools:server:vehicleSpawnedRecord', requestId, true, props)
end)

RegisterNetEvent('tc5_admintools:client:deleteVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if vehicle and vehicle ~= 0 then DeleteVehicle(vehicle) end
end)

RegisterNetEvent('tc5_admintools:client:fixVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
    end
end)

RegisterNetEvent('tc5_admintools:client:cleanVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and vehicle ~= 0 then SetVehicleDirtLevel(vehicle, 0.0) end
end)

RegisterNetEvent('tc5_admintools:client:setDevMode', function(state)
    devMode = state == true

    exports.tc5_ui:Notify({
        title = 'TC5 Admin',
        message = devMode and 'Dev mode enabled.' or 'Dev mode disabled.',
        type = devMode and 'success' or 'info'
    })

    if not devMode then
        SendNUIMessage({ action = 'devmode', data = { enabled = false } })
    end
end)

CreateThread(function()
    while true do
        if not devMode then
            Wait(500)
        else
            Wait(100)
            local transform = getPlayerTransform()
            transform.enabled = true
            SendNUIMessage({ action = 'devmode', data = transform })
        end
    end
end)

RegisterCommand(TC5Admin.Config.GiveKeysCommand, function()
    local plate = getNearestVehiclePlate()
    TriggerServerEvent('tc5_admintools:server:giveKeys', plate)
end, false)

RegisterNUICallback('close', function(_, cb)
    setFocus(false)
    SendNUIMessage({ action = 'close', data = {} })
    cb('ok')
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('tc5_admintools:server:requestRefresh')
    cb('ok')
end)

RegisterNUICallback('copyCoords', function(_, cb)
    local transform = getPlayerTransform()
    cb(transform)
end)

RegisterNUICallback('action', function(data, cb)
    local action = data.action
    local target = data.target
    local input = data.input
    local amount = data.amount

    if action == 'goto' then
        TriggerServerEvent('tc5_admintools:server:goto', target)
    elseif action == 'bring' then
        TriggerServerEvent('tc5_admintools:server:bring', target)
    elseif action == 'freeze' then
        TriggerServerEvent('tc5_admintools:server:freeze', target, true)
    elseif action == 'unfreeze' then
        TriggerServerEvent('tc5_admintools:server:freeze', target, false)
    elseif action == 'heal' then
        TriggerServerEvent('tc5_admintools:server:heal', target)
    elseif action == 'revive' then
        TriggerServerEvent('tc5_admintools:server:revive', target)
    elseif action == 'kill' then
        TriggerServerEvent('tc5_admintools:server:kill', target)
    elseif action == 'kick' then
        TriggerServerEvent('tc5_admintools:server:kick', target, input)
    elseif action == 'spectate' then
        TriggerServerEvent('tc5_admintools:server:spectate', target)
    elseif action == 'stopspectate' then
        TriggerServerEvent('tc5_admintools:server:stopSpectate')
    elseif action == 'togglenoclip' then
        TriggerServerEvent('tc5_admintools:server:toggleNoclip')
    elseif action == 'togglegodmode' then
        TriggerServerEvent('tc5_admintools:server:toggleGodmode')
    elseif action == 'spawnvehicle' then
        TriggerServerEvent('tc5_admintools:server:spawnVehicle', input)
    elseif action == 'spawnregisteredvehicle' then
        TriggerServerEvent('tc5_admintools:server:spawnRegisteredVehicle', data.model)
    elseif action == 'deletevehicle' then
        TriggerServerEvent('tc5_admintools:server:deleteVehicle')
    elseif action == 'fixvehicle' then
        TriggerServerEvent('tc5_admintools:server:fixVehicle')
    elseif action == 'cleanvehicle' then
        TriggerServerEvent('tc5_admintools:server:cleanVehicle')
    elseif action == 'givekeys' then
        local plate = getNearestVehiclePlate()
        TriggerServerEvent('tc5_admintools:server:giveKeys', plate)
    elseif action == 'setcash' then
        TriggerServerEvent('tc5_admintools:server:setCash', target, amount)
    elseif action == 'addcash' then
        TriggerServerEvent('tc5_admintools:server:addCash', target, amount)
    elseif action == 'setbank' then
        TriggerServerEvent('tc5_admintools:server:setBank', target, amount)
    elseif action == 'addbank' then
        TriggerServerEvent('tc5_admintools:server:addBank', target, amount)
    elseif action == 'giveitem' then
        TriggerServerEvent('tc5_admintools:server:giveItem', target, input, amount)
    elseif action == 'removeitem' then
        TriggerServerEvent('tc5_admintools:server:removeItem', target, input, amount)
    elseif action == 'closereport' then
        TriggerServerEvent('tc5_admintools:server:closeReport', target)
    elseif action == 'createreport' then
        TriggerServerEvent('tc5_admintools:server:createReport', input)
    elseif action == 'setjob' then
        TriggerServerEvent('tc5_admintools:server:setJob', target, data.jobName, data.grade)
    elseif action == 'toggledevmode' then
        TriggerServerEvent('tc5_admintools:server:toggleDevMode')
    end
    cb('ok')
end)

TC5Police = TC5Police or {}
TC5Police.Client = TC5Police.Client or {
    payload = nil,
    panelOpen = false,
    spawnedVehicles = {}
}

local function notify(title, message, kind, duration)
    if GetResourceState('tc5_ui') == 'started' then
        exports.tc5_ui:Notify({
            title = title,
            message = message,
            type = kind or 'info',
            duration = duration or 3500
        })
    else
        print(('[tc5_policejob] %s: %s'):format(title, message))
    end
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function getState()
    local payload = TC5Police.Client.payload or {}
    payload.officer = payload.officer or nil
    payload.armory = payload.armory or TC5Police.Config.Armory
    payload.garage = payload.garage or TC5Police.Config.Garage
    payload.stations = payload.stations or TC5Police.Config.Stations
    payload.theme = payload.theme or TC5Police.Config.Theme
    return payload
end

local function setPanel(state)
    TC5Police.Client.panelOpen = state == true
    SetNuiFocus(TC5Police.Client.panelOpen, TC5Police.Client.panelOpen)
    SetNuiFocusKeepInput(false)
    if TC5Police.Client.panelOpen then
        send('open', getState())
    else
        send('close', {})
    end
end

local function isPolice()
    local payload = getState()
    return payload.isPolice == true
end

local function isOnDuty()
    local payload = getState()
    return payload.isOnDuty == true
end

local function getDistanceTo(vec)
    return #(GetEntityCoords(PlayerPedId()) - vec)
end

local function canUsePoint(key, maxDistance)
    for _, station in pairs(TC5Police.Config.Stations or {}) do
        if station[key] and getDistanceTo(station[key]) <= maxDistance then
            return true, station
        end
    end
    return false, nil
end

local function openPanel(tab)
    if not isPolice() then
        notify('Police', 'You are not police.', 'error')
        return
    end

    TriggerServerEvent('tc5_policejob:server:getPanelData')
    Wait(100)
    local payload = getState()
    payload.activeTab = tab or 'home'
    send('open', payload)
    SetNuiFocus(true, true)
    TC5Police.Client.panelOpen = true
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function registerSuggestions()
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.OpenPanel), 'Open the police panel')
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.ToggleDuty), 'Toggle police duty')
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.ReturnVehicle), 'Store the current police vehicle')
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.Recruit), 'Hire a police officer', {
        { name = 'id', help = 'Player server ID' },
        { name = 'badge', help = 'Badge number' },
        { name = 'callsign', help = 'Officer callsign' }
    })
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.SetGrade), 'Set police grade', {
        { name = 'id', help = 'Player server ID' },
        { name = 'grade', help = 'Police grade' }
    })
    TriggerEvent('chat:addSuggestion', ('/%s'):format(TC5Police.Config.Commands.Fire), 'Remove a police officer', {
        { name = 'id', help = 'Player server ID' }
    })
end

RegisterNetEvent('tc5_policejob:client:syncOfficer', function(payload)
    TC5Police.Client.payload = payload or {}
    if TC5Police.Client.panelOpen then
        send('sync', getState())
    end
end)

RegisterNetEvent('tc5_core:client:userLoaded', function()
    TriggerServerEvent('tc5_policejob:server:requestInit')
end)

RegisterNetEvent('tc5_jobs:client:jobUpdated', function()
    TriggerServerEvent('tc5_policejob:server:requestInit')
end)

RegisterNetEvent('tc5_policejob:client:applyLoadout', function(loadout, label)
    local ped = PlayerPedId()
    for _, item in ipairs(loadout or {}) do
        if item.type == 'weapon' and item.name then
            GiveWeaponToPed(ped, joaat(item.name), tonumber(item.ammo or 0) or 0, false, false)
        end
    end

    notify('Armory', ('Issued %s.'):format(label or 'duty kit'), 'success')
end)

RegisterNetEvent('tc5_policejob:client:spawnVehicle', function(vehicleData)
    local ok, station = canUsePoint('garageMenu', 20.0)
    if not ok or not station or not station.garageSpawn then
        notify('Garage', 'You are not near a police garage.', 'error')
        return
    end

    local model = joaat(vehicleData.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local spawn = station.garageSpawn
    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNumberPlateText(vehicle, ('PD%s'):format(math.random(111, 999)))
    if TC5Police.Config.Garage.Livery and TC5Police.Config.Garage.Livery >= 0 then
        SetVehicleLivery(vehicle, TC5Police.Config.Garage.Livery)
    end
    for _, extraId in ipairs(TC5Police.Config.Garage.Extras or {}) do
        if DoesExtraExist(vehicle, extraId) then
            SetVehicleExtra(vehicle, extraId, 0)
        end
    end
    if TC5Police.Config.Garage.WarpIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TC5Police.Client.spawnedVehicles[netId] = true
    SetModelAsNoLongerNeeded(model)
    notify('Garage', ('%s deployed.'):format(vehicleData.label or 'Police vehicle'), 'success')
end)

RegisterCommand(TC5Police.Config.Commands.OpenPanel, function()
    openPanel('home')
end, false)

RegisterCommand(TC5Police.Config.Commands.ToggleDuty, function()
    if not isPolice() then
        notify('Police', 'You are not police.', 'error')
        return
    end
    TriggerServerEvent('tc5_policejob:server:toggleDuty')
end, false)

RegisterCommand(TC5Police.Config.Commands.ReturnVehicle, function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        local coords = GetEntityCoords(PlayerPedId())
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    end

    if vehicle == 0 then
        notify('Garage', 'No vehicle nearby to store.', 'warning')
        return
    end

    TriggerServerEvent('tc5_policejob:server:returnVehicle', NetworkGetNetworkIdFromEntity(vehicle))
end, false)

CreateThread(function()
    Wait(1000)
    registerSuggestions()
    TriggerServerEvent('tc5_policejob:server:requestInit')

    if TC5Police.Config.UseTC5Eye and GetResourceState('tc5_eye') == 'started' then
        for stationId, station in pairs(TC5Police.Config.Stations or {}) do
            if station.duty then
                exports.tc5_eye:AddBoxZone({
                    id = ('tc5_policejob_duty_%s'):format(stationId),
                    coords = station.duty,
                    radius = 2.0,
                    options = {
                        {
                            id = ('tc5_policejob_duty_opt_%s'):format(stationId),
                            label = 'Toggle Duty',
                            icon = '🛡️',
                            event = 'tc5_policejob:client:toggleDutyEye',
                            canInteract = function() return isPolice() end
                        }
                    }
                })
            end

            if station.armory then
                exports.tc5_eye:AddBoxZone({
                    id = ('tc5_policejob_armory_%s'):format(stationId),
                    coords = station.armory,
                    radius = 2.0,
                    options = {
                        {
                            id = ('tc5_policejob_armory_opt_%s'):format(stationId),
                            label = 'Open Armory',
                            icon = '🔫',
                            event = 'tc5_policejob:client:openArmoryEye',
                            canInteract = function() return isPolice() end
                        }
                    }
                })
            end

            if station.garageMenu then
                exports.tc5_eye:AddBoxZone({
                    id = ('tc5_policejob_garage_%s'):format(stationId),
                    coords = station.garageMenu,
                    radius = 2.0,
                    options = {
                        {
                            id = ('tc5_policejob_garage_opt_%s'):format(stationId),
                            label = 'Open Police Garage',
                            icon = '🚓',
                            event = 'tc5_policejob:client:openGarageEye',
                            canInteract = function() return isPolice() end
                        }
                    }
                })
            end
        end
    end
end)

RegisterNetEvent('tc5_policejob:client:toggleDutyEye', function()
    ExecuteCommand(TC5Police.Config.Commands.ToggleDuty)
end)

RegisterNetEvent('tc5_policejob:client:openArmoryEye', function()
    openPanel('armory')
end)

RegisterNetEvent('tc5_policejob:client:openGarageEye', function()
    openPanel('garage')
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if TC5Police.Config.UseTargetFallbackMarkers then
            for _, station in pairs(TC5Police.Config.Stations or {}) do
                local payload = getState()
                if payload.isPolice then
                    if station.duty and getDistanceTo(station.duty) < 20.0 then
                        sleep = 0
                        DrawMarker(2, station.duty.x, station.duty.y, station.duty.z + 0.15, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.2, 0.2, 0.2, 177, 15, 31, 180, false, true, 2, false, nil, nil, false)
                        if getDistanceTo(station.duty) < 1.5 then
                            drawText3D(station.duty + vector3(0.0, 0.0, 0.2), '[E] Toggle Duty')
                            if IsControlJustReleased(0, 38) then
                                ExecuteCommand(TC5Police.Config.Commands.ToggleDuty)
                            end
                        end
                    end

                    if station.armory and getDistanceTo(station.armory) < 20.0 then
                        sleep = 0
                        DrawMarker(2, station.armory.x, station.armory.y, station.armory.z + 0.15, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.2, 0.2, 0.2, 177, 15, 31, 180, false, true, 2, false, nil, nil, false)
                        if getDistanceTo(station.armory) < 1.5 then
                            drawText3D(station.armory + vector3(0.0, 0.0, 0.2), '[E] Open Armory')
                            if IsControlJustReleased(0, 38) then
                                openPanel('armory')
                            end
                        end
                    end

                    if station.garageMenu and getDistanceTo(station.garageMenu) < 20.0 then
                        sleep = 0
                        DrawMarker(36, station.garageMenu.x, station.garageMenu.y, station.garageMenu.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.65, 0.65, 0.65, 177, 15, 31, 180, false, true, 2, false, nil, nil, false)
                        if getDistanceTo(station.garageMenu) < 2.0 then
                            drawText3D(station.garageMenu + vector3(0.0, 0.0, 0.2), '[E] Open Garage')
                            if IsControlJustReleased(0, 38) then
                                openPanel('garage')
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNUICallback('close', function(_, cb)
    setPanel(false)
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('tc5_policejob:server:toggleDuty')
    cb('ok')
end)

RegisterNUICallback('claimArmory', function(data, cb)
    TriggerServerEvent('tc5_policejob:server:claimArmory', data and data.id)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('tc5_policejob:server:spawnVehicle', data and data.id)
    cb('ok')
end)

exports('IsPolice', function()
    return isPolice()
end)

exports('GetPoliceData', function()
    return getState()
end)

local seatbeltOn = false
local hudVisible = false
local menuOpen = false

local lastSpeed = 0.0
local lastBodyHealth = 1000.0
local lastEngineHealth = 1000.0

local function notify(message, nType)
    if GetResourceState('tc5_ui') == 'started' then
        exports.tc5_ui:Notify({
            title = 'Vehicles',
            message = message,
            type = nType or 'info',
            duration = 2500
        })
    end
end

local function sendUI(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function setMenuFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    menuOpen = state
end

local function getVehicleInOrNear()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if vehicle == 0 then
        return nil
    end

    return vehicle
end

local function getLightsState(vehicle)
    local lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
    if highbeamsOn == 1 then
        return 'High'
    end
    if lightsOn == 1 then
        return 'On'
    end
    return 'Off'
end

local function getGear(vehicle)
    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then
        if GetEntitySpeed(vehicle) < 1.0 then
            return 'P'
        end
        return 'R'
    end
    return tostring(gear)
end

local function getFuel(vehicle)
    if GetVehicleFuelLevel then
        return math.floor(GetVehicleFuelLevel(vehicle) + 0.5)
    end
    return 100
end

local function getRpm(vehicle)
    local rpm = GetVehicleCurrentRpm(vehicle)
    if not rpm then
        return 0.0
    end
    return math.max(0.0, math.min(1.0, rpm))
end

local function toggleSeatbelt()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return
    end

    seatbeltOn = not seatbeltOn

    if seatbeltOn then
        notify('Seatbelt fastened.', 'success')
    else
        notify('Seatbelt removed.', 'info')
    end
end

local function openVehicleMenu()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('You must be in a vehicle.', 'error')
        return
    end

    setMenuFocus(true)
    sendUI('vehicleMenu', { open = true })
end

local function resetVehicleState()
    seatbeltOn = false

    if hudVisible then
        hudVisible = false
        sendUI('hideHud', {})
    end
end

local function tryEjectFromCrash(vehicle, speed)
    if seatbeltOn then
        return
    end

    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)

    local speedDrop = lastSpeed - speed
    local bodyDrop = lastBodyHealth - bodyHealth
    local engineDrop = lastEngineHealth - engineHealth

    if speedDrop > 25.0 or bodyDrop > 120.0 or engineDrop > 120.0 then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(vehicle)

        SetEntityCoords(
            ped,
            coords.x + forward.x * 2.0,
            coords.y + forward.y * 2.0,
            coords.z + 0.5,
            true,
            true,
            true,
            false
        )

        SetPedToRagdoll(ped, 2500, 3000, 0, false, false, false)
        notify('You were ejected because you were not wearing a seatbelt.', 'error')
    end
end

RegisterCommand('tc5_flipcar', function()
    local vehicle = getVehicleInOrNear()

    if not vehicle then
        notify('No vehicle nearby to flip.', 'error')
        return
    end

    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)

    SetEntityRotation(vehicle, 0.0, 0.0, heading, 2, true)
    SetEntityCoords(vehicle, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
    SetVehicleOnGroundProperly(vehicle)

    notify('Vehicle flipped upright.', 'success')
end, false)

RegisterCommand('vehmenu', function()
    openVehicleMenu()
end, false)

RegisterKeyMapping('vehmenu', 'Open vehicle menu', 'keyboard', 'K')

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/tc5_flipcar', 'Flip the nearest vehicle upright')
    TriggerEvent('chat:addSuggestion', '/vehmenu', 'Open the vehicle menu')
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    TriggerEvent('chat:removeSuggestion', '/tc5_flipcar')
    TriggerEvent('chat:removeSuggestion', '/vehmenu')

    setMenuFocus(false)
    resetVehicleState()
end)

RegisterNUICallback('closeVehicleMenu', function(_, cb)
    setMenuFocus(false)
    sendUI('vehicleMenu', { open = false })
    cb('ok')
end)

RegisterNUICallback('vehicleAction', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        cb('ok')
        return
    end

    local action = tostring(data.action or '')

    if action == 'engine' then
        local running = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not running, false, true)
    elseif action == 'lights' then
        local lightsOn, _ = GetVehicleLightsState(vehicle)
        if lightsOn == 1 then
            SetVehicleLights(vehicle, 1)
        else
            SetVehicleLights(vehicle, 3)
        end
    elseif action == 'door_fl' then
        if GetVehicleDoorAngleRatio(vehicle, 0) > 0.1 then
            SetVehicleDoorShut(vehicle, 0, false)
        else
            SetVehicleDoorOpen(vehicle, 0, false, false)
        end
    elseif action == 'door_fr' then
        if GetVehicleDoorAngleRatio(vehicle, 1) > 0.1 then
            SetVehicleDoorShut(vehicle, 1, false)
        else
            SetVehicleDoorOpen(vehicle, 1, false, false)
        end
    elseif action == 'door_rl' then
        if GetVehicleDoorAngleRatio(vehicle, 2) > 0.1 then
            SetVehicleDoorShut(vehicle, 2, false)
        else
            SetVehicleDoorOpen(vehicle, 2, false, false)
        end
    elseif action == 'door_rr' then
        if GetVehicleDoorAngleRatio(vehicle, 3) > 0.1 then
            SetVehicleDoorShut(vehicle, 3, false)
        else
            SetVehicleDoorOpen(vehicle, 3, false, false)
        end
    elseif action == 'door_hood' then
        if GetVehicleDoorAngleRatio(vehicle, 4) > 0.1 then
            SetVehicleDoorShut(vehicle, 4, false)
        else
            SetVehicleDoorOpen(vehicle, 4, false, false)
        end
    elseif action == 'door_trunk' then
        if GetVehicleDoorAngleRatio(vehicle, 5) > 0.1 then
            SetVehicleDoorShut(vehicle, 5, false)
        else
            SetVehicleDoorOpen(vehicle, 5, false, false)
        end
    end

    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)

        if inVehicle then
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local speed = GetEntitySpeed(vehicle) * 2.236936
                local rpm = getRpm(vehicle)
                local gear = getGear(vehicle)
                local fuel = getFuel(vehicle)
                local engineHealth = GetVehicleEngineHealth(vehicle)
                local bodyHealth = GetVehicleBodyHealth(vehicle)
                local engineOn = GetIsVehicleEngineRunning(vehicle)
                local handbrake = GetVehicleHandbrake(vehicle)
                local locked = GetVehicleDoorLockStatus(vehicle)
                local lights = getLightsState(vehicle)
                local streetHash = GetStreetNameAtCoord(table.unpack(GetEntityCoords(ped)))
                local streetName = GetStreetNameFromHashKey(streetHash)

                if not hudVisible then
                    hudVisible = true
                    sendUI('showHud', {})
                end

                sendUI('updateHud', {
                    speed = math.floor(speed + 0.5),
                    rpm = rpm,
                    gear = gear,
                    fuel = fuel,
                    engineHealth = math.floor(engineHealth + 0.5),
                    bodyHealth = math.floor(bodyHealth + 0.5),
                    engineOn = engineOn,
                    handbrake = handbrake,
                    locked = locked and locked ~= 1,
                    lights = lights,
                    seatbelt = seatbeltOn,
                    street = streetName or ''
                })

                if seatbeltOn then
                    DisableControlAction(0, 75, true)
                end

                tryEjectFromCrash(vehicle, speed)

                lastSpeed = speed
                lastBodyHealth = bodyHealth
                lastEngineHealth = engineHealth
            else
                resetVehicleState()
            end
        else
            resetVehicleState()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if IsControlJustReleased(0, 29) then -- B
            toggleSeatbelt()
        end
    end
end)
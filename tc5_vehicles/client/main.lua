local seatbeltOn = false
local hudVisible = false

local function notify(msg, type)
    if GetResourceState('tc5_ui') == 'started' then
        exports.tc5_ui:Notify({
            title = 'Vehicle',
            message = msg,
            type = type or 'info'
        })
    end
end

-- ======================
-- FLIP COMMAND
-- ======================
local function getVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    return veh ~= 0 and veh or nil
end

RegisterCommand('tc5_flipcar', function()
    local veh = getVehicle()
    if not veh then
        notify('No vehicle nearby', 'error')
        return
    end

    local coords = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)

    SetEntityRotation(veh, 0.0, 0.0, heading, 2, true)
    SetEntityCoords(veh, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
    SetVehicleOnGroundProperly(veh)

    notify('Vehicle flipped', 'success')
end)

-- ======================
-- SEATBELT
-- ======================
RegisterCommand('seatbelt', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    seatbeltOn = not seatbeltOn
    notify(seatbeltOn and 'Seatbelt ON' or 'Seatbelt OFF')
end)

RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', 'B')

local function resetHud()
    if hudVisible then
        hudVisible = false
        SendNUIMessage({ action = 'hide' })
    end

    DisplayRadar(false)
end

-- ======================
-- HUD LOOP
-- ======================
CreateThread(function()
    while true do
        Wait(100)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = math.floor(GetEntitySpeed(veh) * 2.236936 + 0.5)
            local fuel = math.floor(GetVehicleFuelLevel(veh) + 0.5)
            local rpm = GetVehicleCurrentRpm(veh)
            local gear = GetVehicleCurrentGear(veh)
            local engineOn = GetIsVehicleEngineRunning(veh)

            local _, lightsOn, highbeamsOn = GetVehicleLightsState(veh)
            local lights = 0
            if highbeamsOn == 1 then
                lights = 2
            elseif lightsOn == 1 then
                lights = 1
            end

            if not hudVisible then
                hudVisible = true
            end

            DisplayRadar(true)

            SendNUIMessage({
                action = 'update',
                speed = speed,
                fuel = fuel,
                rpm = rpm,
                gear = gear,
                engineOn = engineOn,
                lights = lights,
                seatbelt = seatbeltOn
            })

            if seatbeltOn then
                DisableControlAction(0, 75, true)
            end
        else
            resetHud()
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    DisplayRadar(false)
end)

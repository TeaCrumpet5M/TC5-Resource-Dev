TC5VehicleKeys = TC5VehicleKeys or {}

local function notify(message, kind)
    if GetResourceState('tc5_ui') == 'started' then
        TriggerEvent('tc5_ui:client:notify', {
            title = 'Vehicle',
            message = message,
            type = kind or 'info'
        })
    end
end

local function canUseVehicle(vehicle)
    if vehicle == 0 then
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    return exports['tc5_vehiclekeys']:HasKeys(PlayerId() and GetPlayerServerId(PlayerId()) or 0, plate)
end

RegisterCommand(TC5VehicleKeys.Config.LockCommand, function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 8.0, 0, 71)
    end

    if vehicle == 0 then
        notify('No vehicle nearby.', 'error')
        return
    end

    if not canUseVehicle(vehicle) then
        notify('You do not have keys for this vehicle.', 'error')
        return
    end

    local locked = GetVehicleDoorLockStatus(vehicle)
    local shouldLock = locked ~= 2
    SetVehicleDoorsLocked(vehicle, shouldLock and 2 or 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, shouldLock)
    notify(shouldLock and 'Vehicle locked.' or 'Vehicle unlocked.', 'success')
end, false)

RegisterKeyMapping(TC5VehicleKeys.Config.LockCommand, 'TC5 Vehicle Lock', 'keyboard', TC5VehicleKeys.Config.LockKey)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsTryingToEnter(ped)

        if vehicle ~= 0 then
            if not canUseVehicle(vehicle) then
                ClearPedTasks(ped)
                notify('You do not have keys for this vehicle.', 'error')
                Wait(1000)
            end
        end
    end
end)

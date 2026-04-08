RegisterCommand('tc5_savedamage', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        exports.tc5_ui:Notify({ title='Damage', message='Drive a vehicle first.', type='error', duration=2500 })
        return
    end

    TriggerServerEvent('tc5_garage:server:storeVehicle', {
        garageId = 'alta_public',
        plate = GetVehicleNumberPlateText(vehicle),
        vehicleProps = {},
        fuel = GetVehicleFuelLevel(vehicle),
        engine = GetVehicleEngineHealth(vehicle),
        body = GetVehicleBodyHealth(vehicle)
    })

    exports.tc5_ui:Notify({ title='Damage', message='Vehicle damage pushed to garage persistence.', type='success', duration=2500 })
end, false)

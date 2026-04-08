RegisterCommand('tc5_trackvehicle', function(_, args)
    local plate = args[1]
    if not plate then
        exports.tc5_ui:Notify({ title='Tracker', message='Usage: /tc5_trackvehicle [plate]', type='error', duration=2500 })
        return
    end
    TriggerServerEvent('tc5_tracker:server:getVehicleData', plate)
end, false)

RegisterNetEvent('tc5_tracker:client:vehicleData', function(vehicle)
    if not vehicle then
        exports.tc5_ui:Notify({ title='Tracker', message='Vehicle not found in garage records.', type='error', duration=2500 })
        return
    end

    exports.tc5_ui:Notify({
        title='Tracker',
        message=('Vehicle %s is %s at %s'):format(vehicle.plate, vehicle.state or 'unknown', vehicle.garageLabel or vehicle.garageId or 'unknown garage'),
        type='info',
        duration=4500
    })
end)

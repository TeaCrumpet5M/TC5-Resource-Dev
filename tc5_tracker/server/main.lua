RegisterNetEvent('tc5_tracker:server:getVehicleData', function(plate)
    local src = source
    local vehicle = exports['tc5_garage']:GetVehicleByPlate(plate)
    TriggerClientEvent('tc5_tracker:client:vehicleData', src, vehicle)
end)

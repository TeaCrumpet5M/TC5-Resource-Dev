TC5VehicleKeys = TC5VehicleKeys or {}
TC5VehicleKeys.Server = {}

exports('HasKeys', function(src, plate)
    return exports['tc5_garage']:HasVehicleAccess(src, plate)
end)

exports('GivePermanentKey', function(src, targetSrc, plate)
    return exports['tc5_garage']:GiveVehicleKey(src, targetSrc, plate)
end)

CreateThread(function()
    while true do
        Wait(TC5Fuel.Config.TickMs)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local speed = GetEntitySpeed(vehicle)
            local fuel = GetVehicleFuelLevel(vehicle)
            local drain = speed > 1.0 and TC5Fuel.Config.DriveDrain or TC5Fuel.Config.IdleDrain
            fuel = math.max(0.0, fuel - drain)
            SetVehicleFuelLevel(vehicle, fuel)
            if fuel <= 0.0 then
                SetVehicleEngineOn(vehicle, false, true, true)
            end
        end
    end
end)

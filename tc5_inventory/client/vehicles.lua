RegisterCommand('trunk', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 4.0, 0, 71)
    if vehicle == 0 then return end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then return end

    TriggerServerEvent('tc5_inventory:server:openInventory', {
        type = 'trunk',
        owner = plate
    })
end)

RegisterCommand('glovebox', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then return end

    TriggerServerEvent('tc5_inventory:server:openInventory', {
        type = 'glovebox',
        owner = plate
    })
end)

RegisterKeyMapping('trunk', 'Open Trunk', 'keyboard', 'K')
RegisterKeyMapping('glovebox', 'Open Glovebox', 'keyboard', 'J')
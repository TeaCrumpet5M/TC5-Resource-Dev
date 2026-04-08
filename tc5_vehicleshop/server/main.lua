RegisterCommand('tc5_buycar', function(src, args)
    if src == 0 then return end
    local model = tostring(args[1] or '')
    if model == '' then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'Vehicle Shop',
            message = 'Usage: /tc5_buycar [model]',
            type = 'error',
            duration = 2500
        })
        return
    end

    local selected
    for i = 1, #TC5VehicleShop.Config.Vehicles do
        if TC5VehicleShop.Config.Vehicles[i].model == model then
            selected = TC5VehicleShop.Config.Vehicles[i]
            break
        end
    end

    if not selected then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'Vehicle Shop',
            message = 'Vehicle not found.',
            type = 'error',
            duration = 2500
        })
        return
    end

    local player = exports['tc5_core']:GetPlayer(src)
    if not player then return end

    if player:GetBank() < selected.price then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'Vehicle Shop',
            message = 'Not enough bank money.',
            type = 'error',
            duration = 2500
        })
        return
    end

    player:RemoveBank(selected.price)
    player:SaveCharacter()

    local plate = ('TC%s'):format(math.random(1000, 9999))
    local ok, vehicle = exports['tc5_garage']:CreateOwnedVehicle(src, {
        model = selected.model,
        plate = plate,
        garageId = selected.garageId,
        vehicleProps = { model = selected.model, plate = plate }
    })

    if not ok then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'Vehicle Shop',
            message = tostring(vehicle),
            type = 'error',
            duration = 2500
        })
        return
    end

    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = 'Vehicle Shop',
        message = ('Purchased %s for $%s. Plate: %s'):format(selected.label, selected.price, plate),
        type = 'success',
        duration = 4500
    })
end, false)

RegisterCommand('tc5_valet', function(_, args)
    local plate = args[1]
    if not plate then
        exports.tc5_ui:Notify({ title='Valet', message='Usage: /tc5_valet [plate]', type='error', duration=2500 })
        return
    end

    exports.tc5_ui:Notify({ title='Valet', message='Valet requested. Retrieving your vehicle...', type='info', duration=2500 })
    Wait(1500)
    TriggerServerEvent('tc5_garage:server:setVehicleOut', plate)
end, false)

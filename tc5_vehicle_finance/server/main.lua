MySQL.query.await([[
CREATE TABLE IF NOT EXISTS tc5_vehicle_finance (
    id INT NOT NULL AUTO_INCREMENT,
    char_id INT NOT NULL,
    plate VARCHAR(16) NOT NULL,
    balance INT NOT NULL DEFAULT 0,
    installment INT NOT NULL DEFAULT 0,
    due_day INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
)]])
RegisterCommand('tc5_financevehicle', function(src, args)
    if src == 0 then return end
    local plate = tostring(args[1] or '')
    local total = tonumber(args[2] or 0) or 0
    local installment = tonumber(args[3] or 0) or 0
    local charId = exports['tc5_core']:GetCharacterId(src)
    if plate == '' or total <= 0 or installment <= 0 or not charId then
        TriggerClientEvent('tc5_ui:client:notify', src, { title='Finance', message='Usage: /tc5_financevehicle [plate] [total] [installment]', type='error', duration=2500 })
        return
    end
    MySQL.insert.await('INSERT INTO tc5_vehicle_finance (char_id, plate, balance, installment, due_day) VALUES (?, ?, ?, ?, ?)', { charId, plate, total, installment, 1 })
    TriggerClientEvent('tc5_ui:client:notify', src, { title='Finance', message='Vehicle finance created.', type='success', duration=2500 })
end, false)

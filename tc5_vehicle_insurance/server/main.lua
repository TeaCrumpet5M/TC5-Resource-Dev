MySQL.query.await([[
CREATE TABLE IF NOT EXISTS tc5_vehicle_insurance (
    id INT NOT NULL AUTO_INCREMENT,
    char_id INT NOT NULL,
    plate VARCHAR(16) NOT NULL,
    policy_type VARCHAR(50) NOT NULL DEFAULT 'basic',
    insured TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
)]])
RegisterCommand('tc5_insurevehicle', function(src, args)
    if src == 0 then return end
    local charId = exports['tc5_core']:GetCharacterId(src)
    local plate = tostring(args[1] or '')
    local policy = tostring(args[2] or 'basic')
    if not charId or plate == '' then
        TriggerClientEvent('tc5_ui:client:notify', src, { title='Insurance', message='Usage: /tc5_insurevehicle [plate] [policy]', type='error', duration=2500 })
        return
    end
    MySQL.insert.await('INSERT INTO tc5_vehicle_insurance (char_id, plate, policy_type, insured) VALUES (?, ?, ?, 1)', { charId, plate, policy })
    TriggerClientEvent('tc5_ui:client:notify', src, { title='Insurance', message='Insurance policy created.', type='success', duration=2500 })
end, false)

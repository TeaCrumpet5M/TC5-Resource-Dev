RegisterNetEvent('tc5_chat:sendMessage', function(message)
    local src = source
    local name = GetPlayerName(src) or ('Player ' .. tostring(src))
    local clean = tostring(message or '')

    clean = clean:gsub('%^%d', '')
    clean = clean:gsub('[\r\n]', ' ')
    clean = clean:sub(1, 240)
    clean = clean:gsub('^%s+', ''):gsub('%s+$', '')

    if clean == '' then
        return
    end

    TriggerClientEvent('chat:addMessage', -1, {
        color = { 177, 15, 31 },
        args = { name, clean }
    })
end)

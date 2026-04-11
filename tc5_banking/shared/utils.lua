TC5Banking = TC5Banking or {}
TC5Banking.Utils = TC5Banking.Utils or {}

function TC5Banking.Utils.Debug(message)
    if not TC5Banking.Config.Debug then return end
    print(('[tc5_banking] %s'):format(tostring(message)))
end

function TC5Banking.Utils.Trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

function TC5Banking.Utils.FormatMoney(value)
    local amount = math.floor(tonumber(value) or 0)
    local formatted = tostring(amount)
    while true do
        formatted, k = formatted:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

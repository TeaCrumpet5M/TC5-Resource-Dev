TC5Banking = TC5Banking or {}
TC5Banking.Utils = TC5Banking.Utils or {}

function TC5Banking.Utils.DebugPrint(message)
    if not TC5Banking.Config.Debug then return end
    print(('[tc5_banking] %s'):format(tostring(message)))
end

function TC5Banking.Utils.Trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

function TC5Banking.Utils.FormatMoney(amount)
    local negative = (tonumber(amount) or 0) < 0
    local value = math.abs(math.floor(tonumber(amount) or 0))
    local formatted = tostring(value)

    while true do
        formatted, _ = formatted:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
        if not formatted:find('^%-?%d+%d%d%d') then break end
    end

    return (negative and '-$' or '$') .. formatted
end

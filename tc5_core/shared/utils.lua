TC5 = TC5 or {}
TC5.Utils = {}

function TC5.Utils.DebugPrint(message)
    if not TC5.Config.Debug then return end
    print(('^3[%s]^7 %s'):format(TC5.Config.FrameworkName, tostring(message)))
end

function TC5.Utils.GetPlayerNameSafe(src)
    if not src then
        return 'Unknown'
    end

    local playerName = GetPlayerName(src)

    if not playerName or playerName == '' then
        return ('Player_%s'):format(src)
    end

    return playerName
end

function TC5.Utils.GetIdentifier(src, identifierType)
    if not src then
        print('^1[tc5_core]^7 GetIdentifier called with nil source.')
        return nil
    end

    local idType = identifierType or 'license'
    local prefix = idType .. ':'
    local identifiers = GetPlayerIdentifiers(src)

    if not identifiers or #identifiers == 0 then
        print(('^1[tc5_core]^7 No identifiers found for source %s.'):format(tostring(src)))
        return nil
    end

    for i = 1, #identifiers do
        local identifier = identifiers[i]

        if identifier and identifier:sub(1, #prefix) == prefix then
            return identifier
        end
    end

    return nil
end

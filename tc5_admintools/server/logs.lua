TC5Admin = TC5Admin or {}

local function getAdminName(src)
    if src == 0 then
        return 'Console'
    end
    return GetPlayerName(src) or ('Player %s'):format(src)
end

function TC5Admin.Log(src, action, message)
    if not TC5Admin.Config.Logging.Enabled then
        return
    end

    local line = ('[%s] [%s:%s] %s\n'):format(
        os.date('%Y-%m-%d %H:%M:%S'),
        getAdminName(src),
        tostring(src),
        ('%s | %s'):format(action, message)
    )

    SaveResourceFile(GetCurrentResourceName(), TC5Admin.Config.Logging.FileName, line, -1)
    print(('^3[tc5_admintools]^7 %s'):format(line:gsub('\n', '')))
end

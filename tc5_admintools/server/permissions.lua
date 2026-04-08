TC5Admin = TC5Admin or {}

local function hasAce(src, ace)
    if src == 0 then
        return true
    end
    return IsPlayerAceAllowed(src, ace)
end

function TC5Admin.GetPermissionGroup(src)
    if hasAce(src, 'group.admin') or hasAce(src, 'tc5.god') then
        return 'god'
    end
    if hasAce(src, 'tc5.admin') then
        return 'admin'
    end
    if hasAce(src, 'tc5.mod') then
        return 'mod'
    end
    return nil
end

function TC5Admin.HasPermission(src, action)
    local group = TC5Admin.GetPermissionGroup(src)
    if not group then
        return false
    end

    local perms = TC5Admin.Permissions[group]
    if not perms then
        return false
    end

    if perms.all then
        return true
    end

    return perms[action] == true
end

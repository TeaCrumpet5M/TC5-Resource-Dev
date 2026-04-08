TC5Admin = TC5Admin or {}

local function safeHasPermission(src, action)
    if type(TC5Admin.HasPermission) ~= 'function' then
        print('^1[tc5_admintools]^7 HasPermission is missing. Check server/permissions.lua and fxmanifest load order.')
        return false
    end
    return TC5Admin.HasPermission(src, action)
end

local function buildPayload(src)
    local jobs = {}
    local vehicles = {}
    local items = {}

    if type(TC5Admin.GetJobCatalog) == 'function' then
        jobs = TC5Admin.GetJobCatalog() or {}
    end

    if type(TC5Admin.GetVehicleCatalog) == 'function' then
        vehicles = TC5Admin.GetVehicleCatalog() or {}
    end

    if type(TC5Admin.GetItemCatalog) == 'function' then
        items = TC5Admin.GetItemCatalog() or {}
    end

    return {
        group = TC5Admin.GetPermissionGroup(src),
        permissions = TC5Admin.Permissions[TC5Admin.GetPermissionGroup(src) or ''] or {},
        players = TC5Admin.GetPlayers(),
        reports = TC5Admin.Reports or {},
        jobs = jobs,
        vehicleCatalog = vehicles,
        vehicleCategories = TC5Admin.Config.VehicleSpawner.Categories or {},
        itemCatalog = items
    }
end

RegisterNetEvent('tc5_admintools:server:requestOpen', function()
    local src = source
    if not safeHasPermission(src, 'open') then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'TC5 Admin',
            message = 'You do not have permission to open admin tools.',
            type = 'error'
        })
        return
    end
    TriggerClientEvent('tc5_admintools:client:openMenu', src, buildPayload(src))
end)

RegisterNetEvent('tc5_admintools:server:requestRefresh', function()
    local src = source
    if not safeHasPermission(src, 'open') then return end
    TriggerClientEvent('tc5_admintools:client:refreshMenu', src, buildPayload(src))
end)

exports('HasPermission', function(src, action)
    return TC5Admin.HasPermission(src, action)
end)

exports('GetPermissionGroup', function(src)
    return TC5Admin.GetPermissionGroup(src)
end)

RegisterCommand(TC5Admin.Config.Command, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_admintools:client:openRequest', src)
end, false)

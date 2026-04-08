TC5Admin = TC5Admin or {}
TC5Admin.Reports = TC5Admin.Reports or {}

local function notify(src, title, message, notifyType)
    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = title,
        message = message,
        type = notifyType or 'info'
    })
end

RegisterNetEvent('tc5_admintools:server:createReport', function(message)
    local src = source

    if not TC5Admin.Config.Reports.Enabled then
        return
    end

    message = tostring(message or ''):sub(1, 300)
    if message == '' then
        return
    end

    local reportId = #TC5Admin.Reports + 1

    TC5Admin.Reports[reportId] = {
        id = reportId,
        playerId = src,
        playerName = GetPlayerName(src),
        message = message,
        status = 'open',
        createdAt = os.time()
    }

    TC5Admin.Log(src, 'REPORT_CREATED', ('Report #%s: %s'):format(reportId, message))

    local players = GetPlayers()
    for i = 1, #players do
        local target = tonumber(players[i])
        if TC5Admin.HasPermission(target, 'reports') or TC5Admin.HasPermission(target, 'open') then
            notify(target, 'TC5 Reports', ('New report #%s from %s'):format(reportId, GetPlayerName(src)), 'inform')
            TriggerClientEvent('tc5_admintools:client:reportsUpdated', target, TC5Admin.Reports)
        end
    end

    notify(src, 'TC5 Reports', 'Your report has been sent to staff.', 'success')
end)

RegisterNetEvent('tc5_admintools:server:closeReport', function(reportId)
    local src = source
    if not TC5Admin.HasPermission(src, 'reports') and not TC5Admin.HasPermission(src, 'open') then
        return
    end

    reportId = tonumber(reportId)
    local report = TC5Admin.Reports[reportId]
    if not report then
        return
    end

    report.status = 'closed'
    report.closedBy = src
    report.closedAt = os.time()

    TC5Admin.Log(src, 'REPORT_CLOSED', ('Report #%s closed'):format(reportId))

    local players = GetPlayers()
    for i = 1, #players do
        local target = tonumber(players[i])
        if TC5Admin.HasPermission(target, 'reports') or TC5Admin.HasPermission(target, 'open') then
            TriggerClientEvent('tc5_admintools:client:reportsUpdated', target, TC5Admin.Reports)
        end
    end
end)

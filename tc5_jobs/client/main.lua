TC5Jobs = TC5Jobs or {}
TC5Jobs.Client = TC5Jobs.Client or {}
TC5Jobs.Client.PlayerJob = TC5Jobs.Client.PlayerJob or nil

local function requestSync()
    TriggerServerEvent('tc5_jobs:server:requestSync')
end

RegisterNetEvent('tc5_jobs:client:jobUpdated', function(jobData)
    TC5Jobs.Client.PlayerJob = jobData
end)

RegisterNetEvent('tc5_jobs:client:forceSync', function()
    requestSync()
end)

RegisterNetEvent('tc5_core:client:userLoaded', function()
    requestSync()
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/tc5_job', 'Show your current job information')
    TriggerEvent('chat:addSuggestion', '/tc5_duty', 'Toggle your current duty status')
    TriggerEvent('chat:addSuggestion', '/tc5_setjob', 'Set a player job', {
        { name = 'id', help = 'Player server ID' },
        { name = 'job', help = 'Job name, e.g. police' },
        { name = 'grade', help = 'Job grade number' }
    })
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    requestSync()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerEvent('chat:removeSuggestion', '/tc5_job')
    TriggerEvent('chat:removeSuggestion', '/tc5_duty')
    TriggerEvent('chat:removeSuggestion', '/tc5_setjob')
end)

RegisterCommand('tc5_job', function()
    requestSync()
    Wait(150)

    local job = TC5Jobs.Client.PlayerJob
    if not job then
        exports.tc5_ui:Notify({
            title = 'Jobs',
            message = 'Your job data has not loaded yet.',
            type = 'warning',
            duration = 2500
        })
        return
    end

    exports.tc5_ui:Notify({
        title = job.label,
        message = ('Grade: %s | Duty: %s'):format(job.gradeLabel, job.onduty and 'On Duty' or 'Off Duty'),
        type = 'info',
        duration = 3500
    })
end, false)

RegisterCommand('tc5_duty', function()
    TriggerServerEvent('tc5_jobs:server:toggleDuty')
end, false)

exports('GetLocalJob', function()
    return TC5Jobs.Client.PlayerJob
end)

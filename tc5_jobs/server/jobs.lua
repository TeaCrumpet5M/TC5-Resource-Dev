TC5Jobs = TC5Jobs or {}
TC5Jobs.Server = TC5Jobs.Server or {}
TC5Jobs.Server.PlayerJobs = TC5Jobs.Server.PlayerJobs or {}

local function getPlayer(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function notify(src, payload)
    TriggerClientEvent('tc5_ui:client:notify', src, payload)
end

local function jobToClientPayload(jobData)
    return {
        name = jobData.name,
        label = jobData.label,
        grade = jobData.grade,
        gradeLabel = jobData.gradeLabel,
        salary = jobData.salary,
        onduty = jobData.onduty
    }
end

local function saveJob(charId, jobData)
    return MySQL.update.await([[
        INSERT INTO tc5_jobs (char_id, job_name, grade, onduty)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            job_name = VALUES(job_name),
            grade = VALUES(grade),
            onduty = VALUES(onduty),
            updated_at = CURRENT_TIMESTAMP
    ]], {
        charId,
        jobData.name,
        jobData.grade,
        jobData.onduty and 1 or 0
    })
end

local function hydrateJobData(jobName, grade, onduty)
    local definition = TC5Jobs.GetJobDefinition(jobName)

    if not definition then
        if TC5Jobs.Config.RequireRegisteredJobs then
            TC5Jobs.Debug(('Tried to hydrate unregistered job "%s", falling back to default job.'):format(tostring(jobName)))
            definition = TC5Jobs.GetJobDefinition(TC5Jobs.Config.DefaultJob)
            grade = TC5Jobs.Config.DefaultGrade
            onduty = TC5Jobs.Config.DefaultDuty
        else
            definition = {
                name = tostring(jobName or TC5Jobs.Config.DefaultJob):lower(),
                label = tostring(jobName or 'Unknown'),
                defaultDuty = onduty ~= false,
                grades = {
                    [0] = { label = 'Employee', salary = 0, permissions = {} }
                }
            }
        end
    end

    grade = math.floor(tonumber(grade) or 0)

    if not definition.grades[grade] then
        grade = 0
    end

    return {
        name = definition.name,
        label = definition.label,
        grade = grade,
        gradeLabel = definition.grades[grade].label,
        salary = definition.grades[grade].salary or 0,
        onduty = onduty == nil and definition.defaultDuty or (onduty == true or onduty == 1)
    }
end

function TC5Jobs.Server.EnsureDatabase()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_jobs (
            char_id INT NOT NULL,
            job_name VARCHAR(50) NOT NULL,
            grade INT NOT NULL DEFAULT 0,
            onduty TINYINT(1) NOT NULL DEFAULT 1,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (char_id)
        )
    ]])
end

function TC5Jobs.Server.LoadPlayerJob(src)
    local charId = getCharacterId(src)
    if not charId then
        return nil, 'character_missing'
    end

    local row = MySQL.single.await('SELECT * FROM tc5_jobs WHERE char_id = ? LIMIT 1', { charId })
    local jobData

    if row then
        jobData = hydrateJobData(row.job_name, row.grade, row.onduty)
    else
        jobData = TC5Jobs.GetDefaultJobData()
        saveJob(charId, jobData)
    end

    TC5Jobs.Server.PlayerJobs[src] = {
        charId = charId,
        data = jobData
    }

    TriggerClientEvent('tc5_jobs:client:jobUpdated', src, jobToClientPayload(jobData))
    return jobData
end

function TC5Jobs.Server.GetPlayerJob(src)
    local state = TC5Jobs.Server.PlayerJobs[src]
    if state and state.data then
        return state.data
    end

    return TC5Jobs.Server.LoadPlayerJob(src)
end

function TC5Jobs.Server.SetPlayerJob(src, jobName, grade, onduty)
    local player = getPlayer(src)
    if not player then
        return false, 'player_missing'
    end

    local charId = getCharacterId(src)
    if not charId then
        return false, 'character_missing'
    end

    local jobData = hydrateJobData(jobName, grade, onduty)
    saveJob(charId, jobData)

    TC5Jobs.Server.PlayerJobs[src] = {
        charId = charId,
        data = jobData
    }

    TriggerClientEvent('tc5_jobs:client:jobUpdated', src, jobToClientPayload(jobData))
    TriggerClientEvent('tc5_jobs:client:forceSync', src)

    notify(src, {
        title = 'Job Updated',
        message = ('You are now %s (%s).'):format(jobData.label, jobData.gradeLabel),
        type = 'success',
        duration = 3000
    })

    return true, jobData
end

function TC5Jobs.Server.ToggleDuty(src, state)
    local player = getPlayer(src)
    if not player then
        return false, 'player_missing'
    end

    local current = TC5Jobs.Server.GetPlayerJob(src)
    if not current then
        return false, 'job_missing'
    end

    if state == nil then
        current.onduty = not current.onduty
    else
        current.onduty = state == true
    end

    local charId = getCharacterId(src)
    if not charId then
        return false, 'character_missing'
    end

    saveJob(charId, current)

    TriggerClientEvent('tc5_jobs:client:jobUpdated', src, jobToClientPayload(current))
    TriggerClientEvent('tc5_jobs:client:forceSync', src)

    notify(src, {
        title = 'Duty Status',
        message = current.onduty and 'You are now on duty.' or 'You are now off duty.',
        type = current.onduty and 'success' or 'info',
        duration = 2500
    })

    return true, current
end

function TC5Jobs.Server.HasJob(src, jobName, minGrade)
    local current = TC5Jobs.Server.GetPlayerJob(src)
    if not current then return false end

    minGrade = math.floor(tonumber(minGrade) or 0)
    return current.name == tostring(jobName):lower() and current.grade >= minGrade
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TC5Jobs.Server.EnsureDatabase()
    TC5Jobs.Debug('Database ready.')
end)

AddEventHandler('playerDropped', function()
    TC5Jobs.Server.PlayerJobs[source] = nil
end)

RegisterNetEvent('tc5_jobs:server:requestSync', function()
    local src = source
    local jobData = TC5Jobs.Server.LoadPlayerJob(src)
    if not jobData then
        notify(src, {
            title = 'Jobs',
            message = 'Unable to load your job data.',
            type = 'error',
            duration = 3000
        })
    end
end)

RegisterNetEvent('tc5_jobs:server:toggleDuty', function(state)
    TC5Jobs.Server.ToggleDuty(source, state)
end)

RegisterCommand('tc5_setjob', function(src, args)
    if src == 0 then
        print('Use this command in-game.')
        return
    end

    if not IsPlayerAceAllowed(src, 'command') then
        notify(src, {
            title = 'Jobs',
            message = 'You do not have permission to use this command.',
            type = 'error',
            duration = 3000
        })
        return
    end

    local target = tonumber(args[1] or src)
    local jobName = tostring(args[2] or '')
    local grade = tonumber(args[3] or 0) or 0

    if not target or jobName == '' then
        notify(src, {
            title = 'Jobs',
            message = 'Usage: /tc5_setjob [id] [job] [grade]',
            type = 'error',
            duration = 4000
        })
        return
    end

    local success, result = TC5Jobs.Server.SetPlayerJob(target, jobName, grade)
    if not success then
        notify(src, {
            title = 'Jobs',
            message = ('Failed to set job: %s'):format(tostring(result)),
            type = 'error',
            duration = 3500
        })
        return
    end

    if src ~= target then
        notify(src, {
            title = 'Jobs',
            message = ('Set player %s to %s (%s).'):format(target, result.label, result.gradeLabel),
            type = 'success',
            duration = 3000
        })
    end
end, false)

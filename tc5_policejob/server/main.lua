TC5Police = TC5Police or {}
TC5Police.Server = TC5Police.Server or {}

local armoryCooldowns = {}

local function now()
    return os.time()
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function getPlayer(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function notify(src, payload)
    TriggerClientEvent('tc5_ui:client:notify', src, payload)
end

local function getJob(src)
    return exports['tc5_jobs']:GetPlayerJob(src)
end

local function hasPoliceJob(src, minGrade)
    return exports['tc5_jobs']:HasJob(src, TC5Police.Config.JobName, minGrade or 0)
end

local function getOfficerByCharId(charId)
    return MySQL.single.await('SELECT * FROM tc5_police_profiles WHERE char_id = ? LIMIT 1', { charId })
end

local function getOfficerProfile(src)
    local charId = getCharacterId(src)
    if not charId then return nil end
    return getOfficerByCharId(charId)
end

local function ensureProfile(charId, badgeNumber, callsign)
    MySQL.insert.await([[
        INSERT INTO tc5_police_profiles (char_id, badge_number, callsign)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            badge_number = VALUES(badge_number),
            callsign = VALUES(callsign),
            updated_at = CURRENT_TIMESTAMP
    ]], {
        charId,
        tostring(badgeNumber or ''),
        tostring(callsign or '')
    })
end

local function removeProfile(charId)
    MySQL.query.await('DELETE FROM tc5_police_profiles WHERE char_id = ?', { charId })
end

local function getFullName(src)
    local player = getPlayer(src)
    if player and player.GetName then
        local ok, name = pcall(function() return player:GetName() end)
        if ok and name and name ~= '' then
            return name
        end
    end

    return GetPlayerName(src) or ('Player %s'):format(src)
end

local function getPanelPayload(src)
    local job = getJob(src)
    local profile = getOfficerProfile(src)
    local isPolice = job and job.name == TC5Police.Config.JobName or false

    return {
        isPolice = isPolice,
        isOnDuty = isPolice and job.onduty == true or false,
        officer = isPolice and {
            fullName = getFullName(src),
            grade = job.grade,
            gradeLabel = job.gradeLabel,
            badgeNumber = profile and profile.badge_number or '',
            callsign = profile and profile.callsign or ''
        } or nil,
        armory = TC5Police.Config.Armory,
        garage = TC5Police.Config.Garage,
        stations = TC5Police.Config.Stations,
        theme = TC5Police.Config.Theme
    }
end

local function syncOfficer(src)
    TriggerClientEvent('tc5_policejob:client:syncOfficer', src, getPanelPayload(src))
end

local function ensureDatabase()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_police_profiles (
            id INT NOT NULL AUTO_INCREMENT,
            char_id INT NOT NULL,
            badge_number VARCHAR(32) DEFAULT NULL,
            callsign VARCHAR(32) DEFAULT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_char_id (char_id)
        )
    ]])
end

local function registerPoliceJob()
    local ok, result = exports['tc5_jobs']:RegisterJob(TC5Police.Config.JobDefinition)
    if ok then
        print('^2[tc5_policejob]^7 Registered police job with tc5_jobs')
    else
        print(('^3[tc5_policejob]^7 Job registration skipped: %s'):format(tostring(result)))
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ensureDatabase()
    registerPoliceJob()
end)

AddEventHandler('tc5_jobs:server:jobChanged', function(src)
    syncOfficer(src)
end)

AddEventHandler('tc5_jobs:server:dutyChanged', function(src)
    syncOfficer(src)
end)

RegisterNetEvent('tc5_policejob:server:requestInit', function()
    syncOfficer(source)
end)

RegisterNetEvent('tc5_policejob:server:getPanelData', function()
    syncOfficer(source)
end)

RegisterNetEvent('tc5_policejob:server:toggleDuty', function()
    local src = source
    if not hasPoliceJob(src, 0) then
        notify(src, {
            title = 'Police',
            message = 'You are not police.',
            type = 'error'
        })
        return
    end

    exports['tc5_jobs']:ToggleDuty(src)
    syncOfficer(src)
end)

RegisterNetEvent('tc5_policejob:server:claimArmory', function(kitId)
    local src = source
    local job = getJob(src)
    if not job or job.name ~= TC5Police.Config.JobName then
        notify(src, {
            title = 'Armory',
            message = 'You are not authorized to use the armory.',
            type = 'error'
        })
        return
    end

    if job.onduty ~= true then
        notify(src, {
            title = 'Armory',
            message = 'Go on duty before claiming a kit.',
            type = 'warning'
        })
        return
    end

    local key = ('%s:%s'):format(src, tostring(kitId))
    local expiresAt = armoryCooldowns[key] or 0
    if expiresAt > now() then
        notify(src, {
            title = 'Armory',
            message = ('Please wait %s seconds before taking that kit again.'):format(expiresAt - now()),
            type = 'warning'
        })
        return
    end

    local selectedKit
    for _, item in ipairs(TC5Police.Config.Armory.Items or {}) do
        if item.id == kitId then
            selectedKit = item
            break
        end
    end

    if not selectedKit then return end
    if (job.grade or 0) < (selectedKit.minGrade or 0) then
        notify(src, {
            title = 'Armory',
            message = 'Your rank is too low for that kit.',
            type = 'error'
        })
        return
    end

    armoryCooldowns[key] = now() + (TC5Police.Config.Armory.CooldownSeconds or 5)
    TriggerClientEvent('tc5_policejob:client:applyLoadout', src, selectedKit.loadout or {}, selectedKit.label)
end)

RegisterNetEvent('tc5_policejob:server:spawnVehicle', function(vehicleId)
    local src = source
    local job = getJob(src)
    if not job or job.name ~= TC5Police.Config.JobName then return end
    if job.onduty ~= true then
        notify(src, {
            title = 'Garage',
            message = 'You must be on duty to take a vehicle out.',
            type = 'warning'
        })
        return
    end

    local selectedVehicle
    for _, vehicle in ipairs(TC5Police.Config.Garage.Vehicles or {}) do
        if vehicle.id == vehicleId then
            selectedVehicle = vehicle
            break
        end
    end

    if not selectedVehicle then return end
    if (job.grade or 0) < (selectedVehicle.minGrade or 0) then
        notify(src, {
            title = 'Garage',
            message = 'Your rank is too low for that vehicle.',
            type = 'error'
        })
        return
    end

    TriggerClientEvent('tc5_policejob:client:spawnVehicle', src, selectedVehicle)
end)

RegisterNetEvent('tc5_policejob:server:returnVehicle', function(netId)
    local src = source
    if not hasPoliceJob(src, 0) then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
        notify(src, {
            title = 'Garage',
            message = 'Vehicle stored.',
            type = 'success'
        })
    end
end)

RegisterCommand(TC5Police.Config.Commands.Recruit, function(src, args)
    if src == 0 then
        print('Use this command in-game.')
        return
    end

    if not hasPoliceJob(src, 4) then
        notify(src, {
            title = 'Police',
            message = 'Only command staff can hire officers.',
            type = 'error'
        })
        return
    end

    local targetId = tonumber(args[1] or 0)
    local badgeNumber = tostring(args[2] or '')
    local callsign = tostring(args[3] or '')

    if not targetId or targetId <= 0 then
        notify(src, {
            title = 'Police',
            message = ('Usage: /%s [id] [badge] [callsign]'):format(TC5Police.Config.Commands.Recruit),
            type = 'error'
        })
        return
    end

    if not GetPlayerName(targetId) then
        notify(src, {
            title = 'Police',
            message = 'Target player not found.',
            type = 'error'
        })
        return
    end

    local charId = getCharacterId(targetId)
    if not charId then
        notify(src, {
            title = 'Police',
            message = 'Target character is not loaded yet.',
            type = 'error'
        })
        return
    end

    local success, result = exports['tc5_jobs']:SetPlayerJob(targetId, TC5Police.Config.JobName, TC5Police.Config.DefaultGrade, false)
    if not success then
        notify(src, {
            title = 'Police',
            message = ('Failed to set police job: %s'):format(tostring(result)),
            type = 'error'
        })
        return
    end

    ensureProfile(charId, badgeNumber, callsign)

    notify(src, {
        title = 'Police',
        message = ('%s added to police.'):format(GetPlayerName(targetId)),
        type = 'success'
    })

    notify(targetId, {
        title = 'Police',
        message = 'You have been hired into the police department.',
        type = 'success'
    })

    syncOfficer(targetId)
end, false)

RegisterCommand(TC5Police.Config.Commands.SetGrade, function(src, args)
    if src == 0 then
        print('Use this command in-game.')
        return
    end

    if not hasPoliceJob(src, 4) then
        notify(src, {
            title = 'Police',
            message = 'Only command staff can change grades.',
            type = 'error'
        })
        return
    end

    local targetId = tonumber(args[1] or 0)
    local grade = tonumber(args[2] or -1)

    if not targetId or grade < 0 then
        notify(src, {
            title = 'Police',
            message = ('Usage: /%s [id] [grade]'):format(TC5Police.Config.Commands.SetGrade),
            type = 'error'
        })
        return
    end

    local success, result = exports['tc5_jobs']:SetPlayerJob(targetId, TC5Police.Config.JobName, grade)
    if not success then
        notify(src, {
            title = 'Police',
            message = ('Failed to change grade: %s'):format(tostring(result)),
            type = 'error'
        })
        return
    end

    notify(src, {
        title = 'Police',
        message = ('Officer grade updated to %s.'):format(result.gradeLabel),
        type = 'success'
    })

    notify(targetId, {
        title = 'Police',
        message = ('Your police grade is now %s.'):format(result.gradeLabel),
        type = 'info'
    })

    syncOfficer(targetId)
end, false)

RegisterCommand(TC5Police.Config.Commands.Fire, function(src, args)
    if src == 0 then
        print('Use this command in-game.')
        return
    end

    if not hasPoliceJob(src, 4) then
        notify(src, {
            title = 'Police',
            message = 'Only command staff can remove officers.',
            type = 'error'
        })
        return
    end

    local targetId = tonumber(args[1] or 0)
    if not targetId or targetId <= 0 then
        notify(src, {
            title = 'Police',
            message = ('Usage: /%s [id]'):format(TC5Police.Config.Commands.Fire),
            type = 'error'
        })
        return
    end

    local charId = getCharacterId(targetId)
    if charId then
        removeProfile(charId)
    end

    local success, result = exports['tc5_jobs']:SetPlayerJob(targetId, 'unemployed', 0, true)
    if not success then
        notify(src, {
            title = 'Police',
            message = ('Failed to remove officer: %s'):format(tostring(result)),
            type = 'error'
        })
        return
    end

    notify(src, {
        title = 'Police',
        message = 'Officer removed from police.',
        type = 'success'
    })

    notify(targetId, {
        title = 'Police',
        message = 'You have been removed from the police department.',
        type = 'warning'
    })

    syncOfficer(targetId)
end, false)

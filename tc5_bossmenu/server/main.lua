TC5BossMenu = TC5BossMenu or {}
TC5BossMenu.Server = TC5BossMenu.Server or {}

local function notify(src, payload)
    TriggerClientEvent('tc5_ui:client:notify', src, payload)
end

local function getPlayer(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function getPlayerData(src)
    return exports['tc5_core']:GetPlayerData(src)
end

local function getJob(src)
    local ok, result = pcall(function()
        return exports['tc5_jobs']:GetPlayerJob(src)
    end)

    if ok and type(result) == 'table' then
        return result
    end

    return {
        name = 'unemployed',
        label = 'Unemployed',
        grade = 0
    }
end

local function isBoss(src, jobName)
    local job = getJob(src)
    if job.name ~= jobName then
        return false
    end
    return (tonumber(job.grade) or 0) >= (TC5BossMenu.Config.BossGrades[jobName] or 99)
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_society_accounts (
            job_name VARCHAR(50) NOT NULL,
            balance INT NOT NULL DEFAULT 0,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (job_name)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_job_employees (
            id INT NOT NULL AUTO_INCREMENT,
            character_id INT NOT NULL,
            source_id INT NULL,
            full_name VARCHAR(100) NOT NULL,
            job_name VARCHAR(50) NOT NULL,
            grade INT NOT NULL DEFAULT 0,
            salary INT NOT NULL DEFAULT 250,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_tc5_job_employee (character_id, job_name),
            KEY idx_tc5_job_name (job_name)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_job_salaries (
            id INT NOT NULL AUTO_INCREMENT,
            job_name VARCHAR(50) NOT NULL,
            grade INT NOT NULL DEFAULT 0,
            salary INT NOT NULL DEFAULT 250,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_tc5_job_grade (job_name, grade)
        )
    ]])
end

local function getSocietyAccount(jobName)
    local row = MySQL.single.await('SELECT * FROM tc5_society_accounts WHERE job_name = ? LIMIT 1', { jobName })
    if not row then
        MySQL.insert.await('INSERT INTO tc5_society_accounts (job_name, balance) VALUES (?, 0)', { jobName })
        return { job_name = jobName, balance = 0 }
    end
    return row
end

local function setSocietyBalance(jobName, balance)
    MySQL.update.await('UPDATE tc5_society_accounts SET balance = ? WHERE job_name = ?', {
        math.max(0, math.floor(tonumber(balance) or 0)),
        jobName
    })
end

local function getEmployees(jobName)
    return MySQL.query.await('SELECT * FROM tc5_job_employees WHERE job_name = ? ORDER BY grade DESC, full_name ASC', {
        jobName
    }) or {}
end

local function getSalaries(jobName)
    return MySQL.query.await('SELECT * FROM tc5_job_salaries WHERE job_name = ? ORDER BY grade ASC', {
        jobName
    }) or {}
end

local function ensureDefaultSalary(jobName, grade)
    grade = math.max(0, math.floor(tonumber(grade) or 0))
    local row = MySQL.single.await('SELECT * FROM tc5_job_salaries WHERE job_name = ? AND grade = ? LIMIT 1', {
        jobName, grade
    })
    if not row then
        MySQL.insert.await('INSERT INTO tc5_job_salaries (job_name, grade, salary) VALUES (?, ?, ?)', {
            jobName, grade, TC5BossMenu.Config.DefaultSalary or 250
        })
    end
end

local function getSalaryForGrade(jobName, grade)
    ensureDefaultSalary(jobName, grade)
    local row = MySQL.single.await('SELECT salary FROM tc5_job_salaries WHERE job_name = ? AND grade = ? LIMIT 1', {
        jobName, math.max(0, math.floor(tonumber(grade) or 0))
    })
    return row and (tonumber(row.salary) or (TC5BossMenu.Config.DefaultSalary or 250)) or (TC5BossMenu.Config.DefaultSalary or 250)
end

local function upsertEmployee(characterId, sourceId, fullName, jobName, grade, salary)
    MySQL.insert.await([[
        INSERT INTO tc5_job_employees (character_id, source_id, full_name, job_name, grade, salary)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            source_id = VALUES(source_id),
            full_name = VALUES(full_name),
            grade = VALUES(grade),
            salary = VALUES(salary)
    ]], {
        characterId,
        sourceId,
        fullName,
        jobName,
        math.max(0, math.floor(tonumber(grade) or 0)),
        math.max(0, math.floor(tonumber(salary) or (TC5BossMenu.Config.DefaultSalary or 250)))
    })
end

local function removeEmployee(characterId, jobName)
    MySQL.update.await('DELETE FROM tc5_job_employees WHERE character_id = ? AND job_name = ?', {
        characterId, jobName
    })
end

local function getNearbyPlayerPayloads(src, range)
    local list = {}
    local ped = GetPlayerPed(src)
    if ped == 0 then return list end
    local srcCoords = GetEntityCoords(ped)
    range = tonumber(range) or (TC5BossMenu.Config.HireDistance or 4.0)

    for _, target in ipairs(GetPlayers()) do
        target = tonumber(target)
        if target ~= src then
            local tped = GetPlayerPed(target)
            if tped ~= 0 then
                local dist = #(srcCoords - GetEntityCoords(tped))
                if dist <= range then
                    local pdata = getPlayerData(target)
                    list[#list + 1] = {
                        source = target,
                        distance = dist,
                        fullName = pdata and pdata.character and pdata.character.fullName or GetPlayerName(target),
                        characterId = pdata and pdata.character and pdata.character.id or nil
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

local function trySetPlayerJob(targetSrc, jobName, grade)
    local attempts = {
        function() return exports['tc5_jobs']:SetPlayerJob(targetSrc, jobName, grade) end,
        function() return exports['tc5_jobs']:SetJob(targetSrc, jobName, grade) end,
        function() return exports['tc5_jobs']:SetPlayerJobGrade(targetSrc, jobName, grade) end
    }

    for i = 1, #attempts do
        local ok, result = pcall(attempts[i])
        if ok and result ~= false then
            return true
        end
    end

    return false
end

local function getBossState(src)
    local job = getJob(src)
    local account = getSocietyAccount(job.name)
    local employees = getEmployees(job.name)
    local salaries = getSalaries(job.name)

    return {
        job = job,
        society = {
            balance = tonumber(account.balance) or 0,
            bossStashId = ('boss_%s_stash'):format(job.name),
            societyStashId = ('society_%s_inventory'):format(job.name)
        },
        employees = employees,
        salaries = salaries
    }
end

RegisterNetEvent('tc5_bossmenu:server:open', function(jobName)
    local src = source
    local job = getJob(src)
    local targetJob = tostring(jobName or job.name)

    if not isBoss(src, targetJob) then
        notify(src, { title = 'Boss Menu', message = 'You do not have boss access.', type = 'error' })
        return
    end

    TriggerClientEvent('tc5_bossmenu:client:open', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:refresh', function()
    local src = source
    local job = getJob(src)
    if not isBoss(src, job.name) then return end
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:getNearbyPlayers', function()
    local src = source
    local job = getJob(src)
    if not isBoss(src, job.name) then return end
    TriggerClientEvent('tc5_bossmenu:client:setNearbyPlayers', src, getNearbyPlayerPayloads(src))
end)

RegisterNetEvent('tc5_bossmenu:server:hireNearby', function(targetSrc)
    local src = source
    targetSrc = tonumber(targetSrc)
    local bossJob = getJob(src)

    if not targetSrc or targetSrc == src then return end
    if not isBoss(src, bossJob.name) then return end

    local nearby = getNearbyPlayerPayloads(src)
    local valid = false
    local targetPayload = nil
    for i = 1, #nearby do
        if nearby[i].source == targetSrc then
            valid = true
            targetPayload = nearby[i]
            break
        end
    end

    if not valid or not targetPayload or not targetPayload.characterId then
        notify(src, { title = 'Boss Menu', message = 'Target is not nearby.', type = 'error' })
        return
    end

    local grade = TC5BossMenu.Config.DefaultHireGrade or 0
    local salary = getSalaryForGrade(bossJob.name, grade)

    local liveHooked = trySetPlayerJob(targetSrc, bossJob.name, grade)
    upsertEmployee(targetPayload.characterId, targetSrc, targetPayload.fullName or ('Character #' .. tostring(targetPayload.characterId)), bossJob.name, grade, salary)

    notify(src, { title = 'Boss Menu', message = ('Hired %s into %s.'):format(targetPayload.fullName or 'player', bossJob.label or bossJob.name), type = 'success' })
    notify(targetSrc, { title = 'Job', message = ('You were hired into %s.'):format(bossJob.label or bossJob.name), type = 'success' })

    if not liveHooked then
        notify(src, { title = 'Boss Menu', message = 'Employee table updated, but tc5_jobs live writeback export was not found.', type = 'warning' })
    end

    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:updateGrade', function(characterId, grade)
    local src = source
    local bossJob = getJob(src)
    characterId = tonumber(characterId)
    grade = math.max(0, math.floor(tonumber(grade) or 0))

    if not isBoss(src, bossJob.name) or not characterId then return end

    local employee = MySQL.single.await('SELECT * FROM tc5_job_employees WHERE character_id = ? AND job_name = ? LIMIT 1', {
        characterId, bossJob.name
    })
    if not employee then return end

    local salary = getSalaryForGrade(bossJob.name, grade)

    MySQL.update.await('UPDATE tc5_job_employees SET grade = ?, salary = ? WHERE character_id = ? AND job_name = ?', {
        grade, salary, characterId, bossJob.name
    })

    if employee.source_id and tonumber(employee.source_id) > 0 then
        trySetPlayerJob(tonumber(employee.source_id), bossJob.name, grade)
    end

    notify(src, { title = 'Boss Menu', message = 'Employee grade updated.', type = 'success' })
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:fireEmployee', function(characterId)
    local src = source
    local bossJob = getJob(src)
    characterId = tonumber(characterId)

    if not isBoss(src, bossJob.name) or not characterId then return end

    local employee = MySQL.single.await('SELECT * FROM tc5_job_employees WHERE character_id = ? AND job_name = ? LIMIT 1', {
        characterId, bossJob.name
    })
    if not employee then return end

    if employee.source_id and tonumber(employee.source_id) > 0 then
        trySetPlayerJob(tonumber(employee.source_id), 'unemployed', 0)
        notify(tonumber(employee.source_id), { title = 'Job', message = ('You were removed from %s.'):format(bossJob.label or bossJob.name), type = 'error' })
    end

    removeEmployee(characterId, bossJob.name)

    notify(src, { title = 'Boss Menu', message = 'Employee removed.', type = 'success' })
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:setSalary', function(grade, salary)
    local src = source
    local bossJob = getJob(src)
    grade = math.max(0, math.floor(tonumber(grade) or 0))
    salary = math.max(0, math.min(math.floor(tonumber(salary) or 0), TC5BossMenu.Config.MaxSalary or 5000))

    if not isBoss(src, bossJob.name) then return end

    MySQL.insert.await([[
        INSERT INTO tc5_job_salaries (job_name, grade, salary)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE salary = VALUES(salary)
    ]], {
        bossJob.name, grade, salary
    })

    MySQL.update.await('UPDATE tc5_job_employees SET salary = ? WHERE job_name = ? AND grade = ?', {
        salary, bossJob.name, grade
    })

    notify(src, { title = 'Boss Menu', message = ('Salary for grade %s set to $%s.'):format(grade, salary), type = 'success' })
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:deposit', function(amount)
    local src = source
    local player = getPlayer(src)
    local job = getJob(src)
    amount = math.floor(tonumber(amount) or 0)

    if not player or amount <= 0 or not isBoss(src, job.name) then return end
    if player:GetCash() < amount then
        notify(src, { title = 'Boss Menu', message = 'Not enough cash.', type = 'error' })
        return
    end

    local account = getSocietyAccount(job.name)
    player:RemoveCash(amount)
    player:SaveCharacter()
    setSocietyBalance(job.name, (tonumber(account.balance) or 0) + amount)

    notify(src, { title = 'Boss Menu', message = ('Deposited $%s into society.'):format(amount), type = 'success' })
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:withdraw', function(amount)
    local src = source
    local player = getPlayer(src)
    local job = getJob(src)
    amount = math.floor(tonumber(tonumber(amount) or 0))

    if not player or amount <= 0 or not isBoss(src, job.name) then return end

    local account = getSocietyAccount(job.name)
    local balance = tonumber(account.balance) or 0
    if balance < amount then
        notify(src, { title = 'Boss Menu', message = 'Society does not have enough money.', type = 'error' })
        return
    end

    setSocietyBalance(job.name, balance - amount)
    player:AddCash(amount)
    player:SaveCharacter()

    notify(src, { title = 'Boss Menu', message = ('Withdrew $%s from society.'):format(amount), type = 'success' })
    TriggerClientEvent('tc5_bossmenu:client:refresh', src, getBossState(src))
end)

RegisterNetEvent('tc5_bossmenu:server:openBossStash', function()
    local src = source
    local job = getJob(src)
    if not isBoss(src, job.name) then return end

    local stashId = ('boss_%s_stash'):format(job.name)
    exports['tc5_inventory']:RegisterStash(stashId, {
        label = ('%s Boss Stash'):format(job.label or job.name),
        owner = stashId,
        maxWeight = 250000,
        maxSlots = 80
    })
    exports['tc5_inventory']:OpenStash(src, stashId)
end)

RegisterNetEvent('tc5_bossmenu:server:openSocietyInventory', function()
    local src = source
    local job = getJob(src)
    if not isBoss(src, job.name) then return end

    local stashId = ('society_%s_inventory'):format(job.name)
    exports['tc5_inventory']:RegisterStash(stashId, {
        label = ('%s Society Inventory'):format(job.label or job.name),
        owner = stashId,
        maxWeight = 400000,
        maxSlots = 120
    })
    exports['tc5_inventory']:OpenStash(src, stashId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local charId = getCharacterId(src)
    if not charId then return end
    MySQL.update.await('UPDATE tc5_job_employees SET source_id = NULL WHERE character_id = ?', { charId })
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ensureTables()
end)

exports('IsBoss', function(src, jobName)
    return isBoss(src, jobName)
end)

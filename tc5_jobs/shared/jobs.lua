TC5Jobs = TC5Jobs or {}
TC5Jobs.Registry = TC5Jobs.Registry or {}

local function cloneTable(tbl)
    if type(tbl) ~= 'table' then return tbl end

    local cloned = {}
    for key, value in pairs(tbl) do
        if type(value) == 'table' then
            cloned[key] = cloneTable(value)
        else
            cloned[key] = value
        end
    end

    return cloned
end

local function normalizeGradeKey(key)
    local grade = tonumber(key)
    if grade == nil then
        return nil
    end

    return math.floor(grade)
end

local function normalizeJobDefinition(job)
    if type(job) ~= 'table' then
        return nil, 'job_definition_invalid'
    end

    local name = tostring(job.name or ''):lower()
    if name == '' then
        return nil, 'job_name_missing'
    end

    local grades = {}
    local inputGrades = job.grades or {}

    for key, gradeData in pairs(inputGrades) do
        local grade = normalizeGradeKey(key)
        if grade ~= nil then
            gradeData = type(gradeData) == 'table' and gradeData or {}
            grades[grade] = {
                label = tostring(gradeData.label or gradeData.name or ('Grade %s'):format(grade)),
                salary = math.floor(tonumber(gradeData.salary or gradeData.payment or 0) or 0),
                permissions = type(gradeData.permissions) == 'table' and cloneTable(gradeData.permissions) or {}
            }
        end
    end

    if not grades[0] then
        grades[0] = {
            label = 'Employee',
            salary = 0,
            permissions = {}
        }
    end

    return {
        name = name,
        label = tostring(job.label or name),
        type = tostring(job.type or 'job'),
        defaultDuty = job.defaultDuty ~= false,
        grades = grades,
        metadata = type(job.metadata) == 'table' and cloneTable(job.metadata) or {}
    }
end

function TC5Jobs.Debug(message)
    if not TC5Jobs.Config.Debug then return end
    print(('^3[tc5_jobs]^7 %s'):format(tostring(message)))
end

function TC5Jobs.RegisterJob(job)
    local normalized, err = normalizeJobDefinition(job)
    if not normalized then
        return false, err
    end

    TC5Jobs.Registry[normalized.name] = normalized
    TC5Jobs.Debug(('Registered dynamic job "%s"'):format(normalized.name))
    return true, cloneTable(normalized)
end

function TC5Jobs.GetJobs()
    return cloneTable(TC5Jobs.Registry)
end

function TC5Jobs.GetJobDefinition(jobName)
    if not jobName then return nil end
    return cloneTable(TC5Jobs.Registry[tostring(jobName):lower()])
end

function TC5Jobs.HasGrade(jobName, grade)
    local job = TC5Jobs.GetJobDefinition(jobName)
    if not job then return false end

    grade = math.floor(tonumber(grade) or 0)
    return job.grades[grade] ~= nil
end

function TC5Jobs.GetDefaultJobData()
    local defaultJob = TC5Jobs.GetJobDefinition(TC5Jobs.Config.DefaultJob)
    if defaultJob then
        return {
            name = defaultJob.name,
            label = defaultJob.label,
            grade = TC5Jobs.Config.DefaultGrade,
            gradeLabel = defaultJob.grades[TC5Jobs.Config.DefaultGrade] and defaultJob.grades[TC5Jobs.Config.DefaultGrade].label or 'Employee',
            salary = defaultJob.grades[TC5Jobs.Config.DefaultGrade] and defaultJob.grades[TC5Jobs.Config.DefaultGrade].salary or 0,
            onduty = defaultJob.defaultDuty
        }
    end

    return {
        name = TC5Jobs.Config.DefaultJob,
        label = 'Unemployed',
        grade = TC5Jobs.Config.DefaultGrade,
        gradeLabel = 'Citizen',
        salary = 0,
        onduty = TC5Jobs.Config.DefaultDuty
    }
end

TC5Jobs.RegisterJob({
    name = 'unemployed',
    label = 'Unemployed',
    defaultDuty = true,
    grades = {
        [0] = {
            label = 'Citizen',
            salary = 0
        }
    }
})

TC5Jobs.RegisterJob({
    name = 'police',
    label = 'Police',
    defaultDuty = false,
    grades = {
        [0] = { label = 'Cadet', salary = 250 },
        [1] = { label = 'Officer', salary = 400 },
        [2] = { label = 'Senior Officer', salary = 550 },
        [3] = { label = 'Sergeant', salary = 700 },
        [4] = { label = 'Lieutenant', salary = 900 },
        [5] = { label = 'Chief', salary = 1200 }
    },
    metadata = {
        department = 'lspd'
    }
})

TC5Doorlock = TC5Doorlock or {}
TC5Doorlock.Server = TC5Doorlock.Server or {}
TC5Doorlock.Server.Doors = TC5Doorlock.Server.Doors or {}

local function notify(src, payload)
    TriggerClientEvent('tc5_ui:client:notify', src, payload)
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function getPlayerData(src)
    return exports['tc5_core']:GetPlayerData(src)
end

local function getJobData(src)
    local ok, result = pcall(function()
        return exports['tc5_jobs']:GetPlayerJob(src)
    end)
    if ok and type(result) == 'table' then return result end
    return { name = 'unemployed', grade = 0 }
end

local function normalizeAccess(access)
    access = type(access) == 'table' and access or {}
    access.jobs = type(access.jobs) == 'table' and access.jobs or {}
    access.gangs = type(access.gangs) == 'table' and access.gangs or {}
    access.characters = type(access.characters) == 'table' and access.characters or {}
    return access
end

local function decode(data)
    if not data or data == '' then return {} end
    local ok, result = pcall(json.decode, data)
    return ok and type(result) == 'table' and result or {}
end

local function mapDoorRow(row)
    return {
        id = row.id,
        name = row.name,
        model = tonumber(row.model) or row.model,
        coords = { x = tonumber(row.x) or 0.0, y = tonumber(row.y) or 0.0, z = tonumber(row.z) or 0.0 },
        heading = tonumber(row.heading) or 0.0,
        locked = row.locked == 1,
        double = row.is_double == 1,
        second = decode(row.second_door),
        distance = tonumber(row.interact_distance) or TC5Doorlock.Config.MaxDistance,
        autoLock = row.auto_lock == 1,
        lockpickable = row.lockpickable == 1,
        doorRate = tonumber(row.door_rate) or 1.0,
        doorType = row.door_type or 'standard',
        rollerOpenRatio = tonumber(row.roller_open_ratio) or TC5Doorlock.Config.RollerDefaultOpenRatio,
        access = normalizeAccess(decode(row.access_json)),
        createdBy = row.created_by_char_id
    }
end

local function loadDoors()
    local rows = MySQL.query.await('SELECT * FROM tc5_doors ORDER BY id ASC') or {}
    TC5Doorlock.Server.Doors = {}
    for i = 1, #rows do
        local door = mapDoorRow(rows[i])
        TC5Doorlock.Server.Doors[door.id] = door
    end
end

local function getAdminDoorList()
    local list = {}
    for id, door in pairs(TC5Doorlock.Server.Doors) do
        list[#list + 1] = {
            id = id,
            name = door.name,
            model = door.model,
            locked = door.locked,
            coords = door.coords,
            distance = door.distance,
            doorType = door.doorType or 'standard'
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function TC5Doorlock.Server.HasDoorAccess(src, doorId)
    local door = TC5Doorlock.Server.Doors[tonumber(doorId)]
    if not door then return false end
    if IsPlayerAceAllowed(src, TC5Doorlock.Config.AdminAce) then return true end

    local charId = getCharacterId(src)
    local playerData = getPlayerData(src)
    local job = getJobData(src)
    local access = normalizeAccess(door.access)

    if charId and access.characters[tostring(charId)] then return true end

    local jobMinGrade = access.jobs[tostring(job.name or '')]
    if jobMinGrade ~= nil and (job.grade or 0) >= tonumber(jobMinGrade or 0) then
        return true
    end

    local gangName = playerData and playerData.character and playerData.character.gangName
    local gangGrade = playerData and playerData.character and playerData.character.gangGrade or 0
    local gangMinGrade = access.gangs[tostring(gangName or '')]
    if gangMinGrade ~= nil and (tonumber(gangGrade) or 0) >= tonumber(gangMinGrade or 0) then
        return true
    end

    return false
end

function TC5Doorlock.Server.SetDoorState(doorId, locked)
    local door = TC5Doorlock.Server.Doors[tonumber(doorId)]
    if not door then return false, 'door_not_found' end

    door.locked = locked == true
    MySQL.update.await('UPDATE tc5_doors SET locked = ? WHERE id = ?', {
        door.locked and 1 or 0,
        tonumber(doorId)
    })

    TriggerClientEvent('tc5_doorlock:client:updateDoorState', -1, tonumber(doorId), door.locked)
    return true, door
end

RegisterNetEvent('tc5_doorlock:server:requestDoors', function()
    TriggerClientEvent('tc5_doorlock:client:setDoors', source, TC5Doorlock.Server.Doors)
end)

RegisterNetEvent('tc5_doorlock:server:openManager', function()
    local src = source
    if not IsPlayerAceAllowed(src, TC5Doorlock.Config.AdminAce) then
        notify(src, { title='Doorlock', message='No permission.', type='error', duration=2500 })
        return
    end
    TriggerClientEvent('tc5_doorlock:client:openManager', src, { doors = getAdminDoorList() })
end)

RegisterNetEvent('tc5_doorlock:server:toggleDoor', function(doorId)
    local src = source
    doorId = tonumber(doorId)
    if not TC5Doorlock.Server.HasDoorAccess(src, doorId) then
        notify(src, { title='Doorlock', message='You do not have access to this door.', type='error', duration=2500 })
        return
    end
    local door = TC5Doorlock.Server.Doors[doorId]
    if not door then return end
    local ok, updated = TC5Doorlock.Server.SetDoorState(doorId, not door.locked)
    if ok then
        notify(src, { title='Doorlock', message=updated.locked and 'Door locked.' or 'Door unlocked.', type='success', duration=1800 })
    end
end)

RegisterNetEvent('tc5_doorlock:server:createDoor', function(payload)
    local src = source
    if not IsPlayerAceAllowed(src, TC5Doorlock.Config.AdminAce) then return end
    local charId = getCharacterId(src)
    payload = payload or {}
    local access = normalizeAccess(payload.access)

    local id = MySQL.insert.await([[
        INSERT INTO tc5_doors (
            name, model, x, y, z, heading, locked, is_double, second_door,
            interact_distance, auto_lock, lockpickable, door_rate,
            access_json, created_by_char_id, door_type, roller_open_ratio
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        tostring(payload.name or 'New Door'),
        tostring(payload.model or 0),
        tonumber(payload.coords and payload.coords.x) or 0.0,
        tonumber(payload.coords and payload.coords.y) or 0.0,
        tonumber(payload.coords and payload.coords.z) or 0.0,
        tonumber(payload.heading) or 0.0,
        payload.locked ~= false and 1 or 0,
        payload.double == true and 1 or 0,
        json.encode(payload.second or {}),
        tonumber(payload.distance) or TC5Doorlock.Config.MaxDistance,
        payload.autoLock == true and 1 or 0,
        payload.lockpickable == true and 1 or 0,
        tonumber(payload.doorRate) or TC5Doorlock.Config.DefaultDoorRate,
        json.encode(access),
        charId,
        tostring(payload.doorType or 'standard'),
        tonumber(payload.rollerOpenRatio) or TC5Doorlock.Config.RollerDefaultOpenRatio
    })

    loadDoors()
    TriggerClientEvent('tc5_doorlock:client:setDoors', -1, TC5Doorlock.Server.Doors)
    TriggerClientEvent('tc5_doorlock:client:refreshManagerDoors', src, getAdminDoorList())
    notify(src, { title='Doorlock', message=('Door created (#%s).'):format(id), type='success', duration=2500 })
end)

RegisterNetEvent('tc5_doorlock:server:updateDoor', function(doorId, payload)
    local src = source
    if not IsPlayerAceAllowed(src, TC5Doorlock.Config.AdminAce) then return end
    payload = payload or {}
    local access = normalizeAccess(payload.access)

    MySQL.update.await([[
        UPDATE tc5_doors
        SET name=?, model=?, x=?, y=?, z=?, heading=?, locked=?, is_double=?, second_door=?, interact_distance=?, auto_lock=?, lockpickable=?, door_rate=?, access_json=?, door_type=?, roller_open_ratio=?
        WHERE id=?
    ]], {
        tostring(payload.name or 'Door'),
        tostring(payload.model or 0),
        tonumber(payload.coords and payload.coords.x) or 0.0,
        tonumber(payload.coords and payload.coords.y) or 0.0,
        tonumber(payload.coords and payload.coords.z) or 0.0,
        tonumber(payload.heading) or 0.0,
        payload.locked ~= false and 1 or 0,
        payload.double == true and 1 or 0,
        json.encode(payload.second or {}),
        tonumber(payload.distance) or TC5Doorlock.Config.MaxDistance,
        payload.autoLock == true and 1 or 0,
        payload.lockpickable == true and 1 or 0,
        tonumber(payload.doorRate) or TC5Doorlock.Config.DefaultDoorRate,
        json.encode(access),
        tostring(payload.doorType or 'standard'),
        tonumber(payload.rollerOpenRatio) or TC5Doorlock.Config.RollerDefaultOpenRatio,
        tonumber(doorId)
    })

    loadDoors()
    TriggerClientEvent('tc5_doorlock:client:setDoors', -1, TC5Doorlock.Server.Doors)
    TriggerClientEvent('tc5_doorlock:client:refreshManagerDoors', src, getAdminDoorList())
    notify(src, { title='Doorlock', message=('Door #%s updated.'):format(doorId), type='success', duration=2500 })
end)

RegisterNetEvent('tc5_doorlock:server:deleteDoor', function(doorId)
    local src = source
    if not IsPlayerAceAllowed(src, TC5Doorlock.Config.AdminAce) then return end
    MySQL.update.await('DELETE FROM tc5_doors WHERE id = ?', { tonumber(doorId) or 0 })
    loadDoors()
    TriggerClientEvent('tc5_doorlock:client:setDoors', -1, TC5Doorlock.Server.Doors)
    TriggerClientEvent('tc5_doorlock:client:refreshManagerDoors', src, getAdminDoorList())
    notify(src, { title='Doorlock', message=('Door #%s deleted.'):format(tostring(doorId)), type='success', duration=2500 })
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_doors (
            id INT NOT NULL AUTO_INCREMENT,
            name VARCHAR(100) NOT NULL,
            model VARCHAR(50) NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            heading DOUBLE NOT NULL DEFAULT 0,
            locked TINYINT(1) NOT NULL DEFAULT 1,
            is_double TINYINT(1) NOT NULL DEFAULT 0,
            second_door LONGTEXT NULL,
            interact_distance DOUBLE NOT NULL DEFAULT 2.5,
            auto_lock TINYINT(1) NOT NULL DEFAULT 0,
            lockpickable TINYINT(1) NOT NULL DEFAULT 0,
            door_rate DOUBLE NOT NULL DEFAULT 1.0,
            access_json LONGTEXT NULL,
            created_by_char_id INT NULL,
            door_type VARCHAR(20) NOT NULL DEFAULT 'standard',
            roller_open_ratio DOUBLE NOT NULL DEFAULT 1.0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]])

    local cols = MySQL.query.await("SHOW COLUMNS FROM tc5_doors LIKE 'door_type'") or {}
    if #cols == 0 then
        MySQL.query.await("ALTER TABLE tc5_doors ADD COLUMN door_type VARCHAR(20) NOT NULL DEFAULT 'standard'")
    end

    cols = MySQL.query.await("SHOW COLUMNS FROM tc5_doors LIKE 'roller_open_ratio'") or {}
    if #cols == 0 then
        MySQL.query.await("ALTER TABLE tc5_doors ADD COLUMN roller_open_ratio DOUBLE NOT NULL DEFAULT 1.0")
    end

    loadDoors()
end)

exports('GetDoor', function(doorId) return TC5Doorlock.Server.Doors[tonumber(doorId)] end)
exports('SetDoorState', function(doorId, locked) return TC5Doorlock.Server.SetDoorState(doorId, locked) end)
exports('HasDoorAccess', function(src, doorId) return TC5Doorlock.Server.HasDoorAccess(src, doorId) end)

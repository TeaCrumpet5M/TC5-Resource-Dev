local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function getPedCoordsSafe(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    return coords, heading
end

local function ensureTable()
    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS tc5_last_locations (
            character_id INT NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            w DOUBLE NOT NULL DEFAULT 0,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (character_id)
        )
    ]])
end

local function saveLastLocation(src)
    local characterId = getCharacterId(src)
    if not characterId then return false end

    local coords, heading = getPedCoordsSafe(src)
    if not coords then return false end

    ensureTable()
    MySQL.insert.await([[ 
        INSERT INTO tc5_last_locations (character_id, x, y, z, w) 
        VALUES (?, ?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE x = VALUES(x), y = VALUES(y), z = VALUES(z), w = VALUES(w) 
    ]], {
        characterId,
        coords.x,
        coords.y,
        coords.z,
        heading or 0.0
    })

    return true
end

exports('SaveLastLocation', function(src)
    return saveLastLocation(src)
end)

exports('GetLastLocation', function(src)
    local characterId = getCharacterId(src)
    if not characterId then return nil end

    ensureTable()
    local row = MySQL.single.await('SELECT * FROM tc5_last_locations WHERE character_id = ? LIMIT 1', { characterId })
    if not row then return nil end

    return {
        label = 'Last Location',
        x = tonumber(row.x) or 0.0,
        y = tonumber(row.y) or 0.0,
        z = tonumber(row.z) or 0.0,
        w = tonumber(row.w) or 0.0
    }
end)

RegisterNetEvent('tc5_spawn:server:requestLastLocation', function()
    local src = source
    TriggerClientEvent('tc5_spawn:client:setLastLocation', src, exports['tc5_spawn']:GetLastLocation(src))
end)

AddEventHandler('playerDropped', function()
    saveLastLocation(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ensureTable()
end)

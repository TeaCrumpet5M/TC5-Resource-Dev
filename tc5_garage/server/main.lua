TC5Garage = TC5Garage or {}
TC5Garage.Server = {}

local function normalizePlate(plate)
    return string.upper(tostring(plate or ''):gsub('%s+', ''))
end

local function getCharId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

function TC5Garage.Server.CreateOwnedVehicle(src, data)
    local charId = getCharId(src)
    if not charId then return false end

    local plate = normalizePlate(data.plate)
    local model = data.model

    local exists = MySQL.single.await(
        'SELECT id FROM tc5_owned_vehicles WHERE plate = ?',
        { plate }
    )

    if exists then
        return false, 'plate_exists'
    end

    local id = MySQL.insert.await([[
        INSERT INTO tc5_owned_vehicles
        (owner_char_id, plate, model, garage_id, stored)
        VALUES (?, ?, ?, ?, 1)
    ]], {
        charId,
        plate,
        model,
        TC5Garage.Config.DefaultGarage
    })

    MySQL.insert.await([[
        INSERT INTO tc5_vehicle_keys (vehicle_id, char_id, is_temporary)
        VALUES (?, ?, 0)
    ]], { id, charId })

    return true, id
end

function TC5Garage.Server.GiveVehicleKey(src, target, plate)
    local charId = getCharId(target)
    if not charId then return false end

    plate = normalizePlate(plate)

    local row = MySQL.single.await(
        'SELECT id FROM tc5_owned_vehicles WHERE plate = ?',
        { plate }
    )

    if not row then return false end

    MySQL.insert.await([[
        INSERT IGNORE INTO tc5_vehicle_keys (vehicle_id, char_id, is_temporary)
        VALUES (?, ?, 0)
    ]], { row.id, charId })

    return true
end

function TC5Garage.Server.HasVehicleAccess(src, plate)
    local charId = getCharId(src)
    if not charId then return false end

    plate = normalizePlate(plate)

    local row = MySQL.single.await(
        'SELECT id, owner_char_id FROM tc5_owned_vehicles WHERE plate = ?',
        { plate }
    )

    if not row then
        return true
    end

    if row.owner_char_id == charId then
        return true
    end

    local key = MySQL.single.await([[
        SELECT id FROM tc5_vehicle_keys
        WHERE vehicle_id = ? AND char_id = ?
    ]], { row.id, charId })

    return key ~= nil
end

exports('CreateOwnedVehicle', function(src, data)
    return TC5Garage.Server.CreateOwnedVehicle(src, data)
end)

exports('GiveVehicleKey', function(src, target, plate)
    return TC5Garage.Server.GiveVehicleKey(src, target, plate)
end)

exports('HasVehicleAccess', function(src, plate)
    return TC5Garage.Server.HasVehicleAccess(src, plate)
end)

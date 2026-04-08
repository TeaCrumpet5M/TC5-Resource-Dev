local function getPlayerData(src)
    return exports['tc5_core']:GetPlayerData(src)
end

local function mapApartment(row)
    if not row then return nil end
    return {
        id = row.id,
        label = row.apartment_label,
        apartment_label = row.apartment_label,
        shell_type = row.shell_type,
        entrance = {
            x = tonumber(row.entry_x) or 0.0,
            y = tonumber(row.entry_y) or 0.0,
            z = tonumber(row.entry_z) or 0.0,
            w = tonumber(row.entry_w) or 0.0
        },
        interior = {
            x = tonumber(row.interior_x) or 0.0,
            y = tonumber(row.interior_y) or 0.0,
            z = tonumber(row.interior_z) or 0.0,
            w = tonumber(row.interior_w) or 0.0
        }
    }
end

local function getApartmentByCharacterId(characterId)
    return MySQL.single.await('SELECT * FROM tc5_apartments WHERE character_id = ? LIMIT 1', {
        characterId
    })
end

local function getApartmentPool()
    return TC5Apartment.Config.ApartmentPool or {}
end

local function getAssignedPoolIndex(characterId)
    local pool = getApartmentPool()
    if #pool == 0 then return nil end
    return ((tonumber(characterId) or 1) % #pool) + 1
end

local function createApartmentFromPool(src, selectionIndex)
    local playerData = getPlayerData(src)
    if not playerData or not playerData.character then return nil end

    local characterId = playerData.character.id
    local existing = getApartmentByCharacterId(characterId)
    if existing then
        exports['tc5_core']:SetCharacterApartment(src, existing.id)
        return mapApartment(existing)
    end

    local pool = getApartmentPool()
    if #pool == 0 then return nil end

    local index = tonumber(selectionIndex) or getAssignedPoolIndex(characterId) or 1
    if not pool[index] then
        index = getAssignedPoolIndex(characterId) or 1
    end

    local selected = pool[index]
    local insertId = MySQL.insert.await([[
        INSERT INTO tc5_apartments (
            character_id,
            apartment_label,
            shell_type,
            entry_x, entry_y, entry_z, entry_w,
            interior_x, interior_y, interior_z, interior_w
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        characterId,
        selected.label,
        selected.shell_type or 'basic',
        selected.entry.x, selected.entry.y, selected.entry.z, selected.entry.w,
        selected.interior.x, selected.interior.y, selected.interior.z, selected.interior.w
    })

    exports['tc5_core']:SetCharacterApartment(src, insertId)
    return mapApartment(MySQL.single.await('SELECT * FROM tc5_apartments WHERE id = ? LIMIT 1', { insertId }))
end

local function buildApartmentStashId(characterId)
    return ('apartment_%s_stash'):format(characterId)
end

local function openApartmentStash(src)
    local playerData = getPlayerData(src)
    if not playerData or not playerData.character then return false end

    local apartment = mapApartment(getApartmentByCharacterId(playerData.character.id))
    if not apartment then return false end

    local stashId = buildApartmentStashId(playerData.character.id)

    exports['tc5_inventory']:RegisterStash(stashId, {
        label = ('%s Stash'):format(apartment.label or 'Apartment'),
        owner = stashId,
        maxSlots = TC5Apartment.Config.StashSlots or 40,
        maxWeight = TC5Apartment.Config.StashWeight or 100000
    })

    return exports['tc5_inventory']:OpenStash(src, stashId)
end

exports('CreateStarterApartment', function(src, selectionIndex)
    return createApartmentFromPool(src, selectionIndex)
end)

exports('GetApartmentChoices', function()
    local pool = getApartmentPool()
    local result = {}

    for i = 1, #pool do
        result[#result + 1] = {
            id = i,
            label = pool[i].label,
            entrance = {
                x = pool[i].entry.x,
                y = pool[i].entry.y,
                z = pool[i].entry.z,
                w = pool[i].entry.w
            },
            interior = {
                x = pool[i].interior.x,
                y = pool[i].interior.y,
                z = pool[i].interior.z,
                w = pool[i].interior.w
            }
        }
    end

    return result
end)

RegisterNetEvent('tc5_apartment:server:request', function()
    local src = source
    local playerData = getPlayerData(src)

    if not playerData or not playerData.character then
        TriggerClientEvent('tc5_apartment:client:setApartment', src, nil)
        return
    end

    local apartment = getApartmentByCharacterId(playerData.character.id)
    if not apartment then
        local choices = exports['tc5_apartment']:GetApartmentChoices()
        TriggerClientEvent('tc5_apartment:client:openSelection', src, choices)
        return
    end

    TriggerClientEvent('tc5_apartment:client:setApartment', src, mapApartment(apartment))
end)

RegisterNetEvent('tc5_apartment:server:selectApartment', function(selectionIndex)
    local src = source
    local apartment = createApartmentFromPool(src, selectionIndex)
    if apartment then
        TriggerClientEvent('tc5_apartment:client:setApartment', src, apartment)
        TriggerClientEvent('tc5_apartment:client:selectionComplete', src, apartment)
    end
end)

RegisterNetEvent('tc5_apartment:server:enter', function()
    local src = source
    local playerData = getPlayerData(src)
    if not playerData or not playerData.character then return end

    local apartment = mapApartment(getApartmentByCharacterId(playerData.character.id))
    if apartment then
        TriggerClientEvent('tc5_apartment:client:enter', src, apartment)
    end
end)

RegisterNetEvent('tc5_apartment:server:exit', function()
    local src = source
    local playerData = getPlayerData(src)
    if not playerData or not playerData.character then return end

    local apartment = mapApartment(getApartmentByCharacterId(playerData.character.id))
    if apartment then
        TriggerClientEvent('tc5_apartment:client:exit', src, apartment)
    end
end)

RegisterNetEvent('tc5_apartment:server:openStash', function()
    local src = source
    local ok = openApartmentStash(src)
    if not ok then
        TriggerClientEvent('tc5_ui:client:notify', src, {
            title = 'Apartment',
            message = 'Failed to open apartment stash.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('tc5_apartment:server:openWardrobe', function()
    local src = source

    if GetResourceState('illenium-appearance') == 'started' then
        TriggerClientEvent('illenium-appearance:client:openOutfitMenu', src)
        return
    end

    if GetResourceState('qb-clothing') == 'started' then
        TriggerClientEvent('qb-clothing:client:openOutfitMenu', src)
        return
    end

    TriggerClientEvent('tc5_apartment:client:wardrobeFallback', src)
end)

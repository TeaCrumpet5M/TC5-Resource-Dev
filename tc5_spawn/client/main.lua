local selectorOpen = false
local apartmentData = nil
local apartmentChoices = {}
local pendingSpawnData = nil
local lastLocation = nil

local function postUI(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function closeSelector()
    selectorOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    postUI('close', {})
end

local function closeLoading()
    if exports['tc5_ui'] and exports['tc5_ui'].CloseLoading then
        exports['tc5_ui']:CloseLoading()
    end
end

local function buildApartmentSpawns()
    local entries = {}

    for i = 1, #(apartmentChoices or {}) do
        local apartment = apartmentChoices[i]
        entries[#entries + 1] = {
            label = apartment.label or apartment.apartment_label or ('Apartment #' .. tostring(apartment.id)),
            description = 'Spawn outside this apartment entrance.',
            category = 'apartments',
            x = apartment.entrance.x,
            y = apartment.entrance.y,
            z = apartment.entrance.z,
            w = apartment.entrance.w
        }

        if apartment.interior then
            entries[#entries + 1] = {
                label = (apartment.label or apartment.apartment_label or ('Apartment #' .. tostring(apartment.id))) .. ' Interior',
                description = 'Spawn directly inside this apartment.',
                category = 'apartments',
                x = apartment.interior.x,
                y = apartment.interior.y,
                z = apartment.interior.z,
                w = apartment.interior.w
            }
        end
    end

    return entries
end

local function buildStarterSpawns()
    local spawns = {
        { label = 'Airport', description = 'Fast travel start near the airport.', category = 'city', x = -1037.76, y = -2737.88, z = 20.17, w = 328.24 },
        { label = 'Legion Square', description = 'Central city spawn close to transport.', category = 'city', x = 215.81, y = -810.12, z = 30.73, w = 157.20 },
        { label = 'Alta Street', description = 'Downtown starter spawn.', category = 'city', x = -269.62, y = -957.87, z = 31.22, w = 205.16 }
    }

    if lastLocation then
        table.insert(spawns, 1, {
            label = lastLocation.label or 'Last Location',
            description = 'Spawn where you last logged out.',
            category = 'recent',
            x = lastLocation.x,
            y = lastLocation.y,
            z = lastLocation.z,
            w = lastLocation.w
        })
    end

    local apartmentSpawns = buildApartmentSpawns()
    for i = 1, #apartmentSpawns do
        table.insert(spawns, i, apartmentSpawns[i])
    end

    return spawns
end

local function openSpawnSelector()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)
    Wait(250)

    selectorOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    postUI('open', {
        apartment = apartmentData,
        apartments = apartmentChoices,
        starterSpawns = buildStarterSpawns()
    })
end

RegisterNetEvent('tc5_spawn:client:prepareSpawn', function(data)
    pendingSpawnData = data or {}
    lastLocation = nil
    apartmentData = nil
    apartmentChoices = {}

    if pendingSpawnData.firstTime then
        closeLoading()
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        Wait(250)
        TriggerEvent('tc5_creator:client:open', {})
        return
    end

    TriggerServerEvent('tc5_apartment:server:request')
    TriggerServerEvent('tc5_spawn:server:requestLastLocation')

    CreateThread(function()
        Wait(700)
        openSpawnSelector()
    end)
end)

RegisterNetEvent('tc5_spawn:client:creatorFinished', function()
    closeLoading()
    apartmentData = nil
    apartmentChoices = {}

    TriggerServerEvent('tc5_apartment:server:request')
    TriggerServerEvent('tc5_spawn:server:requestLastLocation')

    CreateThread(function()
        Wait(700)
        openSpawnSelector()
    end)
end)

RegisterNetEvent('tc5_spawn:client:forceClose', function()
    closeSelector()
end)

RegisterNetEvent('tc5_spawn:client:setLastLocation', function(data)
    lastLocation = data
end)

RegisterNetEvent('tc5_apartment:client:setApartment', function(data)
    apartmentData = data

    if type(data) == 'table' and data.entrance and data.interior then
        apartmentChoices = { data }
    elseif type(data) == 'table' and data[1] then
        apartmentChoices = data
        apartmentData = data[1]
    end
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    closeSelector()
    TriggerEvent('tc5_creator:client:forceClose')
    TriggerEvent('tc5_core:client:spawnPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    closeSelector()
    cb({ ok = true })
end)

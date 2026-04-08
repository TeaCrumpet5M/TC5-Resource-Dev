TC5Eye = TC5Eye or {}
TC5Eye.Client = TC5Eye.Client or {}

TC5Eye.Client.Zones = {}
TC5Eye.Client.EntityOptions = {}
TC5Eye.Client.ModelOptions = {}
TC5Eye.Client.IsOpen = false
TC5Eye.Client.CurrentContext = nil
TC5Eye.Client.NextZoneId = 0

local function debugPrint(message)
    if not TC5Eye.Config.Debug then return end
    print(('^3[tc5_eye]^7 %s'):format(tostring(message)))
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function setOpen(state)
    TC5Eye.Client.IsOpen = state == true
    SetNuiFocus(false, false)
    send(state and 'open' or 'close', {})
end

local function getDistance(a, b)
    return #(a - b)
end

local function buildOptionPayload(option, entity, coords, zoneId)
    return {
        id = option.id or option.label,
        label = option.label or 'Interact',
        icon = option.icon or '•',
        event = option.event,
        serverEvent = option.serverEvent,
        command = option.command,
        data = option.data or {},
        entity = entity,
        coords = coords,
        zoneId = zoneId
    }
end

local function canUseOption(option, entity, distance)
    if option.distance and distance > option.distance then
        return false
    end

    if option.canInteract and type(option.canInteract) == 'function' then
        local ok, result = pcall(option.canInteract, entity, distance, option.data)
        if ok then
            return result == true
        end
        return false
    end

    return true
end

local function getZoneOptions()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local options = {}

    for zoneId, zone in pairs(TC5Eye.Client.Zones) do
        local dist = getDistance(coords, zone.coords)
        if dist <= (zone.radius or 2.0) then
            for i = 1, #(zone.options or {}) do
                local option = zone.options[i]
                if canUseOption(option, 0, dist) then
                    options[#options + 1] = buildOptionPayload(option, 0, { x = zone.coords.x, y = zone.coords.y, z = zone.coords.z }, zoneId)
                end
            end
        end
    end

    return options
end

local function getEntityTarget()
    local hit, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if hit and entity and entity ~= 0 then
        return entity
    end

    local coords = GetGameplayCamCoord()
    local destination = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 6.0, 0.0)
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 10, PlayerPedId(), 0)
    local _, hitResult, _, _, targetEntity = GetShapeTestResult(ray)

    if hitResult == 1 and targetEntity and targetEntity ~= 0 then
        return targetEntity
    end

    return 0
end

local function getEntityOptions()
    local entity = getEntityTarget()
    if entity == 0 then return {}, 0 end

    local coords = GetEntityCoords(entity)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local distance = #(pedCoords - coords)
    if distance > (TC5Eye.Config.MaxDistance or 6.0) then
        return {}, 0
    end

    local options = {}

    local netId = NetworkGetNetworkIdFromEntity(entity)
    local directOptions = TC5Eye.Client.EntityOptions[netId]
    if directOptions then
        for i = 1, #directOptions do
            local option = directOptions[i]
            if canUseOption(option, entity, distance) then
                options[#options + 1] = buildOptionPayload(option, entity, { x = coords.x, y = coords.y, z = coords.z }, nil)
            end
        end
    end

    local model = GetEntityModel(entity)
    local modelOptions = TC5Eye.Client.ModelOptions[model]
    if modelOptions then
        for i = 1, #modelOptions do
            local option = modelOptions[i]
            if canUseOption(option, entity, distance) then
                options[#options + 1] = buildOptionPayload(option, entity, { x = coords.x, y = coords.y, z = coords.z }, nil)
            end
        end
    end

    return options, entity
end

local function refreshEye()
    local zoneOptions = getZoneOptions()
    local entityOptions, entity = getEntityOptions()

    local all = {}
    for i = 1, #zoneOptions do all[#all + 1] = zoneOptions[i] end
    for i = 1, #entityOptions do all[#all + 1] = entityOptions[i] end

    TC5Eye.Client.CurrentContext = {
        options = all,
        entity = entity
    }

    send('setOptions', {
        options = all
    })

    if #all > 0 then
        setOpen(true)
    else
        setOpen(false)
    end
end

local function handleSelection(data)
    if not data then return end
    local selected
    local ctx = TC5Eye.Client.CurrentContext
    if not ctx or not ctx.options then return end

    for i = 1, #ctx.options do
        if tostring(ctx.options[i].id) == tostring(data.id) then
            selected = ctx.options[i]
            break
        end
    end

    if not selected then return end

    if selected.event then
        TriggerEvent(selected.event, selected)
    elseif selected.serverEvent then
        TriggerServerEvent(selected.serverEvent, selected)
    elseif selected.command then
        ExecuteCommand(selected.command)
    end
end

exports('AddBoxZone', function(data)
    TC5Eye.Client.NextZoneId = TC5Eye.Client.NextZoneId + 1
    local zoneId = data.id or ('zone_' .. TC5Eye.Client.NextZoneId)

    TC5Eye.Client.Zones[zoneId] = {
        id = zoneId,
        coords = data.coords,
        radius = data.radius or 2.0,
        options = data.options or {}
    }

    return zoneId
end)

exports('AddEntityOption', function(entity, options)
    if not DoesEntityExist(entity) then return false end
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TC5Eye.Client.EntityOptions[netId] = TC5Eye.Client.EntityOptions[netId] or {}
    for i = 1, #options do
        TC5Eye.Client.EntityOptions[netId][#TC5Eye.Client.EntityOptions[netId] + 1] = options[i]
    end
    return true
end)

exports('AddModelOption', function(model, options)
    local modelHash = type(model) == 'number' and model or joaat(model)
    TC5Eye.Client.ModelOptions[modelHash] = TC5Eye.Client.ModelOptions[modelHash] or {}
    for i = 1, #options do
        TC5Eye.Client.ModelOptions[modelHash][#TC5Eye.Client.ModelOptions[modelHash] + 1] = options[i]
    end
    return true
end)

exports('RemoveZone', function(zoneId)
    TC5Eye.Client.Zones[zoneId] = nil
end)

exports('RemoveEntityOption', function(entity)
    if not DoesEntityExist(entity) then return end
    local netId = NetworkGetNetworkIdFromEntity(entity)
    TC5Eye.Client.EntityOptions[netId] = nil
end)

exports('RemoveModelOption', function(model)
    local modelHash = type(model) == 'number' and model or joaat(model)
    TC5Eye.Client.ModelOptions[modelHash] = nil
end)

RegisterNUICallback('select', function(data, cb)
    handleSelection(data)
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if IsControlPressed(0, TC5Eye.Config.HoldKey) then
            refreshEye()
            Wait(100)
        else
            if TC5Eye.Client.IsOpen then
                setOpen(false)
            end
            Wait(200)
        end
    end
end)

-- Demo integration for tc5_garage
CreateThread(function()
    Wait(1500)
    if GetResourceState('tc5_garage') ~= 'started' then return end

    for garageId, garage in pairs((TC5Garage and TC5Garage.Config and TC5Garage.Config.Garages) or {}) do
        exports.tc5_eye:AddBoxZone({
            id = 'garage_' .. garageId,
            coords = garage.coords,
            radius = 2.5,
            options = {
                {
                    id = 'open_' .. garageId,
                    label = ('Open %s'):format(garage.label),
                    icon = '🚗',
                    event = 'tc5_eye:client:openGarage',
                    data = { garageId = garageId }
                }
            }
        })
    end
end)

RegisterNetEvent('tc5_eye:client:openGarage', function(payload)
    if payload and payload.data and payload.data.garageId then
        TriggerServerEvent('tc5_garage:server:openUi', payload.data.garageId)
    end
end)

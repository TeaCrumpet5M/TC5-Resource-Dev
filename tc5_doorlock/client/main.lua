TC5Doorlock = TC5Doorlock or {}
TC5Doorlock.Client = TC5Doorlock.Client or {}
TC5Doorlock.Client.Doors = {}
TC5Doorlock.Client.UiOpen = false
TC5Doorlock.Client.ManagerState = { doors = {} }
TC5Doorlock.Client.RegisteredEyeZones = {}

local function notify(payload)
    exports.tc5_ui:Notify(payload)
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setUiOpen(state)
    TC5Doorlock.Client.UiOpen = state == true
    SetNuiFocus(TC5Doorlock.Client.UiOpen, TC5Doorlock.Client.UiOpen)
    SetNuiFocusKeepInput(false)
    send(state and 'open' or 'close', {})
end

local function drawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 210)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function drawDoorHighlight(door)
    DrawMarker(
        TC5Doorlock.Config.HighlightSprite or 1,
        door.coords.x, door.coords.y, door.coords.z - 1.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.35, 0.35, 0.2,
        door.locked and 177 or 46,
        door.locked and 15 or 204,
        door.locked and 31 or 113,
        130, false, false, 2, false, nil, nil, false
    )

    if door.double and door.second and door.second.coords then
        DrawMarker(
            TC5Doorlock.Config.HighlightSprite or 1,
            door.second.coords.x, door.second.coords.y, door.second.coords.z - 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.35, 0.35, 0.2,
            door.locked and 177 or 46,
            door.locked and 15 or 204,
            door.locked and 31 or 113,
            130, false, false, 2, false, nil, nil, false
        )
    end
end

local function getDoorCoords(door)
    return vector3(door.coords.x, door.coords.y, door.coords.z)
end

local function getClosestDoor()
    local coords = GetEntityCoords(PlayerPedId())
    local closestDoor, closestDistance
    for _, door in pairs(TC5Doorlock.Client.Doors) do
        local dist = #(coords - getDoorCoords(door))
        if not closestDistance or dist < closestDistance then
            closestDistance = dist
            closestDoor = door
        end
    end
    return closestDoor, closestDistance or 9999.0
end

local function ensureDoorSystemDoor(door, doorData, index)
    local systemName = ('tc5_doorlock_%s_%s'):format(door.id, index or 1)
    local hash = joaat(systemName)
    if not IsDoorRegisteredWithSystem(hash) then
        AddDoorToSystem(hash, tonumber(doorData.model), doorData.coords.x, doorData.coords.y, doorData.coords.z, false, false, false)
    end
    return hash
end

local function applyStandardDoorState(door, doorData, index)
    local obj = GetClosestObjectOfType(doorData.coords.x, doorData.coords.y, doorData.coords.z, 1.5, tonumber(doorData.model), false, false, false)
    if obj ~= 0 then
        FreezeEntityPosition(obj, door.locked)
        SetEntityHeading(obj, doorData.heading or GetEntityHeading(obj))
    end
end

local function applyRollerDoorState(door, doorData, index)
    local hash = ensureDoorSystemDoor(door, doorData, index)
    DoorSystemSetAutomaticDistance(hash, 0.0, false, false)
    DoorSystemSetAutomaticRate(hash, door.doorRate or 1.0, false, false)
    DoorSystemSetDoorState(hash, door.locked and 1 or 0, false, false)
    DoorSystemSetOpenRatio(hash, door.locked and 0.0 or (door.rollerOpenRatio or 1.0), false, false)
end

local function applyDoorState(door)
    local primary = {
        model = door.model,
        coords = door.coords,
        heading = door.heading
    }

    if (door.doorType or 'standard') == 'roller' then
        applyRollerDoorState(door, primary, 1)
    else
        applyStandardDoorState(door, primary, 1)
    end

    if door.double and door.second and door.second.model then
        if (door.doorType or 'standard') == 'roller' then
            applyRollerDoorState(door, door.second, 2)
        else
            applyStandardDoorState(door, door.second, 2)
        end
    end
end

local function getDoorDataFromCrosshair()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dirX = -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x)))
    local dirY = math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x)))
    local dirZ = math.sin(math.rad(camRot.x))
    local dest = vector3(camCoords.x + dirX * 7.0, camCoords.y + dirY * 7.0, camCoords.z + dirZ * 7.0)

    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, dest.x, dest.y, dest.z, 16, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit ~= 1 or entity == 0 then return nil end

    local coords = GetEntityCoords(entity)
    return {
        entity = entity,
        model = GetEntityModel(entity),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = GetEntityHeading(entity)
    }
end

local function openManager(payload)
    setUiOpen(true)
    send('showManager', payload or {})
end

local function openEditor(mode, door)
    setUiOpen(true)
    send('showEditor', { mode = mode, door = door })
end

local function toggleClosestDoor()
    local door, dist = getClosestDoor()
    if not door or dist > (door.distance or 2.5) then
        notify({ title='Doorlock', message='No configured door nearby.', type='error', duration=2000 })
        return
    end
    TriggerServerEvent('tc5_doorlock:server:toggleDoor', door.id)
end

local function rebuildEyeOptions()
    if GetResourceState('tc5_eye') ~= 'started' then return end

    for zoneId, _ in pairs(TC5Doorlock.Client.RegisteredEyeZones) do
        exports.tc5_eye:RemoveZone(zoneId)
    end
    TC5Doorlock.Client.RegisteredEyeZones = {}

    for doorId, door in pairs(TC5Doorlock.Client.Doors) do
        local zoneId = 'tc5_doorlock_' .. tostring(doorId)
        exports.tc5_eye:AddBoxZone({
            id = zoneId,
            coords = vector3(door.coords.x, door.coords.y, door.coords.z),
            radius = (door.distance or 2.5),
            options = {
                {
                    id = 'toggle_door_' .. tostring(doorId),
                    label = (door.locked and ('Unlock ') or ('Lock ')) .. (door.name or 'Door'),
                    icon = '🚪',
                    event = 'tc5_doorlock:client:toggleDoorById',
                    data = { doorId = doorId }
                }
            }
        })
        TC5Doorlock.Client.RegisteredEyeZones[zoneId] = true
    end
end

RegisterNetEvent('tc5_doorlock:client:toggleDoorById', function(payload)
    local doorId = payload and payload.data and payload.data.doorId
    if not doorId then return end
    TriggerServerEvent('tc5_doorlock:server:toggleDoor', tonumber(doorId))
end)

RegisterNetEvent('tc5_doorlock:client:setDoors', function(doors)
    TC5Doorlock.Client.Doors = doors or {}
    rebuildEyeOptions()
end)

RegisterNetEvent('tc5_doorlock:client:updateDoorState', function(doorId, locked)
    doorId = tonumber(doorId)
    if TC5Doorlock.Client.Doors[doorId] then
        TC5Doorlock.Client.Doors[doorId].locked = locked == true
    end
end)

RegisterNetEvent('tc5_doorlock:client:openManager', function(payload)
    TC5Doorlock.Client.ManagerState.doors = payload and payload.doors or {}
    openManager({ doors = TC5Doorlock.Client.ManagerState.doors })
end)

RegisterNetEvent('tc5_doorlock:client:refreshManagerDoors', function(doors)
    TC5Doorlock.Client.ManagerState.doors = doors or {}
    send('updateDoorList', { doors = TC5Doorlock.Client.ManagerState.doors })
end)

RegisterCommand(TC5Doorlock.Config.ManageCommand, function()
    TriggerServerEvent('tc5_doorlock:server:openManager')
end, false)

RegisterCommand(TC5Doorlock.Config.CreateCommand, function()
    local data = getDoorDataFromCrosshair()
    if not data then
        notify({ title='Doorlock', message='Aim at a door object first.', type='error', duration=2500 })
        return
    end
    openEditor('create', {
        name='New Door',
        model=data.model,
        coords=data.coords,
        heading=data.heading,
        locked=true,
        double=false,
        second={},
        distance=TC5Doorlock.Config.MaxDistance,
        autoLock=false,
        lockpickable=false,
        doorRate=1.0,
        doorType='standard',
        rollerOpenRatio=1.0,
        access={ jobs={}, gangs={}, characters={} }
    })
end, false)

RegisterCommand(TC5Doorlock.Config.EditCommand, function(_, args)
    local doorId = tonumber(args[1] or 0)
    local door = TC5Doorlock.Client.Doors[doorId]
    if not door then
        notify({ title='Doorlock', message='Usage: /tc5_dooredit [doorId]', type='error', duration=2500 })
        return
    end
    openEditor('edit', door)
end, false)

RegisterCommand(TC5Doorlock.Config.ToggleCommand, function()
    toggleClosestDoor()
end, false)

RegisterKeyMapping(TC5Doorlock.Config.ToggleCommand, 'TC5 Door Toggle', 'keyboard', TC5Doorlock.Config.ToggleKey)

RegisterNUICallback('close', function(_, cb)
    setUiOpen(false)
    cb({ ok = true })
end)

RegisterNUICallback('requestCreateFromAim', function(_, cb)
    local data = getDoorDataFromCrosshair()
    if not data then
        notify({ title='Doorlock', message='Aim at a door object first.', type='error', duration=2500 })
        cb({ ok = false })
        return
    end
    openEditor('create', {
        name='New Door',
        model=data.model,
        coords=data.coords,
        heading=data.heading,
        locked=true,
        double=false,
        second={},
        distance=TC5Doorlock.Config.MaxDistance,
        autoLock=false,
        lockpickable=false,
        doorRate=1.0,
        doorType='standard',
        rollerOpenRatio=1.0,
        access={ jobs={}, gangs={}, characters={} }
    })
    cb({ ok = true })
end)

RegisterNUICallback('requestEditDoor', function(data, cb)
    local doorId = tonumber(data and data.doorId or 0)
    local door = TC5Doorlock.Client.Doors[doorId]
    if not door then
        cb({ ok = false })
        return
    end
    openEditor('edit', door)
    cb({ ok = true })
end)

RegisterNUICallback('saveDoor', function(data, cb)
    if data.mode == 'edit' and data.door and data.door.id then
        TriggerServerEvent('tc5_doorlock:server:updateDoor', data.door.id, data.door)
    else
        TriggerServerEvent('tc5_doorlock:server:createDoor', data.door)
    end
    TriggerServerEvent('tc5_doorlock:server:openManager')
    cb({ ok = true })
end)

RegisterNUICallback('deleteDoor', function(data, cb)
    TriggerServerEvent('tc5_doorlock:server:deleteDoor', data and data.doorId)
    TriggerServerEvent('tc5_doorlock:server:openManager')
    cb({ ok = true })
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('tc5_doorlock:server:requestDoors')
end)

CreateThread(function()
    while true do
        local waitTime = 1000
        local door, dist = getClosestDoor()

        if door and dist <= (TC5Doorlock.Config.DisplayDistance or 12.0) then
            waitTime = 0
            applyDoorState(door)

            if dist <= (TC5Doorlock.Config.HighlightDistance or 5.0) then
                drawDoorHighlight(door)
            end

            if dist <= (TC5Doorlock.Config.TextDistance or 8.0) then
                local typeLabel = (door.doorType == 'roller') and 'Roller' or 'Door'
                drawText3D(door.coords.x, door.coords.y, door.coords.z + 1.0, ('%s %s [%s]'):format(typeLabel, door.name, door.locked and 'Locked' or 'Unlocked'))
            end
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('tc5_doorlock:server:requestDoors')
end)

local tabletOpen = false
local tabletObject = nil
local activeContract = nil
local activeVehicle = nil
local pickupBlip = nil
local dropoffBlip = nil
local canCompleteAtDropoff = false


local function forceCloseTabletUi()
    tabletOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('close', {})
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function notify(message, notifyType)
    if exports['tc5_ui'] and exports['tc5_ui'].Notify then
        exports['tc5_ui']:Notify({
            title = 'Tablet',
            message = message,
            type = notifyType or 'info'
        })
    end
end

local function requestModel(model)
    if HasModelLoaded(model) then
        return true
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasModelLoaded(model)
end

local function requestAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasAnimDictLoaded(dict)
end

local function attachTabletProp()
    if tabletObject and DoesEntityExist(tabletObject) then
        return
    end

    local prop = TC5Tablet.Config.Prop
    if not requestModel(prop.Model) then
        return
    end

    local ped = PlayerPedId()
    tabletObject = CreateObject(prop.Model, 1.0, 1.0, 1.0, true, true, false)
    SetEntityCollision(tabletObject, false, false)
    AttachEntityToEntity(
        tabletObject,
        ped,
        GetPedBoneIndex(ped, prop.Bone),
        prop.Offset.x,
        prop.Offset.y,
        prop.Offset.z,
        prop.Rotation.x,
        prop.Rotation.y,
        prop.Rotation.z,
        true,
        true,
        false,
        true,
        1,
        true
    )
    SetModelAsNoLongerNeeded(prop.Model)
end

local function removeTabletProp()
    if tabletObject and DoesEntityExist(tabletObject) then
        DeleteEntity(tabletObject)
    end
    tabletObject = nil
end

local function playTabletAnim()
    local anim = TC5Tablet.Config.Animation
    if requestAnimDict(anim.Dict) then
        TaskPlayAnim(PlayerPedId(), anim.Dict, anim.Clip, 3.0, 3.0, -1, anim.Flag, 0.0, false, false, false)
    end
end

local function clearTabletAnim()
    local anim = TC5Tablet.Config.Animation
    StopAnimTask(PlayerPedId(), anim.Dict, anim.Clip, 2.0)
    ClearPedSecondaryTask(PlayerPedId())
end

local function removeBlipSafe(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    return nil
end

local function setTabletState(state)
    tabletOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)

    if state then
        attachTabletProp()
        playTabletAnim()
    else
        clearTabletAnim()
        removeTabletProp()
        send('close', {})
    end
end

local function createBoostVehicle(contract)
    if activeVehicle and DoesEntityExist(activeVehicle) then
        DeleteVehicle(activeVehicle)
    end

    local model = joaat(contract.vehicle)
    if not requestModel(model) then
        notify('Unable to load contract vehicle.', 'error')
        return
    end

    activeVehicle = CreateVehicle(
        model,
        contract.pickup.x,
        contract.pickup.y,
        contract.pickup.z,
        contract.pickup.w or 0.0,
        true,
        false
    )

    SetVehicleOnGroundProperly(activeVehicle)
    SetEntityAsMissionEntity(activeVehicle, true, true)
    SetVehicleDoorsLocked(activeVehicle, 2)
    SetVehicleDoorsLockedForAllPlayers(activeVehicle, true)
    SetVehicleNumberPlateText(activeVehicle, ('TC5%03d'):format(math.random(100, 999)))
    SetModelAsNoLongerNeeded(model)
end

local function setPickupBlip(coords)
    pickupBlip = removeBlipSafe(pickupBlip)
    pickupBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(pickupBlip, 225)
    SetBlipScale(pickupBlip, 0.9)
    SetBlipColour(pickupBlip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Boost Target')
    EndTextCommandSetBlipName(pickupBlip)
    SetNewWaypoint(coords.x, coords.y)
end

local function setDropoffBlip(coords)
    dropoffBlip = removeBlipSafe(dropoffBlip)
    dropoffBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(dropoffBlip, 1)
    SetBlipScale(dropoffBlip, 0.9)
    SetBlipColour(dropoffBlip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Boost Drop-off')
    EndTextCommandSetBlipName(dropoffBlip)
    SetNewWaypoint(coords.x, coords.y)
end

local function startBoostContract(contract)
    activeContract = contract
    canCompleteAtDropoff = false
    createBoostVehicle(contract)
    setPickupBlip(contract.pickup)
    dropoffBlip = removeBlipSafe(dropoffBlip)
    notify(('New contract: steal the %s.'):format(contract.vehicleLabel), 'success')
    send('boostContractStarted', contract)
    setTabletState(false)
end

local function finishBoostContract(data)
    activeContract = nil
    canCompleteAtDropoff = false
    pickupBlip = removeBlipSafe(pickupBlip)
    dropoffBlip = removeBlipSafe(dropoffBlip)

    if activeVehicle and DoesEntityExist(activeVehicle) then
        DeleteVehicle(activeVehicle)
    end
    activeVehicle = nil

    notify(('Contract complete. You received $%s'):format(data.payout), 'success')
    send('boostContractCompleted', data)
end

RegisterNetEvent('tc5_tablet:client:useTablet', function()
    TriggerServerEvent('tc5_tablet:server:openTablet')
end)

RegisterCommand(TC5Tablet.Config.OpenCommand or 'tablet', function()
    TriggerServerEvent('tc5_tablet:server:openTablet')
end, false)

RegisterNetEvent('tc5_tablet:client:openTablet', function(payload)
    setTabletState(true)
    send('boot', {
        delay = TC5Tablet.Config.BootTime or 900
    })
    send('open', payload)
end)

RegisterNetEvent('tc5_tablet:client:updateBoostingData', function(payload)
    send('boostingData', payload)
end)

RegisterNetEvent('tc5_tablet:client:boostContractStarted', function(contract)
    startBoostContract(contract)
end)

RegisterNetEvent('tc5_tablet:client:boostContractCompleted', function(data)
    finishBoostContract(data)
end)

RegisterNUICallback('close', function(_, cb)
    setTabletState(false)
    cb('ok')
end)

RegisterNUICallback('requestBoostingData', function(_, cb)
    TriggerServerEvent('tc5_tablet:server:requestBoostingData')
    cb('ok')
end)

RegisterNUICallback('startBoostContract', function(_, cb)
    TriggerServerEvent('tc5_tablet:server:startBoostContract')
    cb('ok')
end)


CreateThread(function()
    Wait(250)
    forceCloseTabletUi()
    Wait(750)
    forceCloseTabletUi()
    Wait(2000)
    forceCloseTabletUi()
end)

AddEventHandler('playerSpawned', function()
    forceCloseTabletUi()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        forceCloseTabletUi()
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if tabletOpen then
            sleep = 0
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 322, true)

            if not IsEntityPlayingAnim(PlayerPedId(), TC5Tablet.Config.Animation.Dict, TC5Tablet.Config.Animation.Clip, 3) then
                playTabletAnim()
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if activeContract and activeVehicle and DoesEntityExist(activeVehicle) then
            sleep = 0
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local vCoords = GetEntityCoords(activeVehicle)

            if not canCompleteAtDropoff then
                if #(pCoords - vCoords) < 15.0 then
                    DrawMarker(1, vCoords.x, vCoords.y, vCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.1, 2.1, 1.0, 255, 95, 87, 180, false, false, 2, false, nil, nil, false)
                end

                if #(pCoords - vCoords) < 3.0 and not IsPedInAnyVehicle(ped, false) then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to unlock the target vehicle')
                    EndTextCommandDisplayHelp(0, false, true, 1)

                    if IsControlJustPressed(0, 38) then
                        SetVehicleDoorsLocked(activeVehicle, 1)
                        SetVehicleDoorsLockedForAllPlayers(activeVehicle, false)
                        notify('Vehicle unlocked. Get in and drive it to the drop-off.', 'success')
                    end
                end

                if GetVehiclePedIsIn(ped, false) == activeVehicle and GetPedInVehicleSeat(activeVehicle, -1) == ped then
                    canCompleteAtDropoff = true
                    pickupBlip = removeBlipSafe(pickupBlip)
                    setDropoffBlip(activeContract.dropoff)
                    notify('Target secured. Deliver it to the drop-off.', 'success')
                end
            else
                local drop = vector3(activeContract.dropoff.x, activeContract.dropoff.y, activeContract.dropoff.z)
                if #(pCoords - drop) < 12.0 then
                    DrawMarker(1, drop.x, drop.y, drop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 86, 171, 47, 180, false, false, 2, false, nil, nil, false)
                end

                if #(pCoords - drop) < 4.0 and GetVehiclePedIsIn(ped, false) == activeVehicle then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to complete the boost contract')
                    EndTextCommandDisplayHelp(0, false, true, 1)

                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('tc5_tablet:server:completeBoostContract', activeContract.id)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    clearTabletAnim()
    removeTabletProp()
    pickupBlip = removeBlipSafe(pickupBlip)
    dropoffBlip = removeBlipSafe(dropoffBlip)
end)

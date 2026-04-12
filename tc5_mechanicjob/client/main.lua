TC5Mechanic = TC5Mechanic or {}
TC5Mechanic.Client = TC5Mechanic.Client or {}
TC5Mechanic.Client.History = TC5Mechanic.Client.History or {}
TC5Mechanic.Client.MenuOpen = false
TC5Mechanic.Client.LastDiagnostic = nil

local function notify(message, notifyType)
    if GetResourceState('tc5_ui') == 'started' then
        TriggerEvent('tc5_ui:client:notify', {
            title = 'Mechanic',
            message = message,
            type = notifyType or 'info'
        })
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

local function getJob()
    if GetResourceState('tc5_jobs') ~= 'started' then return nil end
    local ok, job = pcall(function()
        return exports['tc5_jobs']:GetLocalJob()
    end)
    return ok and job or nil
end

local function getCurrentShop()
    local job = getJob()
    if not job or not job.name then return nil, nil, nil end
    local shopKey, shop = TC5Mechanic.GetShopByJob(job.name)
    return job, shopKey, shop
end

local function isAllowed()
    local job = getJob()
    return job and TC5Mechanic.IsMechanicJob(job.name) or false
end

local function getNearbyVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, TC5Mechanic.Config.ScanDistance or 6.0, 0, 70)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end
    return vehicle
end

local function getRepairLabel(index)
    local labels = {
        [11] = 'Engine',
        [12] = 'Brakes',
        [13] = 'Transmission',
        [15] = 'Suspension',
        [16] = 'Armour',
        [18] = 'Turbo'
    }
    return labels[index] or ('Mod %s'):format(index)
end

local function drawHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function TC5Mechanic.BuildDiagnosticPayload(includeHistory)
    local job, shopKey, shop = getCurrentShop()
    if not job or not shop then
        return nil, 'You are not employed at a mechanic shop.'
    end
    if TC5Mechanic.Config.RequireDuty and not job.onduty then
        return nil, 'You must be on duty.'
    end

    local vehicle = getNearbyVehicle()
    if not vehicle then
        return nil, 'No nearby vehicle.'
    end

    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = TC5Mechanic.Trim(GetVehicleNumberPlateText(vehicle))
    local netId = VehToNet(vehicle)

    local mods = {}
    for _, idx in ipairs({11, 12, 13, 15, 16, 18}) do
        local value = GetVehicleMod(vehicle, idx)
        if idx == 18 then
            value = IsToggleModOn(vehicle, idx) and 'Installed' or 'Not Installed'
        else
            value = value >= 0 and ('Level %s'):format(value + 1) or 'Stock'
        end
        mods[#mods + 1] = {
            label = getRepairLabel(idx),
            value = value
        }
    end

    local tyres = {}
    for i = 0, 5 do
        tyres[#tyres + 1] = {
            label = ('Tyre %s'):format(i + 1),
            burst = IsVehicleTyreBurst(vehicle, i, false)
        }
    end

    local doors = {}
    for i = 0, 5 do
        doors[#doors + 1] = {
            index = i,
            damaged = IsVehicleDoorDamaged(vehicle, i)
        }
    end

    local payload = {
        shopKey = shopKey,
        shopLabel = shop.label,
        model = model ~= 'CARNOTFOUND' and model or GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))),
        plate = plate,
        netId = netId,
        engine = TC5Mechanic.RoundPercent(GetVehicleEngineHealth(vehicle), 1000.0),
        body = TC5Mechanic.RoundPercent(GetVehicleBodyHealth(vehicle), 1000.0),
        petrol = TC5Mechanic.RoundPercent(GetVehiclePetrolTankHealth(vehicle), 1000.0),
        fuelLevel = math.floor(GetVehicleFuelLevel(vehicle) + 0.5),
        mods = mods,
        damage = {
            tyres = tyres,
            doors = doors
        },
        history = includeHistory and (TC5Mechanic.Client.History[plate] or {}) or {}
    }

    return payload
end

local function sendMenu(menuType)
    if menuType == 'repair' then
        local diagnostic, err = TC5Mechanic.BuildDiagnosticPayload(true)
        if not diagnostic then
            notify(err or 'Unable to scan vehicle.', 'error')
            return
        end
        TC5Mechanic.Client.LastDiagnostic = diagnostic
        TriggerServerEvent('tc5_mechanicjob:server:updateVehicleContext', diagnostic)
    end
    TriggerServerEvent('tc5_mechanicjob:server:openMenu', menuType)
end

local function handleLocation(shopKey, shop, pointName, coords, distance)
    local job, currentShopKey, currentShop = getCurrentShop()
    if not currentShop or currentShopKey ~= shopKey then return end

    DrawMarker(2, coords.x, coords.y, coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 220, 60, 60, 180, false, false, 2, false, nil, nil, false)

    if distance > (TC5Mechanic.Config.InteractDistance or 1.75) then return end

    if pointName == 'duty' then
        drawHelpText('Press ~INPUT_CONTEXT~ to toggle duty')
        if IsControlJustReleased(0, 38) then
            TriggerServerEvent('tc5_mechanicjob:server:toggleDuty')
        end
    elseif pointName == 'crafting' then
        drawHelpText('Press ~INPUT_CONTEXT~ to open crafting bench')
        if IsControlJustReleased(0, 38) then
            sendMenu('crafting')
        end
    elseif pointName == 'repair' then
        drawHelpText('Press ~INPUT_CONTEXT~ to open repair bay')
        if IsControlJustReleased(0, 38) then
            sendMenu('repair')
        end
    elseif pointName == 'boss' then
        if TC5Mechanic.IsBossGrade(shop, job.grade) then
            drawHelpText('Press ~INPUT_CONTEXT~ to open boss menu')
            if IsControlJustReleased(0, 38) then
                sendMenu('boss')
            end
        end
    elseif pointName == 'shop' then
        drawHelpText('Press ~INPUT_CONTEXT~ to open mechanic stock shop')
        if IsControlJustReleased(0, 38) then
            sendMenu('shop')
        end
    end
end

RegisterNetEvent('tc5_mechanicjob:client:openMenu', function(payload)
    if type(payload) ~= 'table' then return end
    TC5Mechanic.Client.MenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = payload
    })
end)

RegisterNetEvent('tc5_mechanicjob:client:updateHistory', function(plate, history)
    if not plate then return end
    TC5Mechanic.Client.History[plate] = history or {}
    if TC5Mechanic.Client.LastDiagnostic and TC5Mechanic.Client.LastDiagnostic.plate == plate then
        TC5Mechanic.Client.LastDiagnostic.history = history or {}
    end
end)

RegisterNetEvent('tc5_mechanicjob:client:repairApproved', function(data)
    if not data or not data.netId or not data.repairId then return end

    local vehicle = NetToVeh(data.netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        notify('Vehicle no longer exists.', 'error')
        return
    end

    local ped = PlayerPedId()
    local vehCoords = GetEntityCoords(vehicle)
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - vehCoords) > (TC5Mechanic.Config.ScanDistance or 6.0) + 1.5 then
        notify('Move closer to the vehicle.', 'error')
        return
    end

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(500)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
    local finishAt = GetGameTimer() + (data.time or 5000)

    while GetGameTimer() < finishAt do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 75, true)
    end

    ClearPedTasks(ped)

    if data.repairId == 'engine' then
        SetVehicleEngineHealth(vehicle, 1000.0)
    elseif data.repairId == 'body' then
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDeformationFixed(vehicle)
    elseif data.repairId == 'tyres' then
        for i = 0, 7 do SetVehicleTyreFixed(vehicle, i) end
    elseif data.repairId == 'electronics' then
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
    elseif data.repairId == 'fullservice' then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        for i = 0, 7 do SetVehicleTyreFixed(vehicle, i) end
    end

    TriggerServerEvent('tc5_mechanicjob:server:repairComplete', {
        repairId = data.repairId,
        plate = data.plate or GetVehicleNumberPlateText(vehicle),
        netId = data.netId,
        engine = GetVehicleEngineHealth(vehicle),
        body = GetVehicleBodyHealth(vehicle),
        petrol = GetVehiclePetrolTankHealth(vehicle)
    })

    notify(('%s complete.'):format(data.label or 'Repair'), 'success')
end)

RegisterNUICallback('close', function(_, cb)
    TC5Mechanic.Client.MenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb({ ok = true })
end)

RegisterNUICallback('craft', function(data, cb)
    TriggerServerEvent('tc5_mechanicjob:server:craftPart', tostring(data.id or ''))
    cb({ ok = true })
end)

RegisterNUICallback('repair', function(data, cb)
    local diagnostic = TC5Mechanic.BuildDiagnosticPayload(true)
    if not diagnostic then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('tc5_mechanicjob:server:startRepair', {
        repairId = tostring(data.id or ''),
        netId = diagnostic.netId,
        plate = diagnostic.plate,
        damage = diagnostic.damage
    })
    cb({ ok = true })
end)

RegisterNUICallback('purchase', function(data, cb)
    TriggerServerEvent('tc5_mechanicjob:server:purchaseStock', tostring(data.id or ''))
    cb({ ok = true })
end)

RegisterNUICallback('createInvoice', function(data, cb)
    TriggerServerEvent('tc5_mechanicjob:server:createInvoice', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('createBusinessAccount', function(_, cb)
    TriggerServerEvent('tc5_mechanicjob:server:createBusinessAccount')
    cb({ ok = true })
end)

RegisterNUICallback('payEmployee', function(data, cb)
    TriggerServerEvent('tc5_mechanicjob:server:payEmployee', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('openBank', function(_, cb)
    if GetResourceState('tc5_banking') == 'started' then
        ExecuteCommand('bankmobile')
    end
    cb({ ok = true })
end)

RegisterCommand('mech', function(_, args)
    local action = tostring(args[1] or ''):lower()
    if action == 'craft' then
        sendMenu('crafting')
    elseif action == 'repair' then
        sendMenu('repair')
    elseif action == 'boss' then
        sendMenu('boss')
    elseif action == 'shop' then
        sendMenu('shop')
    elseif action == 'duty' then
        TriggerServerEvent('tc5_mechanicjob:server:toggleDuty')
    elseif action == 'scan' or action == '' then
        local payload, err = TC5Mechanic.BuildDiagnosticPayload(true)
        if not payload then
            notify(err or 'Unable to scan vehicle.', 'error')
            return
        end
        TC5Mechanic.Client.LastDiagnostic = payload
        TriggerServerEvent('tc5_mechanicjob:server:updateVehicleContext', payload)
        notify(('%s | Engine %s%% | Body %s%% | Fuel Tank %s%%'):format(payload.plate, payload.engine, payload.body, payload.petrol), 'info')
    else
        notify('Usage: /mech [scan|duty|repair|craft|shop|boss]', 'error')
    end
end, false)

RegisterCommand('mech_scan', function()
    ExecuteCommand('mech scan')
end, false)

RegisterCommand('mech_craft', function(_, args)
    local recipeId = tostring(args[1] or '')
    if recipeId == '' then
        sendMenu('crafting')
        return
    end
    TriggerServerEvent('tc5_mechanicjob:server:craftPart', recipeId)
end, false)

RegisterCommand('mech_repair', function()
    sendMenu('repair')
end, false)

RegisterCommand('mech_shop', function()
    sendMenu('shop')
end, false)

RegisterCommand('mech_boss', function()
    sendMenu('boss')
end, false)

RegisterCommand('mech_bank', function()
    if GetResourceState('tc5_banking') == 'started' then
        ExecuteCommand('bankmobile')
    else
        notify('Banking resource is not running.', 'error')
    end
end, false)

CreateThread(function()
    while true do
        local waitTime = 1500
        if isAllowed() and not TC5Mechanic.Client.MenuOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            for shopKey, shop in pairs(TC5Mechanic.GetShops()) do
                if shop.enabled ~= false and shop.locations then
                    for pointName, pointCoords in pairs(shop.locations) do
                        if pointName == 'duty' or pointName == 'crafting' or pointName == 'repair' or pointName == 'boss' or pointName == 'shop' then
                            local distance = #(coords - pointCoords)
                            if distance < (TC5Mechanic.Config.MarkerDistance or 18.0) then
                                waitTime = 0
                                handleLocation(shopKey, shop, pointName, pointCoords, distance)
                            end
                        end
                    end
                end
            end
        end
        Wait(waitTime)
    end
end)

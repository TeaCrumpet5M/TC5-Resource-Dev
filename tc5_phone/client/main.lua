TC5Phone = TC5Phone or {}
TC5Phone.Client = TC5Phone.Client or { isOpen = false, state = nil, messages = {} }

local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setOpen(state)
    TC5Phone.Client.isOpen = state == true
    SetNuiFocus(TC5Phone.Client.isOpen, TC5Phone.Client.isOpen)
    SetNuiFocusKeepInput(false)

    if not TC5Phone.Client.isOpen then
        send('close', {})
    end
end

local function pushState()
    if not TC5Phone.Client.state then return end
    send('theme', TC5Phone.Config.Theme)
    send('state', TC5Phone.Client.state)
end

RegisterCommand(TC5Phone.Config.OpenCommand, function()
    if TC5Phone.Client.isOpen then
        setOpen(false)
        return
    end

    TriggerServerEvent('tc5_phone:server:open')
end, false)

RegisterKeyMapping(TC5Phone.Config.OpenCommand, 'Open TC5 Phone', 'keyboard', TC5Phone.Config.OpenKey)

RegisterNetEvent('tc5_phone:client:open', function(state)
    TC5Phone.Client.state = state
    setOpen(true)
    pushState()
    send('open', {})
end)

RegisterNetEvent('tc5_phone:client:refresh', function(state)
    TC5Phone.Client.state = state
    if TC5Phone.Client.isOpen then
        pushState()
    end
end)

RegisterNetEvent('tc5_phone:client:messages', function(peerNumber, messages)
    TC5Phone.Client.messages[peerNumber] = messages
    send('messages', { peerNumber = peerNumber, messages = messages })
end)

RegisterNetEvent('tc5_phone:client:garageRefreshRequested', function()
    TriggerServerEvent('tc5_phone:server:refresh')
end)

RegisterNetEvent('tc5_phone:client:mechanicHistory', function(plate, history)
    send('mechanicHistory', { plate = plate, history = history or {} })
end)

RegisterNetEvent('tc5_phone:client:mechanicBossDataForward', function(data)
    send('mechanicBossData', data or {})
end)

RegisterNetEvent('tc5_phone:client:mechanicRefresh', function(payload)
    send('mechanicDiagnostic', payload)
end)

RegisterNetEvent('tc5_core:client:userLoaded', function()
    TriggerServerEvent('tc5_phone:server:refresh')
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('tc5_phone:server:refresh')
    cb({ ok = true })
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('tc5_phone:server:addContact', data)
    cb({ ok = true })
end)

RegisterNUICallback('deleteContact', function(data, cb)
    TriggerServerEvent('tc5_phone:server:deleteContact', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('openThread', function(data, cb)
    TriggerServerEvent('tc5_phone:server:getMessages', data and data.peerNumber)
    cb({ ok = true })
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('tc5_phone:server:sendMessage', data)
    cb({ ok = true })
end)

RegisterNUICallback('notify', function(data, cb)
    exports.tc5_ui:Notify({
        title = data and data.title or 'Phone',
        message = data and data.message or '',
        type = data and data.type or 'info',
        duration = data and data.duration or 2500
    })
    cb({ ok = true })
end)

RegisterNUICallback('requestMechanicPhoneData', function(_, cb)
    if GetResourceState('tc5_mechanicshops') == 'started' then
        local ok, result = pcall(function()
            return exports['tc5_mechanicshops']:BuildDiagnosticPayload(true)
        end)

        if ok and result then
            cb({ ok = true, payload = result })
            return
        end
    end

    if TC5Mechanic and TC5Mechanic.BuildDiagnosticPayload then
        local payload, err = TC5Mechanic.BuildDiagnosticPayload(true)
        cb(payload and { ok = true, payload = payload } or { ok = false, message = err or 'Scan failed.' })
        return
    end

    cb({ ok = false, message = 'Mechanic resource unavailable.' })
end)

RegisterNUICallback('requestMechanicRecipes', function(_, cb)
    if GetResourceState('tc5_mechanicshops') ~= 'started' then
        cb({ recipes = {} })
        return
    end

    local ok, recipes = pcall(function()
        return exports['tc5_mechanicshops']:GetRecipes()
    end)

    cb({ recipes = ok and recipes or {} })
end)

RegisterNUICallback('craftMechanicRecipe', function(data, cb)
    if data and data.recipeId then
        TriggerServerEvent('tc5_mechanicshops:server:craftPart', data.recipeId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('mechanicToggleDuty', function(_, cb)
    TriggerServerEvent('tc5_mechanicshops:server:toggleDuty')
    cb({ ok = true })
end)

RegisterNUICallback('requestMechanicBossData', function(_, cb)
    TriggerServerEvent('tc5_mechanicshops:server:getBossData')
    cb({ ok = true })
end)

RegisterNUICallback('mechanicHire', function(data, cb)
    TriggerServerEvent('tc5_mechanicshops:server:hirePlayer', data and data.targetId)
    cb({ ok = true })
end)

RegisterNUICallback('mechanicPromote', function(data, cb)
    TriggerServerEvent('tc5_mechanicshops:server:updateEmployeeGrade', data and data.targetId, 'up')
    cb({ ok = true })
end)

RegisterNUICallback('mechanicDemote', function(data, cb)
    TriggerServerEvent('tc5_mechanicshops:server:updateEmployeeGrade', data and data.targetId, 'down')
    cb({ ok = true })
end)

RegisterNUICallback('mechanicFire', function(data, cb)
    TriggerServerEvent('tc5_mechanicshops:server:firePlayer', data and data.targetId)
    cb({ ok = true })
end)

RegisterNUICallback('startMechanicRepair', function(data, cb)
    if data and data.repairId then
        TriggerServerEvent('tc5_mechanicshops:server:startRepair', data)
    end
    cb({ ok = true })
end)
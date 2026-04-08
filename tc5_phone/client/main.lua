TC5Phone = TC5Phone or {}
TC5Phone.Client = TC5Phone.Client or {
    isOpen = false,
    state = nil,
    messages = {}
}

local function setOpen(state)
    TC5Phone.Client.isOpen = state == true
    SetNuiFocus(TC5Phone.Client.isOpen, TC5Phone.Client.isOpen)
    SetNuiFocusKeepInput(false)
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function pushState()
    if not TC5Phone.Client.state then return end
    send('theme', TC5Phone.Config.Theme)
    send('state', TC5Phone.Client.state)
end

RegisterCommand(TC5Phone.Config.OpenCommand, function()
    if TC5Phone.Client.isOpen then
        setOpen(false)
        send('close', {})
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
    send('messages', {
        peerNumber = peerNumber,
        messages = messages
    })
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

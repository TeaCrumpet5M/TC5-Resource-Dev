local chatOpen = false
local suggestions = {}

local function sendUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setChatOpen(state)
    chatOpen = state
    SetNuiFocus(state, state)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    sendUI('toggleInput', { state = state, suggestions = suggestions })
end

local function normalizeMessage(message)
    local author = ''
    local text = ''
    local color = nil

    if type(message) == 'string' then
        text = message
    elseif type(message) == 'table' then
        if message.args and #message.args > 0 then
            author = tostring(message.args[1] or '')
            local parts = {}
            for i = 2, #message.args do
                parts[#parts + 1] = tostring(message.args[i])
            end
            text = table.concat(parts, ' ')
        else
            author = tostring(message.author or '')
            text = tostring(message.text or message.message or '')
        end
        color = message.color
    end

    return author, text, color
end

local function addMessageToUi(message)
    local author, text, color = normalizeMessage(message)

    if text == '' and author == '' then
        return
    end

    sendUI('addMessage', {
        author = author,
        text = text,
        color = color
    })
end

CreateThread(function()
    Wait(500)

    if SetTextChatEnabled then
        SetTextChatEnabled(false)
    end

    sendUI('bootstrap', {
        theme = {
            primary = '#b10f1f',
            panel = 'rgba(10, 10, 10, 0.84)',
            panelAlt = 'rgba(22, 22, 22, 0.96)',
            border = 'rgba(255, 255, 255, 0.08)',
            text = '#ffffff',
            muted = 'rgba(255, 255, 255, 0.68)'
        }
    })
end)


CreateThread(function()
    while true do
        if chatOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 200, true)
            EnableControlAction(0, 202, true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

RegisterCommand('tc5chat_open', function()
    if chatOpen then return end
    setChatOpen(true)
end, false)

RegisterKeyMapping('tc5chat_open', 'Open TC5 chat', 'keyboard', 'T')

RegisterNUICallback('close', function(_, cb)
    setChatOpen(false)
    cb('ok')
end)

RegisterNUICallback('submit', function(data, cb)
    local text = tostring(data.text or '')
    text = text:gsub('^%s+', ''):gsub('%s+$', '')

    setChatOpen(false)

    if text == '' then
        cb('ok')
        return
    end

    if text:sub(1, 1) == '/' then
        ExecuteCommand(text:sub(2))
        cb('ok')
        return
    end

    TriggerServerEvent('tc5_chat:sendMessage', text)
    cb('ok')
end)

RegisterNetEvent('chat:addMessage', function(message)
    addMessageToUi(message)
end)

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    suggestions[name] = {
        name = name,
        help = help,
        params = params or {}
    }

    sendUI('setSuggestions', { suggestions = suggestions })
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    suggestions[name] = nil
    sendUI('setSuggestions', { suggestions = suggestions })
end)

RegisterNetEvent('chat:addSuggestions', function(list)
    for _, entry in ipairs(list or {}) do
        if entry.name then
            suggestions[entry.name] = entry
        end
    end

    sendUI('setSuggestions', { suggestions = suggestions })
end)

RegisterNetEvent('chat:clear', function()
    sendUI('clearMessages', {})
end)

exports('addMessage', function(message)
    addMessageToUi(message)
end)

exports('addSuggestion', function(name, help, params)
    suggestions[name] = {
        name = name,
        help = help,
        params = params or {}
    }
    sendUI('setSuggestions', { suggestions = suggestions })
end)

exports('removeSuggestion', function(name)
    suggestions[name] = nil
    sendUI('setSuggestions', { suggestions = suggestions })
end)

exports('addSuggestions', function(list)
    for _, entry in ipairs(list or {}) do
        if entry.name then
            suggestions[entry.name] = entry
        end
    end
    sendUI('setSuggestions', { suggestions = suggestions })
end)

exports('clear', function()
    sendUI('clearMessages', {})
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    if SetTextChatEnabled then
        SetTextChatEnabled(true)
    end
end)

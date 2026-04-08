local uiOpen = false
local currentPayload = nil

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeUi()
    uiOpen = false
    setFocus(false)
    send('close', {})
end

local function openUi(payload)
    currentPayload = payload or {}
    uiOpen = true
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)
    Wait(250)
    setFocus(true)
    send('open', currentPayload)
end

RegisterNetEvent('tc5_multichar:client:open', function(payload)
    openUi(payload)
end)

RegisterNetEvent('tc5_multichar:client:forceClose', function()
    closeUi()
end)

RegisterNetEvent('tc5_multichar:client:selected', function()
    closeUi()
end)

RegisterNetEvent('tc5_multichar:client:selectionFailed', function(reason)
    if exports['tc5_ui'] and exports['tc5_ui'].Notify then
        exports['tc5_ui']:Notify({
            title = 'Character Selection',
            message = ('Selection failed: %s'):format(tostring(reason or 'unknown_error')),
            type = 'error',
            duration = 3500
        })
    end
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    if not uiOpen then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('tc5_core:server:selectCharacter', tonumber(data and data.characterId))
    cb({ ok = true })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    if not uiOpen then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('tc5_core:server:createCharacter', {
        firstName = data and data.firstName,
        lastName = data and data.lastName
    })
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('tc5_core:server:requestCharacterList')
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
end)

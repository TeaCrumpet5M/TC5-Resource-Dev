local creatorOpen = false
local lastData = {}

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function closeCreator()
    creatorOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('close', {})
end

local function openCreator(data)
    lastData = data or {}
    creatorOpen = true

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    DoScreenFadeIn(500)
    Wait(250)

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    send('open', lastData)
end

RegisterNetEvent('tc5_creator:client:open', function(data)
    openCreator(data)
end)

RegisterNetEvent('tc5_creator:client:reopen', function()
    openCreator(lastData)
end)

RegisterNetEvent('tc5_creator:client:forceClose', function()
    closeCreator()
end)

RegisterNUICallback('close', function(_, cb)
    closeCreator()
    cb('ok')
end)

RegisterNUICallback('submit', function(data, cb)
    if not creatorOpen then
        cb({ ok = false })
        return
    end

    closeCreator()

    if exports['tc5_ui'] and exports['tc5_ui'].OpenLoading then
        exports['tc5_ui']:OpenLoading({
            title = 'Creating Character',
            message = 'Preparing your starter apartment...'
        })
    end

    TriggerServerEvent('tc5_core:server:finishCreator', {
        firstName = data.firstName,
        lastName = data.lastName
    })

    cb({ ok = true })
end)

RegisterCommand('tc5_testcreator', function()
    TriggerEvent('tc5_creator:client:open', {
        firstName = 'New',
        lastName = 'Citizen'
    })
end, false)
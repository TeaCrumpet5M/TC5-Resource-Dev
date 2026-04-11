local uiOpen = false
local currentMode = 'bank'
local lastFocusAccountId = nil

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    uiOpen = state
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function notify(data)
    if exports['tc5_ui'] and exports['tc5_ui'].Notify then
        exports['tc5_ui']:Notify(data)
    end
end

local function isNear(coords, radius)
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    return #(myCoords - coords) <= radius
end

local function isNearATM()
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    for i = 1, #TC5Banking.Config.ATMs do
        if #(myCoords - TC5Banking.Config.ATMs[i]) <= 1.7 then
            return true
        end
    end
    return false
end

local function isNearBankBranch()
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    for i = 1, #TC5Banking.Config.BankBranches do
        if #(myCoords - TC5Banking.Config.BankBranches[i].coords) <= 2.0 then
            return true
        end
    end
    return false
end

local function tryOpen(mode)
    if mode == 'atm' and not isNearATM() then
        notify({ title = 'Banking', message = 'You need to be near an ATM.', type = 'error' })
        return
    end

    if mode == 'bank' and not isNearBankBranch() then
        notify({ title = 'Banking', message = 'You need to be inside a bank branch.', type = 'error' })
        return
    end

    currentMode = mode
    TriggerServerEvent('tc5_banking:server:openUi', mode)
end

RegisterNetEvent('tc5_banking:client:openUi', function(payload)
    currentMode = payload and payload.mode or currentMode
    setFocus(true)
    send('open', payload)
end)

RegisterNetEvent('tc5_banking:client:refreshUi', function(payload)
    currentMode = payload and payload.mode or currentMode
    send('refresh', payload)
end)

RegisterNetEvent('tc5_banking:client:forceClose', function()
    setFocus(false)
    send('close', {})
end)

RegisterNetEvent('tc5_banking:client:notify', function(data)
    notify(data)
end)

RegisterNUICallback('close', function(_, cb)
    setFocus(false)
    send('close', {})
    cb('ok')
end)

RegisterNUICallback('refresh', function(data, cb)
    lastFocusAccountId = data and data.focusAccountId or lastFocusAccountId
    TriggerServerEvent('tc5_banking:server:requestRefresh', currentMode, lastFocusAccountId)
    cb('ok')
end)

RegisterNUICallback('createPersonalAccount', function(data, cb)
    TriggerServerEvent('tc5_banking:server:createPersonalAccount', data and data.name or '', currentMode)
    cb('ok')
end)

RegisterNUICallback('createBusinessAccount', function(data, cb)
    TriggerServerEvent('tc5_banking:server:createBusinessAccount', data and data.jobName or '', data and data.name or '', currentMode)
    cb('ok')
end)

RegisterNUICallback('setDefaultAccount', function(data, cb)
    lastFocusAccountId = data and data.accountId or lastFocusAccountId
    TriggerServerEvent('tc5_banking:server:setDefaultAccount', data and data.accountId or 0, currentMode)
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    lastFocusAccountId = data and data.accountId or lastFocusAccountId
    TriggerServerEvent('tc5_banking:server:deposit', data and data.accountId or 0, data and data.amount or 0, data and data.reference or '', currentMode)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    lastFocusAccountId = data and data.accountId or lastFocusAccountId
    TriggerServerEvent('tc5_banking:server:withdraw', data and data.accountId or 0, data and data.amount or 0, data and data.reference or '', currentMode)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    lastFocusAccountId = data and data.fromAccountId or lastFocusAccountId
    TriggerServerEvent('tc5_banking:server:transfer', data and data.fromAccountId or 0, data and data.targetAccountNumber or '', data and data.amount or 0, data and data.reference or '', currentMode)
    cb('ok')
end)

CreateThread(function()
    while true do
        local waitMs = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for i = 1, #TC5Banking.Config.BankBranches do
            local branch = TC5Banking.Config.BankBranches[i]
            local dist = #(coords - branch.coords)
            if dist <= 10.0 then
                waitMs = 0
                DrawMarker(2, branch.coords.x, branch.coords.y, branch.coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.18, 200, 35, 35, 160, false, true, 2, false, nil, nil, false)
                if dist <= 2.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to access bank services')
                    EndTextCommandDisplayHelp(0, false, true, 1)
                    if IsControlJustPressed(0, 38) then
                        tryOpen('bank')
                    end
                end
            end
        end

        for i = 1, #TC5Banking.Config.ATMs do
            local atm = TC5Banking.Config.ATMs[i]
            local dist = #(coords - atm)
            if dist <= 5.0 then
                waitMs = 0
                if dist <= 1.7 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to use ATM')
                    EndTextCommandDisplayHelp(0, false, true, 1)
                    if IsControlJustPressed(0, 38) then
                        tryOpen('atm')
                    end
                end
            end
        end

        Wait(waitMs)
    end
end)

RegisterCommand(TC5Banking.Config.OpenCommand, function()
    tryOpen('bank')
end, false)

RegisterCommand(TC5Banking.Config.ATMCommand, function()
    tryOpen('atm')
end, false)

RegisterCommand(TC5Banking.Config.CloseCommand, function()
    if uiOpen then
        setFocus(false)
        send('close', {})
    end
end, false)

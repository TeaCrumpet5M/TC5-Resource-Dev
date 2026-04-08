local loadingOpen = false
local playerNeeds = {
    food = (TC5UI.Config.StatusHud and TC5UI.Config.StatusHud.DefaultFood) or 100,
    drink = (TC5UI.Config.StatusHud and TC5UI.Config.StatusHud.DefaultDrink) or 100
}

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function buildStatusPayload()
    local ped = PlayerPedId()
    local maxHealth = (GetEntityMaxHealth(ped) or 200) - 100
    if maxHealth <= 0 then maxHealth = 100 end

    local currentHealth = (GetEntityHealth(ped) or 100) - 100
    local healthPercent = math.floor((clamp(currentHealth, 0, maxHealth) / maxHealth) * 100)
    local armourPercent = clamp(GetPedArmour(ped) or 0, 0, 100)

    return {
        visible = TC5UI.Config.StatusHud.Enabled,
        health = healthPercent,
        armour = armourPercent,
        food = clamp(playerNeeds.food, 0, 100),
        drink = clamp(playerNeeds.drink, 0, 100),
        showArmour = TC5UI.Config.StatusHud.ShowArmourWhenZero or armourPercent > 0
    }
end

local function pushStatusHud()
    send('status:update', buildStatusPayload())
end

CreateThread(function()
    Wait(250)
    send('theme', TC5UI.Config.Theme)
    send('status:config', TC5UI.Config.StatusHud)
    pushStatusHud()
end)

CreateThread(function()
    while true do
        Wait(TC5UI.Config.StatusHud.UpdateInterval)
        pushStatusHud()
    end
end)

exports('Notify', function(payload)
    payload = payload or {}
    send('notify', {
        title = payload.title or 'TC5',
        message = payload.message or 'Notification',
        type = payload.type or 'info',
        duration = payload.duration or 3500
    })
end)

exports('OpenLoading', function(payload)
    payload = payload or {}
    loadingOpen = true
    SetNuiFocus(false, false)

    send('loading:open', {
        title = payload.title or 'Loading',
        message = payload.message or 'Please wait...'
    })
end)

exports('CloseLoading', function()
    if not loadingOpen then return end
    loadingOpen = false
    send('loading:close', {})
end)

exports('SetNeeds', function(food, drink)
    playerNeeds.food = clamp(food or playerNeeds.food, 0, 100)
    playerNeeds.drink = clamp(drink or playerNeeds.drink, 0, 100)
    pushStatusHud()
end)

exports('SetFood', function(food)
    playerNeeds.food = clamp(food or playerNeeds.food, 0, 100)
    pushStatusHud()
end)

exports('SetDrink', function(drink)
    playerNeeds.drink = clamp(drink or playerNeeds.drink, 0, 100)
    pushStatusHud()
end)

RegisterNetEvent('tc5_ui:client:notify', function(payload)
    exports.tc5_ui:Notify(payload)
end)

RegisterNetEvent('tc5_ui:client:loading', function(state, payload)
    if state then
        exports.tc5_ui:OpenLoading(payload)
    else
        exports.tc5_ui:CloseLoading()
    end
end)

RegisterNetEvent('tc5_ui:client:updateNeeds', function(food, drink)
    exports.tc5_ui:SetNeeds(food, drink)
end)

RegisterNetEvent('tc5_ui:client:updateFood', function(food)
    exports.tc5_ui:SetFood(food)
end)

RegisterNetEvent('tc5_ui:client:updateDrink', function(drink)
    exports.tc5_ui:SetDrink(drink)
end)

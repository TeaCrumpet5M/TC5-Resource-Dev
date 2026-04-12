local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_inventory:client:notify', src, {
        title = 'Cash',
        message = message,
        type = notifyType or 'info'
    })
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function ensurePlayerInventory(src)
    local charId = getCharacterId(src)
    if not charId then return nil, nil end
    return charId, TC5Inventory.GetInventory('player', charId)
end

local function getCashSlots(inventory)
    local slots = {}

    for slot, item in pairs(inventory and inventory.items or {}) do
        if item.name == 'cash' and (tonumber(item.amount) or 0) > 0 then
            slots[#slots + 1] = {
                slot = tonumber(slot),
                amount = tonumber(item.amount) or 0
            }
        end
    end

    table.sort(slots, function(a, b)
        return a.slot < b.slot
    end)

    return slots
end

local function getCashTotal(inventory)
    local total = 0
    for _, item in pairs(inventory and inventory.items or {}) do
        if item.name == 'cash' then
            total = total + (tonumber(item.amount) or 0)
        end
    end
    return total
end

exports('GetCash', function(src)
    local _, inventory = ensurePlayerInventory(src)
    return getCashTotal(inventory)
end)

exports('AddCash', function(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local _, inventory = ensurePlayerInventory(src)
    if not inventory then
        return false, 'no_inventory'
    end

    local ok, result = TC5Inventory.AddItem('player', getCharacterId(src), 'cash', amount)
    if ok then
        TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    end
    return ok, result
end)

exports('RemoveCash', function(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local charId, inventory = ensurePlayerInventory(src)
    if not inventory then
        return false, 'no_inventory'
    end

    if getCashTotal(inventory) < amount then
        return false, 'not_enough_cash'
    end

    local remaining = amount
    local slots = getCashSlots(inventory)

    for i = 1, #slots do
        if remaining <= 0 then break end

        local entry = slots[i]
        local removeAmount = math.min(entry.amount, remaining)
        local ok = TC5Inventory.RemoveItem('player', charId, 'cash', removeAmount, entry.slot)

        if ok then
            remaining = remaining - removeAmount
        end
    end

    if remaining <= 0 then
        TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
        return true
    end

    return false, 'remove_failed'
end)

RegisterCommand('cashcount', function(src)
    if src == 0 then return end
    local _, inventory = ensurePlayerInventory(src)
    if not inventory then return end

    notify(src, ('You are carrying $%s in cash.'):format(getCashTotal(inventory)), 'success')
end, false)

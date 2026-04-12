local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_inventory:client:notify', src, {
        title = 'Shop',
        message = message,
        type = notifyType or 'info'
    })
end

RegisterNetEvent('tc5_inventory:server:buyItem', function(shopId, itemName, slot, amount)
    local src = source
    local shop = TC5Shops[shopId]

    if not shop then
        return
    end

    amount = tonumber(amount) or 1
    if amount <= 0 then
        notify(src, 'Invalid amount.', 'error')
        return
    end

    local entry = nil

    if slot then
        entry = shop.inventory[tonumber(slot)]
    end

    if not entry and itemName then
        for _, item in pairs(shop.inventory) do
            if item.name == itemName then
                entry = item
                break
            end
        end
    end

    if not entry then
        notify(src, 'Shop item not found.', 'error')
        return
    end

    local price = (tonumber(entry.price) or 0) * amount
    local currentCash = exports['tc5_inventory']:GetCash(src)

    if currentCash < price then
        notify(src, 'Not enough cash.', 'error')
        return
    end

    local ok = exports['tc5_inventory']:CanCarryItem(src, entry.name, amount)
    if not ok then
        notify(src, 'You cannot carry that.', 'error')
        return
    end

    local removed, reason = exports['tc5_inventory']:RemoveCash(src, price)
    if not removed then
        notify(src, ('Cash removal failed: %s'):format(reason or 'unknown'), 'error')
        return
    end

    exports['tc5_inventory']:AddItem(src, entry.name, amount)

    notify(src, ('Bought %sx %s for $%s'):format(
        amount,
        TC5Items[entry.name] and TC5Items[entry.name].label or entry.name,
        price
    ), 'success')

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
end)

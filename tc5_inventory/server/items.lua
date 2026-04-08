local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_inventory:client:notify', src, {
        title = 'Inventory',
        message = message,
        type = notifyType or 'info'
    })
end

local function buildItemCatalog()
    local items = {}

    for itemName, def in pairs(TC5Items or {}) do
        if type(def) == 'table' then
            items[itemName] = {
                name = itemName,
                label = tostring(def.label or itemName),
                description = tostring(def.description or ''),
                weight = tonumber(def.weight) or 0,
                stack = def.stack == true,
                image = tostring(def.image or 'default.png'),
                close = def.close == true,
                durability = def.durability == true,
                defaultDurability = tonumber(def.defaultDurability) or nil,
                useEvent = tostring(def.useEvent or '')
            }
        end
    end

    return items
end

RegisterNetEvent('tc5_inventory:server:useItem', function(slot)
    local src = source
    local charId = exports['tc5_core']:GetCharacterId(src)
    if not charId then return end

    local inventory = TC5Inventory.GetInventory('player', charId)
    local item = inventory and inventory.items[tonumber(slot)]

    if not item then
        notify(src, 'Item not found.', 'error')
        return
    end

    local itemDef = TC5Items[item.name]
    if not itemDef then
        notify(src, 'Invalid item.', 'error')
        return
    end

    if itemDef.durability and item.metadata and item.metadata.durability then
        item.metadata.durability = math.max(0, (tonumber(item.metadata.durability) or 0) - 5)

        if item.metadata.durability <= 0 then
            inventory.items[tonumber(slot)] = nil
            TC5Inventory.SaveInventory(inventory)

            notify(src, ('%s broke.'):format(item.label), 'error')
            TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
            return
        end

        TC5Inventory.SaveInventory(inventory)
    end

    if itemDef.useEvent then
        TriggerClientEvent(itemDef.useEvent, src, item, tonumber(slot))
    else
        notify(src, ('Used %s.'):format(item.label), 'success')
    end

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
end)

RegisterNetEvent('tc5_inventory:server:giveItem', function(targetId, slot, amount)
    local src = source
    targetId = tonumber(targetId)
    amount = tonumber(amount) or 1

    if not targetId or GetPlayerPing(targetId) <= 0 then
        notify(src, 'Target player not found.', 'error')
        return
    end

    local sourceCharId = exports['tc5_core']:GetCharacterId(src)
    local targetCharId = exports['tc5_core']:GetCharacterId(targetId)

    if not sourceCharId or not targetCharId then
        notify(src, 'Character not loaded.', 'error')
        return
    end

    local sourceInventory = TC5Inventory.GetInventory('player', sourceCharId)
    local item = sourceInventory and sourceInventory.items[tonumber(slot)]

    if not item then
        notify(src, 'Item not found.', 'error')
        return
    end

    if amount <= 0 then
        notify(src, 'Invalid amount.', 'error')
        return
    end

    if amount > item.amount then
        amount = item.amount
    end

    local success, reason = TC5Inventory.AddItem('player', targetCharId, item.name, amount, item.metadata)
    if not success then
        notify(src, ('Give failed: %s'):format(reason or 'unknown'), 'error')
        return
    end

    local removed = TC5Inventory.RemoveItem('player', sourceCharId, item.name, amount, tonumber(slot))
    if not removed then
        notify(src, 'Failed to remove item from your inventory.', 'error')
        return
    end

    notify(src, ('Gave %sx %s.'):format(amount, item.label), 'success')
    notify(targetId, ('Received %sx %s.'):format(amount, item.label), 'success')

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    TriggerClientEvent('tc5_inventory:client:refreshInventory', targetId)
end)

RegisterNetEvent('tc5_inventory:server:dropItem', function(slot, amount, coords)
    local src = source
    local charId = exports['tc5_core']:GetCharacterId(src)
    if not charId then return end

    local inventory = TC5Inventory.GetInventory('player', charId)
    local item = inventory and inventory.items[tonumber(slot)]

    if not item then
        notify(src, 'Item not found.', 'error')
        return
    end

    amount = math.min(tonumber(amount) or 1, item.amount)

    if amount <= 0 then
        notify(src, 'Invalid amount.', 'error')
        return
    end

    if not coords or not coords.x or not coords.y or not coords.z then
        notify(src, 'Invalid drop position.', 'error')
        return
    end

    local removed = TC5Inventory.RemoveItem('player', charId, item.name, amount, tonumber(slot))
    if not removed then
        notify(src, 'Failed to drop item.', 'error')
        return
    end

    local dropId = TC5Inventory.CreateWorldDrop(coords, item.name, amount, item.metadata)

    notify(src, ('Dropped %sx %s.'):format(amount, item.label), 'success')
    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    TriggerClientEvent('tc5_inventory:client:addWorldDrop', -1, {
        id = dropId,
        coords = coords
    })
end)

RegisterNetEvent('tc5_inventory:server:cleanupDropIfEmpty', function(dropId)
    local src = source
    if not dropId then return end

    local inventory = TC5Inventory.GetInventory('drop', tostring(dropId))
    if not inventory then return end

    if TC5Inventory.IsInventoryEmpty('drop', tostring(dropId)) then
        TC5Inventory.DeleteWorldDrop(tostring(dropId))
    else
        TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    end
end)

exports('GetItems', function()
    return buildItemCatalog()
end)

exports('GetItemCatalog', function()
    return buildItemCatalog()
end)

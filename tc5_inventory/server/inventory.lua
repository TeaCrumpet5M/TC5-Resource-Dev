TC5Inventory = TC5Inventory or {}
TC5Inventory.Inventories = TC5Inventory.Inventories or {}
TC5Inventory.WorldDrops = TC5Inventory.WorldDrops or {}
TC5Inventory.Stashes = TC5Inventory.Stashes or {}

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function inventoryKey(invType, owner)
    return ('%s:%s'):format(invType, tostring(owner))
end

local function getInventoryConfig(invType, owner)
    if invType == 'player' then
        return {
            label = 'Inventory',
            maxWeight = TC5Inventory.Config.MaxWeight,
            maxSlots = TC5Inventory.Config.MaxSlots
        }
    end

    if invType == 'stash' then
        local stash = TC5Inventory.Stashes[tostring(owner)]
        if stash then
            return {
                label = stash.label,
                maxWeight = stash.maxWeight,
                maxSlots = stash.maxSlots
            }
        end
    end

    return TC5Inventory.Config.SecondaryInventories[invType]
end

function TC5Inventory.GetWeight(inventory)
    if not inventory or not inventory.items then
        return 0
    end

    local total = 0

    for _, item in pairs(inventory.items) do
        total = total + ((tonumber(item.weight) or 0) * (tonumber(item.amount) or 0))
    end

    return total
end

function TC5Inventory.NormalizeMetadata(itemName, metadata)
    local itemDef = TC5Items[itemName]
    metadata = metadata or {}

    if itemDef and itemDef.durability then
        metadata.durability = metadata.durability or itemDef.defaultDurability or 100
    end

    return metadata
end

function TC5Inventory.MetadataMatches(a, b)
    local encodedA = json.encode(a or {})
    local encodedB = json.encode(b or {})
    return encodedA == encodedB
end

function TC5Inventory.GetInventory(invType, owner)
    owner = tostring(owner)

    local key = inventoryKey(invType, owner)
    if TC5Inventory.Inventories[key] then
        return TC5Inventory.Inventories[key]
    end

    local config = getInventoryConfig(invType, owner)
    if not config then
        return nil
    end

    local rows = MySQL.query.await([[
        SELECT slot, item_name, amount, metadata
        FROM tc5_inventory_items
        WHERE inventory_type = ? AND inventory_owner = ?
        ORDER BY slot ASC
    ]], {
        invType,
        owner
    }) or {}

    local items = {}

    for i = 1, #rows do
        local row = rows[i]
        local itemDef = TC5Items[row.item_name]

        if itemDef then
            local metadata = {}

            if row.metadata and row.metadata ~= '' then
                local ok, decoded = pcall(json.decode, row.metadata)
                if ok and type(decoded) == 'table' then
                    metadata = decoded
                end
            end

            items[tonumber(row.slot)] = {
                slot = tonumber(row.slot),
                name = row.item_name,
                label = itemDef.label,
                amount = tonumber(row.amount) or 1,
                weight = tonumber(itemDef.weight) or 0,
                stack = itemDef.stack == true,
                close = itemDef.close == true,
                description = itemDef.description or '',
                image = itemDef.image or 'default.png',
                metadata = metadata
            }
        end
    end

    local inventory = {
        type = invType,
        owner = owner,
        label = config.label,
        maxWeight = config.maxWeight,
        maxSlots = config.maxSlots,
        items = items
    }

    TC5Inventory.Inventories[key] = inventory
    return inventory
end

function TC5Inventory.SaveInventory(inventory)
    if not inventory then
        return false
    end

    MySQL.update.await([[
        DELETE FROM tc5_inventory_items
        WHERE inventory_type = ? AND inventory_owner = ?
    ]], {
        inventory.type,
        tostring(inventory.owner)
    })

    for slot, item in pairs(inventory.items or {}) do
        MySQL.insert.await([[
            INSERT INTO tc5_inventory_items (inventory_type, inventory_owner, slot, item_name, amount, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            inventory.type,
            tostring(inventory.owner),
            tonumber(slot),
            item.name,
            tonumber(item.amount) or 1,
            json.encode(item.metadata or {})
        })
    end

    return true
end

function TC5Inventory.CanCarry(invType, owner, itemName, amount)
    local inventory = TC5Inventory.GetInventory(invType, owner)
    local itemDef = TC5Items[itemName]

    if not inventory or not itemDef then
        return false
    end

    local addWeight = (tonumber(itemDef.weight) or 0) * (tonumber(amount) or 0)
    return (TC5Inventory.GetWeight(inventory) + addWeight) <= inventory.maxWeight
end

function TC5Inventory.FindFreeSlot(inventory)
    for slot = 1, inventory.maxSlots do
        if not inventory.items[slot] then
            return slot
        end
    end

    return nil
end

function TC5Inventory.FindStackSlot(inventory, itemName, metadata)
    for slot = 1, inventory.maxSlots do
        local item = inventory.items[slot]

        if item
            and item.name == itemName
            and item.stack
            and TC5Inventory.MetadataMatches(item.metadata, metadata)
        then
            return slot
        end
    end

    return nil
end

function TC5Inventory.AddItem(invType, owner, itemName, amount, metadata, slot)
    amount = tonumber(amount) or 1

    local itemDef = TC5Items[itemName]
    local inventory = TC5Inventory.GetInventory(invType, owner)
    metadata = TC5Inventory.NormalizeMetadata(itemName, metadata)

    if not itemDef then
        return false, 'invalid_item'
    end

    if not inventory then
        return false, 'invalid_inventory'
    end

    if not TC5Inventory.CanCarry(invType, owner, itemName, amount) then
        return false, 'too_heavy'
    end

    local targetSlot = tonumber(slot)

    if not targetSlot and itemDef.stack then
        targetSlot = TC5Inventory.FindStackSlot(inventory, itemName, metadata)
    end

    if not targetSlot then
        targetSlot = TC5Inventory.FindFreeSlot(inventory)
    end

    if not targetSlot then
        return false, 'no_slot'
    end

    local existing = inventory.items[targetSlot]

    if existing then
        if existing.name == itemName and existing.stack and TC5Inventory.MetadataMatches(existing.metadata, metadata) then
            existing.amount = existing.amount + amount
        else
            return false, 'slot_occupied'
        end
    else
        inventory.items[targetSlot] = {
            slot = targetSlot,
            name = itemName,
            label = itemDef.label,
            amount = amount,
            weight = tonumber(itemDef.weight) or 0,
            stack = itemDef.stack == true,
            close = itemDef.close == true,
            description = itemDef.description or '',
            image = itemDef.image or 'default.png',
            metadata = metadata
        }
    end

    TC5Inventory.SaveInventory(inventory)
    return true, targetSlot
end

function TC5Inventory.RemoveItem(invType, owner, itemName, amount, slot)
    amount = tonumber(amount) or 1

    local inventory = TC5Inventory.GetInventory(invType, owner)
    if not inventory then
        return false, 'invalid_inventory'
    end

    local item = inventory.items[tonumber(slot)]
    if not item or item.name ~= itemName then
        return false, 'item_not_found'
    end

    item.amount = item.amount - amount

    if item.amount <= 0 then
        inventory.items[tonumber(slot)] = nil
    end

    TC5Inventory.SaveInventory(inventory)
    return true
end

function TC5Inventory.SplitItem(invType, owner, fromSlot, toSlot, amount)
    local inventory = TC5Inventory.GetInventory(invType, owner)
    if not inventory then
        return false, 'invalid_inventory'
    end

    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)
    amount = tonumber(amount) or 1

    local item = inventory.items[fromSlot]
    if not item then
        return false, 'item_not_found'
    end

    if amount <= 0 or amount >= item.amount then
        return false, 'invalid_amount'
    end

    if inventory.items[toSlot] then
        return false, 'slot_occupied'
    end

    item.amount = item.amount - amount

    inventory.items[toSlot] = {
        slot = toSlot,
        name = item.name,
        label = item.label,
        amount = amount,
        weight = item.weight,
        stack = item.stack,
        close = item.close,
        description = item.description,
        image = item.image,
        metadata = json.decode(json.encode(item.metadata or {}))
    }

    TC5Inventory.SaveInventory(inventory)
    return true
end

function TC5Inventory.MoveItem(fromType, fromOwner, toType, toOwner, fromSlot, toSlot, amount)
    amount = tonumber(amount) or 1

    local fromInventory = TC5Inventory.GetInventory(fromType, fromOwner)
    local toInventory = TC5Inventory.GetInventory(toType, toOwner)

    if not fromInventory or not toInventory then
        return false, 'invalid_inventory'
    end

    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)

    local fromItem = fromInventory.items[fromSlot]
    if not fromItem then
        return false, 'invalid_item'
    end

    if amount > fromItem.amount then
        amount = fromItem.amount
    end

    if not TC5Inventory.CanCarry(toType, toOwner, fromItem.name, amount) then
        return false, 'too_heavy'
    end

    if fromType == toType and tostring(fromOwner) == tostring(toOwner) then
        local toItem = toInventory.items[toSlot]

        if toItem
            and toItem.name == fromItem.name
            and toItem.stack
            and TC5Inventory.MetadataMatches(toItem.metadata, fromItem.metadata)
        then
            toItem.amount = toItem.amount + amount
            fromItem.amount = fromItem.amount - amount

            if fromItem.amount <= 0 then
                fromInventory.items[fromSlot] = nil
            end

            TC5Inventory.SaveInventory(fromInventory)
            return true
        end

        if not toItem then
            if amount == fromItem.amount then
                toInventory.items[toSlot] = fromItem
                toInventory.items[toSlot].slot = toSlot
                fromInventory.items[fromSlot] = nil
                TC5Inventory.SaveInventory(fromInventory)
                return true
            else
                return TC5Inventory.SplitItem(fromType, fromOwner, fromSlot, toSlot, amount)
            end
        end

        return false, 'slot_occupied'
    end

    local ok, reason = TC5Inventory.AddItem(toType, toOwner, fromItem.name, amount, fromItem.metadata, toSlot)
    if not ok then
        return false, reason
    end

    local removed = TC5Inventory.RemoveItem(fromType, fromOwner, fromItem.name, amount, fromSlot)
    if not removed then
        return false, 'move_failed'
    end

    return true
end

function TC5Inventory.RegisterStash(stashId, data)
    TC5Inventory.Stashes[tostring(stashId)] = {
        label = data.label or 'Stash',
        owner = data.owner or stashId,
        maxWeight = data.maxWeight or TC5Inventory.Config.SecondaryInventories.stash.maxWeight,
        maxSlots = data.maxSlots or TC5Inventory.Config.SecondaryInventories.stash.maxSlots
    }
end

function TC5Inventory.CreateWorldDrop(coords, itemName, amount, metadata)
    local dropId = ('drop_%s_%s'):format(math.random(100000, 999999), os.time())

    TC5Inventory.WorldDrops[dropId] = {
        id = dropId,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        createdAt = os.time()
    }

    MySQL.insert.await([[
        INSERT INTO tc5_inventory_drops (id, x, y, z)
        VALUES (?, ?, ?, ?)
    ]], {
        dropId,
        coords.x,
        coords.y,
        coords.z
    })

    TC5Inventory.AddItem('drop', dropId, itemName, amount, metadata)

    return dropId
end

function TC5Inventory.DeleteWorldDrop(dropId)
    TC5Inventory.WorldDrops[dropId] = nil
    TC5Inventory.Inventories[inventoryKey('drop', dropId)] = nil

    MySQL.update.await('DELETE FROM tc5_inventory_drops WHERE id = ?', {
        dropId
    })

    MySQL.update.await('DELETE FROM tc5_inventory_items WHERE inventory_type = ? AND inventory_owner = ?', {
        'drop',
        tostring(dropId)
    })
end

function TC5Inventory.IsInventoryEmpty(invType, owner)
    local inventory = TC5Inventory.GetInventory(invType, owner)
    if not inventory or not inventory.items then
        return true
    end

    for _, item in pairs(inventory.items) do
        if item and (tonumber(item.amount) or 0) > 0 then
            return false
        end
    end

    return true
end

exports('GetInventory', function(src)
    local charId = getCharacterId(src)
    if not charId then
        return nil
    end

    return TC5Inventory.GetInventory('player', charId)
end)

exports('AddItem', function(src, itemName, amount, metadata, slot)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'no_character'
    end

    return TC5Inventory.AddItem('player', charId, itemName, amount, metadata, slot)
end)

exports('RemoveItem', function(src, itemName, amount, slot)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'no_character'
    end

    return TC5Inventory.RemoveItem('player', charId, itemName, amount, slot)
end)

exports('CanCarryItem', function(src, itemName, amount)
    local charId = getCharacterId(src)
    if not charId then
        return false
    end

    return TC5Inventory.CanCarry('player', charId, itemName, amount)
end)

exports('GetItemCount', function(src, itemName)
    local charId = getCharacterId(src)
    if not charId then
        return 0
    end

    local inventory = TC5Inventory.GetInventory('player', charId)
    local total = 0

    for _, item in pairs(inventory and inventory.items or {}) do
        if item.name == itemName then
            total = total + (tonumber(item.amount) or 0)
        end
    end

    return total
end)

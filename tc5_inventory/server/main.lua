local function notify(src, message, notifyType)
    TriggerClientEvent('tc5_inventory:client:notify', src, {
        title = 'Inventory',
        message = message,
        type = notifyType or 'info'
    })
end

local function buildClientInventory(inventory)
    if not inventory then return nil end

    return {
        type = inventory.type,
        owner = inventory.owner,
        label = inventory.label,
        maxWeight = inventory.maxWeight,
        maxSlots = inventory.maxSlots,
        currentWeight = TC5Inventory.GetWeight(inventory),
        items = inventory.items
    }
end

local function buildShopInventory(shopId)
    local shop = TC5Shops[shopId]
    if not shop then return nil end

    local items = {}

    for slot = 1, #shop.inventory do
        local entry = shop.inventory[slot]
        local def = TC5Items[entry.name]

        if def then
            items[slot] = {
                slot = slot,
                name = entry.name,
                label = def.label,
                amount = entry.amount or 999,
                weight = def.weight or 0,
                stack = def.stack == true,
                close = false,
                description = def.description or '',
                image = def.image or 'default.png',
                metadata = {
                    price = entry.price or 0
                }
            }
        end
    end

    return {
        type = 'shop',
        owner = shopId,
        label = shop.label,
        maxWeight = 1000000,
        maxSlots = math.max(#shop.inventory, 40),
        items = items
    }
end

RegisterNetEvent('tc5_inventory:server:openInventory', function(data)
    local src = source
    local charId = exports['tc5_core']:GetCharacterId(src)
    if not charId then return end

    local playerInventory = TC5Inventory.GetInventory('player', charId)
    local secondaryInventory = nil

    if data and data.type and data.owner then
        if data.type == 'shop' then
            secondaryInventory = buildShopInventory(data.owner)
        else
            secondaryInventory = TC5Inventory.GetInventory(data.type, data.owner)
        end
    end

    TriggerClientEvent('tc5_inventory:client:openInventory', src, {
        player = buildClientInventory(playerInventory),
        secondary = buildClientInventory(secondaryInventory)
    })
end)

RegisterNetEvent('tc5_inventory:server:refreshInventory', function()
    local src = source
    local charId = exports['tc5_core']:GetCharacterId(src)
    if not charId then return end

    local playerInventory = TC5Inventory.GetInventory('player', charId)

    TriggerClientEvent('tc5_inventory:client:refreshInventoryData', src, {
        player = buildClientInventory(playerInventory)
    })
end)

RegisterNetEvent('tc5_inventory:server:moveItem', function(data)
    local src = source
    local charId = exports['tc5_core']:GetCharacterId(src)
    if not charId or type(data) ~= 'table' then return end

    local fromType = data.fromType
    local fromOwner = data.fromOwner
    local toType = data.toType
    local toOwner = data.toOwner
    local fromSlot = tonumber(data.fromSlot)
    local toSlot = tonumber(data.toSlot)
    local amount = tonumber(data.amount) or 1

    if fromType == 'player' then fromOwner = charId end
    if toType == 'player' then toOwner = charId end

    if fromType == 'shop' or toType == 'shop' then
        notify(src, 'Drag/drop with shops is disabled. Click to buy instead.', 'error')

        local secondaryInventory = nil
        if data and data.toType == 'shop' then
            secondaryInventory = buildShopInventory(data.toOwner)
        elseif data and data.fromType == 'shop' then
            secondaryInventory = buildShopInventory(data.fromOwner)
        end

        TriggerClientEvent('tc5_inventory:client:refreshOpenInventories', src, {
            player = buildClientInventory(TC5Inventory.GetInventory('player', charId)),
            secondary = buildClientInventory(secondaryInventory)
        })
        return
    end

    local success, reason = TC5Inventory.MoveItem(fromType, fromOwner, toType, toOwner, fromSlot, toSlot, amount)
    if not success then
        notify(src, ('Move failed: %s'):format(reason or 'unknown'), 'error')
    end

    if fromType == 'drop' and TC5Inventory.IsInventoryEmpty('drop', fromOwner) then
        TC5Inventory.DeleteWorldDrop(tostring(fromOwner))
        TriggerClientEvent('tc5_inventory:client:removeWorldDrop', -1, tostring(fromOwner))
    end

    if toType == 'drop' and TC5Inventory.IsInventoryEmpty('drop', toOwner) then
        TC5Inventory.DeleteWorldDrop(tostring(toOwner))
        TriggerClientEvent('tc5_inventory:client:removeWorldDrop', -1, tostring(toOwner))
    end

    local playerInventory = TC5Inventory.GetInventory('player', charId)
    local secondaryInventory = nil

    if toType ~= 'player' then
        secondaryInventory = TC5Inventory.GetInventory(toType, toOwner)
    elseif fromType ~= 'player' then
        secondaryInventory = TC5Inventory.GetInventory(fromType, fromOwner)
    end

    if secondaryInventory and secondaryInventory.type == 'drop' and TC5Inventory.IsInventoryEmpty('drop', secondaryInventory.owner) then
        secondaryInventory = nil
    end

    TriggerClientEvent('tc5_inventory:client:refreshOpenInventories', src, {
        player = buildClientInventory(playerInventory),
        secondary = buildClientInventory(secondaryInventory)
    })
end)

RegisterNetEvent('tc5_inventory:server:requestWorldDrops', function()
    local src = source
    local drops = {}

    for dropId, drop in pairs(TC5Inventory.WorldDrops or {}) do
        drops[#drops + 1] = {
            id = dropId,
            coords = drop.coords
        }
    end

    TriggerClientEvent('tc5_inventory:client:setWorldDrops', src, drops)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local rows = MySQL.query.await('SELECT * FROM tc5_inventory_drops') or {}

    for i = 1, #rows do
        local row = rows[i]
        TC5Inventory.WorldDrops[row.id] = {
            id = row.id,
            coords = {
                x = row.x,
                y = row.y,
                z = row.z
            },
            createdAt = os.time()
        }
    end

    print('^2[tc5_inventory]^7 Inventory started.')
end)

RegisterCommand(TC5Inventory.Config.OpenCommand, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_inventory:client:toggleInventory', src)
end, false)

exports('OpenInventory', function(src, invType, owner)
    TriggerClientEvent('tc5_inventory:client:forceOpenInventory', src, {
        type = invType,
        owner = owner
    })
end)
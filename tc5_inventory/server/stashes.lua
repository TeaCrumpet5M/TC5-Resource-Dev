TC5Inventory = TC5Inventory or {}
TC5Inventory.Stashes = TC5Inventory.Stashes or {}

function TC5Inventory.RegisterStash(stashId, data)
    TC5Inventory.Stashes[tostring(stashId)] = {
        label = data.label or 'Stash',
        owner = data.owner or stashId,
        maxWeight = data.maxWeight or TC5Inventory.Config.SecondaryInventories.stash.maxWeight,
        maxSlots = data.maxSlots or TC5Inventory.Config.SecondaryInventories.stash.maxSlots
    }
end

CreateThread(function()
    if not TC5NamedStashes then return end

    for stashId, data in pairs(TC5NamedStashes) do
        TC5Inventory.RegisterStash(stashId, data or {})
    end
end)

exports('RegisterStash', function(stashId, data)
    TC5Inventory.RegisterStash(stashId, data or {})
end)

exports('OpenStash', function(src, stashId)
    local stash = TC5Inventory.Stashes[tostring(stashId)]
    if not stash then
        return false
    end

    TriggerClientEvent('tc5_inventory:client:forceOpenInventory', src, {
        type = 'stash',
        owner = tostring(stashId)
    })

    return true
end)
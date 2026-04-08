RegisterCommand(TC5Inventory.Config.HotbarCommand, function()
    TriggerServerEvent('tc5_inventory:server:refreshInventory')
end, false)

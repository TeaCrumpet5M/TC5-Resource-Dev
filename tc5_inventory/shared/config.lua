TC5Inventory = TC5Inventory or {}
TC5Inventory.Config = {}

TC5Inventory.Config.Debug = true
TC5Inventory.Config.MaxSlots = 40
TC5Inventory.Config.MaxWeight = 30000
TC5Inventory.Config.HotbarSlots = 5

TC5Inventory.Config.OpenCommand = 'inventory'
TC5Inventory.Config.HotbarCommand = 'hotbar'

TC5Inventory.Config.SecondaryInventories = {
    trunk = {
        label = 'Vehicle Trunk',
        maxWeight = 80000,
        maxSlots = 50
    },
    glovebox = {
        label = 'Vehicle Glovebox',
        maxWeight = 10000,
        maxSlots = 10
    },
    stash = {
        label = 'Stash',
        maxWeight = 100000,
        maxSlots = 80
    },
    drop = {
        label = 'Ground',
        maxWeight = 100000,
        maxSlots = 40
    },
    shop = {
        label = 'Shop',
        maxWeight = 1000000,
        maxSlots = 40
    }
}

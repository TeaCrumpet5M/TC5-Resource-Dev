TC5Items = {
    cash = {
        label = 'Cash',
        weight = 0,
        stack = true,
        image = 'cash.png',
        description = 'Physical money'
    },

    water = {
        label = 'Water',
        weight = 500,
        stack = true,
        image = 'water.png'
    },

    lockpick = {
        label = 'Lockpick',
        weight = 200,
        stack = false,
        image = 'lockpick.png',
        durability = true,
        defaultDurability = 100
    },

    phone = {
        label = 'Phone',
        weight = 800,
        stack = false,
        image = 'phone.png'
    },

    tablet = {
        label = 'Encrypted Tablet',
        weight = 1200,
        stack = false,
        image = 'tablet.png',
        description = 'A modular tablet that can load USB apps.',
        useEvent = 'tc5_tablet:client:useTablet'
    },

    usb_boosting = {
        label = 'Boosting USB',
        weight = 100,
        stack = false,
        image = 'usb_boosting.png',
        description = 'Contains a boosting application for your tablet.'
    },

    scrap_metal = {
        label = 'Scrap Metal',
        weight = 500,
        stack = true,
        image = 'scrap_metal.png',
        description = 'Used to craft mechanical components.'
    },

    rubber = {
        label = 'Rubber',
        weight = 300,
        stack = true,
        image = 'rubber.png',
        description = 'Essential material for tyres and seals.'
    },

    electronics = {
        label = 'Electronics',
        weight = 200,
        stack = true,
        image = 'electronics.png',
        description = 'Used for advanced vehicle repairs.'
    },

    glass = {
        label = 'Glass',
        weight = 400,
        stack = true,
        image = 'glass.png',
        description = 'Used to replace damaged windows.'
    },

    oil = {
        label = 'Engine Oil',
        weight = 600,
        stack = true,
        image = 'oil.png',
        description = 'Required for engine servicing.'
    },

    engine_parts = {
        label = 'Engine Parts',
        weight = 1200,
        stack = true,
        image = 'engine_parts.png',
        description = 'Used to repair engine damage.'
    },

    body_parts = {
        label = 'Body Parts',
        weight = 1000,
        stack = true,
        image = 'body_parts.png',
        description = 'Used to repair vehicle body damage.'
    },

    tyre = {
        label = 'Tyre',
        weight = 800,
        stack = true,
        image = 'tyre.png',
        description = 'Replacement tyre for damaged wheels.'
    },

    glass_kit = {
        label = 'Glass Repair Kit',
        weight = 700,
        stack = true,
        image = 'glass_kit.png',
        description = 'Used to repair vehicle windows.'
    },

    electronics_kit = {
        label = 'Electronics Kit',
        weight = 600,
        stack = true,
        image = 'electronics_kit.png',
        description = 'Used to repair vehicle electronics and sensors.'
    },

    repair_kit_basic = {
        label = 'Basic Repair Kit',
        weight = 1500,
        stack = false,
        image = 'repair_kit_basic.png',
        durability = true,
        defaultDurability = 100,
        description = 'Used for minor vehicle repairs.'
    },

    repair_kit_advanced = {
        label = 'Advanced Repair Kit',
        weight = 2000,
        stack = false,
        image = 'repair_kit_advanced.png',
        durability = true,
        defaultDurability = 150,
        description = 'Used for advanced vehicle repairs.'
    },

    mechanic_toolbox = {
        label = 'Mechanic Toolbox',
        weight = 2500,
        stack = false,
        image = 'toolbox.png',
        durability = true,
        defaultDurability = 200,
        description = 'Contains essential tools for mechanics.'
    },

    full_service_kit = {
        label = 'Full Service Kit',
        weight = 3000,
        stack = false,
        image = 'full_service_kit.png',
        description = 'Used to fully restore a vehicle to perfect condition.'
    }
}

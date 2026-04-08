TC5Items = {
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
    }
}
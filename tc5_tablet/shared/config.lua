TC5Tablet = TC5Tablet or {}

TC5Tablet.Config = {
    TabletItem = 'tablet',
    OpenCommand = 'tablet',

    Prop = {
        Model = `prop_cs_tablet`,
        Bone = 57005,
        Offset = vec3(0.17, 0.10, -0.13),
        Rotation = vec3(20.0, 180.0, 180.0)
    },

    Animation = {
        Dict = 'amb@world_human_seat_wall_tablet@female@base',
        Clip = 'base',
        Flag = 49
    },

    BootTime = 900,

    Apps = {
        boosting = {
            id = 'boosting',
            label = 'Boosting',
            icon = 'BOOST',
            usbItem = 'usb_boosting',
            accent = '#ff5f57'
        }
    },

    Boosting = {
        CooldownSeconds = 15,
        StartingRep = 0,
        Tiers = {
            D = {
                minRep = 0,
                payout = { min = 1500, max = 2500 },
                vehicles = { 'blista', 'asea', 'prairie' }
            },
            C = {
                minRep = 3,
                payout = { min = 2500, max = 4000 },
                vehicles = { 'sultan', 'buffalo', 'schafter2' }
            },
            B = {
                minRep = 8,
                payout = { min = 4000, max = 6500 },
                vehicles = { 'jugular', 'kuruma', 'elegy' }
            }
        },
        PickupLocations = {
            vec4(215.84, -810.12, 30.73, 157.2),
            vec4(-42.41, -1097.67, 26.42, 90.0),
            vec4(273.91, -343.21, 44.91, 251.0),
            vec4(903.12, -55.17, 78.76, 58.0),
            vec4(-1183.42, -1496.21, 4.37, 124.0)
        },
        DropoffLocations = {
            vec3(1204.88, -3116.32, 5.54),
            vec3(-456.12, -2794.91, 6.00),
            vec3(1731.25, 3311.42, 41.22)
        }
    }
}

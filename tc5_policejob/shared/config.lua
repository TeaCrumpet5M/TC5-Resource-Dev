TC5Police = TC5Police or {}

TC5Police.Config = {
    JobName = 'police',
    DefaultGrade = 0,
    UseTC5Eye = true,
    UseTargetFallbackMarkers = true,
    Theme = {
        Primary = '#b10f1f',
        PrimarySoft = 'rgba(177, 15, 31, 0.18)',
        Background = '#090909',
        Panel = '#121212',
        PanelAlt = '#1a1a1a',
        Border = 'rgba(255,255,255,0.08)',
        Text = '#ffffff',
        Muted = '#c6c6c6',
        Success = '#2ecc71',
        Error = '#ff4d4f',
        Warning = '#f4b400'
    },
    JobDefinition = {
        name = 'police',
        label = 'Police',
        defaultDuty = false,
        grades = {
            [0] = { label = 'Cadet', salary = 250 },
            [1] = { label = 'Officer', salary = 400 },
            [2] = { label = 'Senior Officer', salary = 550 },
            [3] = { label = 'Sergeant', salary = 700 },
            [4] = { label = 'Lieutenant', salary = 900 },
            [5] = { label = 'Chief', salary = 1200 }
        }
    },
    Stations = {
        missionrow = {
            label = 'Mission Row Police Department',
            duty = vector3(441.4127, -978.8524, 30.6896),
            armory = vector3(441.4127, -978.8524, 30.6896),
            garageMenu = vector3(441.4127, -978.8524, 30.6896),
            garageSpawn = vector4(435.2232, -1017.6968, 28.8184, 103.6468),
            bossmenu = vector3(448.42, -973.24, 30.69)
        }
    },
    Armory = {
        CooldownSeconds = 5,
        Items = {
            {
                id = 'standard_kit',
                label = 'Standard Duty Kit',
                description = 'Taser, flashlight, nightstick and service pistol.',
                minGrade = 0,
                loadout = {
                    { type = 'weapon', name = 'WEAPON_STUNGUN', ammo = 1 },
                    { type = 'weapon', name = 'WEAPON_FLASHLIGHT', ammo = 1 },
                    { type = 'weapon', name = 'WEAPON_NIGHTSTICK', ammo = 1 },
                    { type = 'weapon', name = 'WEAPON_COMBATPISTOL', ammo = 60 }
                }
            },
            {
                id = 'traffic_kit',
                label = 'Traffic Kit',
                description = 'Extra carbine for higher-risk traffic deployment.',
                minGrade = 2,
                loadout = {
                    { type = 'weapon', name = 'WEAPON_FLASHLIGHT', ammo = 1 },
                    { type = 'weapon', name = 'WEAPON_COMBATPISTOL', ammo = 72 },
                    { type = 'weapon', name = 'WEAPON_CARBINERIFLE', ammo = 120 }
                }
            },
            {
                id = 'command_kit',
                label = 'Command Kit',
                description = 'Command-grade duty loadout with shotgun support.',
                minGrade = 4,
                loadout = {
                    { type = 'weapon', name = 'WEAPON_FLASHLIGHT', ammo = 1 },
                    { type = 'weapon', name = 'WEAPON_COMBATPISTOL', ammo = 90 },
                    { type = 'weapon', name = 'WEAPON_CARBINERIFLE', ammo = 180 },
                    { type = 'weapon', name = 'WEAPON_PUMPSHOTGUN', ammo = 24 }
                }
            }
        }
    },
    Garage = {
        Fuel = 100.0,
        WarpIntoVehicle = true,
        Livery = -1,
        Extras = {},
        Vehicles = {
            { id = 'police1', label = 'Vapid Cruiser', model = 'police', minGrade = 0 },
            { id = 'police2', label = 'Buffalo Interceptor', model = 'police2', minGrade = 1 },
            { id = 'police3', label = 'Stanier Interceptor', model = 'police3', minGrade = 2 },
            { id = 'riot', label = 'Riot Van', model = 'riot', minGrade = 4 }
        }
    },
    Commands = {
        ToggleDuty = 'pdduty',
        OpenPanel = 'pd',
        Recruit = 'pdhire',
        SetGrade = 'pdgrade',
        Fire = 'pdfire',
        ReturnVehicle = 'pdreturn'
    }
}

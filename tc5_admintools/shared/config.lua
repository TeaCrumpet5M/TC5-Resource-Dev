TC5Admin = TC5Admin or {}
TC5Admin.Config = {}

TC5Admin.Config.Command = 'admin'
TC5Admin.Config.OpenKey = 'PAGEDOWN'
TC5Admin.Config.GiveKeysCommand = 'givekeys'
TC5Admin.Config.GiveKeysMinutes = 60
TC5Admin.Config.DevModeCommand = 'devmode'
TC5Admin.Config.Debug = true

TC5Admin.Config.Noclip = {
    Slow = 0.5,
    Normal = 2.5,
    Fast = 6.0
}

TC5Admin.Config.Logging = {
    Enabled = true,
    FileName = 'admin_logs.txt'
}

TC5Admin.Config.Reports = {
    Enabled = true
}

TC5Admin.Config.VehicleSpawner = {
    DefaultGarage = 'admin_lot',
    UsePermanentKeys = true,
    FallbackToTempKeysMinutes = 1440,
    SaveToAdminTable = true,
    SaveToOwnedVehicles = false,
    OwnedVehiclesInsertQuery = [[
        INSERT INTO owned_vehicles (owner, plate, vehicle, stored, garage)
        VALUES (?, ?, ?, ?, ?)
    ]],
    Categories = {
        { id = 'emergency', label = 'Emergency' },
        { id = 'sedans', label = 'Sedans' },
        { id = 'sports', label = 'Sports' },
        { id = 'imports', label = 'Imports' },
        { id = 'suvs', label = 'SUVs' },
        { id = 'utility', label = 'Utility' },
        { id = 'bikes', label = 'Bikes' }
    },
    Vehicles = {
        { model = 'police', label = 'Police Cruiser', brand = 'Vapid', category = 'emergency', class = 'sedan' },
        { model = 'police2', label = 'Police Buffalo', brand = 'Bravado', category = 'emergency', class = 'muscle' },
        { model = 'police3', label = 'Police Interceptor', brand = 'Vapid', category = 'emergency', class = 'sedan' },
        { model = 'fbi', label = 'FIB Buffalo', brand = 'Bravado', category = 'emergency', class = 'sedan' },
        { model = 'sultan', label = 'Sultan', brand = 'Karin', category = 'sports', class = 'sports' },
        { model = 'urusperf23', label = 'Urus', brand = 'Lamborghini', category = 'imports', class = 'sports' },
        { model = 'bmwm8', label = 'M8', brand = 'BMW', category = 'imports', class = 'sports' },
        { model = 'elegy', label = 'Elegy Retro', brand = 'Annis', category = 'sports', class = 'sports' },
        { model = 'comet2', label = 'Comet', brand = 'Pfister', category = 'sports', class = 'sports' },
        { model = 'tailgater', label = 'Tailgater', brand = 'Obey', category = 'sedans', class = 'sedan' },
        { model = 'premier', label = 'Premier', brand = 'Declasse', category = 'sedans', class = 'sedan' },
        { model = 'asea', label = 'Asea', brand = 'Declasse', category = 'sedans', class = 'sedan' },
        { model = 'granger', label = 'Granger', brand = 'Declasse', category = 'suvs', class = 'suv' },
        { model = 'baller2', label = 'Baller', brand = 'Gallivanter', category = 'suvs', class = 'suv' },
        { model = 'dubsta', label = 'Dubsta', brand = 'Benefactor', category = 'suvs', class = 'suv' },
        { model = 'bison', label = 'Bison', brand = 'Bravado', category = 'utility', class = 'truck' },
        { model = 'sadler', label = 'Sadler', brand = 'Vapid', category = 'utility', class = 'truck' },
        { model = 'speedo', label = 'Speedo', brand = 'Vapid', category = 'utility', class = 'van' },
        { model = 'bati', label = 'Bati 801', brand = 'Pegassi', category = 'bikes', class = 'bike' },
        { model = 'hakuchou', label = 'Hakuchou', brand = 'Shitzu', category = 'bikes', class = 'bike' },
        { model = 'daemon', label = 'Daemon', brand = 'Western', category = 'bikes', class = 'bike' }
    }
}

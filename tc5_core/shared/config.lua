TC5 = TC5 or {}
TC5.Config = {}

TC5.Config.FrameworkName = 'tc5_core'
TC5.Config.Debug = true
TC5.Config.IdentifierType = 'license'
TC5.Config.AutoCreateUserOnJoin = true
TC5.Config.SaveIntervalMinutes = 5

TC5.Config.DefaultCharacter = {
    FirstName = 'New',
    LastName = 'Citizen',
    Cash = 500,
    Bank = 5000
}

TC5.Config.StartingApartment = {
    Label = 'Alta Street Apartment',
    Shell = 'modern_apartment_1',
    Entrance = vector4(-269.62, -957.87, 31.22, 205.16),
    Interior = vector4(266.11, -1007.68, -101.01, 357.44)
}

TC5.Config.StarterSpawn = {
    vector4(-269.62, -957.87, 31.22, 205.16),
    vector4(-1037.76, -2737.88, 20.17, 328.24),
    vector4(215.81, -810.12, 30.73, 157.20)
}

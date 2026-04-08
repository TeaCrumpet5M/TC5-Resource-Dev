TC5BossMenu = TC5BossMenu or {}
TC5BossMenu.Config = {
    InteractKey = 38, -- E
    InteractDistance = 2.0,
    MarkerDistance = 8.0,
    HireDistance = 4.0,

    BossGrades = {
        police = 3,
        ambulance = 3,
        mechanic = 3
    },

    JobMenus = {
        police = {
            label = 'Police Boss Menu',
            coords = vector3(448.95, -973.22, 30.69)
        },
        ambulance = {
            label = 'EMS Boss Menu',
            coords = vector3(335.61, -594.63, 43.28)
        },
        mechanic = {
            label = 'Mechanic Boss Menu',
            coords = vector3(-347.54, -133.45, 39.01)
        }
    },

    DefaultHireGrade = 0,
    DefaultSalary = 250,
    MaxSalary = 5000
}

TC5Mechanic = TC5Mechanic or {}
TC5Mechanic.Config = TC5Mechanic.Config or {}

TC5Mechanic.Config.Debug = true
TC5Mechanic.Config.RequireDuty = true
TC5Mechanic.Config.ScanDistance = 6.0
TC5Mechanic.Config.InteractDistance = 1.75
TC5Mechanic.Config.MarkerDistance = 18.0
TC5Mechanic.Config.MenuCommand = 'mech'
TC5Mechanic.Config.CurrencyLabel = '$'

TC5Mechanic.Config.DefaultGrades = {
    [0] = { label = 'Apprentice', salary = 200 },
    [1] = { label = 'Mechanic', salary = 350 },
    [2] = { label = 'Senior Mechanic', salary = 500 },
    [3] = { label = 'Lead Tech', salary = 700 },
    [4] = { label = 'Manager', salary = 900 },
    [5] = { label = 'Owner', salary = 1200 }
}

TC5Mechanic.Config.SharedRecipes = {
    engine_parts = {
        label = 'Engine Parts',
        item = 'engine_parts',
        amount = 1,
        craftTime = 7000,
        materials = {
            scrap_metal = 4,
            oil = 2,
            electronics = 1
        }
    },
    body_parts = {
        label = 'Body Parts',
        item = 'body_parts',
        amount = 1,
        craftTime = 5000,
        materials = {
            scrap_metal = 5,
            rubber = 1
        }
    },
    tyre_parts = {
        label = 'Tyre Parts',
        item = 'tyre_parts',
        amount = 1,
        craftTime = 4000,
        materials = {
            rubber = 4,
            scrap_metal = 1
        }
    },
    electronics_parts = {
        label = 'Electronics Parts',
        item = 'electronics_parts',
        amount = 1,
        craftTime = 6000,
        materials = {
            electronics = 3,
            scrap_metal = 1
        }
    },
    full_service_kit = {
        label = 'Full Service Kit',
        item = 'full_service_kit',
        amount = 1,
        craftTime = 10000,
        materials = {
            engine_parts = 1,
            body_parts = 1,
            tyre_parts = 1,
            electronics_parts = 1
        }
    }
}

TC5Mechanic.Config.SharedRepairs = {
    engine = {
        label = 'Engine Repair',
        item = 'engine_parts',
        time = 10000,
        minGrade = 1,
        fix = 'engine'
    },
    body = {
        label = 'Body Repair',
        item = 'body_parts',
        time = 8000,
        minGrade = 0,
        fix = 'body'
    },
    tyres = {
        label = 'Tyre Replacement',
        item = 'tyre_parts',
        time = 6000,
        minGrade = 0,
        fix = 'tyres'
    },
    electronics = {
        label = 'Electronics Service',
        item = 'electronics_parts',
        time = 7000,
        minGrade = 1,
        fix = 'electronics'
    },
    fullservice = {
        label = 'Full Service',
        item = 'full_service_kit',
        time = 15000,
        minGrade = 2,
        fix = 'fullservice'
    }
}

TC5Mechanic.Config.SharedStock = {
    scrap_metal = { label = 'Scrap Metal', item = 'scrap_metal', amount = 5, price = 150 },
    rubber = { label = 'Rubber', item = 'rubber', amount = 3, price = 100 },
    oil = { label = 'Oil', item = 'oil', amount = 2, price = 120 },
    electronics = { label = 'Electronics', item = 'electronics', amount = 2, price = 180 }
}

TC5Mechanic.Config.Shops = {
    galaxys = {
        enabled = true,
        label = "Galaxy's Motorworks",
        job = 'mechanic_Galaxys',
        icon = 'BEN',
        accent = '#d63b3b',
        bossGrades = { [4] = true, [5] = true },
        grades = {
                 [0] = { label = 'Trainee', salary = 180 },
                 [1] = { label = 'Mechanic', salary = 325 },
                 [2] = { label = 'Senior Mechanic', salary = 475 },
                 [3] = { label = 'Shop Lead', salary = 650 },
                 [4] = { label = 'Manager', salary = 850 },
                 [5] = { label = 'Owner', salary = 1100 },

        },
        locations = {
            duty = vec3(308.5997, -704.2717, 29.5824),
            boss = vec3(313.4858, -702.1065, 33.9434),
            crafting = vec3(287.7386, -695.8843, 29.5458),
            repair = vec3(288.5187, -692.9570, 29.6359),
            shop = vec3(296.1456, -685.3162, 29.5458)
        },
        recipes = true,
        repairs = true,
        stock = true
    },
    hayes = {
        enabled = true,
        label = 'Hayes Autos',
        job = 'mechanic_hayes',
        icon = 'HAY',
        accent = '#4f8cff',
        bossGrades = { [4] = true, [5] = true },
        grades = {
            [0] = { label = 'Trainee', salary = 180 },
            [1] = { label = 'Mechanic', salary = 325 },
            [2] = { label = 'Senior Mechanic', salary = 475 },
            [3] = { label = 'Shop Lead', salary = 650 },
            [4] = { label = 'Manager', salary = 850 },
            [5] = { label = 'Owner', salary = 1100 }
        },
        locations = {
            duty = vec3(-1414.28, -455.41, 35.91),
            boss = vec3(-1411.33, -451.20, 35.91),
            crafting = vec3(-1421.64, -445.80, 35.91),
            repair = vec3(-1430.04, -449.65, 35.91),
            shop = vec3(-1418.84, -443.88, 35.91)
        },
        recipes = false,
        repairs = false,
        stock = false
    }
}

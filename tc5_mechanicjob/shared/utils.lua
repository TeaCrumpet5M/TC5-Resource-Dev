TC5Mechanic = TC5Mechanic or {}

function TC5Mechanic.Debug(message)
    if not TC5Mechanic.Config or not TC5Mechanic.Config.Debug then return end
    print(('[tc5_mechanicjob] %s'):format(tostring(message)))
end

function TC5Mechanic.GetShops()
    return (TC5Mechanic.Config and TC5Mechanic.Config.Shops) or {}
end

function TC5Mechanic.GetShopByKey(shopKey)
    return TC5Mechanic.GetShops()[shopKey]
end

function TC5Mechanic.GetShopByJob(jobName)
    if not jobName then return nil, nil end
    for shopKey, shop in pairs(TC5Mechanic.GetShops()) do
        if shop.enabled ~= false and tostring(shop.job):lower() == tostring(jobName):lower() then
            return shopKey, shop
        end
    end
    return nil, nil
end

function TC5Mechanic.GetShopGrades(shop)
    if shop and type(shop.grades) == 'table' then
        return shop.grades
    end
    return TC5Mechanic.Config.DefaultGrades or {}
end

function TC5Mechanic.GetShopRecipes(shop)
    if shop and type(shop.recipes) == 'table' then
        return shop.recipes
    end
    return TC5Mechanic.Config.SharedRecipes or {}
end

function TC5Mechanic.GetShopRepairs(shop)
    if shop and type(shop.repairs) == 'table' then
        return shop.repairs
    end
    return TC5Mechanic.Config.SharedRepairs or {}
end

function TC5Mechanic.GetShopStock(shop)
    if shop and type(shop.stock) == 'table' then
        return shop.stock
    end
    return TC5Mechanic.Config.SharedStock or {}
end

function TC5Mechanic.IsBossGrade(shop, grade)
    grade = tonumber(grade) or 0
    return shop and shop.bossGrades and shop.bossGrades[grade] == true
end

function TC5Mechanic.IsMechanicJob(jobName)
    local _, shop = TC5Mechanic.GetShopByJob(jobName)
    return shop ~= nil
end

function TC5Mechanic.RoundPercent(value, max)
    value = tonumber(value) or 0.0
    max = tonumber(max) or 1000.0
    return math.floor(math.max(0.0, math.min(value, max)) / max * 100.0 + 0.5)
end

function TC5Mechanic.Trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

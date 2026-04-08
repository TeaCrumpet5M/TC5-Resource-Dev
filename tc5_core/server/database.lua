TC5 = TC5 or {}
TC5.DB = {}

local function mysqlMissing()
    return type(MySQL) ~= 'table'
end

function TC5.DB.FetchAll(query, params)
    if mysqlMissing() then
        print('^1[tc5_core]^7 MySQL is not available.')
        return nil
    end

    return MySQL.query.await(query, params or {})
end

function TC5.DB.FetchOne(query, params)
    if mysqlMissing() then
        print('^1[tc5_core]^7 MySQL is not available.')
        return nil
    end

    return MySQL.single.await(query, params or {})
end

function TC5.DB.Insert(query, params)
    if mysqlMissing() then
        print('^1[tc5_core]^7 MySQL is not available.')
        return nil
    end

    return MySQL.insert.await(query, params or {})
end

function TC5.DB.Update(query, params)
    if mysqlMissing() then
        print('^1[tc5_core]^7 MySQL is not available.')
        return nil
    end

    return MySQL.update.await(query, params or {})
end

function TC5.DB.Scalar(query, params)
    if mysqlMissing() then
        print('^1[tc5_core]^7 MySQL is not available.')
        return nil
    end

    return MySQL.scalar.await(query, params or {})
end

function TC5.DB.Ready()
    if mysqlMissing() then
        print('^1[tc5_core]^7 Database connection failed: MySQL global is nil.')
        return false
    end

    local ok, result = pcall(function()
        return MySQL.query.await('SELECT 1 AS status')
    end)

    if not ok then
        print(('^1[tc5_core]^7 Database connection failed: %s'):format(tostring(result)))
        return false
    end

    if result and result[1] and result[1].status == 1 then
        print('^2[tc5_core]^7 Database connection established successfully.')
        return true
    end

    print('^1[tc5_core]^7 Database test query returned an unexpected result.')
    return false
end

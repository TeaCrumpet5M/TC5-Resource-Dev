TC5Inventory = TC5Inventory or {}
TC5Inventory.Utils = TC5Inventory.Utils or {}

function TC5Inventory.Utils.DebugPrint(message)
    if not TC5Inventory.Config.Debug then return end
    print(('[tc5_inventory] %s'):format(tostring(message)))
end

function TC5Inventory.Utils.SafeDecode(data, fallback)
    if type(data) ~= 'string' or data == '' then
        return fallback or {}
    end

    local ok, result = pcall(json.decode, data)
    if not ok or type(result) ~= 'table' then
        return fallback or {}
    end

    return result
end

function TC5Inventory.Utils.SafeEncode(data)
    local ok, result = pcall(json.encode, data or {})
    if not ok then
        return '{}'
    end

    return result
end

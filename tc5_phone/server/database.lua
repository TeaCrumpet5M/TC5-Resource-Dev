TC5Phone = TC5Phone or {}
TC5Phone.DB = {}

local function debugPrint(message)
    if TC5Phone.Config and TC5Phone.Config.Debug then
        print(('^3[tc5_phone]^7 %s'):format(tostring(message)))
    end
end

function TC5Phone.DB.Ready()
    local ok, result = pcall(function()
        return MySQL.query.await('SELECT 1 AS status')
    end)

    if not ok then
        print(('^1[tc5_phone]^7 Database connection failed: %s'):format(tostring(result)))
        return false
    end

    return result and result[1] and result[1].status == 1
end

function TC5Phone.DB.Setup()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_phone_numbers (
            char_id INT NOT NULL,
            phone_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (char_id),
            UNIQUE KEY uq_tc5_phone_number (phone_number)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_phone_contacts (
            id INT NOT NULL AUTO_INCREMENT,
            char_id INT NOT NULL,
            contact_name VARCHAR(100) NOT NULL,
            contact_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_tc5_phone_contacts_char (char_id)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_phone_messages (
            id INT NOT NULL AUTO_INCREMENT,
            owner_char_id INT NOT NULL,
            peer_number VARCHAR(20) NOT NULL,
            sender_number VARCHAR(20) NOT NULL,
            direction VARCHAR(10) NOT NULL,
            message TEXT NOT NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_tc5_phone_messages_owner (owner_char_id),
            KEY idx_tc5_phone_messages_peer (peer_number)
        )
    ]])

    debugPrint('Database tables ensured.')
    return true
end

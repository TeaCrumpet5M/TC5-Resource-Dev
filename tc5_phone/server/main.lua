TC5Phone = TC5Phone or {}
TC5Phone.Server = TC5Phone.Server or {}
TC5Phone.Server.Apps = TC5Phone.Server.Apps or {}
TC5Phone.Server.Cache = TC5Phone.Server.Cache or {}

local function debugPrint(message)
    if TC5Phone.Config.Debug then
        print(('^3[tc5_phone]^7 %s'):format(tostring(message)))
    end
end

local function getPlayer(src)
    return exports['tc5_core']:GetPlayer(src)
end

local function getCharacterId(src)
    return exports['tc5_core']:GetCharacterId(src)
end

local function notify(src, payload)
    TriggerClientEvent('tc5_ui:client:notify', src, payload)
end

local function sanitizeString(value, maxLength)
    local text = tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if maxLength and #text > maxLength then
        text = text:sub(1, maxLength)
    end
    return text
end

local function generatePhoneNumber()
    for _ = 1, 100 do
        local candidate = ('%03d-%04d'):format(math.random(100, 999), math.random(1000, 9999))
        local exists = MySQL.scalar.await('SELECT phone_number FROM tc5_phone_numbers WHERE phone_number = ? LIMIT 1', { candidate })
        if not exists then
            return candidate
        end
    end
    return ('555-%04d'):format(math.random(1000, 9999))
end

local function ensurePhoneNumber(charId)
    local existing = MySQL.single.await('SELECT phone_number FROM tc5_phone_numbers WHERE char_id = ? LIMIT 1', { charId })
    if existing and existing.phone_number then
        return existing.phone_number
    end

    local phoneNumber = generatePhoneNumber()
    MySQL.insert.await('INSERT INTO tc5_phone_numbers (char_id, phone_number) VALUES (?, ?)', { charId, phoneNumber })
    return phoneNumber
end

local function getCharacterIdentity(src)
    local data = exports['tc5_core']:GetPlayerData(src)
    if not data or not data.character then
        return {
            fullName = 'Unknown',
            firstName = 'Unknown',
            lastName = 'Citizen',
            cash = 0,
            bank = 0
        }
    end

    return {
        fullName = data.character.fullName or ((data.character.firstName or 'Unknown') .. ' ' .. (data.character.lastName or 'Citizen')),
        firstName = data.character.firstName or 'Unknown',
        lastName = data.character.lastName or 'Citizen',
        cash = data.character.cash or 0,
        bank = data.character.bank or 0
    }
end

local function getJobData(src)
    local ok, result = pcall(function()
        return exports['tc5_jobs']:GetPlayerJob(src)
    end)

    if ok and result then
        return {
            name = result.name or 'unemployed',
            label = result.label or 'Unemployed',
            grade = result.grade or 0,
            gradeLabel = result.gradeLabel or 'Citizen',
            onduty = result.onduty == true
        }
    end

    return {
        name = 'unemployed',
        label = 'Unemployed',
        grade = 0,
        gradeLabel = 'Citizen',
        onduty = false
    }
end

local function getApps()
    local apps = {}

    for i = 1, #TC5Phone.Config.DefaultApps do
        apps[#apps + 1] = TC5Phone.Config.DefaultApps[i]
    end

    for _, app in pairs(TC5Phone.Server.Apps) do
        apps[#apps + 1] = app
    end

    table.sort(apps, function(a, b)
        return tostring(a.label or a.id) < tostring(b.label or b.id)
    end)

    return apps
end

local function getContacts(charId)
    return MySQL.query.await([[
        SELECT id, contact_name, contact_number, created_at
        FROM tc5_phone_contacts
        WHERE char_id = ?
        ORDER BY contact_name ASC
    ]], { charId }) or {}
end

local function getThreads(charId)
    local rows = MySQL.query.await([[
        SELECT peer_number, MAX(created_at) as last_at, COUNT(*) as total_messages
        FROM tc5_phone_messages
        WHERE owner_char_id = ?
        GROUP BY peer_number
        ORDER BY last_at DESC
    ]], { charId }) or {}

    local contacts = getContacts(charId)
    local contactMap = {}
    for i = 1, #contacts do
        contactMap[contacts[i].contact_number] = contacts[i].contact_name
    end

    for i = 1, #rows do
        rows[i].label = contactMap[rows[i].peer_number] or rows[i].peer_number
    end

    return rows
end

local function getMessages(charId, peerNumber)
    return MySQL.query.await([[
        SELECT id, peer_number, sender_number, direction, message, created_at
        FROM tc5_phone_messages
        WHERE owner_char_id = ? AND peer_number = ?
        ORDER BY created_at ASC
        LIMIT ?
    ]], { charId, peerNumber, TC5Phone.Config.MaxMessagesPerThread }) or {}
end

function TC5Phone.Server.BuildState(src)
    local player = getPlayer(src)
    if not player then
        return nil, 'player_missing'
    end

    local charId = getCharacterId(src)
    if not charId then
        return nil, 'character_missing'
    end

    local number = ensurePhoneNumber(charId)
    local identity = getCharacterIdentity(src)
    local job = getJobData(src)

    local state = {
        profile = {
            phoneNumber = number,
            fullName = identity.fullName,
            firstName = identity.firstName,
            lastName = identity.lastName,
            cash = identity.cash,
            bank = identity.bank,
            wallpaper = TC5Phone.Config.DefaultWallpaper
        },
        contacts = getContacts(charId),
        threads = getThreads(charId),
        apps = getApps(),
        jobs = {
            current = job
        },
        garage = (function()
    local ok, result = pcall(function()
        return exports['tc5_garage']:GetPhoneGarageData(src)
    end)

    if ok and type(result) == 'table' then
        return result
    end

    return {
        vehicles = {},
        message = 'Garage integration ready for tc5_garage or your vehicle module.'
    }
end)(),
```

And in `tc5_phone/client/main.lua`, add:

```lua
RegisterNetEvent('tc5_phone:client:garageRefreshRequested', function()
    TriggerServerEvent('tc5_phone:server:refresh')
end)
        bank = {
            balance = identity.bank,
            cash = identity.cash,
            message = 'Bank app is connected to tc5_core character balances.'
        },
        calls = {
            recent = {},
            active = nil
        }
    }

    TC5Phone.Server.Cache[src] = state
    return state
end

function TC5Phone.Server.Open(src)
    local state, err = TC5Phone.Server.BuildState(src)
    if not state then
        notify(src, {
            title = 'Phone',
            message = ('Unable to open phone: %s'):format(tostring(err)),
            type = 'error',
            duration = 3000
        })
        return false
    end

    TriggerClientEvent('tc5_phone:client:open', src, state)
    return true
end

function TC5Phone.Server.AddContact(src, name, number)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'character_missing'
    end

    name = sanitizeString(name, 100)
    number = sanitizeString(number, 20)

    if name == '' or number == '' then
        return false, 'invalid_contact'
    end

    local currentTotal = MySQL.scalar.await('SELECT COUNT(*) FROM tc5_phone_contacts WHERE char_id = ?', { charId }) or 0
    if currentTotal >= TC5Phone.Config.MaxContacts then
        return false, 'max_contacts'
    end

    MySQL.insert.await([[
        INSERT INTO tc5_phone_contacts (char_id, contact_name, contact_number)
        VALUES (?, ?, ?)
    ]], { charId, name, number })

    return true, getContacts(charId)
end

function TC5Phone.Server.DeleteContact(src, contactId)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'character_missing'
    end

    MySQL.update.await('DELETE FROM tc5_phone_contacts WHERE id = ? AND char_id = ?', { tonumber(contactId) or 0, charId })
    return true, getContacts(charId)
end

function TC5Phone.Server.SendMessage(src, peerNumber, content)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'character_missing'
    end

    peerNumber = sanitizeString(peerNumber, 20)
    content = sanitizeString(content, 500)

    if peerNumber == '' or content == '' then
        return false, 'invalid_message'
    end

    local senderNumber = ensurePhoneNumber(charId)

    MySQL.insert.await([[
        INSERT INTO tc5_phone_messages (owner_char_id, peer_number, sender_number, direction, message)
        VALUES (?, ?, ?, 'outgoing', ?)
    ]], { charId, peerNumber, senderNumber, content })

    local target = MySQL.single.await('SELECT char_id FROM tc5_phone_numbers WHERE phone_number = ? LIMIT 1', { peerNumber })
    if target and target.char_id then
        MySQL.insert.await([[
            INSERT INTO tc5_phone_messages (owner_char_id, peer_number, sender_number, direction, message)
            VALUES (?, ?, ?, 'incoming', ?)
        ]], { target.char_id, senderNumber, senderNumber, content })

        for playerSrc, cached in pairs(TC5Phone.Server.Cache) do
            local targetCharId = getCharacterId(playerSrc)
            if targetCharId == target.char_id then
                notify(playerSrc, {
                    title = 'Messages',
                    message = ('New message from %s'):format(senderNumber),
                    type = 'info',
                    duration = 3500
                })
                local targetState = TC5Phone.Server.BuildState(playerSrc)
                TriggerClientEvent('tc5_phone:client:refresh', playerSrc, targetState)
            end
        end
    end

    return true, {
        threads = getThreads(charId),
        messages = getMessages(charId, peerNumber)
    }
end

function TC5Phone.Server.GetMessages(src, peerNumber)
    local charId = getCharacterId(src)
    if not charId then
        return {}
    end
    return getMessages(charId, sanitizeString(peerNumber, 20))
end

function TC5Phone.Server.GetPhoneNumber(src)
    local charId = getCharacterId(src)
    if not charId then return nil end
    return ensurePhoneNumber(charId)
end

function TC5Phone.Server.RegisterApp(app)
    if type(app) ~= 'table' then return false, 'app_invalid' end

    local id = sanitizeString(app.id, 50):lower()
    local label = sanitizeString(app.label, 50)
    local icon = sanitizeString(app.icon, 10)
    local color = sanitizeString(app.color, 20)

    if id == '' or label == '' then
        return false, 'app_missing_fields'
    end

    TC5Phone.Server.Apps[id] = {
        id = id,
        label = label,
        icon = icon ~= '' and icon or '📦',
        color = color ~= '' and color or '#1f1f1f'
    }

    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    math.randomseed(os.time())
    TC5Phone.DB.Setup()
    debugPrint('Phone resource started.')
end)

AddEventHandler('playerDropped', function()
    TC5Phone.Server.Cache[source] = nil
end)

RegisterNetEvent('tc5_phone:server:open', function()
    TC5Phone.Server.Open(source)
end)

RegisterNetEvent('tc5_phone:server:refresh', function()
    local src = source
    local state = TC5Phone.Server.BuildState(src)
    if state then
        TriggerClientEvent('tc5_phone:client:refresh', src, state)
    end
end)

RegisterNetEvent('tc5_phone:server:addContact', function(payload)
    local src = source
    local ok, result = TC5Phone.Server.AddContact(src, payload and payload.name, payload and payload.number)
    if not ok then
        notify(src, {
            title = 'Contacts',
            message = tostring(result),
            type = 'error',
            duration = 3000
        })
        return
    end

    local state = TC5Phone.Server.BuildState(src)
    TriggerClientEvent('tc5_phone:client:refresh', src, state)
    notify(src, {
        title = 'Contacts',
        message = 'Contact added.',
        type = 'success',
        duration = 2000
    })
end)

RegisterNetEvent('tc5_phone:server:deleteContact', function(contactId)
    local src = source
    local ok = TC5Phone.Server.DeleteContact(src, contactId)
    if ok then
        local state = TC5Phone.Server.BuildState(src)
        TriggerClientEvent('tc5_phone:client:refresh', src, state)
        notify(src, {
            title = 'Contacts',
            message = 'Contact deleted.',
            type = 'success',
            duration = 2000
        })
    end
end)

RegisterNetEvent('tc5_phone:server:getMessages', function(peerNumber)
    local src = source
    local messages = TC5Phone.Server.GetMessages(src, peerNumber)
    TriggerClientEvent('tc5_phone:client:messages', src, peerNumber, messages)
end)

RegisterNetEvent('tc5_phone:server:sendMessage', function(payload)
    local src = source
    local ok, result = TC5Phone.Server.SendMessage(src, payload and payload.peerNumber, payload and payload.message)
    if not ok then
        notify(src, {
            title = 'Messages',
            message = tostring(result),
            type = 'error',
            duration = 3000
        })
        return
    end

    local state = TC5Phone.Server.BuildState(src)
    TriggerClientEvent('tc5_phone:client:refresh', src, state)
    TriggerClientEvent('tc5_phone:client:messages', src, payload.peerNumber, result.messages)
    notify(src, {
        title = 'Messages',
        message = 'Message sent.',
        type = 'success',
        duration = 1800
    })
end)

exports('RegisterApp', function(app)
    return TC5Phone.Server.RegisterApp(app)
end)

exports('GetPhoneNumber', function(src)
    return TC5Phone.Server.GetPhoneNumber(src)
end)

TC5 = TC5 or {}

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function getOrCreateUser(src)
    if not src then
        return nil, 'Source was nil in getOrCreateUser.'
    end

    local license = TC5.Utils.GetIdentifier(src, TC5.Config.IdentifierType)

    if not license then
        return nil, 'No valid license identifier found.'
    end

    local playerName = TC5.Utils.GetPlayerNameSafe(src)

    local user = TC5.DB.FetchOne('SELECT * FROM tc5_users WHERE license = ? LIMIT 1', {
        license
    })

    if user then
        TC5.DB.Update([[
            UPDATE tc5_users
            SET name = ?, last_seen = NOW()
            WHERE id = ?
        ]], {
            playerName,
            user.id
        })

        user.name = playerName
        user.last_seen = os.date('%Y-%m-%d %H:%M:%S')
        return user
    end

    if not TC5.Config.AutoCreateUserOnJoin then
        return nil, 'User not found and auto-create is disabled.'
    end

    local insertId = TC5.DB.Insert([[
        INSERT INTO tc5_users (license, name, last_seen)
        VALUES (?, ?, NOW())
    ]], {
        license,
        playerName
    })

    if not insertId then
        return nil, 'Failed to create new user.'
    end

    local newUser = TC5.DB.FetchOne('SELECT * FROM tc5_users WHERE id = ? LIMIT 1', {
        insertId
    })

    if not newUser then
        return nil, 'User was inserted but could not be reloaded.'
    end

    return newUser
end

local function loadPlayer(src)
    if not src then
        print('^1[tc5_core]^7 loadPlayer called with nil source.')
        return
    end

    local user, err = getOrCreateUser(src)

    if not user then
        print(('^1[%s]^7 Failed loading player %s: %s'):format(
            TC5.Config.FrameworkName,
            tostring(src),
            tostring(err)
        ))

        DropPlayer(src, 'Failed to load your user data.')
        return
    end

    local player = TC5.CreatePlayerSession(src, user)
    local character = TC5.LoadOrCreateCharacter(player:GetUserId())

    if not character then
        print(('^1[%s]^7 Failed loading character for source %s'):format(
            TC5.Config.FrameworkName,
            tostring(src)
        ))

        DropPlayer(src, 'Failed to load your character data.')
        return
    end

    player:SetCharacter(character)

    print(('^2[%s]^7 Loaded user | source=%s userId=%s name=%s license=%s'):format(
        TC5.Config.FrameworkName,
        tostring(player:GetSource()),
        tostring(player:GetUserId()),
        tostring(player:GetName()),
        tostring(player:GetLicense())
    ))

    print(('^2[%s]^7 Loaded character | charId=%s fullName=%s cash=%s bank=%s creatorDone=%s apartmentId=%s'):format(
        TC5.Config.FrameworkName,
        tostring(character:GetId()),
        tostring(character:GetFullName()),
        tostring(character:GetCash()),
        tostring(character:GetBank()),
        tostring(character:GetHasCompletedCreator()),
        tostring(character:GetApartmentId())
    ))

    TriggerClientEvent('tc5_core:client:userLoaded', src, {
        userId = player:GetUserId(),
        name = player:GetName(),
        license = player:GetLicense(),
        character = {
            id = character:GetId(),
            firstName = character:GetFirstName(),
            lastName = character:GetLastName(),
            fullName = character:GetFullName(),
            cash = character:GetCash(),
            bank = character:GetBank(),
            apartmentId = character:GetApartmentId(),
            hasCompletedCreator = character:GetHasCompletedCreator()
        }
    })

    TriggerClientEvent('tc5_spawn:client:prepareSpawn', src, {
        firstTime = not character:GetHasCompletedCreator()
    })
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Wait(1000)
    TC5.DB.Ready()
end)

AddEventHandler('playerJoining', function()
    local src = source

    if not src then
        print('^1[tc5_core]^7 playerJoining fired with nil source.')
        return
    end

    print(('[tc5_core] playerJoining fired for source %s'):format(tostring(src)))

    CreateThread(function()
        Wait(1000)
        loadPlayer(src)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source

    if not src then return end

    TC5.SavePlayer(src)
    TC5.RemovePlayerSession(src)

    TC5.Utils.DebugPrint(('Saved and removed session for source %s'):format(src))
end)

CreateThread(function()
    local interval = (TC5.Config.SaveIntervalMinutes or 5) * 60000

    while true do
        Wait(interval)

        local savedCount = TC5.SaveAllPlayers()
        TC5.Utils.DebugPrint(('Auto-saved %s player sessions.'):format(savedCount))
    end
end)

RegisterNetEvent('tc5_core:server:finishCreator', function(data)
    local src = source
    local player = TC5.GetPlayer(src)

    if not player then
        print(('[tc5_core] finishCreator failed for %s: no player session'):format(tostring(src)))
        TriggerClientEvent('tc5_creator:client:reopen', src)
        return
    end

    local character = player:GetCharacter()

    if not character then
        print(('[tc5_core] finishCreator failed for %s: no character'):format(tostring(src)))
        TriggerClientEvent('tc5_creator:client:reopen', src)
        return
    end

    local firstName = trim(data and data.firstName)
    local lastName = trim(data and data.lastName)

    if firstName == '' or lastName == '' then
        print(('[tc5_core] finishCreator failed for %s: invalid name'):format(tostring(src)))
        TriggerClientEvent('tc5_creator:client:reopen', src)
        return
    end

    character:SetFirstName(firstName)
    character:SetLastName(lastName)
    character:SetHasCompletedCreator(true)
    character:Save()

    local apartment = exports['tc5_apartment']:CreateStarterApartment(src)

    if not apartment then
        print(('[tc5_core] finishCreator failed for %s: starter apartment creation failed'):format(tostring(src)))
        TriggerClientEvent('tc5_creator:client:reopen', src)
        return
    end

    TriggerClientEvent('tc5_spawn:client:creatorFinished', src)
end)

RegisterCommand('tc5_me', function(src)
    if src == 0 then
        print('This command can only be used in-game.')
        return
    end

    local player = TC5.GetPlayer(src)

    if not player then
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'TC5', 'Your user session is not loaded yet.' }
        })
        return
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = {
            'TC5',
            ('userId=%s | name=%s | license=%s'):format(
                tostring(player:GetUserId()),
                tostring(player:GetName()),
                tostring(player:GetLicense())
            )
        }
    })
end, false)

RegisterCommand('tc5_char', function(src)
    if src == 0 then
        print('This command can only be used in-game.')
        return
    end

    local player = TC5.GetPlayer(src)

    if not player or not player:GetCharacter() then
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'TC5', 'Your character is not loaded yet.' }
        })
        return
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = {
            'TC5',
            ('charId=%s | fullName=%s | cash=%s | bank=%s | creatorDone=%s | apartmentId=%s'):format(
                tostring(player:GetCharacterId()),
                tostring(player:GetCharacterName()),
                tostring(player:GetCash()),
                tostring(player:GetBank()),
                tostring(player:GetCharacter():GetHasCompletedCreator()),
                tostring(player:GetCharacter():GetApartmentId())
            )
        }
    })
end, false)

RegisterCommand('tc5_addcash', function(src, args)
    if src == 0 then
        print('This command can only be used in-game.')
        return
    end

    local amount = tonumber(args[1])
    if not amount then
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'TC5', 'Usage: /tc5_addcash [amount]' }
        })
        return
    end

    local player = TC5.GetPlayer(src)
    if not player or not player:GetCharacter() then return end

    player:AddCash(amount)
    player:SaveCharacter()

    TriggerClientEvent('chat:addMessage', src, {
        args = { 'TC5', ('Cash updated. New cash: %s'):format(player:GetCash()) }
    })
end, false)

RegisterCommand('tc5_addbank', function(src, args)
    if src == 0 then
        print('This command can only be used in-game.')
        return
    end

    local amount = tonumber(args[1])
    if not amount then
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'TC5', 'Usage: /tc5_addbank [amount]' }
        })
        return
    end

    local player = TC5.GetPlayer(src)
    if not player or not player:GetCharacter() then return end

    player:AddBank(amount)
    player:SaveCharacter()

    TriggerClientEvent('chat:addMessage', src, {
        args = { 'TC5', ('Bank updated. New bank: %s'):format(player:GetBank()) }
    })
end, false)

RegisterCommand('tc5_saveall', function(src)
    if src ~= 0 then return end

    local savedCount = TC5.SaveAllPlayers()
    print(('[tc5_core] Saved %s player sessions.'):format(savedCount))
end, true)

exports('GetPlayer', function(src)
    return TC5.GetPlayer(src)
end)

exports('GetPlayerData', function(src)
    local player = TC5.GetPlayer(src)
    if not player then return nil end

    local character = player:GetCharacter()

    return {
        source = player:GetSource(),
        userId = player:GetUserId(),
        license = player:GetLicense(),
        name = player:GetName(),
        character = character and {
            id = character:GetId(),
            userId = character:GetUserId(),
            firstName = character:GetFirstName(),
            lastName = character:GetLastName(),
            fullName = character:GetFullName(),
            cash = character:GetCash(),
            bank = character:GetBank(),
            apartmentId = character:GetApartmentId(),
            hasCompletedCreator = character:GetHasCompletedCreator(),
            isSelected = character.isSelected,
            createdAt = character.createdAt
        } or nil
    }
end)

exports('GetCharacterId', function(src)
    local player = TC5.GetPlayer(src)
    if not player then return nil end
    return player:GetCharacterId()
end)

exports('SetCharacterApartment', function(src, apartmentId)
    local player = TC5.GetPlayer(src)
    if not player then return false end

    local character = player:GetCharacter()
    if not character then return false end

    character:SetApartmentId(apartmentId)
    character:Save()

    return true
end)
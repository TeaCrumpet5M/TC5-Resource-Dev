TC5Admin = TC5Admin or {}

local function getCharacterName(src)
    local player = exports['tc5_core']:GetPlayer(src)
    if player and player.GetCharacterName then
        return player:GetCharacterName() or GetPlayerName(src)
    end
    return GetPlayerName(src)
end

local function getCash(src)
    local player = exports['tc5_core']:GetPlayer(src)
    if player and player.GetCash then
        return player:GetCash()
    end
    return 0
end

local function getBank(src)
    local player = exports['tc5_core']:GetPlayer(src)
    if player and player.GetBank then
        return player:GetBank()
    end
    return 0
end

function TC5Admin.GetPlayers()
    local list = {}
    local players = GetPlayers()

    for i = 1, #players do
        local src = tonumber(players[i])
        list[#list + 1] = {
            id = src,
            name = GetPlayerName(src),
            character = getCharacterName(src),
            ping = GetPlayerPing(src),
            cash = getCash(src),
            bank = getBank(src),
            job = (exports['tc5_jobs'] and exports['tc5_jobs']:GetPlayerJob(src) or nil)
        }
    end

    table.sort(list, function(a, b)
        return a.id < b.id
    end)

    return list
end

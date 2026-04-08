TC5 = TC5 or {}
TC5.Players = TC5.Players or {}

local Player = {}
Player.__index = Player

function Player:new(source, userData)
    local self = setmetatable({}, Player)

    self.source = source
    self.userId = userData.id
    self.license = userData.license
    self.name = userData.name
    self.createdAt = userData.created_at
    self.lastSeen = userData.last_seen
    self.character = nil

    return self
end

function Player:GetSource() return self.source end
function Player:GetUserId() return self.userId end
function Player:GetLicense() return self.license end
function Player:GetName() return self.name end
function Player:SetName(name) self.name = name end
function Player:GetCharacter() return self.character end
function Player:SetCharacter(character) self.character = character end
function Player:GetCharacterId() return self.character and self.character:GetId() or nil end
function Player:GetCharacterName() return self.character and self.character:GetFullName() or nil end
function Player:GetCash() return self.character and self.character:GetCash() or 0 end
function Player:GetBank() return self.character and self.character:GetBank() or 0 end
function Player:AddCash(amount) if self.character then self.character:AddCash(amount) end end
function Player:RemoveCash(amount) if self.character then self.character:RemoveCash(amount) end end
function Player:AddBank(amount) if self.character then self.character:AddBank(amount) end end
function Player:RemoveBank(amount) if self.character then self.character:RemoveBank(amount) end end

function Player:SaveUser()
    return TC5.DB.Update([[
        UPDATE tc5_users
        SET name = ?, last_seen = NOW()
        WHERE id = ?
    ]], { self.name, self.userId })
end

function Player:SaveCharacter()
    if not self.character then return 0 end
    return self.character:Save() or 0
end

function Player:Save()
    self:SaveUser()
    self:SaveCharacter()
    return true
end

TC5.Player = Player

function TC5.GetPlayer(source) return TC5.Players[source] end

function TC5.GetPlayerByUserId(userId)
    for _, player in pairs(TC5.Players) do
        if player:GetUserId() == userId then
            return player
        end
    end
    return nil
end

function TC5.CreatePlayerSession(source, userData)
    local player = Player:new(source, userData)
    TC5.Players[source] = player
    return player
end

function TC5.RemovePlayerSession(source)
    TC5.Players[source] = nil
end

function TC5.SavePlayer(source)
    local player = TC5.GetPlayer(source)
    if not player then return false end
    player:Save()
    return true
end

function TC5.SaveAllPlayers()
    local savedCount = 0
    for _, player in pairs(TC5.Players) do
        if player then
            player:Save()
            savedCount = savedCount + 1
        end
    end
    return savedCount
end

TC5 = TC5 or {}

local Character = {}
Character.__index = Character

function Character:new(data)
    local self = setmetatable({}, Character)

    self.id = data.id
    self.userId = data.user_id
    self.firstName = data.first_name
    self.lastName = data.last_name
    self.cash = data.cash or 0
    self.bank = data.bank or 0
    self.isSelected = data.is_selected == 1 or data.is_selected == true
    self.apartmentId = data.apartment_id
    self.hasCompletedCreator = data.has_completed_creator == 1 or data.has_completed_creator == true
    self.createdAt = data.created_at

    return self
end

function Character:GetId()
    return self.id
end

function Character:GetUserId()
    return self.userId
end

function Character:GetFirstName()
    return self.firstName
end

function Character:GetLastName()
    return self.lastName
end

function Character:GetFullName()
    return ('%s %s'):format(self.firstName, self.lastName)
end

function Character:GetCash()
    return self.cash
end

function Character:GetBank()
    return self.bank
end

function Character:GetApartmentId()
    return self.apartmentId
end

function Character:GetHasCompletedCreator()
    return self.hasCompletedCreator
end

function Character:SetFirstName(firstName)
    self.firstName = firstName
end

function Character:SetLastName(lastName)
    self.lastName = lastName
end

function Character:SetCash(amount)
    self.cash = math.max(0, math.floor(tonumber(amount) or 0))
end

function Character:SetBank(amount)
    self.bank = math.max(0, math.floor(tonumber(amount) or 0))
end

function Character:SetApartmentId(apartmentId)
    self.apartmentId = apartmentId
end

function Character:SetHasCompletedCreator(state)
    self.hasCompletedCreator = state == true
end

function Character:AddCash(amount)
    self:SetCash(self.cash + (tonumber(amount) or 0))
end

function Character:RemoveCash(amount)
    self:SetCash(self.cash - (tonumber(amount) or 0))
end

function Character:AddBank(amount)
    self:SetBank(self.bank + (tonumber(amount) or 0))
end

function Character:RemoveBank(amount)
    self:SetBank(self.bank - (tonumber(amount) or 0))
end

function Character:Save()
    return TC5.DB.Update([[
        UPDATE tc5_characters
        SET first_name = ?, last_name = ?, cash = ?, bank = ?, is_selected = ?, apartment_id = ?, has_completed_creator = ?
        WHERE id = ?
    ]], {
        self.firstName,
        self.lastName,
        self.cash,
        self.bank,
        self.isSelected and 1 or 0,
        self.apartmentId,
        self.hasCompletedCreator and 1 or 0,
        self.id
    })
end

TC5.Character = Character

function TC5.GetCharactersByUserId(userId)
    local rows = TC5.DB.FetchAll([[
        SELECT * FROM tc5_characters
        WHERE user_id = ?
        ORDER BY id ASC
    ]], {
        userId
    })

    if not rows then
        return {}
    end

    local characters = {}

    for i = 1, #rows do
        characters[#characters + 1] = Character:new(rows[i])
    end

    return characters
end

function TC5.GetCharacterById(characterId)
    local row = TC5.DB.FetchOne([[
        SELECT * FROM tc5_characters
        WHERE id = ?
        LIMIT 1
    ]], {
        characterId
    })

    if not row then
        return nil
    end

    return Character:new(row)
end

function TC5.CreateCharacter(userId, firstName, lastName)
    local insertId = TC5.DB.Insert([[
        INSERT INTO tc5_characters (user_id, first_name, last_name, cash, bank, is_selected, apartment_id, has_completed_creator)
        VALUES (?, ?, ?, ?, ?, 1, NULL, 0)
    ]], {
        userId,
        firstName or TC5.Config.DefaultCharacter.FirstName,
        lastName or TC5.Config.DefaultCharacter.LastName,
        TC5.Config.DefaultCharacter.Cash,
        TC5.Config.DefaultCharacter.Bank
    })

    if not insertId then
        return nil
    end

    return TC5.GetCharacterById(insertId)
end

function TC5.ClearSelectedCharacter(userId)
    TC5.DB.Update([[
        UPDATE tc5_characters
        SET is_selected = 0
        WHERE user_id = ?
    ]], {
        userId
    })
end

function TC5.SetSelectedCharacter(userId, characterId)
    TC5.ClearSelectedCharacter(userId)

    TC5.DB.Update([[
        UPDATE tc5_characters
        SET is_selected = 1
        WHERE user_id = ? AND id = ?
    ]], {
        userId,
        characterId
    })

    return TC5.GetCharacterById(characterId)
end

function TC5.LoadOrCreateCharacter(userId)
    local characters = TC5.GetCharactersByUserId(userId)

    if #characters == 0 then
        local newCharacter = TC5.CreateCharacter(
            userId,
            TC5.Config.DefaultCharacter.FirstName,
            TC5.Config.DefaultCharacter.LastName
        )

        return newCharacter
    end

    for i = 1, #characters do
        if characters[i].isSelected then
            return characters[i]
        end
    end

    local firstCharacter = characters[1]
    return TC5.SetSelectedCharacter(userId, firstCharacter:GetId())
end
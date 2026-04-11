TC5Banking = TC5Banking or {}

local function notify(src, title, message, notifyType)
    TriggerClientEvent('tc5_ui:client:notify', src, {
        title = title or 'Banking',
        message = message or '',
        type = notifyType or 'info'
    })

    TriggerClientEvent('tc5_banking:client:notify', src, {
        title = title or 'Banking',
        message = message or '',
        type = notifyType or 'info'
    })
end

local function getPlayer(src)
    if not exports['tc5_core'] or not exports['tc5_core'].GetPlayer then
        return nil
    end
    return exports['tc5_core']:GetPlayer(src)
end

local function getPlayerData(src)
    if not exports['tc5_core'] or not exports['tc5_core'].GetPlayerData then
        return nil
    end
    return exports['tc5_core']:GetPlayerData(src)
end

local function getCharacterId(src)
    if not exports['tc5_core'] or not exports['tc5_core'].GetCharacterId then
        return nil
    end
    return exports['tc5_core']:GetCharacterId(src)
end

local function getCurrentJob(src)
    if exports['tc5_jobs'] and exports['tc5_jobs'].GetPlayerJob then
        local job = exports['tc5_jobs']:GetPlayerJob(src)
        if type(job) == 'table' then
            return {
                name = tostring(job.name or job.job or ''),
                label = tostring(job.label or job.name or 'Business'),
                grade = tonumber(job.grade or job.gradeLevel or 0) or 0,
                gradeName = tostring(job.gradeName or '')
            }
        end
    end

    return {
        name = '',
        label = '',
        grade = 0,
        gradeName = ''
    }
end

local function getLegacyBankAmount(src)
    local data = getPlayerData(src)
    if data and data.character then
        return math.max(0, math.floor(tonumber(data.character.bank) or 0))
    end
    return 0
end

local function syncLegacyBank(src, amount)
    local charId = getCharacterId(src)
    if not charId or amount == nil then return end

    local target = math.max(0, math.floor(tonumber(amount) or 0))

    MySQL.update.await([[
        UPDATE tc5_characters
        SET bank = ?
        WHERE id = ?
    ]], {
        target,
        tonumber(charId)
    })
end

local function getInventory(src)
    if not exports['tc5_inventory'] or not exports['tc5_inventory'].GetInventory then
        return nil
    end
    return exports['tc5_inventory']:GetInventory(src)
end

local function getCashOnHand(src)
    local inventory = getInventory(src)
    if not inventory or not inventory.items then return 0 end

    local total = 0
    for _, item in pairs(inventory.items) do
        if item.name == TC5Banking.Config.CashItemName then
            total = total + (tonumber(item.amount) or 0)
        end
    end
    return math.max(0, math.floor(total))
end

local function addCashItem(src, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end
    if not exports['tc5_inventory'] or not exports['tc5_inventory'].AddItem then
        return false, 'inventory_missing'
    end
    return exports['tc5_inventory']:AddItem(src, TC5Banking.Config.CashItemName, amount)
end

local function removeCashItem(src, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end

    local inventory = getInventory(src)
    if not inventory or not inventory.items then
        return false, 'inventory_missing'
    end

    local remaining = amount
    for slot, item in pairs(inventory.items) do
        if item.name == TC5Banking.Config.CashItemName and remaining > 0 then
            local removeAmount = math.min(tonumber(item.amount) or 0, remaining)
            local ok = exports['tc5_inventory']:RemoveItem(src, TC5Banking.Config.CashItemName, removeAmount, tonumber(slot))
            if ok then
                remaining = remaining - removeAmount
            end
        end
    end

    if remaining > 0 then
        return false, 'not_enough_cash'
    end

    return true
end

local function randomDigits(length)
    local out = ''
    for i = 1, length do
        out = out .. tostring(math.random(0, 9))
    end
    return out
end

local function generateUniqueAccountNumber()
    while true do
        local accountNumber = ('%s%s'):format(TC5Banking.Config.AccountNumberPrefix, randomDigits(8))
        local exists = MySQL.scalar.await('SELECT id FROM tc5_bank_accounts WHERE account_number = ? LIMIT 1', { accountNumber })
        if not exists then
            return accountNumber
        end
    end
end

local function getAccountById(accountId)
    return MySQL.single.await('SELECT * FROM tc5_bank_accounts WHERE id = ? LIMIT 1', { tonumber(accountId) })
end

local function getAccountByNumber(accountNumber)
    return MySQL.single.await('SELECT * FROM tc5_bank_accounts WHERE account_number = ? LIMIT 1', { tostring(accountNumber) })
end

local function getPersonalAccountCount(charId)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM tc5_bank_accounts WHERE owner_char_id = ? AND account_type = ?', {
        tonumber(charId),
        'personal'
    })
    return tonumber(count) or 0
end

local function getDefaultPersonalAccount(charId)
    local account = MySQL.single.await([[
        SELECT * FROM tc5_bank_accounts
        WHERE owner_char_id = ? AND account_type = 'personal' AND is_default = 1
        LIMIT 1
    ]], { tonumber(charId) })

    if account then return account end

    return MySQL.single.await([[
        SELECT * FROM tc5_bank_accounts
        WHERE owner_char_id = ? AND account_type = 'personal'
        ORDER BY id ASC
        LIMIT 1
    ]], { tonumber(charId) })
end

local function setDefaultPersonalAccount(charId, accountId)
    MySQL.update.await('UPDATE tc5_bank_accounts SET is_default = 0 WHERE owner_char_id = ? AND account_type = ?', {
        tonumber(charId),
        'personal'
    })

    MySQL.update.await('UPDATE tc5_bank_accounts SET is_default = 1 WHERE id = ? AND owner_char_id = ? AND account_type = ?', {
        tonumber(accountId),
        tonumber(charId),
        'personal'
    })
end

local function insertTransaction(accountId, actorCharId, txType, amount, balanceAfter, referenceText, targetAccountNumber)
    MySQL.insert.await([[
        INSERT INTO tc5_bank_transactions (account_id, actor_char_id, tx_type, amount, balance_after, reference_text, target_account_number)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        tonumber(accountId),
        actorCharId and tonumber(actorCharId) or nil,
        tostring(txType),
        math.floor(tonumber(amount) or 0),
        math.floor(tonumber(balanceAfter) or 0),
        referenceText and tostring(referenceText) or nil,
        targetAccountNumber and tostring(targetAccountNumber) or nil
    })
end

local function buildAccountPermissions(src, account)
    local charId = getCharacterId(src)
    if not charId or not account then
        return nil
    end

    if account.account_type == 'personal' then
        if tonumber(account.owner_char_id) ~= tonumber(charId) then
            return nil
        end

        return {
            view = true,
            deposit = true,
            withdraw = true,
            transfer = true,
            manage = true,
            role = 'owner'
        }
    end

    if account.account_type == 'business' then
        local job = getCurrentJob(src)
        if not job.name or job.name == '' then
            return nil
        end

        local access = MySQL.single.await([[
            SELECT * FROM tc5_bank_business_access
            WHERE account_id = ? AND job_name = ?
            ORDER BY min_grade DESC
            LIMIT 1
        ]], {
            tonumber(account.id),
            tostring(job.name)
        })

        if not access then
            return nil
        end

        local minGrade = tonumber(access.min_grade) or 0
        if job.grade < minGrade then
            return nil
        end

        local canManage = job.grade >= minGrade
        return {
            view = true,
            deposit = true,
            withdraw = true,
            transfer = true,
            manage = canManage,
            role = canManage and 'manager' or 'member',
            job = job
        }
    end

    return nil
end

local function canAccessAccount(src, accountId, permission)
    local account = getAccountById(accountId)
    if not account then
        return false, nil
    end

    local permissions = buildAccountPermissions(src, account)
    if not permissions then
        return false, nil
    end

    if permission and permissions[permission] ~= true then
        return false, account
    end

    return true, account, permissions
end

local function ensureCharacterSetup(src)
    local charId = getCharacterId(src)
    if not charId then return false end

    local existing = getDefaultPersonalAccount(charId)
    if existing then
        syncLegacyBank(src, tonumber(existing.balance) or 0)
        return true
    end

    local legacyBank = getLegacyBankAmount(src)
    local accountNumber = generateUniqueAccountNumber()

    local accountId = MySQL.insert.await([[
        INSERT INTO tc5_bank_accounts (account_type, owner_char_id, account_name, account_number, sort_code, balance, is_default)
        VALUES ('personal', ?, ?, ?, ?, ?, 1)
    ]], {
        tonumber(charId),
        'Main Account',
        accountNumber,
        TC5Banking.Config.SortCode,
        legacyBank
    })

    MySQL.insert.await([[
        INSERT INTO tc5_bank_migrations (char_id, migrated_legacy_bank)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE migrated_legacy_bank = 1
    ]], { tonumber(charId) })

    insertTransaction(accountId, charId, 'migration', legacyBank, legacyBank, 'Legacy bank import', nil)
    syncLegacyBank(src, legacyBank)
    return true
end

local function getAccessibleAccounts(src)
    ensureCharacterSetup(src)

    local charId = getCharacterId(src)
    if not charId then return {} end

    local accounts = {}

    local personalRows = MySQL.query.await([[
        SELECT * FROM tc5_bank_accounts
        WHERE owner_char_id = ?
        ORDER BY account_type ASC, is_default DESC, id ASC
    ]], { tonumber(charId) }) or {}

    for i = 1, #personalRows do
        local account = personalRows[i]
        local permissions = buildAccountPermissions(src, account)
        if permissions then
            accounts[#accounts + 1] = {
                id = tonumber(account.id),
                type = account.account_type,
                name = account.account_name,
                accountNumber = account.account_number,
                sortCode = account.sort_code,
                balance = tonumber(account.balance) or 0,
                isDefault = tonumber(account.is_default) == 1,
                isFrozen = tonumber(account.is_frozen) == 1,
                businessJobName = account.business_job_name,
                permissions = permissions
            }
        end
    end

    local job = getCurrentJob(src)
    if job.name and job.name ~= '' then
        local businessRows = MySQL.query.await([[
            SELECT a.*
            FROM tc5_bank_accounts a
            INNER JOIN tc5_bank_business_access b ON b.account_id = a.id
            WHERE a.account_type = 'business' AND b.job_name = ? AND b.min_grade <= ?
            GROUP BY a.id
            ORDER BY a.id ASC
        ]], {
            tostring(job.name),
            tonumber(job.grade) or 0
        }) or {}

        for i = 1, #businessRows do
            local account = businessRows[i]
            local permissions = buildAccountPermissions(src, account)
            if permissions then
                accounts[#accounts + 1] = {
                    id = tonumber(account.id),
                    type = account.account_type,
                    name = account.account_name,
                    accountNumber = account.account_number,
                    sortCode = account.sort_code,
                    balance = tonumber(account.balance) or 0,
                    isDefault = false,
                    isFrozen = tonumber(account.is_frozen) == 1,
                    businessJobName = account.business_job_name,
                    permissions = permissions
                }
            end
        end
    end

    table.sort(accounts, function(a, b)
        if a.type ~= b.type then
            return a.type < b.type
        end
        if a.isDefault ~= b.isDefault then
            return a.isDefault
        end
        return a.id < b.id
    end)

    return accounts
end

local function getStatements(accountId)
    local rows = MySQL.query.await([[
        SELECT * FROM tc5_bank_transactions
        WHERE account_id = ?
        ORDER BY id DESC
        LIMIT ?
    ]], {
        tonumber(accountId),
        tonumber(TC5Banking.Config.StatementLimit) or 50
    }) or {}

    local statements = {}
    for i = 1, #rows do
        local row = rows[i]
        statements[#statements + 1] = {
            id = tonumber(row.id),
            type = row.tx_type,
            amount = tonumber(row.amount) or 0,
            balanceAfter = tonumber(row.balance_after) or 0,
            reference = row.reference_text,
            targetAccountNumber = row.target_account_number,
            createdAt = tostring(row.created_at or '')
        }
    end
    return statements
end

local function createPersonalAccount(src, accountName)
    local charId = getCharacterId(src)
    if not charId then
        return false, 'no_character'
    end

    ensureCharacterSetup(src)

    if getPersonalAccountCount(charId) >= TC5Banking.Config.MaxPersonalAccounts then
        return false, 'max_accounts'
    end

    accountName = TC5Banking.Utils.Trim(accountName)
    if accountName == '' then
        accountName = ('Personal Account %s'):format(getPersonalAccountCount(charId) + 1)
    end

    local accountId = MySQL.insert.await([[
        INSERT INTO tc5_bank_accounts (account_type, owner_char_id, account_name, account_number, sort_code, balance, is_default)
        VALUES ('personal', ?, ?, ?, ?, 0, 0)
    ]], {
        tonumber(charId),
        accountName,
        generateUniqueAccountNumber(),
        TC5Banking.Config.SortCode
    })

    insertTransaction(accountId, charId, 'account_opened', 0, 0, 'Account opened', nil)
    return true, accountId
end

local function createBusinessAccount(src, jobName, accountName)
    local job = getCurrentJob(src)
    jobName = TC5Banking.Utils.Trim(jobName)
    accountName = TC5Banking.Utils.Trim(accountName)

    if jobName == '' or accountName == '' then
        return false, 'invalid_arguments'
    end

    if job.name ~= jobName then
        return false, 'job_mismatch'
    end

    if job.grade < (TC5Banking.Config.BusinessCreationMinGrade or 3) then
        return false, 'grade_too_low'
    end

    local existing = MySQL.scalar.await('SELECT id FROM tc5_bank_accounts WHERE account_type = ? AND business_job_name = ? LIMIT 1', {
        'business',
        jobName
    })
    if existing then
        return false, 'business_exists'
    end

    local accountId = MySQL.insert.await([[
        INSERT INTO tc5_bank_accounts (account_type, owner_char_id, business_job_name, account_name, account_number, sort_code, balance, is_default)
        VALUES ('business', NULL, ?, ?, ?, ?, 0, 0)
    ]], {
        jobName,
        accountName,
        generateUniqueAccountNumber(),
        TC5Banking.Config.SortCode
    })

    MySQL.insert.await([[
        INSERT INTO tc5_bank_business_access (account_id, job_name, min_grade)
        VALUES (?, ?, ?)
    ]], {
        tonumber(accountId),
        jobName,
        TC5Banking.Config.BusinessCreationMinGrade or 3
    })

    local charId = getCharacterId(src)
    insertTransaction(accountId, charId, 'account_opened', 0, 0, 'Business account opened', nil)
    return true, accountId
end

local function depositToAccount(src, accountId, amount, reference)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end

    local ok, account = canAccessAccount(src, accountId, 'deposit')
    if not ok then return false, 'no_access' end
    if tonumber(account.is_frozen) == 1 then return false, 'account_frozen' end
    if getCashOnHand(src) < amount then return false, 'not_enough_cash' end

    local removed = removeCashItem(src, amount)
    if not removed then return false, 'not_enough_cash' end

    local newBalance = (tonumber(account.balance) or 0) + amount
    MySQL.update.await('UPDATE tc5_bank_accounts SET balance = ? WHERE id = ?', { newBalance, tonumber(account.id) })

    local charId = getCharacterId(src)
    insertTransaction(account.id, charId, 'deposit', amount, newBalance, reference or 'Cash deposit', nil)

    local charIdLocal = getCharacterId(src)
    if charIdLocal and account.account_type == 'personal' and tonumber(account.owner_char_id) == tonumber(charIdLocal) then
        local defaultAccount = getDefaultPersonalAccount(charIdLocal)
        if defaultAccount and tonumber(defaultAccount.id) == tonumber(account.id) then
            syncLegacyBank(src, newBalance)
        end
    end

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    return true, newBalance
end

local function withdrawFromAccount(src, accountId, amount, reference)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end

    local ok, account = canAccessAccount(src, accountId, 'withdraw')
    if not ok then return false, 'no_access' end
    if tonumber(account.is_frozen) == 1 then return false, 'account_frozen' end

    local balance = tonumber(account.balance) or 0
    if balance < amount then return false, 'insufficient_funds' end

    local inventoryCanCarry = true
    if exports['tc5_inventory'] and exports['tc5_inventory'].CanCarryItem then
        inventoryCanCarry = exports['tc5_inventory']:CanCarryItem(src, TC5Banking.Config.CashItemName, amount)
    end
    if inventoryCanCarry == false then
        return false, 'cannot_carry_cash'
    end

    local okAdd = addCashItem(src, amount)
    if not okAdd then return false, 'cannot_carry_cash' end

    local newBalance = balance - amount
    MySQL.update.await('UPDATE tc5_bank_accounts SET balance = ? WHERE id = ?', { newBalance, tonumber(account.id) })

    local charId = getCharacterId(src)
    insertTransaction(account.id, charId, 'withdraw', amount, newBalance, reference or 'Cash withdrawal', nil)

    local charIdLocal = getCharacterId(src)
    if charIdLocal and account.account_type == 'personal' and tonumber(account.owner_char_id) == tonumber(charIdLocal) then
        local defaultAccount = getDefaultPersonalAccount(charIdLocal)
        if defaultAccount and tonumber(defaultAccount.id) == tonumber(account.id) then
            syncLegacyBank(src, newBalance)
        end
    end

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    return true, newBalance
end

local function transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reference)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end

    local ok, fromAccount = canAccessAccount(src, fromAccountId, 'transfer')
    if not ok then return false, 'no_access' end
    if tonumber(fromAccount.is_frozen) == 1 then return false, 'account_frozen' end

    local target = getAccountByNumber(targetAccountNumber)
    if not target then return false, 'target_not_found' end
    if tonumber(target.id) == tonumber(fromAccount.id) then return false, 'same_account' end
    if tonumber(target.is_frozen) == 1 then return false, 'target_frozen' end

    local fromBalance = tonumber(fromAccount.balance) or 0
    if fromBalance < amount then return false, 'insufficient_funds' end

    local toBalance = tonumber(target.balance) or 0
    local newFromBalance = fromBalance - amount
    local newToBalance = toBalance + amount

    MySQL.update.await('UPDATE tc5_bank_accounts SET balance = ? WHERE id = ?', { newFromBalance, tonumber(fromAccount.id) })
    MySQL.update.await('UPDATE tc5_bank_accounts SET balance = ? WHERE id = ?', { newToBalance, tonumber(target.id) })

    local charId = getCharacterId(src)
    reference = reference and tostring(reference) or 'Bank transfer'

    insertTransaction(fromAccount.id, charId, 'transfer_out', amount, newFromBalance, reference, target.account_number)
    insertTransaction(target.id, charId, 'transfer_in', amount, newToBalance, reference, fromAccount.account_number)

    local charIdLocal = getCharacterId(src)
    if charIdLocal and fromAccount.account_type == 'personal' and tonumber(fromAccount.owner_char_id) == tonumber(charIdLocal) then
        local defaultAccount = getDefaultPersonalAccount(charIdLocal)
        if defaultAccount and tonumber(defaultAccount.id) == tonumber(fromAccount.id) then
            syncLegacyBank(src, newFromBalance)
        end
    end

    return true, newFromBalance
end

local function buildUiPayload(src, mode, focusAccountId)
    local playerData = getPlayerData(src)
    local accounts = getAccessibleAccounts(src)
    local statementsByAccount = {}

    for i = 1, #accounts do
        statementsByAccount[tostring(accounts[i].id)] = getStatements(accounts[i].id)
    end

    local job = getCurrentJob(src)

    return {
        mode = mode or 'bank',
        character = playerData and playerData.character and {
            id = playerData.character.id,
            fullName = playerData.character.fullName
        } or nil,
        cashOnHand = getCashOnHand(src),
        accounts = accounts,
        statements = statementsByAccount,
        focusAccountId = focusAccountId,
        config = {
            maxPersonalAccounts = TC5Banking.Config.MaxPersonalAccounts,
            statementLimit = TC5Banking.Config.StatementLimit,
            enableATMDeposits = TC5Banking.Config.EnableATMDeposits,
            enableATMTransfers = TC5Banking.Config.EnableATMTransfers
        },
        job = job
    }
end

local function refreshUi(src, mode, focusAccountId)
    TriggerClientEvent('tc5_banking:client:refreshUi', src, buildUiPayload(src, mode, focusAccountId))
end

RegisterNetEvent('tc5_banking:server:openUi', function(mode)
    local src = source
    ensureCharacterSetup(src)
    TriggerClientEvent('tc5_banking:client:openUi', src, buildUiPayload(src, mode or 'bank'))
end)

RegisterNetEvent('tc5_banking:server:requestRefresh', function(mode, focusAccountId)
    local src = source
    refreshUi(src, mode, focusAccountId)
end)

RegisterNetEvent('tc5_banking:server:createPersonalAccount', function(accountName, mode)
    local src = source
    local ok, result = createPersonalAccount(src, accountName)
    if not ok then
        local map = {
            max_accounts = 'You have reached the maximum number of personal accounts.',
            no_character = 'Character not loaded.'
        }
        notify(src, 'Banking', map[result] or 'Could not create account.', 'error')
        refreshUi(src, mode or 'bank')
        return
    end

    notify(src, 'Banking', 'Personal account created successfully.', 'success')
    refreshUi(src, mode or 'bank', result)
end)

RegisterNetEvent('tc5_banking:server:createBusinessAccount', function(jobName, accountName, mode)
    local src = source
    local ok, result = createBusinessAccount(src, jobName, accountName)
    if not ok then
        local map = {
            invalid_arguments = 'Usage: provide a valid job and account name.',
            job_mismatch = 'You can only create a business account for your active job.',
            grade_too_low = 'Your grade is too low to create a business account.',
            business_exists = 'A business account for that job already exists.'
        }
        notify(src, 'Banking', map[result] or 'Could not create business account.', 'error')
        refreshUi(src, mode or 'bank')
        return
    end

    notify(src, 'Banking', 'Business account created successfully.', 'success')
    refreshUi(src, mode or 'bank', result)
end)

RegisterNetEvent('tc5_banking:server:setDefaultAccount', function(accountId, mode)
    local src = source
    local charId = getCharacterId(src)
    if not charId then return end

    local ok, account = canAccessAccount(src, accountId, 'manage')
    if not ok or account.account_type ~= 'personal' then
        notify(src, 'Banking', 'You cannot set that account as default.', 'error')
        refreshUi(src, mode or 'bank')
        return
    end

    setDefaultPersonalAccount(charId, account.id)
    local defaultAccount = getDefaultPersonalAccount(charId)
    if defaultAccount then
        syncLegacyBank(src, tonumber(defaultAccount.balance) or 0)
    end

    notify(src, 'Banking', 'Default account updated.', 'success')
    refreshUi(src, mode or 'bank', account.id)
end)

RegisterNetEvent('tc5_banking:server:deposit', function(accountId, amount, reference, mode)
    local src = source
    local ok, result = depositToAccount(src, accountId, amount, reference)
    if not ok then
        local map = {
            invalid_amount = 'Enter a valid amount.',
            no_access = 'You do not have access to that account.',
            account_frozen = 'That account is frozen.',
            not_enough_cash = 'You do not have enough cash on hand.'
        }
        notify(src, 'Banking', map[result] or 'Deposit failed.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end

    notify(src, 'Banking', ('Deposit complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:withdraw', function(accountId, amount, reference, mode)
    local src = source
    local ok, result = withdrawFromAccount(src, accountId, amount, reference)
    if not ok then
        local map = {
            invalid_amount = 'Enter a valid amount.',
            no_access = 'You do not have access to that account.',
            account_frozen = 'That account is frozen.',
            insufficient_funds = 'Insufficient funds.',
            cannot_carry_cash = 'You cannot carry that much cash.'
        }
        notify(src, 'Banking', map[result] or 'Withdrawal failed.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end

    notify(src, 'Banking', ('Withdrawal complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:transfer', function(fromAccountId, targetAccountNumber, amount, reference, mode)
    local src = source
    local ok, result = transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reference)
    if not ok then
        local map = {
            invalid_amount = 'Enter a valid amount.',
            no_access = 'You do not have access to that account.',
            account_frozen = 'The source account is frozen.',
            target_frozen = 'The target account is frozen.',
            target_not_found = 'Target account not found.',
            same_account = 'You cannot transfer to the same account.',
            insufficient_funds = 'Insufficient funds.'
        }
        notify(src, 'Banking', map[result] or 'Transfer failed.', 'error')
        refreshUi(src, mode or 'bank', fromAccountId)
        return
    end

    notify(src, 'Banking', ('Transfer complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    refreshUi(src, mode or 'bank', fromAccountId)
end)

RegisterCommand(TC5Banking.Config.OpenCommand, function(src)
    if src == 0 then return end
    TriggerEvent('tc5_banking:server:openUi', 'bank')
end, false)

RegisterCommand(TC5Banking.Config.ATMCommand, function(src)
    if src == 0 then return end
    TriggerEvent('tc5_banking:server:openUi', 'atm')
end, false)

RegisterCommand(TC5Banking.Config.CloseCommand, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_banking:client:forceClose', src)
end, false)

RegisterCommand('bankaccounts', function(src)
    if src == 0 then return end

    local accounts = getAccessibleAccounts(src)
    if #accounts == 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Banking', 'No accessible accounts found.' } })
        return
    end

    for i = 1, #accounts do
        local account = accounts[i]
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'Banking', ('[%s] %s | %s | %s | %s%s'):format(
                tostring(account.id),
                tostring(account.name),
                tostring(account.accountNumber),
                tostring(account.type),
                TC5Banking.Utils.FormatMoney(account.balance),
                account.isDefault and ' | default' or ''
            ) }
        })
    end
end, false)

RegisterCommand('bankcreatepersonal', function(src, args)
    if src == 0 then return end
    local accountName = table.concat(args or {}, ' ')
    local ok, result = createPersonalAccount(src, accountName)
    if ok then
        notify(src, 'Banking', 'Personal account created successfully.', 'success')
    else
        notify(src, 'Banking', 'Could not create personal account.', 'error')
    end
end, false)

RegisterCommand('bankcreatebusiness', function(src, args)
    if src == 0 then return end
    local jobName = args[1] or ''
    table.remove(args, 1)
    local accountName = table.concat(args or {}, ' ')
    local ok, result = createBusinessAccount(src, jobName, accountName)
    if ok then
        notify(src, 'Banking', 'Business account created successfully.', 'success')
    else
        notify(src, 'Banking', 'Could not create business account.', 'error')
    end
end, false)

RegisterCommand('banksetdefault', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    if not accountId then
        notify(src, 'Banking', 'Usage: /banksetdefault [accountId]', 'error')
        return
    end
    local charId = getCharacterId(src)
    if not charId then return end
    setDefaultPersonalAccount(charId, accountId)
    local defaultAccount = getDefaultPersonalAccount(charId)
    if defaultAccount then
        syncLegacyBank(src, tonumber(defaultAccount.balance) or 0)
        notify(src, 'Banking', 'Default account updated.', 'success')
    end
end, false)

RegisterCommand('bankdeposit', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not accountId or not amount then
        notify(src, 'Banking', 'Usage: /bankdeposit [accountId] [amount]', 'error')
        return
    end
    local ok, result = depositToAccount(src, accountId, amount, 'Chat command deposit')
    if ok then
        notify(src, 'Banking', ('Deposit complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    else
        notify(src, 'Banking', 'Deposit failed.', 'error')
    end
end, false)

RegisterCommand('bankwithdraw', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not accountId or not amount then
        notify(src, 'Banking', 'Usage: /bankwithdraw [accountId] [amount]', 'error')
        return
    end
    local ok, result = withdrawFromAccount(src, accountId, amount, 'Chat command withdrawal')
    if ok then
        notify(src, 'Banking', ('Withdrawal complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    else
        notify(src, 'Banking', 'Withdrawal failed.', 'error')
    end
end, false)

RegisterCommand('banktransfer', function(src, args)
    if src == 0 then return end
    local fromAccountId = tonumber(args[1])
    local targetAccountNumber = tostring(args[2] or '')
    local amount = tonumber(args[3])
    if not fromAccountId or targetAccountNumber == '' or not amount then
        notify(src, 'Banking', 'Usage: /banktransfer [fromAccountId] [toAccountNumber] [amount] [reference]', 'error')
        return
    end
    local reference = ''
    if #args >= 4 then
        reference = table.concat(args, ' ', 4)
    end
    local ok, result = transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reference)
    if ok then
        notify(src, 'Banking', ('Transfer complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)), 'success')
    else
        notify(src, 'Banking', 'Transfer failed.', 'error')
    end
end, false)

exports('GetAccessibleAccounts', function(src)
    return getAccessibleAccounts(src)
end)

exports('GetDefaultPersonalAccount', function(src)
    local charId = getCharacterId(src)
    if not charId then return nil end
    return getDefaultPersonalAccount(charId)
end)

exports('GetBalance', function(src, accountId)
    local ok, account = canAccessAccount(src, accountId, 'view')
    if not ok then return nil end
    return tonumber(account.balance) or 0
end)

exports('DepositToAccount', function(src, accountId, amount, reason)
    return depositToAccount(src, accountId, amount, reason)
end)

exports('WithdrawFromAccount', function(src, accountId, amount, reason)
    return withdrawFromAccount(src, accountId, amount, reason)
end)

exports('TransferBetweenAccounts', function(src, fromAccountId, targetAccountNumber, amount, reason)
    return transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reason)
end)

exports('CreateBusinessAccount', function(src, jobName, accountName)
    return createBusinessAccount(src, jobName, accountName)
end)

exports('CreatePersonalAccount', function(src, accountName)
    return createPersonalAccount(src, accountName)
end)

exports('GetCashOnHand', function(src)
    return getCashOnHand(src)
end)


TC5Banking = TC5Banking or {}
TC5Banking.State = TC5Banking.State or { payrollPaidAt = {} }

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

local function getPlayerData(src)
    if exports['tc5_core'] and exports['tc5_core'].GetPlayerData then
        return exports['tc5_core']:GetPlayerData(src)
    end
    return nil
end

local function getCharacterId(src)
    if exports['tc5_core'] and exports['tc5_core'].GetCharacterId then
        return exports['tc5_core']:GetCharacterId(src)
    end
    return nil
end

local function getCharacterName(src)
    local data = getPlayerData(src)
    if data and data.character and data.character.fullName then
        return tostring(data.character.fullName)
    end
    return GetPlayerName(src) or ('Player %s'):format(tostring(src))
end

local function syncLegacyBank(src, amount)
    local charId = getCharacterId(src)
    if not charId then return end
    MySQL.update.await('UPDATE tc5_characters SET bank = ? WHERE id = ?', {
        math.max(0, math.floor(tonumber(amount) or 0)),
        tonumber(charId)
    })
end

local function getLegacyBankAmount(src)
    local data = getPlayerData(src)
    if data and data.character then
        return math.max(0, math.floor(tonumber(data.character.bank) or 0))
    end
    return 0
end

local function getCurrentJob(src)
    if exports['tc5_jobs'] and exports['tc5_jobs'].GetPlayerJob then
        local job = exports['tc5_jobs']:GetPlayerJob(src)
        if type(job) == 'table' then
            return {
                name = tostring(job.name or job.job or ''),
                label = tostring(job.label or job.name or ''),
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

local function getInventory(src)
    if exports['tc5_inventory'] and exports['tc5_inventory'].GetInventory then
        return exports['tc5_inventory']:GetInventory(src)
    end
    return nil
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
    local slots = {}

    for slot, item in pairs(inventory.items) do
        if item.name == TC5Banking.Config.CashItemName then
            slots[#slots + 1] = {
                slot = tonumber(slot),
                amount = tonumber(item.amount) or 0
            }
        end
    end

    table.sort(slots, function(a, b)
        return a.slot < b.slot
    end)

    for i = 1, #slots do
        if remaining <= 0 then break end
        local entry = slots[i]
        local take = math.min(entry.amount, remaining)
        local ok = exports['tc5_inventory']:RemoveItem(src, TC5Banking.Config.CashItemName, take, entry.slot)
        if ok then
            remaining = remaining - take
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

local function updateAccountBalance(accountId, newBalance)
    MySQL.update.await('UPDATE tc5_bank_accounts SET balance = ? WHERE id = ?', {
        math.max(0, math.floor(tonumber(newBalance) or 0)),
        tonumber(accountId)
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

    if account then
        return account
    end

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

local function ensureCharacterSetup(src)
    local charId = getCharacterId(src)
    if not charId then return false end

    local existing = getDefaultPersonalAccount(charId)
    if existing then
        syncLegacyBank(src, tonumber(existing.balance) or 0)
        return true
    end

    local legacyBank = getLegacyBankAmount(src)
    local accountId = MySQL.insert.await([[
        INSERT INTO tc5_bank_accounts (account_type, owner_char_id, account_name, account_number, sort_code, balance, is_default)
        VALUES ('personal', ?, ?, ?, ?, ?, 1)
    ]], {
        tonumber(charId),
        'Main Account',
        generateUniqueAccountNumber(),
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

local function buildAccountPermissions(src, account)
    local charId = getCharacterId(src)
    if not charId or not account then return nil end

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
            invoice = true,
            payroll = false,
            role = 'owner'
        }
    end

    if account.account_type == 'business' then
        local job = getCurrentJob(src)
        if job.name == '' then return nil end

        local access = MySQL.single.await([[
            SELECT * FROM tc5_bank_business_access
            WHERE account_id = ? AND job_name = ?
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

        local manage = job.grade >= minGrade
        return {
            view = true,
            deposit = true,
            withdraw = true,
            transfer = true,
            manage = manage,
            invoice = true,
            payroll = manage,
            role = manage and 'manager' or 'member',
            job = job,
            minGrade = minGrade
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
        return false, account
    end

    if permission and permissions[permission] ~= true then
        return false, account, permissions
    end

    return true, account, permissions
end

local function getStatements(accountId)
    local rows = MySQL.query.await([[
        SELECT * FROM tc5_bank_transactions
        WHERE account_id = ?
        ORDER BY id DESC
        LIMIT ?
    ]], {
        tonumber(accountId),
        tonumber(TC5Banking.Config.StatementLimit) or 60
    }) or {}

    local statements = {}
    for i = 1, #rows do
        local row = rows[i]
        statements[#statements + 1] = {
            id = tonumber(row.id),
            type = row.tx_type,
            amount = tonumber(row.amount) or 0,
            balanceAfter = tonumber(row.balance_after) or 0,
            reference = row.reference_text or '',
            targetAccountNumber = row.target_account_number or '',
            createdAt = tostring(row.created_at or '')
        }
    end
    return statements
end

local function getAccessibleAccounts(src)
    ensureCharacterSetup(src)
    local charId = getCharacterId(src)
    if not charId then return {} end

    local accounts = {}
    local personalRows = MySQL.query.await('SELECT * FROM tc5_bank_accounts WHERE owner_char_id = ? ORDER BY is_default DESC, id ASC', {
        tonumber(charId)
    }) or {}

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
                businessJobName = account.business_job_name or '',
                permissions = permissions
            }
        end
    end

    local job = getCurrentJob(src)
    if job.name ~= '' then
        local businessRows = MySQL.query.await([[
            SELECT a.*
            FROM tc5_bank_accounts a
            INNER JOIN tc5_bank_business_access b ON b.account_id = a.id
            WHERE a.account_type = 'business' AND b.job_name = ? AND b.min_grade <= ?
            GROUP BY a.id
            ORDER BY a.id ASC
        ]], {
            job.name,
            job.grade
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
                    businessJobName = account.business_job_name or '',
                    permissions = permissions
                }
            end
        end
    end

    table.sort(accounts, function(a, b)
        if a.type ~= b.type then return a.type < b.type end
        if a.isDefault ~= b.isDefault then return a.isDefault end
        return a.id < b.id
    end)

    return accounts
end

local function getPayrollRows(accountId)
    local rows = MySQL.query.await('SELECT * FROM tc5_bank_payroll WHERE account_id = ? ORDER BY grade ASC', {
        tonumber(accountId)
    }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = tonumber(row.id),
            grade = tonumber(row.grade) or 0,
            amount = tonumber(row.amount) or 0,
            jobName = tostring(row.job_name or '')
        }
    end
    return out
end

local function getPendingInvoicesForChar(charId)
    local rows = MySQL.query.await([[
        SELECT i.*, a.account_name
        FROM tc5_bank_invoices i
        INNER JOIN tc5_bank_accounts a ON a.id = i.account_id
        WHERE i.to_char_id = ? AND i.status = 'pending'
        ORDER BY i.id DESC
    ]], {
        tonumber(charId)
    }) or {}

    local invoices = {}
    for i = 1, #rows do
        local row = rows[i]
        invoices[#invoices + 1] = {
            id = tonumber(row.id),
            accountId = tonumber(row.account_id),
            accountName = tostring(row.account_name or 'Business'),
            fromCharId = tonumber(row.from_char_id),
            fromName = tostring(row.from_name or ''),
            toCharId = tonumber(row.to_char_id),
            toName = tostring(row.to_name or ''),
            amount = tonumber(row.amount) or 0,
            reason = tostring(row.reason or ''),
            status = tostring(row.status or 'pending'),
            createdAt = tostring(row.created_at or '')
        }
    end
    return invoices
end

local function buildUiPayload(src, mode, focusAccountId)
    local playerData = getPlayerData(src)
    local charId = getCharacterId(src)
    local accounts = getAccessibleAccounts(src)
    local statementsByAccount = {}
    local payrollByAccount = {}

    for i = 1, #accounts do
        statementsByAccount[tostring(accounts[i].id)] = getStatements(accounts[i].id)
        if accounts[i].type == 'business' then
            payrollByAccount[tostring(accounts[i].id)] = getPayrollRows(accounts[i].id)
        end
    end

    return {
        mode = mode or 'bank',
        character = playerData and playerData.character and {
            id = playerData.character.id,
            fullName = playerData.character.fullName
        } or nil,
        cashOnHand = getCashOnHand(src),
        job = getCurrentJob(src),
        accounts = accounts,
        statements = statementsByAccount,
        payroll = payrollByAccount,
        pendingInvoices = charId and getPendingInvoicesForChar(charId) or {},
        focusAccountId = focusAccountId,
        config = {
            maxPersonalAccounts = TC5Banking.Config.MaxPersonalAccounts,
            statementLimit = TC5Banking.Config.StatementLimit,
            enableATMDeposits = TC5Banking.Config.EnableATMDeposits,
            enableATMTransfers = TC5Banking.Config.EnableATMTransfers,
            enablePayroll = TC5Banking.Config.EnablePayroll
        }
    }
end

local function refreshUi(src, mode, focusAccountId)
    TriggerClientEvent('tc5_banking:client:refreshUi', src, buildUiPayload(src, mode, focusAccountId))
end

local function createPersonalAccount(src, accountName)
    local charId = getCharacterId(src)
    if not charId then return false, 'no_character' end
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

    local requiredGrade = tonumber(TC5Banking.Config.BusinessCreationMinGrade) or 3
    if job.grade < requiredGrade then
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
        tonumber(TC5Banking.Config.DefaultBusinessAccessGrade) or requiredGrade
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
    updateAccountBalance(account.id, newBalance)
    local charId = getCharacterId(src)
    insertTransaction(account.id, charId, 'deposit', amount, newBalance, reference ~= '' and reference or 'Cash deposit', nil)

    if account.account_type == 'personal' and tonumber(account.owner_char_id) == tonumber(charId) then
        local defaultAccount = getDefaultPersonalAccount(charId)
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

    if exports['tc5_inventory'] and exports['tc5_inventory'].CanCarryItem then
        local canCarry = exports['tc5_inventory']:CanCarryItem(src, TC5Banking.Config.CashItemName, amount)
        if canCarry == false then
            return false, 'cannot_carry_cash'
        end
    end

    local okAdd = addCashItem(src, amount)
    if not okAdd then return false, 'cannot_carry_cash' end

    local newBalance = balance - amount
    updateAccountBalance(account.id, newBalance)
    local charId = getCharacterId(src)
    insertTransaction(account.id, charId, 'withdraw', amount, newBalance, reference ~= '' and reference or 'Cash withdrawal', nil)

    if account.account_type == 'personal' and tonumber(account.owner_char_id) == tonumber(charId) then
        local defaultAccount = getDefaultPersonalAccount(charId)
        if defaultAccount and tonumber(defaultAccount.id) == tonumber(account.id) then
            syncLegacyBank(src, newBalance)
        end
    end

    TriggerClientEvent('tc5_inventory:client:refreshInventory', src)
    return true, newBalance
end

local function transferByAccounts(src, fromAccount, target, amount, reference, txOutType, txInType)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return false, 'invalid_amount' end
    if tonumber(fromAccount.is_frozen) == 1 then return false, 'account_frozen' end
    if tonumber(target.is_frozen) == 1 then return false, 'target_frozen' end

    local fromBalance = tonumber(fromAccount.balance) or 0
    if fromBalance < amount then return false, 'insufficient_funds' end

    local newFromBalance = fromBalance - amount
    local newToBalance = (tonumber(target.balance) or 0) + amount

    updateAccountBalance(fromAccount.id, newFromBalance)
    updateAccountBalance(target.id, newToBalance)

    local actorCharId = src and getCharacterId(src) or nil
    local ref = reference ~= '' and reference or 'Bank transfer'
    insertTransaction(fromAccount.id, actorCharId, txOutType or 'transfer_out', amount, newFromBalance, ref, target.account_number)
    insertTransaction(target.id, actorCharId, txInType or 'transfer_in', amount, newToBalance, ref, fromAccount.account_number)

    if src and fromAccount.account_type == 'personal' and tonumber(fromAccount.owner_char_id) == tonumber(actorCharId) then
        local defaultAccount = getDefaultPersonalAccount(actorCharId)
        if defaultAccount and tonumber(defaultAccount.id) == tonumber(fromAccount.id) then
            syncLegacyBank(src, newFromBalance)
        end
    end

    return true, newFromBalance, newToBalance
end

local function transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reference)
    local ok, fromAccount = canAccessAccount(src, fromAccountId, 'transfer')
    if not ok then return false, 'no_access' end

    local target = getAccountByNumber(targetAccountNumber)
    if not target then return false, 'target_not_found' end
    if tonumber(target.id) == tonumber(fromAccount.id) then return false, 'same_account' end

    return transferByAccounts(src, fromAccount, target, amount, reference, 'transfer_out', 'transfer_in')
end

local function setBusinessAccessGrade(src, accountId, minGrade)
    minGrade = math.max(0, math.floor(tonumber(minGrade) or 0))
    local ok, account = canAccessAccount(src, accountId, 'manage')
    if not ok or account.account_type ~= 'business' then
        return false, 'no_access'
    end

    local jobName = tostring(account.business_job_name or '')
    if jobName == '' then
        return false, 'invalid_account'
    end

    MySQL.update.await([[
        UPDATE tc5_bank_business_access
        SET min_grade = ?
        WHERE account_id = ? AND job_name = ?
    ]], {
        minGrade,
        tonumber(account.id),
        jobName
    })

    return true
end

local function setBusinessFrozen(src, accountId, isFrozen)
    local ok, account = canAccessAccount(src, accountId, 'manage')
    if not ok or account.account_type ~= 'business' then
        return false, 'no_access'
    end

    MySQL.update.await('UPDATE tc5_bank_accounts SET is_frozen = ? WHERE id = ?', {
        isFrozen and 1 or 0,
        tonumber(account.id)
    })
    return true
end

local function setPayrollAmount(src, accountId, grade, amount)
    grade = math.max(0, math.floor(tonumber(grade) or 0))
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    local ok, account = canAccessAccount(src, accountId, 'payroll')
    if not ok or account.account_type ~= 'business' then
        return false, 'no_access'
    end

    MySQL.insert.await([[
        INSERT INTO tc5_bank_payroll (account_id, job_name, grade, amount)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE amount = VALUES(amount), updated_at = CURRENT_TIMESTAMP
    ]], {
        tonumber(account.id),
        tostring(account.business_job_name or ''),
        grade,
        amount
    })

    return true
end

local function payPlayerFromBusiness(src, accountId, targetSrc, amount, reference)
    targetSrc = tonumber(targetSrc)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    reference = TC5Banking.Utils.Trim(reference)

    if not targetSrc or GetPlayerPing(targetSrc) <= 0 then
        return false, 'target_not_found'
    end
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local ok, businessAccount = canAccessAccount(src, accountId, 'payroll')
    if not ok or businessAccount.account_type ~= 'business' then
        return false, 'no_access'
    end

    ensureCharacterSetup(targetSrc)
    local targetCharId = getCharacterId(targetSrc)
    if not targetCharId then
        return false, 'target_character_missing'
    end

    local targetDefault = getDefaultPersonalAccount(targetCharId)
    if not targetDefault then
        return false, 'target_account_missing'
    end

    local success = transferByAccounts(src, businessAccount, targetDefault, amount, reference ~= '' and reference or 'Business payment', 'business_payment_out', 'business_payment_in')
    if not success then
        return false, targetDefault
    end

    notify(targetSrc, 'Banking', ('You received %s from %s.'):format(TC5Banking.Utils.FormatMoney(amount), tostring(businessAccount.account_name)), 'success')
    syncLegacyBank(targetSrc, tonumber(getDefaultPersonalAccount(targetCharId).balance) or 0)
    return true
end

local function createInvoice(src, targetSrc, accountId, amount, reason)
    targetSrc = tonumber(targetSrc)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    reason = TC5Banking.Utils.Trim(reason)

    if not targetSrc or GetPlayerPing(targetSrc) <= 0 then
        return false, 'target_not_found'
    end
    if amount <= 0 then
        return false, 'invalid_amount'
    end
    if amount > (tonumber(TC5Banking.Config.MaxInvoiceAmount) or 500000) then
        return false, 'invoice_too_large'
    end

    local ok, account = canAccessAccount(src, accountId, 'invoice')
    if not ok then
        return false, 'no_access'
    end
    if tonumber(account.is_frozen) == 1 then
        return false, 'account_frozen'
    end

    local fromCharId = getCharacterId(src)
    local toCharId = getCharacterId(targetSrc)
    if not fromCharId or not toCharId then
        return false, 'character_missing'
    end

    local invoiceId = MySQL.insert.await([[
        INSERT INTO tc5_bank_invoices (account_id, from_char_id, from_name, to_char_id, to_name, amount, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        tonumber(account.id),
        tonumber(fromCharId),
        getCharacterName(src),
        tonumber(toCharId),
        getCharacterName(targetSrc),
        amount,
        reason ~= '' and reason or 'Invoice'
    })

    notify(targetSrc, 'Invoice', ('New invoice received for %s. Open /bankmobile or /bank to review it.'):format(TC5Banking.Utils.FormatMoney(amount)), 'info')
    return true, invoiceId
end

local function acceptInvoice(src, invoiceId)
    local charId = getCharacterId(src)
    if not charId then return false, 'no_character' end
    ensureCharacterSetup(src)

    local invoice = MySQL.single.await('SELECT * FROM tc5_bank_invoices WHERE id = ? LIMIT 1', {
        tonumber(invoiceId)
    })

    if not invoice then return false, 'invoice_not_found' end
    if tostring(invoice.status) ~= 'pending' then return false, 'invoice_closed' end
    if tonumber(invoice.to_char_id) ~= tonumber(charId) then return false, 'not_your_invoice' end

    local payerAccount = getDefaultPersonalAccount(charId)
    if not payerAccount then return false, 'no_account' end

    local businessAccount = getAccountById(invoice.account_id)
    if not businessAccount then return false, 'target_missing' end

    local ok, reason = transferByAccounts(src, payerAccount, businessAccount, invoice.amount, invoice.reason or 'Invoice payment', 'invoice_payment_out', 'invoice_payment_in')
    if not ok then
        return false, reason
    end

    MySQL.update.await('UPDATE tc5_bank_invoices SET status = ? WHERE id = ?', { 'paid', tonumber(invoice.id) })
    syncLegacyBank(src, tonumber(getDefaultPersonalAccount(charId).balance) or 0)
    return true
end

local function declineInvoice(src, invoiceId)
    local charId = getCharacterId(src)
    if not charId then return false, 'no_character' end

    local invoice = MySQL.single.await('SELECT * FROM tc5_bank_invoices WHERE id = ? LIMIT 1', {
        tonumber(invoiceId)
    })

    if not invoice then return false, 'invoice_not_found' end
    if tostring(invoice.status) ~= 'pending' then return false, 'invoice_closed' end
    if tonumber(invoice.to_char_id) ~= tonumber(charId) then return false, 'not_your_invoice' end

    MySQL.update.await('UPDATE tc5_bank_invoices SET status = ? WHERE id = ?', { 'declined', tonumber(invoice.id) })
    return true
end

local function processPayrollForPlayer(src)
    if not TC5Banking.Config.EnablePayroll then return end
    local charId = getCharacterId(src)
    if not charId then return end
    ensureCharacterSetup(src)

    local now = os.time()
    local lastPaid = TC5Banking.State.payrollPaidAt[src] or 0
    local interval = math.max(1, tonumber(TC5Banking.Config.PayIntervalMinutes) or 30) * 60
    if now - lastPaid < interval then
        return
    end

    local job = getCurrentJob(src)
    if job.name == '' then
        return
    end

    local row = MySQL.single.await([[
        SELECT p.*, a.balance, a.account_number, a.id AS resolved_account_id, a.is_frozen
        FROM tc5_bank_payroll p
        INNER JOIN tc5_bank_accounts a ON a.id = p.account_id
        WHERE p.job_name = ? AND p.grade = ? AND a.account_type = 'business'
        LIMIT 1
    ]], {
        job.name,
        job.grade
    })

    if not row then
        return
    end

    if tonumber(row.is_frozen) == 1 then
        return
    end

    local amount = tonumber(row.amount) or 0
    if amount <= 0 then
        return
    end

    local defaultAccount = getDefaultPersonalAccount(charId)
    if not defaultAccount then return end

    local businessAccount = getAccountById(row.resolved_account_id or row.account_id)
    if not businessAccount then return end

    local ok = transferByAccounts(src, businessAccount, defaultAccount, amount, TC5Banking.Config.PayrollReference or 'Salary payment', 'payroll_out', 'payroll_in')
    if ok then
        TC5Banking.State.payrollPaidAt[src] = now
        syncLegacyBank(src, tonumber(getDefaultPersonalAccount(charId).balance) or 0)
        notify(src, 'Payroll', ('You were paid %s.'):format(TC5Banking.Utils.FormatMoney(amount)), 'success')
    end
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
            no_character = 'Character not loaded.',
            max_accounts = 'You have reached the maximum number of personal accounts.'
        }
        notify(src, 'Banking', map[result] or 'Could not create personal account.', 'error')
        refreshUi(src, mode or 'bank')
        return
    end
    notify(src, 'Banking', 'Personal account created.', 'success')
    refreshUi(src, mode or 'bank', result)
end)

RegisterNetEvent('tc5_banking:server:createBusinessAccount', function(jobName, accountName, mode)
    local src = source
    local ok, result = createBusinessAccount(src, jobName, accountName)
    if not ok then
        local map = {
            invalid_arguments = 'Enter a valid job and account name.',
            job_mismatch = 'You can only create a business account for your active job.',
            grade_too_low = 'Your grade is too low to create a business account.',
            business_exists = 'That job already has a business account.'
        }
        notify(src, 'Banking', map[result] or 'Could not create business account.', 'error')
        refreshUi(src, mode or 'bank')
        return
    end
    notify(src, 'Banking', 'Business account created.', 'success')
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
            account_frozen = 'Source account is frozen.',
            target_frozen = 'Target account is frozen.',
            target_not_found = 'Target account was not found.',
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

RegisterNetEvent('tc5_banking:server:createInvoice', function(targetSrc, accountId, amount, reason, mode)
    local src = source
    local ok, result = createInvoice(src, targetSrc, accountId, amount, reason)
    if not ok then
        local map = {
            target_not_found = 'Target player was not found.',
            invalid_amount = 'Enter a valid invoice amount.',
            invoice_too_large = 'Invoice exceeds the configured maximum.',
            no_access = 'You do not have invoice access on that account.',
            account_frozen = 'That account is frozen.',
            character_missing = 'A player character is not loaded.'
        }
        notify(src, 'Invoice', map[result] or 'Invoice creation failed.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end
    notify(src, 'Invoice', ('Invoice #%s sent.'):format(tostring(result)), 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:acceptInvoice', function(invoiceId, mode)
    local src = source
    local ok, result = acceptInvoice(src, invoiceId)
    if not ok then
        local map = {
            invoice_not_found = 'Invoice not found.',
            invoice_closed = 'That invoice is no longer pending.',
            not_your_invoice = 'That invoice does not belong to you.',
            no_account = 'You do not have a default account.',
            target_missing = 'The destination account is missing.',
            insufficient_funds = 'Insufficient funds.',
            account_frozen = 'Source account is frozen.',
            target_frozen = 'Destination account is frozen.'
        }
        notify(src, 'Invoice', map[result] or 'Invoice payment failed.', 'error')
        refreshUi(src, mode or 'mobile')
        return
    end
    notify(src, 'Invoice', 'Invoice paid successfully.', 'success')
    refreshUi(src, mode or 'mobile')
end)

RegisterNetEvent('tc5_banking:server:declineInvoice', function(invoiceId, mode)
    local src = source
    local ok, result = declineInvoice(src, invoiceId)
    if not ok then
        local map = {
            invoice_not_found = 'Invoice not found.',
            invoice_closed = 'That invoice is no longer pending.',
            not_your_invoice = 'That invoice does not belong to you.'
        }
        notify(src, 'Invoice', map[result] or 'Could not decline invoice.', 'error')
        refreshUi(src, mode or 'mobile')
        return
    end
    notify(src, 'Invoice', 'Invoice declined.', 'success')
    refreshUi(src, mode or 'mobile')
end)

RegisterNetEvent('tc5_banking:server:setBusinessAccess', function(accountId, minGrade, mode)
    local src = source
    local ok, result = setBusinessAccessGrade(src, accountId, minGrade)
    if not ok then
        notify(src, 'Business', result == 'no_access' and 'You do not have access to manage that business account.' or 'Could not update access grade.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end
    notify(src, 'Business', 'Business access grade updated.', 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:setBusinessFrozen', function(accountId, frozenState, mode)
    local src = source
    local ok = setBusinessFrozen(src, accountId, frozenState == true)
    if not ok then
        notify(src, 'Business', 'Could not update frozen state.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end
    notify(src, 'Business', frozenState and 'Business account frozen.' or 'Business account unfrozen.', 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:businessPayPlayer', function(accountId, targetSrc, amount, reference, mode)
    local src = source
    local ok, result = payPlayerFromBusiness(src, accountId, targetSrc, amount, reference)
    if not ok then
        local map = {
            target_not_found = 'Target player was not found.',
            invalid_amount = 'Enter a valid amount.',
            no_access = 'You do not have payroll access on that account.',
            target_character_missing = 'Target character is not loaded.',
            target_account_missing = 'Target player has no bank account.',
            insufficient_funds = 'Business account has insufficient funds.',
            account_frozen = 'Business account is frozen.',
            target_frozen = 'Target account is frozen.'
        }
        notify(src, 'Business', map[result] or 'Business payment failed.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end
    notify(src, 'Business', 'Business payment sent.', 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

RegisterNetEvent('tc5_banking:server:setPayroll', function(accountId, grade, amount, mode)
    local src = source
    local ok, result = setPayrollAmount(src, accountId, grade, amount)
    if not ok then
        notify(src, 'Payroll', result == 'no_access' and 'You do not have payroll access to that account.' or 'Could not update payroll.', 'error')
        refreshUi(src, mode or 'bank', accountId)
        return
    end
    notify(src, 'Payroll', 'Payroll amount updated.', 'success')
    refreshUi(src, mode or 'bank', accountId)
end)

CreateThread(function()
    while true do
        Wait(10000)
        if TC5Banking.Config.EnablePayroll then
            for _, src in ipairs(GetPlayers()) do
                local numericSrc = tonumber(src)
                if numericSrc then
                    pcall(processPayrollForPlayer, numericSrc)
                end
            end
        end
    end
end)

RegisterCommand(TC5Banking.Config.OpenCommand, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_banking:client:openUi', src, buildUiPayload(src, 'bank'))
end, false)

RegisterCommand(TC5Banking.Config.ATMCommand, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_banking:client:openUi', src, buildUiPayload(src, 'atm'))
end, false)

RegisterCommand(TC5Banking.Config.MobileCommand, function(src)
    if src == 0 then return end
    TriggerClientEvent('tc5_banking:client:openUi', src, buildUiPayload(src, 'mobile'))
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
    local ok = createPersonalAccount(src, table.concat(args or {}, ' '))
    notify(src, 'Banking', ok and 'Personal account created.' or 'Could not create personal account.', ok and 'success' or 'error')
end, false)

RegisterCommand('bankcreatebusiness', function(src, args)
    if src == 0 then return end
    local jobName = args[1] or ''
    table.remove(args, 1)
    local ok = createBusinessAccount(src, jobName, table.concat(args or {}, ' '))
    notify(src, 'Banking', ok and 'Business account created.' or 'Could not create business account.', ok and 'success' or 'error')
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
    notify(src, 'Banking', ok and ('Deposit complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)) or 'Deposit failed.', ok and 'success' or 'error')
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
    notify(src, 'Banking', ok and ('Withdrawal complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)) or 'Withdrawal failed.', ok and 'success' or 'error')
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
    local reference = #args >= 4 and table.concat(args, ' ', 4) or ''
    local ok, result = transferBetweenAccounts(src, fromAccountId, targetAccountNumber, amount, reference)
    notify(src, 'Banking', ok and ('Transfer complete. New balance: %s'):format(TC5Banking.Utils.FormatMoney(result)) or 'Transfer failed.', ok and 'success' or 'error')
end, false)

RegisterCommand('bill', function(src, args)
    if src == 0 then return end
    local targetSrc = tonumber(args[1])
    local accountId = tonumber(args[2])
    local amount = tonumber(args[3])
    if not targetSrc or not accountId or not amount then
        notify(src, 'Invoice', 'Usage: /bill [playerId] [accountId] [amount] [reason]', 'error')
        return
    end
    local reason = #args >= 4 and table.concat(args, ' ', 4) or 'Invoice'
    local ok, result = createInvoice(src, targetSrc, accountId, amount, reason)
    notify(src, 'Invoice', ok and ('Invoice #%s sent.'):format(tostring(result)) or 'Invoice failed.', ok and 'success' or 'error')
end, false)

RegisterCommand('bankinvoiceaccept', function(src, args)
    if src == 0 then return end
    local invoiceId = tonumber(args[1])
    if not invoiceId then
        notify(src, 'Invoice', 'Usage: /bankinvoiceaccept [invoiceId]', 'error')
        return
    end
    local ok = acceptInvoice(src, invoiceId)
    notify(src, 'Invoice', ok and 'Invoice paid.' or 'Invoice payment failed.', ok and 'success' or 'error')
end, false)

RegisterCommand('bankinvoicedecline', function(src, args)
    if src == 0 then return end
    local invoiceId = tonumber(args[1])
    if not invoiceId then
        notify(src, 'Invoice', 'Usage: /bankinvoicedecline [invoiceId]', 'error')
        return
    end
    local ok = declineInvoice(src, invoiceId)
    notify(src, 'Invoice', ok and 'Invoice declined.' or 'Could not decline invoice.', ok and 'success' or 'error')
end, false)

RegisterCommand('businesspay', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local targetSrc = tonumber(args[2])
    local amount = tonumber(args[3])
    if not accountId or not targetSrc or not amount then
        notify(src, 'Business', 'Usage: /businesspay [accountId] [playerId] [amount] [reason]', 'error')
        return
    end
    local reason = #args >= 4 and table.concat(args, ' ', 4) or 'Business payment'
    local ok = payPlayerFromBusiness(src, accountId, targetSrc, amount, reason)
    notify(src, 'Business', ok and 'Business payment sent.' or 'Business payment failed.', ok and 'success' or 'error')
end, false)

RegisterCommand('businessaccess', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local grade = tonumber(args[2])
    if not accountId or grade == nil then
        notify(src, 'Business', 'Usage: /businessaccess [accountId] [minGrade]', 'error')
        return
    end
    local ok = setBusinessAccessGrade(src, accountId, grade)
    notify(src, 'Business', ok and 'Access grade updated.' or 'Could not update access grade.', ok and 'success' or 'error')
end, false)

RegisterCommand('businessfreeze', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local frozen = tostring(args[2] or ''):lower()
    if not accountId or (frozen ~= 'true' and frozen ~= 'false') then
        notify(src, 'Business', 'Usage: /businessfreeze [accountId] [true/false]', 'error')
        return
    end
    local ok = setBusinessFrozen(src, accountId, frozen == 'true')
    notify(src, 'Business', ok and 'Frozen state updated.' or 'Could not update frozen state.', ok and 'success' or 'error')
end, false)

RegisterCommand('businesssetwage', function(src, args)
    if src == 0 then return end
    local accountId = tonumber(args[1])
    local grade = tonumber(args[2])
    local amount = tonumber(args[3])
    if not accountId or grade == nil or amount == nil then
        notify(src, 'Payroll', 'Usage: /businesssetwage [accountId] [grade] [amount]', 'error')
        return
    end
    local ok = setPayrollAmount(src, accountId, grade, amount)
    notify(src, 'Payroll', ok and 'Payroll amount updated.' or 'Could not update payroll.', ok and 'success' or 'error')
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

exports('CreateInvoice', function(src, targetSrc, accountId, amount, reason)
    return createInvoice(src, targetSrc, accountId, amount, reason)
end)

exports('AcceptInvoice', function(src, invoiceId)
    return acceptInvoice(src, invoiceId)
end)

exports('DeclineInvoice', function(src, invoiceId)
    return declineInvoice(src, invoiceId)
end)

exports('PayPlayerFromBusiness', function(src, accountId, targetSrc, amount, reason)
    return payPlayerFromBusiness(src, accountId, targetSrc, amount, reason)
end)

exports('SetBusinessAccessGrade', function(src, accountId, minGrade)
    return setBusinessAccessGrade(src, accountId, minGrade)
end)

exports('SetPayrollAmount', function(src, accountId, grade, amount)
    return setPayrollAmount(src, accountId, grade, amount)
end)

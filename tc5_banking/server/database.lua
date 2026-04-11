CreateThread(function()
    Wait(500)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_bank_accounts (
            id INT NOT NULL AUTO_INCREMENT,
            account_type VARCHAR(20) NOT NULL DEFAULT 'personal',
            owner_char_id INT NULL,
            business_job_name VARCHAR(50) NULL,
            account_name VARCHAR(100) NOT NULL,
            account_number VARCHAR(20) NOT NULL,
            sort_code VARCHAR(12) NOT NULL,
            balance BIGINT NOT NULL DEFAULT 0,
            is_default TINYINT(1) NOT NULL DEFAULT 0,
            is_frozen TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_account_number (account_number)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_bank_business_access (
            id INT NOT NULL AUTO_INCREMENT,
            account_id INT NOT NULL,
            job_name VARCHAR(50) NOT NULL,
            min_grade INT NOT NULL DEFAULT 0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_account_job (account_id, job_name)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_bank_transactions (
            id INT NOT NULL AUTO_INCREMENT,
            account_id INT NOT NULL,
            actor_char_id INT NULL,
            tx_type VARCHAR(30) NOT NULL,
            amount BIGINT NOT NULL,
            balance_after BIGINT NOT NULL,
            reference_text VARCHAR(255) NULL,
            target_account_number VARCHAR(20) NULL,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_account_created (account_id, created_at)
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tc5_bank_migrations (
            char_id INT NOT NULL,
            migrated_legacy_bank TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (char_id)
        )
    ]])

    print('^2[tc5_banking]^7 Database ready.')
end)

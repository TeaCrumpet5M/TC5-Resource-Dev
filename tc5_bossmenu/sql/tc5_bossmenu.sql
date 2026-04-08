CREATE TABLE IF NOT EXISTS tc5_society_accounts (
    job_name VARCHAR(50) NOT NULL,
    balance INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (job_name)
);

CREATE TABLE IF NOT EXISTS tc5_job_employees (
    id INT NOT NULL AUTO_INCREMENT,
    character_id INT NOT NULL,
    source_id INT NULL,
    full_name VARCHAR(100) NOT NULL,
    job_name VARCHAR(50) NOT NULL,
    grade INT NOT NULL DEFAULT 0,
    salary INT NOT NULL DEFAULT 250,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tc5_job_employee (character_id, job_name),
    KEY idx_tc5_job_name (job_name)
);

CREATE TABLE IF NOT EXISTS tc5_job_salaries (
    id INT NOT NULL AUTO_INCREMENT,
    job_name VARCHAR(50) NOT NULL,
    grade INT NOT NULL DEFAULT 0,
    salary INT NOT NULL DEFAULT 250,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tc5_job_grade (job_name, grade)
);

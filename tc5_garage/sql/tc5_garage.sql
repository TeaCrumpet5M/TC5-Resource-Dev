CREATE TABLE IF NOT EXISTS tc5_owned_vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_char_id INT NOT NULL,
    plate VARCHAR(16) UNIQUE,
    model VARCHAR(100),
    garage_id VARCHAR(50),
    stored TINYINT DEFAULT 1
);

CREATE TABLE IF NOT EXISTS tc5_vehicle_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    char_id INT,
    is_temporary TINYINT DEFAULT 0
);

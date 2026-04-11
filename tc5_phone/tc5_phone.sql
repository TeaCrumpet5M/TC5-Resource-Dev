CREATE TABLE IF NOT EXISTS tc5_phone_numbers (
    char_id INT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (char_id),
    UNIQUE KEY uq_tc5_phone_number (phone_number)
);

CREATE TABLE IF NOT EXISTS tc5_phone_contacts (
    id INT NOT NULL AUTO_INCREMENT,
    char_id INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_tc5_phone_contacts_char (char_id)
);

CREATE TABLE IF NOT EXISTS tc5_phone_messages (
    id INT NOT NULL AUTO_INCREMENT,
    owner_char_id INT NOT NULL,
    peer_number VARCHAR(20) NOT NULL,
    sender_number VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_tc5_phone_messages_owner (owner_char_id),
    KEY idx_tc5_phone_messages_peer (peer_number)
);

CREATE TABLE IF NOT EXISTS tc5_inventory_items (
    id INT NOT NULL AUTO_INCREMENT,
    inventory_type VARCHAR(50) NOT NULL,
    inventory_owner VARCHAR(100) NOT NULL,
    slot INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    amount INT NOT NULL DEFAULT 1,
    metadata LONGTEXT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uniq_inventory_slot (inventory_type, inventory_owner, slot),
    KEY idx_inventory_lookup (inventory_type, inventory_owner),
    KEY idx_item_name (item_name)
);

CREATE TABLE IF NOT EXISTS tc5_inventory_drops (
    id VARCHAR(100) NOT NULL,
    x DOUBLE NOT NULL,
    y DOUBLE NOT NULL,
    z DOUBLE NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
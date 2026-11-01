-- Member E: medicines, prescriptions, audit_log

CREATE TABLE medicines (
    medicine_id   INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(80) NOT NULL UNIQUE,
    unit_price    DECIMAL(10,2) NOT NULL,
    stock_qty     INT NOT NULL,
    reorder_level INT NOT NULL DEFAULT 20,
    expiry_date   DATE NOT NULL,
    CONSTRAINT chk_med_price CHECK (unit_price >= 0),
    CONSTRAINT chk_med_stock CHECK (stock_qty >= 0),
    CONSTRAINT chk_med_reorder CHECK (reorder_level >= 0)
);

CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id       INT NOT NULL,
    medicine_id     INT NOT NULL,
    quantity        INT NOT NULL,
    dosage          VARCHAR(100) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL DEFAULT 0,   -- price snapshot, filled by trigger
    prescribed_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rx_qty CHECK (quantity > 0),
    CONSTRAINT fk_rx_record   FOREIGN KEY (record_id)   REFERENCES medical_records(record_id),
    CONSTRAINT fk_rx_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

CREATE TABLE audit_log (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    event_type   ENUM('ADMIT','DISCHARGE','INVOICE','PAYMENT','LOW_STOCK') NOT NULL,
    table_name   VARCHAR(40) NOT NULL,
    record_id    INT NOT NULL,
    details      VARCHAR(255),
    performed_by INT NULL,
    logged_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (performed_by) REFERENCES users(user_id)
);

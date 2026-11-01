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

INSERT INTO medicines (medicine_name, unit_price, stock_qty, reorder_level, expiry_date) VALUES
 ('Paracetamol 500mg', 2.50, 500, 100, '2028-03-31'),
 ('Amoxicillin 500mg', 8.00, 200,  50, '2027-08-31'),
 ('Metformin 500mg',   4.00, 300,  80, '2027-12-31'),
 ('Aspirin 80mg',      3.00, 150,  50, '2027-05-31'),
 ('Amlodipine 5mg',    6.00,  60,  40, '2027-09-30'),
 ('Ibuprofen 400mg',   5.00, 100,  30, '2026-06-30'),   -- already expired
 ('Losartan 50mg',     7.50,  80,  30, '2028-01-31');   -- never prescribed (LEFT JOIN demo)

INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage) VALUES
 (2, 2, 21, '1 capsule 3x a day for 7 days'),
 (2, 1, 10, '1 tablet every 6 hours if fever'),
 (3, 3, 60, '1 tablet twice a day');

INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage) VALUES
 (5, 4, 30, '1 tablet daily'),                  -- Aspirin
 (5, 1, 20, '1 tablet every 6 hours if pain'),  -- Paracetamol
 (6, 1, 30, '2 tablets every 6 hours'),
 (7, 5, 30, '1 tablet daily');                  -- Amlodipine: stock 60 -> 30 triggers LOW STOCK


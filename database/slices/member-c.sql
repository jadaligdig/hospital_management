CREATE TABLE admissions (
    admission_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id     INT NOT NULL,
    doctor_id      INT NOT NULL,
    bed_id         INT NOT NULL,
    admit_date     DATETIME NOT NULL,
    discharge_date DATETIME NULL,
    status         ENUM('Admitted','Discharged') NOT NULL DEFAULT 'Admitted',
    reason         VARCHAR(200) NOT NULL,
    CONSTRAINT chk_discharge_after_admit
        CHECK (discharge_date IS NULL OR discharge_date >= admit_date),
    CONSTRAINT fk_adm_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_adm_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
    CONSTRAINT fk_adm_bed     FOREIGN KEY (bed_id)     REFERENCES beds(bed_id)
);

CREATE TABLE invoices (
    invoice_id      INT AUTO_INCREMENT PRIMARY KEY,
    admission_id    INT NOT NULL UNIQUE,
    invoice_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    room_charge     DECIMAL(12,2) NOT NULL DEFAULT 0,
    lab_charge      DECIMAL(12,2) NOT NULL DEFAULT 0,
    medicine_charge DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(12,2) AS (room_charge + lab_charge + medicine_charge) STORED,
    amount_paid     DECIMAL(12,2) NOT NULL DEFAULT 0,
    status          ENUM('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT chk_inv_paid CHECK (amount_paid >= 0),
    CONSTRAINT fk_inv_adm FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    method     ENUM('Cash','Card','GCash','Insurance') NOT NULL,
    paid_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pay_amount CHECK (amount > 0),
    CONSTRAINT fk_pay_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

SET @app_user_id = 2;    -- dr.delacruz is logged in
INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, reason) VALUES
 (1, 3, 1, '2026-10-12 12:00:00', 'Suspected cardiac event'),    -- admission 1 (W-101 B1)
 (5, 5, 3, '2026-10-14 13:00:00', 'Appendicitis, for surgery'),  -- admission 2 (P-201 B1)
 (4, 3, 2, '2026-10-16 08:00:00', 'Hypertensive urgency');       -- admission 3 (W-101 B2), still admitted

SET @app_user_id = 4;    -- cashier1 is logged in
INSERT INTO payments (invoice_id, amount, method) VALUES
 (1, 3000.00, 'Cash'),    -- invoice 1 becomes Partial
 (1, 3140.00, 'Card'),    -- invoice 1 becomes Paid
 (2, 2000.00, 'GCash');   -- invoice 2 becomes Partial


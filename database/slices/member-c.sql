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
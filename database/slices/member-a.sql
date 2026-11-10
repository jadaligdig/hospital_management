-- member a: patients, appointments, medical_records

CREATE TABLE patients (
    patient_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    birth_date    DATE NOT NULL,
    gender        CHAR(1) NOT NULL,
    phone         VARCHAR(20),
    address       VARCHAR(150),
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_patient_gender CHECK (gender IN ('M','F')),
    CONSTRAINT chk_patient_birth  CHECK (birth_date >= '1900-01-01'),
    CONSTRAINT chk_patient_phone  CHECK (phone IS NULL OR phone REGEXP '^[0-9+() -]{7,20}$')
);

CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id     INT NOT NULL,
    doctor_id      INT NOT NULL,
    appt_datetime  DATETIME NOT NULL,
    status         ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    reason         VARCHAR(200) NOT NULL,
    CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_appt_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)
);
CREATE INDEX idx_appt_doctor_time ON appointments (doctor_id, appt_datetime);

CREATE TABLE medical_records (
    record_id      INT AUTO_INCREMENT PRIMARY KEY,
    patient_id     INT NOT NULL,
    doctor_id      INT NOT NULL,
    appointment_id INT NULL,
    admission_id   INT NULL,
    diagnosis      VARCHAR(255) NOT NULL,
    notes          TEXT,
    recorded_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_record_source CHECK (appointment_id IS NOT NULL OR admission_id IS NOT NULL),
    CONSTRAINT fk_rec_patient FOREIGN KEY (patient_id)     REFERENCES patients(patient_id),
    CONSTRAINT fk_rec_doctor  FOREIGN KEY (doctor_id)      REFERENCES doctors(doctor_id),
    CONSTRAINT fk_rec_appt    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    CONSTRAINT fk_rec_adm     FOREIGN KEY (admission_id)   REFERENCES admissions(admission_id)
);

INSERT INTO patients (first_name, last_name, birth_date, gender, phone, address) VALUES
 ('Maria',  'Lopez',    '1990-03-14', 'F', '0918-555-0101', 'Cebu City'),
 ('Pedro',  'Ramos',    '1985-07-22', 'M', '0918-555-0102', 'Mandaue City'),
 ('Ana',    'Bautista', '2015-11-02', 'F', '0918-555-0103', 'Lapu-Lapu City'),
 ('Carlos', 'Tan',      '1962-01-30', 'M', '0918-555-0104', 'Cebu City'),
 ('Elena',  'Cruz',     '1978-09-09', 'F', '0918-555-0105', 'Talisay City'),
 ('Jose',   'Navarro',  '2001-05-18', 'M', '0918-555-0106', 'Cebu City'),
 ('Lorna',  'Aquino',   '1955-12-25', 'F', '0918-555-0107', 'Consolacion'),
 ('Mark',   'Soriano',  '1999-04-04', 'M', '0918-555-0108', 'Minglanilla');   -- never visits

INSERT INTO appointments (patient_id, doctor_id, appt_datetime, status, reason) VALUES
 (1, 3, '2026-10-12 09:00:00', 'Scheduled', 'Chest pain'),               -- 1
 (3, 2, '2026-10-12 10:00:00', 'Scheduled', 'Fever and cough'),          -- 2
 (7, 4, '2026-10-13 14:00:00', 'Scheduled', 'Diabetes follow-up'),       -- 3
 (4, 3, '2026-10-13 09:30:00', 'Scheduled', 'Hypertension check'),       -- 4
 (5, 5, '2026-10-14 11:00:00', 'Scheduled', 'Abdominal pain'),           -- 5
 (6, 1, '2026-10-20 15:00:00', 'Scheduled', 'Ankle injury'),             -- 6
 (1, 3, '2026-10-21 09:00:00', 'Scheduled', 'Post-discharge follow-up'), -- 7
 (2, 4, '2026-10-18 10:00:00', 'Cancelled', 'General check-up');         -- 8

INSERT INTO medical_records (patient_id, doctor_id, appointment_id, diagnosis, notes) VALUES
 (1, 3, 1, 'Suspected angina',         'ECG ordered, patient to be admitted for monitoring'),  -- record 1
 (3, 2, 2, 'Acute bronchitis',         'Antibiotic prescribed'),                                -- record 2
 (7, 4, 3, 'Type 2 diabetes mellitus', 'Continue metformin'),                                   -- record 3
 (5, 5, 5, 'Acute appendicitis',       'Admit for appendectomy');                               -- record 4


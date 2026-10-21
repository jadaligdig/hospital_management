-- =====================================================================
--  HOSPITAL MANAGEMENT SYSTEM  (DBMS only)
--  Target: MySQL 8.0+   (also runs on MariaDB 10.5+)
--  Run:    mysql -u root -p < hospital_management.sql
--
--  PART 1  Schema ............ 16 tables, PK/FK, validation (CHECK, UNIQUE, ENUM)
--  PART 2  Automation ........ triggers + stored procedures (the "major feature")
--  PART 3  Master data ....... departments, doctors, patients, rooms, beds, medicines, tests
--  PART 4  Workflows ......... SQL commands run in hospital order (creates the transactions)
--  PART 5  Join reports ...... INNER, LEFT, RIGHT, FULL OUTER (via UNION), aggregates
--  PART 6  Edge-case tests ... statements that SHOULD fail (uncomment one at a time)
--
--  MAJOR FEATURE: Inpatient flow with automatic bed control and automatic billing
--    admit    -> bed becomes Occupied (blocked if bed is taken / patient already admitted)
--    prescribe-> stock is checked, expired medicine is blocked, price is snapshotted,
--                stock is deducted, low stock shows up in v_stock_alerts
--    discharge-> bed becomes Available, invoice is generated (nights x room rate
--                + lab tests + medicines) inside one transaction
--    pay      -> invoice moves Unpaid -> Partial -> Paid, overpayment is blocked
-- =====================================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db CHARACTER SET utf8mb4;
USE hospital_db;

-- =====================================================================
-- PART 1: SCHEMA
-- =====================================================================

-- 1. departments
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name     VARCHAR(60) NOT NULL UNIQUE,
    location      VARCHAR(60)
);

-- 2. doctors  (a doctor belongs to one department)
CREATE TABLE doctors (
    doctor_id      INT AUTO_INCREMENT PRIMARY KEY,
    department_id  INT NOT NULL,
    first_name     VARCHAR(50) NOT NULL,
    last_name      VARCHAR(50) NOT NULL,
    specialization VARCHAR(80) NOT NULL,
    phone          VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT chk_doctor_phone CHECK (phone REGEXP '^[0-9+() -]{7,20}$'),
    CONSTRAINT fk_doctor_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);

-- 3. patients
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

-- 4. appointments  (outpatient visit: patient + doctor + time)
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

-- 5. rooms  (a room may belong to a department's ward, or be unassigned)
CREATE TABLE rooms (
    room_id       INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NULL,
    room_no       VARCHAR(10) NOT NULL UNIQUE,
    room_type     ENUM('Ward','Private','ICU') NOT NULL,
    daily_rate    DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_room_rate CHECK (daily_rate > 0),
    CONSTRAINT fk_room_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 6. beds
CREATE TABLE beds (
    bed_id  INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    bed_no  VARCHAR(5) NOT NULL,
    status  ENUM('Available','Occupied','Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT uq_bed UNIQUE (room_id, bed_no),
    CONSTRAINT fk_bed_room FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

-- 7. admissions  (inpatient stay: patient + attending doctor + bed)
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

-- 8. medical_records  (a consultation note or a ward-round note)
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

-- 9. medicines  (pharmacy stock)
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

-- 10. prescriptions  (one row = one medicine ordered on a medical record)
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

-- 11. lab_tests  (catalog with price)
CREATE TABLE lab_tests (
    test_id   INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(80) NOT NULL UNIQUE,
    price     DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_test_price CHECK (price >= 0)
);

-- 12. lab_orders  (a test ordered on a medical record)
CREATE TABLE lab_orders (
    lab_order_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id    INT NOT NULL,
    test_id      INT NOT NULL,
    ordered_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('Ordered','Completed') NOT NULL DEFAULT 'Ordered',
    result_text  VARCHAR(255),
    CONSTRAINT fk_lab_record FOREIGN KEY (record_id) REFERENCES medical_records(record_id),
    CONSTRAINT fk_lab_test   FOREIGN KEY (test_id)   REFERENCES lab_tests(test_id)
);

-- 13. invoices  (exactly one per admission; created automatically on discharge)
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

-- 14. payments  (many payments per invoice)
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    method     ENUM('Cash','Card','GCash','Insurance') NOT NULL,
    paid_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pay_amount CHECK (amount > 0),
    CONSTRAINT fk_pay_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- 15. users  (system accounts; a Doctor account must point to a real doctor)
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(40) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,          -- the app should store a bcrypt hash
    role          ENUM('Admin','Doctor','Nurse','Cashier','Pharmacist') NOT NULL,
    doctor_id     INT NULL UNIQUE,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_doctor CHECK (role <> 'Doctor' OR doctor_id IS NOT NULL),
    CONSTRAINT fk_user_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- 16. audit_log  (written by triggers/procedures; performed_by comes from @app_user_id,
--                 which the application sets after login:  SET @app_user_id = <user_id>;)
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

-- =====================================================================
-- PART 2: AUTOMATION (triggers, procedures, view)
-- =====================================================================
DELIMITER $$

-- Rule 1: a doctor cannot have two active appointments less than 30 minutes apart
CREATE TRIGGER trg_appt_no_overlap
BEFORE INSERT ON appointments FOR EACH ROW
BEGIN
    IF NEW.status <> 'Cancelled' AND EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.doctor_id = NEW.doctor_id
          AND a.status <> 'Cancelled'
          AND ABS(TIMESTAMPDIFF(MINUTE, a.appt_datetime, NEW.appt_datetime)) < 30
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Doctor already has an appointment within 30 minutes of this time';
    END IF;
END$$

-- Rule 2: admit only to an Available bed, and never admit someone who is already admitted
CREATE TRIGGER trg_admission_before_insert
BEFORE INSERT ON admissions FOR EACH ROW
BEGIN
    DECLARE v_bed_status VARCHAR(20);
    SELECT status INTO v_bed_status FROM beds WHERE bed_id = NEW.bed_id;
    IF v_bed_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is not available';
    END IF;
    IF EXISTS (SELECT 1 FROM admissions
               WHERE patient_id = NEW.patient_id AND status = 'Admitted') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already admitted';
    END IF;
END$$

-- Rule 3: admitting a patient marks the bed Occupied
CREATE TRIGGER trg_admission_after_insert
AFTER INSERT ON admissions FOR EACH ROW
BEGIN
    UPDATE beds SET status = 'Occupied' WHERE bed_id = NEW.bed_id;
    INSERT INTO audit_log (event_type, table_name, record_id, details, performed_by)
    VALUES ('ADMIT', 'admissions', NEW.admission_id,
            CONCAT('Patient ', NEW.patient_id, ' admitted to bed ', NEW.bed_id), @app_user_id);
END$$

-- Rule 4: discharging a patient frees the bed
CREATE TRIGGER trg_admission_after_update
AFTER UPDATE ON admissions FOR EACH ROW
BEGIN
    IF OLD.status = 'Admitted' AND NEW.status = 'Discharged' THEN
        UPDATE beds SET status = 'Available' WHERE bed_id = NEW.bed_id;
        INSERT INTO audit_log (event_type, table_name, record_id, details, performed_by)
        VALUES ('DISCHARGE', 'admissions', NEW.admission_id,
                CONCAT('Patient ', NEW.patient_id, ' discharged, bed ', NEW.bed_id, ' freed'), @app_user_id);
    END IF;
END$$

-- Rule 5: prescribing checks expiry and stock, and snapshots the current price
CREATE TRIGGER trg_rx_before_insert
BEFORE INSERT ON prescriptions FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    DECLARE v_expiry DATE;
    DECLARE v_price DECIMAL(10,2);
    SELECT stock_qty, expiry_date, unit_price
      INTO v_stock, v_expiry, v_price
      FROM medicines WHERE medicine_id = NEW.medicine_id;
    IF v_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicine is expired';
    ELSEIF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient medicine stock';
    END IF;
    SET NEW.unit_price = v_price;
END$$

-- Rule 6: a saved prescription deducts the stock, and logs an alert if it hits the reorder level
CREATE TRIGGER trg_rx_after_insert
AFTER INSERT ON prescriptions FOR EACH ROW
BEGIN
    DECLARE v_stock   INT;
    DECLARE v_reorder INT;
    UPDATE medicines SET stock_qty = stock_qty - NEW.quantity
    WHERE medicine_id = NEW.medicine_id;
    SELECT stock_qty, reorder_level INTO v_stock, v_reorder
      FROM medicines WHERE medicine_id = NEW.medicine_id;
    IF v_stock <= v_reorder THEN
        INSERT INTO audit_log (event_type, table_name, record_id, details, performed_by)
        VALUES ('LOW_STOCK', 'medicines', NEW.medicine_id,
                CONCAT('Stock is ', v_stock, ' (reorder level ', v_reorder, ')'), @app_user_id);
    END IF;
END$$

-- Rule 7: a payment cannot be larger than the remaining balance
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payments FOR EACH ROW
BEGIN
    DECLARE v_balance DECIMAL(12,2);
    SELECT total_amount - amount_paid INTO v_balance
      FROM invoices WHERE invoice_id = NEW.invoice_id;
    IF NEW.amount > v_balance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds the remaining balance';
    END IF;
END$$

-- Rule 8: after a payment, recompute amount_paid and move the invoice status
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payments FOR EACH ROW
BEGIN
    DECLARE v_paid  DECIMAL(12,2);
    DECLARE v_total DECIMAL(12,2);
    SELECT SUM(amount) INTO v_paid FROM payments WHERE invoice_id = NEW.invoice_id;
    SELECT total_amount INTO v_total FROM invoices WHERE invoice_id = NEW.invoice_id;
    UPDATE invoices
       SET amount_paid = v_paid,
           status = IF(v_paid >= v_total, 'Paid', 'Partial')
     WHERE invoice_id = NEW.invoice_id;
    INSERT INTO audit_log (event_type, table_name, record_id, details, performed_by)
    VALUES ('PAYMENT', 'payments', NEW.payment_id,
            CONCAT(NEW.amount, ' paid by ', NEW.method, ' on invoice ', NEW.invoice_id), @app_user_id);
END$$

-- Procedure: build the invoice of one admission
--   room charge = nights x daily rate (minimum 1 night)
--   lab charge  = sum of lab test prices ordered under that admission
--   medicine    = sum of quantity x snapshot price under that admission
CREATE PROCEDURE sp_generate_invoice(IN p_admission_id INT)
BEGIN
    DECLARE v_nights INT;
    DECLARE v_rate   DECIMAL(10,2);
    DECLARE v_room   DECIMAL(12,2);
    DECLARE v_lab    DECIMAL(12,2);
    DECLARE v_med    DECIMAL(12,2);

    SELECT GREATEST(1, DATEDIFF(a.discharge_date, a.admit_date)), r.daily_rate
      INTO v_nights, v_rate
      FROM admissions a
      JOIN beds  b ON b.bed_id  = a.bed_id
      JOIN rooms r ON r.room_id = b.room_id
     WHERE a.admission_id = p_admission_id;
    SET v_room = v_nights * v_rate;

    SELECT COALESCE(SUM(t.price), 0) INTO v_lab
      FROM lab_orders lo
      JOIN medical_records mr ON mr.record_id = lo.record_id
      JOIN lab_tests t        ON t.test_id    = lo.test_id
     WHERE mr.admission_id = p_admission_id;

    SELECT COALESCE(SUM(p.quantity * p.unit_price), 0) INTO v_med
      FROM prescriptions p
      JOIN medical_records mr ON mr.record_id = p.record_id
     WHERE mr.admission_id = p_admission_id;

    INSERT INTO invoices (admission_id, room_charge, lab_charge, medicine_charge)
    VALUES (p_admission_id, v_room, v_lab, v_med);

    INSERT INTO audit_log (event_type, table_name, record_id, details, performed_by)
    VALUES ('INVOICE', 'invoices', LAST_INSERT_ID(),
            CONCAT('Invoice for admission ', p_admission_id, ' total ', v_room + v_lab + v_med),
            @app_user_id);
END$$

-- Procedure: discharge = update admission + free bed (trigger) + create invoice, all or nothing
CREATE PROCEDURE sp_discharge_patient(IN p_admission_id INT, IN p_discharge DATETIME)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status INTO v_status FROM admissions WHERE admission_id = p_admission_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission not found';
    ELSEIF v_status = 'Discharged' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already discharged';
    END IF;

    START TRANSACTION;
        UPDATE admissions
           SET status = 'Discharged',
               discharge_date = COALESCE(p_discharge, NOW())
         WHERE admission_id = p_admission_id;
        CALL sp_generate_invoice(p_admission_id);
    COMMIT;
END$$

DELIMITER ;

-- Alert view: medicines that are at/below reorder level, expired, or expiring within 90 days
CREATE VIEW v_stock_alerts AS
SELECT medicine_id, medicine_name, stock_qty, reorder_level, expiry_date,
       CASE
           WHEN expiry_date < CURDATE()                          THEN 'EXPIRED'
           WHEN stock_qty <= reorder_level                       THEN 'LOW STOCK'
           WHEN expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY) THEN 'EXPIRING SOON'
       END AS alert
FROM medicines
WHERE expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
   OR stock_qty <= reorder_level;

-- =====================================================================
-- PART 3: MASTER DATA
-- =====================================================================
INSERT INTO departments (dept_name, location) VALUES
 ('Emergency',        'Ground Floor'),
 ('Pediatrics',       '2nd Floor'),
 ('Internal Medicine','3rd Floor'),
 ('Surgery',          '4th Floor'),
 ('Radiology',        'Basement');          -- has no ward room (used by the FULL OUTER demo)

INSERT INTO doctors (department_id, first_name, last_name, specialization, phone) VALUES
 (1, 'Marco',  'Reyes',       'Emergency Medicine', '0917-123-0001'),
 (2, 'Liza',   'Santos',      'Pediatrician',       '0917-123-0002'),
 (3, 'Ramon',  'Dela Cruz',   'Cardiologist',       '0917-123-0003'),
 (3, 'Ana',    'Villanueva',  'Internist',          '0917-123-0004'),
 (4, 'Jose',   'Garcia',      'General Surgeon',    '0917-123-0005'),
 (5, 'Carla',  'Mendoza',     'Radiologist',        '0917-123-0006');

-- demo accounts only: SHA2 is for the demo, a real app should hash passwords with bcrypt
INSERT INTO users (username, password_hash, role, doctor_id) VALUES
 ('admin',        SHA2('admin123', 256),  'Admin',      NULL),   -- user 1
 ('dr.delacruz',  SHA2('doctor123', 256), 'Doctor',     3),      -- user 2
 ('dr.garcia',    SHA2('doctor123', 256), 'Doctor',     5),      -- user 3
 ('cashier1',     SHA2('cashier123', 256),'Cashier',    NULL),   -- user 4
 ('pharmacist1',  SHA2('pharma123', 256), 'Pharmacist', NULL);   -- user 5

INSERT INTO patients (first_name, last_name, birth_date, gender, phone, address) VALUES
 ('Maria',  'Lopez',    '1990-03-14', 'F', '0918-555-0101', 'Cebu City'),
 ('Pedro',  'Ramos',    '1985-07-22', 'M', '0918-555-0102', 'Mandaue City'),
 ('Ana',    'Bautista', '2015-11-02', 'F', '0918-555-0103', 'Lapu-Lapu City'),
 ('Carlos', 'Tan',      '1962-01-30', 'M', '0918-555-0104', 'Cebu City'),
 ('Elena',  'Cruz',     '1978-09-09', 'F', '0918-555-0105', 'Talisay City'),
 ('Jose',   'Navarro',  '2001-05-18', 'M', '0918-555-0106', 'Cebu City'),
 ('Lorna',  'Aquino',   '1955-12-25', 'F', '0918-555-0107', 'Consolacion'),
 ('Mark',   'Soriano',  '1999-04-04', 'M', '0918-555-0108', 'Minglanilla');   -- never visits

-- rooms: 4 belong to a department ward, G-001 is unassigned (FULL OUTER demo)
INSERT INTO rooms (department_id, room_no, room_type, daily_rate) VALUES
 (3,    'W-101',  'Ward',    1500.00),
 (4,    'P-201',  'Private', 3500.00),
 (1,    'ICU-1',  'ICU',     8000.00),
 (2,    'PED-1',  'Ward',    1500.00),
 (NULL, 'G-001',  'Ward',    1200.00);

INSERT INTO beds (room_id, bed_no, status) VALUES
 (1,'B1','Available'), (1,'B2','Available'),   -- bed 1, 2
 (2,'B1','Available'),                          -- bed 3
 (3,'B1','Available'), (3,'B2','Available'),   -- bed 4, 5
 (4,'B1','Available'),                          -- bed 6
 (5,'B1','Available'), (5,'B2','Maintenance');  -- bed 7, 8

INSERT INTO medicines (medicine_name, unit_price, stock_qty, reorder_level, expiry_date) VALUES
 ('Paracetamol 500mg', 2.50, 500, 100, '2028-03-31'),
 ('Amoxicillin 500mg', 8.00, 200,  50, '2027-08-31'),
 ('Metformin 500mg',   4.00, 300,  80, '2027-12-31'),
 ('Aspirin 80mg',      3.00, 150,  50, '2027-05-31'),
 ('Amlodipine 5mg',    6.00,  60,  40, '2027-09-30'),
 ('Ibuprofen 400mg',   5.00, 100,  30, '2026-06-30'),   -- already expired
 ('Losartan 50mg',     7.50,  80,  30, '2028-01-31');   -- never prescribed (LEFT JOIN demo)

INSERT INTO lab_tests (test_name, price) VALUES
 ('Complete Blood Count', 350.00),
 ('Urinalysis',           150.00),
 ('ECG',                  600.00),
 ('Troponin I',           900.00),
 ('Chest X-ray',          800.00);                       -- never ordered (LEFT JOIN demo)

-- =====================================================================
-- PART 4: WORKFLOWS  (run in this order; ids rely on a fresh database)
-- =====================================================================

-- ---------------------------------------------------------------------
-- WORKFLOW 1: Outpatient appointment
--   book -> (doctor overlap rule fires) -> consult -> record -> mark Completed
-- ---------------------------------------------------------------------
INSERT INTO appointments (patient_id, doctor_id, appt_datetime, status, reason) VALUES
 (1, 3, '2026-10-12 09:00:00', 'Scheduled', 'Chest pain'),               -- 1
 (3, 2, '2026-10-12 10:00:00', 'Scheduled', 'Fever and cough'),          -- 2
 (7, 4, '2026-10-13 14:00:00', 'Scheduled', 'Diabetes follow-up'),       -- 3
 (4, 3, '2026-10-13 09:30:00', 'Scheduled', 'Hypertension check'),       -- 4
 (5, 5, '2026-10-14 11:00:00', 'Scheduled', 'Abdominal pain'),           -- 5
 (6, 1, '2026-10-20 15:00:00', 'Scheduled', 'Ankle injury'),             -- 6
 (1, 3, '2026-10-21 09:00:00', 'Scheduled', 'Post-discharge follow-up'), -- 7
 (2, 4, '2026-10-18 10:00:00', 'Cancelled', 'General check-up');         -- 8

-- the consultations happen: write the medical record, then complete the appointment
INSERT INTO medical_records (patient_id, doctor_id, appointment_id, diagnosis, notes) VALUES
 (1, 3, 1, 'Suspected angina',         'ECG ordered, patient to be admitted for monitoring'),  -- record 1
 (3, 2, 2, 'Acute bronchitis',         'Antibiotic prescribed'),                                -- record 2
 (7, 4, 3, 'Type 2 diabetes mellitus', 'Continue metformin'),                                   -- record 3
 (5, 5, 5, 'Acute appendicitis',       'Admit for appendectomy');                               -- record 4

UPDATE appointments SET status = 'Completed' WHERE appointment_id IN (1,2,3,4,5);
-- note: appointment 4 is Completed but has NO medical record yet (the LEFT JOIN report finds it)

-- ---------------------------------------------------------------------
-- WORKFLOW 2: Outpatient treatment
--   prescribe (stock check, price snapshot, stock deduction)
-- ---------------------------------------------------------------------
INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage) VALUES
 (2, 2, 21, '1 capsule 3x a day for 7 days'),
 (2, 1, 10, '1 tablet every 6 hours if fever'),
 (3, 3, 60, '1 tablet twice a day');

-- ---------------------------------------------------------------------
-- WORKFLOW 3: Admission (inpatient)
--   admit -> bed turns Occupied automatically
--   (the app sets @app_user_id after login so the audit log knows who acted)
-- ---------------------------------------------------------------------
SET @app_user_id = 2;    -- dr.delacruz is logged in
INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, reason) VALUES
 (1, 3, 1, '2026-10-12 12:00:00', 'Suspected cardiac event'),    -- admission 1 (W-101 B1)
 (5, 5, 3, '2026-10-14 13:00:00', 'Appendicitis, for surgery'),  -- admission 2 (P-201 B1)
 (4, 3, 2, '2026-10-16 08:00:00', 'Hypertensive urgency');       -- admission 3 (W-101 B2), still admitted

-- ward-round records, medicines and lab tests during the stay
INSERT INTO medical_records (patient_id, doctor_id, admission_id, diagnosis, notes) VALUES
 (1, 3, 1, 'Unstable angina',     'Daily ward round, medication started'),   -- record 5
 (5, 5, 2, 'Post-appendectomy',   'Recovering well'),                         -- record 6
 (4, 3, 3, 'Hypertensive urgency','BP monitoring, oral medication');          -- record 7

INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage) VALUES
 (5, 4, 30, '1 tablet daily'),                  -- Aspirin
 (5, 1, 20, '1 tablet every 6 hours if pain'),  -- Paracetamol
 (6, 1, 30, '2 tablets every 6 hours'),
 (7, 5, 30, '1 tablet daily');                  -- Amlodipine: stock 60 -> 30 triggers LOW STOCK

INSERT INTO lab_orders (record_id, test_id, status, result_text) VALUES
 (5, 3, 'Completed', 'ST depression noted'),
 (5, 4, 'Completed', 'Mildly elevated'),
 (6, 1, 'Completed', 'WBC normal'),
 (7, 1, 'Ordered',   NULL);

-- ---------------------------------------------------------------------
-- WORKFLOW 4: Discharge + automatic billing
--   one CALL = admission updated + bed freed + invoice created (one transaction)
-- ---------------------------------------------------------------------
CALL sp_discharge_patient(1, '2026-10-15 10:00:00');   -- 3 nights x 1500 + labs + medicines
CALL sp_discharge_patient(2, '2026-10-16 09:00:00');   -- 2 nights x 3500 + labs + medicines

-- ---------------------------------------------------------------------
-- WORKFLOW 5: Payment
--   invoice goes Unpaid -> Partial -> Paid automatically
-- ---------------------------------------------------------------------
SET @app_user_id = 4;    -- cashier1 is logged in
INSERT INTO payments (invoice_id, amount, method) VALUES
 (1, 3000.00, 'Cash'),    -- invoice 1 becomes Partial
 (1, 3140.00, 'Card'),    -- invoice 1 becomes Paid
 (2, 2000.00, 'GCash');   -- invoice 2 becomes Partial

-- =====================================================================
-- PART 5: REPORTS (SQL joins and aggregates)
-- =====================================================================

-- R1. INNER JOIN: full appointment schedule (4 tables)
SELECT a.appointment_id,
       a.appt_datetime,
       CONCAT(p.first_name, ' ', p.last_name)        AS patient,
       CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor,
       dep.dept_name,
       a.status
FROM appointments a
INNER JOIN patients    p   ON p.patient_id     = a.patient_id
INNER JOIN doctors     d   ON d.doctor_id      = a.doctor_id
INNER JOIN departments dep ON dep.department_id = d.department_id
ORDER BY a.appt_datetime;

-- R2. LEFT JOIN: every patient with their number of Completed appointments (zero included)
SELECT p.patient_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient,
       COUNT(a.appointment_id)                AS completed_visits
FROM patients p
LEFT JOIN appointments a
       ON a.patient_id = p.patient_id AND a.status = 'Completed'
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY completed_visits DESC;

-- R3. LEFT JOIN (anti-join): Completed appointments that still have no medical record
SELECT a.appointment_id, a.appt_datetime, a.reason
FROM appointments a
LEFT JOIN medical_records mr ON mr.appointment_id = a.appointment_id
WHERE a.status = 'Completed' AND mr.record_id IS NULL;

-- R4. LEFT JOIN (anti-join): medicines and lab tests that were never used
SELECT 'Medicine' AS item_type, m.medicine_name AS item
FROM medicines m
LEFT JOIN prescriptions rx ON rx.medicine_id = m.medicine_id
WHERE rx.prescription_id IS NULL
UNION ALL
SELECT 'Lab test', t.test_name
FROM lab_tests t
LEFT JOIN lab_orders lo ON lo.test_id = t.test_id
WHERE lo.lab_order_id IS NULL;

-- R5. RIGHT JOIN: bed occupancy board (every bed, with its current patient if any)
SELECT r.room_no,
       b.bed_no,
       b.status AS bed_status,
       CONCAT(p.first_name, ' ', p.last_name) AS current_patient
FROM admissions a
RIGHT JOIN beds b  ON b.bed_id = a.bed_id AND a.status = 'Admitted'
INNER JOIN rooms r ON r.room_id = b.room_id
LEFT  JOIN patients p ON p.patient_id = a.patient_id
ORDER BY r.room_no, b.bed_no;

-- R6. FULL OUTER JOIN (MySQL has none, so LEFT JOIN UNION RIGHT JOIN):
--     departments without a ward room AND rooms without a department
SELECT d.dept_name, r.room_no, r.room_type
FROM departments d
LEFT JOIN rooms r ON r.department_id = d.department_id
UNION
SELECT d.dept_name, r.room_no, r.room_type
FROM departments d
RIGHT JOIN rooms r ON r.department_id = d.department_id;

-- R7. INNER JOIN + aggregate: billing summary with balance
SELECT i.invoice_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient,
       i.room_charge, i.lab_charge, i.medicine_charge,
       i.total_amount, i.amount_paid,
       (i.total_amount - i.amount_paid)       AS balance,
       i.status
FROM invoices i
INNER JOIN admissions a ON a.admission_id = i.admission_id
INNER JOIN patients   p ON p.patient_id   = a.patient_id;

-- R8. GROUP BY + HAVING: doctors with at least 1 completed consultation, busiest first
SELECT CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor,
       dep.dept_name,
       COUNT(*) AS completed_appointments
FROM doctors d
INNER JOIN departments dep ON dep.department_id = d.department_id
INNER JOIN appointments a  ON a.doctor_id = d.doctor_id AND a.status = 'Completed'
GROUP BY d.doctor_id, d.first_name, d.last_name, dep.dept_name
HAVING COUNT(*) >= 1
ORDER BY completed_appointments DESC;

-- R9. Subquery: patients currently admitted, with bed and nights so far
SELECT CONCAT(p.first_name, ' ', p.last_name) AS patient,
       r.room_no, b.bed_no, a.admit_date,
       GREATEST(1, DATEDIFF(NOW(), a.admit_date)) AS nights_so_far
FROM admissions a
INNER JOIN patients p ON p.patient_id = a.patient_id
INNER JOIN beds b     ON b.bed_id     = a.bed_id
INNER JOIN rooms r    ON r.room_id    = b.room_id
WHERE a.status = 'Admitted';

-- R10. View: pharmacy alerts (LOW STOCK / EXPIRED / EXPIRING SOON)
SELECT * FROM v_stock_alerts;

-- R11. LEFT JOIN: audit trail with the user who acted (NULL = no user was logged in)
SELECT l.logged_at, l.event_type, l.details,
       COALESCE(u.username, '(system)') AS performed_by,
       u.role
FROM audit_log l
LEFT JOIN users u ON u.user_id = l.performed_by
ORDER BY l.log_id;

-- R12. LEFT JOIN: accounts and the doctor they belong to (staff accounts have no doctor)
SELECT u.username, u.role, CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS linked_doctor
FROM users u
LEFT JOIN doctors d ON d.doctor_id = u.doctor_id;

-- =====================================================================
-- PART 6: EDGE-CASE TESTS (each one should be REJECTED; uncomment one at a time)
-- =====================================================================

-- T1. Doctor 3 is booked at 09:00 on 2026-10-21; 09:15 is inside the 30-minute window
-- INSERT INTO appointments (patient_id, doctor_id, appt_datetime, reason)
-- VALUES (2, 3, '2026-10-21 09:15:00', 'Overlap test');          -- ERROR: Doctor already has an appointment...

-- T2. Bed 2 is occupied by Carlos Tan
-- INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, reason)
-- VALUES (2, 4, 2, NOW(), 'Occupied bed test');                  -- ERROR: Bed is not available

-- T3. Carlos Tan is already admitted (bed 5 is free)
-- INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, reason)
-- VALUES (4, 3, 5, NOW(), 'Double admission test');              -- ERROR: Patient is already admitted

-- T4. Ibuprofen is expired
-- INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage)
-- VALUES (7, 6, 5, '1 tablet');                                  -- ERROR: Medicine is expired

-- T5. Not enough stock (Amlodipine has 30 left)
-- INSERT INTO prescriptions (record_id, medicine_id, quantity, dosage)
-- VALUES (7, 5, 999, '1 tablet');                                -- ERROR: Insufficient medicine stock

-- T6. Overpayment (invoice 1 is already fully paid)
-- INSERT INTO payments (invoice_id, amount, method) VALUES (1, 1.00, 'Cash');   -- ERROR: Payment exceeds...

-- T7. Discharging twice
-- CALL sp_discharge_patient(1, NOW());                           -- ERROR: Patient is already discharged

-- T8. Discharge before admission (CHECK constraint, and the whole transaction rolls back)
-- CALL sp_discharge_patient(3, '2026-10-01 00:00:00');           -- ERROR: CONSTRAINT chk_discharge_after_admit failed

-- T9. Field validation
-- INSERT INTO patients (first_name,last_name,birth_date,gender) VALUES ('X','Y','2000-01-01','Z');  -- ERROR: gender CHECK
-- INSERT INTO doctors (department_id,first_name,last_name,specialization,phone)
-- VALUES (1,'A','B','C','abc');                                  -- ERROR: phone CHECK

-- T11. A Doctor account must be linked to a doctor
-- INSERT INTO users (username, password_hash, role) VALUES ('dr.fake', 'x', 'Doctor');   -- ERROR: chk_user_doctor failed

-- T10. Foreign key
-- INSERT INTO appointments (patient_id, doctor_id, appt_datetime, reason)
-- VALUES (999, 1, '2026-11-01 08:00:00', 'No such patient');     -- ERROR: foreign key constraint fails

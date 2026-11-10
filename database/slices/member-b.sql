-- Member B: 
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name     VARCHAR(60) NOT NULL UNIQUE,
    location      VARCHAR(60)
);

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


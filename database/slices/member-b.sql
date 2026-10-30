-- Member B: your tables

-- Departments has no table dependency.
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(60) NOT NULL UNIQUE,
    location VARCHAR(60)
);

-- Doctors needs the departments table first.
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(80) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT chk_doctor_phone CHECK (phone REGEXP '^[0-9+() -]{7,20}$'),
    CONSTRAINT fk_doctor_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);

-- Users needs the doctors table first.
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(40) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Admin','Doctor','Nurse','Cashier','Pharmacist') NOT NULL,
    doctor_id INT NULL UNIQUE,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_doctor CHECK (role <> 'Doctor' OR doctor_id IS NOT NULL),
    CONSTRAINT fk_user_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
);

-- Member A: patients, appointments, medical_records

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE
);

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    appointment_date DATETIME,
    status VARCHAR(50),
    CONSTRAINT fk_appointments_patient 
        FOREIGN KEY (patient_id) 
        REFERENCES patients(patient_id) 
        ON DELETE CASCADE
);

CREATE TABLE medical_records (
    record_id INT PRIMARY KEY,
    patient_id INT,
    diagnosis TEXT,
    treatment TEXT,
    record_date DATE,
    CONSTRAINT fk_medical_records_patient 
        FOREIGN KEY (patient_id) 
        REFERENCES patients(patient_id) 
        ON DELETE CASCADE
);

INSERT INTO patients (patient_id, first_name, last_name, date_of_birth) VALUES
(1, 'Danilo', 'Magbanua', '1985-06-15'),
(2, 'Marisol', 'Dimalanta', '1990-11-22'),
(3, 'Bayani', 'Catacutan', '1978-03-04');

INSERT INTO appointments (appointment_id, patient_id, appointment_date, status) VALUES
(101, 1, '2026-11-10 09:30:00', 'Scheduled'),
(102, 2, '2026-11-10 10:15:00', 'Confirmed'),
(103, 3, '2026-11-11 14:00:00', 'Completed');

INSERT INTO medical_records (record_id, patient_id, diagnosis, treatment, record_date) VALUES
(1001, 3, 'Hypertension', 'Prescribed Lisinopril 10mg daily and advised on low-sodium diet.', '2026-10-15'),
(1002, 1, 'Acute Bronchitis', 'Prescribed Amoxicillin and cough suppressant. Rest for 5 days.', '2026-10-20');
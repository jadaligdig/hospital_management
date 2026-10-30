-- Member Joanna: patients, appointments, medical_records

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
-- Member F: lab_tests, lab_orders
CREATE TABLE lab_tests (
    test_id   INT NOT NULL AUTO_INCREMENT,
    test_name VARCHAR(80) NOT NULL,
    price     DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (test_id),
    UNIQUE KEY uq_test_name (test_name),
    CONSTRAINT chk_test_price CHECK (price >= 0)
);

-- needs medical_records and lab_test to exist first
CREATE TABLE lab_orders (
    lab_order_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id    INT NOT NULL,
    test_id      INT NOT NULL,
    ordered_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('Ordered', 'Completed') NOT NULL DEFAULT 'Ordered',
    result_text  VARCHAR(255),
    CONSTRAINT fk_lab_record FOREIGN KEY (record_id) REFERENCES medical_records(record_id),
    CONSTRAINT fk_lab_test FOREIGN KEY (test_id) REFERENCES lab_tests(test_id)
);

INSERT INTO lab_tests (test_name, price) VALUES
 ('Complete Blood Count', 350.00),
 ('Urinalysis',           150.00),
 ('ECG',                  600.00),
 ('Troponin I',           900.00),
 ('Chest X-ray',          800.00);

INSERT INTO lab_orders (record_id, test_id, status, result_text) VALUES
 (5, 3, 'Completed', 'ST depression noted'),
 (5, 4, 'Completed', 'Mildly elevated'),
 (6, 1, 'Completed', 'WBC normal'),
 (7, 1, 'Ordered',   NULL);

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



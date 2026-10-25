-- Member F: lab_tests, lab_orders
CREATE TABLE lab_tests (
    test_id   INT NOT NULL AUTO_INCREMENT,
    test_name VARCHAR(80) NOT NULL,
    price     DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (test_id),
    UNIQUE KEY uq_test_name (test_name),
    CONSTRAINT chk_test_price CHECK (price >= 0)
);
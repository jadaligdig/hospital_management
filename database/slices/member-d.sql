-- Member D: rooms and beds tables

CREATE TABLE rooms (
    room_id       INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NULL,
    room_no       VARCHAR(10) NOT NULL UNIQUE,
    room_type     ENUM('Ward','Private','ICU') NOT NULL,
    daily_rate    DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_room_rate CHECK (daily_rate > 0),
    CONSTRAINT fk_room_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE beds (
    bed_id  INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    bed_no  VARCHAR(5) NOT NULL,
    status  ENUM('Available','Occupied','Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT uq_bed UNIQUE (room_id, bed_no),
    CONSTRAINT fk_bed_room FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

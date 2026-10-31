-- Member D: Join reports R5 and R6

-- R5. RIGHT JOIN: bed occupancy board
SELECT r.room_no,
       b.bed_no,
       b.status AS bed_status,
       CONCAT(p.first_name, ' ', p.last_name) AS current_patient
FROM admissions a
RIGHT JOIN beds b
    ON b.bed_id = a.bed_id AND a.status = 'Admitted'
INNER JOIN rooms r
    ON r.room_id = b.room_id
LEFT JOIN patients p
    ON p.patient_id = a.patient_id
ORDER BY r.room_no, b.bed_no;


-- R6. FULL OUTER JOIN: departments and rooms
-- MySQL uses LEFT JOIN UNION RIGHT JOIN for this.
SELECT d.dept_name, r.room_no, r.room_type
FROM departments d
LEFT JOIN rooms r
    ON r.department_id = d.department_id

UNION

SELECT d.dept_name, r.room_no, r.room_type
FROM departments d
RIGHT JOIN rooms r
    ON r.department_id = d.department_id;
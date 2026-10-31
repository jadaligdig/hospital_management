-- R12: Accounts and Linked Doctor
-- JOIN type: LEFT JOIN
-- Purpose: Display all user accounts and their linked doctor information.

USE scratch_b;

SELECT
    u.user_id,
    u.username,
    u.role,
    u.is_active,
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization
FROM users AS u
LEFT JOIN doctors AS d
    ON u.doctor_id = d.doctor_id
ORDER BY u.user_id;
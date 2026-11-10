-- R11: Audit Trail Join Report (LEFT JOIN)
-- Description: Retrieves system audit logs alongside the username of the user who performed the action.

SELECT 
    al.log_id,
    al.event_type,
    al.table_name,
    al.record_id,
    al.details,
    al.logged_at,
    COALESCE(u.username, 'System / Unknown') AS performed_by_user,
    u.role AS user_role
FROM audit_log al
LEFT JOIN users u ON al.performed_by = u.user_id
ORDER BY al.logged_at DESC;
# Member E - medicines, prescriptions, audit_log

## 1. Table Explanations & Purpose
* **medicines**: This table manages the hospital's drug inventory catalog. It tracks available stock quantities, unit pricing, reorder thresholds, and expiration dates to ensure the pharmacy maintains adequate medical supplies.
* **prescriptions**: This table bridges patient medical consultations with the pharmacy. It records specific medication details, dosages, and quantities prescribed during a medical visit (record_id).
* **audit_log**: This table acts as a security and compliance tracker. It logs critical system events, data modifications, and user actions to maintain accountability and trace system activity.

## 2. Table Relationships (ER Diagram Connections)
* **medicines to prescriptions**: Connected via medicine_id in a One-to-Many relationship. Each medicine can be prescribed multiple times across different prescriptions.
* **prescriptions to medical_records**: Connected via record_id in a Many-to-One relationship, linking prescriptions directly to a patient's medical consultation record.
* **audit_log to users**: Connected via performed_by (linking to user_id) in a Many-to-One relationship, tracking which user performed specific actions logged in the system.
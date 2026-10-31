# Member E - Medicines, Prescriptions, and Audit Log Slice


## Table Breakdown & Purpose

### 1. medicines
* *Purpose:* Acts as the central inventory catalog for all pharmaceutical products available in the hospital.
* *Key Fields:* 
  * medicine_id (Primary Key)
  * medicine_name: The commercial or generic name of the drug.
  * unit_price: Cost per unit of the medicine.
  * stock_qty: Current quantity available in inventory.
  * reorder_level: Threshold that triggers restocking alerts.
  * expiry_date: Expiration date of the batch to maintain safety compliance.

### 2. prescriptions
* *Purpose:* Serves as the transactional bridging table connecting patient consultations (medical_records) to specific pharmaceutical products (medicines). It records what medication was prescribed, how much, and at what dosage.
* *Key Fields:*
  * prescription_id (Primary Key)
  * record_id (Foreign Key referencing medical_records): Links the prescription to a specific patient diagnosis or visit.
  * medicine_id (Foreign Key referencing medicines): Identifies the drug being prescribed.
  * quantity: Number of units prescribed.
  * dosage: Instructions for administration (e.g., frequency and amount).
  * unit_price: Captured price at the time of prescription.
  * prescribed_at: Timestamp of when the prescription was issued.

### 3. audit_log
* *Purpose:* Maintains a secure system-wide tracking mechanism for compliance, security monitoring, and troubleshooting. It logs critical events, changes, or actions performed across database tables.
* *Key Fields:*
  * log_id (Primary Key)
  * event_type: The category of action (e.g., INSERT, UPDATE, DELETE, LOGIN).
  * table_name: The database table affected by the action.
  * record_id: The primary key of the specific record impacted.
  * details: Descriptive text or JSON payload containing context about the change.
  * performed_by (Foreign Key referencing users): Identifies which user account executed the action.
  * logged_at: Exact timestamp of when the event occurred.

---

## Table Relationships & Connections
* **prescriptions to medicines:** Connected via a Many-to-One relationship (medicine_id). Multiple prescriptions can reference the same catalogued medicine.
* **prescriptions to medical_records:** Connected via a Many-to-One relationship (record_id), associating prescriptions directly with a patient's medical consultation record.
* **audit_log to users:** Connected via a Many-to-One relationship (performed_by linking to users.user_id), allowing administrators to trace system events back to the responsible user account using a *LEFT JOIN* (ensuring system logs are captured even if a user reference is unassigned or system-automated).
# Member A - patients, appointments, medical_records

## What I built

- `patients`, `appointments` and `medical_records` tables with sample data
  (8 patients, 8 appointments, 4 medical records).
- A join report: Appointment schedule (INNER JOIN).
- Patients screens to add, edit and delete patients (`/patients`).

## Rules on the tables

`patients`:

- `first_name`, `last_name`, `birth_date` and `gender` are NOT NULL.
- `gender` can only be M or F (`chk_patient_gender`).
- `birth_date` can't be before 1900-01-01 (`chk_patient_birth`).
- `phone` is optional, but if it is filled in it must be 7 to 20 digits or phone
  symbols (`chk_patient_phone`).

`appointments`:

- `patient_id` and `doctor_id` must exist (`fk_appt_patient`, `fk_appt_doctor`).
- `status` can only be Scheduled, Completed or Cancelled.

`medical_records`:

- A record must come from an appointment or an admission (`chk_record_source`).
- It points to a patient, a doctor, and optionally an appointment and an
  admission (`fk_rec_patient`, `fk_rec_doctor`, `fk_rec_appt`, `fk_rec_adm`).

## Sample data

Patient 8 (Mark Soriano) never has an appointment. This gives a "never visits"
patient so reports about patients without visits always have something to show.

## Join report: Appointment schedule (INNER JOIN)

Page: `/appointment-schedule`

```sql
SELECT a.appointment_id, p.first_name, p.last_name, d.last_name,
       a.appt_datetime, a.status, a.reason
FROM appointments a
INNER JOIN patients p ON a.patient_id = p.patient_id
INNER JOIN doctors d ON a.doctor_id = d.doctor_id
ORDER BY a.appt_datetime;
```

Why an INNER JOIN: a schedule only makes sense for appointments that have both a
patient and a doctor. An INNER JOIN keeps only the rows that match on both sides,
which is exactly that. Because `patient_id` and `doctor_id` are NOT NULL with
foreign keys, every appointment has a match, so no appointment is lost. Patients
without any appointment (like Mark Soriano) don't appear, because they have nothing
to schedule.

The page shows all 8 appointments, sorted by date and time.

## Screens and the rules they trigger

| Screen | What it does | Rules it can trigger |
|---|---|---|
| Create (`patients add`) | Adds a patient | NOT NULL on the name, birth date and gender, `chk_patient_gender`, `chk_patient_birth`, `chk_patient_phone` |
| Edit (`patients edit <id>`) | Changes a patient's details | The same three CHECK rules |
| Delete (`patients delete <id>`) | Deletes one patient | Foreign keys from `appointments`, `medical_records` and `admissions`: a patient with visits can't be deleted |

Each route uses try/except. If the database refuses a change, the Patients page
shows a red message instead of crashing.

## What I tested

| # | What I tried | What happened |
|---|---|---|
| 1 | Edited a patient's birth date to 1800-01-01 | Rejected. `Check constraint 'chk_patient_birth' is violated.` (error 3819) |
| 2 | Edited a patient's phone to letters | Rejected. `Check constraint 'chk_patient_phone' is violated.` (error 3819) |
| 3 | Deleted a patient who has admissions | Rejected. `Cannot delete or update a parent row: a foreign key constraint fails (... admissions, CONSTRAINT 'fk_adm_patient' ...)` (error 1451) |
| 4 | Deleted Mark Soriano (no visits) | It worked. "Patient deleted." |

`patients` has no UNIQUE key, so there is no 1062 error for this slice.

## What the errors mean

- **3819 (Check constraint is violated):** the new value breaks a CHECK rule. A
  birth date before 1900 breaks `chk_patient_birth`, and a phone with letters
  breaks `chk_patient_phone`.
- **1451 (Cannot delete or update a parent row):** another table points to this
  patient. The `admissions` table has a foreign key to `patients`, so MySQL
  refuses to delete a patient who still has admissions. This protects the visit
  history from pointing to a patient that no longer exists.

## Files

- `database/slices/member-a.sql`
- `docs/slices/member-a.md`
- Routes in `app/app.py`, templates `patients.html` and `edit_patient.html`
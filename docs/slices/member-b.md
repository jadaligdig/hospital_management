# Member B - Tables and Report Notes

## 1. Departments Table

**Purpose:** Stores the hospital departments.

**Columns and rules:**
- `department_id` – Primary key and automatically increases.
- `dept_name` – Department name; required and must be unique.
- `location` – Location of the department.

**Connection:** One department can have many doctors.

## 2. Doctors Table

**Purpose:** Stores the information about hospital doctors.

**Columns and rules:**
- `doctor_id` – Primary key and automatically increases.
- `department_id` – Required foreign key connected to the departments table.
- `first_name` – Doctor's first name; required.
- `last_name` – Doctor's last name; required.
- `specialization` – Doctor's specialization; required.
- `phone` – Required and unique phone number. It must follow the allowed phone-number format.

**Connection:** Each doctor belongs to a department. A doctor can also be linked to a user account.

## 3. Users Table

**Purpose:** Stores the accounts used to access the hospital system.

**Columns and rules:**
- `user_id` – Primary key and automatically increases.
- `username` – Required and unique.
- `password_hash` – Required field for the stored password hash.
- `role` – Required account role, such as Admin, Doctor, Nurse, Cashier, or Pharmacist.
- `doctor_id` – Optional unique foreign key connected to the doctors table.
- `is_active` – Shows whether the account is active. Default value is 1.
- `created_at` – Records the date and time the account was created.

**Connection:** A user account can be linked to a doctor. If the role is Doctor, a doctor ID is required. Other roles can have a NULL doctor ID.

## 4. Tests Performed

- Checked the `scratch_b` database.
- Checked that the `departments`, `doctors`, and `users` tables existed.
- Tested the sample department, doctor, and user records.
- Ran the R12 report using LEFT JOIN.
- Confirmed that both the Doctor and Nurse accounts appeared.
- Temporarily changed LEFT JOIN to INNER JOIN.
- Confirmed that the Nurse account disappeared because it had no linked doctor.

**Error codes:** I will only list error codes that I actually encountered during these project tests. I will not include unrelated errors.

## 5. R12 Report – Accounts and Linked Doctor

**JOIN type: LEFT JOIN**

I used LEFT JOIN because I wanted to display all user accounts, even if they do not have a linked doctor.

When I changed it to INNER JOIN, the Nurse account disappeared because its doctor ID was NULL and it had no matching doctor record.

This shows why LEFT JOIN is needed for this report.
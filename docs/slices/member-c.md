Member C — Billing Summary

Member: KC Cimafranca
Assigned Tables: Admissions, Invoices, Payments
Feature: Transactions
Query Report: R7 Billing Summary

1. Table Descriptions

Admissions

The admissions table stores information about patients admitted to the hospital. It includes the patient ID, doctor ID, bed ID, admission date, discharge date, status, and reason for admission.

Invoices

The invoices table stores billing information for each admission. It includes room charges, laboratory charges, medicine charges, total amount, amount paid, and payment status.

Payments

The payments table stores payment transactions. It includes the payment ID, invoice ID, amount, payment method, and payment date.

2. Table Relationships

- Patients — Admissions: One patient can have many admissions.
- Doctors — Admissions: One doctor can handle many admissions.
- Beds — Admissions: One bed can be used for different admissions over time.
- Admissions — Invoices: Each admission can have only one invoice.
- Invoices — Payments: One invoice can have multiple payments.

3. R7 Billing Summary

The R7 Billing Summary uses an INNER JOIN between the invoices and payments tables. It displays invoice details together with their related payment records.

4. Test Results

The SQL query was tested using the separate "scratch_c" practice database.

- Three admissions were inserted successfully.
- Three invoices were inserted successfully.
- Three payment records were inserted successfully.
- The R7 Billing Summary returned three rows.
- Invoice 1 appeared twice because it had two payments.
- Invoice 2 appeared once because it had one payment.
- Invoice 3 did not appear because it had no matching payment.

5. Why INNER JOIN Is Used

INNER JOIN is used because the report should show invoices that have matching payment records. Invoices without payments are not displayed in this report.
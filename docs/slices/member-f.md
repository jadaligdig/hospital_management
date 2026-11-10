# Member F - lab_tests and lab_orders

## What I built

- `lab_tests` table: the list of lab tests and their prices.
- `lab_orders` table: which test was ordered for which medical record, with a status and a result.
- A report called "Lab tests never ordered".
- Screens to add, edit and delete lab tests (`/lab-tests`).

## Rules on the tables

`lab_tests`:

- `test_id` is the primary key and fills in by itself (AUTO_INCREMENT).
- `test_name` must be unique (`uq_test_name`).
- `price` can't be negative (`chk_test_price`).

`lab_orders`:

- `record_id` must exist in `medical_records` (`fk_lab_record`).
- `test_id` must exist in `lab_tests` (`fk_lab_test`).
- `status` can only be `Ordered` or `Completed`.

## Sample data

`database/slices/member-f.sql` creates both tables, adds 5 tests and 4 orders. Only
Complete Blood Count, ECG and Troponin I are ordered, so Urinalysis and
Chest X-ray are never ordered. That way the report always has something to show.

## Never-ordered report

Page: `/lab-tests-never-ordered`

```sql
SELECT lab_tests.test_name, lab_tests.price
FROM lab_tests
LEFT JOIN lab_orders
    ON lab_tests.test_id = lab_orders.test_id
WHERE lab_orders.lab_order_id IS NULL;
```

Result with the sample data: Urinalysis (150.00) and Chest X-ray (800.00).

Why it needs a LEFT JOIN: a normal INNER JOIN only keeps rows that have a match
on both sides. A test that was never ordered has no row in `lab_orders`, so an
INNER JOIN would throw it away, and that is exactly the row I want to find. A LEFT
JOIN keeps every test and fills the `lab_orders` columns with NULL when there is no
match. Then `WHERE lab_orders.lab_order_id IS NULL` keeps only the tests with no
orders.

## Screens and the rules they trigger

| Screen | What it does | Rules it can trigger |
|---|---|---|
| Create (`/lab-tests/add`) | Adds a new test | NOT NULL on name and price, UNIQUE `uq_test_name`, CHECK `chk_test_price` |
| Edit (`/lab-tests/edit/<id>`) | Changes the price of one test | CHECK `chk_test_price` (only the price can be edited) |
| Delete (`/lab-tests/delete/<id>`) | Deletes one test | Foreign key `fk_lab_test`: a test that has orders can't be deleted |

Each route uses try/except around the query. If the database rejects the change,
the page shows a red message instead of crashing.

## What I tested

I tried to break each rule on purpose, in MySQL Workbench 8.0 CE and in the app.

| # | What I tried | What happened |
|---|---|---|
| 1 | Added a normal test (Fasting Blood Sugar, 250.00) | It worked, `1 row(s) affected`. |
| 2 | Added "ECG" a second time | Rejected. `Error 1062: Duplicate entry 'ECG' for key 'lab_tests.uq_test_name'` |
| 3 | Added a test with price -5 | Rejected. `Error 3819: Check constraint 'chk_test_price' is violated.` |
| 4 | Deleted Complete Blood Count (it has orders) | Rejected. `Error 1451: Cannot delete or update a parent row: a foreign key constraint fails (... CONSTRAINT 'fk_lab_test' ...)` |
| 5 | Deleted Urinalysis (never ordered) | It worked. |

I also saw `Error 1366: Incorrect decimal value: '' for column 'price'` when I
pressed Add with the price box empty.

## What the errors mean

- **1062 (Duplicate entry):** the value already exists in a UNIQUE column. Test names
  must be unique, so MySQL refuses a second "ECG".
- **3819 (Check constraint is violated):** the row breaks a CHECK rule. A negative
  price breaks `chk_test_price`.
- **1451 (Cannot delete or update a parent row):** a foreign key protects the data.
  `lab_orders` points to the test, so the test can't be deleted until its orders
  are gone.
- **1452 (Cannot add or update a child row):** the opposite of 1451. I got this
  when my sample orders used `record_id` values that did not exist in
  `medical_records`.

## Files

- `database/slices/member-f.sql`
- `docs/slices/member-f.md`
- Routes in `app/app.py`, templates `lab_tests.html` and `edit_lab_test.html`
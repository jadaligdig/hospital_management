# Member F - lab_tests and lab_orders



## Member F: lab_tests constraint testing



## What I tested

I made the `lab_tests` table with three rules on it:



- `test_id` is the primary key and fills in by itself (AUTO_INCREMENT).

- `test_name` must be unique (key name `uq_test_name`).

- `price` can't be negative (`chk_test_price`).



To check that these rules really work, I ran three INSERT statements in MySQL Workbench 8.0 CE (schema `scratch_f`).



## Results



| # | What I tried | What happened |

|---|--------------|---------------|

| 1 | Added a normal row: `Fasting Blood Sugar`, price `250.00` | It worked. Workbench showed `1 row(s) affected`. |

| 2 | Added `Fasting Blood Sugar` a second time with price `300.00` | It was rejected. `Error Code: 1062. Duplicate entry 'Fasting Blood Sugar' for key 'lab_tests.uq_test_name' |

| 3 | Added `Lipid Profile` with price `-150.00` | It was rejected. `Error Code: 3819. Check constraint 'chk_test_price' is violated.` |



## What this shows

- The first insert shows that a valid test can be saved.

- Error 1062 shows the database itself stops two tests from having the same name. I don't need to rely on the app to catch it.

- Error 3819 shows the database refuses a negative price. It also tells me my MySQL is version 8.0.16 or newer, because older versions ignore CHECK rules.



## How I know my constraints work

I didn't just assume they work. I tried to break each rule on purpose, and MySQL blocked both bad rows with a clear error message.

# Member F: Lab tests and lab orders

## Never-ordered report

The report at "Lab tests never ordered" lists every test that has no row in
`lab_orders`. With the sample data, that is Urinalysis and Chest X-ray.

    SELECT t.test_name, t.price
    FROM lab_tests t
    LEFT JOIN lab_orders o ON o.test_id = t.test_id
    WHERE o.lab_order_id IS NULL;

(Replace this with the exact query from your app.py.)

It needs a LEFT JOIN because a normal (INNER) JOIN only keeps rows that have
a match on both sides. A test that was never ordered has no match in
`lab_orders`, so an INNER JOIN would drop it, which is exactly the row I want.
A LEFT JOIN keeps every row from `lab_tests` and fills the `lab_orders` columns
with NULL when there is no match. Then `WHERE o.lab_order_id IS NULL` keeps
only those unmatched tests.

## Screens and the database rules they trigger

| Screen | What it does | Rules it can trigger |
|---|---|---|
| Create (`lab-tests/add`) | INSERT a new test | NOT NULL on `test_name` and `price`; UNIQUE `uq_test_name` (no duplicate names); CHECK `chk_test_price` (price >= 0) |
| Edit (`/lab-tests/edit/<id>`) | UPDATE the price of one test | CHECK `chk_test_price` (price >= 0). Only the price can be edited, so the name rule doesn't apply. |
| Delete (`/lab-tests/delete/<id>`) | DELETE one test | Foreign key `fk_lab_test` from `lab_orders.test_id`: a test that has orders can't be deleted |

Each route uses try/except around the query. If the database rejects the
change, the user sees a readable message on the lab tests page instead of
a crash.

## Errors I saw

- **1062 (Duplicate entry):** I tried to add a test whose name already exists.
  The UNIQUE key `uq_test_name` blocks it, because two tests can't share a name.
- **3819 (Check constraint is violated):** I entered a negative price. The
  CHECK `chk_test_price` requires price >= 0, so MySQL rejects the row.
- **1451 (Cannot delete or update a parent row):** I tried to delete a test
  that already has rows in `lab_orders`. The foreign key `fk_lab_test` protects
  those orders from pointing at a test that no longer exists. A test with no
  orders, like Urinalysis, deletes fine.


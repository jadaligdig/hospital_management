# Member D - rooms and beds

## What I built

- `rooms` and `beds` tables with sample data (5 rooms, 8 beds).
- Two join reports: Bed board and Departments vs rooms.
- Beds screens to add, edit and delete beds (`/beds`).
- One rule of my own: an occupied bed cannot be deleted.

## Rules on the tables

`rooms`:

- `room_no` is NOT NULL and UNIQUE.
- `room_type` can only be Ward, Private or ICU.
- `daily_rate` can't be zero or negative (`chk_room_rate`).
- `department_id` can be NULL, so a room can exist without a department
  (`fk_room_dept` links it to `departments`).

`beds`:

- A bed number can only appear once in the same room (`uq_bed` on `room_id, bed_no`).
- `room_id` must exist in `rooms` (`fk_bed_room`).
- `status` can only be Available, Occupied or Maintenance (default Available).

## Join reports

### Bed board (RIGHT JOIN) - `bed-board`

```sql
SELECT r.room_no, r.room_type, b.bed_no, b.status
FROM beds b
RIGHT JOIN rooms r ON b.room_id = r.room_id
ORDER BY r.room_no, b.bed_no;
```

A RIGHT JOIN keeps every row from the table on the right (`rooms`), even when it
has no match on the left (`beds`). So a room with no beds still appears on the
board, with NULL in the bed columns. With the sample data every room has beds,
so the result shows all 8 beds.

### Departments vs rooms (FULL OUTER JOIN via UNION) - `/departments-rooms`

```sql
SELECT d.dept_name, r.room_no
FROM departments d
LEFT JOIN rooms r ON r.department_id = d.department_id
UNION
SELECT d.dept_name, r.room_no
FROM departments d
RIGHT JOIN rooms r ON r.department_id = d.department_id;
```

MySQL has no FULL OUTER JOIN, so I combine a LEFT JOIN and a RIGHT JOIN with UNION.
The LEFT JOIN finds departments with no rooms and the RIGHT JOIN finds rooms with
no department. UNION removes the duplicate matched rows.

Result with the sample data:

- Radiology has no room (shown as None).
- Room G-001 has no department (shown as None).
- The other rows match normally.

## Screens and the rules they trigger

| Screen | What it does | Rules it can trigger |
|---|---|---|
| Create (`beds add`) | Adds a bed to a room | UNIQUE `uq_bed` (same bed number twice in one room), foreign key `fk_bed_room` (room must exist) |
| Edit (`beds edit <id>`) | Changes the status of one bed | ENUM on `status` (only Available, Occupied or Maintenance) |
| Delete (`beds delete <id>`) | Deletes one bed | My rule: an Occupied bed can't be deleted. Also the foreign key `fk_adm_bed` from `admissions` if an admission uses the bed. |

Each route uses try/except, so a database error shows as a red message on the
Beds page instead of crashing.

## What I tested

| # | What I tried | What happened |
|---|---|---|
| 1 | Added a bed to room 1 with a new bed number | It worked, "Bed added." |
| 2 | Added room ID 1 with bed B1 (already exists) | Rejected. `Duplicate entry '1-B1' for key 'beds.uq_bed'` (error 1062) |
| 3 | Added a bed with room ID 99 (no such room) | Rejected. `Cannot add or update a child row: a foreign key constraint fails (... CONSTRAINT 'fk_bed_room' ...)` (error 1452) |
| 4 | Deleted bed B2 in room 1 (status Occupied) | Blocked by my rule. "Cannot delete an occupied bed." |
| 5 | Deleted a test bed that was Available | It worked, "Bed deleted." |

I also tried to drop the `beds` table in Workbench and got error 3730, because
`admissions` has a foreign key (`fk_adm_bed`) pointing to it.

## What the errors mean

- **1062 (Duplicate entry):** the value already exists in a UNIQUE key. Bed B1 can't
  exist twice in the same room.
- **1452 (Cannot add or update a child row):** the foreign key needs a parent. A bed
  must belong to a room that exists.
- **3730 (Cannot drop table referenced by a foreign key):** another table depends on
  this one, so MySQL won't drop it until the child table is dropped first.

## Files

- `database/slices/member-d.sql`
- `docs/slices/member-d.md`
- Routes in `app/app.py`, templates `beds.html` and `edit_bed.html`
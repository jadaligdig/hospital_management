\# Member F - lab\_tests and lab\_orders



\## Member F: lab\_tests constraint testing



\## What I tested

I made the `lab\_tests` table with three rules on it:



\- `test\_id` is the primary key and fills in by itself (AUTO\_INCREMENT).

\- `test\_name` must be unique (key name `uq\_test\_name`).

\- `price` can't be negative (`chk\_test\_price`).



To check that these rules really work, I ran three INSERT statements in MySQL Workbench 8.0 CE (schema `scratch\_f`).



\## Results



| # | What I tried | What happened |

|---|--------------|---------------|

| 1 | Added a normal row: `Fasting Blood Sugar`, price `250.00` | It worked. Workbench showed `1 row(s) affected`. |

| 2 | Added `Fasting Blood Sugar` a second time with price `300.00` | It was rejected. `Error Code: 1062. Duplicate entry 'Fasting Blood Sugar' for key 'lab\_tests.uq\_test\_name' |

| 3 | Added `Lipid Profile` with price `-150.00` | It was rejected. `Error Code: 3819. Check constraint 'chk\_test\_price' is violated.` |



\## What this shows

\- The first insert shows that a valid test can be saved.

\- Error 1062 shows the database itself stops two tests from having the same name. I don't need to rely on the app to catch it.

\- Error 3819 shows the database refuses a negative price. It also tells me my MySQL is version 8.0.16 or newer, because older versions ignore CHECK rules.



\## How I know my constraints work

I didn't just assume they work. I tried to break each rule on purpose, and MySQL blocked both bad rows with a clear error message.


# \# Hospital Management - DBMS Final Project

# 

# A hospital database with patients, appointments, medical records, inpatient admissions with bed control, pharmacy stock, lab tests and billing.

# 

# Track: \*\*Merged Track\*\* (one project for DBMS 1 and SIA). This README covers the \*\*DBMS 1\*\* part. The SIA part (Node.js backend and frontend) will be added later.

# 

# \## Group roster and ownership matrix

# 

# | Member | GitHub username | Tables | Complete resource (screen or endpoints, built later) | Join report and type | Feature role |

# |---|---|---|---|---|---|

# | A - \[Joanna Joyce Caromayan] | \[Joyce\_Moyce05] | patients, appointments, medical\_records | Patients | R1 Appointment schedule (INNER JOIN) | Core |

# | B - \[Jerry Mae Callao] | \[jerrydevvv] | departments, doctors, users | Doctors | R12 Accounts and linked doctor (LEFT JOIN) | Master data |

# | C - \[KC Cimafranca] | \[camy\_ky] | admissions, invoices, payments | Payments | R7 Billing summary (INNER JOIN) | Transactions |

# | D - \[Mary Aljane Cadano] | \[marie-chan] | rooms, beds | Beds | R5 Bed board (RIGHT JOIN), R6 Departments vs rooms (FULL OUTER JOIN via UNION) | Unique feature (rules) |

# | E - \[Erich Cabugnason] | \[erichs333] | medicines, prescriptions, audit\_log | Medicines | R11 Audit trail (LEFT JOIN) | Unique feature (workflow, alerts), Audit |

# | F - \[Josh Agne Daligdig] | \[jadaligdig] | lab\_tests, lab\_orders | Lab tests | R4 Never-used medicines and tests (LEFT JOIN) | Reports |

# 

# \## Major feature: inpatient flow with automatic bed control and billing

# 

# \- \*\*Admit:\*\* the bed becomes Occupied. It is blocked if the bed is taken or the patient is already admitted.

# \- \*\*Prescribe:\*\* stock is checked, expired medicine is blocked, the price is saved, stock is deducted, and low stock shows in the `v\_stock\_alerts` view.

# \- \*\*Discharge:\*\* the bed becomes Available, and the invoice is created (nights x room rate + lab tests + medicines) in one transaction.

# \- \*\*Pay:\*\* the invoice moves Unpaid, then Partial, then Paid. Overpayment is blocked.

# \- \*\*Audit:\*\* admissions, discharges, invoices, payments and low-stock alerts are written to `audit\_log` with the user who did them.

# 

# \## Database overview (16 tables)

# 

# | Area | Tables |

# |---|---|

# | Master data | departments, doctors, patients, rooms, beds, medicines, lab\_tests, users |

# | Outpatient | appointments, medical\_records, prescriptions, lab\_orders |

# | Inpatient and billing | admissions, invoices, payments |

# | Audit | audit\_log |

# 

# The script also has 8 triggers, 2 stored procedures (`sp\_generate\_invoice`, `sp\_discharge\_patient`) and 1 view (`v\_stock\_alerts`). Validation uses PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, ENUM and CHECK constraints.

# 

# \## ER diagram

# 

# !\[ER diagram](docs/er-diagram.png)

# 

# \## How to run

# 

# 1\. Install MySQL Server 8.0.16 or newer and MySQL Workbench.

# 2\. Open MySQL Workbench and connect to your local MySQL.

# 3\. Choose \*\*File > Open SQL Script\*\* and select `database/hospital\_management.sql`.

# 4\. Click the first lightning bolt to run the whole script. It recreates the `hospital\_db` database from scratch, so you can run it again to reset the data.

# 5\. Refresh the Schemas list. You should see `hospital\_db` with 16 tables.

# 6\. The script shows the join reports as it runs. Part 6 at the bottom has edge-case tests that should fail, which you can run one at a time.

# 

# Do not put real passwords in this repository.

# 

# \## Git workflow

# 

# \- Nobody commits directly to `main`. Each member works on their own branch, such as `feature/name-topic`.

# \- Commit messages start with a prefix: `feat:`, `fix:`, `docs:` or `refactor:`.

# \- Every change goes through a pull request reviewed by a different member.

# \- Pull requests are merged with \*\*Create a merge commit\*\* (no squash).

# \- Commits are made from our own computers, not in the GitHub web editor.


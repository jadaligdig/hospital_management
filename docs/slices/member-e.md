\# Member E: Medicines



\## What I built

\- `/medicines` page to list, add, edit and delete medicines

\- Link to Medicines added to `index.html`

\- Audit logging for medicine changes, shown on `/audit-trail`



\## Tests



| Test | What I did | Result |

|------|-----------|--------|

| 1062 | Added "Aspirin 80mg" again | `Duplicate entry 'Aspirin 80mg' for key 'medicines.medicine\_name'` |

| 3819 | Added a medicine with price -5 | `Check constraint 'chk\_med\_price' is violated.` |

| 1451 | Deleted a medicine used in a prescription | Foreign key error on `fk\_rx\_medicine` |

| Unique feature | Edited Amoxicillin to stock 2 (reorder level 50) | LOW STOCK label on `/medicines` and a new `LOW\_STOCK` row on `/audit-trail` |



Screenshots: `screenshots/1062.jpeg`, `3819.jpeg`, `1451.jpeg`, `low-stock.jpeg`, `audit-trail.jpeg`



\## Sample data

\- Amlodipine 5mg starts below its reorder level (30 vs 40)

\- One audit row has `performed\_by` NULL, so the LEFT JOIN shows an empty User cell



\## Notes

\- The add form needs every field filled in. Empty values fail at the MySQL type check before the constraint tests apply.



# 🧱 1. **Data Access Operators**
These operators retrieve rows from tables or indexes.

- **Table Scan** — Reads the entire heap or clustered index.
- **Index Scan** — Reads an entire nonclustered index.
- **Index Seek** — Navigates the B‑tree to retrieve specific rows.
- **RID Lookup** — Fetches heap rows using a row identifier.
- **Key Lookup** — Fetches clustered index rows using a key.
- **Columnstore Scan** — Reads columnstore segments.
- **Columnstore Index Seek** — Predicate pushdown into columnstore.

---

# 🔍 2. **Join Operators**
These implement physical join algorithms.

- **Nested Loops Join** — Repeated seeks/scans for each outer row.
- **Merge Join** — Efficient join on sorted inputs.
- **Hash Join** — Builds a hash table; may spill to TempDB.
- **Adaptive Join** — Chooses between Nested Loops and Hash at runtime.
- **Nested Loops (Left/Right/Full)** — Variants for outer joins.

---

# 📊 3. **Aggregation & Grouping Operators**
Used for GROUP BY, DISTINCT, and aggregates.

- **Stream Aggregate** — Requires sorted input; low memory.
- **Hash Aggregate** — Uses a hash table; may spill.
- **Window Aggregate** — Used for OVER() functions.

---

# 🔄 4. **Sort & Windowing Operators**
These handle ORDER BY, window functions, ranking, and analytic queries.

- **Sort** — Sorts rows; high spill risk.
- **Top** — Returns the first N rows.
- **Top N Sort** — Sorts only enough rows to satisfy TOP.
- **Window Spool** — Supports window functions.
- **Segment** — Groups rows into segments for windowing.

---

# 🧮 5. **Filtering & Predicate Operators**
These apply WHERE, HAVING, and ON conditions.

- **Filter** — Applies a predicate.
- **Compute Scalar** — Computes expressions (e.g., `Price * Quantity`).
- **Bitmap Filter** — Used in parallel plans to reduce row flow.
- **Predicate Pushdown** — Not an operator, but a behavior inside scans.

---

# 🔁 6. **Spool Operators**
Spools store intermediate results—often to TempDB.

- **Table Spool** — Stores rows for reuse.
- **Index Spool** — Builds a temporary index.
- **Row Count Spool** — Stores row counts.
- **Eager Spool** — Materializes all rows immediately.
- **Lazy Spool** — Materializes rows on demand.

Spools are often signs of:
- Repeated subqueries  
- Nested loops inefficiencies  
- Missing indexes  

---

# 🔀 7. **Parallelism Operators**
These manage multi‑threaded execution.

- **Distribute Streams** — Splits rows across threads.
- **Repartition Streams** — Redistributes rows by hash or round‑robin.
- **Gather Streams** — Combines parallel streams into one.
- **Parallelism (Exchange)** — Generic operator for thread coordination.

---

# 📦 8. **Insert/Update/Delete Operators**
These modify data.

- **Insert**  
- **Update**  
- **Delete**  
- **Split** — Splits rows for update operations.
- **Sort (for DML)** — Used for index maintenance.
- **Clustered Index Update** — Updates clustered index keys.
- **Nonclustered Index Update** — Updates nonclustered index entries.

---

# 🧰 9. **Miscellaneous Operators**
These appear in specialized plans.

- **Concatenation** — UNION ALL.
- **Union** — Logical union (rare in physical plans).
- **Apply** — CROSS APPLY / OUTER APPLY.
- **Sequence** — Executes operators in order.
- **Assert** — Enforces constraints (e.g., CHECK constraints).
- **Foreign Key Check** — Validates FK constraints.
- **Table Valued Function** — Inline or multi‑statement TVF.
- **Remote Query** — Linked server operations.
- **Remote Scan** — Scans remote tables.

---

# 🎯 Summary Table (Perfect for Slides)

| Category | Operators |
|----------|-----------|
| Data Access | Table Scan, Index Scan, Index Seek, Key Lookup, Columnstore Scan |
| Joins | Nested Loops, Merge Join, Hash Join, Adaptive Join |
| Aggregation | Stream Aggregate, Hash Aggregate, Window Aggregate |
| Sorting & Windowing | Sort, Top, Top N Sort, Window Spool |
| Filtering | Filter, Compute Scalar, Bitmap Filter |
| Spools | Table Spool, Index Spool, Row Count Spool, Eager/Lazy Spool |
| Parallelism | Distribute Streams, Repartition Streams, Gather Streams |
| DML | Insert, Update, Delete, Split |
| Misc | Concatenation, Apply, Sequence, Assert, Remote Query |

---

# 🏁 Final Takeaway
**Operators are the physical building blocks of SQL Server’s execution plan.**  
They represent *how* SQL Server actually performs your query after the optimizer decides *what* the plan should be.


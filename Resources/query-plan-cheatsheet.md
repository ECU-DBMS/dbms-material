# SQL Server Query Plan Cheat Sheet for VS Code

A **query plan** shows the physical operations that the SQL Server Query Optimizer chose to run a T-SQL statement. Use it to understand how SQL Server reads, joins, sorts, filters, and returns data.

> [!IMPORTANT]
> A plan is evidence, not a verdict. A scan, hash join, sort, or parallel plan can be the correct choice. Measure the query, inspect the plan in context, change one thing, and measure again.

---

## 1. Before you start

You need:

- Visual Studio Code with the Microsoft **MSSQL** extension (`ms-mssql.mssql`)
- an open `.sql` file connected to SQL Server
- the correct database selected for the query
- permission to execute the statement
- `SHOWPLAN` permission on every database containing objects referenced by the statement

If the MSSQL extension or connection is not ready, follow [SQL Server 2025 in Docker Desktop with VS Code](vscode-sqlserver-container.md).

---

## 2. Estimated plan vs. actual plan

| Plan | Executes the statement? | Contains | Best used when |
|---|---:|---|---|
| **Estimated** | No | Optimizer estimates, chosen operators, estimated rows, and estimated costs | You need to inspect a plan without running an expensive or data-changing statement |
| **Actual** | Yes | The compiled plan plus runtime rows, execution counts, resource information, and runtime warnings | You need to compare estimates with what happened during execution |

An estimated plan cannot show actual rows or runtime warnings because the statement never runs.

> [!CAUTION]
> An actual plan **executes the statement**. An `INSERT`, `UPDATE`, `DELETE`, `MERGE`, or stored procedure can change data. Enabling the actual plan does not make a statement read-only. Test data-changing or expensive statements in a safe environment.

---

## 3. View a graphical plan in VS Code

### Display an estimated plan

1. Open a connected `.sql` editor.
2. Confirm the connection and database shown by the MSSQL extension.
3. Highlight the statement you want to inspect so the extension does not analyze other statements in the editor.
4. Select **Estimated Plan** (the flowchart icon beside **Run Query**) on the query toolbar.
5. Open the plan result.
6. Hover over or select an operator to inspect its details.

SQL Server compiles the statement but does not execute it.

### Display an actual plan

1. Open a connected `.sql` editor.
2. Highlight the statement you want to inspect.
3. Select **Enable Actual Plan** on the query toolbar.
4. Select **Run Query**.
5. Open the plan result after execution finishes.
6. Inspect the operator details, especially actual and estimated rows, execution counts, and warnings.

The statement executes and the results are returned along with runtime plan information.

---

## 4. T-SQL alternatives

The toolbar is usually the quickest method in VS Code. These T-SQL options return the plan as XML and are useful when a graphical command is unavailable or when plan XML must be saved or shared.

### Estimated plan with `SHOWPLAN_XML`

```sql
SET SHOWPLAN_XML ON;
GO

SELECT name, database_id
FROM sys.databases
WHERE database_id > 4;
GO

SET SHOWPLAN_XML OFF;
GO
```

`SHOWPLAN_XML` compiles the query and returns the estimated plan without executing the query.

> [!NOTE]
> While `SHOWPLAN_XML` is on, SQL Server returns plans instead of executing subsequent statements. Keep the `ON`, query, and `OFF` commands in separate batches as shown, and always turn the option off when finished.

### Actual plan with `STATISTICS XML`

```sql
SET STATISTICS XML ON;
GO

SELECT name, database_id
FROM sys.databases
WHERE database_id > 4;
GO

SET STATISTICS XML OFF;
GO
```

`STATISTICS XML` executes the query and returns runtime plan data.

| Need | VS Code toolbar | T-SQL |
|---|---|---|
| Plan without executing | **Estimated Plan** | `SET SHOWPLAN_XML ON` |
| Runtime rows and warnings | **Enable Actual Plan**, then **Run Query** | `SET STATISTICS XML ON` |

---

## 5. How to read the diagram

### Read the data flow

1. Start with the rightmost operators. These are commonly the first table or index access operations.
2. Follow the arrows from right to left and toward the top-left root.
3. Observe where rows are filtered, joined, sorted, aggregated, or looked up.
4. Finish at the leftmost `SELECT`, modification, or other root operator.

For an operator with two inputs, SQL Server processes both branches before passing their output to the next operator. Hover over or select each operator to inspect its properties.

### Understand the visual clues

| Visual clue | Meaning |
|---|---|
| **Operator icon** | The physical operation SQL Server selected |
| **Arrow direction** | The direction rows flow between operators |
| **Arrow thickness** | Relative row volume, not elapsed time |
| **Operator percentage** | Estimated cost relative to the displayed statement |
| **Statement percentage** | Estimated cost relative to other statements in the batch |
| **Warning icon** | A condition such as a spill or conversion that deserves inspection |

> [!WARNING]
> Cost percentages are optimizer estimates. They are not measured percentages of elapsed time, CPU time, or logical reads. Do not tune only the operator with the largest percentage.

---

## 6. Common operators

| Operator | What it does | When it can be appropriate | Investigate when |
|---|---|---|---|
| **Index Seek** | Navigates an index to a key or key range | A selective predicate can use the index key | It returns many rows, applies a large residual predicate, or triggers many lookups |
| **Index Scan / Table Scan** | Reads much or all of an index or heap | The table is small, many rows are needed, or scanning is cheaper than many random reads | It reads many rows but returns few, especially on a large object |
| **Key Lookup / RID Lookup** | Fetches columns missing from a nonclustered index | A small number of rows needs extra columns | A Nested Loops operator executes the lookup thousands of times |
| **Nested Loops** | For each row from one input, searches the other input | The outer input is small and the inner input is indexed | The outer input is much larger than estimated or the inner work repeats excessively |
| **Hash Match** | Builds a hash table to join or aggregate rows | Large, unsorted inputs need an equality join or aggregate | It spills to TempDB, receives a poor estimate, or needs an excessive memory grant |
| **Merge Join** | Joins two inputs ordered by the join keys | Both inputs are already ordered and many rows must be joined | Extra Sort operators are required or duplicate keys cause substantial work |
| **Sort** | Orders rows for `ORDER BY`, grouping, joins, or window functions | The requested ordering is not available from an index | It spills, sorts far more rows than expected, or dominates measured work |
| **Stream Aggregate** | Aggregates an ordered input | Input is already ordered by grouping keys | A preceding sort is expensive or too many rows reach the aggregate |
| **Hash Aggregate** | Groups rows in a hash table | Large, unordered input must be grouped | It spills or receives inaccurate row/group estimates |
| **Spool** | Stores intermediate rows, often for reuse | Reusing protected or expensive intermediate work is cheaper | A large spool writes to TempDB or hides repeated work caused by query shape |
| **Parallelism** | Distributes, repartitions, or gathers rows across worker threads | Enough work exists to benefit from multiple workers | Exchanges move highly skewed row sets or coordination cost exceeds the benefit |

The operator name alone does not prove a problem. Examine row counts, executions, warnings, predicates, object size, and measured performance.

See [Relational Database Operators](4_relational-db-operators.md) for a broader operator catalog.

---

## 7. What to inspect first

Use this order so that estimated costs do not distract from stronger evidence.

1. **Confirm correctness and scope.** Verify the query returns the intended result and identify the slow statement in a multi-statement batch.
2. **Compare rows.** In an actual plan, compare **Actual Number of Rows** with **Estimated Number of Rows** at important operators.
3. **Inspect warnings.** Select warning icons and read the properties for spills, implicit conversions, missing statistics, memory-grant issues, and other runtime conditions.
4. **Follow row flow.** Find thick arrows and places where row counts expand sharply or where many rows are later discarded.
5. **Find repeated work.** Check **Actual Number of Executions**, especially for lookups or scans below Nested Loops.
6. **Inspect access and processing choices in context.** Review scans, residual predicates, joins, sorts, spools, and parallel exchanges.
7. **Treat suggestions as hypotheses.** A missing-index suggestion considers one query and does not account for the full write, storage, and maintenance cost of another index.

### Estimated rows vs. actual rows

A large difference is called a **cardinality estimation error**. Because row estimates influence join type, join order, memory grants, parallelism, and index access, an error near the beginning of a plan can affect everything above it.

Compare counts using a ratio rather than only the absolute difference:

- estimated 1 row, actual 10,000 rows: a major underestimate;
- estimated 1,000,000 rows, actual 900,000 rows: usually much closer;
- actual rows multiplied by many executions: repeated work can be more important than one execution.

For more background, see [The Cardinality Estimator](3_cardinal-estimator.md).

---

## 8. Symptom-to-question guide

| Plan evidence | Questions to ask | Candidate response to test |
|---|---|---|
| Actual rows are far above or below estimated rows | Are statistics stale or missing? Is data skewed? Did a parameter influence compilation? Is the predicate difficult to estimate? | Test updated statistics, representative parameters, and a more sargable predicate in a safe environment |
| A scan reads many rows but returns few | Is the predicate selective? Can an existing index support it? Is a function or conversion applied to the indexed column? | Test a suitable index or rewrite the predicate so the column remains directly searchable |
| A lookup has a high execution count | Does the query need every selected column? Would including a small number of columns avoid repeated lookups? | Test selecting fewer columns or a carefully designed covering index |
| A Sort or Hash operator reports a spill | Was the memory grant based on a poor estimate? Are rows unusually wide? Could input order or row volume be reduced? | Correct the estimate first, then test query shape or indexing changes |
| The plan reports an implicit conversion | Do the parameter, variable, and column use matching data types and lengths? | Align data types and retest; conversions on the indexed column can prevent efficient access |
| Many rows are removed by a late Filter | Can a logically equivalent selective predicate be applied earlier? | Rewrite carefully and verify identical results, especially with outer joins |
| The join algorithm looks unexpected | Were input sizes estimated correctly? Are useful indexes and ordering available? | Investigate estimates and access paths before considering a query hint |

**Sargable** means a predicate is written so SQL Server can use an index search argument. For example:

```sql
-- More likely to support an index seek on OrderDate.
WHERE OrderDate >= '20260101'
  AND OrderDate <  '20260201';

-- Applying a function to the column can prevent an efficient seek.
WHERE YEAR(OrderDate) = 2026
  AND MONTH(OrderDate) = 1;
```

---

## 9. Use the plan: measure, change, compare

1. **Capture a baseline.**
   - Save the exact query and representative parameter values.
   - Confirm the result is correct.
   - Record duration, CPU time, and logical reads when available.
   - Capture the actual plan.
2. **Choose one evidence-backed issue.**
   - Prefer actual row mismatches, warnings, excessive reads, spills, or repeated work over estimated cost alone.
3. **Form one testable hypothesis.**
   - Example: “The repeated Key Lookup causes most reads because the query requests a column that is not in the nonclustered index.”
4. **Change one thing.**
   - Change a predicate, selected columns, index, statistics, or query structure in a test environment.
5. **Rerun under comparable conditions.**
   - Use the same parameters, database, data, and server conditions when possible.
6. **Verify correctness and compare.**
   - Confirm the intended result is unchanged.
   - Compare runtime metrics and the new actual plan.
7. **Keep only demonstrated improvements.**
   - Test changes outside production first and consider effects on other queries, writes, storage, and maintenance.

You can add measured I/O and CPU information to the Messages output:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT name, database_id
FROM sys.databases
WHERE database_id > 4;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

Run a query more than once only when doing so matches the behavior you intend to study. Cache state can change results; do not discard an inconvenient measurement without explaining why.

---

## 10. Practice: compare a scan and an indexed access path

This exercise creates temporary data, captures a baseline plan, adds an index, and reruns the same query. Run every block in the same connected editor session so the temporary table remains available. Use **Enable Actual Plan** before each query execution.

### Step 1: Create sample data

```sql
DROP TABLE IF EXISTS #OrderPlanDemo;

CREATE TABLE #OrderPlanDemo
(
    OrderID int NOT NULL,
    CustomerID int NOT NULL,
    OrderDate date NOT NULL,
    Amount decimal(10, 2) NOT NULL
);

WITH Numbers AS
(
    SELECT TOP (10000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
)
INSERT #OrderPlanDemo (OrderID, CustomerID, OrderDate, Amount)
SELECT
    n,
    CASE
        WHEN n <= 6000 THEN 1
        ELSE (n % 100) + 2
    END,
    DATEADD(day, n % 365, CONVERT(date, '20250101')),
    CONVERT(decimal(10, 2), (n % 50000) / 100.0)
FROM Numbers;
```

### Step 2: Capture the baseline actual plan

```sql
SELECT OrderID, OrderDate, Amount
FROM #OrderPlanDemo
WHERE CustomerID = 87;
```

Inspect:

- the table access operator;
- estimated rows versus actual rows;
- rows read versus rows returned;
- measured logical reads if `SET STATISTICS IO ON` is enabled.

### Step 3: Add an index and rerun the same query

```sql
CREATE INDEX IX_OrderPlanDemo_CustomerID
ON #OrderPlanDemo (CustomerID)
INCLUDE (OrderID, OrderDate, Amount);

SELECT OrderID, OrderDate, Amount
FROM #OrderPlanDemo
WHERE CustomerID = 87;
```

Compare the access operator, row estimates, row flow, and logical reads with the baseline. SQL Server may choose an Index Seek because the predicate is selective and the index contains the requested columns, but the optimizer is free to choose a scan when it estimates that scanning is cheaper.

### Step 4: Clean up

```sql
DROP TABLE IF EXISTS #OrderPlanDemo;
```

Do not conclude that every query needs another index. Indexes consume storage and add work to inserts, updates, deletes, statistics maintenance, and backups.

---

## 11. Common mistakes

- **Tuning only the highest cost percentage.** Cost is estimated and relative, not measured elapsed time.
- **Assuming every scan is bad.** Scanning can be optimal for small tables or queries that return much of a table.
- **Assuming every seek is good.** A seek that returns many rows or causes thousands of lookups can be expensive.
- **Assuming a hash join, sort, spool, or parallel plan is automatically wrong.** Each can be the best available operator.
- **Trusting a missing-index suggestion without testing.** It does not evaluate the complete workload or index maintenance cost.
- **Comparing different workloads.** Plans produced with different parameters, data, database options, or cache conditions are not a controlled comparison.
- **Running a data-changing statement for an actual plan without considering side effects.**
- **Forgetting to turn `SHOWPLAN_XML`, `STATISTICS XML`, `STATISTICS IO`, or `STATISTICS TIME` off.**
- **Changing several things at once.** You will not know which change affected the result.
- **Using a query hint as the first fix.** A forced join or index can hide the root cause and age poorly as data changes.

---

## 12. Troubleshooting

| Problem | Check |
|---|---|
| Plan buttons are missing | Confirm the Microsoft MSSQL extension is installed and enabled, then reopen the `.sql` editor |
| No connection or plan appears | Connect the editor, select the intended database, and confirm the status bar shows the connection |
| The wrong statement is analyzed | Highlight only the intended statement before requesting or running the plan |
| Permission error mentions Showplan | Request `SHOWPLAN` permission for every database containing referenced objects |
| Actual row properties are absent | You generated an estimated plan; enable the actual plan and execute the statement |
| Query returns XML plans instead of normal results | Run `SET SHOWPLAN_XML OFF` or `SET STATISTICS XML OFF` in the appropriate session |
| Plan differs between runs | Compare parameters, data changes, statistics, recompilation, database settings, and cache conditions |
| Plan is too large to understand at once | Find the slow statement, inspect warnings and row mismatches, then follow the largest row flows |

---

## 13. Quick reference

| If you need to... | Do this |
|---|---|
| Inspect a plan without running the statement | Use **Estimated Plan** or `SET SHOWPLAN_XML ON` |
| See actual rows, executions, and runtime warnings | Use **Enable Actual Plan**, then **Run Query**, or use `SET STATISTICS XML ON` |
| Explain a surprising operator choice | Compare estimated and actual rows, predicates, available indexes, and input ordering |
| Investigate a warning icon | Open the operator properties and read the warning details before changing the query |
| Evaluate a possible improvement | Record a baseline, change one thing, rerun, verify results, and compare measured metrics |
| Decide whether a scan or seek is better | Compare rows read, rows returned, executions, logical reads, and elapsed work in context |

---

## 14. Related course resources

- [SQL Server 2025 in Docker Desktop with VS Code](vscode-sqlserver-container.md)
- [The Cardinality Estimator](3_cardinal-estimator.md)
- [Relational Database Operators](4_relational-db-operators.md)
- [T-SQL Table Joins](1_join-types-cheatsheet.md)

Remember that a logical join such as `INNER JOIN` describes the requested result, while a physical operator such as Nested Loops, Hash Match, or Merge Join describes how SQL Server produces that result.

---

## 15. Microsoft references

- [MSSQL extension for Visual Studio Code](https://learn.microsoft.com/sql/tools/visual-studio-code-extensions/mssql/mssql-extension-visual-studio-code)
- [Display and save execution plans](https://learn.microsoft.com/sql/relational-databases/performance/display-and-save-execution-plans)
- [`SET SHOWPLAN_XML` (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/statements/set-showplan-xml-transact-sql)
- [`SET STATISTICS XML` (Transact-SQL)](https://learn.microsoft.com/sql/t-sql/statements/set-statistics-xml-transact-sql)
- [Showplan logical and physical operators reference](https://learn.microsoft.com/sql/relational-databases/showplan-logical-and-physical-operators-reference)

---

## Final takeaway

Start with an actual plan when it is safe to execute the query. Compare estimates with runtime rows, inspect warnings, follow row flow, and look for repeated work. Then make one evidence-based change and measure again. The goal is not to produce a prettier plan; it is to preserve correct results while improving measured performance.


## Anatomy of a T‑SQL SELECT Statement (Written Syntax Order)
This is the order you write and read:

1. **SELECT**  
2. **FROM**  
3. **JOIN … ON**  
4. **WHERE**  
5. **GROUP BY**  
6. **HAVING**  
7. **ORDER BY**  
8. **TOP / OFFSET-FETCH** 

This structure is defined in SQL Server’s SELECT syntax documentation.   [Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-transact-sql?view=sql-server-ver17)

---

## Logical Query Processing Order (Actual Evaluation Order)
SQL Server *conceptually* processes a SELECT statement in this order:

1. **FROM** — Identify source tables; apply cross joins.  
2. **ON** — Apply join predicates.  
3. **JOIN** — Add outer rows (for LEFT/RIGHT/FULL joins).  
4. **WHERE** — Filter rows *before* grouping.  
5. **GROUP BY** — Form groups.  
6. **HAVING** — Filter groups.  
7. **SELECT** — Evaluate expressions, aliases, DISTINCT, TOP.  
8. **ORDER BY** — Sort the final result.  

This ordering is documented in SQL Server logical processing references.   [Techoral](https://techoral.com/mssql/mssql-select-internals.html)

---

## Why the Logical Order Matters  
### Column aliases  
Aliases defined in `SELECT` are **not visible** to `WHERE`, `GROUP BY`, or `HAVING` because those clauses run **before** the SELECT step.  
(They *are* visible to `ORDER BY` because ORDER BY runs after SELECT.)

### Join behavior  
Understanding the `FROM → ON → JOIN` sequence explains why:  
- INNER JOIN filters rows early  
- OUTER JOIN reintroduces unmatched rows with NULLs  
- WHERE filters *after* outer rows are added

### Grouping  
`WHERE` filters rows *before* grouping;  
`HAVING` filters groups *after* grouping.

---

## Full Example With Logical Steps  
Query:

```sql
SELECT d.DepartmentName, COUNT(*) AS EmployeeCount
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
WHERE e.Status = 'Active'
GROUP BY d.DepartmentName
HAVING COUNT(*) > 5
ORDER BY EmployeeCount DESC;
```

Logical processing:

1. **FROM** → Employees × Departments  
2. **ON** → Match `e.DeptID = d.DeptID`  
3. **JOIN** → Add unmatched outer rows (none for INNER JOIN)  
4. **WHERE** → Keep only active employees  
5. **GROUP BY** → Group by department  
6. **HAVING** → Keep groups with > 5 employees  
7. **SELECT** → Compute `COUNT(*)` and alias  
8. **ORDER BY** → Sort by EmployeeCount  

This sequence matches SQL Server’s documented logical order.   [dbalogics.com](https://www.dbalogics.com/article/t-sql-queries/understanding-sql-logical-query-processing-order-the-heart-of-sql-queries)

## Relational Algebra Example

Symbols using in Relational Algrebra

JOIN: ⋈

WHERE: σ

GROUP BY + COUNT: γ

HAVING: σ on the aggregated relation

SELECT: π

ORDER BY: τ (optional extension)

```math

\tau_{EmployeeCount\;DESC}\;
\pi_{DepartmentName,\;EmployeeCount}\;
\sigma_{EmployeeCount > 5}\;
\gamma_{DepartmentName,\;COUNT(*) \rightarrow EmployeeCount}\;
\sigma_{Status='Active'}\;
(Employees \bowtie_{Employees.DeptID = Departments.DeptID} Departments)

```
---

## Visual Model
```
FROM
  ↓
ON
  ↓
JOIN
  ↓
WHERE
  ↓
GROUP BY
  ↓
HAVING
  ↓
SELECT
  ↓
ORDER BY
```

Each step produces a **virtual table** that becomes the input to the next step.

---

## Boolean Algebra
Boolean algebra in SQL is the system that governs how conditions in `WHERE`, `JOIN`, `HAVING`, and `CASE` are evaluated using **TRUE**, **FALSE**, and **NULL**. SQL implements Boolean logic using the operators **AND**, **OR**, and **NOT**, but with two twists: **three‑valued logic** (because of NULL) and **operator precedence** (NOT → AND → OR). 

---

## Core idea: SQL uses *three‑valued logic*
Unlike classical Boolean algebra (TRUE/FALSE only), SQL adds a third truth value:

- **TRUE**
- **FALSE**
- **NULL** (meaning *unknown*)

Every logical operator must account for this third state. This is why some expressions behave differently than programmers expect.

---

## How SQL evaluates Boolean expressions

### AND (logical conjunction)  
TRUE only if **both** sides are TRUE.  
If either side is FALSE → result is FALSE.  
If one side is NULL and the other is TRUE → result is NULL.  
If one side is NULL and the other is FALSE → result is FALSE.  

### OR (logical disjunction)  
TRUE if **any** side is TRUE.  
If both sides are FALSE → FALSE.  
If one side is NULL and the other is TRUE → TRUE.  
If one side is NULL and the other is FALSE → NULL.  

### NOT (logical negation)  
NOT TRUE → FALSE  
NOT FALSE → TRUE  
NOT NULL → NULL (still unknown)  

---

## Truth tables (SQL version)

### AND
| A | B | A AND B |
|---|---|---------|
| TRUE | TRUE | TRUE |
| TRUE | FALSE | FALSE |
| TRUE | NULL | NULL |
| FALSE | TRUE | FALSE |
| FALSE | NULL | FALSE |
| NULL | NULL | NULL |

### OR
| A | B | A OR B |
|---|---|--------|
| TRUE | TRUE | TRUE |
| TRUE | FALSE | TRUE |
| TRUE | NULL | TRUE |
| FALSE | TRUE | TRUE |
| FALSE | FALSE | FALSE |
| FALSE | NULL | NULL |
| NULL | NULL | NULL |

### NOT
| A | NOT A |
|---|--------|
| TRUE | FALSE |
| FALSE | TRUE |
| NULL | NULL |

These tables come directly from SQL’s three‑valued logic rules.   

---

## Operator precedence (SQL’s evaluation order)

SQL evaluates Boolean operators in this order:

1. **NOT**  
2. **AND**  
3. **OR**

This means:

```sql
WHERE A OR B AND C
```

is interpreted as:

```sql
WHERE A OR (B AND C)
```

NOT binds the tightest, OR the loosest. This precedence rule is a major source of bugs. 

---

## Why NULL breaks naive Boolean intuition

Example:

```sql
WHERE phone != NULL
```

This returns **no rows** because:

- `phone = NULL` → NULL  
- `NOT (phone = NULL)` → NOT NULL → NULL  
- WHERE only keeps rows where the result is TRUE  
- NULL is not TRUE → row is discarded

This is why SQL requires:

```sql
WHERE phone IS NOT NULL
```

---

## How Boolean algebra fits into SQL’s execution pipeline

Boolean expressions are evaluated during:

- `WHERE` (filters rows before grouping)  
- `ON` (filters rows during join matching)  
- `HAVING` (filters groups after aggregation)  
- `CASE` (branching logic)  

SQL Server evaluates these expressions **after** the row is assembled from the `FROM`/`JOIN` phase but **before** projection in the `SELECT` phase. (This is part of SQL’s logical query processing order.)

---


Boolean algebra in SQL =  
**three‑valued logic** + **AND/OR/NOT truth tables** + **operator precedence** + **NULL semantics**.

Once you internalize:

- AND is strict  
- OR is permissive  
- NOT does not “fix” NULL  
- NULL means “unknown,” not “false”  
- AND binds tighter than OR  

…you can reason about SQL conditions predictably.

---


## Final Synthesis  
The key insight: **SQL is declarative**, so the order you *write* is for human readability and grammar, but the order SQL Server *executes* is driven by relational algebra. Once students internalize this, confusing behaviors—alias visibility, join filtering, grouping rules—become predictable.


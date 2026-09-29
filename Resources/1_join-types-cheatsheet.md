# T‑SQL Table Joins
ECU — Department of Computer Science  
Instructor: Brian Dietrick

---

## 1. What a JOIN *Is*
A **JOIN** combines rows from two tables based on a logical relationship.  
In SQL Server, this relationship is expressed in the **ON** clause:

```sql
FROM A
JOIN B ON A.Key = B.Key
```

A join does **not** merge tables; it produces a *virtual result set* based on matching rules.

---

## 2. Sample Tables Used Throughout

### Employees
| id | name  | department_id |
|----|--------|----------------|
| 1  | Alice | 10             |
| 2  | Bob   | 20             |
| 3  | Carol | 10             |
| 4  | Dave  | 30             |
| 5  | Eve   | NULL           |

### Departments
| id | department_name |
|----|------------------|
| 10 | Engineering      |
| 20 | Sales            |
| 30 | Marketing        |
| 40 | HR               |

---

# 3. INNER JOIN  
### Only rows with matching keys appear.

```sql
SELECT e.name, d.department_name
FROM Employees e
INNER JOIN Departments d
    ON e.department_id = d.id;
```

### Result
- Alice → Engineering  
- Bob → Sales  
- Carol → Engineering  
- Dave → Marketing  
- Eve excluded (no department)  
- HR excluded (no employees)

### Diagram
```
Employees ⟂ Departments
   [only overlapping rows]
```

---

# 4. LEFT OUTER JOIN  
### All rows from the left table; NULLs where no match exists.

```sql
SELECT e.name, d.department_name
FROM Employees e
LEFT JOIN Departments d
    ON e.department_id = d.id;
```

### Result
- Alice → Engineering  
- Bob → Sales  
- Carol → Engineering  
- Dave → Marketing  
- Eve → NULL

### Diagram
```
Employees → Departments
[keep all left rows]
```

---

# 5. RIGHT OUTER JOIN  
### All rows from the right table; NULLs where no match exists.

```sql
SELECT e.name, d.department_name
FROM Employees e
RIGHT JOIN Departments d
    ON e.department_id = d.id;
```

### Result
- Engineering → Alice, Carol  
- Sales → Bob  
- Marketing → Dave  
- HR → NULL

### Diagram
```
Employees ← Departments
[keep all right rows]
```

---

# 6. FULL OUTER JOIN  
### All rows from both tables; unmatched rows show NULLs.

```sql
SELECT e.name, d.department_name
FROM Employees e
FULL OUTER JOIN Departments d
    ON e.department_id = d.id;
```

### Result
- Alice → Engineering  
- Bob → Sales  
- Carol → Engineering  
- Dave → Marketing  
- Eve → NULL  
- NULL → HR

### Diagram
```
Employees ↔ Departments
[complete union of both sides]
```

---

# 7. CROSS JOIN  
### Cartesian product: every row from A paired with every row from B.

```sql
SELECT e.name, d.department_name
FROM Employees e
CROSS JOIN Departments d;
```

If Employees has 5 rows and Departments has 4 rows → **20 rows**.

### Diagram
```
Employees × Departments
[all combinations]
```

---

# 8. SELF JOIN  
### A table joined to itself, often for hierarchical data.

Example: employees and their managers stored in the same table.

```sql
SELECT e.name AS Employee, m.name AS Manager
FROM Employees e
LEFT JOIN Employees m
    ON e.manager_id = m.id;
```

### Diagram
```
Employees ↻ Employees
[relational hierarchy]
```

---

# 9. ON vs WHERE — The Most Common Student Bug

### ❌ Incorrect (WHERE filters *after* the join)
This accidentally turns a LEFT JOIN into an INNER JOIN:

```sql
SELECT e.name, d.department_name
FROM Employees e
LEFT JOIN Departments d
    ON e.department_id = d.id
WHERE d.department_name = 'Engineering';
```

### ✔️ Correct (filter inside the JOIN)
Preserves unmatched rows:

```sql
SELECT e.name, d.department_name
FROM Employees e
LEFT JOIN Departments d
    ON e.department_id = d.id
    AND d.department_name = 'Engineering';
```

---

# 10. Physical Join Algorithms (SQL Server Internals)
SQL Server chooses the algorithm automatically:

| Algorithm      | Best For |
|----------------|----------|
| Nested Loops   | Small + indexed tables |
| Merge Join     | Both inputs sorted on join keys |
| Hash Join      | Large, unsorted sets |
| Adaptive Join  | SQL Server 2017+ runtime choice |

These are not join *types*—they are execution strategies.

---

# 11. Summary Table

| Join Type | Keeps Left? | Keeps Right? | NULLs? | Typical Use |
|-----------|-------------|--------------|--------|-------------|
| INNER | No | No | No | Only matched rows |
| LEFT OUTER | Yes | Only matched | Right side NULLs | Preserve left rows |
| RIGHT OUTER | Only matched | Yes | Left side NULLs | Preserve right rows |
| FULL OUTER | Yes | Yes | Both sides NULLs | Complete union |
| CROSS | Yes | Yes | No | All combinations |
| SELF | N/A | N/A | Depends | Hierarchies |

---

# 12. Practice Exercises (Canvas‑Ready)

### Exercise 1 — INNER JOIN
Return each employee and their department name.

### Exercise 2 — LEFT JOIN
Return all employees, showing “No Department” when NULL.

### Exercise 3 — FULL OUTER JOIN
Return all employees and all departments, matched when possible.

### Exercise 4 — SELF JOIN
Given a `manager_id` column, list employees with their managers.

### Exercise 5 — ON vs WHERE
Rewrite a query that incorrectly filters in the WHERE clause.

---

# 13. Instructor Notes (Faculty‑Only)
- Students frequently confuse **JOIN type** with **physical join algorithm**. Reinforce the distinction early.
- The ON vs WHERE mistake is the #1 source of incorrect LEFT JOIN results.
- Encourage students to sketch Venn‑style diagrams before writing queries.
- For advanced classes, show execution plans and highlight Nested Loops vs Hash Join behavior.

---

# 14. Suggested Homework
Create a three‑table join using:
- Employees  
- Departments  
- Projects  

Include:
- INNER JOIN  
- LEFT JOIN  
- A self join  
- A diagram for each  

---




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

# Setup for examples

## 1) Same schema as the examples

```sql
USE master;
GO

IF DB_ID('JoinTypeExamples') IS NOT NULL
BEGIN
    ALTER DATABASE JoinTypeExamples SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JoinTypeExamples;
END
GO

CREATE DATABASE JoinTypeExamples;
GO

USE JoinTypeExamples;
GO

CREATE TABLE dbo.Departments (
    id int NOT NULL PRIMARY KEY,
    department_name varchar(50) NOT NULL
);

CREATE TABLE dbo.Employees (
    id int NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL,
    department_id int NULL,
    manager_id int NULL,
    CONSTRAINT FK_Employees_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.Projects (
    id int NOT NULL PRIMARY KEY,
    project_name varchar(100) NOT NULL,
    department_id int NULL,
    CONSTRAINT FK_Projects_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

INSERT INTO dbo.Departments (id, department_name) VALUES
(1, 'Engineering'),
(2, 'Sales'),
(3, 'Human Resources'),
(4, 'Finance'),
(5, 'Marketing'),
(6, 'Operations'),
(7, 'Customer Support'),
(8, 'IT Infrastructure'),
(9, 'Research & Development'),
(10, 'Administration');

;WITH nums AS (
    SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Employees (id, name, department_id, manager_id)
SELECT
    n.id,
    CONCAT('Employee ', RIGHT('00' + CAST(n.id AS varchar(2)), 2)),
    ((n.id - 1) % 10) + 1,
    CASE
        WHEN (n.id - 1) % 5 = 0 THEN NULL
        ELSE (((n.id - 1) / 5) * 5) + 1
    END AS manager_id
FROM nums n
ORDER BY n.id;

INSERT INTO dbo.Projects (id, project_name, department_id) VALUES
(1, 'Apollo Portal', 1),
(2, 'Northwind CRM', 2),
(3, 'Operations Dashboard', 6);
GO
```

This version matches the join examples: employees belong to a department, and the project table adds a third dataset for multi-table examples.

---

## 2) Many-to-many relationship setup

```sql
USE master;
GO

IF DB_ID('JoinTypeExamples_ManyToMany') IS NOT NULL
BEGIN
    ALTER DATABASE JoinTypeExamples_ManyToMany SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JoinTypeExamples_ManyToMany;
END
GO

CREATE DATABASE JoinTypeExamples_ManyToMany;
GO

USE JoinTypeExamples_ManyToMany;
GO

CREATE TABLE dbo.Departments (
    id int NOT NULL PRIMARY KEY,
    department_name varchar(50) NOT NULL
);

CREATE TABLE dbo.Employees (
    id int NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL,
    manager_id int NULL,
    CONSTRAINT FK_Employees_Manager
        FOREIGN KEY (manager_id) REFERENCES dbo.Employees(id)
);

CREATE TABLE dbo.Projects (
    id int NOT NULL PRIMARY KEY,
    project_name varchar(100) NOT NULL,
    department_id int NULL,
    CONSTRAINT FK_Projects_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.EmployeeDepartment (
    employee_id int NOT NULL,
    department_id int NOT NULL,
    is_primary bit NOT NULL DEFAULT (0),
    PRIMARY KEY (employee_id, department_id),
    CONSTRAINT FK_EmployeeDepartment_Employees
        FOREIGN KEY (employee_id) REFERENCES dbo.Employees(id),
    CONSTRAINT FK_EmployeeDepartment_Departments
        FOREIGN KEY (department_id) REFERENCES dbo.Departments(id)
);

CREATE TABLE dbo.EmployeeProject (
    employee_id int NOT NULL,
    project_id int NOT NULL,
    role_name varchar(50) NOT NULL,
    PRIMARY KEY (employee_id, project_id),
    CONSTRAINT FK_EmployeeProject_Employees
        FOREIGN KEY (employee_id) REFERENCES dbo.Employees(id),
    CONSTRAINT FK_EmployeeProject_Projects
        FOREIGN KEY (project_id) REFERENCES dbo.Projects(id)
);

INSERT INTO dbo.Departments (id, department_name) VALUES
(1, 'Engineering'),
(2, 'Sales'),
(3, 'Human Resources'),
(4, 'Finance'),
(5, 'Marketing'),
(6, 'Operations'),
(7, 'Customer Support'),
(8, 'IT Infrastructure'),
(9, 'Research & Development'),
(10, 'Administration');

;WITH nums AS (
    SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Employees (id, name, manager_id)
SELECT
    n.id,
    CONCAT('Employee ', RIGHT('00' + CAST(n.id AS varchar(2)), 2)),
    CASE
        WHEN (n.id - 1) % 5 = 0 THEN NULL
        ELSE (((n.id - 1) / 5) * 5) + 1
    END AS manager_id
FROM nums n
ORDER BY n.id;

INSERT INTO dbo.Projects (id, project_name, department_id) VALUES
(1, 'Apollo Portal', 1),
(2, 'Northwind CRM', 2),
(3, 'Operations Dashboard', 6);

;WITH employee_dept AS (
    SELECT
        e.id AS employee_id,
        ((e.id - 1) % 10) + 1 AS primary_department,
        CASE
            WHEN ((e.id - 1) % 10) + 1 = 10 THEN 1
            ELSE (((e.id - 1) % 10) + 2)
        END AS secondary_department
    FROM dbo.Employees e
)
INSERT INTO dbo.EmployeeDepartment (employee_id, department_id, is_primary)
SELECT employee_id, primary_department, 1
FROM employee_dept
UNION ALL
SELECT employee_id, secondary_department, 0
FROM employee_dept
WHERE secondary_department <> primary_department;

;WITH employee_project_seed AS (
    SELECT
        e.id AS employee_id,
        CASE
            WHEN e.id % 3 = 1 THEN 1
            WHEN e.id % 3 = 2 THEN 2
            ELSE 3
        END AS project_id,
        CASE
            WHEN e.id % 5 = 0 THEN 'Reviewer'
            ELSE 'Contributor'
        END AS role_name
    FROM dbo.Employees e
)
INSERT INTO dbo.EmployeeProject (employee_id, project_id, role_name)
SELECT employee_id, project_id, role_name
FROM employee_project_seed
UNION ALL
SELECT employee_id,
       CASE project_id
           WHEN 1 THEN 2
           WHEN 2 THEN 3
           ELSE 1
       END,
       'Reviewer'
FROM employee_project_seed
WHERE employee_id % 5 = 0;
GO
```

This version uses bridge tables for both employee-to-department and employee-to-project relationships, which makes it a clear example of many-to-many joins in SQL.

---







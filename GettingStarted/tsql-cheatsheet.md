# T-SQL Cheat Sheet

This quick reference covers the most common SQL Server / T-SQL tasks for schema design, security, and daily CRUD work.

> Tip: `GO` is a batch separator used by SQL Server tools such as SSMS and Azure Data Studio / VS Code SQL extensions. It is not a T-SQL statement itself.

---

## 1) Database and schema creation

### Create a database
```sql
CREATE DATABASE SalesDb;
GO
```

### Create a database with file options
```sql
CREATE DATABASE SalesDb
ON PRIMARY (
    NAME = SalesDb_data,
    FILENAME = 'C:\SQLData\SalesDb.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON (
    NAME = SalesDb_log,
    FILENAME = 'C:\SQLData\SalesDb_log.ldf',
    SIZE = 25MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
);
GO
```

### Use a database
```sql
USE SalesDb;
GO
```

### Create a schema
```sql
CREATE SCHEMA Sales;
GO
```

### Drop a database (careful)
```sql
DROP DATABASE SalesDb;
GO
```

---

## 2) Tables and columns

### Create a table
```sql
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT (1),
    CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Customers_CreatedDate DEFAULT (SYSUTCDATETIME())
);
GO
```

### Add a column
```sql
ALTER TABLE dbo.Customers
ADD PhoneNumber NVARCHAR(20) NULL;
GO
```

### Alter a column
```sql
ALTER TABLE dbo.Customers
ALTER COLUMN PhoneNumber NVARCHAR(30) NOT NULL;
GO
```

### Rename a column
```sql
EXEC sp_rename 'dbo.Customers.PhoneNumber', 'Phone', 'COLUMN';
GO
```

### Drop a column
```sql
ALTER TABLE dbo.Customers
DROP COLUMN Phone;
GO
```

### Add a check constraint
```sql
ALTER TABLE dbo.Customers
ADD CONSTRAINT CK_Customers_Email CHECK (Email IS NULL OR Email LIKE '%@%.%');
GO
```

### Drop a table
```sql
DROP TABLE IF EXISTS dbo.Customers;
GO
```

### Rename a table
```sql
EXEC sp_rename 'dbo.Customers', 'Customer';
GO
```

---

## 3) Views

### Create a view
```sql
CREATE VIEW dbo.vwActiveCustomers AS
SELECT
    CustomerID,
    FirstName,
    LastName,
    Email
FROM dbo.Customers
WHERE IsActive = 1;
GO
```

### Create or alter a view
```sql
CREATE OR ALTER VIEW dbo.vwActiveCustomers AS
SELECT
    CustomerID,
    FirstName,
    LastName,
    Email,
    CreatedDate
FROM dbo.Customers
WHERE IsActive = 1;
GO
```

### Query a view
```sql
SELECT *
FROM dbo.vwActiveCustomers;
GO
```

### Drop a view
```sql
DROP VIEW IF EXISTS dbo.vwActiveCustomers;
GO
```

---

## 4) Indexes

### Create a nonclustered index
```sql
CREATE NONCLUSTERED INDEX IX_Customers_LastName
ON dbo.Customers (LastName);
GO
```

### Create a unique index
```sql
CREATE UNIQUE INDEX UX_Customers_Email
ON dbo.Customers (Email);
GO
```

### Create a clustered index (for a table with no clustered index)
```sql
CREATE CLUSTERED INDEX CX_Customers_CustomerID
ON dbo.Customers (CustomerID);
GO
```

### Drop an index
```sql
DROP INDEX IF EXISTS IX_Customers_LastName ON dbo.Customers;
GO
```

### Rebuild an index
```sql
ALTER INDEX ALL ON dbo.Customers REBUILD;
GO
```

---

## 5) Security: logins, users, permissions

### Create a SQL Server login
```sql
CREATE LOGIN AppLogin
WITH PASSWORD = 'Str0ngPassword!2026',
     CHECK_POLICY = ON,
     CHECK_EXPIRATION = ON;
GO
```

### Create a database user for a login
```sql
USE SalesDb;
GO

CREATE USER AppUser FOR LOGIN AppLogin;
GO
```

### Add a user to a fixed database role
```sql
ALTER ROLE db_datareader ADD MEMBER AppUser;
GO
```

### Grant permissions
```sql
GRANT SELECT, INSERT, UPDATE ON dbo.Customers TO AppUser;
GO

GRANT SELECT ON SCHEMA::Sales TO AppUser;
GO
```

### Revoke permissions
```sql
REVOKE INSERT ON dbo.Customers FROM AppUser;
GO
```

### Deny permissions
```sql
DENY DELETE ON dbo.Customers TO AppUser;
GO
```

### Create a user without a login (for app-level isolation)
```sql
CREATE USER AppUserNoLogin WITHOUT LOGIN;
GO
```

### Drop a user or login
```sql
DROP USER IF EXISTS AppUser;
GO

DROP LOGIN IF EXISTS AppLogin;
GO
```

---

## 6) SELECT statements

### Basic select
```sql
SELECT *
FROM dbo.Customers;
GO
```

### Select specific columns
```sql
SELECT CustomerID, FirstName, LastName, Email
FROM dbo.Customers;
GO
```

### Filter rows with WHERE
```sql
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE IsActive = 1
  AND LastName LIKE 'S%';
GO
```

### Sort rows
```sql
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
ORDER BY LastName, FirstName;
GO
```

### Top N rows
```sql
SELECT TOP (10)
    CustomerID,
    FirstName,
    LastName
FROM dbo.Customers
ORDER BY CreatedDate DESC;
GO
```

### Distinct values
```sql
SELECT DISTINCT LastName
FROM dbo.Customers;
GO
```

### Join tables
```sql
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    o.OrderID,
    o.TotalAmount
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o
    ON o.CustomerID = c.CustomerID;
GO
```

### Grouping and aggregation
```sql
SELECT
    c.LastName,
    COUNT(*) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSales
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o
    ON o.CustomerID = c.CustomerID
GROUP BY c.LastName
HAVING COUNT(*) > 0;
GO
```

### Common CASE expression
```sql
SELECT
    CustomerID,
    FirstName,
    CASE
        WHEN IsActive = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS Status
FROM dbo.Customers;
GO
```

---

## 7) INSERT, UPDATE, DELETE

### Insert a single row
```sql
INSERT INTO dbo.Customers (FirstName, LastName, Email, IsActive)
VALUES ('Alicia', 'Nguyen', 'alicia@example.com', 1);
GO
```

### Insert multiple rows
```sql
INSERT INTO dbo.Customers (FirstName, LastName, Email, IsActive)
VALUES
    ('Sam', 'Lee', 'sam@example.com', 1),
    ('Priya', 'Patel', 'priya@example.com', 0);
GO
```

### Insert from another table
```sql
INSERT INTO dbo.CustomersArchive (CustomerID, FirstName, LastName)
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE IsActive = 0;
GO
```

### Update one or more rows
```sql
UPDATE dbo.Customers
SET Email = 'newemail@example.com',
    IsActive = 1
WHERE CustomerID = 12;
GO
```

### Update with a join pattern
```sql
UPDATE c
SET c.Email = p.Email
FROM dbo.Customers AS c
INNER JOIN dbo.CustomerProfiles AS p
    ON p.CustomerID = c.CustomerID
WHERE c.CustomerID = 12;
GO
```

### Delete rows
```sql
DELETE FROM dbo.Customers
WHERE IsActive = 0;
GO
```

### Delete all rows in a table (use carefully)
```sql
DELETE FROM dbo.Customers;
GO
```

---

## 8) TRUNCATE TABLE

### Remove all rows quickly
```sql
TRUNCATE TABLE dbo.CustomerLog;
GO
```

### Notes
- `TRUNCATE TABLE` is faster than `DELETE` for removing all rows from a table.
- It cannot include a `WHERE` clause.
- It resets identity values for identity columns.
- It cannot be used on tables referenced by foreign keys unless they are dropped or disabled.

---

## 9) UPDATE STATISTICS

### Update statistics for a table
```sql
UPDATE STATISTICS dbo.Customers;
GO
```

### Update statistics with full scan
```sql
UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
GO
```

### Update all statistics in a database
```sql
EXEC sp_updatestats;
GO
```

### Check current stats metadata
```sql
DBCC SHOW_STATISTICS ('dbo.Customers', IX_Customers_LastName);
GO
```

---

## 10) Useful database maintenance commands

### Check if a table exists
```sql
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
    PRINT 'Table exists';
ELSE
    PRINT 'Table does not exist';
GO
```

### Check if a view exists
```sql
IF OBJECT_ID('dbo.vwActiveCustomers', 'V') IS NOT NULL
    PRINT 'View exists';
GO
```

### Show database objects
```sql
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('dbo');
GO
```

### Show indexes for a table
```sql
SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Customers');
GO
```

---

## 11) Common patterns and safety notes

- Use `BEGIN TRANSACTION` and `COMMIT` for logical batches:
```sql
BEGIN TRANSACTION;

UPDATE dbo.Customers
SET IsActive = 0
WHERE CustomerID = 10;

COMMIT;
GO
```

- Use `ROLLBACK` if you need to undo the transaction:
```sql
BEGIN TRANSACTION;

DELETE FROM dbo.Customers
WHERE CustomerID = 100;

ROLLBACK;
GO
```

- `TRUNCATE TABLE` is a DDL-like operation and cannot be rolled back in the same way as a row-by-row `DELETE` in some scenarios. Use it only when you intentionally want to remove all rows quickly.
- For query performance, index columns used in `WHERE`, `JOIN`, and `ORDER BY` clauses.
- For security, grant the least privileges needed.

---

## 12) Quick reference summary

```sql
-- CREATE DATABASE
CREATE DATABASE SalesDb;
GO

-- CREATE TABLE
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) NULL,
    IsActive BIT NOT NULL DEFAULT (1)
);
GO

-- CREATE VIEW
CREATE VIEW dbo.vwActiveCustomers AS
SELECT CustomerID, FirstName, LastName
FROM dbo.Customers
WHERE IsActive = 1;
GO

-- CREATE INDEX
CREATE INDEX IX_Customers_LastName ON dbo.Customers (LastName);
GO

-- CREATE LOGIN / USER / PERMISSIONS
CREATE LOGIN AppLogin WITH PASSWORD = 'Str0ngPassword!2026';
USE SalesDb;
CREATE USER AppUser FOR LOGIN AppLogin;
GRANT SELECT ON dbo.Customers TO AppUser;
GO

-- SELECT
SELECT *
FROM dbo.Customers
WHERE IsActive = 1
ORDER BY LastName;
GO

-- INSERT
INSERT INTO dbo.Customers (FirstName, LastName, Email, IsActive)
VALUES ('Alicia', 'Nguyen', 'alicia@example.com', 1);
GO

-- UPDATE
UPDATE dbo.Customers
SET Email = 'new@example.com'
WHERE CustomerID = 1;
GO

-- DELETE
DELETE FROM dbo.Customers
WHERE CustomerID = 1;
GO

-- TRUNCATE
TRUNCATE TABLE dbo.CustomerLog;
GO

-- UPDATE STATISTICS
UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
GO
```

This cheat sheet covers the fundamentals; once you are comfortable with these patterns, the next topics to study are transactions, constraints, foreign keys, stored procedures, and SQL Server execution plans.

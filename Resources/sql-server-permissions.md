# SQL Server Permissions Cheat Sheet

This quick-reference guide covers the most common SQL Server permission concepts, roles, and commands.

## 1) Security model

SQL Server permissions can be granted at different scopes:

- Server-level: logins, server roles
- Database-level: users, database roles, permissions
- Schema-level: access to groups of objects
- Object-level: tables, views, procedures, functions

Permission rules:

- `GRANT` gives access
- `DENY` blocks access even if another role grants it
- `REVOKE` removes a granted or denied permission

`DENY` normally wins over `GRANT` for the same principal and permission.

---

## 2) Common server roles

| Role | Typical use |
| --- | --- |
| `sysadmin` | Full control of the instance |
| `serveradmin` | Configure server settings |
| `securityadmin` | Manage logins and server permissions |
| `processadmin` | Manage SQL Server processes |
| `dbcreator` | Create and drop databases |
| `setupadmin` | Manage setup tasks and linked servers |
| `bulkadmin` | Allow `BULK INSERT` |
| `public` | Default role for all logins |

```sql
-- Add login to server role
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\UserName];
```

---

## 3) Common database roles

| Role | Typical use |
| --- | --- |
| `db_owner` | Full database control |
| `db_accessadmin` | Add or remove database access |
| `db_securityadmin` | Manage database roles and permissions |
| `db_ddladmin` | Create/alter database objects |
| `db_backupoperator` | Backup the database |
| `db_datareader` | Read all user tables/views |
| `db_datawriter` | Insert/update/delete all user tables |
| `db_denydatareader` | Prevent read access |
| `db_denydatawriter` | Prevent write access |
| `public` | Default role for all database users |

```sql
USE MyDatabase;
GO

CREATE USER AppUser FOR LOGIN AppLogin;
ALTER ROLE db_datareader ADD MEMBER AppUser;
ALTER ROLE db_datawriter ADD MEMBER AppUser;
```

---

## 4) Object permissions

Common permissions:

|Permission|Description|Includes / Implies
| --- | --- | --- |
|CONTROL|Full control over a securable. Can perform almost any action and grant permissions to others.|ALTER, DELETE, EXECUTE, INSERT, REFERENCES, SELECT, TAKE OWNERSHIP, UPDATE, VIEW DEFINITION, and most other permissions|
|ALTER|Modify the definition of a securable (table, view, procedure, schema, etc.).|May allow creating, changing, or dropping subordinate objects depending on scope|
|SELECT|Read data from tables or views.|Read-only access to rows returned by queries|
|INSERT|Add new rows to a table.|Ability to insert data|
|UPDATE|Modify existing rows.|Ability to update data|
|DELETE|Remove rows from a table.|Ability to delete data|
|EXECUTE|Run stored procedures or functions.|Execution of routines|
|REFERENCES|Create foreign keys or other references to an object.|Ability to reference an object in constraints|
|VIEW DEFINITION|See object metadata and source definitions.|View DDL, procedure code, view definitions, function definitions|
|TAKE OWNERSHIP|Change ownership of a securable.|Ownership transfer capabilities|
|ALTER ANY|Modify any object of a specific type in a database.|Depends on object type (e.g., ALTER ANY USER, ALTER ANY ROLE)|
|CONNECT|Connect to a database or SQL Server instance.|Ability to establish a session|
|CREATE|Create new tables.|Table creation rights|
|CREATE VIEW|Create new views.|View creation rights|
|CREATE PROCED|Create stored procedures.|Procedure creation rights|
|CREATE FUNCTION|Create functions.|Function creation rights|
|BACKUP DATABASE|Perform database backups.|Database backup operations|
|VIEW|View internal database diagnostic information.|DMVs, monitoring, performance information|
|VIEW SERVER STATE|View server-wide diagnostic information.|Server DMVs and performance data|
|IMPERSONATE|Execute as another login or user.|Context switching capabilities|
|ALTER ROLE|Manage role membership.|Add/Remove members from role|
|ALTER ANY|Manage server logins.|Create, alter, and disable logins|

```sql
USE MyDatabase;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Customers TO AppUser;
GRANT EXECUTE ON dbo.GetCustomerById TO AppUser;
REVOKE DELETE ON dbo.Customers FROM AppUser;
DENY UPDATE ON dbo.Customers TO AppUser;
```

Schema-level example:

```sql
GRANT SELECT, INSERT ON SCHEMA::Sales TO AppUser;
```

### Permission Hierarchy Examples

```
CONTROL
 ├─ ALTER
 ├─ DELETE
 ├─ EXECUTE
 ├─ INSERT
 ├─ REFERENCES
 ├─ SELECT
 ├─ TAKE OWNERSHIP
 ├─ UPDATE
 ├─ VIEW DEFINITION
 └─ Most other permissions

ALTER
 ├─ Modify object definition
 ├─ Add columns
 ├─ Change indexes
 ├─ Modify constraints
 └─ Rename object components

VIEW DEFINITION
 ├─ View table metadata
 ├─ View view definitions
 ├─ View stored procedure code
 ├─ View function definitions
 └─ View object properties

VIEW DATABASE STATE
 ├─ Query DMVs
 ├─ View active sessions
 ├─ View locks
 ├─ View query statistics
 └─ View performance metrics

ALTER ANY USER
 ├─ Create users
 ├─ Modify users
 ├─ Drop users
 ├─ Change default schema
 └─ Manage user properties

ALTER ANY ROLE
 ├─ Create roles
 ├─ Modify roles
 ├─ Drop roles
 ├─ Add members
 └─ Remove members

 Server-Level Permissions
 ├─ ALTER ANY LOGIN
 ├─ ALTER ANY SERVER ROLE
 ├─ CONTROL SERVER
 ├─ VIEW SERVER STATE
 ├─ SHUTDOWN
 └─ CONNECT SQL

Database-Level Permissions
 ├─ CONNECT
 ├─ CREATE TABLE
 ├─ CREATE VIEW
 ├─ CREATE PROCEDURE
 ├─ CREATE FUNCTION
 ├─ ALTER ANY USER
 ├─ ALTER ANY ROLE
 ├─ VIEW DATABASE STATE
 └─ CONTROL

Object-Level Permissions
 ├─ SELECT
 ├─ INSERT
 ├─ UPDATE
 ├─ DELETE
 ├─ EXECUTE
 ├─ ALTER
 ├─ REFERENCES
 ├─ VIEW DEFINITION
 ├─ TAKE OWNERSHIP
 └─ CONTROL
```

A useful rule of thumb is:

```
CONTROL
  > ALTER
    > SELECT / INSERT / UPDATE / DELETE / EXECUTE
      > VIEW DEFINITION
```

Where CONTROL is effectively object ownership-level authority, while VIEW DEFINITION is merely visibility into how the object is defined.


---

## 5) Login and user creation

```sql
-- Server login
CREATE LOGIN AppLogin WITH PASSWORD = 'StrongPassword!123';

-- Database user mapped to login
USE MyDatabase;
CREATE USER AppUser FOR LOGIN AppLogin;
```

Windows principal example:

```sql
CREATE LOGIN [DOMAIN\UserName] FROM WINDOWS;
```

---

## 6) Role membership checks

```sql
SELECT r.name AS role_name, m.name AS member_name
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id;

SELECT r.name AS role_name, u.name AS user_name
FROM sys.database_role_members drm
JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id;
```

---

## 7) Check current effective permissions

```sql
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
SELECT * FROM fn_my_permissions('dbo.Customers', 'OBJECT');
```

Check permissions on a specific object:

```sql
SELECT *
FROM sys.database_permissions
WHERE major_id = OBJECT_ID('dbo.Customers');
```

---

## 8) Common patterns

### Read-only app user

```sql
USE MyDatabase;
CREATE USER AppReadOnly FOR LOGIN AppLogin;
ALTER ROLE db_datareader ADD MEMBER AppReadOnly;
```

### App user with write access to one schema

```sql
USE MyDatabase;
CREATE USER AppWriter FOR LOGIN AppLogin;
ALTER ROLE db_datawriter ADD MEMBER AppWriter;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Sales TO AppWriter;
```

### Stored procedure execution

```sql
GRANT EXECUTE ON dbo.usp_GetOrders TO AppUser;
```

### Admin access

```sql
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\DBA_User];
```

---

## 9) Permission precedence

The usual effective precedence is:

1. Explicit `DENY`
2. Explicit `GRANT`
3. Role membership grants
4. Ownership and chaining behavior
5. Default `public` access

This means a `DENY` at the object level can block a user even if a role grants access.

---

## 10) Best practices

- Grant least privilege
- Prefer roles instead of one-off user grants
- Use `DENY` only when necessary
- Separate admin users from application users
- Review role membership and explicit object permissions regularly
- Keep ownership and chaining in mind when working with stored procedures and views

---

## 11) Quick command reference

```sql
-- Grant object permission
GRANT SELECT ON dbo.TableName TO UserName;

-- Revoke permission
REVOKE SELECT ON dbo.TableName FROM UserName;

-- Deny permission
DENY SELECT ON dbo.TableName TO UserName;

-- Add user to database role
ALTER ROLE db_datareader ADD MEMBER UserName;

-- Add login to server role
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\UserName];

-- Check execute permission
SELECT HAS_PERMS_BY_NAME('dbo.usp_GetOrders', 'OBJECT', 'EXECUTE');
```

---

## 12) Troubleshooting checklist

If a user cannot access a table or procedure:

- Confirm the login is mapped to a database user
- Check role membership
- Check for a `DENY` override
- Confirm the user has access to the object or schema
- Check whether ownership chaining or cross-database access is involved

---

## 13) Mental model

Think in layers:

- Instance/server: who can log in and manage the SQL Server?
- Database: who can connect and use the database?
- Schema: who can work with groups of objects?
- Object: who can read, write, or execute a specific object?

Use the smallest permission needed and expand only when the requirement justifies it.

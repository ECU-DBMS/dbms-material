# SQL Server Stored Procedures Cheatsheet

A stored procedure is a named, saved group of T-SQL statements in a database.
You can run it by name, pass it values, and return result sets or output values.
Procedures are useful for reusable database tasks; they are not the same as
functions, which can be used as expressions in queries.

> Examples use the `dbo` schema and a small `dbo.Students` table. Run the setup
> first in a practice database. `GO` is a batch separator understood by tools
> such as SSMS, Azure Data Studio, and the VS Code SQL Server extension; it is
> not a T-SQL statement sent to SQL Server.

## 1. Example table

```sql
CREATE TABLE dbo.Students (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Major NVARCHAR(100) NULL
);
GO

INSERT INTO dbo.Students (FirstName, LastName, Major)
VALUES
    (N'Ada', N'Lovelace', N'Computer Science'),
    (N'Grace', N'Hopper', N'Computer Science'),
    (N'Katherine', N'Johnson', N'Mathematics');
GO
```

## 2. Create a basic procedure

Use `CREATE OR ALTER PROCEDURE` to create a procedure the first time and update
it on later runs:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_GetStudents
AS
BEGIN
    SET NOCOUNT ON;

    SELECT StudentID, FirstName, LastName, Major
    FROM dbo.Students
    ORDER BY LastName, FirstName;
END;
GO
```

- `dbo` is the schema; include it when creating and calling the procedure.
- `BEGIN` and `END` group the procedure's statements.
- `SET NOCOUNT ON` suppresses extra “rows affected” messages.
- A `SELECT` inside a procedure sends a result set back to the caller.

> `CREATE OR ALTER` is supported by SQL Server 2016 SP1 and later. Older
> versions may require separate `CREATE PROCEDURE` and `ALTER PROCEDURE`
> scripts.

## 3. Run a procedure

Use `EXEC` (or its longer form, `EXECUTE`):

```sql
EXEC dbo.usp_GetStudents;
```

## 4. Add input parameters

Parameters let the caller provide values. Declare each parameter with a name
and a SQL data type:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_GetStudentsByMajor
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT StudentID, FirstName, LastName, Major
    FROM dbo.Students
    WHERE Major = @Major
    ORDER BY LastName, FirstName;
END;
GO
```

Pass an argument by name. The value's type should match the column or
expression it is compared with:

```sql
EXEC dbo.usp_GetStudentsByMajor @Major = N'Computer Science';
```

Named arguments make calls easier to read and safer when a procedure has
multiple parameters. Positional calls are also allowed, but values must be in
the declared order:

```sql
EXEC dbo.usp_GetStudentsByMajor N'Mathematics';
```

## 5. Use an optional parameter

Give a parameter a default value to make it optional. This example returns all
students when `@Major` is omitted or set to `NULL`:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_SearchStudents
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT StudentID, FirstName, LastName, Major
    FROM dbo.Students
    WHERE @Major IS NULL OR Major = @Major
    ORDER BY LastName, FirstName;
END;
GO
```

```sql
EXEC dbo.usp_SearchStudents; -- All majors
EXEC dbo.usp_SearchStudents @Major = N'Mathematics';
```

SQL uses `IS NULL` to test for `NULL`; `= NULL` does not work as a null test.
In this example, `NULL` means “do not filter by major,” so it cannot also be
used to request only rows whose `Major` is `NULL`.

## 6. Insert and update rows

An insert procedure can return the new row's identity value as a result set:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_AddStudent
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Students (FirstName, LastName, Major)
    VALUES (@FirstName, @LastName, @Major);

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS StudentID;
END;
GO
```

```sql
EXEC dbo.usp_AddStudent
    @FirstName = N'Barbara',
    @LastName = N'Liskov',
    @Major = N'Computer Science';
```

Use a key in an update procedure's `WHERE` clause so the intended row is
changed:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajor
    @StudentID INT,
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Students
    SET Major = @Major
    WHERE StudentID = @StudentID;
END;
GO
```

```sql
EXEC dbo.usp_UpdateStudentMajor
    @StudentID = 1,
    @Major = N'Mathematics';
```

## 7. Return an output parameter

Use an `OUTPUT` parameter when the procedure needs to give back a single value
in addition to any result sets:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_GetStudentCount
    @StudentCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @StudentCount = COUNT(*)
    FROM dbo.Students;
END;
GO
```

Declare a variable to receive it. `OUTPUT` must appear in the call as well:

```sql
DECLARE @Count INT;

EXEC dbo.usp_GetStudentCount
    @StudentCount = @Count OUTPUT;

SELECT @Count AS StudentCount;
```

### Result sets, output parameters, and `RETURN`

- A procedure's `SELECT` returns a result set (one or more rows and columns).
- An `OUTPUT` parameter returns a specifically named value.
- `RETURN` supplies an integer status code, not a table or general-purpose
  value. Use result sets or output parameters for data.

For example, capture an integer return status like this:

```sql
DECLARE @Status INT;

EXEC @Status = dbo.usp_GetStudents;

SELECT @Status AS ReturnStatus;
```

Most procedures do not need an explicit `RETURN`; the default status is `0`.

## 8. Change or remove a procedure

Run the `CREATE OR ALTER PROCEDURE` definition again to update the procedure.
To remove it:

```sql
DROP PROCEDURE IF EXISTS dbo.usp_GetStudents;
GO
```

`DROP PROCEDURE IF EXISTS` is supported by SQL Server 2016 and later. Dropping
a procedure removes its definition, not the table or data it uses.

## 9. Advanced topics

### Error handling and transactions

Use a transaction when a group of changes must succeed or fail together.
`TRY...CATCH` handles an error, and `THROW` re-raises it so the caller knows
the operation failed:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_AddStudentWithTransaction
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Students (FirstName, LastName, Major)
        VALUES (@FirstName, @LastName, @Major);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
```

This is a simple, self-contained transaction pattern. When procedures are
called inside transactions managed by other code, agree clearly on which layer
owns starting, committing, and rolling back the transaction.

### Parameterized dynamic SQL

Most queries do not need dynamic SQL. If a query must be built at runtime, pass
data values as parameters to `sys.sp_executesql`; do not concatenate user
input into the SQL text:

```sql
CREATE OR ALTER PROCEDURE dbo.usp_SearchStudentsDynamic
    @Major NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX) =
        N'SELECT StudentID, FirstName, LastName, Major
          FROM dbo.Students
          WHERE Major = @Major;';

    EXEC sys.sp_executesql
        @Sql,
        N'@Major NVARCHAR(100)',
        @Major = @Major;
END;
GO
```

SQL parameters represent values, not table or column names. If dynamic object
names are unavoidable, validate them against an allow-list and quote them
appropriately; parameterizing values remains essential.

### Limit who can execute a procedure

Grant only the permissions users need. Replace `[StudentReader]` with an
existing database user or role:

```sql
GRANT EXECUTE ON OBJECT::dbo.usp_GetStudents TO [StudentReader];
```

## 10. Common mistakes to avoid

- Forgetting `EXEC` when running a procedure.
- Omitting the schema, such as writing `usp_GetStudents` instead of
  `dbo.usp_GetStudents`.
- Using a parameter type or length that does not match the data being handled.
- Comparing to `NULL` with `=` instead of using `IS NULL` or `IS NOT NULL`.
- Updating or deleting rows without a sufficiently restrictive `WHERE` clause.
- Concatenating user-provided values into dynamic SQL.
- Expecting `RETURN` to return a result set or arbitrary data.
- Treating `GO` as part of the procedure; it is a client-tool batch separator.
- Assuming a transaction automatically spans every statement in every call;
  make transaction ownership explicit when combining procedures.

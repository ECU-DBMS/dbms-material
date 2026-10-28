# Advanced SQL Server Stored Procedures Cheatsheet

This guide focuses on production-grade stored procedure patterns for junior
developers moving beyond syntax basics.

Companion references:
- [Resources/sp-cheatsheet.md](Resources/sp-cheatsheet.md)
- [Resources/query-plan-cheatsheet.md](Resources/query-plan-cheatsheet.md)

---

## 1. Procedure contracts and input validation

### When to use
Use explicit contracts when procedures are called by applications, integration
jobs, or other procedures that need predictable behavior.

### Why it matters
Stored procedures often become API boundaries. If parameter rules are implicit,
callers guess, bugs spread, and data quality degrades.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajor
    @StudentID INT,
    @Major NVARCHAR(100),
    @ChangedBy SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    IF @StudentID IS NULL OR @StudentID <= 0
        THROW 50001, 'StudentID must be a positive integer.', 1;

    IF @Major IS NULL OR LEN(LTRIM(RTRIM(@Major))) = 0
        THROW 50002, 'Major is required.', 1;

    IF @ChangedBy IS NULL OR LEN(LTRIM(RTRIM(@ChangedBy))) = 0
        THROW 50003, 'ChangedBy is required.', 1;

    UPDATE dbo.Students
    SET Major = @Major
    WHERE StudentID = @StudentID;

    IF @@ROWCOUNT = 0
        THROW 50004, 'Student not found.', 1;
END;
GO
```

### Common failure mode
Only validating in the application layer and assuming database callers are
always well-behaved.

### Safer alternative
Enforce critical rules in both layers: API validation for user experience,
database validation for final integrity.

---

## 2. Transaction ownership patterns

### When to use
Use explicit transaction ownership when a procedure makes multiple writes that
must succeed or fail as one unit.

### Why it matters
Unclear ownership causes nested transaction confusion, partial updates, and
hard-to-debug rollback behavior.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_TransferAdvisor
    @FromAdvisorID INT,
    @ToAdvisorID INT,
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Students
        SET AdvisorID = @ToAdvisorID
        WHERE StudentID = @StudentID
          AND AdvisorID = @FromAdvisorID;

        IF @@ROWCOUNT = 0
            THROW 50101, 'Transfer preconditions failed.', 1;

        INSERT INTO dbo.StudentAudit (StudentID, ActionType, ChangedAtUtc)
        VALUES (@StudentID, N'AdvisorTransfer', SYSUTCDATETIME());

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

### Common failure mode
Starting transactions everywhere "just in case," then mixing outer/inner
ownership without a documented rule.

### Safer alternative
Document one ownership model per procedure category:
- leaf procedures do not start transactions;
- orchestration procedures own transaction boundaries.

---

## 3. Error handling contracts

### When to use
Use a defined error contract whenever callers must distinguish validation,
business-rule, and unexpected failures.

### Why it matters
Without a contract, every caller invents ad hoc parsing logic, which breaks
when messages change.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_EnrollStudent
    @StudentID INT,
    @CourseID INT,
    @ResultCode INT OUTPUT,
    @ResultMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ResultCode = 0;
    SET @ResultMessage = N'OK';

    BEGIN TRY
        IF @StudentID IS NULL OR @CourseID IS NULL
            THROW 50201, 'StudentID and CourseID are required.', 1;

        INSERT INTO dbo.Enrollments (StudentID, CourseID, EnrolledAtUtc)
        VALUES (@StudentID, @CourseID, SYSUTCDATETIME());
    END TRY
    BEGIN CATCH
        SET @ResultCode = ERROR_NUMBER();
        SET @ResultMessage = ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO
```

### Common failure mode
Swallowing exceptions inside `CATCH` and returning success-shaped output.

### Safer alternative
Capture diagnostics and re-throw with `THROW` unless there is a documented,
intentional translation policy.

---

## 4. Security context and permission boundaries

### When to use
Use explicit execution context and least privilege when callers need access to
data through procedures but should not have direct table rights.

### Why it matters
Security boundaries drift quickly when direct table permissions are granted as a
"quick fix."

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_GetDepartmentRoster
    @DepartmentID INT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.StudentID, s.FirstName, s.LastName
    FROM dbo.Students AS s
    WHERE s.DepartmentID = @DepartmentID
    ORDER BY s.LastName, s.FirstName;
END;
GO

GRANT EXECUTE ON OBJECT::dbo.usp_GetDepartmentRoster TO [AppReaderRole];
```

### Common failure mode
Granting `SELECT` on base tables to application roles because procedure access
seems inconvenient.

### Safer alternative
Keep base tables private and expose controlled procedure surfaces with explicit
`GRANT EXECUTE`.

---

## 5. Performance stability patterns

### When to use
Use plan-stability strategies when parameter distributions are skewed and one
cached plan performs poorly for other values.

### Why it matters
Parameter sniffing itself is normal; instability happens when one plan is wrong
for many runtime shapes.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_SearchStudents
    @Major NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Major IS NULL
    BEGIN
        SELECT StudentID, FirstName, LastName, Major
        FROM dbo.Students
        ORDER BY LastName, FirstName;
        RETURN;
    END;

    SELECT StudentID, FirstName, LastName, Major
    FROM dbo.Students
    WHERE Major = @Major
    ORDER BY LastName, FirstName
    OPTION (RECOMPILE);
END;
GO
```

### Common failure mode
Using one optional-filter query shape for all cases, then treating random slow
runs as intermittent infrastructure issues.

### Safer alternative
Branch by query shape (`IF/ELSE`) and selectively use `OPTION (RECOMPILE)` for
high-variance search predicates.

---

## 6. Safe dynamic SQL patterns

### When to use
Use dynamic SQL when object names or optional filters truly need runtime
composition and static branching becomes unmanageable.

### Why it matters
Dynamic SQL is powerful but becomes a direct injection path if values are
concatenated into executable text.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_SearchStudentsDynamic
    @Major NVARCHAR(100) = NULL,
    @SortDirection VARCHAR(4) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    IF @SortDirection NOT IN ('ASC', 'DESC')
        THROW 50301, 'SortDirection must be ASC or DESC.', 1;

    DECLARE @Sql NVARCHAR(MAX) = N'
        SELECT StudentID, FirstName, LastName, Major
        FROM dbo.Students
        WHERE (@Major IS NULL OR Major = @Major)
        ORDER BY LastName ' + @SortDirection + N', FirstName ' + @SortDirection + N';';

    EXEC sys.sp_executesql
        @Sql,
        N'@Major NVARCHAR(100)',
        @Major = @Major;
END;
GO
```

### Common failure mode
Assuming all user-controlled input can be parameterized, including object names
or keyword fragments.

### Safer alternative
Parameterize values, allow-list non-parameterizable tokens, and reject any
token not in the approved set.

---

## 7. Deployment/versioning patterns

### When to use
Use backward-compatible versioning when multiple services or jobs consume the
same procedure and cannot all deploy at once.

### Why it matters
Procedure signatures are integration contracts. Breaking them without migration
windows causes runtime failures outside the database deployment pipeline.

### Recommended template
```sql
-- Keep current contract stable
CREATE OR ALTER PROCEDURE dbo.usp_GetStudentProfile_v1
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StudentID, FirstName, LastName, Major
    FROM dbo.Students
    WHERE StudentID = @StudentID;
END;
GO

-- Introduce new contract explicitly
CREATE OR ALTER PROCEDURE dbo.usp_GetStudentProfile_v2
    @StudentID INT,
    @IncludeAdvisor BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT s.StudentID, s.FirstName, s.LastName, s.Major,
           CASE WHEN @IncludeAdvisor = 1 THEN a.AdvisorName END AS AdvisorName
    FROM dbo.Students AS s
    LEFT JOIN dbo.Advisors AS a
      ON a.AdvisorID = s.AdvisorID
    WHERE s.StudentID = @StudentID;
END;
GO
```

### Common failure mode
Changing parameter lists in place and assuming all callers update immediately.

### Safer alternative
Version procedure names for breaking changes, maintain overlap period, and
retire old versions on a documented deadline.

---

## 8. Observability and troubleshooting hooks

### When to use
Use observability hooks for high-value procedures where support teams need fast
root-cause context during incidents.

### Why it matters
Without lightweight diagnostics, troubleshooting depends on reproducing caller
state, which is often unavailable.

### Recommended template
```sql
CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajorObserved
    @StudentID INT,
    @Major NVARCHAR(100),
    @CorrelationID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @CorrelationID = COALESCE(@CorrelationID, NEWID());

    BEGIN TRY
        UPDATE dbo.Students
        SET Major = @Major
        WHERE StudentID = @StudentID;

        INSERT INTO dbo.ProcedureDiagnostics
            (CorrelationID, ProcedureName, StatusCode, LoggedAtUtc)
        VALUES
            (@CorrelationID, N'dbo.usp_UpdateStudentMajorObserved', 0, SYSUTCDATETIME());
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.ProcedureDiagnostics
            (CorrelationID, ProcedureName, StatusCode, ErrorNumber, ErrorMessage, LoggedAtUtc)
        VALUES
            (@CorrelationID, N'dbo.usp_UpdateStudentMajorObserved', 1,
             ERROR_NUMBER(), ERROR_MESSAGE(), SYSUTCDATETIME());
        THROW;
    END CATCH;
END;
GO
```

### Common failure mode
Over-logging every detail synchronously in the transaction path, creating
contention and latency.

### Safer alternative
Log minimal structured diagnostics needed for correlation and triage.

---

## 9. Anti-pattern quick table

| Anti-pattern | Risk | Safer approach |
|---|---|---|
| Concatenating user input into SQL text | SQL injection | `sp_executesql` with parameterized values |
| No transaction ownership policy | Partial updates, inconsistent state | Explicit transaction contract per procedure type |
| Swallowing errors in `CATCH` | Hidden production failures | Capture diagnostics and re-throw with `THROW` |
| Granting table permissions directly to app roles | Security boundary erosion | `GRANT EXECUTE` on curated procedure surface |
| One optional-filter query shape for all cases | Plan instability and regressions | Branch query shapes and selectively recompile |
| Breaking signature changes in place | Cross-service runtime breakage | Version procedures and deprecate intentionally |

---

## 10. Procedure ship checklist

- [ ] Inputs are validated and contract rules are documented.
- [ ] Transaction ownership is explicit (including rollback behavior).
- [ ] Error behavior is deterministic (`THROW` or documented status contract).
- [ ] Permission model follows least privilege (`GRANT EXECUTE` patterns).
- [ ] Optional-filter plan risk has been reviewed.
- [ ] Dynamic SQL paths parameterize values and allow-list unsafe tokens.
- [ ] Breaking changes use versioning/deprecation strategy.
- [ ] Diagnostic hooks are minimal, structured, and useful for support.

---

## 11. Smoke-test harness

Use these calls after deployment to verify key behavior quickly.

```sql
-- Success path
EXEC dbo.usp_UpdateStudentMajor
    @StudentID = 1,
    @Major = N'Mathematics',
    @ChangedBy = SUSER_SNAME();

-- Validation failure path
EXEC dbo.usp_UpdateStudentMajor
    @StudentID = 0,
    @Major = N'Mathematics',
    @ChangedBy = SUSER_SNAME();

-- Transaction rollback path (expected to throw if preconditions fail)
EXEC dbo.usp_TransferAdvisor
    @FromAdvisorID = -1,
    @ToAdvisorID = 2,
    @StudentID = 1;

-- Permission boundary path (run as low-privilege principal)
EXECUTE AS USER = 'AppReaderUser';
EXEC dbo.usp_GetDepartmentRoster @DepartmentID = 10;
REVERT;
```

Expected outcomes:
- Valid calls complete without partial data side effects.
- Invalid inputs fail with explicit error numbers/messages.
- Failed transactional operations leave no partial writes.
- Low-privilege principals can execute approved procedures without direct table
  access.

# Advanced SP Cheatsheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `advanced-sp-cheatsheet.md` as a production-focused SQL Server stored procedure reference for junior developers.

**Architecture:** Build the document as a pattern catalog with consistent sections (`When to use`, `Why it matters`, `Template`, `Failure mode`, `Safer alternative`) and include runnable examples, anti-pattern table, and smoke-test harness. Keep this file complementary to existing resources by linking to foundational cheat sheets instead of duplicating beginner content.

**Tech Stack:** Markdown, SQL Server T-SQL examples, repository documentation conventions.

---

### Task 1: Create document skeleton and section contracts

**Files:**
- Create: `advanced-sp-cheatsheet.md`
- Modify: `advanced-sp-cheatsheet.md`
- Test: `advanced-sp-cheatsheet.md`

- [ ] **Step 1: Create the new file with title and scope statement**

```markdown
# Advanced SQL Server Stored Procedures Cheatsheet

This guide focuses on production-grade stored procedure patterns for junior
developers moving beyond syntax basics.

> Companion references:
> - [Resources/sp-cheatsheet.md](Resources/sp-cheatsheet.md)
> - [Resources/query-plan-cheatsheet.md](Resources/query-plan-cheatsheet.md)
```

- [ ] **Step 2: Add top-level section headers in final order**

```markdown
## 1. Procedure contracts and input validation
## 2. Transaction ownership patterns
## 3. Error handling contracts
## 4. Security context and permission boundaries
## 5. Performance stability patterns
## 6. Safe dynamic SQL patterns
## 7. Deployment/versioning patterns
## 8. Observability and troubleshooting hooks
## 9. Anti-pattern quick table
## 10. Procedure ship checklist
## 11. Smoke-test harness
```

- [ ] **Step 3: Add reusable pattern block subheaders under the first 8 sections**

```markdown
### When to use
### Why it matters
### Recommended template
### Common failure mode
### Safer alternative
```

- [ ] **Step 4: Verify skeleton completeness**

Run: `rg "^## " advanced-sp-cheatsheet.md`
Expected: 11 section headers shown in the planned order.

- [ ] **Step 5: Commit**

```bash
git add advanced-sp-cheatsheet.md
git commit -m "docs: scaffold advanced stored procedure cheatsheet"
```

### Task 2: Populate production templates and explanatory content

**Files:**
- Modify: `advanced-sp-cheatsheet.md`
- Test: `advanced-sp-cheatsheet.md`

- [ ] **Step 1: Add contract/validation and transaction templates**

```sql
CREATE OR ALTER PROCEDURE dbo.usp_UpdateStudentMajor
    @StudentID INT,
    @Major NVARCHAR(100),
    @ChangedBy SYSNAME
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @StudentID IS NULL OR @StudentID <= 0
        THROW 50001, 'StudentID must be a positive integer.', 1;

    IF @Major IS NULL OR LEN(LTRIM(RTRIM(@Major))) = 0
        THROW 50002, 'Major is required.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Students
        SET Major = @Major
        WHERE StudentID = @StudentID;

        IF @@ROWCOUNT = 0
            THROW 50003, 'Student not found.', 1;

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

- [ ] **Step 2: Add error-contract, security, and performance-stability templates**

```sql
CREATE OR ALTER PROCEDURE dbo.usp_SearchStudents
    @Major NVARCHAR(100) = NULL
WITH EXECUTE AS OWNER
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

- [ ] **Step 3: Add dynamic SQL, versioning, and observability examples with explanations**

```sql
DECLARE @Sql NVARCHAR(MAX) =
N'SELECT StudentID, FirstName, LastName, Major
  FROM dbo.Students
  WHERE (@Major IS NULL OR Major = @Major);';

EXEC sys.sp_executesql
    @Sql,
    N'@Major NVARCHAR(100)',
    @Major = @Major;
```

- [ ] **Step 4: Verify required keywords and advanced topics are present**

Run: `rg "THROW|TRY|CATCH|EXECUTE AS|sp_executesql|OPTION \\(RECOMPILE\\)|XACT_ABORT|anti-pattern|checklist|smoke-test" advanced-sp-cheatsheet.md`
Expected: Matches for each required advanced area.

- [ ] **Step 5: Commit**

```bash
git add advanced-sp-cheatsheet.md
git commit -m "docs: add advanced production stored procedure patterns"
```

### Task 3: Add anti-pattern table, ship checklist, and final quality pass

**Files:**
- Modify: `advanced-sp-cheatsheet.md`
- Test: `advanced-sp-cheatsheet.md`

- [ ] **Step 1: Add anti-pattern quick table**

```markdown
| Anti-pattern | Risk | Safer approach |
|---|---|---|
| Concatenating user input into SQL text | SQL injection | `sp_executesql` with parameters |
| No transaction ownership policy | Partial updates | Explicit transaction contract |
| Swallowing errors in CATCH | Hidden failures | Re-throw with `THROW` |
| Overusing one optional-filter query shape | Plan instability | Branching or controlled recompilation |
```

- [ ] **Step 2: Add procedure ship checklist and smoke-test harness**

```markdown
- [ ] Inputs validated and contract documented
- [ ] Transaction ownership explicit
- [ ] Errors surfaced via `THROW` or documented status contract
- [ ] Permissions are least-privilege
- [ ] Plan risk reviewed for optional-filter patterns
```

- [ ] **Step 3: Run placeholder and consistency scan**

Run: `rg "TODO|TBD|implement later|add appropriate|edge cases|similar to task" advanced-sp-cheatsheet.md`
Expected: No matches.

- [ ] **Step 4: Run markdown readability spot-check**

Run: `rg "^#|^##|^###|^\\|" advanced-sp-cheatsheet.md`
Expected: Headings and table structure are intact and ordered.

- [ ] **Step 5: Commit**

```bash
git add advanced-sp-cheatsheet.md
git commit -m "docs: finalize advanced SP cheatsheet with checklist and tests"
```

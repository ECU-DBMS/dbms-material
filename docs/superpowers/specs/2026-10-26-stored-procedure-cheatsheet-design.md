# Stored Procedure Cheatsheet Design

## Goal

Create a beginner-friendly SQL Server stored procedure reference at
`Resources/sp-cheatsheet.md`. Teach the complete basics first, then add a
clearly separated advanced section for students who are ready to go further.

## Structure

1. Explain what a stored procedure is and distinguish it from a query.
2. Build a procedure from a small, self-contained example: create/alter,
   parameters, procedure body, and execution with named arguments.
3. Cover common beginner patterns: default parameters, result sets, insert and
   update examples, output parameters, and dropping a procedure.
4. Add advanced topics in a separate section: error handling and transactions,
   safe parameterized dynamic SQL, execution permissions, and common pitfalls.
5. Include SQL Server-specific reminders such as `GO` being a client batch
   separator, schema qualification, and using `CREATE OR ALTER` where available.

## Style and Validation

Follow the existing Markdown and fenced-T-SQL style in
`Resources/tsql-cheatsheet.md`. Keep examples consistent, approachable, and
safe to run against clearly named sample tables. Review the final document for
correct SQL Server syntax, coherent progression, and beginner-friendly
explanations; no build or test suite is needed for a documentation-only change.

## Scope

Only the requested stored-procedure cheatsheet is in scope. Do not modify the
existing T-SQL reference or unrelated repository files.

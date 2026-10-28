# Design Spec: advanced-sp-cheatsheet.md

## 1. Goal

Create an advanced companion cheat sheet focused on production-grade SQL Server
stored procedure patterns for junior developers moving beyond syntax basics.

This file will complement, not duplicate, the existing
`Resources/sp-cheatsheet.md` reference.

## 2. Audience and outcomes

### Primary audience

- Junior developers transitioning from classroom/basic T-SQL usage to
  production SQL Server development.

### Learning outcomes

After using this cheat sheet, a reader should be able to:

1. Define explicit procedure contracts and validate inputs defensively.
2. Choose and apply an intentional transaction ownership model.
3. Implement robust error contracts with predictable caller behavior.
4. Apply least-privilege and execution-context security patterns.
5. Avoid common performance instability issues (especially parameter sniffing).
6. Use dynamic SQL safely for flexible search requirements.
7. Roll out procedure changes safely with compatibility in mind.
8. Add lightweight observability hooks for debugging and support.

## 3. Document architecture

The new `advanced-sp-cheatsheet.md` will use a pattern-catalog structure.

Each major pattern block will use this consistent layout:

1. **When to use**
2. **Why it matters**
3. **Recommended template**
4. **Common failure mode**
5. **Safer alternative**

### Planned top-level sections

1. Procedure contracts and input validation
2. Transaction ownership patterns
3. Error handling contracts (`TRY...CATCH`, `THROW`, output diagnostics)
4. Security context and permission boundaries
5. Performance stability and parameter-sniffing-safe templates
6. Safe dynamic SQL for optional filters and flexible querying
7. Deployment/versioning and backward compatibility
8. Observability and troubleshooting hooks
9. Anti-pattern quick table
10. Procedure ship checklist and smoke-test harness

## 4. Content strategy

### Example style

- Explanation-first writing style with concise but complete examples.
- Each section includes at least one production-style, runnable template using:
  - `CREATE OR ALTER PROCEDURE`
  - explicit schema qualification
  - `SET NOCOUNT ON`
  - defensive parameter validation

### Comparison style

- Include paired examples where helpful:
  - **Fragile pattern**
  - **Robust pattern**
- Explain what changed and why in practical terms.

### Required performance patterns

The performance section will include canonical patterns for:

1. `OPTION (RECOMPILE)` for highly selective search scenarios.
2. Branching logic patterns to avoid a single unstable plan for optional filters.
3. Parameterized dynamic SQL with `sp_executesql`.

### Required security patterns

The security section will include:

- `EXECUTE AS` usage guidance and boundaries.
- Ownership-chain implications at a practical level.
- Least-privilege `GRANT EXECUTE` patterns with role-based examples.

### Required operations patterns

The operations section will include:

- Backward-compatible rollout patterns (new parameters, wrappers, deprecation).
- Signature/versioning strategy notes for safe consumer migration.
- Lightweight error correlation and diagnostic output guidance.

## 5. Error-handling and reliability posture

- No silent failure templates.
- Errors should either:
  - be re-thrown with `THROW`, or
  - be surfaced via explicit, documented return contracts.
- Transaction behavior must be explicit and predictable.
- Examples should make ownership of `BEGIN/COMMIT/ROLLBACK` clear.

## 6. Verification and test harness expectations

Include a practical smoke-test section with copy/paste calls that cover:

1. Success path
2. Validation failure path
3. Transaction rollback behavior on error
4. Permission-denied behavior for restricted principals

## 7. Cross-reference strategy

Use explicit references to existing resources when appropriate:

- `Resources/sp-cheatsheet.md` for foundational syntax patterns.
- `Resources/query-plan-cheatsheet.md` for deeper plan-inspection workflow.

The advanced sheet should stay focused on production behavior and decision
patterns rather than repeating beginner-level syntax content.

## 8. Out of scope

- Full coverage of all T-SQL language features.
- Deep index design theory (only procedure-relevant guidance included).
- Extended Event/session-level observability deep dives.
- CI/CD pipeline automation for database deployment.

## 9. Acceptance criteria

`advanced-sp-cheatsheet.md` is done when:

1. It is clearly advanced and complementary to the existing SP cheat sheet.
2. It includes robust templates for contracts, transactions, errors, security,
   performance, and versioning.
3. It includes an anti-pattern table and a ship-checklist section.
4. It includes a practical smoke-test harness.
5. It avoids placeholders, ambiguity, and contradictory guidance.

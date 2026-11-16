# Product Sales and Inventory: two-part database assignment

## Business brief

You support **Hearthside Trade Gifts**, a fictional wholesale distributor of homewares, gifts, display accessories, and seasonal goods. Purchasing receives stock into a main warehouse; sales accepts orders; fulfillment ships available units; finance applies payments and refunds; inventory staff count physical stock; auditors investigate changes and access attempts.

Report **booked order value**, not recognized revenue. An accepted order is not evidence that goods shipped or money was collected. Historical order demand and a deliberately limited operational sample coexist in this database.

All currency amounts represent USD. There are no geography, exchange-rate, or tax attributes. Products and customers use meaningless identity primary keys. Business codes identify products/documents but are not primary keys.

## Files and reading order

1. [ERD](ProductSalesInventory_ERD.md) and [data dictionary](ProductSalesInventory_DataDictionary.md).
2. [Setup entry point](ProductSalesInventory_Setup.sql), which includes the schema, all bridges, static seed files, baseline objects, and checks.
3. [Administrator prerequisites and examples](ProductSalesInventory_AdminSetup.sql).
4. [Part 1: Foundations](ProductSalesInventory_Part1_Assignment.sql).
5. [Part 2: Extensions](ProductSalesInventory_Part2_Assignment.sql).

## Learning progression

Each part has **24 exercises and a separate 100-point rubric**.

| Layer | Part 1 introduction | Part 2 extension |
|---|---|---|
| Reading data | SELECT, filters, bridge joins, grouped totals | EXISTS, scalar/correlated queries, CTEs, windows, ranking |
| Changing data | Reversible inserts, updates, deletes, identity capture | Atomic entity/bridge procedures, savepoints, error handling, serialized payments |
| Reuse | View, parameterized procedure, scalar function, inline TVF | As-of lookup, fulfillment view, function inlining comparisons |
| Reporting | Grain, payments, stock, anomalies | Monthly trends, rankings, aging, running balances |
| Performance | Index experiment, estimated/actual plans, IO/TIME | Two bad-but-correct reports, set-based rewrite, covering index, Query Store |
| Auditing | Observe set-based product audit and rollback | Multirow price updates and three-operation snapshot trigger |
| Administration | Database roles and EXECUTE AS USER | Ownership chaining, EXECUTE AS LOGIN, certificate signing, SQL Server Audit |

Part 1 includes a gently guided first derived-table example; Part 2 develops nested-query techniques explicitly. Every new concept has a similar example and Microsoft Learn references. Result correctness, evidence, and explanations matter more than matching the instructor's SQL text.

## Environment and privilege labels

| Label | Responsibilities |
|---|---|
| Student/reporting connection | Queries and explicitly permitted operations; collect results and plan evidence |
| Database administrator | Database setup, student DDL, roles/users, audit triggers, Query Store inspection |
| Server administrator | Test logins, certificate login, server performance privileges, SQL Server Audit |
| Host/container administrator | Docker resources, server port, persistent storage, audit-directory ownership |

The administrator connection can provision the lab, but permission tests must actually impersonate restricted users/logins. Running everything as `sa` does not prove least privilege.

Record SQL Server version, extension version, container CPU/memory limits, report parameters, and baseline state. Developer Edition is the validation target. Use at least 3 GB container memory for this package; other containers need their own headroom. No tooling or credentials are installed by these SQL files.

### Execute setup in VS Code

Open the repository root as the VS Code workspace (File > Open Folder on the cloned repository). If your installed MSSQL extension exposes SQLCMD mode, enable it and run [Setup](ProductSalesInventory_Setup.sql). The extension resolves `:r` include paths against the opened workspace folder, and Setup's includes are written relative to the repository root, so no path edits are needed.

If SQLCMD mode is absent or local includes cannot be resolved, use the VS Code integrated PowerShell terminal with `sqlcmd` installed:

```powershell
# Run from repository root; omit -P to avoid saving passwords in a command.
# Set SQLCMDPASSWORD securely in this session or use your configured authentication.
sqlcmd -S localhost,<your-container-port> -U <your-admin-login> -C -b `
  -i .\Assignments\ProductSalesInventory\ProductSalesInventory_Setup.sql
```

`-C` trusts the local development container's certificate; do not treat that as a production TLS policy.

An alternative, requiring no SQLCMD preprocessing in the editor, is:

1. Execute Setup's preamble through `USE ProductSalesInventory` (omit its colon directives).
2. Execute Schema, Bridges, then BaselineObjects in that database.
3. In **one retained SQL connection**, execute `SET XACT_ABORT ON; BEGIN TRANSACTION;`, then the four seed files in this order: LookupsAndOperations, CatalogAndParties, SalesAndFulfillment, PurchasingAndInventory.
4. Execute `COMMIT;` only after all four files succeed. On any failure explicitly `ROLLBACK;` and stop.
5. Execute SetupChecks.

Do not run only highlighted fragments of a seed file. GO separates batches but must not change connections; temporary mapping tables and the transaction span batches. Inserts are batched to avoid excessive SQL compilation memory.

Setup refuses an existing database; it never silently deletes work. A failure can leave an empty or partially initialized schema even though the seed transaction rolls back. Inspect the error, then explicitly use the guarded reset on this one local database before retrying.

### Persistent container audit storage

Mount a dedicated Docker named volume at `/var/opt/mssql` when creating your student container so databases and audit files survive container recreation. Do not retrofit a mount onto another person's running instance.

For your own container, provision the audit directory from PowerShell:

```powershell
docker exec -u 0 <your-container-name> mkdir -p /var/opt/mssql/audit-ProductSalesInventory
docker exec -u 0 <your-container-name> chown 10001:0 /var/opt/mssql/audit-ProductSalesInventory
docker exec -u 0 <your-container-name> chmod 770 /var/opt/mssql/audit-ProductSalesInventory
```

These are **Linux container paths**, not Windows host paths. Verify your image's SQL Server service UID rather than assuming a customized image uses 10001. A bind mount also needs host permissions compatible with the service account.

Run AdminSetup with `EnableServerLabs` left at 0 for database roles. Change it to 1 after directory provisioning to create the named server lab objects. SQL Server Audit uses `FAIL_OPERATION` if an audited operation cannot be recorded: a broken directory is an error to fix, not a condition to ignore. Audit rollover is bounded to four 32 MB files.

### Baseline populations and small-table exceptions

The database contains 10,000 source orders, 196,731 source order lines, **3,331 products** (3,329 sourced plus two authored), **3,137 customers** (3,135 sourced plus two authored), 3,329 initial price observations, 200 purchase orders/lines/receipts/receipt lines/shipments/shipment lines/payments/count lines, and 408 stock movements.

Every relationship population follows actual participating records. Most transactional bridges have at least 200 rows. These under-200 populations are intentional:

| Tables / relationship group | Count | Reason |
|---|---:|---|
| OrderStatus / MovementType / PaymentMethod | 4 / 6 / 4 | Finite real vocabularies |
| Supplier / Employee / Warehouse | 7 / 6 / 3 | Plausible scale of this distributor |
| SalesReturn / SalesReturnLine | 8 each | Eight explicitly approved sample returns, not 200 artificial complaints |
| Return header/line, shipment/return, return/payment, return/movement bridges | 8 each | Match those returns exactly |
| StockCount | 1 | One documented physical count session covering 200 products |
| WarehouseStockCount / EmployeeStockCount | 1 each | One location and responsible counter for that session |
| EmployeeSalesOrder | 26 | Staff responsibility is known only for the 26 sampled orders |

AuditEvent and ProductAuditEvent each start with 3,331 entries; setup time and execution actor vary. Student demonstration tables start empty and are **not seeded business tables**. Temporary tables, system catalogs and table variables are not 200-row business-table requirements.

## Business rules and two investigations

1. `PO-DOCK-001` was promised for 2010-11-19 but received on 2010-11-22: **three days late**. Receipt quantities still agree with purchasing and stock movements.
2. `UCI-1` receives an authorized **10.0000** line discount, about **65.3595%** of its 15.3000 gross. Investigate approval and commercial rationale; do not silently remove it to make reports easier.

All other seeded receipts meet their promise dates and all other discounts are zero. The anomaly view intentionally defines these two investigation rules; it is not a claim that no other business question can be asked.

Stock is the signed movement ledger, not a second editable balance field. Receipts, shipments and returns each have a typed source bridge. The physical count agrees with the ledger. Payments allocate to orders through a bridge. Refunds reduce net sales and net receipts together; `Balance` remains gross booked amount less gross payments. No return has more units than its original shipment.

All entity relationships, including one-to-many, pass through bridges. Child-side UNIQUE constraints enforce at-most-one parent; they do not prove required participation. Procedures create required entities and bridges atomically, restricted application roles cannot bypass those procedures, and SetupChecks detects missing participation.

Product deletion is soft deactivation. Audit event JSON stores snapshots, not a fake polymorphic foreign key. Immutable snapshots in the disposable review-queue exercise intentionally survive deletion of the reviewed row; they are evidence, not a live entity relationship.

## Performance and plan evidence

Both `lab` procedures return correct results. The monthly report wraps dates in YEAR/MONTH, initially lacks the supporting date index, and redundantly recalculates each product's amount through a deliberately non-inlined scalar function. The customer report uses a cursor to repeat work per customer. Do not describe every scan, cursor, or scalar function as inherently wrong; explain the actual workload and plans.

Capture Part 1 baselines before installing Part 2's date index. Compare slow-before-index, slow-after-index, and fast-after-index. The seed has almost 200,000 authentic lines; report costs do not depend on generated row inflation.

Use the MSSQL toolbar's **Estimated Plan** and **Enable Actual Plan** features. Save plans and statistics output. Investigate estimates/actuals, residual predicates, join choices, lookups, memory grants and spills when present. Do not demand a particular operator if the optimizer makes a justified alternative choice.

Validation on SQL Server 2025 Developer Edition in a 2-CPU/3-GB container measured approximately **601,000 versus 301,000 logical reads (49.94% fewer)** for the specified broad customer workload, and **1,348,000 versus 6,900 reads (about 99.49% fewer)** for the monthly workload. This is measured evidence, not a universal wall-clock guarantee. PerformanceChecks requires identical results and fewer reads for both workloads; container resource differences require investigation and documented interpretation.

## Security and auditing boundaries

- `LabClerk`, `LabWarehouse`, `LabAnalyst`, `LabAuditor`, and `LabApplication` are database users WITHOUT LOGIN assigned to named roles.
- Analysts can inspect base business tables; warehouse/application roles cannot directly read or mutate them. Reporting views use same-owner ownership chaining.
- Application users execute specifically taught modules; they never receive `db_owner` or `sysadmin`.
- The server demo uses `PSI2025_LabLogin`, mapped to `PSI2025_LoginUser` in the application role. EXECUTE AS LOGIN has a server authentication context; EXECUTE AS USER for a WITHOUT LOGIN user does not.
- The signed cached-statement-count procedure adds `VIEW SERVER PERFORMANCE STATE` through a certificate-mapped login. It does not enable TRUSTWORTHY, grant that permission directly to the student, or change the execution identity. ALTER invalidates signatures; AdminSetup re-signs its module.
- DML audit rows describe successful transactional changes and roll back with those changes. SQL Server Audit records access attempts including denied operations, using separate file permissions and server-level read privileges.
- Review evidence is writable only by trusted lab code/admins, not an assurance against a malicious sysadmin. Audit integrity still depends on administrator trust and protected files.
- Revert execution context even after expected errors; reconnect if unsure. A session left impersonated is not a clean result.

## Validation and reset

Instructor sequence: Setup; database AdminSetup; Part 1 solutions; Part 2 solutions; AssignmentChecks; PerformanceChecks; host provisioning and enabled AdminSetup; SecurityChecks. The supplied [PowerShell verifier](../Solutions/ProductSalesInventory_Verify.ps1) runs these on a named Docker container with SQLCMDPASSWORD already set:

```powershell
.\Solutions\ProductSalesInventory_Verify.ps1 -ContainerName <your-container> `
  -OutputDirectory C:\temp\psi-validation -Setup -ServerLabs
```

Only add `-Setup` for a fresh database. Omit `-ServerLabs` if host/server prerequisites are intentionally not being tested; that does not count as completing their required assignment evidence.

Automated checks test numeric contracts, metadata, required participation, constraints, reconciliation, invalid parameters, transactional writes, multirow audit behavior, equivalent report output, permissions, signing, impersonation and real audit-file events. Rubrics also require manual plan analysis and reasoning; automated passes alone do not earn all points.

Before resetting a server-enabled lab, explicitly opt in to [AdminCleanup](ProductSalesInventory_AdminCleanup.sql), then explicitly opt in to [Reset](ProductSalesInventory_Reset.sql), then rerun Setup. Cleanup only targets this package's named objects; it does not delete audit files or Docker volumes. Never use broad Docker pruning or another database's reset script.

/*
PRODUCT SALES AND INVENTORY - PART 2: EXTENSIONS
24 tasks / 100 points. Reuse the same database, not a new invented schema.
Run after Part 1, or install Part 1 reference objects on a clean baseline.
Mutations default to rollback. DDL persists. Record environment and all evidence.
Every task below identifies its Part 1 predecessor. Do not run instructor solutions
until you have attempted the tasks. Read the background's privilege labels.
*/
USE ProductSalesInventory;
GO
/*
GUIDE A - EXISTS asks whether a matching row exists without multiplying rows:
SELECT s.SupplierCode FROM dbo.Supplier s
WHERE EXISTS (SELECT 1 FROM rel.SupplierProduct x WHERE x.SupplierId=s.SupplierId);
A scalar nested query can return one aggregate:
SELECT SupplierCode FROM dbo.Supplier
WHERE LeadTimeDays > (SELECT AVG(CONVERT(decimal(10,2),LeadTimeDays)) FROM dbo.Supplier);
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/exists-transact-sql
https://learn.microsoft.com/en-us/sql/relational-databases/performance/subqueries
*/
-- P2.01 [4; extends P1.05/22] Using NOT EXISTS, return OrderNumber for orders
-- with NO shipment. Sort by OrderNumber. Explain why NOT IN can misbehave with NULLs.

-- P2.02 [4; extends P1.04/21] Use a nested aggregate query to return CustomerCode,
-- SalesAmount for customers above the mean customer sales amount, ordered by
-- SalesAmount DESC, CustomerCode. Define the mean over ALL customers including zero.

/*
GUIDE B - CTE names an intermediate result; window functions preserve row grain:
WITH SupplierRanking AS
(
 SELECT SupplierCode,LeadTimeDays,
        DENSE_RANK() OVER(ORDER BY LeadTimeDays DESC) AS LeadTimeRank
 FROM dbo.Supplier
)
SELECT * FROM SupplierRanking ORDER BY LeadTimeRank,SupplierCode;
https://learn.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/lag-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/dense-rank-transact-sql
*/
-- P2.03 [4; extends P1.04] Return MonthStart, SalesAmount, PreviousMonthSales,
-- ChangeAmount using a monthly CTE and LAG. First observed month has NULL
-- PreviousMonthSales and ChangeAmount. State that absent months are not synthesized.

-- P2.04 [4; extends P1.24] Return MonthStart, ProductCode, SalesAmount, SalesRank
-- for the top THREE dense ranks per month. Include ties; deterministic final
-- ordering MonthStart, SalesRank, ProductCode.

-- P2.05 [4; extends P1.21] As of 2011-07-31, return OrderNumber, AgeDays, Balance,
-- AgingBucket ('0-30','31-60','61+') for positive balances. Use a CTE and CASE.
-- This is a fixed-date baseline report, not a general historical payment reconstruction.

-- P2.06 [4; extends P1.06] For MAIN/product 85123A return OccurredAt,
-- MovementCode, QuantityChange, RunningQuantity. Use SUM OVER with an explicit
-- ROWS frame and tie-break by StockMovementId. Explain transaction ordering.

/*
GUIDE C - transaction error handling:
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 UPDATE dbo.Supplier SET LeadTimeDays=LeadTimeDays WHERE SupplierCode='HEARTH';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql
*/
-- P2.07 [4; extends P1.07/12] Create student.usp_CreateSingleLineOrder
-- (@OrderNumber varchar(30),@CustomerCode varchar(30),@ProductCode varchar(30),
-- @Quantity int,@UnitPrice decimal(12,4),@OrderedAt datetime2(0)).
-- Validate inputs and existing active product/customer. Atomically create header,
-- line, CustomerSalesOrder, SalesOrderSalesOrderLine, ProductSalesOrderLine.
-- Return SalesOrderId, SalesOrderLineId. It accepts backorders; it does not reserve stock.
-- Support an ambient caller transaction using a savepoint; reject doomed transactions.

-- P2.08 [4; extends P1.06/12] Create student.usp_CheckAvailability
-- (@ProductCode varchar(30),@WarehouseCode varchar(30),@Requested int).
-- Reject unknown codes and nonpositive/NULL quantity. Return ProductCode,
-- WarehouseCode,QuantityOnHand,RequestedQuantity,IsAvailable bit.
-- Unknown position for known product/warehouse means zero; this is not a reservation.
-- Explain why checking and later shipping without locking is a race.

-- P2.09 [4; extends P1.21] Create student.usp_RecordPayment
-- (@Reference varchar(40),@OrderNumber varchar(30),@Amount decimal(16,4),
-- @PaidAt datetime2(0)). Atomically insert Payment + allocation with Bank transfer.
-- Serialize payment attempts by locking the target SalesOrder UPDLOCK,HOLDLOCK.
-- Reject unknown orders, invalid/NULL values, and overpayment. Re-throw all failures.
-- Procedure owns its transaction: reject ambient transactions explicitly.

-- P2.10 [4; extends P1.10] Test two concurrent payment sessions on a newly
-- created $10 order: session A pays $7 and session B attempts $7. Provide a
-- runnable two-session script and prove at most one succeeds and balance is $3.
-- Keep this test database disposable; do not reset another student's container.

/*
GUIDE D - temporal lookup with APPLY:
SELECT p.ProductCode,x.UnitPrice
FROM dbo.Product p
OUTER APPLY
(
 SELECT TOP(1) h.UnitPrice
 FROM rel.ProductProductPrice r JOIN dbo.ProductPrice h ON h.ProductPriceId=r.ProductPriceId
 WHERE r.ProductId=p.ProductId AND h.EffectiveFrom<'2010-12-02'
 ORDER BY h.EffectiveFrom DESC,h.ProductPriceId DESC
) x;
https://learn.microsoft.com/en-us/sql/t-sql/queries/from-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/row-number-transact-sql
*/
-- P2.11 [4; extends P1.13] Create inline TVF student.ufn_PriceAsOf
-- (@ProductCode varchar(30),@AsOf datetime2(0)) returning ProductCode,UnitPrice,
-- EffectiveFrom. Use TOP(1), <= @AsOf and deterministic identity tie-break.
-- Unknown product or a time before its first price returns no rows.
-- In a rollback transaction add two literal later observations for 85123A:
-- 2011-02-01 at 2.7500 and 2011-06-01 at 2.9500, with their bridges.
-- Demonstrate May selects 2.7500 and July selects 2.9500; prove captured sales
-- line prices did not change, then roll back the added price observations.

-- P2.12 [4; extends P1.11/22] Create student.v_Fulfillment with SourceLineCode,
-- OrderedQuantity,ShippedQuantity,ReturnedQuantity,RemainingQuantity.
-- Include ALL sales lines and aggregate shipments and returns independently.
-- Returned units do not increase the original order's remaining shipment quantity.

-- P2.13 [4; extends P1.14/17] Compare inline arithmetic, scalar ufn_LineNet and
-- inline TVF reporting over the same source lines. Prove equal totals; capture
-- plans/IO/TIME and scalar-function inlining metadata. Do not assert that every
-- scalar function is always slower: SQL Server may inline eligible functions.

-- P2.14 [4; extends P1.15/17] Create student.usp_MonthlyProductSales_Fast
-- (@Year int,@Month int) with the SAME contract as the slow version:
-- ProductCode,Units int,SalesAmount decimal(38,4), ordered ProductCode.
-- Validate NULL/ranges; use a half-open date predicate and a justified covering index.
-- Inspect lab.ufn_ProductMonthAmount: INLINE=OFF intentionally preserves the
-- redundant per-product work in the teaching baseline. The fast report should
-- aggregate once rather than invoke that helper.

-- P2.15 [4; extends P1.05/17] Create student.usp_CustomerOrderSummary_Fast
-- (@From datetime2(0),@Until datetime2(0),@FirstCustomerCode varchar(30),
-- @LastCustomerCode varchar(30)). Preserve the slow report's customers with zero
-- activity, order-count semantics, half-open dates, and ordering. Use set-based SQL.
-- Output CustomerCode varchar(30),OrderCount int,SalesAmount decimal(19,4).

-- P2.16 [4; extends P1.16/17] Capture slow BEFORE indexes and fast AFTER indexes
-- plans for July 2011. Explain reads, scans/seeks, cardinality estimates, residual
-- predicates, key lookups, memory grants, spills if present, and index maintenance cost.
-- Also rerun the slow procedure after indexes to distinguish code from index effects.
-- Use sys.dm_exec_function_stats to investigate work hidden inside the deliberately
-- non-inlined helper, not just the apparent cost of the outer graphical plan.

-- P2.17 [4; extends P1.16/17] Query Query Store for both report procedure object IDs,
-- query/plan IDs and aggregated execution metrics. Compare a broad and narrow
-- customer range. Explain parameter sensitivity without forcing an unproven plan.
-- Query Store statistics require interval-aware aggregation; counts are not durations.

-- P2.18 [4; extends P1.17/24] Run instructor PerformanceChecks or build equivalent
-- duplicate-aware bidirectional output comparisons. Include January, July, an empty
-- month, a boundary timestamp, and zero-activity customers. Report repeatable
-- logical-read changes, not a guaranteed wall-clock speedup.

/*
GUIDE E - inserted/deleted are tables, not scalar variables:
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.tr_Product_Audit'));
A multirow trigger must SELECT from the entire inserted/deleted rowsets.
https://learn.microsoft.com/en-us/sql/relational-databases/triggers/use-the-inserted-and-deleted-tables
https://learn.microsoft.com/en-us/sql/t-sql/functions/original-login-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/json-value-transact-sql
*/
-- P2.19 [4; extends P1.18] Create dbo.tr_Student_ProductPrice_Audit AFTER UPDATE.
-- Write one audit.AuditEvent per affected price, old/new JSON, ORIGINAL_LOGIN()
-- and USER_NAME(), plus audit.ProductAuditEvent using ProductProductPrice.
-- Test two rows, NULL-safe snapshot interpretation, impersonation, and rollback.
-- Product prices are nonnullable; do not manufacture NULL price values.

-- P2.20 [4; extends P1.09/18] Create an AFTER INSERT,UPDATE,DELETE trigger on
-- student.ReviewQueue writing immutable JSON evidence to student.ReviewEvidence
-- (EvidenceId int IDENTITY PK,Operation varchar(10),OldValue nvarchar(max) NULL,
-- NewValue nvarchar(max) NULL). This stores event snapshots, not a live FK to
-- deleted rows. Test three-row insert, two-row update, three-row delete and rollback.
-- Explain why evidence survives logical deletion but the whole transaction can roll back.

-- P2.21 [5; extends P1.19/20] DBA: grant LabApplication EXECUTE on the assessed
-- customer procedure, prove direct base-table SELECT fails yet the same-owner
-- procedure succeeds. Explain ownership chaining versus EXECUTE AS.
-- Show that DENY and role membership are evaluated in the appropriate access path.

-- P2.22 [5; extends P1.20] DBA: complete AdminSetup's EXECUTE AS LOGIN and
-- certificate-signed DMV demo. Show the original login/current user before,
-- during and after; prove the unsigned direct DMV access fails (error 300)
-- but the signed module succeeds for the restricted application user.
-- Explain signature invalidation after ALTER and re-signing.

-- P2.23 [5; extends P1.18/19] Container administrator + DBA: provision the audit
-- directory as documented, enable AdminSetup's audit section, perform a permitted
-- audited access and a denied UPDATE on dbo.Product, then query fn_get_audit_file.
-- Submit event action, success flag and principal evidence. Explain failed writes
-- versus committed DML trigger events, audit-file privileges and container persistence.

-- P2.24 [5; extends P1.24] Deliver a final reporting/administration packet:
-- optimized reports with unchanged contracts; v_Fulfillment; monthly sales and
-- running stock; both business investigations; least-privilege evidence; audit
-- evidence; and a reconciliation summary. Run automated checks from a fresh
-- baseline plus solutions and explain each documented small-table exception.
/*
GUIDE F - discover unfamiliar administration and performance features:
Query Store catalog example:
SELECT actual_state_desc,query_capture_mode_desc FROM sys.database_query_store_options;
Read the procedure-query-plan-runtime-statistics relationships before joining them.
https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store
https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-runtime-stats-transact-sql
https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining
https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-function-stats-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/save-transaction-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-table
https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-signing-stored-procedures-with-a-certificate
https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-database-engine
https://learn.microsoft.com/en-us/sql/t-sql/functions/datefromparts-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql
https://learn.microsoft.com/en-us/sql/relational-databases/json/format-query-results-as-json-with-for-json-sql-server
Use AdminSetup's signed cached-statement-count procedure as the security guide,
not a blanket permission grant on server DMVs. Server-scope demonstrations use
EXECUTE AS LOGIN with a real mapped login; WITHOUT LOGIN users are database-scoped.
*/

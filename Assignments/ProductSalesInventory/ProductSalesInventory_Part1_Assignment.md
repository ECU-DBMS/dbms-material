
# PRODUCT SALES AND INVENTORY - PART 1: FOUNDATIONS

## SQL Server 2025 / VS Code MSSQL extension. 24 tasks, 100 points.
- Read ProductSalesInventory_Background.md and the ERD first.
- Begin with a fresh baseline. Save your answers in a copy of this file.
- Run DDL as your local database administrator. Role tests explicitly change context.
- Return the requested column names and order; sort only where specified.
- Money is decimal, never FLOAT. Date intervals are [start, end).
- For mutations: show before/after, then ROLLBACK unless explicitly told otherwise.
- Supply SQL, result evidence, and a short explanation for EVERY task.
- Examples are guides: select and execute the SQL inside the example block.
- Do not install instructor solutions before attempting the assignment.

```sql
USE ProductSalesInventory;
GO
```

GUIDE A - following a bridge (a different business relationship):
```sql
SELECT s.SupplierName, p.PurchaseOrderNumber
FROM dbo.Supplier s
JOIN rel.SupplierPurchaseOrder r ON r.SupplierId=s.SupplierId
JOIN dbo.PurchaseOrder p ON p.PurchaseOrderId=r.PurchaseOrderId
ORDER BY p.PurchaseOrderNumber;
```
Discover JOIN and GROUP BY:
- https://learn.microsoft.com/en-us/sql/t-sql/queries/from-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql


**P1.01** [4] 
- Schema discovery. Return TableSchema, TableName, PrimaryKeyColumn, IsIdentity for entity tables. 
- Explain why keys do not encode product information.

**P1.02** [4] 
- Return ProductCode, ProductName for active products containing LANTERN, sorted by ProductCode. Use a predicate, not a hardcoded list of codes.

**P1.03** [4] 
- Follow customer/order/line/product bridges. For order 536365 return OrderNumber, CustomerCode, ProductCode, Quantity, UnitPrice, DiscountAmount, LineAmount. Sort by ProductCode. Do not select a prebuilt reporting view.

**P1.04** [4] 
- Using reporting.v_SalesDetail, return ReportYear, ReportMonth, Units, SalesAmount, grouped by calendar year/month, ordered chronologically. Units is the sum of Quantity; SalesAmount is the sum of LineAmount.

**P1.05** [4] 
- LEFT JOIN customers to CustomerSalesOrder. Return CustomerCode, OrderCount for ALL customers, including zero matches; sort by CustomerCode. Explain COUNT(*) versus COUNT(SalesOrderId).

**P1.06** [4] 
- Read reporting.v_StockOnHand. Return WarehouseCode, ProductCode, QuantityOnHand for MAIN, sorted by ProductCode. Explain the ledger's signs.

GUIDE B - reversible mutation:
Select and execute the SQL in this example:
```sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT dbo.Product(ProductCode,ProductName) VALUES('EXAMPLE-SAMPLE',N'Display sample');
SELECT ProductCode,ProductName FROM dbo.Product WHERE ProductCode='EXAMPLE-SAMPLE';
ROLLBACK;
SELECT ProductCode FROM dbo.Product WHERE ProductCode='EXAMPLE-SAMPLE';
```
Discover `SCOPE_IDENTITY`, transactions, and `INSERT`/`UPDATE`/`DELETE`:
- https://learn.microsoft.com/en-us/sql/t-sql/functions/scope-identity-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transactions-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/insert-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/queries/update-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/delete-transact-sql

**P1.07** [4]
- In one transaction, insert product `STUDENT-MUG`, one `ProductPrice` effective 2011-07-01 at 4.5000, and its separate bridge.
- Capture identities, prove all three rows join, then roll back. Never assume an identity value.

**P1.08** [4]
- Soft-deactivate product 71053. Show before/after and roll back.
- Explain why deleting a product with historical relationships is not appropriate.

**P1.09** [4]
- Create `student.ReviewQueue` with `ReviewId int IDENTITY PRIMARY KEY` and `ReviewNote nvarchar(120) NOT NULL`.
- In a transaction, insert three distinct review notes. Delete one by captured identity, prove two remain, then roll back.
- Keep the empty demonstration table for Part 2.

**P1.10** [4]
- In a disposable transaction, try a negative `SalesOrderLine` quantity.
- Include `SourceLineCode` and `SourceRecordedAt`. Capture the expected CHECK error (547), roll back safely, prove no row survived, and show `@@TRANCOUNT = 0`.

Guided constraint-test pattern:
New control-flow syntax is explained further in Part 2. Select and execute the SQL in this example:
```sql
BEGIN TRY
 BEGIN TRANSACTION;
 INSERT dbo.Supplier(SupplierCode,SupplierName,LeadTimeDays) VALUES('BAD-EXAMPLE',N'Test',-1);
 ROLLBACK; -- reached only if the expected constraint did not reject the row
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER()<>547 THROW;
 SELECT ERROR_NUMBER() AS ExpectedCheckError;
END CATCH;
```
- https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql

GUIDE C - a simple reusable view:
Execute DDL in its own batch:
```sql
CREATE OR ALTER VIEW student.v_ExampleSuppliers
AS SELECT SupplierCode,SupplierName FROM dbo.Supplier;
```
- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-view-transact-sql

GUIDE D - parameterized procedure:
Execute DDL in its own batch:
```sql
CREATE OR ALTER PROCEDURE student.usp_ExampleSupplier @SupplierCode varchar(30)
AS
BEGIN
 SET NOCOUNT ON;
 SELECT SupplierCode,SupplierName FROM dbo.Supplier WHERE SupplierCode=@SupplierCode;
END;
```
Then run:
```sql
EXEC student.usp_ExampleSupplier @SupplierCode='HEARTH';
```
- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql

**P1.11** [4]
- Create `student.v_OrderTotals` with `SalesOrderId`, `OrderNumber`, and `TotalAmount`.
- Reuse `reporting.v_SalesDetail`; return one row per order with lines.
- Compare order 536365 with P1.03. Do not aggregate a header after payment joins.

**P1.12** [4]
- Create `student.usp_CustomerOrders(@CustomerCode varchar(30))`.
- Reject NULL or unknown codes with `THROW`.
- Return `OrderNumber`, `OrderedAt`, and `TotalAmount`, ordered by `OrderedAt`, `OrderNumber`.
- Demonstrate customer 17850.

GUIDE E - inline table-valued function:
Execute DDL in its own batch:
```sql
CREATE OR ALTER FUNCTION student.ufn_ExampleSuppliers(@Days int)
RETURNS TABLE AS RETURN
(SELECT SupplierCode,LeadTimeDays FROM dbo.Supplier WHERE LeadTimeDays<=@Days);
```
Then run:
```sql
SELECT * FROM student.ufn_ExampleSuppliers(7);
```

Scalar function example (execute in another batch):
```sql
CREATE OR ALTER FUNCTION student.ufn_ExampleDouble(@Units int)
RETURNS int AS BEGIN RETURN @Units*2; END;
```
- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql

**P1.13** [4]
- Create inline table-valued function `student.ufn_ProductSales(@ProductCode varchar(30))`.
- Return `OrderNumber`, `OrderedAt`, `Quantity`, and `LineAmount` from `reporting.v_SalesDetail`.
- Unknown or NULL product codes yield no rows (a filter, not an error).

**P1.14** [4]
- Create scalar function `student.ufn_LineNet(@Quantity int, @UnitPrice decimal(12,4), @DiscountAmount decimal(16,4))`, returning `decimal(19,4)`.
- Calculate quantity * price - discount. NULL propagates; invalid negative inputs or discount exceeding gross return NULL (functions cannot `THROW`).
- Test valid, NULL, negative, and excessive-discount cases.

GUIDE F - inspect an index, not just its existence:
Select and execute the SQL in this example:
```sql
SELECT name,type_desc FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Supplier');
```
Example DDL (execute in a separate batch):
```sql
CREATE INDEX IX_Example_SupplierLeadTime ON dbo.Supplier(LeadTimeDays)
INCLUDE(SupplierName);
```
- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql
- https://learn.microsoft.com/en-us/sql/relational-databases/performance/execution-plans
- https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statistics-io-transact-sql

**P1.15** [4]
- Create `IX_Student_ProductName` on `Product(ProductName) INCLUDE(ProductCode)`.
- Compare plans for prefix `'WHITE%'` and contains `'%WHITE%'`.
- Explain why the optimizer may choose differently and why an index does not guarantee a seek.

**P1.16** [4]
- Capture estimated and actual plans in VS Code for P1.03.
- Identify a seek or scan, a join operator, and estimated versus actual row counts.
- Explain that estimated plans do not execute the query.

**P1.17** [4]
- Enable `STATISTICS IO` and `STATISTICS TIME`; execute `lab.usp_MonthlyProductSales_Slow @Year=2011, @Month=7`; then disable statistics.
- Record reads, CPU, elapsed time, actual plan, parameters, and container limits.
- Do not change the report yet or clear shared server caches.

GUIDE G - observing a trigger-created audit:
Select and execute the SQL in this example:
```sql
SELECT TOP(5) Operation,OriginalLogin,ExecutionUser,EventAt
FROM audit.AuditEvent ORDER BY AuditEventId DESC;
```
Inspect `dbo.tr_Product_Audit` using `OBJECT_DEFINITION` and follow `ProductAuditEvent`.
- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql
- https://learn.microsoft.com/en-us/sql/relational-databases/triggers/create-dml-triggers-to-handle-multiple-rows-of-data

**P1.18** [4]
- Update TWO product names in a rollback transaction.
- Prove two new UPDATE audit events and two bridges were written; inspect before/after JSON.
- Roll back and prove product values AND audit event count return to baseline.
- Explain why selecting one scalar from `inserted` would be incorrect.

GUIDE H - permissions and execution context:
The DBA must first run AdminSetup. Select and execute the SQL in this example:
```sql
SELECT ORIGINAL_LOGIN() AS OriginalLogin,USER_NAME() AS ExecutionUser;
EXECUTE AS USER='LabWarehouse';
SELECT TOP(3) ProductCode,QuantityOnHand FROM reporting.v_StockOnHand;
REVERT;
SELECT USER_NAME() AS RestoredUser;
```
- https://learn.microsoft.com/en-us/sql/t-sql/statements/grant-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/deny-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/execute-as-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/revert-transact-sql

**P1.19** [4]
- DBA: run the AdminSetup database-role section, then return `RoleName` and `MemberName` from `sys.database_role_members` for the five named lab roles.
- Explain role membership versus object permission grants.

**P1.20** [4]
- As `LabWarehouse`, prove the stock view succeeds but `SELECT` directly from `dbo.StockMovement` fails with error 229.
- Catch ONLY the expected failure, always `REVERT`, and show original and restored execution context.

**P1.21** [5]
- For orders with any payment, return `OrderNumber`, `TotalAmount`, `PaidAmount`, `RefundAmount`, and `Balance`, sorted by `OrderNumber`.
- Use `v_OrderBalance`.
- Explain gross payments versus `NetReceipts` and why refunds are not negative sales lines.

**P1.22** [5]
- For each partially shipped line, return `SourceLineCode`, `OrderedQuantity`, `ShippedQuantity`, and `RemainingQuantity`, sorted by `SourceLineCode`.
- First aggregate `ShipmentLine` at the sales-line grain, then join.
- Explain the difference between a line's partial fulfillment and a header's status label.

**P1.23** [5]
- Identify both cases in `reporting.v_BusinessAnomalies`.
- Return `AnomalyType`, `BusinessCode`, and `Measure`, ordered by `AnomalyType`.
- Explain why each is a business investigation, not broken arithmetic or a foreign key.

**P1.24** [5]
- Deliver a product activity report with `ProductCode`, `OrderedUnits`, `SalesAmount`, and `QuantityOnHand`.
- Include every product, even with no stock position, and sort by `ProductCode`.
- Use separately aggregated sales and inventory to avoid multiplying sales by movements.
- Explain the report grain and show total sales reconciliation.

GUIDE I - a first derived table:
This example introduces a derived table before Part 2's deeper nested queries. Select and execute the SQL in this example:
```sql
SELECT s.SupplierCode,COALESCE(x.PurchaseCount,0) AS PurchaseCount
FROM dbo.Supplier s
LEFT JOIN
(
 SELECT SupplierId,COUNT(*) AS PurchaseCount
 FROM rel.SupplierPurchaseOrder GROUP BY SupplierId
) x ON x.SupplierId=s.SupplierId;
```
- The parentheses produce one row per supplier BEFORE the outer join.
- `COALESCE` supplies zero only for an absent aggregate, not for invalid input.
- https://learn.microsoft.com/en-us/sql/t-sql/queries/from-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/language-elements/coalesce-transact-sql

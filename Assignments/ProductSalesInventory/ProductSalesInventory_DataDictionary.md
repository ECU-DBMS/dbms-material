# ProductSalesInventory data dictionary

See the [physical schema](ProductSalesInventory_Schema.sql) and [bridge DDL](ProductSalesInventory_Bridges.sql) for executable definitions. All entities have a single meaningless identity primary key. Unless marked nullable, attributes are required. Dates use `datetime2(0)` except audit timestamps, which use `datetime2(3)`.

## Entity and lookup columns

`ID` in this table means the exact identity primary key named in the second column, not a shared natural key. Business-code UNIQUE constraints are single-column constraints.

| Table | Identity PK | Other columns and constraints |
|---|---|---|
| dbo.OrderStatus | OrderStatusId int | StatusName varchar(30), UNIQUE; finite order-status vocabulary |
| dbo.MovementType | MovementTypeId int | TypeName varchar(30), UNIQUE; Direction smallint CHECK IN (-1,1) |
| dbo.PaymentMethod | PaymentMethodId int | MethodName varchar(30), UNIQUE |
| dbo.Product | ProductId int | ProductCode varchar(30) UNIQUE; ProductName nvarchar(200); IsActive bit DEFAULT 1; soft deactivation preserves history |
| dbo.Customer | CustomerId int | CustomerCode varchar(30) UNIQUE; DisplayName nvarchar(120) NULL; source customers intentionally anonymous |
| dbo.Supplier | SupplierId int | SupplierCode varchar(30) UNIQUE; SupplierName nvarchar(120); LeadTimeDays int CHECK 0..365 |
| dbo.Employee | EmployeeId int | EmployeeCode varchar(30) UNIQUE; EmployeeName nvarchar(120); JobTitle nvarchar(80); fictional staff |
| dbo.Warehouse | WarehouseId int | WarehouseCode varchar(30) UNIQUE; WarehouseName nvarchar(120) |
| dbo.ProductPrice | ProductPriceId int | PriceCode varchar(40) UNIQUE; EffectiveFrom datetime2(0); UnitPrice decimal(12,4) CHECK >0 |
| dbo.SalesOrder | SalesOrderId int | OrderNumber varchar(30) UNIQUE; OrderedAt datetime2(0); OrderStatusId int lookup FK; Notes nvarchar(250) NULL |
| dbo.SalesOrderLine | SalesOrderLineId int | SourceLineCode varchar(40) UNIQUE; SourceRecordedAt datetime2(0); Quantity int CHECK >0; UnitPrice decimal(12,4) CHECK >0; DiscountAmount decimal(16,4) DEFAULT 0, CHECK 0 <= discount <= quantity*price |
| dbo.PurchaseOrder | PurchaseOrderId int | PurchaseOrderNumber varchar(30) UNIQUE; OrderedAt, ExpectedAt datetime2(0), CHECK ExpectedAt >= OrderedAt |
| dbo.PurchaseOrderLine | PurchaseOrderLineId int | PurchaseLineCode varchar(40) UNIQUE; Quantity int CHECK >0; UnitCost decimal(12,4) CHECK >0 |
| dbo.GoodsReceipt | GoodsReceiptId int | ReceiptNumber varchar(30) UNIQUE; ReceivedAt datetime2(0) |
| dbo.GoodsReceiptLine | GoodsReceiptLineId int | ReceiptLineCode varchar(40) UNIQUE; Quantity int CHECK >0 |
| dbo.Shipment | ShipmentId int | ShipmentNumber varchar(30) UNIQUE; ShippedAt datetime2(0) |
| dbo.ShipmentLine | ShipmentLineId int | ShipmentLineCode varchar(40) UNIQUE; Quantity int CHECK >0 |
| dbo.Payment | PaymentId int | PaymentReference varchar(40) UNIQUE; PaidAt datetime2(0); Amount decimal(16,4) CHECK >0; PaymentMethodId int lookup FK |
| dbo.SalesReturn | SalesReturnId int | ReturnNumber varchar(30) UNIQUE; ReturnedAt datetime2(0); Reason nvarchar(120) |
| dbo.SalesReturnLine | SalesReturnLineId int | ReturnLineCode varchar(40) UNIQUE; Quantity int CHECK >0; RefundAmount decimal(16,4) CHECK >=0 |
| dbo.StockMovement | StockMovementId int | MovementCode varchar(40) UNIQUE; OccurredAt datetime2(0); QuantityChange int CHECK <>0; MovementTypeId int lookup FK; sign/type agreement checked by validation |
| dbo.StockCount | StockCountId int | CountReference varchar(30) UNIQUE; CountedAt datetime2(0) |
| dbo.StockCountLine | StockCountLineId int | CountLineCode varchar(40) UNIQUE; CountedQuantity int CHECK >=0 |
| audit.AuditEvent | AuditEventId bigint | EventAt datetime2(3) DEFAULT SYSUTCDATETIME(); Operation varchar(10) CHECK INSERT/UPDATE/DELETE/IMPORT; OriginalLogin sysname; ExecutionUser sysname; OldValue/NewValue nvarchar(max) NULL, valid JSON when present |

## Complete relationship inventory

Each following table is a bridge. Its two listed ID columns are NOT NULL and together form its composite primary key. Every ID has a foreign key to the correspondingly named entity. A child UNIQUE constraint means at most one parent for that child; it does not require the child to participate.

All bridges are in `rel` except `audit.ProductAuditEvent`. No bridge has an identity key. No entity has a composite primary or candidate key.

| Bridge | Composite key columns, in order | Additional single-column UNIQUE |
|---|---|---|
| ProductProductPrice | ProductId, ProductPriceId | ProductPriceId |
| CustomerSalesOrder | CustomerId, SalesOrderId | SalesOrderId |
| SalesOrderSalesOrderLine | SalesOrderId, SalesOrderLineId | SalesOrderLineId |
| ProductSalesOrderLine | ProductId, SalesOrderLineId | SalesOrderLineId |
| EmployeeSalesOrder | EmployeeId, SalesOrderId | SalesOrderId |
| SupplierProduct | SupplierId, ProductId | None: many-to-many |
| SupplierPurchaseOrder | SupplierId, PurchaseOrderId | PurchaseOrderId |
| EmployeePurchaseOrder | EmployeeId, PurchaseOrderId | PurchaseOrderId |
| PurchaseOrderPurchaseOrderLine | PurchaseOrderId, PurchaseOrderLineId | PurchaseOrderLineId |
| ProductPurchaseOrderLine | ProductId, PurchaseOrderLineId | PurchaseOrderLineId |
| GoodsReceiptGoodsReceiptLine | GoodsReceiptId, GoodsReceiptLineId | GoodsReceiptLineId |
| PurchaseOrderLineGoodsReceiptLine | PurchaseOrderLineId, GoodsReceiptLineId | GoodsReceiptLineId |
| WarehouseGoodsReceipt | WarehouseId, GoodsReceiptId | GoodsReceiptId |
| EmployeeGoodsReceipt | EmployeeId, GoodsReceiptId | GoodsReceiptId |
| SalesOrderShipment | SalesOrderId, ShipmentId | ShipmentId |
| WarehouseShipment | WarehouseId, ShipmentId | ShipmentId |
| EmployeeShipment | EmployeeId, ShipmentId | ShipmentId |
| ShipmentShipmentLine | ShipmentId, ShipmentLineId | ShipmentLineId |
| SalesOrderLineShipmentLine | SalesOrderLineId, ShipmentLineId | ShipmentLineId |
| PaymentSalesOrder | PaymentId, SalesOrderId | None; AllocatedAmount decimal(16,4) CHECK >0 is the relationship payload |
| SalesReturnSalesReturnLine | SalesReturnId, SalesReturnLineId | SalesReturnLineId |
| ShipmentLineSalesReturnLine | ShipmentLineId, SalesReturnLineId | SalesReturnLineId |
| SalesReturnLinePayment | SalesReturnLineId, PaymentId | None; RefundedAmount decimal(16,4) CHECK >0 allocates refund to original payments |
| ProductWarehouse | ProductId, WarehouseId | None; an eligible stocked position, not a balance |
| ProductStockMovement | ProductId, StockMovementId | StockMovementId |
| WarehouseStockMovement | WarehouseId, StockMovementId | StockMovementId |
| GoodsReceiptLineStockMovement | GoodsReceiptLineId, StockMovementId | StockMovementId |
| ShipmentLineStockMovement | ShipmentLineId, StockMovementId | StockMovementId |
| SalesReturnLineStockMovement | SalesReturnLineId, StockMovementId | StockMovementId |
| WarehouseStockCount | WarehouseId, StockCountId | StockCountId |
| EmployeeStockCount | EmployeeId, StockCountId | StockCountId |
| StockCountStockCountLine | StockCountId, StockCountLineId | StockCountLineId |
| ProductStockCountLine | ProductId, StockCountLineId | StockCountLineId |
| audit.ProductAuditEvent | ProductId, AuditEventId bigint | AuditEventId |

Receipt, shipment and return source bridges are separate rather than an unenforced `(SourceType,SourceId)` pair. StockMovement's chosen source is exclusive in the baseline validation. Repeated receipts/shipments are supported as separate identity-keyed line entities; no line is forced to be unique solely by its product.

Simple lookup relationships are the only direct entity foreign keys: SalesOrder -> OrderStatus, Payment -> PaymentMethod, and StockMovement -> MovementType.

## Reporting contracts

| Object | Grain and values |
|---|---|
| reporting.v_SalesDetail | One source order line; header/customer/product business codes, Quantity, UnitPrice, DiscountAmount and LineAmount decimal(19,4) |
| reporting.v_OrderBalance | One order; TotalAmount, PaidAmount, RefundAmount, NetSales, NetReceipts and Balance, all decimal(19,4) |
| reporting.v_StockOnHand | One eligible product/warehouse position; QuantityOnHand is sum of signed movements, including zero positions |
| reporting.v_BusinessAnomalies | One investigation; AnomalyType varchar(30), BusinessCode varchar(40), Measure decimal(19,4); days or percentage according to type |
| lab.usp_MonthlyProductSales_Slow | @Year int, @Month int; ProductCode, Units int, SalesAmount decimal(38,4); sorted product code |
| lab.ufn_ProductMonthAmount | Internal baseline scalar helper; ProductId/year/month -> decimal(38,4); INLINE=OFF deliberately retains repeated aggregation for performance investigation |
| lab.usp_CustomerOrderSummary_Slow | @From/@Until datetime2(0), @FirstCustomerCode/@LastCustomerCode varchar(30); CustomerCode, OrderCount int, SalesAmount decimal(19,4); includes zero activity, sorted customer code |

The date interval is half-open. Initial price observation timestamps and actual historical order-line price values serve different purposes; never replace captured line prices with today's ProductPrice.

## Supported writes and constraints

Baseline FK/CHECK/UNIQUE constraints enforce local row validity and at-most-one child parent. Required bridge participation, cross-document quantities, allocations, chronological stock, and financial reconciliation are also verified by SetupChecks. These are not falsely described as constraints SQL Server automatically infers from bridges.

Part 2 supported payment writes lock the target order before checking balance. That protects cooperating procedure callers, not a sysadmin bypassing the procedure. Application permissions prohibit direct writes. Part 2 order creation atomically creates the header, line and three required bridges; it explicitly accepts backorders and does not reserve stock.

Baseline Product audit is set-based for INSERT/UPDATE. Product deletion is soft deactivation. Student price-update auditing preserves product association through its bridge. Student ReviewQueue/ReviewEvidence are disposable teaching entities with identity keys; archived JSON is a snapshot rather than a live reference to a deleted row.

No automatic cascade deletes destroy history. Reset and server-object cleanup are separate, explicitly guarded operations.

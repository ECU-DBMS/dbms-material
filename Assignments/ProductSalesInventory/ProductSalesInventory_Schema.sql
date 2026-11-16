-- DATABASE ADMINISTRATOR. Run through ProductSalesInventory_Setup.sql.
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
CREATE SCHEMA rel AUTHORIZATION dbo;
GO
CREATE SCHEMA reporting AUTHORIZATION dbo;
GO
CREATE SCHEMA lab AUTHORIZATION dbo;
GO
CREATE SCHEMA student AUTHORIZATION dbo;
GO
CREATE SCHEMA audit AUTHORIZATION dbo;
GO
CREATE TABLE dbo.OrderStatus
(
    OrderStatusId int IDENTITY PRIMARY KEY,
    StatusName varchar(30) NOT NULL UNIQUE
);
CREATE TABLE dbo.MovementType
(
    MovementTypeId int IDENTITY PRIMARY KEY,
    TypeName varchar(30) NOT NULL UNIQUE,
    Direction smallint NOT NULL CHECK (Direction IN (-1,1))
);
CREATE TABLE dbo.PaymentMethod
(
    PaymentMethodId int IDENTITY PRIMARY KEY,
    MethodName varchar(30) NOT NULL UNIQUE
);
CREATE TABLE dbo.Product
(
    ProductId int IDENTITY PRIMARY KEY,
    ProductCode varchar(30) NOT NULL UNIQUE,
    ProductName nvarchar(200) NOT NULL,
    IsActive bit NOT NULL DEFAULT 1
);
CREATE TABLE dbo.Customer
(
    CustomerId int IDENTITY PRIMARY KEY,
    CustomerCode varchar(30) NOT NULL UNIQUE,
    DisplayName nvarchar(120) NULL
);
CREATE TABLE dbo.Supplier
(
    SupplierId int IDENTITY PRIMARY KEY,
    SupplierCode varchar(30) NOT NULL UNIQUE,
    SupplierName nvarchar(120) NOT NULL,
    LeadTimeDays int NOT NULL CHECK (LeadTimeDays BETWEEN 0 AND 365)
);
CREATE TABLE dbo.Employee
(
    EmployeeId int IDENTITY PRIMARY KEY,
    EmployeeCode varchar(30) NOT NULL UNIQUE,
    EmployeeName nvarchar(120) NOT NULL,
    JobTitle nvarchar(80) NOT NULL
);
CREATE TABLE dbo.Warehouse
(
    WarehouseId int IDENTITY PRIMARY KEY,
    WarehouseCode varchar(30) NOT NULL UNIQUE,
    WarehouseName nvarchar(120) NOT NULL
);
CREATE TABLE dbo.ProductPrice
(
    ProductPriceId int IDENTITY PRIMARY KEY,
    PriceCode varchar(40) NOT NULL UNIQUE,
    EffectiveFrom datetime2(0) NOT NULL,
    UnitPrice decimal(12,4) NOT NULL CHECK (UnitPrice > 0)
);
CREATE TABLE dbo.SalesOrder
(
    SalesOrderId int IDENTITY PRIMARY KEY,
    OrderNumber varchar(30) NOT NULL UNIQUE,
    OrderedAt datetime2(0) NOT NULL,
    OrderStatusId int NOT NULL REFERENCES dbo.OrderStatus(OrderStatusId),
    Notes nvarchar(250) NULL
);
CREATE TABLE dbo.SalesOrderLine
(
    SalesOrderLineId int IDENTITY PRIMARY KEY,
    SourceLineCode varchar(40) NOT NULL UNIQUE,
    SourceRecordedAt datetime2(0) NOT NULL,
    Quantity int NOT NULL CHECK (Quantity > 0),
    UnitPrice decimal(12,4) NOT NULL CHECK (UnitPrice > 0),
    DiscountAmount decimal(16,4) NOT NULL DEFAULT 0,
    CHECK (DiscountAmount >= 0 AND DiscountAmount <= Quantity * UnitPrice)
);
CREATE TABLE dbo.PurchaseOrder
(
    PurchaseOrderId int IDENTITY PRIMARY KEY,
    PurchaseOrderNumber varchar(30) NOT NULL UNIQUE,
    OrderedAt datetime2(0) NOT NULL,
    ExpectedAt datetime2(0) NOT NULL,
    CHECK (ExpectedAt >= OrderedAt)
);
CREATE TABLE dbo.PurchaseOrderLine
(
    PurchaseOrderLineId int IDENTITY PRIMARY KEY,
    PurchaseLineCode varchar(40) NOT NULL UNIQUE,
    Quantity int NOT NULL CHECK (Quantity > 0),
    UnitCost decimal(12,4) NOT NULL CHECK (UnitCost > 0)
);
CREATE TABLE dbo.GoodsReceipt
(
    GoodsReceiptId int IDENTITY PRIMARY KEY,
    ReceiptNumber varchar(30) NOT NULL UNIQUE,
    ReceivedAt datetime2(0) NOT NULL
);
CREATE TABLE dbo.GoodsReceiptLine
(
    GoodsReceiptLineId int IDENTITY PRIMARY KEY,
    ReceiptLineCode varchar(40) NOT NULL UNIQUE,
    Quantity int NOT NULL CHECK (Quantity > 0)
);
CREATE TABLE dbo.Shipment
(
    ShipmentId int IDENTITY PRIMARY KEY,
    ShipmentNumber varchar(30) NOT NULL UNIQUE,
    ShippedAt datetime2(0) NOT NULL
);
CREATE TABLE dbo.ShipmentLine
(
    ShipmentLineId int IDENTITY PRIMARY KEY,
    ShipmentLineCode varchar(40) NOT NULL UNIQUE,
    Quantity int NOT NULL CHECK (Quantity > 0)
);
CREATE TABLE dbo.Payment
(
    PaymentId int IDENTITY PRIMARY KEY,
    PaymentReference varchar(40) NOT NULL UNIQUE,
    PaidAt datetime2(0) NOT NULL,
    Amount decimal(16,4) NOT NULL CHECK (Amount > 0),
    PaymentMethodId int NOT NULL REFERENCES dbo.PaymentMethod(PaymentMethodId)
);
CREATE TABLE dbo.SalesReturn
(
    SalesReturnId int IDENTITY PRIMARY KEY,
    ReturnNumber varchar(30) NOT NULL UNIQUE,
    ReturnedAt datetime2(0) NOT NULL,
    Reason nvarchar(120) NOT NULL
);
CREATE TABLE dbo.SalesReturnLine
(
    SalesReturnLineId int IDENTITY PRIMARY KEY,
    ReturnLineCode varchar(40) NOT NULL UNIQUE,
    Quantity int NOT NULL CHECK (Quantity > 0),
    RefundAmount decimal(16,4) NOT NULL CHECK (RefundAmount >= 0)
);
CREATE TABLE dbo.StockMovement
(
    StockMovementId int IDENTITY PRIMARY KEY,
    MovementCode varchar(40) NOT NULL UNIQUE,
    OccurredAt datetime2(0) NOT NULL,
    QuantityChange int NOT NULL CHECK (QuantityChange <> 0),
    MovementTypeId int NOT NULL REFERENCES dbo.MovementType(MovementTypeId)
);
CREATE TABLE dbo.StockCount
(
    StockCountId int IDENTITY PRIMARY KEY,
    CountReference varchar(30) NOT NULL UNIQUE,
    CountedAt datetime2(0) NOT NULL
);
CREATE TABLE dbo.StockCountLine
(
    StockCountLineId int IDENTITY PRIMARY KEY,
    CountLineCode varchar(40) NOT NULL UNIQUE,
    CountedQuantity int NOT NULL CHECK (CountedQuantity >= 0)
);
CREATE TABLE audit.AuditEvent
(
    AuditEventId bigint IDENTITY PRIMARY KEY,
    EventAt datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    Operation varchar(10) NOT NULL CHECK (Operation IN ('INSERT','UPDATE','DELETE','IMPORT')),
    OriginalLogin sysname NOT NULL,
    ExecutionUser sysname NOT NULL,
    OldValue nvarchar(max) NULL CHECK (OldValue IS NULL OR ISJSON(OldValue) = 1),
    NewValue nvarchar(max) NULL CHECK (NewValue IS NULL OR ISJSON(NewValue) = 1)
);
GO
-- Bridge definitions are expanded to ordinary DDL by BuildSeed.mjs.

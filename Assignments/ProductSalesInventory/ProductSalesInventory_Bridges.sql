-- Every non-lookup entity relationship is represented explicitly.
CREATE TABLE rel.ProductProductPrice (ProductId int REFERENCES dbo.Product, ProductPriceId int REFERENCES dbo.ProductPrice UNIQUE, PRIMARY KEY(ProductId,ProductPriceId));
CREATE TABLE rel.CustomerSalesOrder (CustomerId int REFERENCES dbo.Customer, SalesOrderId int REFERENCES dbo.SalesOrder UNIQUE, PRIMARY KEY(CustomerId,SalesOrderId));
CREATE TABLE rel.SalesOrderSalesOrderLine (SalesOrderId int REFERENCES dbo.SalesOrder, SalesOrderLineId int REFERENCES dbo.SalesOrderLine UNIQUE, PRIMARY KEY(SalesOrderId,SalesOrderLineId));
CREATE TABLE rel.ProductSalesOrderLine (ProductId int REFERENCES dbo.Product, SalesOrderLineId int REFERENCES dbo.SalesOrderLine UNIQUE, PRIMARY KEY(ProductId,SalesOrderLineId));
CREATE TABLE rel.EmployeeSalesOrder (EmployeeId int REFERENCES dbo.Employee, SalesOrderId int REFERENCES dbo.SalesOrder UNIQUE, PRIMARY KEY(EmployeeId,SalesOrderId));
CREATE TABLE rel.SupplierProduct (SupplierId int REFERENCES dbo.Supplier, ProductId int REFERENCES dbo.Product, PRIMARY KEY(SupplierId,ProductId));
CREATE TABLE rel.SupplierPurchaseOrder (SupplierId int REFERENCES dbo.Supplier, PurchaseOrderId int REFERENCES dbo.PurchaseOrder UNIQUE, PRIMARY KEY(SupplierId,PurchaseOrderId));
CREATE TABLE rel.EmployeePurchaseOrder (EmployeeId int REFERENCES dbo.Employee, PurchaseOrderId int REFERENCES dbo.PurchaseOrder UNIQUE, PRIMARY KEY(EmployeeId,PurchaseOrderId));
CREATE TABLE rel.PurchaseOrderPurchaseOrderLine (PurchaseOrderId int REFERENCES dbo.PurchaseOrder, PurchaseOrderLineId int REFERENCES dbo.PurchaseOrderLine UNIQUE, PRIMARY KEY(PurchaseOrderId,PurchaseOrderLineId));
CREATE TABLE rel.ProductPurchaseOrderLine (ProductId int REFERENCES dbo.Product, PurchaseOrderLineId int REFERENCES dbo.PurchaseOrderLine UNIQUE, PRIMARY KEY(ProductId,PurchaseOrderLineId));
CREATE TABLE rel.GoodsReceiptGoodsReceiptLine (GoodsReceiptId int REFERENCES dbo.GoodsReceipt, GoodsReceiptLineId int REFERENCES dbo.GoodsReceiptLine UNIQUE, PRIMARY KEY(GoodsReceiptId,GoodsReceiptLineId));
CREATE TABLE rel.PurchaseOrderLineGoodsReceiptLine (PurchaseOrderLineId int REFERENCES dbo.PurchaseOrderLine, GoodsReceiptLineId int REFERENCES dbo.GoodsReceiptLine UNIQUE, PRIMARY KEY(PurchaseOrderLineId,GoodsReceiptLineId));
CREATE TABLE rel.WarehouseGoodsReceipt (WarehouseId int REFERENCES dbo.Warehouse, GoodsReceiptId int REFERENCES dbo.GoodsReceipt UNIQUE, PRIMARY KEY(WarehouseId,GoodsReceiptId));
CREATE TABLE rel.EmployeeGoodsReceipt (EmployeeId int REFERENCES dbo.Employee, GoodsReceiptId int REFERENCES dbo.GoodsReceipt UNIQUE, PRIMARY KEY(EmployeeId,GoodsReceiptId));
CREATE TABLE rel.SalesOrderShipment (SalesOrderId int REFERENCES dbo.SalesOrder, ShipmentId int REFERENCES dbo.Shipment UNIQUE, PRIMARY KEY(SalesOrderId,ShipmentId));
CREATE TABLE rel.WarehouseShipment (WarehouseId int REFERENCES dbo.Warehouse, ShipmentId int REFERENCES dbo.Shipment UNIQUE, PRIMARY KEY(WarehouseId,ShipmentId));
CREATE TABLE rel.EmployeeShipment (EmployeeId int REFERENCES dbo.Employee, ShipmentId int REFERENCES dbo.Shipment UNIQUE, PRIMARY KEY(EmployeeId,ShipmentId));
CREATE TABLE rel.ShipmentShipmentLine (ShipmentId int REFERENCES dbo.Shipment, ShipmentLineId int REFERENCES dbo.ShipmentLine UNIQUE, PRIMARY KEY(ShipmentId,ShipmentLineId));
CREATE TABLE rel.SalesOrderLineShipmentLine (SalesOrderLineId int REFERENCES dbo.SalesOrderLine, ShipmentLineId int REFERENCES dbo.ShipmentLine UNIQUE, PRIMARY KEY(SalesOrderLineId,ShipmentLineId));
CREATE TABLE rel.PaymentSalesOrder
(
    PaymentId int NOT NULL REFERENCES dbo.Payment,
    SalesOrderId int NOT NULL REFERENCES dbo.SalesOrder,
    AllocatedAmount decimal(16,4) NOT NULL CHECK (AllocatedAmount > 0),
    PRIMARY KEY(PaymentId,SalesOrderId)
);
CREATE TABLE rel.SalesReturnSalesReturnLine (SalesReturnId int REFERENCES dbo.SalesReturn, SalesReturnLineId int REFERENCES dbo.SalesReturnLine UNIQUE, PRIMARY KEY(SalesReturnId,SalesReturnLineId));
CREATE TABLE rel.ShipmentLineSalesReturnLine (ShipmentLineId int REFERENCES dbo.ShipmentLine, SalesReturnLineId int REFERENCES dbo.SalesReturnLine UNIQUE, PRIMARY KEY(ShipmentLineId,SalesReturnLineId));
CREATE TABLE rel.SalesReturnLinePayment
(
    SalesReturnLineId int NOT NULL REFERENCES dbo.SalesReturnLine,
    PaymentId int NOT NULL REFERENCES dbo.Payment,
    RefundedAmount decimal(16,4) NOT NULL CHECK(RefundedAmount>0),
    PRIMARY KEY(SalesReturnLineId,PaymentId)
);
CREATE TABLE rel.ProductWarehouse (ProductId int REFERENCES dbo.Product, WarehouseId int REFERENCES dbo.Warehouse, PRIMARY KEY(ProductId,WarehouseId));
CREATE TABLE rel.ProductStockMovement (ProductId int REFERENCES dbo.Product, StockMovementId int REFERENCES dbo.StockMovement UNIQUE, PRIMARY KEY(ProductId,StockMovementId));
CREATE TABLE rel.WarehouseStockMovement (WarehouseId int REFERENCES dbo.Warehouse, StockMovementId int REFERENCES dbo.StockMovement UNIQUE, PRIMARY KEY(WarehouseId,StockMovementId));
CREATE TABLE rel.GoodsReceiptLineStockMovement (GoodsReceiptLineId int REFERENCES dbo.GoodsReceiptLine, StockMovementId int REFERENCES dbo.StockMovement UNIQUE, PRIMARY KEY(GoodsReceiptLineId,StockMovementId));
CREATE TABLE rel.ShipmentLineStockMovement (ShipmentLineId int REFERENCES dbo.ShipmentLine, StockMovementId int REFERENCES dbo.StockMovement UNIQUE, PRIMARY KEY(ShipmentLineId,StockMovementId));
CREATE TABLE rel.SalesReturnLineStockMovement (SalesReturnLineId int REFERENCES dbo.SalesReturnLine, StockMovementId int REFERENCES dbo.StockMovement UNIQUE, PRIMARY KEY(SalesReturnLineId,StockMovementId));
CREATE TABLE rel.WarehouseStockCount (WarehouseId int REFERENCES dbo.Warehouse, StockCountId int REFERENCES dbo.StockCount UNIQUE, PRIMARY KEY(WarehouseId,StockCountId));
CREATE TABLE rel.EmployeeStockCount (EmployeeId int REFERENCES dbo.Employee, StockCountId int REFERENCES dbo.StockCount UNIQUE, PRIMARY KEY(EmployeeId,StockCountId));
CREATE TABLE rel.StockCountStockCountLine (StockCountId int REFERENCES dbo.StockCount, StockCountLineId int REFERENCES dbo.StockCountLine UNIQUE, PRIMARY KEY(StockCountId,StockCountLineId));
CREATE TABLE rel.ProductStockCountLine (ProductId int REFERENCES dbo.Product, StockCountLineId int REFERENCES dbo.StockCountLine UNIQUE, PRIMARY KEY(ProductId,StockCountLineId));
CREATE TABLE audit.ProductAuditEvent (ProductId int REFERENCES dbo.Product, AuditEventId bigint REFERENCES audit.AuditEvent UNIQUE, PRIMARY KEY(ProductId,AuditEventId));
GO

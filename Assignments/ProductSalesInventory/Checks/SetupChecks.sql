-- Public baseline integrity checks; no instructor solution objects are required.
USE ProductSalesInventory;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Product')
    THROW 51000, 'Product schema is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Product)
    THROW 51001, 'Product seed is missing.', 1;
IF (SELECT COUNT_BIG(*) FROM dbo.SalesOrder) < 10000
    THROW 51002, 'Expected at least 10,000 source orders.', 1;
IF (SELECT COUNT_BIG(*) FROM dbo.SalesOrderLine) < 40000
    THROW 51003, 'Expected at least 40,000 source lines.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.indexes i ON i.object_id = t.object_id AND i.is_primary_key = 1
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE (s.name = N'dbo' OR (s.name = N'audit' AND t.name = N'AuditEvent'))
      AND c.is_identity = 0
)
    THROW 51004, 'Entity primary keys must be identity columns.', 1;

IF EXISTS
(
    SELECT 1 FROM dbo.SalesOrderLine l
    LEFT JOIN rel.SalesOrderSalesOrderLine ol ON ol.SalesOrderLineId = l.SalesOrderLineId
    LEFT JOIN rel.ProductSalesOrderLine pl ON pl.SalesOrderLineId = l.SalesOrderLineId
    WHERE ol.SalesOrderId IS NULL OR pl.ProductId IS NULL
)
    THROW 51005, 'A sales line is missing a required relationship.', 1;

IF EXISTS
(
    SELECT 1 FROM rel.PaymentSalesOrder a
    JOIN dbo.Payment p ON p.PaymentId = a.PaymentId
    GROUP BY p.PaymentId, p.Amount
    HAVING SUM(a.AllocatedAmount) > p.Amount
)
    THROW 51006, 'Payment allocations exceed payment amounts.', 1;

IF EXISTS
(
    SELECT 1 FROM reporting.v_OrderBalance WHERE Balance < 0
)
    THROW 51007, 'An order is overpaid.', 1;

IF EXISTS (SELECT 1 FROM reporting.v_StockOnHand WHERE QuantityOnHand < 0)
    THROW 51008, 'Stock cannot be negative.', 1;

IF EXISTS
(
    SELECT 1 FROM dbo.StockCountLine c
    JOIN rel.ProductStockCountLine pc ON pc.StockCountLineId = c.StockCountLineId
    JOIN rel.StockCountStockCountLine cc ON cc.StockCountLineId = c.StockCountLineId
    JOIN dbo.StockCount h ON h.StockCountId = cc.StockCountId
    JOIN rel.WarehouseStockCount wc ON wc.StockCountId = h.StockCountId
    OUTER APPLY
    (
        SELECT SUM(m.QuantityChange) AS Quantity
        FROM dbo.StockMovement m
        JOIN rel.ProductStockMovement pm ON pm.StockMovementId = m.StockMovementId
        JOIN rel.WarehouseStockMovement wm ON wm.StockMovementId = m.StockMovementId
        WHERE pm.ProductId = pc.ProductId AND wm.WarehouseId = wc.WarehouseId
          AND m.OccurredAt <= h.CountedAt
    ) q
    WHERE c.CountedQuantity <> COALESCE(q.Quantity, 0)
)
    THROW 51009, 'A physical count does not reconcile to the ledger.', 1;

IF (SELECT COUNT(*) FROM reporting.v_BusinessAnomalies) <> 2
    THROW 51010, 'Expected exactly two documented anomaly cases.', 1;

IF EXISTS
(
    SELECT 1 FROM sys.indexes i
    JOIN sys.tables t ON t.object_id=i.object_id
    JOIN sys.schemas s ON s.schema_id=t.schema_id
    JOIN sys.index_columns c ON c.object_id=i.object_id AND c.index_id=i.index_id AND c.key_ordinal>0
    WHERE i.is_unique=1 AND (s.name='dbo' OR (s.name='audit' AND t.name='AuditEvent'))
    GROUP BY i.object_id,i.index_id HAVING COUNT(*)>1
)
    THROW 51011, 'Composite entity candidate keys are not permitted.', 1;
IF EXISTS
(
    SELECT 1 FROM sys.foreign_keys f
    WHERE OBJECT_SCHEMA_NAME(f.parent_object_id)='dbo' AND
        (OBJECT_SCHEMA_NAME(f.referenced_object_id)<>'dbo' OR OBJECT_NAME(f.referenced_object_id)
        NOT IN ('OrderStatus','MovementType','PaymentMethod'))
)
    THROW 51012, 'A non-lookup entity relationship bypasses a bridge.', 1;

DECLARE @Required TABLE(EntityName sysname,BridgeName nvarchar(200),KeyName sysname);
INSERT @Required VALUES
('ProductPrice','rel.ProductProductPrice','ProductPriceId'),
('SalesOrder','rel.CustomerSalesOrder','SalesOrderId'),
('PurchaseOrder','rel.SupplierPurchaseOrder','PurchaseOrderId'),
('PurchaseOrderLine','rel.PurchaseOrderPurchaseOrderLine','PurchaseOrderLineId'),
('PurchaseOrderLine','rel.ProductPurchaseOrderLine','PurchaseOrderLineId'),
('GoodsReceipt','rel.WarehouseGoodsReceipt','GoodsReceiptId'),
('GoodsReceiptLine','rel.GoodsReceiptGoodsReceiptLine','GoodsReceiptLineId'),
('GoodsReceiptLine','rel.PurchaseOrderLineGoodsReceiptLine','GoodsReceiptLineId'),
('GoodsReceiptLine','rel.GoodsReceiptLineStockMovement','GoodsReceiptLineId'),
('Shipment','rel.SalesOrderShipment','ShipmentId'),
('Shipment','rel.WarehouseShipment','ShipmentId'),
('ShipmentLine','rel.ShipmentShipmentLine','ShipmentLineId'),
('ShipmentLine','rel.SalesOrderLineShipmentLine','ShipmentLineId'),
('ShipmentLine','rel.ShipmentLineStockMovement','ShipmentLineId'),
('Payment','rel.PaymentSalesOrder','PaymentId'),
('SalesReturnLine','rel.SalesReturnSalesReturnLine','SalesReturnLineId'),
('SalesReturnLine','rel.ShipmentLineSalesReturnLine','SalesReturnLineId'),
('SalesReturnLine','rel.SalesReturnLinePayment','SalesReturnLineId'),
('SalesReturnLine','rel.SalesReturnLineStockMovement','SalesReturnLineId'),
('StockMovement','rel.ProductStockMovement','StockMovementId'),
('StockMovement','rel.WarehouseStockMovement','StockMovementId'),
('StockCount','rel.WarehouseStockCount','StockCountId'),
('StockCountLine','rel.StockCountStockCountLine','StockCountLineId'),
('StockCountLine','rel.ProductStockCountLine','StockCountLineId');
DECLARE @Entity sysname,@Bridge nvarchar(200),@Key sysname,@Sql nvarchar(max);
DECLARE RequiredRelationships CURSOR LOCAL FAST_FORWARD FOR SELECT EntityName,BridgeName,KeyName FROM @Required;
OPEN RequiredRelationships;
FETCH NEXT FROM RequiredRelationships INTO @Entity,@Bridge,@Key;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @Sql=N'IF EXISTS(SELECT 1 FROM dbo.'+QUOTENAME(@Entity)+N' e WHERE NOT EXISTS(SELECT 1 FROM '+
        @Bridge+N' b WHERE b.'+QUOTENAME(@Key)+N'=e.'+QUOTENAME(@Key)+N')) THROW 51013,''Required bridge participation missing.'',1;';
    EXEC sys.sp_executesql @Sql;
    FETCH NEXT FROM RequiredRelationships INTO @Entity,@Bridge,@Key;
END;
CLOSE RequiredRelationships;
DEALLOCATE RequiredRelationships;

IF EXISTS
(
    SELECT 1 FROM dbo.StockMovement m JOIN dbo.MovementType t ON t.MovementTypeId=m.MovementTypeId
    WHERE SIGN(m.QuantityChange)<>t.Direction
)
    THROW 51014,'Movement sign conflicts with its type.',1;
IF EXISTS
(
    SELECT 1 FROM dbo.StockMovement m
    LEFT JOIN rel.GoodsReceiptLineStockMovement r ON r.StockMovementId=m.StockMovementId
    LEFT JOIN rel.ShipmentLineStockMovement s ON s.StockMovementId=m.StockMovementId
    LEFT JOIN rel.SalesReturnLineStockMovement x ON x.StockMovementId=m.StockMovementId
    WHERE (CASE WHEN r.StockMovementId IS NULL THEN 0 ELSE 1 END+
           CASE WHEN s.StockMovementId IS NULL THEN 0 ELSE 1 END+
           CASE WHEN x.StockMovementId IS NULL THEN 0 ELSE 1 END)<>1
)
    THROW 51015,'Baseline movements must have exactly one typed source.',1;
IF EXISTS
(
    SELECT r.GoodsReceiptLineId FROM dbo.GoodsReceiptLine r
    JOIN rel.GoodsReceiptLineStockMovement rm ON rm.GoodsReceiptLineId=r.GoodsReceiptLineId
    JOIN dbo.StockMovement m ON m.StockMovementId=rm.StockMovementId
    GROUP BY r.GoodsReceiptLineId,r.Quantity HAVING SUM(m.QuantityChange)<>r.Quantity
)
    THROW 51016,'Receipt movement quantities do not reconcile.',1;
IF EXISTS
(
    SELECT s.ShipmentLineId FROM dbo.ShipmentLine s
    JOIN rel.ShipmentLineStockMovement sm ON sm.ShipmentLineId=s.ShipmentLineId
    JOIN dbo.StockMovement m ON m.StockMovementId=sm.StockMovementId
    GROUP BY s.ShipmentLineId,s.Quantity HAVING -SUM(m.QuantityChange)<>s.Quantity
)
    THROW 51017,'Shipment movement quantities do not reconcile.',1;
IF EXISTS
(
    SELECT r.SalesReturnLineId FROM dbo.SalesReturnLine r
    JOIN rel.SalesReturnLineStockMovement rm ON rm.SalesReturnLineId=r.SalesReturnLineId
    JOIN dbo.StockMovement m ON m.StockMovementId=rm.StockMovementId
    GROUP BY r.SalesReturnLineId,r.Quantity HAVING SUM(m.QuantityChange)<>r.Quantity
)
    THROW 51018,'Return movement quantities do not reconcile.',1;
IF EXISTS
(
    SELECT l.SalesOrderLineId FROM dbo.SalesOrderLine l
    JOIN rel.SalesOrderLineShipmentLine x ON x.SalesOrderLineId=l.SalesOrderLineId
    JOIN dbo.ShipmentLine s ON s.ShipmentLineId=x.ShipmentLineId
    GROUP BY l.SalesOrderLineId,l.Quantity HAVING SUM(s.Quantity)>l.Quantity
)
    THROW 51019,'A line has been overshipped.',1;
IF EXISTS
(
    SELECT s.ShipmentLineId FROM dbo.ShipmentLine s
    JOIN rel.ShipmentLineSalesReturnLine x ON x.ShipmentLineId=s.ShipmentLineId
    JOIN dbo.SalesReturnLine r ON r.SalesReturnLineId=x.SalesReturnLineId
    GROUP BY s.ShipmentLineId,s.Quantity HAVING SUM(r.Quantity)>s.Quantity
)
    THROW 51020,'A shipment has been overreturned.',1;
IF EXISTS
(
    SELECT 1 FROM
    (
        SELECT SUM(m.QuantityChange) OVER(PARTITION BY p.ProductId,w.WarehouseId
            ORDER BY m.OccurredAt,m.StockMovementId ROWS UNBOUNDED PRECEDING) AS RunningQuantity
        FROM dbo.StockMovement m
        JOIN rel.ProductStockMovement p ON p.StockMovementId=m.StockMovementId
        JOIN rel.WarehouseStockMovement w ON w.StockMovementId=m.StockMovementId
    ) q WHERE RunningQuantity<0
)
    THROW 51021,'Historical stock becomes negative.',1;
IF (SELECT SUM(LineAmount) FROM reporting.v_SalesDetail)<>4471666.4700
    THROW 51022,'Seed sales total differs from independently imported source less authorized discount.',1;
IF (SELECT SUM(QuantityOnHand) FROM reporting.v_StockOnHand)<>39106
    THROW 51023,'Seed inventory total differs from explicit physical counts.',1;

IF EXISTS
(
    SELECT r.SalesReturnLineId FROM dbo.SalesReturnLine r
    JOIN rel.SalesReturnLinePayment p ON p.SalesReturnLineId=r.SalesReturnLineId
    GROUP BY r.SalesReturnLineId,r.RefundAmount HAVING SUM(p.RefundedAmount)<>r.RefundAmount
) OR EXISTS
(
    SELECT p.PaymentId FROM dbo.Payment p
    JOIN rel.SalesReturnLinePayment r ON r.PaymentId=p.PaymentId
    GROUP BY p.PaymentId,p.Amount HAVING SUM(r.RefundedAmount)>p.Amount
)
    THROW 51024,'Refund allocations disagree with return amounts or exceed original payments.',1;

IF EXISTS
(
    SELECT 1 FROM rel.GoodsReceiptLineStockMovement rm
    JOIN rel.PurchaseOrderLineGoodsReceiptLine pr ON pr.GoodsReceiptLineId=rm.GoodsReceiptLineId
    JOIN rel.ProductPurchaseOrderLine pp ON pp.PurchaseOrderLineId=pr.PurchaseOrderLineId
    JOIN rel.ProductStockMovement pm ON pm.StockMovementId=rm.StockMovementId
    JOIN rel.GoodsReceiptGoodsReceiptLine rr ON rr.GoodsReceiptLineId=rm.GoodsReceiptLineId
    JOIN rel.WarehouseGoodsReceipt rw ON rw.GoodsReceiptId=rr.GoodsReceiptId
    JOIN rel.WarehouseStockMovement mw ON mw.StockMovementId=rm.StockMovementId
    WHERE pm.ProductId<>pp.ProductId OR mw.WarehouseId<>rw.WarehouseId
) OR EXISTS
(
    SELECT 1 FROM rel.ShipmentLineStockMovement sm
    JOIN rel.SalesOrderLineShipmentLine ls ON ls.ShipmentLineId=sm.ShipmentLineId
    JOIN rel.ProductSalesOrderLine lp ON lp.SalesOrderLineId=ls.SalesOrderLineId
    JOIN rel.ProductStockMovement pm ON pm.StockMovementId=sm.StockMovementId
    JOIN rel.ShipmentShipmentLine ss ON ss.ShipmentLineId=sm.ShipmentLineId
    JOIN rel.WarehouseShipment sw ON sw.ShipmentId=ss.ShipmentId
    JOIN rel.WarehouseStockMovement mw ON mw.StockMovementId=sm.StockMovementId
    JOIN rel.SalesOrderShipment os ON os.ShipmentId=ss.ShipmentId
    JOIN rel.SalesOrderSalesOrderLine ol ON ol.SalesOrderLineId=ls.SalesOrderLineId
    WHERE pm.ProductId<>lp.ProductId OR mw.WarehouseId<>sw.WarehouseId OR os.SalesOrderId<>ol.SalesOrderId
) OR EXISTS
(
    SELECT 1 FROM rel.SalesReturnLineStockMovement rm
    JOIN rel.ShipmentLineSalesReturnLine sr ON sr.SalesReturnLineId=rm.SalesReturnLineId
    JOIN rel.SalesOrderLineShipmentLine ls ON ls.ShipmentLineId=sr.ShipmentLineId
    JOIN rel.ProductSalesOrderLine lp ON lp.SalesOrderLineId=ls.SalesOrderLineId
    JOIN rel.ProductStockMovement pm ON pm.StockMovementId=rm.StockMovementId
    WHERE pm.ProductId<>lp.ProductId
)
    THROW 51025,'A stock movement disagrees with its source product, location, or order.',1;
IF EXISTS
(
    SELECT 1 FROM dbo.StockMovement m
    JOIN rel.ProductStockMovement pm ON pm.StockMovementId=m.StockMovementId
    JOIN rel.WarehouseStockMovement wm ON wm.StockMovementId=m.StockMovementId
    LEFT JOIN rel.ProductWarehouse pw ON pw.ProductId=pm.ProductId AND pw.WarehouseId=wm.WarehouseId
    WHERE pw.ProductId IS NULL
)
    THROW 51026,'A movement lacks an eligible product/warehouse position.',1;

IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1)
   OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE is_disabled=1 OR is_not_trusted=1)
    THROW 51027,'An integrity constraint is disabled or untrusted.',1;
IF EXISTS
(
    SELECT 1 FROM sys.tables t
    WHERE (SCHEMA_NAME(t.schema_id)='dbo' OR (SCHEMA_NAME(t.schema_id)='audit' AND t.name='AuditEvent'))
      AND NOT EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=t.object_id AND i.is_primary_key=1)
)
    THROW 51028,'An entity is missing its primary key.',1;
IF EXISTS
(
    SELECT 1 FROM sys.tables t
    WHERE (SCHEMA_NAME(t.schema_id)='rel' OR (SCHEMA_NAME(t.schema_id)='audit' AND t.name='ProductAuditEvent'))
      AND ((SELECT COUNT(*) FROM sys.indexes i JOIN sys.index_columns c ON c.object_id=i.object_id AND c.index_id=i.index_id
            WHERE i.object_id=t.object_id AND i.is_primary_key=1 AND c.key_ordinal>0)<>2
           OR EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=t.object_id AND c.is_identity=1))
)
    THROW 51029,'A baseline bridge must have two composite key columns and no identity.',1;
IF EXISTS
(
    SELECT p.PurchaseOrderLineId FROM dbo.PurchaseOrderLine p
    JOIN rel.PurchaseOrderLineGoodsReceiptLine x ON x.PurchaseOrderLineId=p.PurchaseOrderLineId
    JOIN dbo.GoodsReceiptLine r ON r.GoodsReceiptLineId=x.GoodsReceiptLineId
    GROUP BY p.PurchaseOrderLineId,p.Quantity HAVING SUM(r.Quantity)>p.Quantity
)
    THROW 51030,'Receipts exceed purchased quantities.',1;
IF EXISTS
(
    SELECT 1 FROM rel.SalesReturnLinePayment rp
    JOIN rel.ShipmentLineSalesReturnLine sr ON sr.SalesReturnLineId=rp.SalesReturnLineId
    JOIN rel.SalesOrderLineShipmentLine ls ON ls.ShipmentLineId=sr.ShipmentLineId
    JOIN rel.SalesOrderSalesOrderLine ol ON ol.SalesOrderLineId=ls.SalesOrderLineId
    WHERE NOT EXISTS(SELECT 1 FROM rel.PaymentSalesOrder a WHERE a.PaymentId=rp.PaymentId AND a.SalesOrderId=ol.SalesOrderId)
)
    THROW 51031,'A refund references a payment for a different order.',1;

DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
SELECT s.name AS SchemaName, t.name AS TableName, SUM(p.rows) AS [RowCount]
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
PRINT 'Setup checks passed.';

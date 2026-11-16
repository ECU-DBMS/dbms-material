CREATE OR ALTER TRIGGER dbo.tr_Product_Audit
ON dbo.Product AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Events TABLE(AuditEventId bigint, ProductId int);
    INSERT audit.AuditEvent(Operation,OriginalLogin,ExecutionUser,OldValue,NewValue)
    OUTPUT inserted.AuditEventId, CONVERT(int,JSON_VALUE(inserted.NewValue,'$.ProductId'))
        INTO @Events(AuditEventId,ProductId)
    SELECT CASE WHEN d.ProductId IS NULL THEN 'INSERT' ELSE 'UPDATE' END,
        ORIGINAL_LOGIN(),USER_NAME(),
        CASE WHEN d.ProductId IS NULL THEN NULL ELSE
            (SELECT d.ProductId,d.ProductCode,d.ProductName,d.IsActive FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) END,
        (SELECT i.ProductId,i.ProductCode,i.ProductName,i.IsActive FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
    FROM inserted i LEFT JOIN deleted d ON d.ProductId=i.ProductId;
    INSERT audit.ProductAuditEvent(ProductId,AuditEventId)
    SELECT ProductId,AuditEventId FROM @Events;
END;
GO
CREATE OR ALTER VIEW reporting.v_SalesDetail
AS
SELECT o.SalesOrderId,o.OrderNumber,o.OrderedAt,c.CustomerId,c.CustomerCode,
    l.SalesOrderLineId,l.SourceLineCode,p.ProductId,p.ProductCode,p.ProductName,
    l.Quantity,l.UnitPrice,l.DiscountAmount,
    CONVERT(decimal(19,4),l.Quantity*l.UnitPrice-l.DiscountAmount) AS LineAmount
FROM dbo.SalesOrder o
JOIN rel.CustomerSalesOrder co ON co.SalesOrderId=o.SalesOrderId
JOIN dbo.Customer c ON c.CustomerId=co.CustomerId
JOIN rel.SalesOrderSalesOrderLine ol ON ol.SalesOrderId=o.SalesOrderId
JOIN dbo.SalesOrderLine l ON l.SalesOrderLineId=ol.SalesOrderLineId
JOIN rel.ProductSalesOrderLine pl ON pl.SalesOrderLineId=l.SalesOrderLineId
JOIN dbo.Product p ON p.ProductId=pl.ProductId;
GO
CREATE OR ALTER VIEW reporting.v_OrderBalance
AS
WITH Totals AS
(
    SELECT SalesOrderId,SUM(LineAmount) AS TotalAmount
    FROM reporting.v_SalesDetail GROUP BY SalesOrderId
),
Payments AS
(
    SELECT SalesOrderId,SUM(AllocatedAmount) AS PaidAmount
    FROM rel.PaymentSalesOrder GROUP BY SalesOrderId
),
Refunds AS
(
    SELECT os.SalesOrderId,SUM(r.RefundAmount) AS RefundAmount
    FROM dbo.SalesReturnLine r
    JOIN rel.ShipmentLineSalesReturnLine sr ON sr.SalesReturnLineId=r.SalesReturnLineId
    JOIN rel.SalesOrderLineShipmentLine ls ON ls.ShipmentLineId=sr.ShipmentLineId
    JOIN rel.SalesOrderSalesOrderLine os ON os.SalesOrderLineId=ls.SalesOrderLineId
    GROUP BY os.SalesOrderId
)
SELECT o.SalesOrderId,o.OrderNumber,CONVERT(decimal(19,4),COALESCE(t.TotalAmount,0)) AS TotalAmount,
    CONVERT(decimal(19,4),COALESCE(p.PaidAmount,0)) AS PaidAmount,
    CONVERT(decimal(19,4),COALESCE(r.RefundAmount,0)) AS RefundAmount,
    CONVERT(decimal(19,4),COALESCE(t.TotalAmount,0)-COALESCE(r.RefundAmount,0)) AS NetSales,
    CONVERT(decimal(19,4),COALESCE(p.PaidAmount,0)-COALESCE(r.RefundAmount,0)) AS NetReceipts,
    CONVERT(decimal(19,4),COALESCE(t.TotalAmount,0)-COALESCE(p.PaidAmount,0)) AS Balance
FROM dbo.SalesOrder o
LEFT JOIN Totals t ON t.SalesOrderId=o.SalesOrderId
LEFT JOIN Payments p ON p.SalesOrderId=o.SalesOrderId
LEFT JOIN Refunds r ON r.SalesOrderId=o.SalesOrderId;
GO
CREATE OR ALTER VIEW reporting.v_StockOnHand
AS
SELECT p.ProductId,p.ProductCode,w.WarehouseId,w.WarehouseCode,
    COALESCE(SUM(m.QuantityChange),0) AS QuantityOnHand
FROM rel.ProductWarehouse pw
JOIN dbo.Product p ON p.ProductId=pw.ProductId
JOIN dbo.Warehouse w ON w.WarehouseId=pw.WarehouseId
LEFT JOIN
(
    dbo.StockMovement m
    JOIN rel.ProductStockMovement pm ON pm.StockMovementId=m.StockMovementId
    JOIN rel.WarehouseStockMovement wm ON wm.StockMovementId=m.StockMovementId
) ON pm.ProductId=p.ProductId AND wm.WarehouseId=w.WarehouseId
GROUP BY p.ProductId,p.ProductCode,w.WarehouseId,w.WarehouseCode;
GO
CREATE OR ALTER VIEW reporting.v_BusinessAnomalies
AS
SELECT CONVERT(varchar(30),'LATE_RECEIPT') AS AnomalyType,
    CONVERT(varchar(40),p.PurchaseOrderNumber) AS BusinessCode,
    CONVERT(decimal(19,4),DATEDIFF(day,p.ExpectedAt,r.ReceivedAt)) AS Measure
FROM dbo.PurchaseOrder p
JOIN rel.PurchaseOrderPurchaseOrderLine po ON po.PurchaseOrderId=p.PurchaseOrderId
JOIN rel.PurchaseOrderLineGoodsReceiptLine pr ON pr.PurchaseOrderLineId=po.PurchaseOrderLineId
JOIN rel.GoodsReceiptGoodsReceiptLine rr ON rr.GoodsReceiptLineId=pr.GoodsReceiptLineId
JOIN dbo.GoodsReceipt r ON r.GoodsReceiptId=rr.GoodsReceiptId
WHERE r.ReceivedAt>p.ExpectedAt
UNION ALL
SELECT 'DEEP_DISCOUNT',SourceLineCode,
    CONVERT(decimal(19,4),100.0*DiscountAmount/(Quantity*UnitPrice))
FROM dbo.SalesOrderLine WHERE DiscountAmount>Quantity*UnitPrice*0.5;
GO
CREATE OR ALTER FUNCTION lab.ufn_ProductMonthAmount(@ProductId int,@Year int,@Month int)
RETURNS decimal(38,4)
WITH INLINE=OFF
AS
BEGIN
    DECLARE @Amount decimal(38,4);
    SELECT @Amount=SUM(LineAmount) FROM reporting.v_SalesDetail
    WHERE ProductId=@ProductId AND YEAR(OrderedAt)=@Year AND MONTH(OrderedAt)=@Month;
    RETURN COALESCE(@Amount,0);
END;
GO
CREATE OR ALTER PROCEDURE lab.usp_MonthlyProductSales_Slow
    @Year int, @Month int
AS
BEGIN
    SET NOCOUNT ON;
    IF @Year IS NULL OR @Month IS NULL OR @Year NOT BETWEEN 2000 AND 2100 OR @Month NOT BETWEEN 1 AND 12
        THROW 51100,'Supply a valid report year and month.',1;
    SELECT ProductCode,SUM(Quantity) AS Units,
        lab.ufn_ProductMonthAmount(ProductId,@Year,@Month) AS SalesAmount
    FROM reporting.v_SalesDetail
    WHERE YEAR(OrderedAt)=@Year AND MONTH(OrderedAt)=@Month
    GROUP BY ProductId,ProductCode ORDER BY ProductCode;
END;
GO
CREATE OR ALTER PROCEDURE lab.usp_CustomerOrderSummary_Slow
    @From datetime2(0), @Until datetime2(0),
    @FirstCustomerCode varchar(30), @LastCustomerCode varchar(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF @From IS NULL OR @Until IS NULL OR @From>=@Until
       OR @FirstCustomerCode IS NULL OR @LastCustomerCode IS NULL
       OR @FirstCustomerCode>@LastCustomerCode
        THROW 51101,'Supply a nonempty half-open date range and ordered customer bounds.',1;
    CREATE TABLE #Results(CustomerCode varchar(30) PRIMARY KEY,
        OrderCount int NOT NULL,SalesAmount decimal(19,4) NOT NULL);
    DECLARE @CustomerCode varchar(30);
    DECLARE Customers CURSOR LOCAL FAST_FORWARD FOR
        SELECT CustomerCode FROM dbo.Customer
        WHERE CustomerCode BETWEEN @FirstCustomerCode AND @LastCustomerCode;
    OPEN Customers;
    FETCH NEXT FROM Customers INTO @CustomerCode;
    WHILE @@FETCH_STATUS=0
    BEGIN
        INSERT #Results(CustomerCode,OrderCount,SalesAmount)
        SELECT @CustomerCode,COUNT(DISTINCT SalesOrderId),COALESCE(SUM(LineAmount),0)
        FROM reporting.v_SalesDetail
        WHERE CustomerCode=@CustomerCode AND OrderedAt>=@From AND OrderedAt<@Until;
        FETCH NEXT FROM Customers INTO @CustomerCode;
    END;
    CLOSE Customers;
    DEALLOCATE Customers;
    SELECT CustomerCode,OrderCount,SalesAmount FROM #Results ORDER BY CustomerCode;
END;
GO

# ProductSalesInventory relationship diagrams

The [dictionary](ProductSalesInventory_DataDictionary.md) lists every column and bridge constraint; the [bridge DDL](ProductSalesInventory_Bridges.sql) is authoritative.

Every box with two entity IDs is an actual bridge table. Entities have single identity primary keys; bridges have composite primary keys. `||--o|` on a child side depicts the database's maximum-one bridge participation, not automatic required participation. Required rows are created atomically and checked separately. No diagram implies a hidden direct entity FK.

## Catalog, locations and product history

```mermaid
erDiagram
    Supplier ||--o{ SupplierProduct : supplies
    Product ||--o{ SupplierProduct : sourced_from
    Product ||--o{ ProductProductPrice : has
    ProductPrice ||--o| ProductProductPrice : belongs_to
    Product ||--o{ ProductWarehouse : eligible_at
    Warehouse ||--o{ ProductWarehouse : stocks
    Product ||--o{ ProductAuditEvent : audited
    AuditEvent ||--o| ProductAuditEvent : documents
```

`ProductAuditEvent` is in the `audit` schema; the other bridges are in `rel`. AuditEvent stores immutable snapshots and execution context. Historical line prices remain on the line entities rather than being recalculated from ProductPrice.

## Sales and payment allocation

```mermaid
erDiagram
    Customer ||--o{ CustomerSalesOrder : places
    SalesOrder ||--o| CustomerSalesOrder : placed_by
    Employee ||--o{ EmployeeSalesOrder : coordinates
    SalesOrder ||--o| EmployeeSalesOrder : assigned_to
    SalesOrder ||--o{ SalesOrderSalesOrderLine : contains
    SalesOrderLine ||--o| SalesOrderSalesOrderLine : belongs_to
    Product ||--o{ ProductSalesOrderLine : ordered_as
    SalesOrderLine ||--o| ProductSalesOrderLine : identifies
    Payment ||--o{ PaymentSalesOrder : allocated_through
    SalesOrder ||--o{ PaymentSalesOrder : paid_through
    OrderStatus ||--o{ SalesOrder : lookup_only
    PaymentMethod ||--o{ Payment : lookup_only
```

PaymentSalesOrder carries AllocatedAmount. An order can have several payments and a payment can cover several orders. Staff assignment is optional where the original demand source does not identify a responsible employee.

## Purchasing and receiving

```mermaid
erDiagram
    Supplier ||--o{ SupplierPurchaseOrder : receives
    PurchaseOrder ||--o| SupplierPurchaseOrder : ordered_from
    Employee ||--o{ EmployeePurchaseOrder : buys
    PurchaseOrder ||--o| EmployeePurchaseOrder : assigned_to
    PurchaseOrder ||--o{ PurchaseOrderPurchaseOrderLine : contains
    PurchaseOrderLine ||--o| PurchaseOrderPurchaseOrderLine : belongs_to
    Product ||--o{ ProductPurchaseOrderLine : purchased_as
    PurchaseOrderLine ||--o| ProductPurchaseOrderLine : identifies
    PurchaseOrderLine ||--o{ PurchaseOrderLineGoodsReceiptLine : received_in
    GoodsReceiptLine ||--o| PurchaseOrderLineGoodsReceiptLine : fulfills
    GoodsReceipt ||--o{ GoodsReceiptGoodsReceiptLine : contains
    GoodsReceiptLine ||--o| GoodsReceiptGoodsReceiptLine : belongs_to
    Warehouse ||--o{ WarehouseGoodsReceipt : receives_at
    GoodsReceipt ||--o| WarehouseGoodsReceipt : location
    Employee ||--o{ EmployeeGoodsReceipt : receives
    GoodsReceipt ||--o| EmployeeGoodsReceipt : checked_by
```

A purchase line may be received in multiple receipt lines. Quantity reconciliation is not inferred solely from the presence of bridges.

## Fulfillment and returns

```mermaid
erDiagram
    SalesOrder ||--o{ SalesOrderShipment : fulfilled_by
    Shipment ||--o| SalesOrderShipment : fulfills
    Warehouse ||--o{ WarehouseShipment : dispatches
    Shipment ||--o| WarehouseShipment : location
    Employee ||--o{ EmployeeShipment : picks
    Shipment ||--o| EmployeeShipment : assigned_to
    Shipment ||--o{ ShipmentShipmentLine : contains
    ShipmentLine ||--o| ShipmentShipmentLine : belongs_to
    SalesOrderLine ||--o{ SalesOrderLineShipmentLine : ships_in
    ShipmentLine ||--o| SalesOrderLineShipmentLine : fulfills
    ShipmentLine ||--o{ ShipmentLineSalesReturnLine : returned_as
    SalesReturnLine ||--o| ShipmentLineSalesReturnLine : originates_from
    SalesReturn ||--o{ SalesReturnSalesReturnLine : contains
    SalesReturnLine ||--o| SalesReturnSalesReturnLine : belongs_to
    SalesReturnLine ||--o{ SalesReturnLinePayment : refunds_against
    Payment ||--o{ SalesReturnLinePayment : original_receipt
```

SalesReturnLine.RefundAmount is the actual refunded amount in the seeded scenarios. Its payment bridge carries RefundedAmount and identifies the original payment; Payment.Amount remains the original incoming cash amount. Net receipts subtract refunds.

## Inventory ledger and physical counts

```mermaid
erDiagram
    Product ||--o{ ProductStockMovement : moves
    StockMovement ||--o| ProductStockMovement : product
    Warehouse ||--o{ WarehouseStockMovement : records
    StockMovement ||--o| WarehouseStockMovement : location
    GoodsReceiptLine ||--o{ GoodsReceiptLineStockMovement : produces
    StockMovement ||--o| GoodsReceiptLineStockMovement : receipt_source
    ShipmentLine ||--o{ ShipmentLineStockMovement : produces
    StockMovement ||--o| ShipmentLineStockMovement : shipment_source
    SalesReturnLine ||--o{ SalesReturnLineStockMovement : produces
    StockMovement ||--o| SalesReturnLineStockMovement : return_source
    MovementType ||--o{ StockMovement : lookup_only
    Warehouse ||--o{ WarehouseStockCount : counted_at
    StockCount ||--o| WarehouseStockCount : location
    Employee ||--o{ EmployeeStockCount : counts
    StockCount ||--o| EmployeeStockCount : assigned_to
    StockCount ||--o{ StockCountStockCountLine : contains
    StockCountLine ||--o| StockCountStockCountLine : belongs_to
    Product ||--o{ ProductStockCountLine : counted_as
    StockCountLine ||--o| ProductStockCountLine : product
```

A baseline movement has exactly one of the three typed source relationships. Its product and warehouse must agree with the source document. The movement sign must agree with MovementType.Direction. These invariants are verified by the setup checks; separate FK constraints alone cannot enforce exclusivity across three different bridges.

The three direct lookup arrows in these diagrams are the only exceptions to the all-bridges entity relationship rule.

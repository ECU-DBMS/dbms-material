/**
 * Public-record ingestion, not a random or formula-based business-data generator.
 * node BuildSeed.mjs <downloaded-UCI-data.csv>
 * Source dates, quantities and numeric prices are preserved, not inflated.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const csvPath = process.argv[2];
if (!csvPath) throw new Error('Supply the original UCI Online Retail CSV path.');
const text = fs.readFileSync(csvPath, 'utf8');
function parseCsv(input) {
  const rows = [];
  let row = [], field = '', quoted = false;
  for (let i = 0; i < input.length; i++) {
    const c = input[i];
    if (c === '"') {
      if (quoted && input[i + 1] === '"') { field += '"'; i++; }
      else quoted = !quoted;
    } else if (c === ',' && !quoted) { row.push(field); field = ''; }
    else if (c === '\n' && !quoted) {
      row.push(field.replace(/\r$/, '')); rows.push(row); row = []; field = '';
    } else field += c;
  }
  if (field || row.length) { row.push(field.replace(/\r$/, '')); rows.push(row); }
  return rows;
}
const rows = parseCsv(text);
if (rows[0].join(',') !== 'InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,CustomerID,Country')
  throw new Error('Unexpected public source columns.');
function isoDate(raw) {
  const m = /^(\d+)\/(\d+)\/(\d{4}) (\d+):(\d+)$/.exec(raw);
  if (!m) throw new Error(`Unexpected source timestamp: ${raw}`);
  const [, month, day, year, hour, minute] = m;
  return `${year}-${month.padStart(2,'0')}-${day.padStart(2,'0')}T${hour.padStart(2,'0')}:${minute}:00`;
}
const orders = new Map(), products = new Map(), customers = new Set(), lines = [];
let excluded = 0;
for (let i = 1; i < rows.length; i++) {
  const [invoice, sku, description, quantity, date, price, customer] = rows[i];
  if (!/^\d{6}$/.test(invoice ?? '') || !/^\d{5}[A-Z]?$/.test(sku ?? '') ||
      !description?.trim() || !customer || Number(quantity) <= 0 ||
      !Number.isInteger(Number(quantity)) || Number(price) <= 0) { excluded++; continue; }
  if (!orders.has(invoice) && orders.size >= 10000) continue;
  const at = isoDate(date);
  const existing = orders.get(invoice);
  if (existing && existing.customer !== customer)
    throw new Error(`Inconsistent invoice header ${invoice}.`);
  orders.set(invoice, {invoice, at: existing && existing.at < at ? existing.at : at, customer});
  customers.add(customer);
  if (!products.has(sku)) products.set(sku, {sku, name: description.trim(), at, price});
  lines.push({code: `UCI-${i}`, invoice, sku, quantity: Number(quantity), price, at});
}
if (orders.size !== 10000 || lines.length < 40000) throw new Error('Insufficient authentic workload.');
const quote = v => v == null ? 'NULL' : `N'${String(v).replaceAll("'", "''")}'`;
function inserts(table, columns, records, numeric = []) {
  let sql = '';
  for (let i = 0; i < records.length; i += 500) {
    sql += `INSERT INTO ${table} (${columns.join(',')}) VALUES\n`;
    sql += records.slice(i, i + 500).map(r =>
      `(${r.map((v,j) => numeric.includes(j) ? String(v) : quote(v)).join(',')})`).join(',\n') + ';\nGO\n';
  }
  return sql;
}
const seedDir = path.join(root, 'Seed');
fs.mkdirSync(seedDir, {recursive: true});
const header = `-- UCI Online Retail, Daqing Chen, DOI 10.24432/C5BW33, CC BY 4.0.\n` +
  `-- Source dates/quantities/numeric prices preserved. Fictional USD teaching adaptation;\n` +
  `-- original numeric prices were sterling; these are NOT represented as actual USD sales.\n` +
  `-- Country omitted. Customer codes are anonymized source identifiers, not invented names.\n`;
let catalog = header;
catalog += inserts('dbo.Product',['ProductCode','ProductName'], [...products.values()].map(p => [p.sku,p.name]));
catalog += inserts('dbo.Customer',['CustomerCode','DisplayName'], [...customers].map(c => [c,null]));
catalog += inserts('dbo.ProductPrice',['PriceCode','EffectiveFrom','UnitPrice'],
  [...products.values()].map(p => [`PRICE-${p.sku}`,p.at,p.price]),[2]);
catalog += `INSERT INTO rel.ProductProductPrice(ProductId,ProductPriceId)\n` +
  `SELECT p.ProductId,h.ProductPriceId FROM dbo.Product p JOIN dbo.ProductPrice h ON h.PriceCode = 'PRICE-' + p.ProductCode;\n`;
fs.writeFileSync(path.join(seedDir,'CatalogAndParties.sql'),catalog);
let sales = header;
sales += inserts('dbo.SalesOrder',['OrderNumber','OrderedAt','OrderStatusId'],
  [...orders.values()].map(o => [o.invoice,o.at,1]),[2]);
sales += inserts('dbo.SalesOrderLine',['SourceLineCode','SourceRecordedAt','Quantity','UnitPrice'],
  lines.map(l => [l.code,l.at,l.quantity,l.price]),[2,3]);
sales += `CREATE TABLE #SourceLineMap(SourceLineCode varchar(40) PRIMARY KEY, OrderNumber varchar(30), ProductCode varchar(30));\n`;
sales += inserts('#SourceLineMap',['SourceLineCode','OrderNumber','ProductCode'],lines.map(l => [l.code,l.invoice,l.sku]));
sales += `INSERT INTO rel.SalesOrderSalesOrderLine(SalesOrderId,SalesOrderLineId)\n` +
  `SELECT o.SalesOrderId,l.SalesOrderLineId FROM #SourceLineMap m JOIN dbo.SalesOrder o ON o.OrderNumber=m.OrderNumber JOIN dbo.SalesOrderLine l ON l.SourceLineCode=m.SourceLineCode;\n` +
  `INSERT INTO rel.ProductSalesOrderLine(ProductId,SalesOrderLineId)\n` +
  `SELECT p.ProductId,l.SalesOrderLineId FROM #SourceLineMap m JOIN dbo.Product p ON p.ProductCode=m.ProductCode JOIN dbo.SalesOrderLine l ON l.SourceLineCode=m.SourceLineCode;\nDROP TABLE #SourceLineMap;\n`;
sales += `CREATE TABLE #OrderCustomer(OrderNumber varchar(30) PRIMARY KEY,CustomerCode varchar(30));\n`;
sales += inserts('#OrderCustomer',['OrderNumber','CustomerCode'],[...orders.values()].map(o => [o.invoice,o.customer]));
sales += `INSERT INTO rel.CustomerSalesOrder(CustomerId,SalesOrderId)\nSELECT c.CustomerId,o.SalesOrderId FROM #OrderCustomer m JOIN dbo.Customer c ON c.CustomerCode=m.CustomerCode JOIN dbo.SalesOrder o ON o.OrderNumber=m.OrderNumber;\nDROP TABLE #OrderCustomer;\n`;
fs.writeFileSync(path.join(seedDir,'SalesAndFulfillment.sql'),sales);
const samples = [];
for (const l of lines) if (!samples.some(p => p.sku === l.sku) && samples.length < 200)
  samples.push({...l, name: products.get(l.sku).name});
const manifest = {
  source:'UCI Online Retail',author:'Daqing Chen',doi:'10.24432/C5BW33',
  license:'CC BY 4.0',sourceUrl:'https://archive.ics.uci.edu/static/public/352/data.csv',
  sha256:crypto.createHash('sha256').update(fs.readFileSync(csvPath)).digest('hex'),
  dates:[lines[0].at,lines.at(-1).at],orders:orders.size,lines:lines.length,
  products:products.size,customers:customers.size,excludedInvalidOrNonMerchandise:excluded,
  lineGross:lines.reduce((sum,l) => sum + BigInt(l.quantity) * BigInt(Math.round(Number(l.price)*10000)),0n).toString(),
  firstOrder:[...orders.values()][0],
  firstOrderLines:lines.filter(l=>l.invoice===lines[0].invoice),
  note:'Source invoices are modelled as accepted sales orders, not proof of settlement or delivery. Only explicitly authored operational scenarios are fulfilled.'
};
fs.writeFileSync(path.join(root,'SourceManifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({orders:manifest.orders,lines:manifest.lines,products:manifest.products,customers:manifest.customers,dates:manifest.dates}));

const fixtures = parseCsv(fs.readFileSync(path.join(root,'OperationalFixtures.csv'),'utf8')).slice(1);
if (fixtures.length !== 200 || new Set(fixtures.map(r=>r[0])).size !== 200)
  throw new Error('Exactly 200 individually authored operational records are required.');
for (const f of fixtures) {
  const source = samples.find(l=>l.code===f[0]);
  if (!source || Number(f[2]) < 1 || Number(f[3]) <= 0 ||
      Number(f[4]) < 0 || !['NOV15','NOV17','NOV18','NOV19'].includes(f[6]))
    throw new Error(`Invalid explicit operational fixture ${f[0]}.`);
}
let ops = `-- Explicit fictional operational records. Numeric values originate in OperationalFixtures.csv.\n` +
`-- These records are NOT generated by sampling prices, modulo arithmetic, randomization, or row expansion.\n` +
`CREATE TABLE #Ops(SourceLineCode varchar(40) PRIMARY KEY,PurchaseNumber varchar(30) UNIQUE,\n` +
`Quantity int,UnitCost decimal(12,4),CountedQuantity int,SupplierCode varchar(30),Batch varchar(10));\n`;
ops += inserts('#Ops',['SourceLineCode','PurchaseNumber','Quantity','UnitCost','CountedQuantity','SupplierCode','Batch'],
  fixtures,[2,3,4]);
ops += `
CREATE TABLE #Batch(Batch varchar(10) PRIMARY KEY,OrderedAt datetime2(0),ExpectedAt datetime2(0),ReceivedAt datetime2(0));
INSERT #Batch VALUES
('NOV15','20101115','20101122','20101122'),
('NOV17','20101117','20101124','20101124'),
('NOV18','20101118','20101126','20101126'),
('NOV19','20101119','20101129','20101129');
SELECT f.*,p.ProductId,l.SalesOrderLineId,o.SalesOrderId,l.UnitPrice,b.OrderedAt,b.ExpectedAt,b.ReceivedAt
INTO #Facts
FROM #Ops f JOIN dbo.SalesOrderLine l ON l.SourceLineCode=f.SourceLineCode
JOIN rel.ProductSalesOrderLine p ON p.SalesOrderLineId=l.SalesOrderLineId
JOIN rel.SalesOrderSalesOrderLine o ON o.SalesOrderLineId=l.SalesOrderLineId
JOIN #Batch b ON b.Batch=f.Batch;
IF (SELECT COUNT(*) FROM #Facts)<>200 THROW 51300,'Operational source references are missing.',1;

INSERT dbo.PurchaseOrder(PurchaseOrderNumber,OrderedAt,ExpectedAt)
SELECT PurchaseNumber,OrderedAt,CASE WHEN PurchaseNumber='PO-DOCK-001' THEN '20101119' ELSE ExpectedAt END FROM #Facts;
INSERT dbo.PurchaseOrderLine(PurchaseLineCode,Quantity,UnitCost)
SELECT PurchaseNumber,Quantity,UnitCost FROM #Facts;
INSERT rel.PurchaseOrderPurchaseOrderLine(PurchaseOrderId,PurchaseOrderLineId)
SELECT p.PurchaseOrderId,l.PurchaseOrderLineId FROM dbo.PurchaseOrder p
JOIN dbo.PurchaseOrderLine l ON l.PurchaseLineCode=p.PurchaseOrderNumber;
INSERT rel.ProductPurchaseOrderLine(ProductId,PurchaseOrderLineId)
SELECT f.ProductId,l.PurchaseOrderLineId FROM #Facts f JOIN dbo.PurchaseOrderLine l ON l.PurchaseLineCode=f.PurchaseNumber;
INSERT rel.SupplierPurchaseOrder(SupplierId,PurchaseOrderId)
SELECT s.SupplierId,p.PurchaseOrderId FROM #Facts f JOIN dbo.Supplier s ON s.SupplierCode=f.SupplierCode
JOIN dbo.PurchaseOrder p ON p.PurchaseOrderNumber=f.PurchaseNumber;
INSERT rel.EmployeePurchaseOrder(EmployeeId,PurchaseOrderId)
SELECT e.EmployeeId,p.PurchaseOrderId FROM dbo.PurchaseOrder p
JOIN dbo.Employee e ON e.EmployeeCode='BUYER-MORGAN';
INSERT rel.SupplierProduct(SupplierId,ProductId)
SELECT s.SupplierId,f.ProductId FROM #Facts f JOIN dbo.Supplier s ON s.SupplierCode=f.SupplierCode;
INSERT dbo.GoodsReceipt(ReceiptNumber,ReceivedAt) SELECT PurchaseNumber,ReceivedAt FROM #Facts;
INSERT dbo.GoodsReceiptLine(ReceiptLineCode,Quantity) SELECT PurchaseNumber,Quantity FROM #Facts;
INSERT rel.GoodsReceiptGoodsReceiptLine(GoodsReceiptId,GoodsReceiptLineId)
SELECT h.GoodsReceiptId,l.GoodsReceiptLineId FROM dbo.GoodsReceipt h JOIN dbo.GoodsReceiptLine l ON l.ReceiptLineCode=h.ReceiptNumber;
INSERT rel.PurchaseOrderLineGoodsReceiptLine(PurchaseOrderLineId,GoodsReceiptLineId)
SELECT p.PurchaseOrderLineId,r.GoodsReceiptLineId FROM dbo.PurchaseOrderLine p
JOIN dbo.GoodsReceiptLine r ON r.ReceiptLineCode=p.PurchaseLineCode;
INSERT rel.WarehouseGoodsReceipt(WarehouseId,GoodsReceiptId)
SELECT w.WarehouseId,r.GoodsReceiptId FROM dbo.GoodsReceipt r JOIN dbo.Warehouse w ON w.WarehouseCode='MAIN';
INSERT rel.EmployeeGoodsReceipt(EmployeeId,GoodsReceiptId)
SELECT e.EmployeeId,r.GoodsReceiptId FROM dbo.GoodsReceipt r JOIN dbo.Employee e ON e.EmployeeCode='RECEIVER-ELLIS';

-- A deliberately limited first-unit fulfillment wave, not a claim that the source invoices were delivered.
INSERT dbo.Shipment(ShipmentNumber,ShippedAt) SELECT PurchaseNumber,'2010-12-03T10:00:00' FROM #Facts;
INSERT dbo.ShipmentLine(ShipmentLineCode,Quantity) SELECT PurchaseNumber,1 FROM #Facts;
INSERT rel.ShipmentShipmentLine(ShipmentId,ShipmentLineId)
SELECT h.ShipmentId,l.ShipmentLineId FROM dbo.Shipment h JOIN dbo.ShipmentLine l ON l.ShipmentLineCode=h.ShipmentNumber;
INSERT rel.SalesOrderLineShipmentLine(SalesOrderLineId,ShipmentLineId)
SELECT f.SalesOrderLineId,l.ShipmentLineId FROM #Facts f JOIN dbo.ShipmentLine l ON l.ShipmentLineCode=f.PurchaseNumber;
INSERT rel.SalesOrderShipment(SalesOrderId,ShipmentId)
SELECT f.SalesOrderId,s.ShipmentId FROM #Facts f JOIN dbo.Shipment s ON s.ShipmentNumber=f.PurchaseNumber;
INSERT rel.WarehouseShipment(WarehouseId,ShipmentId)
SELECT w.WarehouseId,s.ShipmentId FROM dbo.Shipment s JOIN dbo.Warehouse w ON w.WarehouseCode='MAIN';
INSERT rel.EmployeeShipment(EmployeeId,ShipmentId)
SELECT e.EmployeeId,s.ShipmentId FROM dbo.Shipment s JOIN dbo.Employee e ON e.EmployeeCode='PICKER-AVERY';
INSERT rel.EmployeeSalesOrder(EmployeeId,SalesOrderId)
SELECT e.EmployeeId,f.SalesOrderId FROM (SELECT DISTINCT SalesOrderId FROM #Facts) f
JOIN dbo.Employee e ON e.EmployeeCode='SALES-JORDAN';
INSERT dbo.Payment(PaymentReference,PaidAt,Amount,PaymentMethodId)
SELECT f.PurchaseNumber,'2010-12-02T14:00:00',f.UnitPrice,m.PaymentMethodId
FROM #Facts f JOIN dbo.PaymentMethod m ON m.MethodName='Bank transfer';
INSERT rel.PaymentSalesOrder(PaymentId,SalesOrderId,AllocatedAmount)
SELECT p.PaymentId,f.SalesOrderId,p.Amount FROM #Facts f JOIN dbo.Payment p ON p.PaymentReference=f.PurchaseNumber;

CREATE TABLE #Returns(PurchaseNumber varchar(30) PRIMARY KEY,RefundAmount decimal(16,4),Reason nvarchar(120));
INSERT #Returns VALUES
('PO-DOCK-001',0.50,'Surface finish not suitable; discounted sample credit approved'),
('PO-DOCK-002',3.39,'Display sample returned after evaluation'),
('PO-DOCK-003',2.75,'Hook spacing unsuitable for display'),
('PO-DOCK-004',3.39,'Pattern did not match seasonal range'),
('PO-DOCK-005',3.39,'Duplicate sample requested in error'),
('PO-DOCK-006',7.65,'Sample returned unopened'),
('PO-DOCK-007',4.25,'Display sample returned in original packaging'),
('PO-DOCK-008',1.85,'Packaging specification not suitable');
INSERT dbo.SalesReturn(ReturnNumber,ReturnedAt,Reason) SELECT PurchaseNumber,'2010-12-06T11:00:00',Reason FROM #Returns;
INSERT dbo.SalesReturnLine(ReturnLineCode,Quantity,RefundAmount) SELECT PurchaseNumber,1,RefundAmount FROM #Returns;
INSERT rel.SalesReturnSalesReturnLine(SalesReturnId,SalesReturnLineId)
SELECT h.SalesReturnId,l.SalesReturnLineId FROM dbo.SalesReturn h JOIN dbo.SalesReturnLine l ON l.ReturnLineCode=h.ReturnNumber;
INSERT rel.ShipmentLineSalesReturnLine(ShipmentLineId,SalesReturnLineId)
SELECT s.ShipmentLineId,r.SalesReturnLineId FROM dbo.ShipmentLine s JOIN dbo.SalesReturnLine r ON r.ReturnLineCode=s.ShipmentLineCode;
INSERT rel.SalesReturnLinePayment(SalesReturnLineId,PaymentId,RefundedAmount)
SELECT r.SalesReturnLineId,p.PaymentId,r.RefundAmount FROM dbo.SalesReturnLine r JOIN dbo.Payment p ON p.PaymentReference=r.ReturnLineCode;

INSERT dbo.StockMovement(MovementCode,OccurredAt,QuantityChange,MovementTypeId)
SELECT 'RECEIPT-'+f.PurchaseNumber,f.ReceivedAt,f.Quantity,t.MovementTypeId FROM #Facts f
JOIN dbo.MovementType t ON t.TypeName='Receipt';
INSERT dbo.StockMovement(MovementCode,OccurredAt,QuantityChange,MovementTypeId)
SELECT 'SHIP-'+f.PurchaseNumber,'2010-12-03T10:00:00',-1,t.MovementTypeId FROM #Facts f
JOIN dbo.MovementType t ON t.TypeName='Shipment';
INSERT dbo.StockMovement(MovementCode,OccurredAt,QuantityChange,MovementTypeId)
SELECT 'RETURN-'+r.PurchaseNumber,'2010-12-06T11:00:00',1,t.MovementTypeId FROM #Returns r
JOIN dbo.MovementType t ON t.TypeName='Return';
INSERT rel.ProductStockMovement(ProductId,StockMovementId)
SELECT f.ProductId,m.StockMovementId FROM #Facts f JOIN dbo.StockMovement m
ON m.MovementCode IN ('RECEIPT-'+f.PurchaseNumber,'SHIP-'+f.PurchaseNumber,'RETURN-'+f.PurchaseNumber);
INSERT rel.WarehouseStockMovement(WarehouseId,StockMovementId)
SELECT w.WarehouseId,m.StockMovementId FROM dbo.StockMovement m JOIN dbo.Warehouse w ON w.WarehouseCode='MAIN';
INSERT rel.GoodsReceiptLineStockMovement(GoodsReceiptLineId,StockMovementId)
SELECT r.GoodsReceiptLineId,m.StockMovementId FROM dbo.GoodsReceiptLine r JOIN dbo.StockMovement m ON m.MovementCode='RECEIPT-'+r.ReceiptLineCode;
INSERT rel.ShipmentLineStockMovement(ShipmentLineId,StockMovementId)
SELECT s.ShipmentLineId,m.StockMovementId FROM dbo.ShipmentLine s JOIN dbo.StockMovement m ON m.MovementCode='SHIP-'+s.ShipmentLineCode;
INSERT rel.SalesReturnLineStockMovement(SalesReturnLineId,StockMovementId)
SELECT r.SalesReturnLineId,m.StockMovementId FROM dbo.SalesReturnLine r JOIN dbo.StockMovement m ON m.MovementCode='RETURN-'+r.ReturnLineCode;
INSERT rel.ProductWarehouse(ProductId,WarehouseId)
SELECT f.ProductId,w.WarehouseId FROM #Facts f JOIN dbo.Warehouse w ON w.WarehouseCode='MAIN';
INSERT dbo.StockCount(CountReference,CountedAt) VALUES('DEC-SAMPLE-WAVE','2010-12-07T09:00:00');
INSERT dbo.StockCountLine(CountLineCode,CountedQuantity) SELECT PurchaseNumber,CountedQuantity FROM #Facts;
INSERT rel.ProductStockCountLine(ProductId,StockCountLineId)
SELECT f.ProductId,c.StockCountLineId FROM #Facts f JOIN dbo.StockCountLine c ON c.CountLineCode=f.PurchaseNumber;
INSERT rel.StockCountStockCountLine(StockCountId,StockCountLineId)
SELECT h.StockCountId,l.StockCountLineId FROM dbo.StockCountLine l JOIN dbo.StockCount h ON h.CountReference='DEC-SAMPLE-WAVE';
INSERT rel.WarehouseStockCount(WarehouseId,StockCountId)
SELECT w.WarehouseId,h.StockCountId FROM dbo.StockCount h JOIN dbo.Warehouse w ON w.WarehouseCode='MAIN';
INSERT rel.EmployeeStockCount(EmployeeId,StockCountId)
SELECT e.EmployeeId,h.StockCountId FROM dbo.StockCount h JOIN dbo.Employee e ON e.EmployeeCode='COUNTER-RILEY';
UPDATE dbo.SalesOrderLine SET DiscountAmount=10 WHERE SourceLineCode='UCI-1';
UPDATE dbo.SalesOrder SET Notes=N'Authorized display-sample discount on UCI-1; approval retained by training distributor.'
WHERE OrderNumber='536365';
UPDATE o SET OrderStatusId=s.OrderStatusId
FROM dbo.SalesOrder o JOIN (SELECT DISTINCT SalesOrderId FROM #Facts) f ON f.SalesOrderId=o.SalesOrderId
JOIN dbo.OrderStatus s ON s.StatusName='Partially fulfilled';
DROP TABLE #Returns;
DROP TABLE #Facts;
DROP TABLE #Batch;
DROP TABLE #Ops;
`;
fs.writeFileSync(path.join(seedDir,'PurchasingAndInventory.sql'),ops);

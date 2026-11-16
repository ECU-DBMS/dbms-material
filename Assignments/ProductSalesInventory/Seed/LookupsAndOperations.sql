-- Authored fictional distributor master records. Small populations are intentional.
INSERT dbo.Customer(CustomerCode,DisplayName) VALUES
('PINE-PARCEL',N'Pine & Parcel Trading'),
('WILLOW-HOME',N'Willow Home Studio');
INSERT dbo.Product(ProductCode,ProductName) VALUES
('SAMPLE-CERAMIC-TRAY',N'Ceramic counter display tray - pending first purchase'),
('DISPLAY-PAPER-KIT',N'Paper gift display starter kit - pending first purchase');
INSERT dbo.OrderStatus(StatusName) VALUES ('Accepted'),('Partially fulfilled'),('Fulfilled'),('Cancelled');
INSERT dbo.MovementType(TypeName,Direction) VALUES ('Receipt',1),('Shipment',-1),('Return',1),('Opening',1),('Adjustment gain',1),('Adjustment loss',-1);
INSERT dbo.PaymentMethod(MethodName) VALUES ('Bank transfer'),('Card'),('Check'),('Account credit');
INSERT dbo.Supplier(SupplierCode,SupplierName,LeadTimeDays) VALUES
('HEARTH',N'Hearth & Display Wholesale',7),
('WARMTH',N'Comfort Textile Supply',7),
('PLAYBOX',N'Playbox Trade Gifts',7),
('TABLETOP',N'Tabletop Merchants',8),
('CLOCKWORK',N'Clockwork Lighting & Timepieces',10),
('PAPERHOUSE',N'Paperhouse Trade Packaging',6),
('BAGWORKS',N'Bagworks Retail Supply',7);
INSERT dbo.Warehouse(WarehouseCode,WarehouseName) VALUES
('MAIN',N'Main fulfillment warehouse'),
('OVERFLOW',N'Overflow storage - not yet commissioned'),
('DISPLAY',N'Display and training facility - not yet commissioned');
INSERT dbo.Employee(EmployeeCode,EmployeeName,JobTitle) VALUES
('BUYER-MORGAN',N'Morgan Reed',N'Purchasing coordinator'),
('RECEIVER-ELLIS',N'Ellis Parker',N'Receiving specialist'),
('PICKER-AVERY',N'Avery Brooks',N'Fulfillment specialist'),
('SALES-JORDAN',N'Jordan Hayes',N'Sales coordinator'),
('COUNTER-RILEY',N'Riley Bennett',N'Inventory controller'),
('AUDITOR-CASEY',N'Casey Morgan',N'Internal controls analyst');

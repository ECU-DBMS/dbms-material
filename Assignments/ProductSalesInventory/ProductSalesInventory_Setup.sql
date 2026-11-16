-- DATABASE ADMINISTRATOR: SQL Server 2025. Enable SQLCMD mode in the MSSQL extension.
-- All :r include paths below are relative to the repository root: open the cloned
-- repository root as your VS Code workspace folder (File > Open Folder), because the
-- MSSQL extension resolves :r paths against the workspace folder, not this file's folder.
-- CLI alternative (run from the repository root):
--   sqlcmd -S <server> -U <admin> -C -b -i Assignments/ProductSalesInventory/ProductSalesInventory_Setup.sql
-- Passwords belong in the connection dialog/environment, never this file.
:ON ERROR EXIT
USE master;
GO
IF CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) < 17
    THROW 51200,'This teaching package targets SQL Server 2025 or later.',1;
IF DB_ID(N'ProductSalesInventory') IS NOT NULL
    THROW 51201,'Database already exists. Setup never resets it; use the explicitly guarded reset script.',1;
GO
CREATE DATABASE ProductSalesInventory;
GO
ALTER DATABASE ProductSalesInventory SET COMPATIBILITY_LEVEL = 170;
ALTER DATABASE ProductSalesInventory SET QUERY_STORE = ON;
ALTER DATABASE ProductSalesInventory SET QUERY_STORE
    (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL, MAX_STORAGE_SIZE_MB = 128);
GO
USE ProductSalesInventory;
GO
:r ./Assignments/ProductSalesInventory/ProductSalesInventory_Schema.sql
:r ./Assignments/ProductSalesInventory/ProductSalesInventory_Bridges.sql
:r ./Assignments/ProductSalesInventory/ProductSalesInventory_BaselineObjects.sql
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r ./Assignments/ProductSalesInventory/Seed/LookupsAndOperations.sql
:r ./Assignments/ProductSalesInventory/Seed/CatalogAndParties.sql
:r ./Assignments/ProductSalesInventory/Seed/SalesAndFulfillment.sql
:r ./Assignments/ProductSalesInventory/Seed/PurchasingAndInventory.sql
COMMIT;
GO
:r ./Assignments/ProductSalesInventory/Checks/SetupChecks.sql
PRINT 'Fresh baseline ready. Student solution objects have NOT been installed.';
GO

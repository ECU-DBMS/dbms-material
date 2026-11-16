-- This script resets the ProductSalesInventory database.
-- It is destructive and will drop the database if it exists.
-- Ensure @ConfirmDatabaseName is set correctly before running.
:ON ERROR EXIT
USE master;
GO
DECLARE @ConfirmDatabaseName sysname = N'ProductSalesInventory';
IF @ConfirmDatabaseName <> N'ProductSalesInventory'
    THROW 51210,'Reset refused. Explicitly enter ProductSalesInventory in @ConfirmDatabaseName.',1;
IF DB_ID(N'ProductSalesInventory') IS NULL
    THROW 51211,'Nothing to reset: the teaching database does not exist.',1;
ALTER DATABASE ProductSalesInventory SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE ProductSalesInventory;
GO
-- Server logins/audit objects are separately managed by AdminSetup; no broad server cleanup.

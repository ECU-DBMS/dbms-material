:ON ERROR EXIT
-- This script performs administrative cleanup for the ProductSalesInventory database.
-- It removes specific server and database objects related to the teaching instance.
-- Run BEFORE resetting the database. Requires @ConfirmCleanup=1.
USE master;
GO
DECLARE @ConfirmCleanup bit=1;
IF @ConfirmCleanup<>1 THROW 51510,'Set @ConfirmCleanup=1 only on your own local teaching instance.',1;
IF DB_ID('ProductSalesInventory') IS NOT NULL
BEGIN
    EXEC(N'USE ProductSalesInventory;
IF EXISTS(SELECT 1 FROM sys.database_audit_specifications WHERE name=''PSI2025_ProductAccess'')
BEGIN
 ALTER DATABASE AUDIT SPECIFICATION PSI2025_ProductAccess WITH(STATE=OFF);
 DROP DATABASE AUDIT SPECIFICATION PSI2025_ProductAccess;
END;
IF DATABASE_PRINCIPAL_ID(''PSI2025_LoginUser'') IS NOT NULL DROP USER PSI2025_LoginUser;');
END;
IF EXISTS(SELECT 1 FROM sys.server_audits WHERE name='PSI2025_ProductAudit')
BEGIN
    ALTER SERVER AUDIT PSI2025_ProductAudit WITH(STATE=OFF);
    DROP SERVER AUDIT PSI2025_ProductAudit;
END;
IF SUSER_ID('PSI2025_LabLogin') IS NOT NULL DROP LOGIN PSI2025_LabLogin;
IF SUSER_ID('PSI2025_PerformanceLogin') IS NOT NULL DROP LOGIN PSI2025_PerformanceLogin;
IF CERT_ID('PSI2025_PerformanceCertificate') IS NOT NULL DROP CERTIFICATE PSI2025_PerformanceCertificate;
-- Audit files and the database remain intact; file retention is a separate host decision.

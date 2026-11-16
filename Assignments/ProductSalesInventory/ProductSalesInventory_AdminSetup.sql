:ON ERROR EXIT
:setvar EnableServerLabs "0"
:setvar AuditDirectory "/var/opt/mssql/audit-ProductSalesInventory"
USE ProductSalesInventory;
GO
-- DATABASE ADMINISTRATOR: idempotent database-only prerequisite for both parts.
SET NOCOUNT ON;
IF DATABASE_PRINCIPAL_ID('lab_clerk') IS NULL CREATE ROLE lab_clerk;
IF DATABASE_PRINCIPAL_ID('lab_warehouse') IS NULL CREATE ROLE lab_warehouse;
IF DATABASE_PRINCIPAL_ID('lab_analyst') IS NULL CREATE ROLE lab_analyst;
IF DATABASE_PRINCIPAL_ID('lab_auditor') IS NULL CREATE ROLE lab_auditor;
IF DATABASE_PRINCIPAL_ID('lab_application') IS NULL CREATE ROLE lab_application;
IF DATABASE_PRINCIPAL_ID('LabClerk') IS NULL CREATE USER LabClerk WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('LabWarehouse') IS NULL CREATE USER LabWarehouse WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('LabAnalyst') IS NULL CREATE USER LabAnalyst WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('LabAuditor') IS NULL CREATE USER LabAuditor WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('LabApplication') IS NULL CREATE USER LabApplication WITHOUT LOGIN;
ALTER ROLE lab_clerk ADD MEMBER LabClerk;
ALTER ROLE lab_warehouse ADD MEMBER LabWarehouse;
ALTER ROLE lab_analyst ADD MEMBER LabAnalyst;
ALTER ROLE lab_auditor ADD MEMBER LabAuditor;
ALTER ROLE lab_application ADD MEMBER LabApplication;
GRANT SELECT ON SCHEMA::reporting TO lab_clerk,lab_warehouse,lab_analyst,lab_auditor,lab_application;
GRANT SELECT ON SCHEMA::dbo TO lab_analyst;
GRANT SELECT ON SCHEMA::rel TO lab_analyst;
GRANT SELECT ON SCHEMA::audit TO lab_auditor;
GRANT EXECUTE ON SCHEMA::student TO lab_clerk,lab_application;
DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::dbo TO lab_warehouse,lab_application;
DENY INSERT,UPDATE,DELETE ON SCHEMA::audit TO lab_clerk,lab_warehouse,lab_analyst,lab_auditor,lab_application;
PRINT 'Database roles ready. All five lab users intentionally have no login.';
GO
-- SERVER/HOST ADMINISTRATOR: opt in by changing EnableServerLabs above to 1.
-- First create AuditDirectory INSIDE the SQL Server Linux container and grant its
-- SQL Server service identity read/write access. See the background for Docker commands.
-- File audit uses the container path, NOT a Windows path on your VS Code computer.
IF '$(EnableServerLabs)'='1'
BEGIN
    IF IS_SRVROLEMEMBER('sysadmin')<>1
        THROW 51500,'Server labs require your local container administrator connection.',1;

    IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys WHERE name='##MS_DatabaseMasterKey##')
    BEGIN
        DECLARE @KeyPassword varchar(100)='Key!'+CONVERT(varchar(80),CRYPT_GEN_RANDOM(32),2);
        DECLARE @KeySql nvarchar(max)=N'CREATE MASTER KEY ENCRYPTION BY PASSWORD='''+@KeyPassword+N''';';
        EXEC sys.sp_executesql @KeySql;
    END;
    IF CERT_ID('PSI2025_PerformanceCertificate') IS NULL
        CREATE CERTIFICATE PSI2025_PerformanceCertificate WITH SUBJECT='Local PSI teaching DMV access';

    DECLARE @Certificate varbinary(max)=CERTENCODED(CERT_ID('PSI2025_PerformanceCertificate'));
    DECLARE @MasterSql nvarchar(max)=N'USE master;
IF CERT_ID(''PSI2025_PerformanceCertificate'') IS NULL
    CREATE CERTIFICATE PSI2025_PerformanceCertificate FROM BINARY = '+CONVERT(nvarchar(max),@Certificate,1)+N';
IF CERTENCODED(CERT_ID(''PSI2025_PerformanceCertificate'')) <> '+CONVERT(nvarchar(max),@Certificate,1)+N'
    THROW 51501,''Old master certificate differs. Run the named admin cleanup before reprovisioning.'',1;
IF SUSER_ID(''PSI2025_PerformanceLogin'') IS NULL
    CREATE LOGIN PSI2025_PerformanceLogin FROM CERTIFICATE PSI2025_PerformanceCertificate;
GRANT VIEW SERVER PERFORMANCE STATE TO PSI2025_PerformanceLogin;';
    EXEC sys.sp_executesql @MasterSql;

    EXEC(N'CREATE OR ALTER PROCEDURE student.usp_SignedPlanCount AS
BEGIN SET NOCOUNT ON; SELECT COUNT_BIG(*) AS CachedStatementCount FROM sys.dm_exec_query_stats; END;');
    ADD SIGNATURE TO OBJECT::student.usp_SignedPlanCount BY CERTIFICATE PSI2025_PerformanceCertificate;
    GRANT EXECUTE ON OBJECT::student.usp_SignedPlanCount TO lab_application;

    IF SUSER_ID('PSI2025_LabLogin') IS NULL
    BEGIN
        DECLARE @LoginPassword varchar(100)='Login!'+CONVERT(varchar(80),CRYPT_GEN_RANDOM(32),2);
        EXEC(N'CREATE LOGIN PSI2025_LabLogin WITH PASSWORD='''+@LoginPassword+
            N''',CHECK_POLICY=ON,DEFAULT_DATABASE=ProductSalesInventory;');
    END;
    IF DATABASE_PRINCIPAL_ID('PSI2025_LoginUser') IS NULL
        CREATE USER PSI2025_LoginUser FOR LOGIN PSI2025_LabLogin;
    ALTER ROLE lab_application ADD MEMBER PSI2025_LoginUser;

    IF NOT EXISTS(SELECT 1 FROM sys.server_audits WHERE name='PSI2025_ProductAudit')
    BEGIN
        DECLARE @AuditSql nvarchar(max)=N'USE master; CREATE SERVER AUDIT PSI2025_ProductAudit TO FILE
(FILEPATH=N'''+REPLACE(N'$(AuditDirectory)',N'''',N'''''')+N''',MAXSIZE=32 MB,MAX_ROLLOVER_FILES=4)
WITH(QUEUE_DELAY=1000,ON_FAILURE=FAIL_OPERATION);';
        EXEC sys.sp_executesql @AuditSql;
    END;
    EXEC(N'USE master; ALTER SERVER AUDIT PSI2025_ProductAudit WITH(STATE=ON);');
    IF NOT EXISTS(SELECT 1 FROM sys.database_audit_specifications WHERE name='PSI2025_ProductAccess')
        CREATE DATABASE AUDIT SPECIFICATION PSI2025_ProductAccess
        FOR SERVER AUDIT PSI2025_ProductAudit
        ADD(SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.Product BY public)
        WITH(STATE=ON);
    ELSE
        ALTER DATABASE AUDIT SPECIFICATION PSI2025_ProductAccess WITH(STATE=ON);
    PRINT 'Server labs provisioned. Signing grants only the module server-performance access.';
END
ELSE
    PRINT 'Server/host labs not provisioned: EnableServerLabs is 0. This is explicit, not a successful server-lab result.';
GO
/*
SERVER ADMINISTRATOR - run these examples separately after enabling server labs:

SELECT ORIGINAL_LOGIN() AS OriginalLogin,SUSER_SNAME() AS CurrentLogin,USER_NAME() AS CurrentUser;
EXECUTE AS LOGIN='PSI2025_LabLogin';
SELECT ORIGINAL_LOGIN() AS OriginalLogin,SUSER_SNAME() AS CurrentLogin,USER_NAME() AS CurrentUser;
SELECT TOP(1) ProductCode FROM reporting.v_StockOnHand;
REVERT;

-- Server-scope signing demo uses an authenticated login context, not a
-- database-only WITHOUT LOGIN impersonation token.
EXECUTE AS LOGIN='PSI2025_LabLogin';
EXEC student.usp_SignedPlanCount;
-- SELECT COUNT_BIG(*) FROM sys.dm_exec_query_stats; -- expect permission error 300
REVERT;

EXECUTE AS USER='LabAnalyst';
SELECT TOP(1) ProductCode FROM dbo.Product ORDER BY ProductCode; -- audited success
REVERT;
EXECUTE AS USER='LabWarehouse';
BEGIN TRY
    UPDATE dbo.Product SET IsActive=0 WHERE ProductCode='71053'; -- audited failure
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ExpectedPermissionError;
END CATCH;
REVERT;
WAITFOR DELAY '00:00:02'; -- allow the configured asynchronous queue to flush
SELECT event_time,action_id,succeeded,session_server_principal_name,
       server_principal_name,database_principal_name,statement
FROM sys.fn_get_audit_file(N'$(AuditDirectory)/'+N'*.sqlaudit',DEFAULT,DEFAULT)
WHERE database_name=N'ProductSalesInventory' ORDER BY event_time DESC;

Never leave a session impersonated after an unexpected error. Reconnect if unsure.
*/

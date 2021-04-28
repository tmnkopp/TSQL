USE [master]
GO
ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [CyberScopeLite] SET MULTI_USER
GO
DROP DATABASE [CyberScopeLite]
GO
CREATE DATABASE [CyberScopeLite]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'CyberScopeLite', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CyberScopeLite.mdf' , SIZE = 1048576KB , FILEGROWTH = 262144KB )
 LOG ON 
( NAME = N'CyberScopeLite_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CyberScopeLite_log.ldf' , SIZE = 524288KB , FILEGROWTH = 131072KB )
GO  
ALTER DATABASE [CyberScopeLite] SET RECOVERY SIMPLE WITH NO_WAIT
GO 
ALTER AUTHORIZATION ON DATABASE::[CyberScopeLite] TO [sa]
GO
ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [CyberScopeLite] SET MULTI_USER
GO
USE [master]
RESTORE DATABASE [CyberScopeLite] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\CyberScope123.bak' WITH  FILE = 1, 
 MOVE N'CyberScorecard' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CyberScopeLite.mdf', 
 MOVE N'CyberScorecard_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CyberScopeLite.ldf',  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5
 RESTORE DATABASE [CyberScopeLite] WITH RECOVERY
GO 
ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE [CyberScopeLite] SET MULTI_USER
GO
USE [CyberScopeLite] -- [CyberScope123] --  
IF OBJECT_ID('tempdb..#StmtProvider') IS NOT NULL DROP TABLE #StmtProvider 
CREATE TABLE #StmtProvider (ROWID INT IDENTITY (1, 1), STMT NVARCHAR(4000) )    
;WITH dbschema AS
(
	SELECT 
		t.name AS TableName, 
		i.name As indexName, 
		cols.COLUMN_NAME As PK,
		sum(p.rows) as RowCounts, 
		(sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
		(sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
		(sum(a.data_pages) * 8) / 1024 as DataSpaceMB
	FROM  sys.tables t
	INNER JOIN INFORMATION_SCHEMA.COLUMNS cols ON cols.TABLE_NAME = t.name ANd cols.ORDINAL_POSITION = 1
	INNER JOIN sys.indexes i ON t.object_id = i.object_id
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
	INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
	WHERE t.name NOT LIKE 'dt%' AND i.object_id > 255 AND i.index_id <= 1
	GROUP BY  t.name, i.object_id, i.index_id, i.name , cols.COLUMN_NAME 
) 
-- SELECT * FROM dbschema ORDER BY TotalSpaceMB DESC 
INSERT INTO #StmtProvider(STMT)
SELECT 
CASE WHEN TableName NOT LIKE 'fsma_%' AND TableName NOT LIKE 'wf_%'    THEN
	'TRUNCATE TABLE [' +TableName+ ']'
WHEN TableName LIKE '%AuditLog%' OR TableName LIKE '%BACKUP%'   THEN
	'TRUNCATE TABLE [' +TableName+ ']'
ELSE
	'-- DELETE FROM [' +TableName+ '] WHERE ' + PK +  ' > (SELECT MAX('+PK+') - 100000 FROM [' +TableName+ '])'
END STMT FROM dbschema WHERE UsedSpaceMB > 1 
SELECT * FROM #StmtProvider  
DECLARE @RowCnt INT = 1 
DECLARE @MaxRows INT =(SELECT COUNT(*) FROM #StmtProvider)
WHILE @RowCnt <= @MaxRows
BEGIN  
	DECLARE @EXE NVARCHAR(MAX) = (SELECT ISNULL(STMT, '0') FROM #StmtProvider WHERE ROWID = @RowCnt) + ';'    
	BEGIN TRY       
		PRINT @EXE    --  EXECUTE sp_executesql @EXE             
	END TRY  
	BEGIN CATCH   
		PRINT ' err '+ @EXE
	END CATCH   
	SET @RowCnt = @RowCnt + 1 
END  
GO 
USE [CyberScopeLite]
GO
DBCC SHRINKFILE (N'CyberScorecard_log' , 0, TRUNCATEONLY) 
GO
DBCC SHRINKDATABASE(N'CyberScopeLite' )
GO 
BACKUP DATABASE [CyberScopeLite] TO  DISK = N'D:\Backup\CyberScopeLite.bak' WITH NOFORMAT, NOINIT, 
NAME = N'CyberScopeLite-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
BACKUP DATABASE [CyberScopeLite] TO  DISK = N'D:\Backup\CyberScopeLite.bak' WITH  DIFFERENTIAL ,NOFORMAT, NOINIT,  
NAME = N'CyberScopeLite-DIFF Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

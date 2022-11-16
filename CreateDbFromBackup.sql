USE [master] 
GO
IF (EXISTS (SELECT * FROM master.dbo.sysdatabases WHERE NAME='CyberScopeLite'))
BEGIN
	ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	ALTER DATABASE [CyberScopeLite] SET MULTI_USER 
	DROP DATABASE [CyberScopeLite]
END 
GO

CREATE DATABASE [CyberScopeLite]
	 CONTAINMENT = NONE
	 ON PRIMARY ( NAME = N'CyberScopeLite', FILENAME = N'D:\DATA\CyberScopeLite.mdf' , SIZE = 1048576KB , FILEGROWTH = 262144KB )
	 LOG ON ( NAME = N'CyberScopeLite_log', FILENAME = N'D:\DATA\CyberScopeLite_log.ldf' , SIZE = 524288KB , FILEGROWTH = 131072KB )
GO  
	ALTER DATABASE [CyberScopeLite] SET RECOVERY SIMPLE WITH NO_WAIT
GO 
	ALTER AUTHORIZATION ON DATABASE::[CyberScopeLite] TO [sa]
GO
	ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	ALTER DATABASE [CyberScopeLite] SET MULTI_USER
GO

USE [master]
RESTORE DATABASE [CyberScopeLite] FROM  
	DISK = N'D:\Backup\CyberScope.bak' WITH  FILE = 1, 
	MOVE N'CyberScorecard' TO N'D:\DATA\CyberScopeLite.mdf', 
	MOVE N'CyberScorecard_log' TO N'D:\DATA\CyberScopeLite.ldf',  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5
	RESTORE DATABASE [CyberScopeLite] WITH RECOVERY
GO 
	ALTER DATABASE [CyberScopeLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	ALTER DATABASE [CyberScopeLite] SET MULTI_USER
GO
USE [master]

	SET NOCOUNT ON;
	USE [CS101122] --  USE [CyberScope123] --  
	IF OBJECT_ID('tempdb..#StmtProvider') IS NOT NULL DROP TABLE #StmtProvider 
	CREATE TABLE #StmtProvider (ROWID INT IDENTITY (1, 1), STMT NVARCHAR(4000) )    
	;WITH dbschema AS
	(
		SELECT 
			t.name AS TableName, 
			i.name As indexName, 
			cols.COLUMN_NAME As PK,
			sum(p.rows) as RowCounts, 
			(sum(a.total_pages) * 8) / 1024 as TotalSpaceMB 
		FROM  sys.tables t
		INNER JOIN INFORMATION_SCHEMA.COLUMNS cols ON cols.TABLE_NAME = t.name ANd cols.ORDINAL_POSITION = 1
		INNER JOIN sys.indexes i ON t.object_id = i.object_id
		INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
		WHERE t.name NOT LIKE 'dt%' AND i.object_id > 255 AND i.index_id <= 1
		GROUP BY  t.name, i.object_id, i.index_id, i.name , cols.COLUMN_NAME 
	) 
	SELECT * FROM dbschema ORDER BY TotalSpaceMB DESC  
	INSERT INTO #StmtProvider(STMT)
	SELECT 
	CASE 
	WHEN TableName LIKE 'Artifacts%' OR TableNAme LIKE '%fsma_NarrAnswers%'  THEN
		' DELETE FROM [' +TableName+ '] WHERE [' + PK +  '] < (SELECT MAX(['+PK+']) - 10 FROM [' +TableName+ '])'
	WHEN TableName LIKE '%BACKUP%'   THEN
		'TRUNCATE TABLE [' +TableName+ ']'
	WHEN TableName LIKE '%AuditLog%' THEN
		' DELETE FROM [' +TableName+ '] WHERE [' + PK +  '] < (SELECT MAX(['+PK+']) - 10000 FROM [' +TableName+ '])'
	WHEN TableName NOT LIKE 'fsma_%' AND TableName NOT LIKE 'wf_%'      THEN
		'TRUNCATE TABLE [' +TableName+ ']' 
	WHEN TableName LIKE 'fsma_%' OR TableName LIKE 'wf_%'  THEN
		' DELETE FROM [' +TableName+ '] WHERE [' + PK +  '] < (SELECT MAX(['+PK+']) - 50000 FROM [' +TableName+ '])'
	ELSE
		' DELETE FROM [' +TableName+ '] WHERE [' + PK +  '] < (SELECT MAX(['+PK+']) - 10000 FROM [' +TableName+ '])'
	END STMT FROM dbschema WHERE TotalSpaceMB > 1 
	  
	DECLARE @RowCnt INT = 1 
	DECLARE @MaxRows INT =(SELECT COUNT(*) FROM #StmtProvider)
	WHILE @RowCnt <= @MaxRows
	BEGIN  
		DECLARE @EXE NVARCHAR(MAX) = (SELECT ISNULL(STMT, '0') FROM #StmtProvider WHERE ROWID = @RowCnt) + ';'    
		BEGIN TRY 
			 --  EXECUTE sp_executesql @EXE       
			  PRINT @EXE    --          
		END TRY  
		BEGIN CATCH   
			PRINT ' err '+ @EXE
		END CATCH   
		SET @RowCnt = @RowCnt + 1 
	END   
GO 

USE [CyberScopeLite] 
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

 
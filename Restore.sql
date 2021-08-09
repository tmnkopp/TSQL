
SELECT  
	msdb.dbo.backupset.database_name,  
	msdb.dbo.backupset.backup_finish_date backup_date,    
	msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name ,
	msdb.dbo.backupset.backup_size
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 90) 
ORDER BY msdb.dbo.backupset.database_name,  msdb.dbo.backupset.backup_finish_date DESC 

RETURN; 

USE [master]
	RESTORE DATABASE [CSLITE] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\CSLITE.bak' 
	WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5
	RESTORE DATABASE [CSLITE] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\CSLITE.bak' 
	WITH  FILE = 14,  NOUNLOAD,  STATS = 5 
GO
--  USE [CSLITE]
--  SELECT * FROM vw_MetricsCompositeKeys
--  ORDER BY QPK DESC
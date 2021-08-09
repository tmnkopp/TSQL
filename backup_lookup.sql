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
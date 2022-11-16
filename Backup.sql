BACKUP DATABASE [CS101122] TO  DISK = N'D:\Backup\CS101122.bak' 
	WITH DIFFERENTIAL, NOFORMAT, NOINIT
	, NAME = N'Cyberscope-Diff Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO 
RETURN;
BACKUP DATABASE [yberscope123] TO  DISK = N'D:\Backup\Cyberscope.bak' 
	WITH DIFFERENTIAL, NOFORMAT, NOINIT
	, NAME = N'Cyberscope123-Diff Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO 
RETURN;

BACKUP DATABASE [CS101122] TO  DISK = N'D:\Backup\CS101122.bak'  
	WITH NOFORMAT, NOINIT
	, NAME = N'CS101122-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO -- FULL  
RETURN;
GO
SELECT
    bs.position
	, bs.*
    , bm.*
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bm on bs.media_set_id = bm.media_set_id
WHERE bs.name LIKE '%Backup%'
AND physical_device_name LIKE '%D:\Backup\%.bak%'
ORDER BY  bs.position DESC

-- DIFF 
/* 
 

*/  
/* 
USE [master]
RESTORE DATABASE [Cyberscope123] FROM  DISK = N'D:\Backup\CyberScope.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [Cyberscope123] FROM  DISK = N'D:\Backup\CyberScope.bak' WITH  FILE = 5,  NOUNLOAD,  STATS = 5 
GO 
*/  
/* 
USE [master]
ALTER DATABASE [CS] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [CS] FROM  DISK = N'D:\Backup\CyberScope6-8.bak' WITH  FILE = 1,  MOVE N'CyberScorecard' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CS.mdf',  MOVE N'CyberScorecard_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\CS.ldf',  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [CS] SET MULTI_USER

GO


*/
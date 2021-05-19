USE [master]
RESTORE DATABASE [CyberScopeLite] FROM  
DISK = N'D:\Backup\CyberScopeLite.bak' 
WITH  FILE = 1,  

NOUNLOAD,  REPLACE,  STATS = 5 
GO

USE [master]
RESTORE DATABASE [CyberScopeLite] FROM  DISK = N'D:\Backup\CyberScopeLite.bak'
 WITH  FILE = 1,  
 MOVE N'CyberScorecard' TO N'C:\RestoreLoc\DATA\CyberScopeLite.mdf',  
 MOVE N'CyberScorecard_log' TO N'C:\RestoreLoc\DATA\CyberScopeLite.ldf',  
 NOUNLOAD,  REPLACE,  STATS = 5 
GO




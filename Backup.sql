BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScope.bak' 
	WITH DIFFERENTIAL, NOFORMAT, NOINIT
	, NAME = N'Cyberscope-Diff Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO 
/*  Full

BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScope.bak' WITH NOFORMAT, NOINIT,  
NAME = N'Cyberscope123-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO 

USE [master]
RESTORE DATABASE [Cyberscope123] FROM  DISK = N'D:\Backup\CyberScope.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [Cyberscope123] FROM  DISK = N'D:\Backup\CyberScope.bak' WITH  FILE = 5,  NOUNLOAD,  STATS = 5 
GO


*/ 

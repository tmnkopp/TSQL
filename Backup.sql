BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScopeFull.bak' 
	WITH DIFFERENTIAL, NOFORMAT, NOINIT
	, NAME = N'Cyberscope-Diff Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
/*
BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScopeFull.bak' WITH NOFORMAT, NOINIT, 
 NAME = N'Cyberscope123-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScopeFull.bak' WITH NOFORMAT, NOINIT, 
 NAME = N'Cyberscope123-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
*/ 
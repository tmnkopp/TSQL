BACKUP DATABASE [Cyberscope123] TO  DISK = N'D:\Backup\CyberScope.bak' 
	WITH DIFFERENTIAL, NOFORMAT, NOINIT
	, NAME = N'Cyberscope-Diff Backup 8-9', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
 
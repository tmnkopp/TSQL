USE [master]
RESTORE DATABASE [CSLITE] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\CSLITE.bak' WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [CSLITE] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\CSLITE.bak' WITH  FILE = 14,  NOUNLOAD,  STATS = 5 
GO
--  USE [CSLITE]
--  SELECT * FROM vw_MetricsCompositeKeys
--  ORDER BY QPK DESC
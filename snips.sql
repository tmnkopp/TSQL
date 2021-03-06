--snippet{"name":"cols from info schema", "category":"sql"}

IF EXISTS (SELECT * FROM sysobjects WHERE name = 'sp_SPROC' AND TYPE = 'P')
    DROP PROCEDURE sp_SPROC
GO  
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'vw_VIEW' AND TYPE = 'V')
    DROP VIEW vw_VIEW
GO 
IF EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[fn_JSONtoTBL]') AND TYPE IN (N'FN', N'IF', N'TF', N'FS', N'FT')) 
	DROP FUNCTION [dbo].[fn_JSONtoTBL]
GO 

DECLARE @COLS  AS NVARCHAR(MAX)=''; 
SELECT @COLS = @COLS + QUOTENAME(COLUMN_NAME) + ',' FROM (SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='fsma_Activities' AND COLUMN_NAME NOT LIKE '%PK_%' AND COLUMN_NAME <> 'IsActive'  AND COLUMN_NAME <> 'DateCreated' AND COLUMN_NAME <> 'DateModified' AND COLUMN_NAME <> 'DateUpdated') vw
SELECT @COLS = substring(@COLS, 0, LEN(@COLS)) --trim "," at end
SELECT @COLS 


SELECT DISTINCT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
--//snippet 


DECLARE @SRC NVARCHAR(55) = 'aspnet_Profile'
DECLARE @DICT TABLE (ROWNUM INT IDENTITY (1, 1) PRIMARY KEY NOT NULL , KY INT, VL NVARCHAR(4000))

DECLARE @RowCnt INT = 0
INSERT INTO @DICT (KY,VL)
SELECT ORDINAL_POSITION, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@SRC
DECLARE @MaxRows INT=(SELECT COUNT(*) FROM @DICT)
WHILE @RowCnt <= @MaxRows
BEGIN
	DECLARE @PKEY INT = (SELECT KY FROM @DICT WHERE ROWNUM = @RowCnt)
	DECLARE @VL NVARCHAR(4000) = (SELECT VL FROM @DICT WHERE ROWNUM = @RowCnt)
	PRINT @VL
	SELECT @RowCnt = @RowCnt + 1
END

 
 
 
 

DECLARE @SRC NVARCHAR(55) = 'aspnet_Users'
IF OBJECT_ID('tempdb..#MTRX') IS NOT NULL DROP TABLE #MTRX
CREATE TABLE #MTRX (ROWNUM INT IDENTITY (1, 1) PRIMARY KEY NOT NULL, KY INT, VL NVARCHAR(4000)) 
DECLARE @RowCnt INT = 1
INSERT INTO #MTRX (KY,VL)
SELECT ORDINAL_POSITION, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@SRC
DECLARE @MaxRows INT =(SELECT COUNT(*) FROM #MTRX)
WHILE @RowCnt <= @MaxRows
BEGIN
	DECLARE @PKEY INT = (SELECT KY FROM #MTRX WHERE ROWNUM = @RowCnt)
	DECLARE @VL NVARCHAR(4000) = (SELECT VL FROM #MTRX WHERE ROWNUM = @RowCnt) 
	SELECT @RowCnt = @RowCnt + 1
END
IF OBJECT_ID('tempdb..#MTRX') IS NOT NULL DROP TABLE #MTRX



DECLARE @exe NVARCHAR(MAX) = ''
SET @exe = ' '  
SET @exe = @exe + ' SELECT  PK_PrimeKey, Change_date, '+ @QUOTENAME +' FROM (  '
SET @exe = @exe + ' 	SELECT Change_date, FieldValue, FieldName, PK_PrimeKey FROM (  '
SET @exe = @exe + ' 		 SELECT FLATBYDATE.PK_AuditLog, Change_date, PK_PrimeKey, FieldName, FieldValue FROM (  '
SET @exe = @exe + ' 			SELECT MAX(PK_AuditLog) PK_AuditLog, Change_date, PK_PrimeKey, FieldName FROM (  '
SET @exe = @exe + ' 				SELECT  CONVERT(NVARCHAR(7), Change_date, 121)  Change_date,  PK_AuditLog , PK_PrimeKey, FieldName FROM AuditLog     '
SET @exe = @exe + ' 			) ALOG GROUP BY Change_date,  PK_PrimeKey, FieldName   '
SET @exe = @exe + ' 		 ) FLATBYDATE '
SET @exe = @exe + ' 		 INNER JOIN ( '
SET @exe = @exe + ' 			 SELECT PK_AuditLog, FieldValue FROM AuditLog WHERE TABLENAME = '''+ @TNAM +''' AND FieldValue IS NOT NULL  '
SET @exe = @exe + ' 		 ) VLOG ON VLOG.PK_AuditLog = FLATBYDATE.PK_AuditLog '
SET @exe = @exe + ' 	 ) y    '
SET @exe = @exe + ' ) x PIVOT(  '
SET @exe = @exe + ' 	MAX(FieldValue) For FieldName IN ('+ @QUOTENAME +') '
SET @exe = @exe + ' ) p  ORDER BY PK_PrimeKey DESC, Change_date DESC '



 
IF OBJECT_ID('tempdb..#MTRX') IS NOT NULL DROP TABLE #MTRX
CREATE TABLE #MTRX (ROWNUM INT IDENTITY (1, 1) PRIMARY KEY NOT NULL, KY INT, VL NVARCHAR(4000))
DECLARE @exe NVARCHAR(MAX) = ''
SET @exe=@exe+' DECLARE @SRC NVARCHAR(55) = ''aspnet_Users'' '
SET @exe=@exe+' DECLARE @RowCnt INT = 1 '
SET @exe=@exe+' INSERT INTO #MTRX (KY,VL) '
SET @exe=@exe+' SELECT ORDINAL_POSITION, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@SRC '
SET @exe=@exe+' DECLARE @MaxRows INT =(SELECT COUNT(*) FROM #MTRX) '
SET @exe=@exe+' WHILE @RowCnt <= @MaxRows '
SET @exe=@exe+' BEGIN '
SET @exe=@exe+' DECLARE @PKEY INT = (SELECT KY FROM #MTRX WHERE ROWNUM = @RowCnt) '
SET @exe=@exe+' DECLARE @VL NVARCHAR(4000) = (SELECT VL FROM #MTRX WHERE ROWNUM = @RowCnt) '
SET @exe=@exe+' SELECT @RowCnt = @RowCnt + 1 '
SET @exe=@exe+' END '
EXECUTE sp_executesql @exe
SELECT KY,VL FROM #MTRX
IF OBJECT_ID('tempdb..#MTRX') IS NOT NULL DROP TABLE #MTRX
 


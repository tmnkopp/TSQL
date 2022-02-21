DECLARE @QUOTENAME  AS NVARCHAR(4000)=''; 
DECLARE @FIELDS AS NVARCHAR(4000)=''; 
DECLARE @TNAM  AS NVARCHAR(55)='TIC_CloudServices'; --AND COLUMN_NAME NOT LIKE '%PK_%'
SELECT @QUOTENAME = @QUOTENAME + QUOTENAME(COLUMN_NAME) + ',' FROM (SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@TNAM  AND COLUMN_NAME <> 'IsActive'  AND COLUMN_NAME <> 'DateCreated' AND COLUMN_NAME <> 'DateModified' AND COLUMN_NAME <> 'DateUpdated') vw
SELECT @QUOTENAME = SUBSTRING(@QUOTENAME, 0, LEN(@QUOTENAME)) 
SELECT @FIELDS =REPLACE( REPLACE(@QUOTENAME, '[', ''''), ']', '''')    
SELECT @FIELDS 
-- SELECT CHANGE_DATE, *  FROM AuditLog  WHERE TABLENAME = @TNAM  AND PK_PrimeKey=24 AND CHANGE_DATE > DATEADD(d,-15,GETDATE()) 
-- UPDATE AuditLog SET CHANGE_DATE = DATEADD(d,-60,CHANGE_DATE) WHERE TABLENAME = 'fsma_Milestones' AND PK_PrimeKey=24 AND CHANGE_DATE > DATEADD(d,-15,GETDATE())
 
SELECT TOP 1000 PK_PrimeKey, Change_date, [Status],[AssignedTo],[Title],[TasksDesc],[ResourceReqmts],[MitConstraints],[ConExplanation],[SchCompDate],[ActCompDate],[Comments] FROM ( 
	SELECT  y.FieldValue, Change_date,  FieldName, PK_PrimeKey FROM ( 
		 SELECT FLATBYDATE.PK_AuditLog, VLOG.FieldValue , Change_date, PK_PrimeKey, FieldName FROM ( 
			SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.Change_date, PK_PrimeKey, FieldName FROM ( 
				SELECT  CONVERT(NVARCHAR(11), Change_date, 121)  Change_date,  PK_AuditLog , PK_PrimeKey, FieldName FROM AuditLog    
			) CONVERTDATE GROUP BY Change_date,  PK_PrimeKey, FieldName  
		 ) FLATBYDATE
		 INNER JOIN (
			 SELECT PK_AuditLog, FieldValue FROM AuditLog WHERE TABLENAME = @TNAM AND FieldValue IS NOT NULL 
		 ) VLOG ON VLOG.PK_AuditLog = FLATBYDATE.PK_AuditLog
	 ) y   
) x PIVOT( 
	MAX(FieldValue) For FieldName IN ([Status],[AssignedTo],[Title],[TasksDesc],[ResourceReqmts],[MitConstraints],[ConExplanation],[SchCompDate],[ActCompDate],[Comments])
) p  ORDER BY PK_PrimeKey DESC, Change_date DESC 

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

PRINT @exe 
--EXECUTE sp_executesql @exe 






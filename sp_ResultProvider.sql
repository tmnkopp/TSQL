/*  
Who:	T.KOPP
When:	8-5-2020
Why:	calculates expression strings, replacement for clr eval func
How:	
	DECLARE @RESULTSET NVARCHAR(4000) = ''
	EXEC sp_ResultProvider @Expressions='2; min(1,2); 1+1; 2+2; 1/0; 0/0; 100*(12+12)/((12+12)+(12+12))+(100*2/9)*2+6;',@RESULTSET=@RESULTSET OUTPUT 
	SELECT @RESULTSET
	SELECT * FROM dbo.fn_HashSplit(@RESULTSET, ':'   ,   ';')  
*/  
SET NOCOUNT ON   
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'sp_ResultProvider' AND type = 'P')
    DROP PROCEDURE [sp_ResultProvider]
GO 
CREATE PROCEDURE [dbo].[sp_ResultProvider] 
	@Expressions NVARCHAR(4000),
	@RESULTSET NVARCHAR(4000) OUTPUT
AS
BEGIN 
	DECLARE @EXPRESSIONSET TABLE (EXPRESSION NVARCHAR(4000))   
	DECLARE @RESULT NVARCHAR(4000) = ''
	INSERT INTO @EXPRESSIONSET (EXPRESSION)
	SELECT STRING FROM dbo.[iter_stringlist_to_tbl](@Expressions,';')
	IF OBJECT_ID('tempdb..#ResultProvider') IS NOT NULL DROP TABLE #ResultProvider  
	CREATE TABLE #ResultProvider (ROWID INT IDENTITY (1, 1), EXPRESSION NVARCHAR(4000), RESULT NVARCHAR(4000))  
	INSERT INTO #ResultProvider(EXPRESSION, RESULT)
	SELECT EXPRESSION, NULL FROM @EXPRESSIONSET WHERE EXPRESSION NOT LIKE '%;%'   
	  
	DECLARE @RowCnt INT = 1 
	DECLARE @MaxRows INT =(SELECT COUNT(*) FROM #ResultProvider)
	WHILE @RowCnt <= @MaxRows
	BEGIN
		DECLARE @EXP NVARCHAR(4000) = (SELECT ISNULL(EXPRESSION, '0') FROM #ResultProvider WHERE ROWID = @RowCnt)  
		DECLARE @FORMULA NVARCHAR(4000) = @EXP
		IF @FORMULA LIKE '%min(%'  
		BEGIN
			SET @FORMULA=REPLACE(@FORMULA,'min(','dbo.MaxMinValue(')
			SET @FORMULA=REPLACE(@FORMULA,')',',1)')
		END
		IF @FORMULA LIKE '%max(%'  
		BEGIN
			SET @FORMULA=REPLACE(@FORMULA,'max(','dbo.MaxMinValue(')
			SET @FORMULA=REPLACE(@FORMULA,')',',0)')
		END
		DECLARE @EXE NVARCHAR(MAX) = ''
		SET @EXE=@EXE+';UPDATE #ResultProvider SET RESULT = (SELECT('+@FORMULA+')) WHERE EXPRESSION = '''+@EXP+''''   
		BEGIN TRY                           
			EXECUTE sp_executesql @EXE--PRINT @EXE                 
		END TRY  
		BEGIN CATCH   
			If ERROR_NUMBER()=8134
			BEGIN
				SET @EXE=';UPDATE #ResultProvider SET RESULT = ''NaN'' WHERE EXPRESSION = '''+@EXP+'''' 
				EXECUTE sp_executesql @EXE--PRINT @EXE
			END 
		END CATCH   
		SET @RowCnt = @RowCnt + 1 
	END   
	SET @RowCnt = 1 
	SET @MaxRows =(SELECT COUNT(*) FROM #ResultProvider) 
	WHILE @RowCnt <= @MaxRows
	BEGIN    
		SET @RESULT = @RESULT + (SELECT REPLACE(ISNULL(EXPRESSION,''),';','[semi]')+':'+REPLACE(ISNULL(RESULT,''),';','[semi]')+';' FROM #ResultProvider  WHERE ROWID = @RowCnt) 
		SET @RowCnt = @RowCnt + 1 
	END   
	SET @RESULTSET = @RESULT 
END
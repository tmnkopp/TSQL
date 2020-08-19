/*  
who: TKOPP 
when: 8-6-2020
why: converts list of item/val pairs to matrix 
how: 
SELECT * FROM dbo.fn_HashSplit('2:2; min(1,2):1; 1+1:2; 2+2:4; 1/0:NaN; 0/0:NaN; 100*(12+12)/((12+12)+(12+12))+(100*2/9)*2+6:100;', ':' , ';') 

*/ 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_HashSplit]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')) 
	DROP FUNCTION [dbo].[fn_HashSplit]
GO 
CREATE FUNCTION dbo.fn_HashSplit(
  @List NVARCHAR(4000)
, @ItemValDelimit NVARCHAR(155) = ':' 
, @ListDelimit NVARCHAR(155) = ';'
) RETURNS @LISTTBL TABLE (ITEM NVARCHAR(4000), VALUE NVARCHAR(4000)) 
BEGIN 
	DECLARE @SET NVARCHAR(4000) 
	DECLARE @TMP TABLE (ROWNUM INT IDENTITY (1, 1), KY NVARCHAR(4000), VL NVARCHAR(4000))  
	INSERT INTO @TMP (KY,VL)
	SELECT CONVERT(NVARCHAR(5), IDX), ITEM FROM dbo.fn_Split(@List,@ListDelimit) 
	DECLARE @RowCnt INT = 1 
	DECLARE @MaxRows INT=(SELECT COUNT(*) FROM @TMP)
	WHILE @RowCnt <= @MaxRows
	BEGIN 
		SET @SET = (SELECT VL FROM @TMP WHERE ROWNUM = @RowCnt)   
		DECLARE @K NVARCHAR(4000) = SUBSTRING(@SET,0,CHARINDEX(@ItemValDelimit,@SET,0)) 
		DECLARE @V NVARCHAR(4000) = SUBSTRING(@SET,CHARINDEX(@ItemValDelimit,@SET,0),LEN(@SET))  
		INSERT INTO @LISTTBL SELECT @K, REPLACE(@V,@ItemValDelimit,'') 
		SET @RowCnt=@RowCnt+1
	END  
	RETURN
END 
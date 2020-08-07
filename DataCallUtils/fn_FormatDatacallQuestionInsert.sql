/*	 

 
-- =============================================
-- Author:		T.KOPP
-- Create date: 08-28-19
-- Description:	return formatted datacall questions by group
-- ============================================= 
UNITTEST  


SELECT dbo.fn_FMTQuestionInsert('[PKQ]', 1001, 5300) 
SELECT dbo.fn_FMTQuestionInsert('[SORT] sajkdfsjakd [PKQ]', 1001, 5300)    
 
	  
*/


ALTER FUNCTION fn_FMTQuestionInsert
(
	@STATEMENT NVARCHAR(MAX) = '',       
	@ROWCOUNT INT = 0,
	@SEED INT = 0 	 
)
RETURNS NVARCHAR(MAX)

AS	    
BEGIN			
				   
	DECLARE @STR_ROWCOUNT VARCHAR(15)
	SET @STR_ROWCOUNT = CONVERT(VARCHAR(15), @ROWCOUNT	) 

	DECLARE @STR_SEEDED_ROWCOUNT VARCHAR(15)
	SET @STR_SEEDED_ROWCOUNT = CONVERT(VARCHAR(15), @SEED + @ROWCOUNT	) 
		
 
	DECLARE @STATEMENT_1 NVARCHAR(MAX) 
	SET @STATEMENT_1 = REPLACE(@STATEMENT, '[PKQ]', @STR_SEEDED_ROWCOUNT)

 
	DECLARE @STATEMENT_2 NVARCHAR(MAX) 
	SET @STATEMENT_2 = REPLACE(@STATEMENT_1, '[SORT]', @STR_ROWCOUNT - 1)	
 	 										    
	RETURN  @STATEMENT_2
END	  
GO



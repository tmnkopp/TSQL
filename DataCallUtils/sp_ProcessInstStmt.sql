/*	 
--USAGE	   

SET NOCOUNT ON
EXEC sp_ProcessInstStmt
   
--UTIL
DROP FUNCTION fn_FMTQuestionInsert
	 
*/


ALTER PROCEDURE sp_ProcessInstStmt
(
	@STATEMENT NVARCHAR(MAX) = '',       
	@ROWCOUNT INT = 0 
)						  

AS	    
BEGIN			
				   
	DECLARE @REPLACEMENT_HASH TABLE(FIND VARCHAR(255), REP VARCHAR(255) )
	INSERT INTO @REPLACEMENT_HASH (FIND, REP) VALUES
	 ('1'   ,'111'	)
	,('2'   ,'22'	)
	,('3'   ,'333'  )
	,('4'   ,'444'  )

	SELECT FIND, REP FROM @REPLACEMENT_HASH 
 
END	  
GO



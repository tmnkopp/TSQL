/* 
-- =============================================
-- Author:		T.KOPP
-- Create date: 08-28-19
-- Description:	generate insert scripts for datacall
-- =============================================
UNITTEST

SELECT * FROM vw_DataCallQuestionInsertGen   
 
*/


ALTER VIEW [dbo].[vw_DataCallQuestionInsertGen] 
AS
   
  SELECT   
  PK_Question , 
  FormName, 
  FK_QuestionGroup,  
	',(' +
	'[PKQ]' + ',' +
	'@FormName' + ',' +
	'@PK_QGroup' + ',' +
	'[SORT],' +   

	CASE WHEN FK_PickListType IS NULL THEN 'NULL' ELSE
		CONVERT(varchar, FK_PickListType  )
	END   + ',' +  

	CASE WHEN FK_QuestionType IS NULL THEN 'NULL' ELSE
		CONVERT(varchar, FK_QuestionType  )
	END  + ',' +  

	CASE WHEN identifier_text IS NULL THEN 'NULL' ELSE
		'N''' +  identifier_text  + ''''  
	END   + ',' +  

	CASE WHEN QuestionText IS NULL THEN  'NULL' ELSE
		'N''' +  QuestionText  + ''''  
	END   + ',' +  
	  
	CASE WHEN help_text IS NULL THEN 'NULL' ELSE
		'N''' +  help_text  + ''''  
	END   + 
	
') /* ORIGIN[' + CONVERT(varchar, PK_Question  ) + '] */'
AS STMT
  
FROM fsma_Questions Q    
  
 
GO



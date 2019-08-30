c 
/* 
-- =============================================
-- Author:		t.kopp
-- Create date: 08-28-19
-- Description:	return formatted datacall questions by section
 


EXEC sp_DataCallQuestionInsertGen  
@PK_FORM='2018-A-SAOP'
, @NEW_PK_START=60000  



 	SELECT DISTINCT PK_Form FROM fsma_QuestionGroups  
	ORDER BY PK_QuestionGroup DESC

*/

ALTER PROCEDURE  sp_DataCallQuestionInsertGen  
		@PK_FORM VARCHAR(15) = ''  ,
		@NEW_PK_START INT = 0
AS 
BEGIN
	SET NOCOUNT ON
	DECLARE @LOOP_CNT INT = 0
	DECLARE @PKQ INT 
	DECLARE @PKQG INT 
	DECLARE @Q_COUNT INT  
	DECLARE @QGTEXT VARCHAR(255) 
 			
	DECLARE Q_CURSOR CURSOR FOR 
	SELECT QG.PK_QuestionGroup PKQG			  
		, QG.Text QGTEXT
		, (SELECT COUNT(PK_Question) FROM fsma_Questions Q WHERE Q.FK_QuestionGroup = QG.PK_QuestionGroup  ) Q_COUNT
	FROM  fsma_QuestionGroups  QG					    
	WHERE PK_FORM  IN (@PK_FORM)  ORDER BY 	PKQG ASC

	OPEN Q_CURSOR 
	FETCH NEXT FROM Q_CURSOR INTO  @PKQG,  @QGTEXT, @Q_COUNT  

	WHILE @@FETCH_STATUS = 0  
	BEGIN
 		
		SELECT N'/** QUESTION_GROUP ' +   CONVERT(nvarchar(55), @PKQG) + '  **/'
		UNION ALL  
		SELECT  N'/** ' +  @QGTEXT	+ '  **/'
		UNION ALL
		SELECT N'SET @PK_QGroup = @PK_QGroup + 1'  
		UNION ALL 
		SELECT N'INSERT INTO fsma_Questions (PK_Question, FormName, FK_QuestionGroup,sortpos,FK_PickListType, FK_QuestionType,identifier_text, QuestionText, help_text) VALUES '  
		UNION ALL 
		
		SELECT 
			CASE WHEN ROWNUM = 1 THEN 
				REPLACE(STMT, ',(',' (') 
			ELSE 
				STMT 
			END AS STMT 	
		 
		FROM 
		(
			SELECT 
			ROWNUM,  
			dbo.fn_FMTQuestionInsert(STMT, ROWNUM, @NEW_PK_START) As STMT,  FK_QuestionGroup 
		
			FROM 
			(
				SELECT ROW_NUMBER() OVER (ORDER BY PK_Question ASC) AS ROWNUM
					,  STMT 
					, FK_QuestionGroup
				FROM vw_DataCallQuestionInsertGen 
				WHERE FK_QuestionGroup = @PKQG	 --FormName = @FormName	AND 
				--AND
				--( 
				--	PK_Question IN( @PK_QUESTION , @PK_QUESTION_1, @PK_QUESTION_2, @PK_QUESTION_3, @PK_QUESTION_4  ) 
				--	OR (PK_Question BETWEEN  @PK_QUESTION_START AND @PK_QUESTION_END)   
				--) 
				
			) s1
		) s2

		SET @NEW_PK_START = @NEW_PK_START + @Q_COUNT + 10

	    FETCH NEXT FROM Q_CURSOR INTO  @PKQG,  @QGTEXT, @Q_COUNT    
	END 

	CLOSE Q_CURSOR 
	DEALLOCATE Q_CURSOR

	--IF @PK_QUESTION_START <= 0 
	--BEGIN
	--	SET @NEW_PK_START = @PK_QUESTION_START
	--END
	--
	--SELECT N'-- QUESTION_GROUP ' +  CONVERT(nvarchar(55), @PK_QUESTION_GROUP)
	--UNION ALL  
	--SELECT N'SET @PK_QGroup = @PK_QGroup + 1'  
	--UNION ALL 
	--SELECT N'INSERT INTO fsma_Questions (PK_Question, FormName, FK_QuestionGroup,sortpos,FK_PickListType, FK_QuestionType,identifier_text, QuestionText, help_text) VALUES '  
	--UNION ALL 
	--
	--SELECT 
	--	CASE WHEN ROWNUM = 1 THEN 
	--		REPLACE(STMT, ',(',' (') 
	--	ELSE 
	--		STMT 
	--	END AS STMT 	
	-- 
	--FROM 
	--(
	--	SELECT 
	--	ROWNUM,  
	--	dbo.fn_FMTQuestionInsert(STMT, ROWNUM, @NEW_PK_START) As STMT,  FK_QuestionGroup	
	--
	--	FROM 
	--	(
	--		SELECT ROW_NUMBER() OVER (ORDER BY PK_Question ASC) AS ROWNUM,  STMT , FK_QuestionGroup
	--		FROM vw_DataCallQuestionInsertGen 
	--		WHERE FK_QuestionGroup = @PK_QUESTION_GROUP		 --FormName = @FormName	AND 
	--		--AND
	--		--( 
	--		--	PK_Question IN( @PK_QUESTION , @PK_QUESTION_1, @PK_QUESTION_2, @PK_QUESTION_3, @PK_QUESTION_4  ) 
	--		--	OR (PK_Question BETWEEN  @PK_QUESTION_START AND @PK_QUESTION_END)   
	--		--) 
	--		
	--	) s1
	--) s2
 

END 

GO



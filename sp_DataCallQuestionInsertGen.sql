 
/* 
-- =============================================
-- Author:		T.KOPP
-- Create date: 08-28-19
-- Description:	return formatted datacall questions by group
  
*/

ALTER PROCEDURE  sp_DataCallQuestionInsertGen  
		@PK_FORM VARCHAR(15) = ''  ,
		@PK_QGroup INT = 0,
		@NEW_PK_START INT = 0,
		@GROUP_SEED INT = 0
AS 
BEGIN
	SET NOCOUNT ON
	DECLARE @LOOP_CNT INT = 0
	DECLARE @PKQ INT 
	DECLARE @PKQG INT 
	DECLARE @Q_COUNT INT  
	DECLARE @QGTEXT NVARCHAR(MAX) 
 			
	DECLARE Q_CURSOR CURSOR FOR 

	SELECT QG.PK_QuestionGroup PKQG			  
	, QG.Text QGTEXT
	, (SELECT COUNT(PK_Question) FROM fsma_Questions Q WHERE Q.FK_QuestionGroup = QG.PK_QuestionGroup  ) Q_COUNT
	FROM  fsma_QuestionGroups  QG					    
	WHERE PK_FORM  IN (@PK_FORM)  
	ORDER BY  PKQG ASC
	
  
	SET @NEW_PK_START = @NEW_PK_START - 1

	OPEN Q_CURSOR 
	FETCH NEXT FROM Q_CURSOR INTO  @PKQG,  @QGTEXT, @Q_COUNT  

	WHILE @@FETCH_STATUS = 0  
	BEGIN
 		
		IF  @PK_QGroup = 0 OR @PK_QGroup=@PKQG
		BEGIN
			  
			SELECT N'/** QGROUP SEED/ORIGIN ' +   CONVERT(nvarchar(9), @GROUP_SEED) + '/' + CONVERT(nvarchar(9), @PKQG) + '   **/'
			UNION ALL  
			SELECT  N'/** ' +  @QGTEXT	+ '  **/'
			UNION ALL
			SELECT N'SET @PK_QGroup = @PK_QGroup + 1'  
			UNION ALL 
			SELECT N'INSERT INTO fsma_Questions (PK_Question, FormName, FK_QuestionGroup,sortpos,FK_PickListType, FK_QuestionType,identifier_text, QuestionText, help_text) VALUES '  
			UNION ALL  
			SELECT 
				CASE WHEN ROWNUM = 1 THEN  	REPLACE(STMT, ',(',' (')  ELSE  STMT  END AS STMT 	 
			FROM  (
				SELECT 
				ROWNUM,  
				dbo.fn_FMTQuestionInsert(STMT, ROWNUM, @NEW_PK_START) As STMT,  FK_QuestionGroup  
				FROM  (
					SELECT ROW_NUMBER() OVER (ORDER BY PK_Question ASC) AS ROWNUM ,  STMT  , FK_QuestionGroup FROM vw_DataCallQuestionInsertGen  WHERE FK_QuestionGroup = @PKQG  
				) s1
			) s2

			SET @NEW_PK_START = @NEW_PK_START + @Q_COUNT + 10
			SET @GROUP_SEED = @GROUP_SEED  + 1
		END

	    FETCH NEXT FROM Q_CURSOR INTO  @PKQG,  @QGTEXT, @Q_COUNT    
	END 

	CLOSE Q_CURSOR 
	DEALLOCATE Q_CURSOR
	 
END  
GO



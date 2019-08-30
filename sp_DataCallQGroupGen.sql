USE [Cyberscope123]
GO

/****** Object:  StoredProcedure [dbo].[sp_DataCallQuestionInsertGen]    Script Date: 8/29/2019 4:09:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* 
-- =============================================
-- Author:		t.kopp
-- Create date: 08-28-19
-- Description:	return formatted datacall questions by section
-- =============================================
 DROP PROCEDUREsp_DataCallQGroupGen
-- =============================================
--USAGE

EXEC sp_DataCallQGroupGen @PK_FORM='2009-A-SAO'

-- =============================================
 DROP PROCEDURE sp_DataCallQGroupGen
-- =============================================
	SELECT Q.PK_Question PKQ
	, FK_QuestionGroup PKQG
	, Q.IDENTIFIER_TEXT IDENTIFIER_TEXT, 
	QG.Text	 QGTEXT
	FROM fsma_Questions	Q
	LEFT OUTER JOIN fsma_QuestionGroups  QG
	ON 	QG.PK_QuestionGroup =  Q.FK_QuestionGroup  
	

*/
  	  
ALTER PROCEDURE sp_DataCallQGroupGen	 
		@PK_FORM VARCHAR(155) = ''
AS
BEGIN

	DECLARE @PKQ INT 
	DECLARE @PKQG INT 
	DECLARE @IDENTIFIER_TEXT VARCHAR(55)  
	DECLARE @QGTEXT VARCHAR(255) 
 			
	DECLARE Q_CURSOR CURSOR FOR 
	SELECT Q.PK_Question PKQ
		, FK_QuestionGroup PKQG
		, Q.IDENTIFIER_TEXT IDENTIFIER_TEXT, 
		QG.Text	 QGTEXT
	FROM fsma_Questions	Q
		LEFT OUTER JOIN fsma_QuestionGroups  QG
		ON 	QG.PK_QuestionGroup =  Q.FK_QuestionGroup   
	WHERE PK_FORM  IN (@PK_FORM) 

	OPEN Q_CURSOR 
	FETCH NEXT FROM Q_CURSOR INTO @PKQ, @PKQG, @IDENTIFIER_TEXT, @QGTEXT  

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		
		UNION ALL  
		EXEC sp_DataCallQuestionInsertGen 
		@PK_QUESTION_GROUP=@PKQG  
		, @NEW_PK_START=60000 
	  

	    FETCH NEXT FROM Q_CURSOR INTO @PKQ, @PKQG, @IDENTIFIER_TEXT, @QGTEXT
	END 

	CLOSE Q_CURSOR 
	DEALLOCATE Q_CURSOR
 	  
END    
GO



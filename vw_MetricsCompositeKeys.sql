IF EXISTS (SELECT * FROM sysobjects WHERE name = 'vw_MetricsCompositeKeys' AND type = 'V')
    DROP VIEW [vw_MetricsCompositeKeys]
GO 
CREATE VIEW [dbo].[vw_MetricsCompositeKeys]   AS
   
SELECT 
	CONVERT(NVARCHAR(5), fsma_QuestionGroups.sortpos) + '-' +
	CONVERT(NVARCHAR(5), fsma_Questions.sortpos) + '-' +
    CONVERT(NVARCHAR(5), fsma_Questions.identifier_text)   
 AS ID
 ,
 fsma_QuestionGroups.PK_QuestionGroup QGROUP, 
 COUNT(PK_QuestionGroup) OVER (PARTITION BY PK_QuestionGroup ORDER BY PK_QuestionGroup) QCOUNTbyGROUP, 
 fsma_QuestionGroups.sortpos  SECTION_COUNT, 
 fsma_QuestionGroups.FK_FormPage, 
  fsma_QuestionGroups.GroupName,
  fsma_QuestionGroups.Text As GroupDesc,  
 PK_Question QPK,
 LEFT(fsma_Questions.identifier_text,5) IdText, 
 LEFT(ISNULL(fsma_QuestionTypes.code, '0'),15) QuestionTypeCode, 
 fsma_Questions.sortpos SortPos,
 PK_Form , 

 ISNULL(fsma_QuestionTypes.PK_QuestionTypeId,'0') QuestionTypeId , 
  fsma_QuestionTypes.description , 
  fsma_Questions.QuestionText QTEXT
FROM    fsma_QuestionGroups 

INNER JOIN fsma_Questions ON fsma_QuestionGroups.PK_QuestionGroup = fsma_Questions.FK_QuestionGroup 
LEFT OUTER JOIN fsma_QuestionTypes ON fsma_Questions.FK_QuestionType = fsma_QuestionTypes.PK_QuestionTypeId
GO

IF EXISTS (SELECT * FROM sysobjects WHERE name = 'vw_MetricsAnswers' AND type = 'V')
    DROP VIEW [vw_MetricsAnswers]
GO 
CREATE VIEW [dbo].[vw_MetricsAnswers]
AS

SELECT 
	CONVERT(NVARCHAR(5), fsma_QuestionGroups.sortpos) + '-' +
	CONVERT(NVARCHAR(5), fsma_Questions.sortpos) + '-' +
    CONVERT(NVARCHAR(5), fsma_Questions.identifier_text)   
 AS ID
 , 
fsma_QuestionGroups.sortpos  SECTION_COUNT,  
PK_Question QPK,
LEFT(fsma_Questions.identifier_text,5) IdText, 
LEFT(ISNULL(fsma_QuestionTypes.code, '0'),15) QuestionTypeCode, 
fsma_Questions.sortpos SortPos, 
ISNULL(fsma_QuestionTypes.PK_QuestionTypeId,'0') QuestionTypeId ,  
fsma_Answers.Answer,
fsma_Answers.FK_OrgSubmission PK_OrgSubmission,
PK_ReportingCycle_Component,
CL.Acronym,
fsma_QuestionGroups.PK_Form ,
fsma_Questions.QuestionText QTEXT
FROM      fsma_Questions 
INNER JOIN fsma_QuestionGroups ON fsma_QuestionGroups.PK_QuestionGroup = fsma_Questions.FK_QuestionGroup  -- AND  fsma_QuestionGroups.PK_Form = '2019-A-IG' 
INNER JOIN fsma_QuestionTypes ON fsma_Questions.FK_QuestionType = fsma_QuestionTypes.PK_QuestionTypeId  
LEFT JOIN fsma_Answers ON fsma_Answers.FK_Question= fsma_Questions.PK_Question
LEFT JOIN fsma_OrgSubmissions ON fsma_Answers.FK_OrgSubmission= fsma_OrgSubmissions.PK_OrgSubmission
LEFT JOIN fsma_ReportingCycle_Components ON fsma_ReportingCycle_Components.PK_ReportingCycle_Component = fsma_OrgSubmissions.FK_ReportingCycle_Component
LEFT JOIN fsma_ReportingCycles ON fsma_ReportingCycle_Components.FK_ReportingCycle = fsma_ReportingCycles.PK_ReportingCycle 
LEFT JOIN [Component List] CL ON fsma_ReportingCycle_Components.FK_Component=CL.PK_Component
-- WHERE YEAR(fsma_ReportingCycles.DateModified) >  YEAR(DATEADD(yy,-3,GETDATE())) 
-- AND fsma_OrgSubmissions.PK_FORM ='2020-A-IG'

-- SELECT  YEAR(fsma_ReportingCycles.DateModified), YEAR(DATEADD(yy,-3,GETDATE())) ,  *  FROM fsma_ReportingCycles
-- WHERE YEAR(fsma_ReportingCycles.DateModified) >  YEAR(DATEADD(yy,-3,GETDATE())) 



GO

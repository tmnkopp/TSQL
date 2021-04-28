IF EXISTS (SELECT * FROM sysobjects WHERE name = 'vw_MetricsCompositeKeys' AND type = 'V')
	DROP VIEW [vw_MetricsCompositeKeys]
GO  
CREATE VIEW vw_MetricsCompositeKeys  
 -- WITH SCHEMABINDING
AS 
    
	SELECT 
		CONVERT(NVARCHAR(5), fsma_QuestionGroups.sortpos) + '-' +
		CONVERT(NVARCHAR(5), fsma_Questions.sortpos) + '-' +
		CONVERT(NVARCHAR(5), fsma_Questions.identifier_text)   
	 AS ID
	 , PK_Form   
	 , MX.MAX_PK_ReportingCycle
	 , MN.MIN_Q_PK
	 , MX.MAX_Q_PK
	 , MX.MAX_Q_PK + 10 [MAX_Q_PK_STAG]
	 , PK_Question - MN.MIN_Q_PK [QOFFSET]
	 , MN.MIN_QG_PK
	 , MX.MAX_QG_PK
	 , MX.MAX_QG_PK + 10 [MAX_QG_PK_STAG]
	 , PK_QuestionGroup - MN.MIN_QG_PK [QGOFFSET]
	 , MN.MIN_FK_Form
	 , MX.MAX_FK_Form
	 , MX.MAX_FK_Form + 10 [MAX_FK_Form_STAG]
	 , FK_FormPage - MN.MIN_FK_Form [FK_Form_OFFSET]

	 , fsma_QuestionGroups.PK_QuestionGroup QGROUP
	 , COUNT(PK_QuestionGroup) OVER (PARTITION BY PK_QuestionGroup ORDER BY PK_QuestionGroup) QCOUNTbyGROUP 
	 , fsma_QuestionGroups.sortpos  SECTION_COUNT 
	 , fsma_QuestionGroups.FK_FormPage
	 , fsma_QuestionGroups.GroupName
	 , fsma_QuestionGroups.Text As GroupDesc  
	 , PK_Question QPK
	 , LEFT(fsma_Questions.identifier_text,5) IdText
	 , LEFT(ISNULL(fsma_QuestionTypes.code, '0'),15) QuestionTypeCode 
	 , fsma_Questions.sortpos SortPos 
	 , ISNULL(fsma_QuestionTypes.PK_QuestionTypeId,'0') QuestionTypeId 
	 , fsma_QuestionTypes.description  
	 , fsma_Questions.FK_PickList
	 , fsma_Questions.QuestionText QTEXT
	 , PK_Question AS PK
	FROM fsma_QuestionGroups  
	INNER JOIN fsma_Questions ON fsma_QuestionGroups.PK_QuestionGroup = fsma_Questions.FK_QuestionGroup 
	LEFT OUTER JOIN fsma_QuestionTypes ON fsma_Questions.FK_QuestionType = fsma_QuestionTypes.PK_QuestionTypeId
	OUTER APPLY(
		SELECT MIN(PK_Question) MIN_Q_PK, MIN(PK_QuestionGroup) MIN_QG_PK, MIN(FK_FormPage) MIN_FK_Form
		FROM fsma_Questions 
		INNER JOIN fsma_QuestionGroups QG ON QG.PK_QuestionGroup = fsma_Questions.FK_QuestionGroup 
		WHERE fsma_QuestionGroups.PK_FORM = QG.PK_FORM
	) MN
	OUTER APPLY(
		SELECT MAX(PK_Question) MAX_Q_PK
		, MAX(PK_QuestionGroup) MAX_QG_PK
		, MAX(FK_FormPage) MAX_FK_Form
		, (SELECT MAX(PK_ReportingCycle) FROM fsma_ReportingCycles) MAX_PK_ReportingCycle
		FROM fsma_Questions 
		INNER JOIN fsma_QuestionGroups QG ON QG.PK_QuestionGroup = fsma_Questions.FK_QuestionGroup  
	) MX
 
 
 
GO 
 -- CREATE UNIQUE CLUSTERED INDEX MCK_product_id ON vw_MetricsCompositeKeys(PK); GO 
 

 /*
 

*/ 

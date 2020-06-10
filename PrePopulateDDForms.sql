DECLARE @PK_FORM_TO NVARCHAR(15) = '2020-A-IG'  
DECLARE @AG_ACRONYM NVARCHAR(5) = 'DOJ'   
DECLARE @PK_FORM_TYPE NVARCHAR(15) = SUBSTRING( @PK_FORM_TO , 5, LEN(@PK_FORM_TO))  
 
--INSERT INTO fsma_Answers (Answer, FK_Question, FK_OrgSubmission ,DateModifed, Answer2 ) 
SELECT MAX(ISNULL(Answer,'0')), QPKTO, ORG_TO.PK_OrgSubmission, GETDATE(), '[::]'
FROM  vw_MetricsAnswers
LEFT JOIN (
	SELECT ID IDTO, QPK QPKTO FROM vw_MetricsAnswers WHERE PK_FORM = @PK_FORM_TO
) FORM_TO ON FORM_TO.IDTO = vw_MetricsAnswers.ID
CROSS JOIN (
	SELECT PK_OrgSubmission FROM fsma_OrgSubmissions 
	INNER JOIN fsma_ReportingCycle_Components ON fsma_ReportingCycle_Components.PK_ReportingCycle_Component = fsma_OrgSubmissions.FK_ReportingCycle_Component
	INNER JOIN [Component List] CL ON fsma_ReportingCycle_Components.FK_Component=CL.PK_Component
	WHERE PK_Form=@PK_FORM_TO	AND CL.Acronym = @AG_ACRONYM 
) ORG_TO  
WHERE ( PK_FORM LIKE '%19'+@PK_FORM_TYPE OR PK_FORM LIKE '%18'+@PK_FORM_TYPE    ) AND QPKTO IS NOT NULL
GROUP BY  QPKTO, ORG_TO.PK_OrgSubmission

--



/* 
UPDATE fsma_Answers SET ANSWER=NULL WHERE FK_OrgSubmission=22300 AND FK_Question=20001
SELECT * FROM fsma_Answers WHERE FK_OrgSubmission=22300 AND FK_Question=20001

	SELECT ID IDTO, QPK, *  FROM vw_MetricsAnswers
	WHERE PK_Form= '2020-A-IG' 
	DELETE FROM fsma_Answers WHERE Answer2='[::]' 
	SELECT * FROM fsma_ReportingCycles Order By PK_ReportingCycle DESC
*/
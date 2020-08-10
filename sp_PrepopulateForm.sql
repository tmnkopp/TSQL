IF EXISTS (SELECT * FROM sysobjects WHERE name = 'sp_PrePopulateFormLookup' AND type = 'P')
    DROP PROCEDURE sp_PrePopulateFormLookup
GO  
CREATE PROCEDURE sp_PrePopulateFormLookup 
  @PK_FORM_FROM NVARCHAR(15) = '2019-Q3-CIO' 
, @PK_FORM_TO NVARCHAR(15) = '' 
, @ACRONYM NVARCHAR(15) = ''  
AS

DECLARE @PK_OrgSubmission INT = 0 
DECLARE @PK_FORM NVARCHAR(15) = @PK_FORM_FROM

IF @ACRONYM <> ''
BEGIN
	SELECT  PK_Form , PK_OrgSubmission, PK_ReportingCycle_Component, Acronym , CL.PK_Component FROM  fsma_OrgSubmissions 
	INNER JOIN fsma_ReportingCycle_Components ON fsma_ReportingCycle_Components.PK_ReportingCycle_Component = fsma_OrgSubmissions.FK_ReportingCycle_Component
	INNER JOIN [Component List] CL ON fsma_ReportingCycle_Components.FK_Component=CL.PK_Component
	WHERE PK_Form LIKE '%' + @PK_FORM + '%' AND CL.Acronym LIKE '%' +  @ACRONYM + '%' 

	SET @PK_OrgSubmission =  (SELECT  PK_OrgSubmission FROM  fsma_OrgSubmissions 
	INNER JOIN fsma_ReportingCycle_Components ON fsma_ReportingCycle_Components.PK_ReportingCycle_Component = fsma_OrgSubmissions.FK_ReportingCycle_Component
	INNER JOIN [Component List] CL ON fsma_ReportingCycle_Components.FK_Component=CL.PK_Component
	WHERE PK_Form LIKE '%' + @PK_FORM + '%'	 AND CL.Acronym LIKE '%' +  @ACRONYM + '%' )
END 

IF @ACRONYM = ''
BEGIN
	Select Acronym , PK_Form , PK_OrgSubmission, PK_ReportingCycle_Component, Acronym  FROM  fsma_OrgSubmissions 
	INNER JOIN fsma_ReportingCycle_Components ON fsma_ReportingCycle_Components.PK_ReportingCycle_Component = fsma_OrgSubmissions.FK_ReportingCycle_Component
	INNER JOIN [Component List] CL ON fsma_ReportingCycle_Components.FK_Component=CL.PK_Component
	WHERE PK_Form LIKE '%' + @PK_FORM + '%'


END 

SELECT @PK_OrgSubmission as [@PK_OrgSubmission ]

SELECT TOP 150 * FROM vw_MetricsAnswers
WHERE PK_Form LIKE '%' + @PK_FORM + '%'
ORDER BY QPK DESC, PK_ReportingCycle_Component DESC




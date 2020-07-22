DECLARE @PK_HVA INT = 0
DECLARE @TRANS NVARCHAR(55) = 'VIEW'
DECLARE @SELECT NVARCHAR(55) = 'MISMATCH'

IF OBJECT_ID('tempdb..#HVA_LIST') IS NOT NULL  DROP TABLE #HVA_LIST
;WITH HVA_LIST (PK_HVA, SystemName, PK_Component_Agency)  
AS (   
	SELECT HVA.PK_HVA , HVA.SystemName, PK_Component_Agency FROM fsma_HVAs HVA     
)    
SELECT * INTO #HVA_LIST FROM HVA_LIST 
 
IF OBJECT_ID('tempdb..#HVA_REPORTING_CYCLE') IS NOT NULL  DROP TABLE #HVA_REPORTING_CYCLE
;WITH HVA_REPORTING_CYCLE (PK_FORM, PK_OrgSubmission, PK_ReportingCycle_Component, Acronym, PK_Component, PK_Component_Agency, PK_HVA, SystemName)  
AS (   
	SELECT 
	  ORG.PK_FORM 
	, ORG.PK_OrgSubmission 
	, RCC.PK_ReportingCycle_Component 
	, CL.Acronym 
	, RCC.FK_Component --< AGENCY KEY FOR REPORTING CYCLE  
	, HVA.PK_Component_Agency  --< HVA AGENCY KEY (THIS KEY SHOULD MATCH / SHOULD BE MOST RECENT AGENCY)
	, HVA.PK_HVA 
	, HVA.SystemName   
	FROM fsma_OrgSubmissions ORG 
	INNER JOIN fsma_ReportingCycle_Components RCC ON ORG.FK_ReportingCycle_Component=RCC.PK_ReportingCycle_Component  
	INNER JOIN [Component List] CL ON RCC.FK_Component=CL.PK_Component
	LEFT JOIN fsma_OrgSubHVAMap MAP ON ORG.PK_OrgSubmission=MAP.PK_OrgSubmission
	LEFT JOIN fsma_HVAs HVA ON HVA.PK_HVA=MAP.PK_HVA   
	WHERE ORG.PK_FORM='2020-A-HVA'
)    
SELECT * INTO #HVA_REPORTING_CYCLE FROM HVA_REPORTING_CYCLE 
 
IF OBJECT_ID('tempdb..#HVA_AGENCY_2019') IS NOT NULL DROP TABLE #HVA_AGENCY_2019  
;WITH HVA_AGENCY_2019 ( FK_Component, PK_OrgSubmission,  Acronym , PK_HVA ) AS (   
	SELECT RCC.FK_Component , ORG.PK_OrgSubmission , CL.Acronym , HVA.PK_HVA 
	FROM fsma_HVAs HVA 
	INNER JOIN fsma_OrgSubmissions ORG ON HVA.PK_OrgSubmission = ORG.PK_OrgSubmission
	INNER JOIN fsma_ReportingCycle_Components RCC ON ORG.FK_ReportingCycle_Component = RCC.PK_ReportingCycle_Component  
	INNER JOIN [Component List] CL ON RCC.FK_Component = CL.PK_Component  
	WHERE PK_FORM = '2019-A-HVA'   
)  
SELECT * INTO #HVA_AGENCY_2019 FROM HVA_AGENCY_2019 

IF OBJECT_ID('tempdb..#AGENCY_RCC_HVA2020') IS NOT NULL  DROP TABLE #AGENCY_RCC_HVA2020 
;WITH AGENCY_RCC_HVA2020 ( FK_Component, PK_OrgSubmission, PK_ReportingCycle_Component, Acronym, PK_HVA  ) AS (   
	SELECT RCC.FK_Component , ORG.PK_OrgSubmission , RCC.PK_ReportingCycle_Component , CL.Acronym, HVA.PK_HVA 
	FROM fsma_OrgSubmissions ORG 
	INNER JOIN fsma_ReportingCycle_Components RCC ON ORG.FK_ReportingCycle_Component = RCC.PK_ReportingCycle_Component  
	INNER JOIN [Component List] CL ON RCC.FK_Component = CL.PK_Component 
	LEFT JOIN fsma_OrgSubHVAMap MAP ON ORG.PK_OrgSubmission=MAP.PK_OrgSubmission
	LEFT JOIN fsma_HVAs HVA ON HVA.PK_HVA=MAP.PK_HVA   
	WHERE PK_FORM = '2020-A-HVA' 
)  
SELECT * INTO #AGENCY_RCC_HVA2020 FROM AGENCY_RCC_HVA2020 

IF OBJECT_ID('tempdb..#RCC_HVA2020') IS NOT NULL  DROP TABLE #RCC_HVA2020 
;WITH RCC_HVA2020 ( FK_Component, PK_ReportingCycle_Component ) AS (   
	SELECT RCC.FK_Component ,  RCC.PK_ReportingCycle_Component 
	FROM fsma_ReportingCycle_Components RCC  
	WHERE RCC.FK_ReportingCycle = 88 --ORDER BY PK_ReportingCycle_Component
)  
SELECT * INTO #RCC_HVA2020 FROM RCC_HVA2020
   
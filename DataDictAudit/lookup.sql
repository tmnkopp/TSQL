DECLARE @PKHVA INT = (SELECT ISNULL(PK_HVA, 0) PK_HVA FROM #DICT WHERE ROWNUM = @RowCnt) 
		 
DECLARE @PK_OrgSubmission INT = (
	SELECT TOP 1 ISNULL(ORG.PK_OrgSubmission,0) FROM fsma_OrgSubHVAMap
	INNER JOIN fsma_OrgSubmissions ORG ON ORG.PK_OrgSubmission=fsma_OrgSubHVAMap.PK_OrgSubmission 
	INNER JOIN fsma_ReportingCycle_Components RCC ON RCC.PK_ReportingCycle_Component=ORG.FK_ReportingCycle_Component
	WHERE PK_HVA=@PKHVA AND ORG.PK_Form=@PK_FORM AND @PK_ReportingCycle_Component=@PK_ReportingCycle_Component 
)   
-- IF NO MAPPING EXISTS
IF @PK_OrgSubmission = 0 OR @PK_OrgSubmission IS NULL
BEGIN 

	SELECT MAP.PK_Orgsubmission, * 
	FROM fsma_OrgSubHVAMap MAP
	WHERE MAP.PK_Orgsubmission NOT IN ( 
		SELECT ORG.PK_Orgsubmission FROM fsma_OrgSubmissions ORG 
		WHERE ORG.PK_Form IN ('2019-A-HVA','2020-A-HVA')
	) 

	SELECT MAP.PK_HVA, * 
	FROM fsma_OrgSubHVAMap MAP
	WHERE MAP.PK_HVA NOT IN ( 
		SELECT HVA.PK_HVA FROM fsma_HVAs HVA  
	) 
		
	PRINT 'MAPPED HVA OrgSub: ' 
		+ CONVERT(NVARCHAR(15), @PK_OrgSubmission) 
		+ ' PK_HVA: ' +  CONVERT(NVARCHAR(15), @PKHVA) 
		+ ' PK_FORM: ' +  CONVERT(NVARCHAR(15), @PK_FORM) 
END

RETURN; 

DECLARE @PK_HVA INT = 675

  EXEC HVA_TRANSACTIONS 
	  @TRANS='TRY_MAP_HVA_TO_REPORTING_CYCLE' 
	, @PK_ReportingCycle = 74
	, @PK_Component_Agency = 170
	, @PK_HVA = 0

exec HVAMaster @PK_Component_Agency=N'170',@VIEW=N'AGENCY_HVAS'
  
RETURN; 
SELECT * FROM fsma_OrgSubmissions WHERE PK_OrgSubmission IN (SELECT PK_OrgSubmission FROM fsma_OrgSubHVAMap WHERE PK_HVA=@PK_HVA )   
SELECT * FROM fsma_OrgSubHVAMap WHERE PK_HVA=@PK_HVA 
SELECT * FROM fsma_HVAs WHERE PK_HVA=@PK_HVA  ORDER BY PK_HVA DESC 
RETURN; 
 
IF @PK_HVA IS NOT NULL
BEGIN
	DELETE FROM fsma_OrgSubmissions WHERE PK_OrgSubmission IN (SELECT PK_OrgSubmission FROM fsma_OrgSubHVAMap WHERE PK_HVA=@PK_HVA )   
	DELETE FROM fsma_OrgSubHVAMap WHERE PK_HVA=@PK_HVA 
	--DELETE FROM fsma_HVAs WHERE PK_HVA=@PK_HVA 
END 


RETURN;  
RETURN; 
--EXEC HVAMaster @VIEW='AGENCY_HVAS', @PK_Component_Agency='170'
--EXEC HVAMaster @VIEW=N'HVA_ANNUAL',@PK_HVA=N'662'

SELECT TOP 5 * FROM fsma_OrgSubmissions ORDER BY PK_OrgSubmission DESC 
SELECT TOP 5 * FROM fsma_OrgSubHVAMap ORDER BY PK_OrgSubmission DESC
SELECT TOP 5 * FROM fsma_HVAs ORDER BY PK_HVA DESC

RETURN ;  

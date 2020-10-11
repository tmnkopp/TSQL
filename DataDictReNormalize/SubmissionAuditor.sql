--TESTING DEFAULTS
	DECLARE @PK_POAM INT = 18 
	DECLARE @PK_Bureau INT = 0
	DECLARE @POAMSubmissionDate DATE = GETDATE()--'2020-07-19'-- SET THIS TO DATE SUBMITTED, USE CURRENT DATE FOR PERFORMANCE TESTING 
 
--CQ FORM DEFAULTS 
	DECLARE @SubmissionDate As DATE = @POAMSubmissionDate  
	IF @POAMSubmissionDate IS NULL OR @POAMSubmissionDate='' SET @SubmissionDate=GETDATE()  
	DECLARE @PK_FORM As NVARCHAR(15) = '2020-A-HVAPOAM'  
--BEGIN QUERY

	--FIELD META INFO FOR DYNAMIC Qs AND JOINS
	IF OBJECT_ID('tempdb..#FIELD_META') IS NOT NULL DROP TABLE #FIELD_META 
	SELECT * INTO #FIELD_META FROM (    
		SELECT COLUMN_NAME FieldName, ORDINAL_POSITION SortOrder , 
		CASE WHEN COLUMN_NAME='AssmtTitle' THEN 'Assessment Title'
		WHEN COLUMN_NAME='AssmtSource' THEN 'Assessment Source'
		WHEN COLUMN_NAME='AgRecievedDate' THEN 'Recieved Date'
		WHEN COLUMN_NAME='RiskCat' THEN 'Risk Cat'
		WHEN COLUMN_NAME='RiskFactor' THEN 'Risk Factor'
		ELSE COLUMN_NAME
		END FieldCaption
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME='fsma_POAMS' AND COLUMN_NAME IN('AssmtTitle', 'AssmtSource', 'Status', 'RiskCat', 'RiskFactor', 'AgRecievedDate')
	)	FIELD_META 
		CREATE CLUSTERED INDEX IX_FIELD_META_CLUST ON #FIELD_META ( FieldName ) 
	--SELECT * FROM #FIELD_META ORDER BY SortOrder RETURN; -- DEBUG BREAKPOINT 
	--AUDITVIEW
    IF OBJECT_ID('tempdb..#AUDITVIEW') IS NOT NULL DROP TABLE #AUDITVIEW
	SELECT * INTO #AUDITVIEW FROM(
		SELECT AuditLog.PK_AuditLog, AuditLog.TABLENAME, CONVERT(NVARCHAR(255), LEFT(AuditLog.FieldName,255)) FieldName, AuditLog.FieldValue, AuditLog.PK_PrimeKey, AuditLog.CHANGE_DATE FROM AuditLog 
		WHERE TABLENAME IN('fsma_POAMS') AND EditType <> 'D' 
		AND CHANGE_DATE > DATEADD(MONTH, -12, @SubmissionDate) AND CHANGE_DATE < DATEADD(DAY, 1, @SubmissionDate)
		AND FieldName IN (SELECT CONVERT(NVARCHAR(55), FieldName) FROM #FIELD_META)
		AND FieldValue IS NOT NULL
	)	AUDITVIEW 
		CREATE CLUSTERED INDEX IX_AUDITVIEW_CLUST ON #AUDITVIEW ( PK_AuditLog ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_PK_PrimeKey ON #AUDITVIEW ( PK_PrimeKey ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_FieldName ON #AUDITVIEW ( TABLENAME, FieldName )  
	--SELECT * FROM #AUDITVIEW RETURN; -- DEBUG BREAKPOINT 
	--AUDITS BY DAY
	IF OBJECT_ID('tempdb..#AUDITFLAT') IS NOT NULL DROP TABLE #AUDITFLAT 
	SELECT * INTO #AUDITFLAT FROM  (  
		SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.CHANGE_DATE, PK_POAM, FieldName 
		FROM ( SELECT CONVERT(NVARCHAR(10), CHANGE_DATE, 121)  CHANGE_DATE,  PK_AuditLog, FieldName, PK_PrimeKey As [PK_POAM] FROM #AUDITVIEW ) 
			CONVERTDATE GROUP BY CHANGE_DATE, PK_POAM, FieldName  
	)	AUDITFLAT 
		CREATE CLUSTERED INDEX IX_AUDITS_CLUST ON #AUDITFLAT ( PK_AuditLog )      
	--SELECT * FROM #AUDITFLAT RETURN; -- DEBUG BREAKPOINT 
	--FLATTEN DAY  
	IF OBJECT_ID('tempdb..#POAM_AUDITS') IS NOT NULL DROP TABLE #POAM_AUDITS
	SELECT * INTO #POAM_AUDITS FROM (
		SELECT PK_PrimeKey As PK_POAM, #AUDITVIEW.PK_AuditLog, FieldValue, #FIELD_META.FieldName FieldName, #FIELD_META.FieldCaption, #AUDITFLAT.CHANGE_DATE, #AUDITVIEW.PK_PrimeKey  
		FROM #AUDITVIEW 
		INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#AUDITVIEW.FieldName 
		WHERE #AUDITVIEW.TableName='fsma_POAMS'  
	)	POAM_AUDITS 
		CREATE CLUSTERED INDEX IX_POAM_AUDITS_CLUST ON #POAM_AUDITS ( PK_PrimeKey ) 
		CREATE NONCLUSTERED INDEX IX_POAM_AUDITS_PK ON #POAM_AUDITS ( PK_POAM )   
          
	--SELECT * FROM #POAM_AUDITS RETURN; -- DEBUG BREAKPOINT 
	--FLATTEN SUBMISSIONS 
	IF OBJECT_ID('tempdb..#SUBMISSIONLOG') IS NOT NULL DROP TABLE #SUBMISSIONLOG  
	SELECT * INTO #SUBMISSIONLOG FROM (
		SELECT #POAM_AUDITS.PK_POAM, #POAM_AUDITS.CHANGE_DATE [SUBMISSION_DATE], #POAM_AUDITS.FieldValue, #POAM_AUDITS.FieldName, #POAM_AUDITS.FieldCaption
		FROM #POAM_AUDITS  
		INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_POAM, FieldName FROM #POAM_AUDITS 
				GROUP BY PK_POAM, FieldName  
		) MAXDATE ON MAXDATE.FieldName=#POAM_AUDITS.FieldName
			AND MAXDATE.CHANGE_DATE=#POAM_AUDITS.CHANGE_DATE
			AND MAXDATE.PK_POAM=#POAM_AUDITS.PK_POAM 
	) SUBMISSIONLOG 
		CREATE NONCLUSTERED INDEX IX_SUBMISSION_FieldName ON #SUBMISSIONLOG ( PK_POAM, FieldName )   
	--SELECT * FROM #SUBMISSIONLOG RETURN; -- DEBUG BREAKPOINT 
	  
	--VIEWABLE FIELDS
	IF OBJECT_ID('tempdb..#SUBMISSION_VIEW') IS NOT NULL DROP TABLE #SUBMISSION_VIEW 
	SELECT * INTO #SUBMISSION_VIEW FROM (
		SELECT  AGENCY.Component AGENCY, BUREAU.Component BUREAU, BUREAU.PK_BUREAU, HVA.SystemName HVA, #SUBMISSIONLOG.PK_POAM, #SUBMISSIONLOG.SUBMISSION_DATE, #SUBMISSIONLOG.FieldName, #SUBMISSIONLOG.FieldCaption
		, CASE 
			WHEN #FIELD_META.FieldName='Status' OR #FIELD_META.FieldName='AssmtSource' OR #FIELD_META.FieldName='RiskFactor' OR #FIELD_META.FieldName='RiskCat'  THEN
				 (SELECT DisplayValue FROM PickLists WHERE PK_PickList = CONVERT(INT,#SUBMISSIONLOG.FieldValue)) 
			ELSE #SUBMISSIONLOG.FieldValue
			END FieldValue 		 
			FROM #SUBMISSIONLOG 
			INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#SUBMISSIONLOG.FieldName 
			INNER JOIN fsma_POAMS POAM ON #SUBMISSIONLOG.PK_POAM = POAM.PK_POAM
			INNER JOIN fsma_HVAs HVA ON HVA.PK_HVA=POAM.FK_PK_HVA
			LEFT JOIN (
				SELECT PK_HVA, AG.PK_Component PK_Agency, AG.Component
				FROM fsma_HVAs HVA
				INNER JOIN fsma_OrgSubmissions ORG ON ORG.PK_OrgSubmission = HVA.PK_OrgSubmission
				INNER JOIN fsma_ReportingCycle_Components RCC ON RCC.PK_ReportingCycle_Component = ORG.FK_ReportingCycle_Component
				INNER JOIN [Component List] AG ON AG.PK_Component=RCC.FK_Component  
			) AGENCY ON AGENCY.PK_HVA = HVA.PK_HVA 
			LEFT JOIN (
				SELECT HVA.PK_HVA  
				, CASE WHEN  B.PK_Component IS NULL THEN -1 ELSE  B.PK_Component END PK_BUREAU
				, CASE WHEN B.Component IS NULL THEN 'UNKNOWN' ELSE B.Component END Component
				FROM fsma_HVAs HVA LEFT JOIN [Component List] B ON  B.PK_Component=HVA.PK_Component AND B.FK_PK_Component IS NOT NULL
			) BUREAU ON BUREAU.PK_HVA = HVA.PK_HVA 
		) SUBMISSION_VIEW 
		CREATE NONCLUSTERED INDEX IX_SUBMISSION_VIEW_PK_POAM ON #SUBMISSION_VIEW ( PK_POAM )   
	--SELECT * FROM #SUBMISSION_VIEW RETURN; -- DEBUG BREAKPOINT
	/*
		AND ((SELECT CodeValue FROM PickLists WHERE PK_PickList = AssmtSource.PK_PickList) =  @AssmtSource OR (@AssmtSource = ''))
		AND ((SELECT CodeValue FROM PickLists WHERE PK_PickList = POAMSTAT.PK_PickList) = @POAMSTAT OR (@POAMSTAT = ''))
	*/

	IF @PK_Bureau = 0 
	BEGIN
		DELETE FROM #SUBMISSION_VIEW WHERE PK_BUREAU = -1 
	END 
	IF @PK_Bureau > 0 
	BEGIN
		DELETE FROM #SUBMISSION_VIEW WHERE PK_BUREAU <> @PK_Bureau
	END
	IF @PK_Bureau =- 1 
	BEGIN
		DELETE FROM #SUBMISSION_VIEW WHERE PK_BUREAU > -1 
	END	
 
	DECLARE @COLS AS NVARCHAR(MAX)=''; 
	DECLARE @exe NVARCHAR(MAX) = '';  
	SELECT @COLS = @COLS + QUOTENAME(FieldCaption) + ',' FROM #FIELD_META ORDER BY SortOrder
	SELECT @COLS = SUBSTRING(@COLS, 0, LEN(@COLS))   

	IF OBJECT_ID('tempdb..#RESULTS_VIEW') IS NOT NULL DROP TABLE #RESULTS_VIEW
	--SET @exe=@exe+'  SELECT * INTO #RESULTS_VIEW FROM ('	
	SET @exe=@exe+'  SELECT * INTO #RESULTS_VIEW FROM ('
		SET @exe=@exe+'	 SELECT AGENCY, BUREAU, HVA, PK_POAM, FieldValue, FieldCaption'
		SET @exe=@exe+'	 FROM #SUBMISSION_VIEW '  
		SET @exe=@exe+') PV PIVOT  ('
		SET @exe=@exe+'	 MAX(FieldValue)  '
		SET @exe=@exe+'	 FOR FieldCaption IN ( '+ @COLS +' )'
	SET @exe=@exe+') P ORDER BY PK_POAM DESC' 

	SET @exe=@exe+'; SELECT * FROM #RESULTS_VIEW ' 

	EXECUTE sp_executesql @exe 
	
 
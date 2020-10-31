--TESTING DEFAULTS -- SELECT * FROM fsma_HVAs
	DECLARE @PK_Component INT = 109
	DECLARE @PK_HVA INT = 30 -- 111 -- 
	DECLARE @PK_POAM INT = 18  
	DECLARE @PK_Bureau INT = 0
	DECLARE @POAMSubmissionDate DATE =  CONVERT(NVARCHAR(10), '10-12-2020', 121)  --  '10-08-2020' --  10-08-2020 SET THIS TO DATE SUBMITTED, USE CURRENT DATE FOR PERFORMANCE TESTING 
	DECLARE @GETDATE DATE = CONVERT(NVARCHAR(10), GETDATE() , 121)
	DECLARE @AssmtSource NVARCHAR(15) = 'RVA'  
	DECLARE @POAMSTAT NVARCHAR(15) = 'IP'   
	DECLARE @SubmissionDate As DATE = @POAMSubmissionDate  
	IF @SubmissionDate IS NULL OR @SubmissionDate='' SET @SubmissionDate=@GETDATE
	
 	IF OBJECT_ID('tempdb..#RESULTS_VIEW') IS NOT NULL DROP TABLE #RESULTS_VIEW  
	SELECT * INTO #RESULTS_VIEW FROM  
	(	SELECT  
		  AGENCY.Component AGENCY
		, BUREAU.Component BUREAU    
		, BUREAU.PK_BUREAU   
		, HVA.SystemName    
		, PK_POAM   
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=POAM.Status) [Status] 
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=RiskCat) RiskCat 
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=RiskFactor) RiskFactor 
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=AssmtSource) AssmtSource
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=AssmtFinding) Finding
		, POAM.AgRecievedDate 
		, MS.Title MSTitle
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=MS.Status) MSStatus
		, ACT.Description
		, (SELECT DisplayValue FROM PickLists WHERE PK_PickList=ACT.Status) ACTStatus
		FROM  fsma_POAMS POAM 
		INNER JOIN (
			SELECT MS.PK_Milestone, MS.Title, MS.Status, FK_PK_POAM FROM fsma_Milestones MS 
		) MS ON MS.FK_PK_POAM = POAM.PK_POAM  
		INNER JOIN (
			SELECT ACT.PK_Activity, ACT.Description, ACT.Status, FK_PK_Milestone FROM fsma_Activities ACT 
		) ACT ON ACT.FK_PK_Milestone = MS.PK_Milestone 
		LEFT JOIN fsma_HVAs HVA ON HVA.PK_HVA = POAM.FK_PK_HVA 
		INNER JOIN (
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
			FROM fsma_HVAs HVA 
			LEFT JOIN [Component List] B ON  B.PK_Component=HVA.PK_Component AND B.FK_PK_Component IS NOT NULL
		) BUREAU ON BUREAU.PK_HVA = HVA.PK_HVA    
		WHERE AGENCY.PK_Agency = @PK_Component
		AND POAM.isActive = 1 
		AND POAM.PK_POAM=@PK_POAM 
	) RESULTS_CURRENT
 
	IF @SubmissionDate <> @GETDATE 
	BEGIN  
		DELETE FROM #RESULTS_VIEW
		IF OBJECT_ID('tempdb..#AUDITVIEW') IS NOT NULL DROP TABLE #AUDITVIEW
		SELECT * INTO #AUDITVIEW FROM(
			SELECT AuditLog.PK_AuditLog, AuditLog.TABLENAME, CONVERT(NVARCHAR(255), LEFT(AuditLog.FieldName,255)) FieldName, AuditLog.FieldValue, AuditLog.PK_PrimeKey, AuditLog.CHANGE_DATE 
			FROM AuditLog 
			WHERE TABLENAME IN('fsma_POAMS', 'fsma_Milestones', 'fsma_Activities') AND EditType <> 'D' 
			AND CHANGE_DATE > DATEADD(MONTH, -6, @SubmissionDate) AND CHANGE_DATE < DATEADD(DAY, 1, @SubmissionDate) 
			AND FieldValue IS NOT NULL
		)	AUDITVIEW 
			CREATE CLUSTERED INDEX IX_AUDITVIEW_CLUST ON #AUDITVIEW ( PK_AuditLog ) 
			CREATE NONCLUSTERED INDEX IX_AUDITVIEW_PK_PrimeKey ON #AUDITVIEW ( PK_PrimeKey ) 
			CREATE NONCLUSTERED INDEX IX_AUDITVIEW_FieldName ON #AUDITVIEW ( TABLENAME, FieldName )   
		IF OBJECT_ID('tempdb..#AUDITFLAT') IS NOT NULL DROP TABLE #AUDITFLAT 
		SELECT * INTO #AUDITFLAT FROM  (  
			SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.CHANGE_DATE, PK_PrimeKey, FieldName 
			FROM ( SELECT CONVERT(NVARCHAR(10), CHANGE_DATE, 121)  CHANGE_DATE,  PK_AuditLog, FieldName, PK_PrimeKey FROM #AUDITVIEW ) 
				CONVERTDATE GROUP BY CHANGE_DATE, PK_PrimeKey, FieldName  
		)	AUDITFLAT 
			CREATE CLUSTERED INDEX IX_AUDITS_CLUST ON #AUDITFLAT ( PK_AuditLog )        
		;WITH POAM_AUDITS AS (
			SELECT #AUDITVIEW.PK_PrimeKey, #AUDITVIEW.PK_AuditLog , FieldValue , #AUDITVIEW.FieldName FieldName , #AUDITFLAT.CHANGE_DATE 
			FROM #AUDITVIEW INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog  
			WHERE #AUDITVIEW.TableName='fsma_POAMS' AND #AUDITVIEW.PK_PrimeKey=@PK_POAM  
		), POAM_SUBMISSIONLOG AS (
			SELECT POAM_AUDITS.PK_PrimeKey, POAM_AUDITS.CHANGE_DATE [SUBMISSION_DATE], POAM_AUDITS.FieldValue, POAM_AUDITS.FieldName 
			FROM POAM_AUDITS  
			INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_PrimeKey, FieldName FROM POAM_AUDITS 
				GROUP BY PK_PrimeKey, FieldName  
			) MAXDATE ON MAXDATE.FieldName=POAM_AUDITS.FieldName
				AND MAXDATE.CHANGE_DATE=POAM_AUDITS.CHANGE_DATE
				AND MAXDATE.PK_PrimeKey=POAM_AUDITS.PK_PrimeKey 
		), POAM_SUBMISSION_VIEW AS (
			SELECT AGENCY.Component AGENCY
			, BUREAU.Component BUREAU
			, BUREAU.PK_BUREAU
			, HVA.SystemName HVA
			, POAM_SUBMISSIONLOG.PK_PrimeKey 
			, POAM_SUBMISSIONLOG.SUBMISSION_DATE
			, POAM_SUBMISSIONLOG.FieldName
			, CASE  
				WHEN POAM_SUBMISSIONLOG.FieldName='Status' 
				OR POAM_SUBMISSIONLOG.FieldName='AssmtSource' 
				OR POAM_SUBMISSIONLOG.FieldName='AssmtFinding' 
				OR POAM_SUBMISSIONLOG.FieldName='RiskFactor' 
				OR POAM_SUBMISSIONLOG.FieldName='RiskCat' THEN
					(SELECT DisplayValue FROM PickLists WHERE PK_PickList = CONVERT(INT,POAM_SUBMISSIONLOG.FieldValue)) 
				ELSE POAM_SUBMISSIONLOG.FieldValue
				END FieldValue 		 
			FROM POAM_SUBMISSIONLOG  
			INNER JOIN fsma_POAMS POAM ON POAM_SUBMISSIONLOG.PK_PrimeKey = POAM.PK_POAM
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
			WHERE AGENCY.PK_Agency = @PK_Component
			AND HVA.PK_HVA=@PK_HVA
		),MS_AUDITS AS (
			SELECT #AUDITVIEW.PK_PrimeKey, #AUDITVIEW.PK_AuditLog, FieldValue, #AUDITVIEW.FieldName FieldName, #AUDITFLAT.CHANGE_DATE 
			FROM #AUDITVIEW INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog  
			WHERE #AUDITVIEW.TableName='fsma_Milestones'  
		),MS_SUBMISSIONLOG AS (
			SELECT MS_AUDITS.PK_PrimeKey, MS_AUDITS.CHANGE_DATE [SUBMISSION_DATE], MS_AUDITS.FieldValue, MS_AUDITS.FieldName 
			FROM MS_AUDITS  
			INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_PrimeKey, FieldName 
				FROM MS_AUDITS GROUP BY PK_PrimeKey, FieldName  
			) MAXDATE ON MAXDATE.FieldName=MS_AUDITS.FieldName
				AND MAXDATE.CHANGE_DATE=MS_AUDITS.CHANGE_DATE
				AND MAXDATE.PK_PrimeKey=MS_AUDITS.PK_PrimeKey 
		),ACT_AUDITS AS (
			SELECT #AUDITVIEW.PK_PrimeKey, #AUDITVIEW.PK_AuditLog, FieldValue, #AUDITVIEW.FieldName FieldName, #AUDITFLAT.CHANGE_DATE 
			FROM #AUDITVIEW INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog  
			WHERE #AUDITVIEW.TableName='fsma_Activities'  
		),ACT_SUBMISSIONLOG AS (
			SELECT ACT_AUDITS.PK_PrimeKey, ACT_AUDITS.CHANGE_DATE [SUBMISSION_DATE], ACT_AUDITS.FieldValue, ACT_AUDITS.FieldName 
			FROM ACT_AUDITS  
			INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_PrimeKey, FieldName 
				FROM ACT_AUDITS GROUP BY PK_PrimeKey, FieldName  
			) MAXDATE ON MAXDATE.FieldName=ACT_AUDITS.FieldName
				AND MAXDATE.CHANGE_DATE=ACT_AUDITS.CHANGE_DATE
				AND MAXDATE.PK_PrimeKey=ACT_AUDITS.PK_PrimeKey 
		),POAM_PIVOT AS( 
			SELECT AGENCY, BUREAU, PK_BUREAU, HVA [SystemName], POAM_PIVOT.PK_PrimeKey PK_POAM, POAM_PIVOT.[Status],[RiskCat],[RiskFactor],[AssmtSource],[AssmtFinding] Finding,[AgRecievedDate] 
			--,fsma_Activities.FK_PK_Milestone ,fsma_Activities.PK_Activity 
			,MS_PIVOT.[Title] [MSTitle]
			,(SELECT DisplayValue FROM PickLists WHERE PK_PickList = CONVERT(INT,MS_PIVOT.[StatusDisplay])) [MSStatus]
			,ACT_PIVOT.[Description] [Description]
			,(SELECT DisplayValue FROM PickLists WHERE PK_PickList = CONVERT(INT,ACT_PIVOT.[StatusDisplay])) [ACTStatus]
			FROM (
				SELECT * FROM (
					SELECT AGENCY, BUREAU, PK_BUREAU, HVA, PK_PrimeKey, FieldValue, FieldName 
					FROM POAM_SUBMISSION_VIEW 
				) P PIVOT ( MAX(FieldValue) FOR FieldName IN ([Status],[RiskCat],[RiskFactor],[AssmtSource],[AssmtFinding],[AgRecievedDate])
				) POAM_PIVOT
			) POAM_PIVOT
			INNER JOIN fsma_Milestones ON fsma_Milestones.FK_PK_POAM=POAM_PIVOT.PK_PrimeKey
			INNER JOIN fsma_Activities ON fsma_Activities.FK_PK_Milestone=fsma_Milestones.PK_Milestone
			INNER JOIN(
				SELECT * FROM (
					SELECT PK_PrimeKey, FieldValue, FieldName FROM MS_SUBMISSIONLOG 
				) P PIVOT ( MAX(FieldValue) FOR FieldName IN ([StatusDisplay],[Title])
				) MS_PIVOT  
			) MS_PIVOT ON MS_PIVOT.PK_PrimeKey=fsma_Milestones.PK_Milestone
			INNER JOIN(
				SELECT * FROM (
					SELECT PK_PrimeKey, FieldValue, FieldName FROM ACT_SUBMISSIONLOG 
				) P PIVOT ( MAX(FieldValue) FOR FieldName IN ([StatusDisplay],[Description])
				) ACT_PIVOT  
			) ACT_PIVOT ON ACT_PIVOT.PK_PrimeKey=fsma_Activities.PK_Activity
		)
 		INSERT INTO #RESULTS_VIEW 
		SELECT * FROM POAM_PIVOT 
	END  
	--SELECT * FROM #RESULTS_VIEW RETURN;
	IF @SubmissionDate = @GETDATE 
	BEGIN
		IF @AssmtSource <> ''
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE AssmtSource <> (SELECT DisplayValue FROM PickLists PL 
			INNER JOIN PickListTypes PLT ON PL.PK_PickListType = PLT.PK_PickListType WHERE UsageField = 'AssmtSource' AND CodeValue=@AssmtSource)
		END 
		IF @POAMSTAT <> ''
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE [Status] <> (SELECT DisplayValue FROM PickLists PL 
			INNER JOIN PickListTypes PLT ON PL.PK_PickListType = PLT.PK_PickListType WHERE UsageField = 'POAMSTAT' AND CodeValue=@POAMSTAT)
		END 
		IF @PK_Bureau = 0 
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE PK_BUREAU = -1 
		END 
		IF @PK_Bureau > 0 
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE PK_BUREAU <> @PK_Bureau
		END
		IF @PK_Bureau =- 1 
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE PK_BUREAU > -1 
		END	 
	END 
	SELECT AGENCY, BUREAU, SystemName, [Status],[RiskCat],[RiskFactor],[AssmtSource],[Finding],[AgRecievedDate],[MSTitle],[MSStatus],Description,ACTStatus FROM #RESULTS_VIEW  
 
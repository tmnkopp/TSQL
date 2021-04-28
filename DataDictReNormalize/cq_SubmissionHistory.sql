IF EXISTS (SELECT * FROM sysobjects WHERE name = 'cq_HVAPOAM_ACTS' AND type = 'P')
    DROP PROCEDURE cq_HVAPOAM_ACTS
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

	EXEC cq_HVAPOAM_MS
	@PK_Component=N'109'
	,@PK_Bureau=N'-2'
	,@AssmtSource=N'RVA'
	,@MSSTAT=''

*/

CREATE PROCEDURE [cq_HVAPOAM_ACTS]
	@UserID smallint = 0,  
	@PK_Component INT = 0,  
	@PK_Bureau INT = 0,  
	@PK_HVA INT = 0, 
	@TypePK INT = 0, 
	@FindingPK INT = 0,
	@PK_Milestone INT = 0, 
	@cfoagency INT = 0, 
	--@POAMSTAT NVARCHAR(55) = '',
	--@MSSTAT NVARCHAR(55) = '',
	@ACTSTAT NVARCHAR(55) = ''
	-- , @POAMSubmissionDate DATE = NULL
AS
SET NOCOUNT ON
	
	DECLARE @GETDATE As DATE = CONVERT(NVARCHAR(10), GETDATE() , 121)
 	DECLARE @SubmissionDate AS DATE = NULL

	IF @SubmissionDate IS NULL OR @SubmissionDate='' 
	BEGIN
		SET @SubmissionDate=@GETDATE
	END

	 DECLARE @PK_POAM INT = (SELECT FK_PK_POAM FROM fsma_Milestones WHERE PK_Milestone = @PK_Milestone)


	IF OBJECT_ID('tempdb..#RESULTS_VIEW') IS NOT NULL 
	DROP TABLE #RESULTS_VIEW  
	
	SELECT * INTO #RESULTS_VIEW FROM  
	(	  
		SELECT DISTINCT
	      vhva.Component AGENCY
		, BUREAU.Component AS BUREAU   
		, BUREAU.PK_BUREAU   
		, SystemName  
		, ASSMTType  
		, PK_POAM 
		, POAMStatus
		, TasksDesc
		, ACT_Comments 
		, MS_Status 
		, ACT_Description
		, ACT_Status
		, Title
		, Finding 
		FROM  [vwHVAAssessments] vhva
		LEFT JOIN fsma_OrgSubmissions o
			ON o.PK_OrgSubmission = vhva.PK_OrgSubmission
		LEFT JOIN fsma_ReportingCycle_Components rc
			ON rc.PK_ReportingCycle_Component = o.FK_ReportingCycle_Component
		LEFT JOIN [Component List] c
			ON c.PK_Component = rc.FK_Component
		LEFT JOIN (
			SELECT HVA.PK_HVA  
			, CASE WHEN  B.PK_Component IS NULL THEN -1 ELSE  B.PK_Component END PK_BUREAU
			, CASE WHEN B.Component IS NULL THEN 'UNKNOWN' ELSE B.Component END Component
			FROM fsma_HVAs HVA 
			LEFT JOIN [Component List] B ON  B.PK_Component=HVA.PK_Component AND B.FK_PK_Component IS NOT NULL
		) BUREAU 
			ON BUREAU.PK_HVA = vhva.PK_HVA    
		WHERE [POAM.IsActive] = 1 
		AND (rc.FK_Component =  @PK_Component OR @PK_Component = 0)
		AND (vhva.PK_HVA = @PK_HVA OR @PK_HVA = 0)
		AND (vhva.AssmtSource = @TypePK OR @TypePK = 0)
		AND (vhva.AssmtFinding = @FindingPK OR @FindingPK = 0)
		AND (@cfoagency = 0 OR c.isCFO = 1)

	) RESULTS_CURRENT
 
	IF @SubmissionDate <> @GETDATE 
	BEGIN  
		DELETE FROM #RESULTS_VIEW

		IF OBJECT_ID('tempdb..#AUDITVIEW') IS NOT NULL DROP TABLE #AUDITVIEW
		SELECT * INTO #AUDITVIEW FROM 
		(
			SELECT AuditLog.PK_AuditLog, AuditLog.TABLENAME, CONVERT(NVARCHAR(255), LEFT(AuditLog.FieldName,255)) FieldName, AuditLog.FieldValue, AuditLog.PK_PrimeKey, AuditLog.CHANGE_DATE 
			FROM AuditLog 
			WHERE TABLENAME IN('fsma_Assessments', 'fsma_POAMS', 'fsma_Milestones', 'fsma_Activities') AND EditType <> 'D' 
			AND CHANGE_DATE > DATEADD(MONTH, -12, @SubmissionDate) AND CHANGE_DATE < DATEADD(DAY, 1, @SubmissionDate)  
		)	AUDITVIEW  
			CREATE CLUSTERED INDEX IX_AUDITVIEW_CLUST ON #AUDITVIEW ( PK_AuditLog ) 
			CREATE NONCLUSTERED INDEX IX_AUDITVIEW_PK_PrimeKey ON #AUDITVIEW ( PK_PrimeKey ) 
			CREATE NONCLUSTERED INDEX IX_AUDITVIEW_FieldName ON #AUDITVIEW ( TABLENAME, FieldName )  
	 
		IF OBJECT_ID('tempdb..#AUDITFLAT') IS NOT NULL DROP TABLE #AUDITFLAT 
		SELECT * INTO #AUDITFLAT FROM  (  
			SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.CHANGE_DATE, FieldName 
			FROM ( SELECT CONVERT(NVARCHAR(10), CHANGE_DATE, 121)  CHANGE_DATE,  PK_AuditLog, FieldName, PK_PrimeKey FROM #AUDITVIEW ) 
				CONVERTDATE GROUP BY CHANGE_DATE, PK_PrimeKey, FieldName  
		)	AUDITFLAT 
			CREATE CLUSTERED INDEX IX_AUDITS_CLUST ON #AUDITFLAT ( PK_AuditLog )   
		   
		;WITH POAM_AUDITS AS (
			SELECT PK_PrimeKey As PK_POAM
			, #AUDITVIEW.PK_AuditLog
			, FieldValue
			, #AUDITVIEW.FieldName FieldName
			, #AUDITVIEW.FieldName FieldCaption
			, #AUDITFLAT.CHANGE_DATE
			, #AUDITVIEW.PK_PrimeKey  
			FROM #AUDITVIEW 
			INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog  
			WHERE #AUDITVIEW.TableName='fsma_POAMS'  
		),POAM_SUBMISSIONLOG AS (
			SELECT POAM_AUDITS.PK_POAM
			, POAM_AUDITS.CHANGE_DATE [SUBMISSION_DATE]
			, POAM_AUDITS.FieldValue
			, POAM_AUDITS.FieldName
			, POAM_AUDITS.FieldCaption
			, POAM.FK_PK_HVA PK_HVA
			FROM POAM_AUDITS  
			INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_POAM, FieldName FROM POAM_AUDITS 
				GROUP BY PK_POAM, FieldName  
				) MAXDATE ON MAXDATE.FieldName=POAM_AUDITS.FieldName
					AND MAXDATE.CHANGE_DATE=POAM_AUDITS.CHANGE_DATE
					AND MAXDATE.PK_POAM=POAM_AUDITS.PK_POAM  
		LEFT JOIN fsma_POAMS POAM ON POAM_AUDITS.PK_POAM = POAM.PK_POAM  

		),ASSM_AUDITS AS ( /* fsma_Assessments AUDITS  */
			SELECT #AUDITVIEW.PK_PrimeKey, #AUDITVIEW.PK_AuditLog, FieldValue, #AUDITVIEW.FieldName FieldName, #AUDITFLAT.CHANGE_DATE 
			FROM #AUDITVIEW INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog  
			WHERE #AUDITVIEW.TableName='fsma_Assessments'  
		),ASSM_SUBMISSIONLOG AS (
			SELECT ASSM_AUDITS.PK_PrimeKey, ASSM_AUDITS.CHANGE_DATE [SUBMISSION_DATE], ASSM_AUDITS.FieldValue, ASSM_AUDITS.FieldName 
			FROM ASSM_AUDITS  
			INNER JOIN (
				SELECT MAX(CHANGE_DATE) CHANGE_DATE, PK_PrimeKey, FieldName 
				FROM ASSM_AUDITS GROUP BY PK_PrimeKey, FieldName  
			) MAXDATE ON MAXDATE.FieldName=ASSM_AUDITS.FieldName
				AND MAXDATE.CHANGE_DATE=ASSM_AUDITS.CHANGE_DATE
				AND MAXDATE.PK_PrimeKey=ASSM_AUDITS.PK_PrimeKey    
		),MS_AUDITS AS ( /* fsma_Milestones AUDITS  */
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
		),ACT_AUDITS AS (  /* fsma_Activities AUDITS  */
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

		),RESULTS_PIVOT AS (  
			  SELECT  
			  HVA.PK_HVA
			, HVA.PK_Component
			, HVA.PK_Component PK_BUREAU
			, HVA.PK_Component_Agency
			, POAM_PIVOT.PK_POAM
			, POAM_PIVOT.[Status] AS POAMStatus 
			, CASE WHEN ASSM_PIVOT.[AssmtSource] IS NULL THEN ASSMT.AssmtSource ELSE ASSM_PIVOT.[AssmtSource] END [AssmtSource]
			, POAM_PIVOT.[AssmtFinding]  
			, MS.PK_Milestone
			, MS_PIVOT.[Status] [MS_Status]
			, MS_PIVOT.[Title]
			, MS_PIVOT.[TasksDesc]
			, ACT_PIVOT.[Status] [ACT_Status]
			, ACT_PIVOT.[Description] [ACT_Description]
			, ACT_PIVOT.[Comments] [ACT_Comments]
			FROM (
 				SELECT * FROM (
					SELECT PK_HVA, PK_POAM, FieldValue, FieldName FROM POAM_SUBMISSIONLOG
				) P PIVOT  (
					MAX(FieldValue) 
					FOR FieldName IN ([Status],[RiskCat],[RiskFactor],[AssmtFinding],[EscalationLevel],[Designation],[RemSchedule],[OffScheduleReason])
				) POAMRESULTS
			) POAM_PIVOT
			INNER JOIN fsma_POAMs POAM ON POAM_PIVOT.PK_POAM = POAM.PK_POAM AND isActive = 1 
			INNER JOIN fsma_Assessments ASSMT ON ASSMT.PK_Assessment = POAM.FK_PK_Assessment AND ASSMT.isActive = 1 
			INNER JOIN fsma_HVAs HVA ON HVA.PK_HVA = ASSMT.FK_PK_HVA  AND HVA.IsActive = 1 
			LEFT JOIN fsma_Milestones MS ON POAM.PK_POAM = MS.FK_PK_POAM 
			LEFT JOIN fsma_Activities ACT ON ACT.FK_PK_Milestone = MS.PK_Milestone 

			LEFT JOIN (
				SELECT * FROM (
					SELECT PK_PrimeKey, FieldValue, FieldName FROM ASSM_SUBMISSIONLOG 
				) P PIVOT (
				MAX(FieldValue) 
				FOR FieldName IN ([AssmtSource],[AgRecievedDate],[CloseOutSignature],[RemPlanSignature])
				) ASSMRESULTS 
			) ASSM_PIVOT ON ASSM_PIVOT.PK_PrimeKey = POAM.FK_PK_Assessment 
 
		
			LEFT JOIN(
				SELECT * FROM (
					SELECT PK_PrimeKey, FieldValue, FieldName FROM MS_SUBMISSIONLOG 
				) P PIVOT ( MAX(FieldValue) FOR FieldName IN ([Status],[Title],[TasksDesc])
				) MS_PIVOT  
			) MS_PIVOT ON MS_PIVOT.PK_PrimeKey=MS.PK_Milestone
		
			LEFT JOIN(
				SELECT * FROM (
					SELECT PK_PrimeKey, FieldValue, FieldName FROM ACT_SUBMISSIONLOG 
				) P PIVOT ( MAX(FieldValue) FOR FieldName IN ([Status],[Description],[Comments])
				) ACT_PIVOT  
			) ACT_PIVOT ON ACT_PIVOT.PK_PrimeKey=ACT.PK_Activity 
		)     
 
		INSERT INTO #RESULTS_VIEW 
		SELECT 
		  (Select TOP 1 Component From [Component List] WHERE PK_Component = PK_Component_Agency) AGENCY 
		, (Select TOP 1 CASE WHEN Component IS NULL THEN 'UNKNOWN' ELSE Component END FROM [Component List] WHERE PK_Component = RESULTS_PIVOT.PK_Component) BUREAU     
		, PK_BUREAU     
		, (Select TOP 1 SystemName From fsma_HVAs WHERE PK_HVA = RESULTS_PIVOT.PK_HVA) SystemName   
		, (SELECT TOP 1 DisplayValue FROM PickLists WHERE PK_PickList=AssmtSource) ASSMTType  
		, PK_POAM 
		, (SELECT TOP 1 DisplayValue FROM PickLists WHERE PK_PickList=POAMStatus) POAMStatus
		, TasksDesc
		, ACT_Comments 
		, (SELECT TOP 1 DisplayValue FROM PickLists WHERE PK_PickList=MS_Status) MS_Status 
		, ACT_Description
		, (SELECT TOP 1 DisplayValue FROM PickLists WHERE PK_PickList=ACT_Status) ACT_Status 
		, Title
		, (SELECT TOP 1 DisplayValue FROM PickLists WHERE PK_PickList=AssmtFinding) Finding
		--, c.PK_Component , PK_HVA, PK_POAM, PK_Milestone--key debugger
		FROM RESULTS_PIVOT
		LEFT JOIN [Component List] c ON c.PK_Component=PK_Component_Agency
		WHERE 1=1
		AND (c.PK_Component =  @PK_Component OR @PK_Component = 0)
		AND (PK_HVA = @PK_HVA OR @PK_HVA = 0)
		AND (AssmtSource = @TypePK OR @TypePK = 0)
		AND (AssmtFinding = @FindingPK OR @FindingPK = 0)
		AND (@cfoagency = 0 OR c.isCFO = 1)
 		
		--SELECT * FROM RESULTS_PIVOT 
	END  

	ELSE
	BEGIN
		IF @ACTSTAT <> ''
		BEGIN
			DELETE FROM #RESULTS_VIEW 
			WHERE [Act_Status] <> 
			(
				SELECT DisplayValue 
				FROM PickLists PL 
				INNER JOIN PickListTypes PLT 
					ON PL.PK_PickListType = PLT.PK_PickListType 
				WHERE UsageField = 'ACTSTAT' 
				AND CodeValue=@ACTSTAT
			)
			OR ACT_Status IS NULL
		END 

		IF @PK_Bureau = -1
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE BUREAU <> 'UNKNOWN'
		END

		IF @PK_Bureau = - 10 
		BEGIN
			DELETE FROM #RESULTS_VIEW WHERE BUREAU = 'UNKNOWN'
		END	  
	END 



	SELECT AGENCY, 
	BUREAU, 
	SystemName, 
	ASSMTType AS 'Type',
	Finding AS 'Finding Title',
	Title AS 'Milestone Title',
	TasksDesc AS 'Milestone Description',
	ACT_Description AS 'Activity Description',
	[ACT_Status] 'Activity Status',

	--, MS_SchCompDate 'Scheduled Completion Date'
	--, MS_ActCompDate AS 'Actual Completion Date'
	 ACT_Comments AS 'Comments'
	FROM #RESULTS_VIEW  
	 

GO
  
EXEC cq_DeleteQueryAndClearRefs 'cq_HVAPOAM_ACTS' 
--Create cq_Query table record
EXEC cq_CreateOrReplaceQueryAndClearRefs 'cq_HVAPOAM_ACTS', 'BOD 18-02 Remediation Plans - Agency HVA Remediation Plan Activities', 14, 0
  
IF NOT EXISTS (SELECT * FROM cq_ParmsMaster WHERE ParmName = 'ffmHVAPOAMForm')
	INSERT INTO cq_ParmsMaster (ParmName, ParmDescription, ParmType, SortOrder, Multiple) VALUES ('ffmHVAPOAMForm', 'HVA Remediation Plan List', 80, 7, 1);
GO
IF NOT EXISTS (SELECT * FROM cq_ParmsMaster WHERE ParmName = 'POAMSubmissionDate')
	INSERT INTO cq_ParmsMaster (ParmName, ParmDescription, ParmType, SortOrder, Multiple) VALUES ('POAMSubmissionDate', 'Rem. Submission Date:', 1, 1, 1);
GO   
--BEGIN PARAMS 
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAPOAM_ACTS','ffmHVAPOAMForm',NULL,NULL,1,1,0,0,0,NULL,NULL,'HVAPOAM_ACTS'-- _MS _ACTS

EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAPOAM_ACTS', 'cfoagency', NULL, 'CFO Agencies Only', 2

DECLARE @PickListTypeACTSTAT INT = (SELECT TOP 1  PK_PickListType FROM PickListTypes WHERE UsageField = 'ACTSTAT') 
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAPOAM_ACTS','PickList','ACTSTAT','Activity Status', 3,1,0,  @PickListTypeACTSTAT
  
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAPOAM_ACTS','UserID',NULL,NULL,2 
--  EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAPOAM_ACTS','POAMSubmissionDate',NULL,'Rem. Submission Date:', 4
--Create Permission mapping records
EXEC cq_CreateOrUpdateSPtoPermissions 'cq_HVAPOAM_ACTS', 'OMBBOD1802POAMDC'

EXEC cq_MasterSort
--
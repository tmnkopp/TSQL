/*
	Author: T.KOPP											
	Date: 7-20-20												
	Description: Gets audit records related to HVA metric submissions (question, answer tables) by submission date 
	EXEC cq_HVAOutSubmissionHistory @PK_ReportingCycle='88', @PK_Component='170', @HVASubmissionDate ='2020-07-19'
*/ 
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'cq_HVAOutSubmissionHistory' AND type = 'P')
    DROP PROCEDURE cq_HVAOutSubmissionHistory
GO 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
CREATE PROCEDURE [cq_HVAOutSubmissionHistory]
    @UserID smallint = 0,
	@PK_ReportingCycle INT = -2,
	@ComponentGroup NVARCHAR(20) = '0',
	@PK_Component  INT = 0, 
	@PK_Bureau INT = 0,  
	@HVASubmissionDate DATE = NULL
AS

IF @PK_ReportingCycle IN ((SELECT PK_ReportingCycle FROM fsma_ReportingCycles RC WHERE RC.PK_DataCall=12))
BEGIN

--CQ FORM DEFAULTS 
	DECLARE @SubmissionDate As DATE = @HVASubmissionDate  
	IF @HVASubmissionDate IS NULL OR @HVASubmissionDate='' SET @SubmissionDate=GETDATE()  
	DECLARE @PK_FORM As NVARCHAR(15) = (
		SELECT TOP 1 PK_FORM FROM fsma_OrgSubmissions ORG
		INNER JOIN fsma_ReportingCycle_Components RCC ON RCC.PK_ReportingCycle_Component = ORG.FK_ReportingCycle_Component
		INNER JOIN fsma_ReportingCycles RC ON RC.PK_ReportingCycle = RCC.FK_ReportingCycle 
		WHERE (RC.PK_ReportingCycle=@PK_ReportingCycle )
	)   
--BEGIN QUERY
	--FIELD META INFO FOR DYNAMIC Qs AND JOINS
	IF OBJECT_ID('tempdb..#FIELD_META') IS NOT NULL DROP TABLE #FIELD_META 
	SELECT * INTO #FIELD_META FROM (   
		SELECT  COLUMN_NAME FieldName, DATA_TYPE FieldType, NULL FK_PickList, COLUMN_NAME FieldCaption, ORDINAL_POSITION SortOrder
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME IN ('HVAOut')  
		AND COLUMN_NAME NOT IN('IsActive')
	)	FIELD_META 
		CREATE CLUSTERED INDEX IX_FIELD_META_CLUST ON #FIELD_META ( FieldName ) 
		--SELECT * FROM #FIELD_META ORDER BY SortOrder RETURN; --< DEBUG BREAKPOINT
	
	--AUDITVIEW
    IF OBJECT_ID('tempdb..#AUDITVIEW') IS NOT NULL DROP TABLE #AUDITVIEW
	SELECT * INTO #AUDITVIEW FROM(
		SELECT AuditLog.PK_AuditLog, AuditLog.TABLENAME, CONVERT(NVARCHAR(255), LEFT(AuditLog.FieldName,255)) FieldName, AuditLog.FieldValue, AuditLog.PK_PrimeKey, AuditLog.CHANGE_DATE, PK_Agency
		FROM AuditLog 
		WHERE EditType <> 'D' 
		AND CHANGE_DATE > DATEADD(MONTH, -12, GETDATE()) AND CHANGE_DATE < DATEADD(DAY, 1, @SubmissionDate)
		AND TABLENAME IN( 'HVAOut')   
		AND FieldName IN (SELECT CONVERT(NVARCHAR(55), FieldName) FROM #FIELD_META)
		AND FieldValue IS NOT NULL
	)	AUDITVIEW 
		CREATE CLUSTERED INDEX IX_AUDITVIEW_CLUST ON #AUDITVIEW ( PK_AuditLog ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_PK_PrimeKey ON #AUDITVIEW ( PK_PrimeKey ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_FieldName ON #AUDITVIEW ( TABLENAME, FieldName )  
		--SELECT * FROM #AUDITVIEW RETURN; --< DEBUG BREAKPOINT
	IF @PK_Component > 0 
	BEGIN 
		DELETE FROM #AUDITVIEW WHERE #AUDITVIEW.PK_Agency <> @PK_Component
	END	  
	--AUDITS BY DAY
	IF OBJECT_ID('tempdb..#AUDITFLAT') IS NOT NULL DROP TABLE #AUDITFLAT 
	SELECT * INTO #AUDITFLAT FROM  (  
		SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.CHANGE_DATE, PK_PrimeKey, FieldName 
		FROM ( 
			SELECT CONVERT(NVARCHAR(10), CHANGE_DATE, 121)  CHANGE_DATE,  PK_AuditLog, FieldName, PK_PrimeKey FROM #AUDITVIEW 
		) CONVERTDATE GROUP BY CHANGE_DATE, PK_PrimeKey, FieldName  
	)	AUDITFLAT 
		CREATE CLUSTERED INDEX IX_AUDITS_CLUST ON #AUDITFLAT ( PK_AuditLog )      
		--SELECT * FROM #AUDITFLAT WHERE PK_AuditLog BETWEEN 747137 AND 747153 RETURN; --< DEBUG BREAKPOINT
	
	--METRICS BY DAY  
	IF OBJECT_ID('tempdb..#AUDITS_MASTER') IS NOT NULL DROP TABLE #AUDITS_MASTER
	SELECT * INTO #AUDITS_MASTER FROM (
		SELECT  
		(	SELECT TOP 1 CONVERT(NVARCHAR(7),ORG.FieldValue) PK_OrgSubmission 
			FROM #AUDITVIEW ORG WHERE FieldName='PK_OrgSubmission' 
			AND ORG.PK_PrimeKey=#AUDITVIEW.PK_PrimeKey ) PK_OrgSubmission 
		,	#AUDITVIEW.PK_AuditLog, FieldValue, #FIELD_META.FieldName FieldName, #FIELD_META.FieldCaption, #AUDITFLAT.CHANGE_DATE, #AUDITVIEW.PK_PrimeKey  
		FROM #AUDITVIEW 
		INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#AUDITVIEW.FieldName  
		WHERE #AUDITVIEW.TableName='HVAOut' 
	)	HVAOut_Audits 
		CREATE CLUSTERED INDEX IX_METRIC_AUDITS_CLUST ON #AUDITS_MASTER ( PK_PrimeKey )   
		CREATE NONCLUSTERED INDEX IX_METRIC_AUDITS_PK_OrgSubmission ON #AUDITS_MASTER ( PK_OrgSubmission )  
		CREATE NONCLUSTERED INDEX IX_METRIC_AUDITS_FieldName ON #AUDITS_MASTER ( FieldName )  
		--SELECT * FROM #AUDITS_MASTER WHERE #AUDITS_MASTER.PK_OrgSubmission='23309' RETURN; --< DEBUG BREAKPOINT
 
	--METRIC SUBMISSIONS FLATTEN
	IF OBJECT_ID('tempdb..#ORG_SUBMISSIONLOG') IS NOT NULL DROP TABLE #ORG_SUBMISSIONLOG  
	SELECT * INTO #ORG_SUBMISSIONLOG FROM (
		SELECT #AUDITS_MASTER.PK_OrgSubmission, #AUDITS_MASTER.PK_PrimeKey, #AUDITS_MASTER.CHANGE_DATE [SUBMISSION_DATE], #AUDITS_MASTER.FieldValue, #AUDITS_MASTER.FieldName, #AUDITS_MASTER.FieldCaption
		FROM #AUDITS_MASTER 
		LEFT JOIN (
				SELECT  MAX(CHANGE_DATE) CHANGE_DATE, PK_OrgSubmission, FieldName FROM #AUDITS_MASTER
				GROUP BY PK_OrgSubmission, FieldName  
		) MAXDATE ON MAXDATE.FieldName=#AUDITS_MASTER.FieldName
			AND MAXDATE.CHANGE_DATE=#AUDITS_MASTER.CHANGE_DATE
			AND MAXDATE.PK_OrgSubmission=#AUDITS_MASTER.PK_OrgSubmission 
	) ORG_SUBMISSIONLOG 
		CREATE NONCLUSTERED INDEX IX_ORG_SUBMISSION_OrgSub_FieldName ON #ORG_SUBMISSIONLOG ( PK_OrgSubmission, FieldName )   
		--SELECT * FROM #ORG_SUBMISSIONLOG WHERE PK_OrgSubmission=23309 RETURN; --< DEBUG BREAKPOINT 
	  
	--VIEWABLE FIELDS
	IF OBJECT_ID('tempdb..#SUBMISSION_VIEW') IS NOT NULL DROP TABLE #SUBMISSION_VIEW 
	SELECT * INTO #SUBMISSION_VIEW FROM (
		SELECT HVA.SystemName HVA, #ORG_SUBMISSIONLOG.PK_OrgSubmission, #ORG_SUBMISSIONLOG.PK_PrimeKey, #ORG_SUBMISSIONLOG.SUBMISSION_DATE, #ORG_SUBMISSIONLOG.FieldName, #ORG_SUBMISSIONLOG.FieldCaption
		, CASE 
			WHEN #FIELD_META.FieldName='PK_Component' THEN
				 (Select Component From [Component List] WHERE CONVERT(NVARCHAR(5), PK_Component) = #ORG_SUBMISSIONLOG.FieldValue) 
			WHEN #FIELD_META.FieldName  IN ('IsInternal','IsHVA','IsEssential','IsPriority' ) THEN 
				CASE 
					WHEN COALESCE(#ORG_SUBMISSIONLOG.FieldValue,'') = 'Y' THEN 'Yes' 
					ELSE 'No' 
				END
			ELSE #ORG_SUBMISSIONLOG.FieldValue
		END FieldValue 		 
		FROM #ORG_SUBMISSIONLOG 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#ORG_SUBMISSIONLOG.FieldName  
		INNER JOIN fsma_OrgSubHVAMap MAP ON MAP.PK_OrgSubmission=#ORG_SUBMISSIONLOG.PK_OrgSubmission
		INNER JOIN fsma_HVAs HVA ON HVA.PK_HVA=MAP.PK_HVA
	) SUBMISSION_VIEW 
		CREATE NONCLUSTERED INDEX IX_SUBMISSION_VIEW_PK_OrgSubmission ON #SUBMISSION_VIEW ( PK_OrgSubmission )   
		--SELECT * FROM #SUBMISSION_VIEW WHERE PK_OrgSubmission=23309 RETURN; --< DEBUG BREAKPOINT

	--PIVOT  
	DECLARE @COLS AS NVARCHAR(MAX)=''; 
	DECLARE @exe NVARCHAR(MAX) = ''; 
	SET @COLS=''
	SET @exe='' 
	SELECT @COLS = @COLS + QUOTENAME(FieldCaption) + ',' FROM #FIELD_META ORDER BY SortOrder
	SELECT @COLS = SUBSTRING(@COLS, 0, LEN(@COLS))   
	SET @exe=@exe+'  SELECT HVA, SystemName, IsEssential, IsPriority FROM ('
	SET @exe=@exe+'	 SELECT HVA, PK_PrimeKey, FieldValue, FieldCaption'
	SET @exe=@exe+'	 FROM #SUBMISSION_VIEW '  
	SET @exe=@exe+') PV PIVOT  ('
	SET @exe=@exe+'	 MAX(FieldValue)  '
	SET @exe=@exe+'	 FOR FieldCaption IN ( '+ @COLS +' )'
	SET @exe=@exe+') P ORDER BY HVA DESC, SystemName DESC ' 
	EXECUTE sp_executesql @exe 
END
	  
GO  
 
IF NOT EXISTS (SELECT * FROM cq_ParmsMaster WHERE ParmName = 'HVASubmissionDate')
	INSERT INTO cq_ParmsMaster (ParmName, ParmDescription, ParmType, SortOrder, Multiple) VALUES ('HVASubmissionDate', 'Submission Date:', 1, 1, 1);
GO 
EXEC cq_DeleteQueryAndClearRefs 'cq_HVAOutSubmissionHistory'  
EXEC cq_CreateOrReplaceQueryAndClearRefs 'cq_HVAOutSubmissionHistory', 'BOD 18-02 Data - Agency HVA External Interconnection Submissions', 12, 0 
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAOutSubmissionHistory','orgsubmission',NULL,NULL,1,1,0,0,0,NULL,NULL,'bod1802' 
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAOutSubmissionHistory','UserID',NULL,NULL,2  
EXEC cq_CreateOrUpdateSPtoParms 'cq_HVAOutSubmissionHistory','HVASubmissionDate',NULL,'Submission Date',3
EXEC cq_CreateOrUpdateSPtoPermissions 'cq_HVAOutSubmissionHistory', 'OMBHVAPOAMDC' 
EXEC cq_MasterSort 
GO 
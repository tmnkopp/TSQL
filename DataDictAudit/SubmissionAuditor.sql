--TESTING DEFAULTS
	DECLARE @PK_ReportingCycle INT = 88--< SET THIS TO REPORTING CYCLE (74 = 2019, 88 = 2020)
	DECLARE @HVASubmissionDate DATE = '2020-07-19'--GETDATE()--< SET THIS TO DATE WHEN HVA SUBMITTED, USE CURRENT DATE FOR PERFORMANCE TESTING

IF @PK_ReportingCycle IN (74,88)
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
		SELECT DISTINCT  CONVERT(NVARCHAR(15), Q.PK_Question) FieldName, FK_QuestionType, FK_PickList, identifier_text FieldCaption, (ROW_NUMBER() OVER (ORDER BY QG.sortpos, Q.sortpos)+100) SortOrder
		FROM  fsma_QuestionGroups QG
		INNER JOIN fsma_Questions Q ON QG.PK_QuestionGroup=Q.FK_QuestionGroup
		WHERE QG.PK_FORM = @PK_FORM AND identifier_text <> ''
		UNION ALL
		SELECT COLUMN_NAME FieldName, NULL, NULL, COLUMN_NAME, ORDINAL_POSITION 
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME='fsma_HVAs' AND COLUMN_NAME IN('SystemName', 'AgencyRank', 'PK_Component', 'Tier', 'LastAssessedRVA', 'LastAssessedSAR')
	)	FIELD_META 
		CREATE CLUSTERED INDEX IX_FIELD_META_CLUST ON #FIELD_META ( FieldName ) 
		--SELECT * FROM #FIELD_META ORDER BY SortOrder RETURN; --< DEBUG BREAKPOINT
	
	--AUDITVIEW
    IF OBJECT_ID('tempdb..#AUDITVIEW') IS NOT NULL DROP TABLE #AUDITVIEW
	SELECT * INTO #AUDITVIEW FROM(
		SELECT AuditLog.PK_AuditLog, AuditLog.TABLENAME, CONVERT(NVARCHAR(255), LEFT(AuditLog.FieldName,255)) FieldName, AuditLog.FieldValue, AuditLog.PK_PrimeKey, AuditLog.CHANGE_DATE FROM AuditLog 
		WHERE TABLENAME IN( 'fsma_Answers', 'fsma_HVAs') AND EditType <> 'D' 
		AND CHANGE_DATE > DATEADD(MONTH, -12, GETDATE()) AND CHANGE_DATE < DATEADD(DAY, 1, @SubmissionDate)
		AND FieldName IN (SELECT CONVERT(NVARCHAR(55), FieldName) FROM #FIELD_META)
		AND FieldValue IS NOT NULL
	)	AUDITVIEW 
		CREATE CLUSTERED INDEX IX_AUDITVIEW_CLUST ON #AUDITVIEW ( PK_AuditLog ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_PK_PrimeKey ON #AUDITVIEW ( PK_PrimeKey ) 
		CREATE NONCLUSTERED INDEX IX_AUDITVIEW_FieldName ON #AUDITVIEW ( TABLENAME, FieldName )  
		--SELECT * FROM #AUDITVIEW RETURN; --< DEBUG BREAKPOINT
		 
	--AUDITS BY DAY
	IF OBJECT_ID('tempdb..#AUDITFLAT') IS NOT NULL DROP TABLE #AUDITFLAT 
	SELECT * INTO #AUDITFLAT FROM  (  
		SELECT MAX(PK_AuditLog) PK_AuditLog, CONVERTDATE.CHANGE_DATE, PK_OrgSubmission, FieldName 
		FROM ( 
			SELECT CONVERT(NVARCHAR(10), CHANGE_DATE, 121)  CHANGE_DATE,  PK_AuditLog, FieldName, PK_PrimeKey As [PK_OrgSubmission] FROM #AUDITVIEW 
		) CONVERTDATE GROUP BY CHANGE_DATE, PK_OrgSubmission, FieldName  
	)	AUDITFLAT 
		CREATE CLUSTERED INDEX IX_AUDITS_CLUST ON #AUDITFLAT ( PK_AuditLog )      
		--SELECT * FROM #AUDITFLAT RETURN; --< DEBUG BREAKPOINT
	
	--METRICS BY DAY  
	IF OBJECT_ID('tempdb..#METRIC_AUDITS') IS NOT NULL DROP TABLE #METRIC_AUDITS
	SELECT * INTO #METRIC_AUDITS FROM (
		SELECT ORG.PK_OrgSubmission, #AUDITVIEW.PK_AuditLog, FieldValue, #FIELD_META.FieldName FieldName, #FIELD_META.FieldCaption, #AUDITFLAT.CHANGE_DATE, #AUDITVIEW.PK_PrimeKey  
		FROM #AUDITVIEW
		INNER JOIN fsma_OrgSubmissions ORG ON ORG.PK_OrgSubmission=#AUDITVIEW.PK_PrimeKey 
		INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#AUDITVIEW.FieldName  
		WHERE ORG.PK_FORM = @PK_FORM AND #AUDITVIEW.TableName='fsma_Answers' 
	)	METRIC_AUDITS  
		CREATE CLUSTERED INDEX IX_METRIC_AUDITS_CLUST ON #METRIC_AUDITS ( PK_PrimeKey )   
		CREATE NONCLUSTERED INDEX IX_METRIC_AUDITS_PK_OrgSubmission ON #METRIC_AUDITS ( PK_OrgSubmission )  
		CREATE NONCLUSTERED INDEX IX_METRIC_AUDITS_FieldName ON #METRIC_AUDITS ( FieldName )  
		--SELECT * FROM #METRIC_AUDITS RETURN; --< DEBUG BREAKPOINT

	--HVA BY DAY  
	IF OBJECT_ID('tempdb..#HVA_AUDITS') IS NOT NULL DROP TABLE #HVA_AUDITS
	SELECT * INTO #HVA_AUDITS FROM (
		SELECT 0 As PK_OrgSubmission, #AUDITVIEW.PK_AuditLog, FieldValue, #FIELD_META.FieldName FieldName, #FIELD_META.FieldCaption, #AUDITFLAT.CHANGE_DATE, #AUDITVIEW.PK_PrimeKey  
		FROM #AUDITVIEW 
		INNER JOIN #AUDITFLAT ON #AUDITFLAT.PK_AuditLog=#AUDITVIEW.PK_AuditLog 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#AUDITVIEW.FieldName 
		WHERE #AUDITVIEW.TableName='fsma_HVAs'  
	)	HVA_AUDITS 
		CREATE CLUSTERED INDEX IX_HVA_AUDITS_CLUST ON #HVA_AUDITS ( PK_PrimeKey ) 
		CREATE NONCLUSTERED INDEX IX_HVA_AUDITS_PK_OrgSubmission ON #HVA_AUDITS ( PK_OrgSubmission )   
         
		UPDATE #HVA_AUDITS SET PK_OrgSubmission = MAP.PK_OrgSubmission
		FROM #HVA_AUDITS
		INNER JOIN fsma_OrgSubHVAMap MAP ON MAP.PK_HVA=#HVA_AUDITS.PK_PrimeKey
		INNER JOIN fsma_OrgSubmissions ORG ON ORG.PK_OrgSubmission=MAP.PK_OrgSubmission AND PK_FORM=@PK_FORM
		
		INSERT INTO #METRIC_AUDITS
		SELECT * FROM #HVA_AUDITS 
		--SELECT * FROM #METRIC_AUDITS WHERE Pk_OrgSubmission = 22617  RETURN; --< DEBUG BREAKPOINT

	--METRIC SUBMISSIONS FLATTEN
	IF OBJECT_ID('tempdb..#ORG_SUBMISSIONLOG') IS NOT NULL DROP TABLE #ORG_SUBMISSIONLOG  
	SELECT * INTO #ORG_SUBMISSIONLOG FROM (
		SELECT #METRIC_AUDITS.PK_OrgSubmission, #METRIC_AUDITS.CHANGE_DATE [SUBMISSION_DATE], #METRIC_AUDITS.FieldValue, #METRIC_AUDITS.FieldName, #METRIC_AUDITS.FieldCaption
		FROM #METRIC_AUDITS  
		LEFT JOIN (
				SELECT  MAX(CHANGE_DATE) CHANGE_DATE, PK_OrgSubmission, FieldName FROM #METRIC_AUDITS 
				GROUP BY PK_OrgSubmission, FieldName  
		) MAXDATE ON MAXDATE.FieldName=#METRIC_AUDITS.FieldName
			AND MAXDATE.CHANGE_DATE=#METRIC_AUDITS.CHANGE_DATE
			AND MAXDATE.PK_OrgSubmission=#METRIC_AUDITS.PK_OrgSubmission 
	) ORG_SUBMISSIONLOG 
		CREATE NONCLUSTERED INDEX IX_ORG_SUBMISSION_OrgSub_FieldName ON #ORG_SUBMISSIONLOG ( PK_OrgSubmission, FieldName )   
		--SELECT * FROM #ORG_SUBMISSIONLOG WHERE PK_OrgSubmission=22617 RETURN; --< DEBUG BREAKPOINT 
	  
	--VIEWABLE FIELDS
	IF OBJECT_ID('tempdb..#SUBMISSION_VIEW') IS NOT NULL DROP TABLE #SUBMISSION_VIEW 
	SELECT * INTO #SUBMISSION_VIEW FROM (
		SELECT HVA.SystemName HVA, #ORG_SUBMISSIONLOG.PK_OrgSubmission, #ORG_SUBMISSIONLOG.SUBMISSION_DATE, #ORG_SUBMISSIONLOG.FieldName, #ORG_SUBMISSIONLOG.FieldCaption
		, CASE 
			WHEN #FIELD_META.FieldName='PK_Component' THEN
				 (Select Component From [Component List] WHERE CONVERT(NVARCHAR(5), PK_Component) = #ORG_SUBMISSIONLOG.FieldValue)
			WHEN #FIELD_META.FieldName='LastAssessedRVA' OR #FIELD_META.FieldName='LastAssessedSAR' THEN
				 CONVERT(NVARCHAR(11),  #ORG_SUBMISSIONLOG.FieldValue)
			WHEN #FIELD_META.FK_QuestionType IN (17,30) OR #FIELD_META.FieldName='Tier' THEN
				 (SELECT TOP 1 DisplayValue FROM PickLists WHERE CAST(PK_PickList AS NVARCHAR) = #ORG_SUBMISSIONLOG.FieldValue) 
			WHEN #FIELD_META.FK_QuestionType IN (18) AND FK_PickList IS NOT NULL THEN 
				 (SELECT TOP 1 DisplayValue FROM PickLists WHERE CAST(PK_PickList AS NVARCHAR) = #ORG_SUBMISSIONLOG.FieldValue) 
			WHEN #FIELD_META.FK_QuestionType IN (43)  THEN   
				(SELECT STUFF((SELECT '|'+ DisplayValue
				FROM PickLists where PK_PickList in (SELECT string FROM dbo.iter_stringlist_to_tbl(#ORG_SUBMISSIONLOG.FieldValue ,',') WHERE ISNUMERIC(string)=1)
				FOR XML PATH('')),1,1,'') ) 
			WHEN #FIELD_META.FK_QuestionType  IN (1,2,31,50,9) THEN 
				CASE 
					WHEN COALESCE(#ORG_SUBMISSIONLOG.FieldValue,'') = 'X' THEN 'N/A' 
					WHEN COALESCE(#ORG_SUBMISSIONLOG.FieldValue,'') = 'DM' THEN 'Defer Metric' 
					ELSE RTRIM(LTRIM((COALESCE(#ORG_SUBMISSIONLOG.FieldValue,'')))) 
				END
			ELSE #ORG_SUBMISSIONLOG.FieldValue
		END FieldValue 		 
		FROM #ORG_SUBMISSIONLOG 
		INNER JOIN #FIELD_META ON #FIELD_META.FieldName=#ORG_SUBMISSIONLOG.FieldName  
		INNER JOIN fsma_OrgSubHVAMap MAP ON MAP.PK_OrgSubmission=#ORG_SUBMISSIONLOG.PK_OrgSubmission
		INNER JOIN fsma_HVAs HVA ON HVA.PK_HVA=MAP.PK_HVA
	) SUBMISSION_VIEW 
		CREATE NONCLUSTERED INDEX IX_SUBMISSION_VIEW_PK_OrgSubmission ON #SUBMISSION_VIEW ( PK_OrgSubmission )   
		--SELECT * FROM #SUBMISSION_VIEW  WHERE PK_OrgSubmission=22617 RETURN; --< DEBUG BREAKPOINT

	--PIVOT  
	DECLARE @COLS AS NVARCHAR(MAX)=''; 
	DECLARE @exe NVARCHAR(MAX) = ''; 
	SET @COLS=''
	SET @exe='' 
	SELECT @COLS = @COLS + QUOTENAME(FieldCaption) + ',' FROM #FIELD_META ORDER BY SortOrder
	SELECT @COLS = SUBSTRING(@COLS, 0, LEN(@COLS))   
	SET @exe=@exe+'  SELECT * FROM ('
	SET @exe=@exe+'	 SELECT HVA, PK_OrgSubmission, FieldValue, FieldCaption'
	SET @exe=@exe+'	 FROM #SUBMISSION_VIEW '  
	SET @exe=@exe+') PV PIVOT  ('
	SET @exe=@exe+'	 MAX(FieldValue)  '
	SET @exe=@exe+'	 FOR FieldCaption IN ( '+ @COLS +' )'
	SET @exe=@exe+') P ORDER BY PK_OrgSubmission DESC' 
	EXECUTE sp_executesql @exe 
END
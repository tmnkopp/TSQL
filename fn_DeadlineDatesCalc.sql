
/*  
AUTHOR: TKOPP 
DATE: 8-6-2020
DESC: calculates poam deadline dates
SELECT * FROM dbo.fn_PoamDeadlineDatesCalc( 26021 )  
*/ 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_PoamDeadlineDatesCalc]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')) 
	DROP FUNCTION [dbo].[fn_PoamDeadlineDatesCalc]
GO 
CREATE FUNCTION dbo.fn_PoamDeadlineDatesCalc(
  @PK_OrgSubmission INT = NULL 
) RETURNS @DeadlineDates TABLE (
		  PK_POAM INT
		, PK_OrgSubmission INT
		, SubmissionStatus NVARCHAR(55)
		, FinalizedDate DATETIME
		, LastSubmissionDate DATETIME 
		, SubmissionDateOffset INT 
		, CurrentDeadline DATETIME
		, NextDeadline DATETIME
		, FutureDeadline DATETIME
		, FinalOverdue DATETIME
    ) 
BEGIN  
	;WITH Audits AS (
		SELECT PK_OrgSubmission, MAX(ALOG.Change_Date) LastSubmissionDate, ORG.Status_code SubmissionStatus 
		FROM AuditLog ALOG
		INNER JOIN fsma_OrgSubmissions ORG ON ORG.PK_OrgSubmission=ALOG.PK_PrimeKey
		WHERE ORG.PK_Form='2020-A-HVAPOAM' AND ALOG.TableName='fsma_OrgSubmissions' AND ALOG.FieldName='POAMApproved' 
		GROUP BY PK_OrgSubmission, ORG.Status_code, FieldName
	), Submission AS ( 
		SELECT TOP 1 ORG.PK_OrgSubmission
		, PK_POAM 
		, LastSubmissionDate 
		, SubmissionStatus
		, COALESCE(ASSMT.AgRecievedDate, ASSMT.DateCreated) AS FinalizedDate  
		FROM fsma_POAMS POAM
		INNER JOIN fsma_OrgSubmissions ORG ON ORG.FK_LINK=POAM.PK_POAM AND ORG.PK_OrgSubmission=@PK_OrgSubmission  
		INNER JOIN fsma_Assessments ASSMT ON POAM.FK_PK_Assessment=ASSMT.PK_Assessment
		LEFT JOIN Audits AUD ON ORG.PK_OrgSubmission = AUD.PK_OrgSubmission 
	)  
	INSERT INTO @DeadlineDates (PK_POAM ,PK_OrgSubmission,SubmissionStatus,FinalizedDate,LastSubmissionDate ) 
	SELECT PK_POAM, PK_OrgSubmission,SubmissionStatus,FinalizedDate,LastSubmissionDate FROM Submission

	DECLARE @FinalizedDate DATETIME = (SELECT TOP 1 FinalizedDate FROM @DeadlineDates)
	DECLARE @LastSubmissionDate DATETIME = (SELECT TOP 1 LastSubmissionDate FROM @DeadlineDates)  
	DECLARE @MonthsSinceFinal INT = DATEDIFF(MONTH, @FinalizedDate, GETDATE()) 
	DECLARE @MonthsSinceSubmission INT = DATEDIFF(MONTH, COALESCE(@LastSubmissionDate, @FinalizedDate), GETDATE())
	DECLARE @DaysSinceSubmission INT = DATEDIFF(DAY, COALESCE(@LastSubmissionDate, @FinalizedDate), GETDATE())
  
	IF @MonthsSinceFinal = 0 
	BEGIN
		SET @MonthsSinceFinal = 1
	END  

	IF COALESCE(@LastSubmissionDate, @FinalizedDate) >= DATEADD(DAY, -55, GETDATE()) -- TIMELY  
	BEGIN     
		UPDATE @DeadlineDates SET CurrentDeadline = DATEADD(DAY, -1, DATEADD(MONTH, @MonthsSinceFinal, FinalizedDate)) 
		UPDATE @DeadlineDates SET SubmissionDateOffset = ISNULL(DATEDIFF(MONTH,(SELECT TOP 1 CurrentDeadline FROM @DeadlineDates), @LastSubmissionDate) , 0)  
		IF @LastSubmissionDate IS NOT NULL--SELECT * FROM @DeadlineDates   
		BEGIN 
			UPDATE @DeadlineDates SET CurrentDeadline = DATEADD(MONTH,  SubmissionDateOffset+1, CurrentDeadline) 
		END 
		--SELECT * FROM @DeadlineDates 
	END
	IF COALESCE(@LastSubmissionDate, @FinalizedDate) < DATEADD(DAY, -55, GETDATE()) -- UNTIMELY  
	BEGIN 
		UPDATE @DeadlineDates SET CurrentDeadline = DATEADD(MONTH, @MonthsSinceFinal , FinalizedDate) 
		IF (SELECT CurrentDeadline FROM @DeadlineDates) < GETDATE()
		BEGIN
			UPDATE @DeadlineDates SET CurrentDeadline = DATEADD(MONTH, @MonthsSinceFinal+1 , FinalizedDate) 
		END  
		UPDATE @DeadlineDates SET CurrentDeadline = DATEADD(DAY, -1, CurrentDeadline)  
	END  
	UPDATE @DeadlineDates SET 
		  NextDeadline=DATEADD(MONTH, 1, CurrentDeadline) 
		, FutureDeadline=DATEADD(MONTH, 2, CurrentDeadline)	  
	UPDATE @DeadlineDates SET FinalOverdue=DATEADD(DAY, -5, NextDeadline) 
	RETURN 
END 
 /* 
	SELECT POAM.PK_POAM, DDC.*
	FROM fsma_POAMS POAM
	INNER JOIN fsma_OrgSubmissions ORG ON ORG.FK_LINK=POAM.PK_POAM
	OUTER APPLY fn_PoamDeadlineDatesCalc(ORG.PK_OrgSubmission ) DDC
	WHERE ORG.PK_OrgSubmission = 25017 
 */
  
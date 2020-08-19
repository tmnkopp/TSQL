/*
Who: TKOPP
When: 8-5-2020
Why: Used for Appendix A 
How: EXEC [dbo].[cap_AppendixA_CIOQ42020] @PK_OrgSubmission=22406 ; EXEC [dbo].[cap_AppendixA_CIOQ32019] @PK_OrgSubmission=22406 ;
*/ 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'cap_AppendixA_CIOQ42020' AND type = 'P')
    DROP PROCEDURE [cap_AppendixA_CIOQ42020]
GO 
CREATE PROCEDURE [dbo].[cap_AppendixA_CIOQ42020]
(
	@PK_OrgSubmission INT = 0
)
AS
BEGIN
	DECLARE @Inf nvarchar(20)='Infinity'--NCHAR(8734)   --1/0
	DECLARE @NaN nvarchar(20)='NaN' --0/0

	DECLARE  @Calc TABLE(PK_Question int,PK_QuestionGroup int,PK_Capability int,capTarget nvarchar(20),compOperator Varchar(10),identifier_text varchar(20),QuestionText nvarchar(max),StrFormula nvarchar(500),valFormula nvarchar(500),Result nvarchar(20),Rating varchar(20),sortpos int)

	INSERT INTO @Calc(PK_Question,PK_QuestionGroup,PK_Capability,capTarget,compOperator,identifier_text,QuestionText,StrFormula,sortpos)
		SELECT q.PK_Question,qg.PK_QuestionGroup,cm.PK_Capability,ltrim(rtrim(cm.ThresholdValue)) capTarget,cm.CompOperator,replace(q.identifier_text,' ','') identifier_text,q.QuestionText,replace(cm.StrFormula,' ','') StrFormula,q.sortpos
		FROM fsma_Questions q
		INNER JOIN fsma_QuestionGroups qg on qg.PK_QuestionGroup=q.FK_QuestionGroup
		inner join fsma_OrgSubmissions org on org.PK_Form=qg.PK_Form AND org.PK_OrgSubmission=@PK_OrgSubmission
		inner JOIN CompareMetrics cm on cm.PK_CompareMetrics=q.PK_ExternalLink
		WHERE 1=1
		--AND qg.PK_Form='2019-Q3-CIO'
		AND qg.GroupName='APPENDIXA' 

	-- *** calculations goes here
	--// Set answers for question numbers, except A8,A10
	UPDATE  @Calc SET Result='0'
	UPDATE  @Calc
	SET valFormula=dbo.fn_SetFormulaAns(@PK_OrgSubmission,StrFormula)
	WHERE identifier_text NOT IN  ('A8','A10')

	DECLARE @RESULTSET TABLE (EXPRESSION NVARCHAR(4000), RESULT NVARCHAR(4000))
	DECLARE @ListResult NVARCHAR(4000) = ''
	DECLARE @StrFormula NVARCHAR(4000) = NULL

	DECLARE @Expressions NVARCHAR(4000) = (SELECT valFormula+';' FROM @Calc WHERE identifier_text not in  ('A8','A10') AND (CHARINDEX('Nx',valFormula)<=0) FOR XML PATH(''))  
	EXEC sp_ResultProvider @Expressions=@Expressions,@RESULTSET=@ListResult OUTPUT 
	INSERT INTO @RESULTSET
	SELECT * FROM dbo.fn_HashSplit(@ListResult, ':' , ';') 
	 
	UPDATE  @Calc
	SET Result=(SELECT TOP 1 RESULT FROM @RESULTSET WHERE EXPRESSION=valFormula AND RESULT IS NOT NULL)
	WHERE identifier_text not in  ('A8','A10') AND (CHARINDEX('Nx',valFormula)<=0)

	UPDATE  @Calc SET Result='NA' WHERE Result = @Inf or Result=@NaN and identifier_text='A6'
	
	UPDATE  @Calc SET Result='0' WHERE Result = @Inf or Result=@NaN
	
	
	--Round decimals 
	UPDATE @Calc
	SET Result=ROUND(CAST(Result AS REAL),0)
	WHERE isnumeric(Result)=1 
	AND  identifier_text not in  ('A8','A10')

	--Compare with target
	UPDATE @Calc
	SET Rating=[dbo].[fn_CompOperator](Result,capTarget,compOperator)-- true:1,false:0
	WHERE identifier_text NOT IN  ('A8','A10') AND ISNUMERIC(Result)=1

	--** A8 logic **
	IF ([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.11')='0')-- dbo.fn_SetFormulaAns(@PK_OrgSubmission,'[3.7]/[2.11]')='0/0')
	BEGIN
		UPDATE @Calc
		SET QuestionText= REPLACE(QuestionText,'4 of 6','3 of 5')
		,StrFormula= REPLACE(StrFormula,'[3.7]/[2.11];','')
		,capTarget=cast(capTarget AS INT) -1
		WHERE identifier_text IN ('A8')

		UPDATE @Calc
		SET QuestionText= REPLACE(QuestionText,'(3.7/2.11),','')
		WHERE identifier_text in('A8')
	END

	SET @StrFormula = (SELECT TOP 1 StrFormula FROM @Calc WHERE identifier_text IN ('A8')) 

	DELETE FROM @RESULTSET
	INSERT INTO @RESULTSET (EXPRESSION, RESULT)
	SELECT dbo.fn_SetFormulaAns(@PK_OrgSubmission,string) Expression, NULL FROM dbo.[iter_stringlist_to_tbl](@StrFormula,';') 

	SET @Expressions = (SELECT EXPRESSION+';' FROM @RESULTSET FOR XML PATH(''))    
	EXEC sp_ResultProvider @Expressions=@Expressions,@RESULTSET=@ListResult OUTPUT 

	INSERT INTO @RESULTSET
	SELECT * FROM dbo.fn_HashSplit(@ListResult, ':' , ';') 
	UPDATE @RESULTSET SET RESULT = 'Nx' WHERE Result = ''
	UPDATE  @Calc
	SET Result=(SELECT COUNT(*)  FROM 
						(
							SELECT expr sval FROM 
							(
								SELECT RESULT expr FROM @RESULTSET
							) s1
							WHERE CHARINDEX('Nx',s1.expr)<=0
						)s2
						WHERE  s2.sval<> @Inf AND s2.sval<>@NaN AND ROUND(CAST(s2.sval AS REAL),0)>=90
				) 
	WHERE identifier_text in('A8')

	UPDATE @Calc
	SET Rating=[dbo].[fn_CompOperator](Result,capTarget,compOperator)
	WHERE identifier_text in('A8')

	--Add dmarck value
	DECLARE @dmarc AS VARCHAR(20)=REPLACE([dbo].[fn_getAnswer](@PK_OrgSubmission,'3.1'),'Nx','')
	UPDATE  @Calc
	SET capTarget='100 | '+capTarget
	,Result=@dmarc+' | '+Result
	WHERE identifier_text in('A8')

	UPDATE  @Calc
	SET Rating= (CASE WHEN  @dmarc>=100 and Rating='1' THEN '1' ELSE '0' END)
	WHERE identifier_text in('A8')

	--** A10 logic **
	DECLARE @Cycle INT;
	SELECT @Cycle = rc.FK_ReportingCycle FROM fsma_OrgSubmissions a INNER JOIN fsma_ReportingCycle_Components rc ON rc.PK_ReportingCycle_Component = a.FK_ReportingCycle_Component INNER JOIN [Component List] c ON rc.FK_Component = c.PK_Component WHERE c.isActive = 1 AND a.PK_OrgSubmission = @PK_OrgSubmission 
	IF ([dbo].[fn_getAnswer](@PK_OrgSubmission,'1.1.5')='0') --2.7.1==HVA
	BEGIN
		IF (@Cycle = 77)
			BEGIN
				UPDATE @Calc
				SET QuestionText= REPLACE(QuestionText,'4 of 6','2 of 2')
				,StrFormula= replace(replace(replace(REPLACE(StrFormula,'100*[2.8]/([1.1.5]-[2.8.1]);',''),'100*[2.13]/[1.1.5];',''),'100*[2.13.1]/[1.1.6];',''),';100*[2.9]/([1.1.6])','')
				,capTarget='2'--cast(capTarget as int) - 4
				WHERE identifier_text in('A10')

				UPDATE @Calc
				SET QuestionText= replace(replace(replace(REPLACE(QuestionText,'(2.8 / (1.1.5 – 2.8.1)),',''),'(2.13 / 1.1.5),',''),'(2.13.1 / 1.1.6),',''),'2.9 / (1.1.6 – 2.9.1)','')
				WHERE identifier_text in('A10')
			END
		IF (@Cycle >77 and @Cycle<80)
			BEGIN
				UPDATE @Calc
				SET QuestionText= REPLACE(QuestionText,'4 of 6','2 of 2')
				,StrFormula= replace(replace(replace(REPLACE(StrFormula,'100*[2.8]/([1.1.5]-[2.8.1]);',''),'100*[2.13]/[1.1.5];',''),'100*[2.13.1]/[2.13];',''),';100*[2.9]/([2.13])','')
				,capTarget='2'--cast(capTarget as int) - 4
				WHERE identifier_text in('A10')

				UPDATE @Calc
				SET QuestionText= replace(replace(replace(REPLACE(QuestionText,'(2.8 / (1.1.5 – 2.8.1)),',''),'(2.13 / 1.1.5),',''),'(2.13.1 / 2.13),',''),'2.9 / (1.1.5 – 2.9.1)','')
				WHERE identifier_text in('A10')
			END
		IF (@Cycle>=80 and @Cycle<83)
			BEGIN
				UPDATE @Calc
				SET QuestionText= REPLACE(QuestionText,'4 of 6','2 of 2')
				,StrFormula= replace(replace(replace(REPLACE(StrFormula,'100*[2.8]/([1.1.6]-[2.8.1]);',''),'100*[2.13]/[1.1.5];',''),'100*[2.13.1]/[2.13];',''),';100*[2.9]/([2.13])','')
				,capTarget='2'--cast(capTarget as int) - 4
				WHERE identifier_text in('A10')

				UPDATE @Calc
				SET QuestionText= replace(replace(replace(REPLACE(QuestionText,'(2.8/(1.1.5-2.8.1)),',''),'(2.13/1.1.5),',''),'(2.13.1/2.13),',''),'2.9/(1.1.6-2.9.1)','')
				WHERE identifier_text in('A10')
			END
		IF (@Cycle>=83 ) --2020-Q3-CIO 
			BEGIN
			--keep (2.12/1.2.1), (lesser of 2.10.1a or 2.10.1b)
				UPDATE @Calc
				SET QuestionText= REPLACE(QuestionText,'4 of 6','2 of 2')
				--,StrFormula= replace(replace(replace(REPLACE(StrFormula,'100*[2.8]/([1.1.6]-[2.8.1]);',''),'100*[2.13]/[1.1.5];',''),'100*[2.13.1]/[2.13];',''),';100*[2.9]/([2.13])','')
				,StrFormula='100.0*[2.12]/[1.2.1];min([2.10.1a],[2.10.1b])'
				,capTarget='2'--cast(capTarget as int) - 4
				WHERE identifier_text in('A10')

				UPDATE @Calc
				SET 
				--QuestionText= replace(replace(replace(replace(REPLACE(QuestionText,'(2.8/(1.1.5-2.8.1)),',''),'(2.13/1.1.5),',''),'(2.13.1/2.13),',''),'2.9/(1.1.6-2.9.1)',''),'(2.13.1/1.1.6),','')
				QuestionText='At least 2 of 2 metrics have met an implementation target of at least 90% [(2.12/1.2.1),  (lesser of 2.10.1a or 2.10.1b)'
				WHERE identifier_text in('A10')
			END

	END
	ELSE
	BEGIN
		UPDATE @Calc SET capTarget='4' WHERE identifier_text in('A10')
	END
	IF ([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.10.1a')='NA') --isnumeric([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.7.1'))=1
	BEGIN
		UPDATE @Calc SET
		--QuestionText= REPLACE(REPLACE(QuestionText,'4 of 6','4 of 5'),'(lesser of 2.10.1a or 2.10.1b),','')
		StrFormula= REPLACE(StrFormula,'min([2.10.1a],[2.10.1b])','[2.10.1b]')
		--,capTarget='4'
		WHERE identifier_text in('A10')

	END
	IF ([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.10.1b')='NA') --isnumeric([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.7.1'))=1
	BEGIN
		UPDATE @Calc SET
		--QuestionText= REPLACE(REPLACE(QuestionText,'4 of 6','4 of 5'),'(lesser of 2.10.1a or 2.10.1b),','')
		StrFormula= REPLACE(StrFormula,'min([2.10.1a],[2.10.1b])','[2.10.1a]')
		--,capTarget='4'
		WHERE identifier_text in('A10')

	END

	IF ([dbo].[fn_getAnswer](@PK_OrgSubmission,'1.1.5')='0' and  ([dbo].[fn_getAnswer](@PK_OrgSubmission,'2.10.1a')='NA' AND [dbo].[fn_getAnswer](@PK_OrgSubmission,'2.10.1a')='NA')) --2.7.1==HVA
	BEGIN
		UPDATE @Calc
		SET QuestionText= REPLACE(REPLACE(QuestionText,'4 of 6','1 of 1'),'(lesser of 2.10.1a or 2.10.1b),','')
		,StrFormula= '100.0*[2.12]/[1.2.1]; 100*[2.13.1]/[1.1.6];'
		,capTarget='1'
		WHERE identifier_text in('A10')

	END

	SET @StrFormula = (SELECT TOP 1 StrFormula FROM @Calc WHERE identifier_text IN ('A10')) 

	DELETE FROM @RESULTSET
	INSERT INTO @RESULTSET (EXPRESSION, RESULT)
	SELECT dbo.fn_SetFormulaAns(@PK_OrgSubmission,string) Expression, NULL FROM dbo.[iter_stringlist_to_tbl](@StrFormula,';') 

	SET @Expressions = (SELECT EXPRESSION+';' FROM @RESULTSET FOR XML PATH(''))    
	EXEC sp_ResultProvider @Expressions=@Expressions,@RESULTSET=@ListResult OUTPUT 

	INSERT INTO @RESULTSET
	SELECT * FROM dbo.fn_HashSplit(@ListResult, ':' , ';') 
	UPDATE @RESULTSET SET RESULT = 'Nx' WHERE Result = ''
	UPDATE  @Calc
	SET Result=(SELECT COUNT(*)  FROM 
						(
							SELECT expr sval FROM 
							(
								SELECT  RESULT expr FROM @RESULTSET
							) s1
							WHERE CHARINDEX('Nx',s1.expr)<=0  and CHARINDEX('NA',s1.expr)<=0
						)s2
						WHERE  s2.sval<> @Inf AND s2.sval<>@NaN  AND ROUND(CAST(s2.sval AS REAL),0)>=90
				) 
	WHERE identifier_text in('A10')

	UPDATE @Calc
	SET Rating=[dbo].[fn_CompOperator](Result,capTarget,compOperator)
	WHERE identifier_text in('A10')


	--SELECT * FROM @Calc

	--*** Results
	SELECT 
	c.PK_Question
	, REPLACE(c.identifier_text,' ','') QuestionNumbering
	, cs.StrategyDescription
	, c.QuestionText
	, (REPLACE(c.identifier_text,' ','')+'. '+COALESCE(cap.Capability,'')) Capability
	, c.Result Answer
	, c.capTarget [TargetVal]
	, c.Rating Rating
	, dbo.fn_stripHTML(narr.Narrative) AS Narrative 
	, narr.PK_NarrAnswers
	, c.sortpos
	, cs.sortpos sortpos_strategy
	FROM 
	@Calc c
	LEFT JOIN fsma_NarrAnswers narr ON narr.LinkFieldCode=c.PK_Question  and narr.PK_OrgSubmission=@PK_OrgSubmission 
	LEFT JOIN cap_Capability cap on cap.PK_Capability=c.PK_Capability
	LEFT JOIN CapStrategy cs on cs.PK_Strategy=cap.PK_Strategy
	ORDER BY cs.SortPos ASC
	 
END 
GO

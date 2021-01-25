SELECT * INTO RMA2020
FROM(
	SELECT  
	PK_Component, 
	Vector.Agency,
	'2020' FiscalYear,
	Vector.Incidents_Vector,
	Vector.Value,
	Vector.Size,
	Vector.SortOrder,
	ORS.PK_OrgSubmission
	FROM (
		SELECT Agency , Size, 'Attrition' [Incidents_Vector] , [Attrition] Value, 0 As SortOrder FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'E-mail' [Incidents_Vector] , [E-mail] Value, 1 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'External/Removable Media' [Incidents_Vector] , [External/Removable Media] Value, 2 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Impersonation' [Incidents_Vector] , [Impersonation] Value, 3 As SortOrder   FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Improper Usage' [Incidents_Vector] , [Improper Usage] Value, 4 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Loss or Theft of Equipment' [Incidents_Vector] , [Loss or Theft of Equipment] Value, 5 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Web' [Incidents_Vector] , [Web] Value, 6 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Other' [Incidents_Vector] , [Other] Value, 7 As SortOrder  FROM RMAIncidents2020 UNION 
		SELECT Agency , Size, 'Multiple Attack Vectors' [Incidents_Vector] , [Multiple Attack Vectors] Value, 8 As SortOrder   FROM RMAIncidents2020 
	) Vector
	CROSS APPLY (
		SELECT Component, PK_Component FROM [Component List] CL
		WHERE Vector.Agency = CL.Component AND FK_PK_Component IS NULL
	)   CL
	CROSS APPLY (
		SELECT PK_OrgSubmission
		FROM fsma_ReportingCycle_Components rc  
		INNER JOIN fsma_OrgSubmissions o ON o.FK_ReportingCycle_Component = rc.PK_ReportingCycle_Component  
		WHERE rc.FK_Component = CL.PK_Component AND rc.FK_ReportingCycle=91
	)   ORS


) RMA2020



DECLARE @PK_ReportingCycleAAPS INT = (SELECT MAX(PK_ReportingCycle) FROM fsma_ReportingCycles WHERE PK_DataCall=13)
PRINT @PK_ReportingCycleAAPS 
 
/*

FROM fsma_ReportingCycle_Components rc  
INNER JOIN fsma_OrgSubmissions o ON o.FK_ReportingCycle_Component = rc.PK_ReportingCycle_Component  
WHERE rc.FK_Component = #RMAIncidents2020.PK_Component AND rc.FK_ReportingCycle=91

*/ 

/*
SELECT *  FROM RMAIncidents2020 
SELECT  'SELECT Agency , '''+COLUMN_NAME+''' [Incidents_Vector] , ['+COLUMN_NAME+'] FROM RMAIncidents2020 UNION '
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='RMAIncidents2020'
*/
SELECT * FROM RMAIncidents_BACKUP

SELECT * INTO RMAIncidents_BACKUP
FROM RMAIncidents

 
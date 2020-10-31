exec cq_HVAPOAMs @PK_Component=N'109',@PK_Bureau=N'-10',@PK_HVA=N'111',@poamsubmissiondate=N'2020-10-11',@UserID=0


RETURN ; 
SELECT 
 PK_AuditLog, TableName, PK_PrimeKey, FieldName, FieldValue, Change_Date
 FROM AuditLog
WHERE TableName IN( 'fsma_Activities'  )
-- AND FieldName LIKE '%PK_%'
ORDER BY Change_Date DESC

RETURN; 

SELECT 
 PK_AuditLog, TableName, PK_PrimeKey, FieldName, FieldValue, Change_Date
 FROM AuditLog
WHERE TableName IN( 'fsma_POAMS'  )
-- AND FieldName LIKE '%PK_%'
ORDER BY Change_Date DESC

RETURN;

exec cq_HVAPOAMs @PK_Component=N'109',@PK_Bureau=N'-10',@PK_HVA=N'155',@assmtsource=N'RVA',@poamstat=N'IP',@UserID=0
exec cq_HVAPOAM_MS @PK_Component=N'109',@PK_Bureau=N'-10',@PK_HVA=N'155',@PK_POAM=N'1',@assmtsource=N'RVA',@msstat=N'IP',@UserID=0 
exec cq_HVAPOAM_ACTS @PK_Component=N'109',@PK_Bureau=N'-10',@PK_HVA=N'155',@PK_POAM=N'1',@PK_Milestone=N'1',@assmtsource=N'RVA',@actstat=N'IP',@UserID=0

RETURN;
 


SELECT 
 PK_AuditLog, TableName, PK_PrimeKey, FieldName, FieldValue, Change_Date
 FROM AuditLog
WHERE TableName IN(   'fsma_Milestones'  )
-- AND FieldName LIKE '%PK_%'
ORDER BY Change_Date DESC

RETURN; 
 
SELECT * FROM fsma_POAMS POAM
LEFT JOIN fsma_OrgSubmissions ON POAM.PK_OrgSubmission = fsma_OrgSubmissions.PK_OrgSubmission
LEFT JOIN fsma_HVAs HVA ON HVA.PK_HVA = POAM.FK_PK_HVA
LEFT JOIN fsma_Milestones MS ON POAM.PK_POAM = MS.FK_PK_POAM 
LEFT JOIN fsma_Activities ACT ON ACT.FK_PK_Milestone = MS.PK_Milestone 
WHERE PK_POAM = 18
 
RETURN; 

SELECT TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME IN('fsma_POAMS', 'fsma_Milestones', 'fsma_Activities' )
 
RETURN; 
 
  
--EXEC HVAMaster @VIEW='AGENCY_HVAS', @PK_Component_Agency='170'
--EXEC HVAMaster @VIEW=N'HVA_ANNUAL',@PK_HVA=N'662'
SELECT TOP 5 * FROM fsma_POAMS ORDER BY PK_POAM DESC 
SELECT TOP 5 * FROM fsma_Milestones ORDER BY PK_Milestone DESC
SELECT TOP 5 * FROM fsma_Activities ORDER BY PK_Activity DESC 


RETURN ;  
 

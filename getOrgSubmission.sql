SELECT DISTINCT 
                     dbo.fsma_OrgSubmissions.PK_OrgSubmission, dbo.fsma_ReportingCycle_Components.FK_ReportingCycle, dbo.[Component List].Acronym, 
                     dbo.fsma_OrgSubmissions.PK_Form, dbo.[Component List].Component
FROM         dbo.fsma_ReportingCycle_Components INNER JOIN
                     dbo.fsma_OrgSubmissions ON 
                     dbo.fsma_ReportingCycle_Components.PK_ReportingCycle_Component = dbo.fsma_OrgSubmissions.FK_ReportingCycle_Component INNER JOIN
                     dbo.[Component List] ON dbo.fsma_ReportingCycle_Components.FK_Component = dbo.[Component List].PK_Component
WHERE     (dbo.fsma_ReportingCycle_Components.FK_ReportingCycle = 51)
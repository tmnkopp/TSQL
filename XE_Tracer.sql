 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='Tracer')
    DROP EVENT SESSION [Tracer] ON SERVER; 
GO
CREATE EVENT SESSION [Tracer] ON SERVER 
	ADD EVENT sqlserver.rpc_completed
	( 
		ACTION(sqlserver.sql_text)
		WHERE (
			   [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Artifact%')  
			OR [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Audit%')  
		)
	)  
	, ADD EVENT sqlserver.sql_statement_completed
    ( 
        ACTION(sqlserver.sql_text)
        WHERE ( 
			   [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Artifact%')  
			OR [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Audit%')  
		)
    )
	ADD TARGET package0.event_file(SET filename=N'C:\temp\Tracer.xel',max_file_size=(50))
GO
ALTER EVENT SESSION [Tracer] ON SERVER  STATE = start;  
GO  


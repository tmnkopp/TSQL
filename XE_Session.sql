 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='Audit')
    DROP EVENT SESSION [Audit] ON SERVER; 
GO
CREATE EVENT SESSION [Audit] ON SERVER 
	ADD EVENT sqlserver.rpc_completed
	(
		SET collect_data_stream=(0),collect_output_parameters=(1),collect_statement=(1)
		ACTION(sqlserver.sql_text)
		WHERE (
			[sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Solar%') 
		)
	)  
	, ADD EVENT sqlserver.sql_statement_completed
    ( 
        ACTION(sqlserver.sql_text)
        WHERE ( 
			[sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Solar%')
			OR [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Artifact%')  
			OR [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%Audit%')  
		)
    )
	ADD TARGET package0.event_file(SET filename=N'C:\temp\trace.xel',max_file_size=(10))
GO
ALTER EVENT SESSION [Audit] ON SERVER  STATE = start;  
GO  


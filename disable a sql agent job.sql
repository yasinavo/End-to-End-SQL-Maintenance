EXEC msdb.dbo.sp_update_job @job_name='DBA - All database FULL backup',@enabled = 0 

EXEC msdb.dbo.sp_update_job @job_name='DBA - Defrag All Databases',@enabled = 0 
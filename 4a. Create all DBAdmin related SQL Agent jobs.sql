USE [msdb]
GO

/****** Object:  Job [DBA - Adhoc COPY_ONLY FULL DB backup]    Script Date: 02/10/2018 16:20:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Adhoc COPY_ONLY FULL DB backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Adhoc COPY_ONLY FULL DB backup SQL Agent step]    Script Date: 02/10/2018 16:20:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Adhoc COPY_ONLY FULL DB backup SQL Agent step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  		                @production varchar(1)
declare 		                @INCSIMPLE	varchar(1) 
declare 		                @ignoredb varchar(1)
declare 		                @checksum varchar(1)
declare 		                @isSP varchar(1)
declare			@recipient_list	varchar(2000)
declare			@format	varchar(8) = ''FORMAT'' -- noformat or format
declare			@init varchar(6) = ''INIT'' -- noinit or init
declare			@operator varchar(30) -- for LOR this should be... DBA-Alerts
declare			@cred varchar(30) = NULL
declare			@mailprof varchar(30) -- DBA-Alerts
declare			@encrypted	bit = 0 -- (0,1) default of 0 for no encryption required 
declare			@algorithm	varchar(20) = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
declare			@servercert	varchar(30) = NULL -- defaults to NULL
declare			@retaindays	int
declare			@buffercount int = 30 -- can be set to any number within reason
declare			@deletion_param int = 1 --can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
declare			@deletion_type bit = 0 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks
 
select 			@job_name = ''Adhoc COPY_ONLY FULL DB backup '' + @@SERVICENAME
select 			@backup_location = ''E:\SQL 2008R2\SQLBACK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
select 			@backup_type = ''F'' -- ''F'', ''S'', ''D'', ''T''
select 			@dbname ='''' --  a valid database name or spaces
select			@iscloud = ''N'' -- if yes, then you MUST uncommment the @cred variable and pass in a valid Azure credential
select 			@copy = 1 -- 1 or 0 -- copy only backup or not -- 0 is for not copy only
select 			@checksum = 1 -- 1 or 0 -- create a checksum for backup integrity validation
select 			@freq = ''Daily'' -- ''Weekly'', ''Daily''
select 			@production = ''Y'' -- ''Y'', ''N'' -- only use ''N'' for non production instances
select 			@INCSIMPLE = ''Y'' -- ''Y'', ''N'' -- include SIMPLE recovery model databases
select 			@ignoredb = ''N'' -- ''Y'' or ''N'' -- if "Y" then it will ignore the databases in the @dbname parameter
select			@isSP = ''N'' -- ''Y'' or ''N'' -- set to Y if the instance is used for SharePoint. Implemented due to extra long SP database names!
select			@recipient_list = ''haden.kingsland@cii.co.uk;''
select			@operator = ''DBA-Alerts''
-- uncommment the @cred variable and pass in a valid Azure credential if you required BLOB storage Azure backups
--select			@cred = ''<your credential here>'' -- uncomment this line if you need to use the iscloud option and enter your Azure BLOB storage credential
select			@mailprof = ''DBA-Alerts''
select			@encrypted = 0 -- default is 0 for not required
-- uncomment and set the below only if you require encrypted backups
--select			@algorithm = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
--select			@servercert	= NULL -- a valid server certificate from sys.certificates for the backups
select			@retaindays = 37
select			@buffercount = 50
select			@deletion_param = 1 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
select			@deletion_type	= 1 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks

--
-- Please note that the parameters MUST be in the correct order or the procedure WILL give incorrect results!
--
 EXECUTE @RC = [dbadmin].[dba].[usp_generic_backup_all_databases] 
 @job_name,
 @backup_location,
 @backup_type,
 @dbname,
 @iscloud,
 @copy,
 @freq,
 @production,
 @INCSIMPLE,
 @ignoredb,
 @checksum,
 @isSP,
 @recipient_list,
 @format,
 @init,
 @operator,
 @cred,
 @mailprof,
 @encrypted,
 @algorithm,
 @servercert,
 @retaindays,
 @buffercount,
 @deletion_param,
 @deletion_type', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - All database Differential backup]    Script Date: 02/10/2018 16:20:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - All database Differential backup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [All database Differential backup SQL Agent step]    Script Date: 02/10/2018 16:20:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'All database Differential backup SQL Agent step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  		                @production varchar(1)
declare 		                @INCSIMPLE	varchar(1) 
declare 		                @ignoredb varchar(1)
declare 		                @checksum varchar(1)
declare 		                @isSP varchar(1)
declare			@recipient_list	varchar(2000)
declare			@format	varchar(8) = ''FORMAT'' -- noformat or format
declare			@init varchar(6) = ''INIT'' -- noinit or init
declare			@operator varchar(30) -- for LOR this should be... DBA-Alerts
declare			@cred varchar(30) = NULL
declare			@mailprof varchar(30) -- DBA-Alerts
declare			@encrypted	bit = 0 -- (0,1) default of 0 for no encryption required 
declare			@algorithm	varchar(20) = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
declare			@servercert	varchar(30) = NULL -- defaults to NULL
declare			@retaindays	int
declare			@buffercount int = 30 -- can be set to any number within reason
declare			@deletion_param int = 1 --can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
declare			@deletion_type bit = 0 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks
 
select 			@job_name = ''All database DIFF Backups '' + @@SERVICENAME
select 			@backup_location = ''E:\SQL 2008R2\SQLBACK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
select 			@backup_type = ''D'' -- ''F'', ''S'', ''D'', ''T''
select 			@dbname ='''' --  a valid database name or spaces
select			@iscloud = ''N'' -- if yes, then you MUST uncommment the @cred variable and pass in a valid Azure credential
select 			@copy = 0 -- 1 or 0 -- copy only backup or not -- 0 is for not copy only
select 			@checksum = 1 -- 1 or 0 -- create a checksum for backup integrity validation
select 			@freq = ''Daily'' -- ''Weekly'', ''Daily''
select 			@production = ''Y'' -- ''Y'', ''N'' -- only use ''N'' for non production instances
select 			@INCSIMPLE = ''Y'' -- ''Y'', ''N'' -- include SIMPLE recovery model databases
select 			@ignoredb = ''N'' -- ''Y'' or ''N'' -- if "Y" then it will ignore the databases in the @dbname parameter
select			@isSP = ''N'' -- ''Y'' or ''N'' -- set to Y if the instance is used for SharePoint. Implemented due to extra long SP database names!
select			@recipient_list = ''haden.kingsland@cii.co.uk;''
select			@operator = ''DBA-Alerts''
-- uncommment the @cred variable and pass in a valid Azure credential if you required BLOB storage Azure backups
--select			@cred = ''<your credential here>'' -- uncomment this line if you need to use the iscloud option and enter your Azure BLOB storage credential
select			@mailprof = ''DBA-Alerts''
select			@encrypted = 0 -- default is 0 for not required
-- uncomment and set the below only if you require encrypted backups
--select			@algorithm = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
--select			@servercert	= NULL -- a valid server certificate from sys.certificates for the backups
select			@retaindays = 37
select			@buffercount = 50
select			@deletion_param = 3 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
select			@deletion_type	= 1 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks

--
-- Please note that the parameters MUST be in the correct order or the procedure WILL give incorrect results!
--
 EXECUTE @RC = [dbadmin].[dba].[usp_generic_backup_all_databases] 
 @job_name,
 @backup_location,
 @backup_type,
 @dbname,
 @iscloud,
 @copy,
 @freq,
 @production,
 @INCSIMPLE,
 @ignoredb,
 @checksum,
 @isSP,
 @recipient_list,
 @format,
 @init,
 @operator,
 @cred,
 @mailprof,
 @encrypted,
 @algorithm,
 @servercert,
 @retaindays,
 @buffercount,
 @deletion_param,
 @deletion_type', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Differential Backup all database schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=203000, 
		@active_end_time=235959, 
		@schedule_uid=N'059ddb70-089f-4885-870d-daa2481495c5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - All database FULL backup]    Script Date: 02/10/2018 16:20:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - All database FULL backup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [All database daily FULL backup SQL Agent step]    Script Date: 02/10/2018 16:20:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'All database daily FULL backup SQL Agent step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  		                @production varchar(1)
declare 		                @INCSIMPLE	varchar(1) 
declare 		                @ignoredb varchar(1)
declare 		                @checksum varchar(1)
declare 		                @isSP varchar(1)
declare			@recipient_list	varchar(2000)
declare			@format	varchar(8) = ''FORMAT'' -- noformat or format
declare			@init varchar(6) = ''INIT'' -- noinit or init
declare			@operator varchar(30) -- for LOR this should be... DBA-Alerts
declare			@cred varchar(30) = NULL
declare			@mailprof varchar(30) -- DBA-Alerts
declare			@encrypted	bit = 0 -- (0,1) default of 0 for no encryption required 
declare			@algorithm	varchar(20) = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
declare			@servercert	varchar(30) = NULL -- defaults to NULL
declare			@retaindays	int
declare			@buffercount int = 30 -- can be set to any number within reason
declare			@deletion_param int = 1 --can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
declare			@deletion_type bit = 0 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks
 
select 			@job_name = ''All database FULL backups '' + @@SERVICENAME
select 			@backup_location = ''E:\SQL 2008R2\SQLBACK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
select 			@backup_type = ''F'' -- ''F'', ''S'', ''D'', ''T''
select 			@dbname ='''' --  a valid database name or spaces
select			@iscloud = ''N'' -- if yes, then you MUST uncommment the @cred variable and pass in a valid Azure credential
select 			@copy = 0 -- 1 or 0 -- copy only backup or not -- 0 is for not copy only
select 			@checksum = 1 -- 1 or 0 -- create a checksum for backup integrity validation
select 			@freq = ''Daily'' -- ''Weekly'', ''Daily''
select 			@production = ''Y'' -- ''Y'', ''N'' -- only use ''N'' for non production instances
select 			@INCSIMPLE = ''Y'' -- ''Y'', ''N'' -- include SIMPLE recovery model databases
select 			@ignoredb = ''N'' -- ''Y'' or ''N'' -- if "Y" then it will ignore the databases in the @dbname parameter
select			@isSP = ''N'' -- ''Y'' or ''N'' -- set to Y if the instance is used for SharePoint. Implemented due to extra long SP database names!
select			@recipient_list = ''haden.kingsland@cii.co.uk;''
select			@operator = ''DBA-Alerts''
-- uncommment the @cred variable and pass in a valid Azure credential if you required BLOB storage Azure backups
--select			@cred = ''<your credential here>'' -- uncomment this line if you need to use the iscloud option and enter your Azure BLOB storage credential
select			@mailprof = ''DBA-Alerts''
select			@encrypted = 0 -- default is 0 for not required
-- uncomment and set the below only if you require encrypted backups
--select			@algorithm = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
--select			@servercert	= NULL -- a valid server certificate from sys.certificates for the backups
select			@retaindays = 37
select			@buffercount = 50
select			@deletion_param = 1 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
select			@deletion_type	= 1 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks

--
-- Please note that the parameters MUST be in the correct order or the procedure WILL give incorrect results!
--
 EXECUTE @RC = [dbadmin].[dba].[usp_generic_backup_all_databases] 
 @job_name,
 @backup_location,
 @backup_type,
 @dbname,
 @iscloud,
 @copy,
 @freq,
 @production,
 @INCSIMPLE,
 @ignoredb,
 @checksum,
 @isSP,
 @recipient_list,
 @format,
 @init,
 @operator,
 @cred,
 @mailprof,
 @encrypted,
 @algorithm,
 @servercert,
 @retaindays,
 @buffercount,
 @deletion_param,
 @deletion_type', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Full Backup schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=203000, 
		@active_end_time=235959, 
		@schedule_uid=N'd4278703-3182-4d82-b579-31ab5e52004e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - All database Transaction Log backup]    Script Date: 02/10/2018 16:20:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - All database Transaction Log backup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [All database Transaction Log backup SQL Agent step]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'All database Transaction Log backup SQL Agent step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  		                @production varchar(1)
declare 		                @INCSIMPLE	varchar(1) 
declare 		                @ignoredb varchar(1)
declare 		                @checksum varchar(1)
declare 		                @isSP varchar(1)
declare			@recipient_list	varchar(2000)
declare			@format	varchar(8) = ''FORMAT'' -- noformat or format
declare			@init varchar(6) = ''INIT'' -- noinit or init
declare			@operator varchar(30) -- for LOR this should be... DBA-Alerts
declare			@cred varchar(30) = NULL
declare			@mailprof varchar(30) -- DBA-Alerts
declare			@encrypted	bit = 0 -- (0,1) default of 0 for no encryption required 
declare			@algorithm	varchar(20) = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
declare			@servercert	varchar(30) = NULL -- defaults to NULL
declare			@retaindays	int
declare			@buffercount int = 30 -- can be set to any number within reason
declare			@deletion_param int = 1 --can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
declare			@deletion_type bit = 0 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks
 
select 			@job_name = ''All database Transaction Log backups'' + @@SERVICENAME
select 			@backup_location = ''E:\SQL 2008R2\SQLBACK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
select 			@backup_type = ''T'' -- ''F'', ''S'', ''D'', ''T''
select 			@dbname ='''' --  a valid database name or spaces
select			@iscloud = ''N'' -- if yes, then you MUST uncommment the @cred variable and pass in a valid Azure credential
select 			@copy = 0 -- 1 or 0 -- copy only backup or not -- 0 is for not copy only
select 			@checksum = 1 -- 1 or 0 -- create a checksum for backup integrity validation
select 			@freq = ''Daily'' -- ''Weekly'', ''Daily''
select 			@production = ''Y'' -- ''Y'', ''N'' -- only use ''N'' for non production instances
select 			@INCSIMPLE = ''Y'' -- ''Y'', ''N'' -- include SIMPLE recovery model databases
select 			@ignoredb = ''N'' -- ''Y'' or ''N'' -- if "Y" then it will ignore the databases in the @dbname parameter
select			@isSP = ''N'' -- ''Y'' or ''N'' -- set to Y if the instance is used for SharePoint. Implemented due to extra long SP database names!
select			@recipient_list = ''haden.kingsland@cii.co.uk;''
select			@operator = ''DBA-Alerts''
-- uncommment the @cred variable and pass in a valid Azure credential if you required BLOB storage Azure backups
--select			@cred = ''<your credential here>'' -- uncomment this line if you need to use the iscloud option and enter your Azure BLOB storage credential
select			@mailprof = ''DBA-Alerts''
select			@encrypted = 0 -- default is 0 for not required
-- uncomment and set the below only if you require encrypted backups
--select			@algorithm = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
--select			@servercert	= NULL -- a valid server certificate from sys.certificates for the backups
select			@retaindays = 37
select			@buffercount = 50
select			@deletion_param = 0 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
select			@deletion_type	= 1 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks

--
-- Please note that the parameters MUST be in the correct order or the procedure WILL give incorrect results!
--
 EXECUTE @RC = [dbadmin].[dba].[usp_generic_backup_all_databases] 
 @job_name,
 @backup_location,
 @backup_type,
 @dbname,
 @iscloud,
 @copy,
 @freq,
 @production,
 @INCSIMPLE,
 @ignoredb,
 @checksum,
 @isSP,
 @recipient_list,
 @format,
 @init,
 @operator,
 @cred,
 @mailprof,
 @encrypted,
 @algorithm,
 @servercert,
 @retaindays,
 @buffercount,
 @deletion_param,
 @deletion_type', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Transaction Log backup schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=100, 
		@active_end_time=235959, 
		@schedule_uid=N'9cab811d-db63-4536-92fd-ce3168637aee'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - All SYSTEM databases only FULL backup]    Script Date: 02/10/2018 16:20:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - All SYSTEM databases only FULL backup', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [All SYSTEM databases only FULL backup SQL Agent step]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'All SYSTEM databases only FULL backup SQL Agent step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  		                @production varchar(1)
declare 		                @INCSIMPLE	varchar(1) 
declare 		                @ignoredb varchar(1)
declare 		                @checksum varchar(1)
declare 		                @isSP varchar(1)
declare			@recipient_list	varchar(2000)
declare			@format	varchar(8) = ''FORMAT'' -- noformat or format
declare			@init varchar(6) = ''INIT'' -- noinit or init
declare			@operator varchar(30) -- for LOR this should be... DBA-Alerts
declare			@cred varchar(30) = NULL
declare			@mailprof varchar(30) -- DBA-Alerts
declare			@encrypted	bit = 0 -- (0,1) default of 0 for no encryption required 
declare			@algorithm	varchar(20) = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
declare			@servercert	varchar(30) = NULL -- defaults to NULL
declare			@retaindays	int
declare			@buffercount int = 30 -- can be set to any number within reason
declare			@deletion_param int = 1 --can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
declare			@deletion_type bit = 0 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks
 
select 			@job_name = ''All SYSTEM Database FULL Backups'' + @@SERVICENAME
select 			@backup_location = ''E:\SQL 2008R2\SQLBACK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
select 			@backup_type = ''S'' -- ''F'', ''S'', ''D'', ''T''
select 			@dbname ='''' --  a valid database name or spaces
select			@iscloud = ''N'' -- if yes, then you MUST uncommment the @cred variable and pass in a valid Azure credential
select 			@copy = 0 -- 1 or 0 -- copy only backup or not -- 0 is for not copy only
select 			@checksum = 1 -- 1 or 0 -- create a checksum for backup integrity validation
select 			@freq = ''Daily'' -- ''Weekly'', ''Daily''
select 			@production = ''Y'' -- ''Y'', ''N'' -- only use ''N'' for non production instances
select 			@INCSIMPLE = ''Y'' -- ''Y'', ''N'' -- include SIMPLE recovery model databases
select 			@ignoredb = ''N'' -- ''Y'' or ''N'' -- if "Y" then it will ignore the databases in the @dbname parameter
select			@isSP = ''N'' -- ''Y'' or ''N'' -- set to Y if the instance is used for SharePoint. Implemented due to extra long SP database names!
select			@recipient_list = ''haden.kingsland@cii.co.uk;''
select			@operator = ''DBA-Alerts''
-- uncommment the @cred variable and pass in a valid Azure credential if you required BLOB storage Azure backups
--select			@cred = ''<your credential here>'' -- uncomment this line if you need to use the iscloud option and enter your Azure BLOB storage credential
select			@mailprof = ''DBA-Alerts''
select			@encrypted = 0 -- default is 0 for not required
-- uncomment and set the below only if you require encrypted backups
--select			@algorithm = NULL -- defaults to NULL / Valid options are... AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY
--select			@servercert	= NULL -- a valid server certificate from sys.certificates for the backups
select			@retaindays = 37
select			@buffercount = 50
select			@deletion_param = 3 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
select			@deletion_type	= 1 -- 0 = weeks, 1 = days -- MUST be set to define value by which old backup files are deleted -- Default is weeks

--
-- Please note that the parameters MUST be in the correct order or the procedure WILL give incorrect results!
--
 EXECUTE @RC = [dbadmin].[dba].[usp_generic_backup_all_databases] 
 @job_name,
 @backup_location,
 @backup_type,
 @dbname,
 @iscloud,
 @copy,
 @freq,
 @production,
 @INCSIMPLE,
 @ignoredb,
 @checksum,
 @isSP,
 @recipient_list,
 @format,
 @init,
 @operator,
 @cred,
 @mailprof,
 @encrypted,
 @algorithm,
 @servercert,
 @retaindays,
 @buffercount,
 @deletion_param,
 @deletion_type', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'System Database backup schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=203000, 
		@active_end_time=235959, 
		@schedule_uid=N'387136f9-f6f9-42fa-903d-12da770ef01a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Check Current SQL Server Log for the word "DBCC database corruption"]    Script Date: 02/10/2018 16:20:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Check Current SQL Server Log for the word "DBCC database corruption"', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check for the word "DBCC database corruption" in the current SQL Server Log. This runs every 30 minutes and looks back over the past 30 minutes for any occurence of the word DBCC database corruption.If it finds one or more, it will send an email to a specified operator, detailing what it found. The table for this process is cleared down to keep a rolling 15 days worth of data via the "Clean up DBAdmin Tables Daily" job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run usp_readerrorlog]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run usp_readerrorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_readerrorlog 0, 1, ''DBCC database corruption:''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'readerrorlog schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181002, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'c274ad3e-1c95-4adc-96a2-cc37c4d80116'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Check Current SQL Server Log for the word "Error"]    Script Date: 02/10/2018 16:20:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Check Current SQL Server Log for the word "Error"', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check for the word "Error" in the current SQL Server Log. This runs every 30 minutes and looks back over the past 30 minutes for any occurence of the word error.If it finds one or more, it will send an email to a specified operator, detailing what it found. The table for this process is cleared down to keep a rolling 15 days worth of data via the "Clean up DBAdmin Tables Daily" job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run usp_readerrorlog]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run usp_readerrorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_readerrorlog 0, 1, ''error''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'readerrorlog schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181002, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'85678779-f0c2-4cfc-b15b-68d87339752e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Check Current SQL Server Log for the words "attempt to fetch logical page"]    Script Date: 02/10/2018 16:20:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Check Current SQL Server Log for the words "attempt to fetch logical page"', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check for the words "attempt to fetch logical page" in the current SQL Server Log. This runs every 30 minutes and looks back over the past 30 minutes for any occurence of the word error.If it finds one or more, it will send an email to a specified operator, detailing what it found. The table for this process is cleared down to keep a rolling 15 days worth of data via the "Clean up DBAdmin Tables Daily" job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run usp_readerrorlog]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run usp_readerrorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_readerrorlog 0, 1, ''attempt to fetch logical page''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'readerrorlog schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181002, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'a5843d41-99b7-4334-8aef-b9cdb19b83b8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Check Current SQL Server Log for the words "BobMgr::GetBuf: Bob write not complete after 60 seconds"]    Script Date: 02/10/2018 16:20:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Check Current SQL Server Log for the words "BobMgr::GetBuf: Bob write not complete after 60 seconds"', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check for the words "BobMgr::GetBuf: Bob write not complete after 60 seconds" in the current SQL Server Log. This runs every 30 minutes and looks back over the past 30 minutes for any occurence of the word error.If it finds one or more, it will send an email to a specified operator, detailing what it found. The table for this process is cleared down to keep a rolling 15 days worth of data via the "Clean up DBAdmin Tables Daily" job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run usp_readerrorlog]    Script Date: 02/10/2018 16:20:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run usp_readerrorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_readerrorlog 0, 1, ''BobMgr::GetBuf: Bob write not complete after 60 seconds''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'readerrorlog schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181002, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'07a29489-cfbe-4b01-9d76-9468746534a2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Check Current SQL Server Log for the words "I/O requests taking longer"]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Check Current SQL Server Log for the words "I/O requests taking longer"', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check for the words "I/O requests taking longer" in the current SQL Server Log. This runs every 30 minutes and looks back over the past 30 minutes for any occurence of the word error.If it finds one or more, it will send an email to a specified operator, detailing what it found. The table for this process is cleared down to keep a rolling 15 days worth of data via the "Clean up DBAdmin Tables Daily" job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run usp_readerrorlog]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run usp_readerrorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_readerrorlog 0, 1, ''I/O requests taking longer''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'readerrorlog schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181002, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'0a05e2bc-7684-46a6-9bef-3d0322bdf55e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Clean Up CPU, Memory & Query Tables]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Clean Up CPU, Memory & Query Tables', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'delete from dbadmin.dba.query where creationtime < GETDATE()-65
delete from dbadmin.dba.cpu where stattime < GETDATE()-65
delete from dbadmin.dba.Server_Memory_Status where logdate < GETDATE()-65', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean up CPU and Query Tables]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean up CPU and Query Tables', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'delete from dbadmin.dba.query where creationtime < GETDATE()-95
delete from dbadmin.dba.cpu where stattime < GETDATE()-95
delete from dbadmin.dba.Server_Memory_Status where logdate < GETDATE()-95', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Clean up cpu and query table schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=34500, 
		@active_end_time=235959, 
		@schedule_uid=N'ab813ec9-3459-4d5a-9859-e39b3b338806'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Clean up DBAdmin Tables Daily]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Clean up DBAdmin Tables Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To maintain the DBAdmin database tables', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up DBAdmin tables daily]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean Up DBAdmin tables daily', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @version varchar(20);

SELECT @version = CASE WHEN @@VERSION LIKE ''%9.0%''	THEN ''SQL 2005'' 
				   WHEN @@VERSION LIKE ''%8.0.%''	THEN ''SQL 2000''
				   WHEN @@VERSION LIKE ''%10.0%'' THEN ''SQL 2008'' 
				   WHEN @@VERSION LIKE ''%10.5%'' THEN ''SQL 2008 R2'' 
				   WHEN @@VERSION LIKE ''%11.0%'' THEN ''SQL 2012''
				   WHEN @@VERSION LIKE ''%12.0%'' THEN ''SQL 2014''
				   WHEN @@VERSION LIKE ''%13.0%'' THEN ''SQL 2016''
				   WHEN @@VERSION LIKE ''%14.0%'' THEN ''SQL 2017'' 
END;

delete from DBAdmin.dbo.DBGrowthRate where MetricDate < GETDATE()-34;
delete from DBAdmin.dbo.DBGrowthRate_Data where MetricDate < GETDATE()-34;
delete from DBAdmin.dbo.DBGrowthRate_TXLog where MetricDate < GETDATE()-34;
delete from DBAdmin.[dbo].[dba_indexDefragStatus] where ScanDate < GETDATE()-34;
delete from DBAdmin.[dbo].[dba_indexDefragLog] where dateTimestart < GETDATE()-34;
delete from DBAdmin.[dbo].[dba_indexDefragStatus_Archive] where ScanDate < GETDATE()-34;
delete from DBAdmin.dba.readerrorlog_results where (CONVERT(datetime, LogDate)) < GETDATE()-15;
delete from DBAdmin.dba.drivespace where metricdate < GETDATE()-15;
delete from DBAdmin.dba.DB_TableSpace where RunDate < GETDATE()-20;
delete from DBAdmin.dba.DB_TableGrowth where RunDate < GETDATE()-20;
delete from DBAdmin.dba.dba_max_size_change where recorded_date < getdate()-31

IF @version in (''SQL 2012'', ''SQL 2014'', ''SQL 2016'', ''SQL 2017'')
BEGIN
	delete from DBAdmin.dba.dbcc_history_2012 where TimeStamp < GETDATE()-14
END
	ELSE
		BEGIN
			delete from DBAdmin.dba.dbcc_history  where TimeStamp < GETDATE()-14
		END;

delete from DBAdmin.dba.io_snapshots where snapshot_creation_date < getdate()-31;
delete from DBAdmin.dba.io_snapshots_statistics where snap_date < getdate()-31;
delete from DBAdmin.dba.dba_instance_fileLatency where CaptureDate < getdate()-14

', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBAdmin CleanUp Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180906, 
		@active_end_date=99991231, 
		@active_start_time=100500, 
		@active_end_time=235959, 
		@schedule_uid=N'9d8843cb-d506-4155-a76a-a498cae60cc6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Clean up msdb.dbo.sysjobstepslogs table]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Clean up msdb.dbo.sysjobstepslogs table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean up the sysjobsteplog table]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean up the sysjobsteplog table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'delete from msdb.dbo.sysjobstepslogs where date_created > GETDATE()-31', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run sysjobstep purge daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'78a4df85-2ebb-4f98-ab0b-e0d6910efb1a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Cycle SQL Server Logs]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Cycle SQL Server Logs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This jobs cycles the SQL Server Log file to allow it to be more manageable. This occurs on the second day of each month at 07:35', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cycle SQL Logs]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cycle SQL Logs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec sys.sp_cycle_errorlog;
exec msdb.dbo.sp_cycle_agent_errorlog;', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Cycle SQL Server Logs Schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=4, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=73500, 
		@active_end_time=235959, 
		@schedule_uid=N'01085333-51b3-4585-9f78-cf7f3127ba05'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Database File Size Alert]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database File Size Alert', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check the datafile size of all databases to ensure that it is within given parameters, and then send an email if it needs to extend, or cannot extend.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Database File Size Alert]    Script Date: 02/10/2018 16:20:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Database File Size Alert', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.database_filesize_alert', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Database File Size Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'eae8b041-aa64-4b3b-be9d-5ae065b3eb27'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Database File Size Alert inc TX Logs]    Script Date: 02/10/2018 16:20:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database File Size Alert inc TX Logs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To check the datafile size of all databases & TX logs to ensure that it is within given parameters, and then send an email if it needs to extend, or cannot extend.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Database File Size Alert inc TX Logs]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Database File Size Alert inc TX Logs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.nullif_database_filesize_alert', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Database File Size Alert inc TX Logs schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=17, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=100, 
		@active_end_time=235959, 
		@schedule_uid=N'ddc474de-0896-4d8a-a0da-28c01d076b3d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Database Server Check Disk Space]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database Server Check Disk Space', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dba.check_server_disk_space', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Server disk space]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Database Server disk space', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.check_server_disk_space', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Check Database Disk Sizes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=51500, 
		@active_end_time=235959, 
		@schedule_uid=N'cbc104bb-a816-46f3-ac15-cee6c6347bdf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Database Server Disk Space Report]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database Server Disk Space Report', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_server_disk_space_report 1,''haden.kingsland@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run disk space report]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run disk space report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_server_disk_space_report 1,''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Disk space report', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=53000, 
		@active_end_time=235959, 
		@schedule_uid=N'ddc8c0da-6063-4770-9af5-b1c77116cb27'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - DBCC CheckDB Daily runs]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - DBCC CheckDB Daily runs', 
		@enabled=0, 
		@notify_level_eventlog=3, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CheckDB on all databases]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CheckDB on all databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sp_MSforeachdb N''IF DATABASEPROPERTYEX(''''?'''', ''''Collation'''') IS NOT NULL

BEGIN

    DBCC CHECKDB (?) WITH ALL_ERRORMSGS, EXTENDED_LOGICAL_CHECKS, DATA_PURITY

END'' ;
', 
		@database_name=N'master', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily DBBC CheckDB', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=230500, 
		@active_end_time=235959, 
		@schedule_uid=N'dd840f83-90cf-49b4-8f3d-af82975e32cd'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - DBCC CheckDB Daily runs logged]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - DBCC CheckDB Daily runs logged', 
		@enabled=1, 
		@notify_level_eventlog=3, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CheckDB on all databases]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CheckDB on all databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [dba].[DBA_RUN_CHECKDB_LOGGED]', 
		@database_name=N'DBAdmin', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily DBBC CheckDB', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=230500, 
		@active_end_time=235959, 
		@schedule_uid=N'dbeb30cb-5be1-45d0-ab5b-87a6cfdd09dc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Defrag All Databases]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Defrag All Databases', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Exec DBAdmin.dbo.dba_indexDefrag_sp procedure and then updates the database statistics across all databases in an instance
', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Defrag Index Job Step]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defrag Index Job Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/********************************************************************************************************************/
-- Disclaimer...
--
-- This script is provided for open use by Haden Kingsland (theflyingDBA) and as such is provided as is, with
-- no warranties or guarantees. 
-- The author takes no responsibility for the use of this script within environments that are outside of his direct 
-- control and advises that the use of this script be fully tested and ratified within a non-production environment 
-- prior to being pushed into production. 
-- This script may be freely used and distributed in line with these terms and used for commercial purposes, but 
-- not for financial gain by anyone other than the original author.
-- All intellectual property rights remain solely with the original author.
--
/********************************************************************************************************************/
--

SET ARITHABORT ON ;
SET QUOTED_IDENTIFIER ON ;

Exec DBAdmin.dba.usp_dba_indexDefrag
              @executeSQL           = 1 --0 = do it otherwise just analyse it
            , @printCommands        = 1
            , @debugMode            = 1
            , @printFragmentation   = 1
            , @forceRescan          = 1
            , @scanMode				= ''LIMITED''
            , @database				= NULL
            , @ignoredatabases		= ''ReportServer,ReportServerTempDB''
            , @maxDopRestriction    = 1
            , @minPageCount         =1000
            , @maxPageCount         = Null
            , @sortInTempDB	= 1 -- much more effecient to sort in TEMPDB if on faster disks
            , @minFragmentation     = 1
            , @rebuildThreshold     = 30
            , @defragDelay          = ''00:00:05''
            , @defragOrderColumn    = ''page_count''
            , @defragSortOrder      = ''DESC''
            , @excludeMaxPartition  = 1
            , @timeLimit            = 240 --  4 hours.
            , @onlineRebuild        = 0  -- 1 = online rebuild; 0 = offline rebuild; only in Enterprise 
            , @comp					= ''N'' -- N or P or R or C or CA specifies the level of data compression, if any, for the indexes 
										  -- during the rebuilds
			, @resume				= 0;  -- 1 for Yes | 0 for No', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update DB Statistics across all databases]    Script Date: 02/10/2018 16:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update DB Statistics across all databases', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--
/********************************************************************************************************************/
-- Disclaimer...
--
-- This script is provided for open use by Haden Kingsland (theflyingDBA) and as such is provided as is, with
-- no warranties or guarantees. 
-- The author takes no responsibility for the use of this script within environments that are outside of his direct 
-- control and advises that the use of this script be fully tested and ratified within a non-production environment 
-- prior to being pushed into production. 
-- This script may be freely used and distributed in line with these terms and used for commercial purposes, but 
-- not for financial gain by anyone other than the original author.
-- All intellectual property rights remain solely with the original author.
--
/********************************************************************************************************************/
--

DECLARE @SQL VARCHAR(1000), @DB SYSNAME, @database_name VARCHAR(30)= NULL;
SET @database_name = NULL; -- NULL -- or a valid database name to explicitly run on single database, in the format of ''Ola''

IF @database_name IS NULL
    BEGIN
        DECLARE database_cursor CURSOR FORWARD_ONLY STATIC
        FOR SELECT [name]
            FROM master.sys.databases
            WHERE database_id NOT IN(1, 2, 3, 4) -- ignore system databases as they are so small, not really worth doing
            AND ([name] NOT LIKE ''%ReportS%'' -- ignore reportserver databases
                 AND name NOT LIKE ''%distribution%'') -- ignore the distribution database, as this is handled by itself
            AND is_read_only != 1 -- database is NOT READ ONLY
            AND state = 0 -- online databases only!
            ORDER BY [name];
        OPEN database_cursor;
        FETCH NEXT FROM database_cursor INTO @DB;
        WHILE @@FETCH_STATUS = 0
            BEGIN
                SELECT @SQL = ''USE [''+@DB+'']''+CHAR(13)+''EXEC sp_updatestats''+CHAR(13);
                PRINT @SQL;
                EXEC (@sql);
                FETCH NEXT FROM database_cursor INTO @DB;
            END;
        CLOSE database_cursor;
        DEALLOCATE database_cursor;
    END;
    ELSE
IF @database_name IS NOT NULL
    BEGIN
        SET @SQL = ''USE [''+@database_name+'']''+CHAR(13)+''EXEC sp_updatestats''+CHAR(13);
        PRINT @SQL;
        EXEC (@sql);
    END;', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Adhoc Schedule for Defrag', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=193000, 
		@active_end_time=235959, 
		@schedule_uid=N'd83138bb-d438-4702-bbcc-d314766ac364'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Defrag all indexes schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180924, 
		@active_end_date=99991231, 
		@active_start_time=190000, 
		@active_end_time=235959, 
		@schedule_uid=N'f374a5fb-527f-4dac-a27c-d2fb69ec1250'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Delete Expired Table Backups]    Script Date: 02/10/2018 16:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Delete Expired Table Backups', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Expired Table Backups step]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Expired Table Backups step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.usp_delete_expired_table_backups', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Delete expired table backups schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'7d7352e3-a41c-4655-b98a-68d8bd8cf2eb'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - get cpu stats for server]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - get cpu stats for server', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [get cpu stats]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'get cpu stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @CPU_BUSY int, @IDLE int
SELECT @CPU_BUSY = @@CPU_BUSY, 
@IDLE = @@IDLE WAITFOR DELAY ''000:00:30''

insert into dbadmin.dba.cpu (cpu, stattime) 
SELECT (@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) *1.00) *100, GETDATE()', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'get cpu stats', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'c7bc1c7d-1b33-4621-b283-b3655f53982a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - get server memory use]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - get server memory use', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'CREATE TABLE #tmp
 ( row_id INT IDENTITY PRIMARY KEY,
 name VARCHAR(100),
 VALUE BIGINT );
 
INSERT INTO #tmp EXEC ( ''DBCC memorystatus'' );
 
-- Populate the temporary table
insert into dba.Server_Memory_Status
(logdate,total_server_mem,
free_server_mem_percent,
avail_server_mem,
used_server_mem,
server_mem_state,
current_SQL_workingset_mem)
SELECT convert(varchar(17),GETDATE(),113) as ''Metric Date'', 
total_physical_memory_kb/1024/1024 as "Total Server Memory GB",
       convert(decimal(10,', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get Server Memory Status]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Server Memory Status', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
CREATE TABLE #tmp
 ( row_id INT IDENTITY PRIMARY KEY,
 name VARCHAR(100),
 VALUE BIGINT );
 
INSERT INTO #tmp EXEC ( ''DBCC memorystatus'' );
 
-- Populate the temporary table
insert into dba.Server_Memory_Status
(logdate,total_server_mem_GB,
free_server_mem_percent,
avail_server_mem_GB,
used_server_mem_GB,
server_mem_state,
current_SQL_workingset_mem_GB)
SELECT convert(varchar(17),GETDATE(),113) as ''Metric Date'', 
total_physical_memory_kb/1024/1024 as "Total Server Memory GB",
       convert(decimal(10,2),available_physical_memory_kb/(total_physical_memory_kb*1.0)*100) AS "% Memory Free",
       available_physical_memory_kb/1024/1024 as ''Available Server Memory GB'',
       (total_physical_memory_kb - available_physical_memory_kb)/1024/1024 as ''Used Memory in GB'',
       system_memory_state_desc,
       -- insert the currently allocated working set memory for SQL Server
       (SELECT TOP 1 VALUE / 1024/1024/1024 ''GB Used'' FROM #tmp WHERE Rtrim(Ltrim(name)) = ''Working Set'')
FROM sys.dm_os_sys_memory

DROP TABLE #tmp;
', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Get Job History', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'5b3e7898-6945-4dcd-aa6e-f1e1631d7a3c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - get top 50 queries]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - get top 50 queries', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [get cpu stats]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'get cpu stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'insert into dba.query(querytext,dbname,obj,creationtime,elapsedtime,reads,writes) 
SELECT TOP 50
convert(varchar(2000),SUBSTRING(qt.text,qs.statement_start_offset/2, 
                (case when qs.statement_end_offset = -1 
                        then len(convert(nvarchar(max), qt.text)) * 2 
                        else qs.statement_end_offset 
                        end - qs.statement_start_offset)/2)) as query_text,        
dbname=db_name(qt.dbid),
        OBJECT_NAME(qt.objectid) as "Object Name",
        --qs.sql_handle,
        --qs.plan_handle,
        qs.creation_time,
        CONVERT(decimal(28,10),qs.total_elapsed_time)/CONVERT(decimal(28,10),qs.execution_count)/1000000 as "Query Elapsed Time (secs)",
		qs.total_logical_reads as reads,
		qs.total_logical_writes as writes
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
where db_name(qt.dbid) not in (''master'',''msdb'',''model'',''tempdb'')', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'get top 50 queries', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=180000, 
		@schedule_uid=N'22ef0eb7-98a4-43a2-829d-783e7398be71'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Log General IO Baseline]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Log General IO Baseline', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To log the general IO baseline pattern of a given instance', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [To log baseline IO patterns Agent Job]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'To log baseline IO patterns Agent Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [dba].[usp_dba_io_vf_stats_snap]', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'To log baseline IO patterns Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'37aa8b7c-4b80-47a7-9c35-d3fc034f67b2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Log IO Latency history]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Log IO Latency history', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To log the IO latency hourly in order to paint an historical picture of such for issue resolution', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [To log IO latency historically step 1]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'To log IO latency historically step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.usp_dba_capture_file_latency', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'To log historical IO latency Agent job', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'0ee6fd00-7956-4205-8a1d-67b268c6ddaa'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Log Missing Indexes Daily (all databases)]    Script Date: 02/10/2018 16:20:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Log Missing Indexes Daily (all databases)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Admin job to log all missing indexes in all databases daily and maintain a history of such, with creation statements, for the DBA team to apply if required.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Maintain rolling window of missing indexes]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Maintain rolling window of missing indexes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- only keep a rolling 15 days worth of history for all missing indexes
declare @delete_period int
set @delete_period = 15

delete from [DBAdmin].[dba].[MissingIndexes_history] where recorded_date < getdate()- @delete_period', 
		@database_name=N'master', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check all database for missing indexes]    Script Date: 02/10/2018 16:20:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check all database for missing indexes', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec master.sys.sp_MSforeachdb
''  use [?];
INSERT into [DBAdmin].[dba].[MissingIndexes_history]
SELECT top 5
	@@servername,
	getdate(),
	db_name(mid.database_id) as [dbname],
	Object_name(mid.[object_id]),
	Cast(((migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans)))as INT) AS [improvement_measure],
	''''CREATE INDEX [IDX_'''' + CONVERT (varchar, mig.index_group_handle) + ''''_'''' + CONVERT (varchar, mid.index_handle) 
  + ''''_'''' + LEFT (PARSENAME(mid.statement, 1), 32) + '''']''''
  + '''' ON '''' + mid.statement 
  + '''' ('''' + ISNULL (mid.equality_columns,'''''''') 
    + CASE WHEN mid.equality_columns IS NOT NULL 
    AND mid.inequality_columns IS NOT NULL 
    THEN '''','''' ELSE '''''''' END 
    + ISNULL (mid.inequality_columns, '''''''')
  + '''')'''' 
  + ISNULL ('''' INCLUDE ('''' + mid.included_columns + '''')'''', '''''''') 
  + '''' WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, 
IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, 
ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85
)''''
AS create_index_statement,
	migs.*, 
	mid.database_id
FROM sys.dm_db_missing_index_groups mig
	INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE 1=1
	--and migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 40000 --uncomment to filter by improvement measure
	--and migs.user_seeks > 250									-- change this for activity level of the index, leave commented out to get back everything
	and mid.database_id > 4										--Skip system databases
	and db_name(mid.database_id) = ''''?''''						--Get top 5 for only the current database
ORDER BY 
	migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC
''', 
		@database_name=N'master', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Check and Log missing indexes schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959, 
		@schedule_uid=N'0ef2a5af-c48a-4345-be12-6e0a1d181e1b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Monitor Database Table Size]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Monitor Database Table Size', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_find_tablegrowth', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Monitor Database Table Growth]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Database Table Growth', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.dba_find_tablegrowth', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monitor Database Table Size', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=74500, 
		@active_end_time=235959, 
		@schedule_uid=N'1b5f28eb-2f5a-4fa6-946c-247e38f766b8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Monitor Failed SQL Agent Jobs]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Monitor Failed SQL Agent Jobs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_failed_sql_agent_jobs_daily ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Monitor Failed SQL Agent Jobs]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Failed SQL Agent Jobs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_failed_sql_agent_jobs_daily ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monitor Failed SQL Agent Jobs', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=233000, 
		@active_end_time=235959, 
		@schedule_uid=N'6962bf87-5ef6-42a2-aeb9-a1422794c8da'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Monitor Memory Use Per Database]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Monitor Memory Use Per Database', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
   FROM sys.dm_os_performance_counters 
   WHERE RTRIM([object_name]) LIKE ''%Buffer Manager''
   AND counter_name = ''Total Pages'';
WITH src AS
(
   SELECT 
       database_id, db_buffer_pages = COUNT_BIG(*)
       FROM sys.dm_os_buffer_descriptors
       --WHERE database_id BETWEEN 5 AND 32766
       GROUP BY database_id
)

INSERT INTO dbadmin.dba.db_buffer_usage
([db_name], [buffer_pages], [buffer_MB], 
[buffer_percent], [date_st', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Monitor Buffer Cache Use by Database]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Buffer Cache Use by Database', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
   FROM sys.dm_os_performance_counters 
   WHERE RTRIM([object_name]) LIKE ''%Buffer Manager''
   AND counter_name = ''Total Pages'';
WITH src AS
(
   SELECT 
       database_id, db_buffer_pages = COUNT_BIG(*)
       FROM sys.dm_os_buffer_descriptors
       --WHERE database_id BETWEEN 5 AND 32766
       GROUP BY database_id
)

INSERT INTO dbadmin.dba.db_buffer_usage
([db_name], [buffer_pages], [buffer_MB], 
[buffer_percent], [date_stamp])
SELECT
   [db_name] = CASE [database_id] WHEN 32767 
       THEN ''Resource DB'' 
       ELSE DB_NAME([database_id]) END,
   db_buffer_pages,
   db_buffer_MB = db_buffer_pages / 128,
   db_buffer_percent = CONVERT(DECIMAL(6,3), 
   db_buffer_pages * 100.0 / @total_buffer),
   getdate()
FROM src
ORDER BY db_buffer_MB DESC;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monitor Buffer Cache Use by Database Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'12e79ec6-346f-4788-8d63-6da79dceaf97'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - No Differential backup within 2 days]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - No Differential backup within 2 days', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_no_diff_backup_within_2_days_report ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [No Differential backup within 2 days]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'No Differential backup within 2 days', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_no_diff_backup_within_2_days_report ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'No Differential backup within 2 days', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'd1de394b-ca1e-4fdc-bdfa-606b50765dcf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - No FULL backup EVER!]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - No FULL backup EVER!', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_no_full_backup_report ''haden.kingsland@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [No FULL backup EVER!]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'No FULL backup EVER!', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_no_full_backup_report ''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'No FULL backup EVER!', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'1971bb7e-9664-4c2c-8888-2fad0c500ac4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - No FULL backup within 8 days]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - No FULL backup within 8 days', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_no_full_backup_within_8_days_report ''haden.kingsland@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [No FULL backup within 8 days]    Script Date: 02/10/2018 16:20:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'No FULL backup within 8 days', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_no_full_backup_within_8_days_report ''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'No FULL backup within 8 days', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'ee859781-9e97-4b13-91e6-d894703cd93e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - No TX Log backup within 90 minutes]    Script Date: 02/10/2018 16:20:29 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - No TX Log backup within 90 minutes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_no_tx_backup_within_90_mins_report ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [No TX Log backup within 90 minutes]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'No TX Log backup within 90 minutes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_no_tx_backup_within_90_mins_report ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'No TX Log backup within 90 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=1, 
		@active_end_time=235959, 
		@schedule_uid=N'ba7bed9b-7be1-4022-a13a-20ef8bdf57a1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Purge Database Mail Items]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Purge Database Mail Items', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To purge all database mail items from within MSDB and keep 60 days worth', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge Database Mail]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Database Mail', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @oldest datetime 
set @oldest=getdate()-60
exec msdb.dbo.sysmail_delete_mailitems_sp  @sent_before=@oldest
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Purge DB Mail Items', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=17, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'2fac2287-278e-4e4b-9d72-d846cc45cf47'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Purge Database Mail Log Items]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Purge Database Mail Log Items', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Purge all MSDB database mail log items to keep 90 days worth of history', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge Database Mail Logs]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Database Mail Logs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @oldest datetime 
set @oldest=getdate()-90
EXECUTE msdb.dbo.sysmail_delete_log_sp @logged_before = @oldest
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Purge DB Mail Items', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=113500, 
		@active_end_time=235959, 
		@schedule_uid=N'e1f66023-213d-4f58-acc6-cfd53bea703f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Purge Job Step Logs]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Purge Job Step Logs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'delete from msdb..sysjobstepslogs where date_created < GETDATE()-8
', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge Job Step Log Step1]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Job Step Log Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'delete from msdb..sysjobstepslogs where date_created < GETDATE()-8
', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Purge Job Step Log Schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=103000, 
		@active_end_time=235959, 
		@schedule_uid=N'e9e6a415-3fc8-4884-8bf9-11d0faf8b9b4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Purge MSDB Agent Job History]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Purge MSDB Agent Job History', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Purge the MSDB Agent Job History once / week on a Sunday to keep 60 days worth of history', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge MSDB Agent Job History]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge MSDB Agent Job History', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*Only Keep 14 days worth, as we are now alerted for failed jobs.*/
declare @oldest datetime 
set @oldest=getdate()-14
print @oldest
exec sp_purge_jobhistory @oldest_date=@oldest', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Purge MSDB Agent Job History', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'65e91295-321e-4ceb-a153-fc2fc439e6a4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Purge MSDB Backup History]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Purge MSDB Backup History', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Purge MSDB Backup History on the 2nd day of each month to keep 35 days wortjh of history', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Purge MSDB Backup History]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge MSDB Backup History', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/* Keep 35 days worth */
declare @oldest datetime 
set @oldest=getdate()-35
print @oldest
exec sp_delete_backuphistory @oldest', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Purge MSDB Backup History', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=71500, 
		@active_end_time=235959, 
		@schedule_uid=N'ed6ca2a2-dc30-4da0-a309-7e033d1650c2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Report on Database Growth Daily]    Script Date: 02/10/2018 16:20:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Report on Database Growth Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.dba_disk_growth_report 3, ''haden.kingsland@cii.co.uk''', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Report on Database Growth Daily]    Script Date: 02/10/2018 16:20:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Report on Database Growth Daily', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_disk_growth_report 3, ''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Report on Database growth daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=60500, 
		@active_end_time=235959, 
		@schedule_uid=N'dc19edae-9278-4a35-831d-b3dba2ba52f2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Report on Database Table Growth Daily]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Report on Database Table Growth Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Report on database table growth step 1]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Report on database table growth step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.db_table_growth_report 2,1, ''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Report on database table growth schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180919, 
		@active_end_date=99991231, 
		@active_start_time=90500, 
		@active_end_time=235959, 
		@schedule_uid=N'e50d3900-a09d-4b80-bb0c-0005caee0bba'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Report on failed Agent Jobs Daily]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Report on failed Agent Jobs Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run the failed agent jobs report]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run the failed agent jobs report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dbadmin.dba.dba_failed_sql_agent_jobs_daily ''haden.kingsland@cii.co.uk;dean.bacon@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Failed SQL Agent jobs daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959, 
		@schedule_uid=N'f6888b7d-71fd-4c2d-9c05-2da32358f41c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Report on Long Running SQL Agent Jobs]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Report on Long Running SQL Agent Jobs', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbo.usp_LongRunningJobs', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Report on Long Running SQL Agent Jobs]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Report on Long Running SQL Agent Jobs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute as login = ''sa'';

exec dba.usp_LongRunningJobs ''haden.kingsland@cii.co.uk'';

revert;', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Report on Long Running SQL Agent Jobs', 
		@enabled=0, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=24, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=51500, 
		@active_end_time=235959, 
		@schedule_uid=N'284670d7-20c9-4864-8e0a-03985d630c2a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - SQLServer Agent Restarted]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - SQLServer Agent Restarted', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To show sql and physical server details upon instance restart
so that we have visibility of unexpected issues with servers and
services.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [To report all system statuses and send email upon agent restart]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'To report all system statuses and send email upon agent restart', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [dba].[usp_quick_check_SQL_services]', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Report on server status upon system and agent restart', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'7c7fab0e-8e25-46b4-b84a-932ec2694314'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Track Database & TX Log Growth Individually Daily]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Track Database & TX Log Growth Individually Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'--########################################################################################################
--PART 2
--Below is the code run weekly to check the growth.
--

-- Check Data File sizes
Select sd.name as DBName, 
mf.name as FileName, 
mf.database_id, 
file_id, 
size
into #TempDBSizeDATA2
from sys.databases sd
join sys.master_files mf
on sd.database_ID = mf.database_ID
where type_desc != ''LOG''
order by mf.database_id, sd.name

-- Check TX Log sizes
Select sd.name as DBName, 
mf', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Track Database and TX Log Growth Individually]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Track Database and TX Log Growth Individually', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--########################################################################################################
--PART 2
--Below is the code run weekly to check the growth.
--

-- Check Data File sizes
Select sd.name as DBName, 
mf.name as FileName, 
mf.database_id, 
file_id, 
size
into #TempDBSizeDATA2
from sys.databases sd
join sys.master_files mf
on sd.database_ID = mf.database_ID
where type_desc != ''LOG''
order by mf.database_id, sd.name

-- Check TX Log sizes
Select sd.name as DBName, 
mf.name as FileName, 
mf.database_id, 
file_id, 
size
into #TempDBSizeTXLOG2
from sys.databases sd
join sys.master_files mf
on sd.database_ID = mf.database_ID
where type_desc = ''LOG''
order by mf.database_id, sd.name

-- Data Files
-- ##########
-- check if database details already exist in dbadmin.dbo.DBGrowthRate_Data table

If Exists (Select Distinct DBName from #TempDBSizeDATA2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate_Data))
	and GetDate() > 
(Select Distinct Max(MetricDate) as MetricDate 
from dbadmin.dbo.DBGrowthRate_Data)

  Begin
		Insert into dbadmin.dbo.DBGrowthRate_Data (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
		(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
		dgr.CurSize as OrigSize,
		Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
		Convert(varchar(100),(Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) 
					- dgr.CurSize)) + '' MB'' as GrowthAmt, GetDate() as MetricDate
		from #TempDBSizeDATA2 tds
		join dbadmin.dbo.DBGrowthRate_Data dgr
		on tds.database_ID = dgr.DBID
		Where DBGrowthID = (Select Distinct Max(DBGrowthID) from dbadmin.dbo.DBGrowthRate_Data
		where DBID = dgr.DBID)
		Group by tds.database_ID, tds.DBName, dgr.CurSize)
  End

 Else
   IF Not Exists (Select Distinct DBName from #TempDBSizeDATA2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate_Data))
		Begin
			Insert into dbadmin.dbo.DBGrowthRate_Data (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
			(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as OrigSize,
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
			''0.00 MB'' as GrowthAmt, GetDate() as MetricDate
			from #TempDBSizeDATA2 tds
			where tds.database_ID not in (Select Distinct DBID from dbadmin.dbo.DBGrowthRate_Data 
			where db_id(DBName) = tds.database_ID)
			Group by tds.database_ID, tds.DBName)
		End


-- ##################################################################################################

-- TX Logs
-- #######
-- check if database details already exist in dbadmin.dbo.DBGrowthRate_Data table

If Exists (Select Distinct DBName from #TempDBSizeTXLOG2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate_TXLog))
	and GetDate() > 
(Select Distinct Max(MetricDate) as MetricDate 
from dbadmin.dbo.DBGrowthRate_TXLog)

  Begin
		Insert into dbadmin.dbo.DBGrowthRate_TXLog (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
		(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
		dgr.CurSize as OrigSize,
		Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
		Convert(varchar(100),(Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) 
					- dgr.CurSize)) + '' MB'' as GrowthAmt, GetDate() as MetricDate
		from #TempDBSizeTXLOG2 tds
		join dbadmin.dbo.DBGrowthRate_TXLog dgr
		on tds.database_ID = dgr.DBID
		Where DBGrowthID = (Select Distinct Max(DBGrowthID) from dbadmin.dbo.DBGrowthRate_TXlog
		where DBID = dgr.DBID)
		Group by tds.database_ID, tds.DBName, dgr.CurSize)
  End

 Else
   IF Not Exists (Select Distinct DBName from #TempDBSizeTXLOG2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate_TXlog))
		Begin
			Insert into dbadmin.dbo.DBGrowthRate_TXlog (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
			(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as OrigSize,
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
			''0.00 MB'' as GrowthAmt, GetDate() as MetricDate
			from #TempDBSizeTXLOG2 tds
			where tds.database_ID not in (Select Distinct DBID from dbadmin.dbo.DBGrowthRate_TXlog
			where db_id(DBName) = tds.database_ID)
			Group by tds.database_ID, tds.DBName)
		End

Drop table #TempDBSizeDATA2
Drop table #TempDBSizeTXLOG2', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Track Database & TX Log Growth', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=53000, 
		@active_end_time=235959, 
		@schedule_uid=N'60f57af4-2a24-4f89-a390-5bf30b9302b1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Track Database Growth Daily]    Script Date: 02/10/2018 16:20:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 02/10/2018 16:20:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Track Database Growth Daily', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'To track Database growth rates every day and log to a table in the DBAdmin database', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run growth steps]    Script Date: 02/10/2018 16:20:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run growth steps', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Select sd.name as DBName, 
mf.name as FileName, 
mf.database_id, 
file_id, 
size
into #TempDBSize2
from sys.databases sd
join sys.master_files mf
on sd.database_ID = mf.database_ID
order by mf.database_id, sd.name

-- check if database details already exist in dbadmin.dbo.DBGrowthRate table

--If Exists (Select Distinct DBName from #TempDBSize2 
--				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate))
--	and Convert(varchar(10),GetDate(),101) > 
--(Select Distinct Convert(varchar(10),Max(MetricDate),101) as MetricDate 
--from dbadmin.dbo.DBGrowthRate)

-- 01/02/2012 -- HJK
-- Changed to allow correct date comparison, as was failing after we moved to 2012!

If Exists (Select Distinct DBName from #TempDBSize2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate))
	and GetDate() > 
(Select Distinct Max(MetricDate) as MetricDate 
from dbadmin.dbo.DBGrowthRate)

  Begin
		Insert into dbadmin.dbo.DBGrowthRate (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
		(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
		dgr.CurSize as OrigSize,
		Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
		Convert(varchar(100),(Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) 
					- dgr.CurSize)) + '' MB'' as GrowthAmt, GetDate() as MetricDate
		from #TempDBSize2 tds
		join dbadmin.dbo.DBGrowthRate dgr
		on tds.database_ID = dgr.DBID
		Where DBGrowthID = (Select Distinct Max(DBGrowthID) from dbadmin.dbo.DBGrowthRate
		where DBID = dgr.DBID)
		Group by tds.database_ID, tds.DBName, dgr.CurSize)
  End

 Else
   IF Not Exists (Select Distinct DBName from #TempDBSize2 
				where DBName in (Select Distinct DBName from dbadmin.dbo.DBGrowthRate))
		Begin
			Insert into dbadmin.dbo.DBGrowthRate (DBName, DBID, NumPages, OrigSize, CurSize, GrowthAmt, MetricDate)
			(Select tds.DBName, tds.database_ID, Sum(tds.Size) as NumPages, 
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as OrigSize,
			Convert(decimal(10,2),(((Sum(Convert(decimal(10,2),tds.Size)) * 8000)/1024)/1024)) as CurSize,
			''0.00 MB'' as GrowthAmt, GetDate() as MetricDate
			from #TempDBSize2 tds
			where tds.database_ID not in (Select Distinct DBID from dbadmin.dbo.DBGrowthRate 
			where db_id(DBName) = tds.database_ID)
			Group by tds.database_ID, tds.DBName)
		End

Drop table #TempDBSize2
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'growth proc schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=51500, 
		@active_end_time=235959, 
		@schedule_uid=N'10a5f51b-0a77-4517-bd1d-e8a8d386532f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Transaction Log Virtual Log File (VLF) Check]    Script Date: 02/10/2018 16:20:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Transaction Log Virtual Log File (VLF) Check', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'exec dbadmin.dba.usp_VLF_TXLOG_Check', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [VLF Check for all databases]    Script Date: 02/10/2018 16:20:32 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'VLF Check for all databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute as login = ''sa'';

exec dba.usp_VLF_TXLOG_Check ''haden.kingsland@cii.co.uk'';

revert;', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'VLF Check for all databases schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180918, 
		@active_end_date=99991231, 
		@active_start_time=71500, 
		@active_end_time=235959, 
		@schedule_uid=N'09e68a9a-4493-4902-8861-33a23d7c5f53'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [DBA - Weekly Instance Report]    Script Date: 02/10/2018 16:20:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/10/2018 16:20:32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Weekly Instance Report', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA-Alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Weekly instance report job step 1]    Script Date: 02/10/2018 16:20:32 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Weekly instance report job step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec dba.usp_SQL_Server_System_Report ''E'',7,''haden.kingsland@cii.co.uk''', 
		@database_name=N'DBAdmin', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly full instance report schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180930, 
		@active_end_date=99991231, 
		@active_start_time=64500, 
		@active_end_time=235959, 
		@schedule_uid=N'c28fc082-783e-44d5-befa-deabdddb1361'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly full instance report schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180930, 
		@active_end_date=99991231, 
		@active_start_time=64500, 
		@active_end_time=235959, 
		@schedule_uid=N'5a3eda29-74f7-4d27-9189-18db5e628ccc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



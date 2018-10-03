USE [msdb]
GO

/****** Object:  Job [All database daily FULL backup]    Script Date: 10/09/2018 09:00:04 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 10/09/2018 09:00:04 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'All database daily FULL backup', 
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
/****** Object:  Step [All database daily FULL backup SQL Agent step]    Script Date: 10/09/2018 09:00:04 ******/
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
declare  			@production varchar(1)
declare 			@INCSIMPLE	varchar(1) 
declare 			@ignoredb varchar(1)
declare 			@checksum varchar(1)
declare 			@isSP varchar(1)
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
 
select 			@job_name = ''Database Backups''
select 			@backup_location = ''E:\SQLBAK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
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
select			@deletion_param = 8 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Backup all database schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180906, 
		@active_end_date=99991231, 
		@active_start_time=180000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [All database transaction log backups]    Script Date: 10/09/2018 09:00:04 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 10/09/2018 09:00:04 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'All database transaction log backups', 
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
/****** Object:  Step [Transaction log backups]    Script Date: 10/09/2018 09:00:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Transaction log backups', 
		@step_id=1, 
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

declare			@RC int
declare	 		@job_name varchar(128)
declare			@BACKUP_LOCATION varchar(200)
declare			@backup_type VARCHAR(1)
declare			@dbname nvarchar(2000)
declare			@iscloud varchar(1)
declare			@copy varchar(1)
declare			@freq varchar(10)
declare  			@production varchar(1)
declare 			@INCSIMPLE	varchar(1) 
declare 			@ignoredb varchar(1)
declare 			@checksum varchar(1)
declare 			@isSP varchar(1)
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
 
select 			@job_name = ''Database Backups''
select 			@backup_location = ''E:\SQLBAK\'' --''\\darfas01\cifs_sqlbak_sata11$\DAREPMSQL01\EPM_LIVE\SQLTRN\'' --
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
select			@deletion_param = 2 -- can be any integer to allow deletion (i.e -- number of weeks or days back to delete backups) -- Default is 1
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Transaction Log Backups Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180906, 
		@active_end_date=99991231, 
		@active_start_time=1, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



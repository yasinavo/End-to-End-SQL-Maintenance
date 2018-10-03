USE [msdb]
GO


declare      @instance sysname = @@SERVICENAME
declare      @performance_condition nvarchar(200) = 'MSSQL:Locks|Lock Requests/sec|Object|>|5000'
declare		 @notification nvarchar(200) = 'Lock Escalation has occured within... ' + @instance

if     @instance != 'MSSQLSERVER'
       SET @performance_condition = replace(@performance_condition, 'MSSQL', 'MSSQL$' + @instance)

/****** Object:  Alert [Alert of Lock Escalation]    Script Date: 01/20/2017 09:49:24 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Alert of Lock Escalation', 
             @message_id=0, 
             @severity=0, 
             @enabled=1, 
             @delay_between_responses=1800, 
             @include_event_description_in=1, 
			 @notification_message=@notification, 
             @category_name=N'[Uncategorized]', 
             @performance_condition=@performance_condition, 
             @job_id=N'00000000-0000-0000-0000-000000000000'
GO

declare      @instance sysname = @@SERVICENAME
declare      @performance_condition nvarchar(200) = 'MSSQL:Locks|Number of Deadlocks/sec|_Total|>|0'
declare		 @notification nvarchar(200) = 'A deadlock has occured within... ' + @instance

if     @instance != 'MSSQLSERVER'
       SET @performance_condition = replace(@performance_condition, 'MSSQL', 'MSSQL$' + @instance)

/****** Object:  Alert [Deadlock Alert]    Script Date: 01/20/2017 09:49:24 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Deadlock Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=1800, 
		@include_event_description_in=1, 
		@notification_message=@notification, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=@performance_condition, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
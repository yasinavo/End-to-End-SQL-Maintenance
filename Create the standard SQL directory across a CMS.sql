execute master.dbo.xp_create_subdir N'E:\SQLDATA\Data'
execute master.dbo.xp_create_subdir N'E:\SQLLOGS\Logs'

-- for database collector files to be created in...

execute master.dbo.xp_create_subdir N'E:\SQLDataCollector\cache'

-- if required, for SQLExpress instances, create the backup directory to hold the scripts and log files

execute master.dbo.xp_create_subdir N'E:\BackupScripts\Logs'

--exec xp_fixeddrives
use [DBAdmin]
GO
--#############################################################
--
-- Author	: Haden Kingsland
-- Date		: 13/09/2018
-- Version	: 01:00
--
-- Desc		: to carry out morning checks across a single instance or over a CMS
--			  
--	
-- Modification History
-- ====================
--
--
/************************************************************************************************************************************/
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
/*************************************************************************************************************************************/
-- Usage...

use [DBAdmin]
GO

-- failed agent jobs
select 'Failed jobs'
exec [dba].[usp_quick_check_for_failed_agent_jobs]
--
-- last backups
select 'Latest backups'
exec [dba].[usp_quick_check_for_latest_backups]
--
-- which services are up and uptime
select 'Services...'
exec [dba].[usp_quick_check_SQL_services_no_email]
--
-- current users connected
select 'Users connected at a glance'
exec [dba].[usp_quick_check_user_info]
--
-- are my databases online etc?
select 'Database status'
exec [dba].[usp_quick_glance_db_health_status]
--
-- last run times and status of all Agent jobs
select 'Last Agent job times'
exec [dba].[usp_quick_check_job_run_Status]

-- Check available server disk space at a glance
select 'Server Disk Space'
exec [dba].[usp_quick_check_server_disk_space]

-- Show any databases whose data or log files needed to have the max size extended
select 'Databases that needed to grow'
select * from [dba].[dba_max_size_change]

-- Show size of ALL database files with headroom and % used
select '% used of ALL database files'
exec [dba].[usp_quick_check_database_file_usage] -- 'DBAdmin'

-- Show amount of data ACTUALLY used within each database file
select 'Amount of space ACTUALLY used within each database file'
exec [dba].[usp_quick_check_filespace_usage] 'ALL' -- 'DBADmin'

-- Show any out of range backups, so we know that they MAY have not completed and can investigate
select 'Show out of range Transaction Log backups'
exec dba.usp_quick_check_for_missing_backups 2, 'L'

select 'Show out of range Full backups'
exec dba.usp_quick_check_for_missing_backups 1

select 'Show out of range Differential backups'
exec dba.usp_quick_check_for_missing_backups 2, 'I'

select 'Show index usage and stats'
-- to show the stats for all indexes in a given database (used and unused)
exec dba.usp_quick_check_index_stats 'DBAdmin',0	

-- to show the stats for all UNUSED indexes in a given database													
exec dba.usp_quick_check_index_stats 'CRM',1	

-- at a glance SQL Uptime
exec dba.usp_quick_check_SQL_uptime
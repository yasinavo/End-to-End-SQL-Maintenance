--#############################################################
--
-- Author	: Haden Kingsland
-- Date		: 10/09/2018
-- Version	: 01:00
--
-- Desc		: To add an email notification operator to all alerts
--
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

declare @operator sysname   
declare @alert_name varchar(200) 
set @operator = 'DBA-Alerts'    


DECLARE notification_alerts CURSOR FOR

	select name from  msdb.dbo.sysalerts
	where  enabled = 1
	and name like '%error%'
    and has_notification = 0;
		
	OPEN notification_alerts;

	-- Loop through the update_stats cursor.

	FETCH NEXT
	  FROM notification_alerts
	  INTO @alert_name;

	WHILE @@FETCH_STATUS <> -1 -- Stop when the FETCH statement failed or the row is beyond the result set
	BEGIN

		IF @@FETCH_STATUS = 0 -- to ignore -2 status "The row fetched is missing"
		BEGIN

			print @alert_name
			EXEC msdb.dbo.sp_add_notification 
			@alert_name=@alert_name, 
			@operator_name=@operator, 
			@notification_method = 1 ;    -- email

		END

	  FETCH NEXT
	  FROM notification_alerts
	  INTO @alert_name;

	END

	CLOSE notification_alerts;
	DEALLOCATE notification_alerts;
 



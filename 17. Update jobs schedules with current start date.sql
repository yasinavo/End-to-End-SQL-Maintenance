declare @scheduleid int,
		@today date

		select @today = getdate()
		print @today

DECLARE My_Cursor CURSOR

-- only do this for the DBA related jobs!
FOR
select js.schedule_id from
msdb.dbo.sysjobschedules js
inner join msdb.dbo.sysjobs s
on js.job_id = s.job_id 
where s.name like 'DBA - %'

OPEN My_Cursor

FETCH NEXT FROM My_Cursor INTO @scheduleid

WHILE (@@FETCH_STATUS <> -1)

BEGIN

EXEC msdb.dbo.sp_update_schedule @schedule_id=@scheduleid, 
		@active_start_date= 20180918 -- YYYYMMDD

FETCH NEXT FROM My_Cursor INTO @scheduleid
END 

CLOSE My_Cursor

DEALLOCATE My_Cursor
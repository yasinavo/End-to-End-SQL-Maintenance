use msdb;

/* Keep 35 days worth */
declare @oldest datetime 
set @oldest=getdate()-35
print @oldest
exec sp_delete_backuphistory @oldest
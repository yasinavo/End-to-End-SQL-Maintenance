
use [msdb]
go

select a.owner_sid, a.name, b.name from dbo.sysjobs_view a
inner join sys.syslogins b
on a.owner_sid = b.sid
where a.name like '%hkadmin%'

select suser_sname(a.owner_sid), a.name from dbo.sysjobs_view a
where suser_sname(a.owner_sid) ! = 'sa'

select suser_sname(owner_sid), name from sys.databases
where suser_sname(owner_sid) != 'sa'

--USE [bpel75]
--GO
--EXEC dbo.sp_changedbowner @loginame = N'POITS\SQLService', @map = false
--GO

SELECT name, suser_sname(sid), convert(nvarchar(11), crdate),dbid, cmptlevel 
FROM master.dbo.sysdatabases

SELECT 'USE ' + name + '; EXEC sp_changedbowner ''sa'';' 
FROM master.dbo.sysdatabases WHERE suser_sname(sid) like '%hkadmin%' -- IS NULL
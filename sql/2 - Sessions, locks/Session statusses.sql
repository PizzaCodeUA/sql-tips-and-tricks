exec sp_who2
-----------------------------------
select 
	s.session_id
	,[program_name]
	,sq.Text as SqlTest
	,r.command
	,r.wait_type
	,r.wait_resource
	,r.[status] as RequestStatus
	,r.wait_time
	,r.start_time
	,r.total_elapsed_time
	,r.reads
	,r.writes
	,r.logical_reads
	,r.cpu_time
	,r.blocking_session_id
	,r.transaction_id
	,s.[status] as SessionStatus
	,case r.transaction_isolation_level
		when 0 then 'Unspecified'
		when 1 then 'ReadUncomitted'
		when 2 then 'ReadCommitted'
		when 3 then 'Repeatable'
		when 4 then 'Serializable'
		when 5 then 'Snapshot'
	end as transaction_isolation_level
	,pl.query_plan
from sys.dm_exec_sessions s
inner join sys.dm_exec_requests r on s.session_id = r.session_id
cross apply sys.dm_exec_sql_text(r.sql_handle) sq
cross apply sys.dm_exec_query_plan(r.plan_handle) pl
where 
	s.[status] = 'running'
order by
	s.[program_name]

--semaphores
--select * from sys.dm_exec_query_resource_semaphores

--kill X
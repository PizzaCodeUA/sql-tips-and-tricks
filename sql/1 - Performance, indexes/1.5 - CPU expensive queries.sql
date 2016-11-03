--top CPU expensive queries
SELECT TOP 50
	[Avg. MultiCore/CPU time(sec)] = qs.total_worker_time / 1000000 / qs.execution_count
	,[Total MultiCore/CPU time(sec)] = qs.total_worker_time / 1000000
	,[Avg. Elapsed Time(sec)] = qs.total_elapsed_time / 1000000 / qs.execution_count
	,[Total Elapsed Time(sec)] = qs.total_elapsed_time / 1000000
	,qs.execution_count
	,[Avg. I/O] = (total_logical_reads + total_logical_writes) / qs.execution_count
	,[Total I/O] = total_logical_reads + total_logical_writes
	,Query = SUBSTRING(qt.[text], (qs.statement_start_offset / 2) + 1
		,(
			(
				CASE qs.statement_end_offset
					WHEN -1 THEN DATALENGTH(qt.[text])
					ELSE qs.statement_end_offset
				END - qs.statement_start_offset
			) / 2
		) + 1
	)
	,Batch = qt.[text]
	,[DB] = DB_NAME(qt.[dbid])
	,qs.last_execution_time
	,qp.query_plan
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
where 
	qs.execution_count > 5	--more than 5 occurences
ORDER BY 
	[Total MultiCore/CPU time(sec)] DESC
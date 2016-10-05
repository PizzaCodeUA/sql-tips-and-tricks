/*
cached plans

Using Plan Guides and Plan Freezing
https://blogs.msdn.microsoft.com/turgays/2013/02/28/using-plan-guides-and-plan-freezing-2/
*/

--list of plans in cache
SELECT 
	 [cp].[refcounts]
	,[cp].[usecounts]
	,[cp].[objtype]
	,[st].[dbid]
	,[st].[objectid]
	,[st].[text]
	, [qp].[query_plan] 
FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text ( cp.plan_handle ) st 
CROSS APPLY sys.dm_exec_query_plan ( cp.plan_handle ) qp ;


--performance statistics for cached plans
select
*
FROM sys.dm_exec_query_stats qs
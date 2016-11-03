/*
	http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/01/19/tuning-cost-threshold-of-parallelism-from-the-plan-cache.aspx
	from cashe show all parallel queries
		* query execution plan
		* cost
*/
------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

WITH XMLNAMESPACES   
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
SELECT
	query_plan AS CompleteQueryPlan
	,n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText
	,n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel
	,cast(n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') as float)AS StatementSubTreeCost
	,n.query('.') AS ParallelSubTreeXML
	,cast(ecp.usecounts as int) UseCounts
	,cast(ecp.size_in_bytes as int) as size_in_bytes
INTO #tmp_res
FROM sys.dm_exec_cached_plans AS ecp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
WHERE  
	n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1
-----------------------------------
SELECT
	StatementText
	,StatementSubTreeCost
	,usecounts
	,size_in_bytes 
	--,CompleteQueryPlan
	--,ParallelSubTreeXML
	--,StatementOptimizationLevel
FROM #tmp_res
order by
	StatementSubTreeCost desc
	--StatementText
--drop table #tmp_res
------------------------------------------
--12.51
select
	count(*)
	,avg(StatementSubTreeCost) as AvgCost
	,min(StatementSubTreeCost) as MinCost
	,max(StatementSubTreeCost) as MaxCost
from #tmp_res
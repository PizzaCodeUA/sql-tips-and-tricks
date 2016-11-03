/*
/*
sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

sp_configure 'cost threshold for parallelism'
GO
----------------------------------
sp_configure 'cost threshold for parallelism', 10;
GO
reconfigure;
GO
*/

*/
CREATE TABLE #SubtreeCost(StatementSubtreeCost DECIMAL(18,2));
 
;WITH XMLNAMESPACES
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
INSERT INTO #SubtreeCost
SELECT
    CAST(n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS DECIMAL(18,2))
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1;
 
SELECT StatementSubtreeCost
FROM #SubtreeCost
ORDER BY 1;
 
SELECT AVG(StatementSubtreeCost) AS AverageSubtreeCost
FROM #SubtreeCost;
 
SELECT
    ((SELECT TOP 1 StatementSubtreeCost
    FROM
        (
        SELECT TOP 50 PERCENT StatementSubtreeCost
        FROM #SubtreeCost
        ORDER BY StatementSubtreeCost ASC
        ) AS A
    ORDER BY StatementSubtreeCost DESC
    )
    +
    (SELECT TOP 1 StatementSubtreeCost
    FROM
        (
        SELECT TOP 50 PERCENT StatementSubtreeCost
        FROM #SubtreeCost
        ORDER BY StatementSubtreeCost DESC
        ) AS A
    ORDER BY StatementSubtreeCost ASC))
    /2 AS MEDIAN;
 
SELECT TOP 1 StatementSubtreeCost AS MODE
FROM   #SubtreeCost
GROUP  BY StatementSubtreeCost
ORDER  BY COUNT(1) DESC;
 
DROP TABLE #SubtreeCost;
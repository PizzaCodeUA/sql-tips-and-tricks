/*
	https://msdn.microsoft.com/ru-ru/library/ms179984(v=sql.120).aspx
*/
WITH [Waits]
AS 
(
	SELECT 
		[wait_type]
		,[wait_time_ms] / 1000.0 AS [WaitS]
		,([wait_time_ms] - [signal_wait_time_ms] ) / 1000.0 AS [ResourceS]
		,[signal_wait_time_ms] / 1000.0 AS [SignalS]
		,[waiting_tasks_count] AS [WaitCount]
		,100.0 * [wait_time_ms] / SUM( [wait_time_ms] ) OVER ( ) AS [Percentage]
		,ROW_NUMBER ( ) OVER ( ORDER BY [wait_time_ms] DESC) AS [RowNum]
	FROM sys.dm_os_wait_stats
	WHERE 
		[wait_type] NOT IN ( N'BROKER_EVENTHANDLER',N'BROKER_RECEIVE_WAITFOR',N'BROKER_TASK_STOP',N'BROKER_TO_FLUSH',N'BROKER_TRANSMITTER',N'CHECKPOINT_QUEUE', N'CHKPT',N'CLR_AUTO_EVENT',N'CLR_MANUAL_EVENT')
)
SELECT 
	[W1].[wait_type] AS [WaitType]
	,CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S]
	,CAST ([W1].[ResourceS] AS DECIMAL(14, 2)) AS [Resource_S]
	,CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S] 
	,[W1].[WaitCount] AS [WaitCount]
	,CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage]
	,CAST (( [W1].[WaitS] / [W1].[WaitCount] ) AS DECIMAL(14, 4)) AS [AvgWait_S]
	,CAST (( [W1].[ResourceS] / [W1].[WaitCount] ) AS DECIMAL(14, 4)) AS [AvgRes_S]
	,CAST (( [W1].[SignalS] / [W1].[WaitCount] ) AS DECIMAL(14, 4)) AS [AvgSig_S]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY 
	[W1].[RowNum] ,
	[W1].[wait_type] ,
	[W1].[WaitS] ,
	[W1].[ResourceS] ,
	[W1].[SignalS] ,
	[W1].[WaitCount] ,
	[W1].[Percentage]
HAVING 
	SUM([W2].[Percentage]) - [W1].[Percentage] < 95;
GO

/*
Common wait types
CXPACKET
Often indicates nothing more than that certain queries are executing with parallelism;
CXPACKET waits in the server are not an immediate sign of problems, although they
may be the symptom of another problem, associated with one of the other high value
wait types on the instance.
• SOS_SCHEDULER_YIELD
The tasks executing in the system are yielding the scheduler, having exceeded their
quantum, and are having to wait in the runnable queue for other tasks to execute. As
discussed earlier, this wait type is most often associated with high signal wait rather
than waits on a specific resource. If you observe this wait type persistently, investigate
for other evidence that may confirm the server is under CPU pressure.
• THREADPOOL
A task had to wait to have a worker thread bound to it, in order to execute. This could
be a sign of worker thread starvation, requiring an increase in the number of CPUs
in the server, to handle a highly concurrent workload, or it can be a sign of blocking,
resulting in a large number of parallel tasks consuming the worker threads for long
periods.
• LCK_*
These wait types signify that blocking is occurring in the system and that sessions
have had to wait to acquire a lock, of a specific type, which was being held by another
database session.

PAGEIOLATCH_*, IO_COMPLETION, WRITELOG
These waits are commonly associated with disk I/O bottlenecks, though the root cause
of the problem may be, and commonly is, a poorly performing query that is consuming
excessive amounts of memory in the server, or simply insufficient memory for the buffer
pool.

PAGELATCH_*
Non-IO waits for latches on data pages in the buffer pool. A lot of times PAGELATCH_*
waits are associated with allocation contention issues. One of the most well-known
allocations issues associated with PAGELATCH_* waits occurs in tempdb when the a
large number of objects are being created and destroyed in tempdb and the system
experiences contention on the Shared Global Allocation Map (SGAM), Global Allocation
Map (GAM), and Page Free Space (PFS) pages in the tempdb database.
• LATCH_*
These waits are associated with lightweight short-term synchronization objects that are
used to protect access to internal caches, but not the buffer cache. These waits can
indicate a range of problems, depending on the latch type. Determining the specific
latch class that has the most accumulated wait time associated with it can be found by
querying the sys.dm_os_latch_stats DMV.
• ASYNC_NETWORK_IO
This wait is often incorrectly attributed to a network bottleneck. In fact, the most
common cause of this wait is a client application that is performing row-by-row
processing of the data being streamed from SQL Server as a result set (client accepts
one row, processes, accepts next row, and so on). Correcting this wait type generally
requires changing the client side code so that it reads the result set as fast as possible,
and then performs processing.


Occurs when a thread makes a call to structure that uses the OLEDB provider and
is waiting while it returns the data. A common cause of such waits is linked server
queries. However, for example, many DMVs use OLEDB internally, so frequent calls to
these DMVs can cause these waits. DBCC checks also use OLEDB so it’s common to
see this wait type when such checks run.


PAGEIOLATCH_XX
PAGEIOLATCH_XX waits appear when sessions have to wait to obtain a latch on a page
that is not currently in memory. This happens when lots of sessions, or maybe one session
in particular, request many data pages that are not available in the buffer pool, and so the
engine needs to perform physical I/O to retrieve them. SQL Server must allocate a buffer
page for each one and place a latch on that page while it retrieves it from disk.
PAGEIOLATCH_SH and PAGEIOLATCH_EX
If a thread needs to read a page, it needs a shared-mode latch on the buffer page, and waits
for such latches for pages not currently in memory appear as PAGEIOLATCH_SH wait types. If
a thread needs to modify a page, we see PAGEIOLATCH_EX wait types.
*/
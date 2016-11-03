/*
RESOURCES (description of waiting resources)
	http://msdn.microsoft.com/en-us/library/ms179984.aspx
	http://sqlworks.blogspot.com/2012/10/SQL-Server-waittype-descriptions.html
	http://www.olap.ru/home.asp?artId=2085
	---------------------------------------------------------------------------------------------------------
	��������� ������� ��� ���������� ��������, �������������� �� ���� �������
	,��� ���� ����������� �������, ��� ���������� �������� � ���������� ����������. 
	
	��� �� ������������ ������������� ����� ������������� �������� ������������������, ������� ������������� ���������� ����� ������������� �������� 
	(�������� ��������� ������, ������������ ����� � �. �.).

	���������� ���������� �������� � ������������ �������� �������� ����� ������ ���������� ����� "��������������" ������� � ������� � ������� ��������� ����� �����.

	��� ���������� ������������� � ������� ���������� ����������� SQL Server, ������� ����� ����� ������� �������� ������� �������� � ������� �� ���� ������� �� ��������.
	����� ������� �������� ���������� �������� ��� ������������ �������, ���������������� �������� DBCC SQLPERF:
	DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
*/
select * from sys.dm_os_wait_stats
order by wait_time_ms desc
-------------------------------------------------------
/*
	������ ��������� ���� ������� �������� ������������ � �������� �������� � ����� ������� �������� � ����� ����������� �������� �� ���������:
	
	��� ��� ����� �������� �������� �������� �������� ��������� ������ �����������, �� ��������� ����� ��������, ������� ���� ������ 10-15%
	,����� ���������� � ���������� �������� �� ���������.

	signal_wait_time_ms - ������� ����� �������� ������������ ���������� ������ � �������� ������ ��� ����������.
	wait_time_ms - ����� ����� �������� ������� ���� � �������������. ��� ����� �������� signal_wait_time_ms.
*/
SELECT
	CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits]
	,CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20, 2)) AS [%resource waits]
FROM sys.dm_os_wait_stats;
------------------------------------------------------------
/*
	�� �������� �������� ������������ �������, �� �������� ������� SQL Server ������ ������ 
	����� �������:
*/
;WITH Waits 
AS
(
	SELECT 
		wait_type
		,wait_time_ms / 1000. AS wait_time_s
		,100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct
		,ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC ) AS rn
	FROM sys.dm_os_wait_stats 
	WHERE 
		wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR','LOGMGR_QUEUE','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE','FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN' ) 
)
SELECT 
	W1.wait_type
	,CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s
	,CAST(W1.pct AS DECIMAL(12, 2)) AS pct
	,CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct 
FROM Waits AS W1 
INNER JOIN Waits AS W2 ON W2.rn <= W1.rn 
GROUP BY 
	W1.rn
	,W1.wait_type
	,W1.wait_time_s
	,W1.pct 
HAVING 
	SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold
---------------------------------------------------------------------------------------------------------
/*
������������ �������� ������������������
���������� �� ������ �� ������ ������� ������������������, �������� �� �������.

https://msdn.microsoft.com/en-us/library/ms187743.aspx

*/
select * from sys.dm_os_performance_counters 
----------------------------------------------
/*
��������� �������� ��������� ������� ������������� �������, ��������� � ������� ����������. 
�� ���������� ���������� � 
	������ ��������������
	,�������� ����� ��������� �������������� �������
	,������� ������� ����������
	,������� ������������ ������� � ���������� ������ � � ���������
	,������ ������������� 
	� ��������� �������� ������� � ������ ���� ������ �������� ���������� SQL Server:

���� ������ ��������� ���������������� ���������� ������ ��. 
�� ����� ������� ��� �����������. ��������, ���� �������� �������� ���������� ������������� ������� �������� ���-�� ��������� � ������ ���������� �������� �� 85%, 
�� ��������� � ������� ���������� ���-�� �� ���.
*/
SELECT 
	db.[name] AS [Database Name]
	,db.recovery_model_desc AS [Recovery Model]
	,db.log_reuse_wait_desc AS [Log Reuse Wait Description]
	,ls.cntr_value AS [Log Size (KB)]
	,lu.cntr_value AS [Log Used (KB)]
	,CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Log Used %]
	,db.[compatibility_level] AS [DB Compatibility Level]
	,db.page_verify_option_desc AS [Page Verify Option]
FROM sys.databases AS db 
INNER JOIN sys.dm_os_performance_counters AS lu ON db.name = lu.instance_name 
INNER JOIN sys.dm_os_performance_counters AS ls ON db.name = ls.instance_name
WHERE 
	lu.counter_name LIKE 'Log File(s) Used Size (KB)%' 
	AND ls.counter_name LIKE 'Log File(s) Size (KB)%';
---------------------------------------------------------------------------------------------------------
/*
	���� ������� ����� ������ ����������� �� ����������, � ������� Status ����� �������� ��� Running (�� ���� �������������).
	���� ����� ����� � ����������, �� �����������, �������� �� ��������, ��������� ������ �����, ����� ����� ����� ������� � ������� Runnable. �� ���� �� ������� ����� ������� �� ������ � ����������. 
	��� ���������� �������� ��������.
	
	����� �������� ����������� � ������� signal_wait_time_ms column, � ��� ������ ����� �������� ����������. 
	���� ����� ������� ������������ ������� �������, ������ ��� ��������������� ��������, ��� �������� ������ ����� ��������� ���� ��� �����, ����� �� ����������� � ������ ��������.
	��� �������� ������� � ��������� ���������� ������ ����� �������� ��� "Suspended" (�� ���� ��������������).
	
	������� �������� �������������� � ����������� � ������� wait_type (��. sys.dm_os_wait_stats). 
	����� ����� �������� �������� � ������� wait_time_ms, ������� ���������� ����� �������� ������� ����� ��������� �������:
		�������� ������� = ����� �������� - �������� ������������ = (wait_time_ms) - (signal_wait_time_ms)
	�������� ������������ ��������� � OLTP-��������, ��� �������� ������� �� �������� ����� �������� ����������. 
	
	�������� ���������� ��������� ���������� ���������� - ���������� ���� �������� ������������ � ����� ������� ��������. 
	������� ���� �������� ���� �������� �� ���������. � ���������� "�������" ��������� �������� ������ 25%, �� ��� ������� �� �������.
	� ����� �������� �� ������� ���������� �������� ������ 10-15%. 
	� �����, ������������� ���������� �������� �������� ����� ����������� ������������ ����������� ������� ������� � �������. 
	����� ������, ��� ������� ��������, ��� ��� ��������� � ������� ��������. ����� ������� ����� ������� ������������ ���� ����� ��������.
	���� ����� ������� ������� � ���������� ������� ������� ��������, ����� ����� ������, ��� ������ � �����������. ���� �� ����� ������� ������� ��-�� ������������� �������, �������������� �� �������� ������ �������� (����� ��� ����, ���������� �����/������ � �. �.), ����� �������, ��� ��������� ���� ��������.
*/
select * from sys.dm_exec_requests
---------------------------------------------------------------------------------------------------------
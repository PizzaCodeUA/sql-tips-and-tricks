SELECT 
	total_physical_memory_kb / 1024 AS total_physical_memory_mb ,
	available_physical_memory_kb / 1024 AS available_physical_memory_mb ,
	total_page_file_kb / 1024 AS total_page_file_mb ,
	available_page_file_kb / 1024 AS available_page_file_mb ,
	system_memory_state_desc
FROM sys.dm_os_sys_memory
------------------------------------------------------------------
SELECT 
	physical_memory_in_use_kb ,
	virtual_address_space_committed_kb ,
	virtual_address_space_available_kb ,
	page_fault_count ,
	process_physical_memory_low ,
	process_virtual_memory_low
FROM sys.dm_os_process_memory
------------------------------------------------------------------
/*
https://msdn.microsoft.com/en-us/library/ms173442.aspx
*/
select * from sys.dm_os_buffer_descriptors 
--select * from sys.allocation_units

--cached page count for each database
SELECT 
	COUNT(*) AS cached_pages_count  
    ,CASE database_id   
		WHEN 32767 THEN 'ResourceDb'   
		ELSE db_name(database_id)   
	END AS database_name  
FROM sys.dm_os_buffer_descriptors  
GROUP BY 
	DB_NAME(database_id) ,database_id  
ORDER BY 
	cached_pages_count DESC;  
----------------------------------------------
--cached page count for each object in the current database
SELECT 
	COUNT(*)AS cached_pages_count
	,name
	,index_id
FROM sys.dm_os_buffer_descriptors AS bd
INNER JOIN   
(
	SELECT 
		object_name(object_id) AS name
		,index_id
		,allocation_unit_id
	FROM sys.allocation_units AS au  
	INNER JOIN sys.partitions AS p ON au.container_id = p.hobt_id AND (au.type = 1 OR au.type = 3)  
	
	UNION ALL  
	SELECT 
		object_name(object_id) AS name     
		,index_id
		,allocation_unit_id  
	FROM sys.allocation_units AS au  
	INNER JOIN sys.partitions AS p   ON au.container_id = p.partition_id AND au.type = 2  
) AS obj   ON bd.allocation_unit_id = obj.allocation_unit_id  
WHERE 
	database_id = DB_ID()  
GROUP BY 
	name
	,index_id   
ORDER BY 
	cached_pages_count DESC; 
----------------------------------------------
-- Get total buffer usage by database
SELECT
	DB_NAME(database_id) AS [Database Name] ,
	COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE
	database_id > 4 -- exclude system databases
	AND database_id <> 32767 -- exclude ResourceDB
GROUP BY 
	DB_NAME(database_id)
ORDER BY 
	[Cached Size (MB)] DESC ;
------------------------------------------------------------------
-- Breaks down buffers by object (table, index) in the buffer pool
SELECT 
	OBJECT_NAME(p.[object_id]) AS [ObjectName] ,
	p.index_id ,
	COUNT(*) / 128 AS [Buffer size(MB)] ,
	COUNT(*) AS [Buffer_count]
FROM sys.allocation_units AS a
INNER JOIN sys.dm_os_buffer_descriptors AS b ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p ON a.container_id = p.hobt_id
WHERE 
	b.database_id = DB_ID()
	AND p.[object_id] > 100 -- exclude system objects
GROUP BY 
	p.[object_id] ,
	p.index_id
ORDER BY 
	buffer_count DESC;
------------------------------------------------------------------
/*
This DMV allows you to check for queries that are waiting (or have recently had to wait)
for a memory grant, as demonstrated in Listing 7.26. Although not used in this query,
note that SQL Server 2008 added some new columns to this DMV.
-- Shows the memory required by both running (non-null grant_time)
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
*/
SELECT 
	DB_NAME(st.dbid) AS [DatabaseName] ,
	mg.requested_memory_kb ,
	mg.ideal_memory_kb ,
	mg.request_time ,
	mg.grant_time ,
	mg.query_cost ,
	mg.dop ,
	st.[text]
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE 
	mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY 
	mg.requested_memory_kb DESC ;
------------------------------------------------------------------
-- Shows the memory required by both running (non-null grant_time)
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
SELECT
	DB_NAME(st.dbid) AS [DatabaseName] ,
	mg.requested_memory_kb ,
	mg.request_time ,
	mg.grant_time ,
	mg.query_cost ,
	mg.dop ,
	st.[text]
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE 
	mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY 
	mg.requested_memory_kb DESC ;
------------------------------------------------------------------
SELECT
*
FROM sys.dm_os_memory_cache_counters
ORDER BY type,name;
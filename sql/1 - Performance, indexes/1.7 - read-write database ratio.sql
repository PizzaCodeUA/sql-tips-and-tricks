--uses a LIKE comparison to only include desired databases, rather than
--using the database_id parameter of sys.dm_io_virtual_file_stats
--if you have a rather large number of databases, this may not be the
--optimal way to execute the query, but this gives you flexibility
--to look at multiple databases simultaneously.
DECLARE @databaseName SYSNAME
SET @databaseName = '%'
--'%' gives all databases
SELECT 
	CAST(SUM(num_of_bytes_read) AS DECIMAL) / ( CAST(SUM(num_of_bytes_written) AS DECIMAL) + CAST(SUM(num_of_bytes_read) AS DECIMAL) ) AS RatioOfReads
	,CAST(SUM(num_of_bytes_written) AS DECIMAL) / ( CAST(SUM(num_of_bytes_written) AS DECIMAL) + CAST(SUM(num_of_bytes_read) AS DECIMAL) ) AS RatioOfWrites
	,SUM(num_of_bytes_read) *1.0 / 1024 AS TotalMBRead
	,SUM(num_of_bytes_written) *1.0 / 1024 AS TotalMBWritten
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
WHERE 
	DB_NAME(database_id) LIKE @databaseName
-----------------
--Per disk Drive
DECLARE @databaseName SYSNAME
SET @databaseName = '%'
--'%' gives all databases
SELECT 
	LEFT(physical_name, 1) AS drive
	,CAST(SUM(num_of_bytes_read) AS DECIMAL) / ( CAST(SUM(num_of_bytes_written) AS DECIMAL) + CAST(SUM(num_of_bytes_read) AS DECIMAL) ) AS RatioOfReads
	,CAST(SUM(num_of_bytes_written) AS DECIMAL) / ( CAST(SUM(num_of_bytes_written) AS DECIMAL) + CAST(SUM(num_of_bytes_read) AS DECIMAL) ) AS RatioOfWrites
	,SUM(num_of_bytes_read) AS TotalBytesRead
	,SUM(num_of_bytes_written) AS TotalBytesWritten
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id AND mf.file_id = divfs.file_id
WHERE 
	DB_NAME(divfs.database_id) LIKE @databaseName
GROUP BY 
	LEFT(mf.physical_name, 1)
----------------------------
--returns the number of reads and writes as a proportion of the total number of reads and writes.
DECLARE @databaseName SYSNAME
SET @databaseName = '%' --'%' gives all databases
SELECT 
	mf.name as DB
	,mf.physical_name as FileName
	,CAST(SUM(num_of_reads) AS DECIMAL) / ( CAST(SUM(num_of_writes) AS DECIMAL) + CAST(SUM(num_of_reads) AS DECIMAL) ) AS RatioOfReads
	,CAST(SUM(num_of_writes) AS DECIMAL) / ( CAST(SUM(num_of_reads) AS DECIMAL) + CAST(SUM(num_of_writes) AS DECIMAL) ) AS RatioOfWrites
	,SUM(num_of_reads) AS TotalReadOperations
	,SUM(num_of_writes) AS TotalWriteOperations
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id AND mf.file_id = divfs.file_id
WHERE 
	DB_NAME(divfs.database_id) LIKE @databaseName
group by
	mf.name
	,mf.physical_name
---------------------------------
--Number of reads and writes at the table level
--Read:write ratio for all objects in a given database
DECLARE @databaseName SYSNAME
SET @databaseName = '%' --'%' gives all databases
SELECT 
	o.name
	,CASE
		WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 ) THEN NULL
		ELSE ( CAST(SUM(user_seeks + user_scans + user_lookups)AS DECIMAL) / CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL) )
	END AS RatioOfReads
	,CASE
		WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 )	THEN NULL 
		ELSE ( CAST(SUM(user_updates) AS DECIMAL) / CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL) )
	END AS RatioOfWrites
	,SUM(user_updates + user_seeks + user_scans + user_lookups) AS TotalReadOperations
	,SUM(user_updates) AS TotalWriteOperations
FROM sys.dm_db_index_usage_stats AS ddius
inner join sys.objects o on o.object_id = ddius.object_id
WHERE 
	DB_NAME(database_id) LIKE @databaseName
group by
	o.name
---------------------------
--only works in the context of the database due to sys.indexes usage
SELECT 
	OBJECT_NAME(ddius.object_id) AS object_name
	,CASE
		WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 ) THEN NULL
		ELSE ( CAST(SUM(user_seeks + user_scans + user_lookups) AS DECIMAL) / CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL) ) 
	END AS RatioOfReads
	,CASE
		WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 ) THEN NULL
		ELSE ( CAST(SUM(user_updates) AS DECIMAL) / CAST(SUM(user_updates + user_seeks + user_scans + user_lookups) AS DECIMAL) ) 
	END AS RatioOfWrites
	,SUM(user_updates + user_seeks + user_scans + user_lookups) AS TotalReadOperations
	,SUM(user_updates) AS TotalWriteOperations
FROM sys.dm_db_index_usage_stats AS ddius
JOIN sys.indexes AS i ON ddius.object_id = i.object_id AND ddius.index_id = i.index_id
WHERE 
	i.type_desc IN ( 'CLUSTERED', 'HEAP' ) --only works in Current db
GROUP BY 
	ddius.object_id
ORDER BY 
	OBJECT_NAME(ddius.object_id)
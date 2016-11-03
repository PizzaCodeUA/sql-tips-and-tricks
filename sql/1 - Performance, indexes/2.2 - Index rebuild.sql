SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

declare @indbname nvarchar(130)
set @indbname = N'DWH'

declare @index_type_desc nvarchar(130);

DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000); 
-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
-- and convert object and index IDs to names.

-- Declare the cursor for the list of partitions to be processed.
DECLARE partitions CURSOR LOCAL FORWARD_ONLY STATIC for 
SELECT
    object_id AS objectid,
    index_id AS indexid,
    partition_number AS partitionnum,
	index_type_desc,
    avg_fragmentation_in_percent AS frag
FROM sys.dm_db_index_physical_stats (DB_ID(@indbname), NULL, NULL , NULL, 'LIMITED')
WHERE
	avg_fragmentation_in_percent > 10.0
	AND index_id > 0
order by  index_type_desc ASC ;

-- Open the cursor.
OPEN partitions;

-- Loop through the partitions.
WHILE (1=1)
BEGIN;
	FETCH NEXT 	FROM partitions
	INTO @objectid, @indexid, @partitionnum, @index_type_desc, @frag;
	
	IF @@FETCH_STATUS < 0 BREAK;
	
	SELECT 
		@objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
	FROM sys.objects AS o
	JOIN sys.schemas as s ON s.schema_id = o.schema_id
	WHERE 
		o.object_id = @objectid;
		
	SELECT 
		@indexname = QUOTENAME(name)
	FROM sys.indexes
	WHERE
		object_id = @objectid AND index_id = @indexid;
	
	SELECT 
		@partitioncount = count (*)
	FROM sys.partitions
	WHERE 
		object_id = @objectid 
		AND index_id = @indexid;
	
	-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
	IF @frag < 30.0
		SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
	IF @frag >= 30.0
		SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';

	IF @partitioncount > 1
		SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
	
	EXEC (@command);
    PRINT N'Executed: ' + @command;
END;

-- Close and deallocate the cursor.
CLOSE partitions;
DEALLOCATE partitions;
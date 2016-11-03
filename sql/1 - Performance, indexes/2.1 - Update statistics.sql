/*
AUTO_CREATE_STATISTICS
AUTO_UPDATE_STATISTICS

SELECT name AS 'Name', 
    is_auto_create_stats_on AS "Auto Create Stats",
    is_auto_update_stats_on AS "Auto Update Stats",
    is_read_only AS "Read Only" 
FROM sys.databases
WHERE database_ID > 4;
*/
--------------------------------
/*
SELECT 
	s.*
FROM sys.stats s
JOIN sys.objects o ON s.[object_id] = o.[object_id]
WHERE 
	o.is_ms_shipped = 0
*/

DECLARE @TableName varchar(200)
DECLARE @msg varchar(max)

DECLARE cTbl
 CURSOR FOR 
 SELECT '[' + s.name + '].[' +t.name +']'FROM sys.tables t
 INNER JOIN sys.schemas s on t.schema_id = s.schema_id order by s.name,t.name

OPEN cTbl;

FETCH NEXT FROM cTbl INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT ' ';
    SELECT @msg = 'UPDATE STATISTICS ' + @TableName
    PRINT @msg;
    exec (@msg);

    FETCH NEXT FROM cTbl INTO @TableName
END

CLOSE cTbl;

DEALLOCATE cTbl;

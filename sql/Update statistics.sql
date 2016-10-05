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
--default schema
USE yourDatabase;
ALTER USER [yourUser] WITH DEFAULT_SCHEMA = myschema;
--------------------------------
--sql_variant
declare @v sql_variant = 15.5
select @v
set @v = 'sadasd asdsad'
select @v
--------------------------------
--XML data type
create table #T
(
	Id int identity,
	Val xml
)

insert into #T (val)
values 
(
	'<root>
	   <role>Alpha</role>
	   <role>Beta</role>
	   <role>Gamma</role>
	</root>'
)
,(
	'<root>
	   <roleA>A</roleA>
	   <roleB>B</roleB>
	   <roleC>C</roleC>
	</root>'
)

--value (XQuery, SQLType)
select 
	*
	,val.value('(/root/role)[1]', 'varchar(max)')
	,val.value('(/root/role)[2]', 'varchar(max)')
	,val.value('(/root/role)[3]', 'varchar(max)')
	,val.value('(/root/roleA)[1]', 'varchar(max)')
from #T

--Метод nodes() незаменим в тех случаях, когда экземпляр типа данных xml необходимо разделить на набор реляционных данных.
select 
	pref.value('(text())[1]', 'varchar(32)') as RoleName
from #T
CROSS APPLY val.nodes('/root/role') AS Roles(pref)
--------------------------------
--JSON (2016)

--------------------------------

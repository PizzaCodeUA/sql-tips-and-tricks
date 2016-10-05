/*
PARTITION
*/
drop table T2

create table T2
(
	Id int identity primary key,
	Name nvarchar(100) NOT NULL,
	EventDate datetime not null
) on BigData


---------------------------
CREATE PARTITION FUNCTION function_name ( input_parameter_type )  
AS RANGE [ LEFT | RIGHT ]   
FOR VALUES ( [ boundary_value [ ,...n ] ] )   


CREATE PARTITION FUNCTION myRangePF1 (int)  
AS RANGE LEFT 
FOR VALUES (1, 100, 1000); 
--------------------------------------
CREATE PARTITION FUNCTION myDateRangePF (datetime)  
AS RANGE RIGHT 
FOR VALUES 
(
	 '20130101'
	,'20140101'
	,'20150101'
	,'20160101'
);
--------------------------------------
CREATE PARTITION SCHEME part_schema
AS PARTITION myDateRangePF
TO (f1, f2, f3, f4, BigData);
--------------------------------------
create table T3
(
	Id int identity,
	Name nvarchar(100) NOT NULL,
	EventDate datetime not null
) on part_schema(EventDate)
--------------------------------------
insert into T3 (Name, EventDate)
values 
	('A1', '2016-05-07')
	,('A2', '2016-05-07')
	,('B1', '2015-01-07')
	,('C1', '2014-05-07')
	,('C2', '2014-04-07')
	,('C3', '2014-09-07')
	
	
select * from T3

select 
	partition_number
	,rows
from sys.partitions
where
	object_id = object_id( 'T3');
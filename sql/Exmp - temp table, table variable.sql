--Table variable
declare @t table
(
	OrderId int,
	Amount numeric(18,4)
)

insert into @t (OrderId, Amount)
select
	OrderId
	,sum(Amount) Amount
from sa.OrderItem
where
	EtlStatus <> 'D'
group by 
	OrderId


SELECT
	o.OrderDate
	,o.BusinessUnitId
	,t.Amount
from sa.[Order] o
inner join @T t on t.OrderId = o.OrderId
------------------------------------
--Temp Table
create table #t
(
	OrderId int,
	Amount numeric(18,4)
)

insert into #t (OrderId, Amount)
select
	OrderId
	,sum(Amount) Amount
from sa.OrderItem
where
	EtlStatus <> 'D'
group by 
	OrderId


SELECT
	o.OrderDate
	,o.BusinessUnitId
	,t.Amount
from sa.[Order] o
inner join #T t on t.OrderId = o.OrderId
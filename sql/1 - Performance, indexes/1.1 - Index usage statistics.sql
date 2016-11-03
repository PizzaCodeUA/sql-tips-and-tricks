/*
	Index usage statistics
	https://msdn.microsoft.com/ru-ru/library/ms188755.aspx

	Можно также определять, какие индексы привносят дополнительную нагрузку,
	связанную с обслуживанием. Стоит рассмотреть возможность удаления индексов, 
	вызывающих дополнительную нагрузку, связанную с их обслуживанием, 
	но не использующихся для выполнения запросов или использующихся лишь иногда.
*/
SELECT
	OBJECT_NAME(S.[OBJECT_ID]) as [OBJECT NAME]
	,I.[NAME] AS [INDEX NAME]
	,USER_SEEKS --very fast search operation in index-tree
	,USER_SCANS --fast full index scan
	,USER_LOOKUPS --loockups
	,USER_UPDATES  --index maintanance operations (insert, update, delete)
	-----------------
	,last_user_seek		--Время последней операции поиска, выполненной пользователем.
	,last_user_scan		--Время последней операции просмотра, выполненной пользователем.
	,last_user_lookup	--Время последней операции поиска соответствия, выполненной пользователем.
	,last_user_update	--Время последней операции обновления, выполненной пользователем.
	----------------
	,last_system_seek	--Время последней системной операции поиска.
	,last_system_scan	--Время последней системной операции просмотра.
	,last_system_lookup	--Время последнего системного уточняющего запроса.
	,last_system_update	--Время последней системной операции обновления.
FROM SYS.DM_DB_INDEX_USAGE_STATS AS S
INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
order by USER_SEEKS desc


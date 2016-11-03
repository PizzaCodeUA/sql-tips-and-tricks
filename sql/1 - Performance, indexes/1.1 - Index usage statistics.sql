/*
	Index usage statistics
	https://msdn.microsoft.com/ru-ru/library/ms188755.aspx

	����� ����� ����������, ����� ������� ��������� �������������� ��������,
	��������� � �������������. ����� ����������� ����������� �������� ��������, 
	���������� �������������� ��������, ��������� � �� �������������, 
	�� �� �������������� ��� ���������� �������� ��� �������������� ���� ������.
*/
SELECT
	OBJECT_NAME(S.[OBJECT_ID]) as [OBJECT NAME]
	,I.[NAME] AS [INDEX NAME]
	,USER_SEEKS --very fast search operation in index-tree
	,USER_SCANS --fast full index scan
	,USER_LOOKUPS --loockups
	,USER_UPDATES  --index maintanance operations (insert, update, delete)
	-----------------
	,last_user_seek		--����� ��������� �������� ������, ����������� �������������.
	,last_user_scan		--����� ��������� �������� ���������, ����������� �������������.
	,last_user_lookup	--����� ��������� �������� ������ ������������, ����������� �������������.
	,last_user_update	--����� ��������� �������� ����������, ����������� �������������.
	----------------
	,last_system_seek	--����� ��������� ��������� �������� ������.
	,last_system_scan	--����� ��������� ��������� �������� ���������.
	,last_system_lookup	--����� ���������� ���������� ����������� �������.
	,last_system_update	--����� ��������� ��������� �������� ����������.
FROM SYS.DM_DB_INDEX_USAGE_STATS AS S
INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
order by USER_SEEKS desc


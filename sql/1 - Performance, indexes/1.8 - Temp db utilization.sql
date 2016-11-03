--Temp db utilization
/*
https://msdn.microsoft.com/en-us/library/ms174412.aspx
https://msdn.microsoft.com/en-us/library/ms186782.aspx

unallocated_extent_page_count – extents that are reserved in the file but not
currently allocated to objects
• version_store_reserved_page_count – number of pages that are reserved to support snapshot isolation transactions
• user_object_reserved_page_count – number of pages reserved to user tables 
• internal_object_reserved_page_count – number of pages reserved to internal objects, such as work tables, that SQL Server creates to hold intermediate results, such as for sorting data
• mixed_extent_page_count – number of extents that have pages of multiple types
– user objects, version store, or internal objects, Index Allocation Map (IAM) pages, etc.
*/
SELECT 
	mf.physical_name as [FileName]
	,mf.size AS entire_file_page_count --8Kb page size
	
	
	,dfsu.unallocated_extent_page_count as FreeAmountOfPages
	,dfsu.version_store_reserved_page_count as ReservedAmountOfPages
	,dfsu.user_object_reserved_page_count as UsedByUserObjects_AmountOfPages
	,dfsu.internal_object_reserved_page_count as UsedByInternalObjects_AmountOfPages
	,dfsu.mixed_extent_page_count
FROM sys.dm_db_file_space_usage dfsu
JOIN sys.master_files AS mf ON mf.database_id = dfsu.database_id AND mf.file_id = dfsu.file_id
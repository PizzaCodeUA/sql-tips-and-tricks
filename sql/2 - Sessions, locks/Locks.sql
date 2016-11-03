/*
lock type:
	RID = Lock on a single row in a table identified by a row identifier (RID).
	KEY = Lock within an index that protects a range of keys in serializable transactions.
	PAG = Lock on a data or index page.
	EXT = Lock on an extent.
	TAB = Lock on an entire table, including all data and indexes.
	DB = Lock on a database.
	FIL = Lock on a database file.
	APP = Lock on an application-specified resource.
	MD = Locks on metadata, or catalog information.
	HBT = Lock on a heap or B-Tree index. This information is incomplete in SQL Server.
	AU = Lock on an allocation unit. This information is incomplete in SQL Server.

lock mode
	NULL = No access is granted to the resource.
	Schema
		Sch-S = Schema stability. Ensures that a schema element, such as a table or index, is not dropped while any session holds a schema stability lock on the schema element.
		Sch-M = Schema modification. Must be held by any session that wants to change the schema of the specified resource. Ensures that no other sessions are referencing the indicated object.
	
	S = Shared. The holding session is granted shared access to the resource.
	U = Update. Indicates an update lock acquired on resources that may eventually be updated. It is used to prevent a common form of deadlock that occurs when multiple sessions lock resources for potential update at a later time.
	BU = Bulk Update. Used by bulk operations.
	X = Exclusive. The holding session is granted exclusive access to the resource.
	IS = Intent Shared. Indicates the intention to place S locks on some subordinate resource in the lock hierarchy.
	IU = Intent Update. Indicates the intention to place U locks on some subordinate resource in the lock hierarchy.
	IX = Intent Exclusive. Indicates the intention to place X locks on some subordinate resource in the lock hierarchy.
	SIU = Shared Intent Update. Indicates shared access to a resource with the intent of acquiring update locks on subordinate resources in the lock hierarchy.
	SIX = Shared Intent Exclusive. Indicates shared access to a resource with the intent of acquiring exclusive locks on subordinate resources in the lock hierarchy.
	UIX = Update Intent Exclusive. Indicates an update lock hold on a resource with the intent of acquiring exclusive locks on subordinate resources in the lock hierarchy.

	Key
		RangeS_S = Shared Key-Range and Shared Resource lock. Indicates serializable range scan.
		RangeS_U = Shared Key-Range and Update Resource lock. Indicates serializable update scan.
		RangeI_N = Insert Key-Range and Null Resource lock. Used to test ranges before inserting a new key into an index.
		RangeI_S = Key-Range Conversion lock. Created by an overlap of RangeI_N and S locks.
		RangeI_U = Key-Range Conversion lock created by an overlap of RangeI_N and U locks.
		RangeI_X = Key-Range Conversion lock created by an overlap of RangeI_N and X locks.
		RangeX_S = Key-Range Conversion lock created by an overlap of RangeI_N and RangeS_S. locks.
		RangeX_U = Key-Range Conversion lock created by an overlap of RangeI_N and RangeS_U locks.
		RangeX_X = Exclusive Key-Range and Exclusive Resource lock. This is a conversion lock used when updating a key in a range.
*/
declare @tmp table
(
	spId smallint
	,dbId smallint
	,objId int
	,IndId smallint
	,Type nchar(4)
	,Resource nchar(32)
	,Mode nvarchar(8)	
	,Status nvarchar(5)
)

INSERT INTO  @tmp (spId, dbId, objId, IndId, Type, Resource, Mode, Status)
exec sp_lock

select
	db_name(dbId)
	,object_name(objId)
	,*
from @tmp
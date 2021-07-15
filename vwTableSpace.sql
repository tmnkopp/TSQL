/*
View containing query logic to inspect sizes of db objects 
IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'vwTableSpace' AND type = 'V')
BEGIN
	DROP VIEW vwTableSpace
END 
GO 
CREATE VIEW vwTableSpace
AS 
*/  
SELECT 
	T.name AS TableName, 
	I.name As indexName, 
	cols.COLUMN_NAME As PK,
	SUM(P.rows) as RowCounts, 
	(SUM(A.total_pages) * 8) / 1024 as TotalSpaceMB 
FROM  SYS.TABLES T 
INNER JOIN SYS.INDEXES I ON T.object_id = I.object_id
INNER JOIN sys.partitions P ON I.object_id = P.object_id AND I.index_id = P.index_id
INNER JOIN sys.allocation_units A ON P.partition_id = A.container_id
INNER JOIN INFORMATION_SCHEMA.COLUMNS cols ON cols.TABLE_NAME = T.name AND cols.ORDINAL_POSITION = 1
WHERE I.name NOT LIKE 'dt%' AND i.object_id > 255 AND i.index_id <= 1
GROUP BY  t.name, i.object_id, i.index_id, i.name , cols.COLUMN_NAME 
ORDER BY TotalSpaceMB DESC
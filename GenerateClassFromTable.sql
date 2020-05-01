DECLARE @TABLENAME VARCHAR(55) = 'LENDERS'

SELECT 'public class ' + @TABLENAME + '{ [fields] }' 
Select  
'	public ' +
CASE 
WHEN DATA_TYPE = 'int' THEN
	 'int '
WHEN DATA_TYPE = 'datetime' THEN 
	 'DateTime '
ELSE 
	 'string '
END 
+ ' ' + COLUMN_NAME 
+ ' { get; set; } ' 
AS PROPERTY 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TABLENAME ORDER BY ORDINAL_POSITION

 

  

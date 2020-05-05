--snippet{"name":"cols from info schema", "category":"sql"}

DECLARE @COLS  AS NVARCHAR(MAX)=''; 
SELECT @COLS = @COLS + COLUMN_NAME + ',' FROM (SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='fsma_Activities' AND COLUMN_NAME NOT LIKE '%PK_%') vw
SELECT @COLS = substring(@COLS, 0, LEN(@COLS)) --trim "," at end
SELECT @COLS 

--//snippet 

DECLARE @SearchStr nvarchar(100)
SET @SearchStr = 'your_search_term'

-- Create temporary table to store results
CREATE TABLE #Results (
    TableName nvarchar(256),
    ColumnName nvarchar(256)
)

-- Insert the tables and columns to search into our temp table
INSERT INTO #Results (TableName, ColumnName)
SELECT DISTINCT 
    t.name AS TableName,
    c.name AS ColumnName
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.system_type_id = ty.system_type_id
WHERE ty.name IN ('nvarchar','nchar','varchar','char','text')
    AND t.name NOT LIKE '%temp%'

-- Now search through each table/column combination
DECLARE @TableName sysname
DECLARE @ColumnName sysname
DECLARE @SQLQuery nvarchar(max)

DECLARE SearchCursor CURSOR FOR
SELECT TableName, ColumnName
FROM #Results

OPEN SearchCursor
FETCH NEXT FROM SearchCursor INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQLQuery = 'IF EXISTS (SELECT 1 FROM [' + @TableName + '] WHERE [' + @ColumnName + '] LIKE ''%' + @SearchStr + '%'')
                     SELECT ''' + @TableName + ''' as TableName, 
                            ''' + @ColumnName + ''' as ColumnName,
                            COUNT(*) as MatchCount
                     FROM [' + @TableName + ']
                     WHERE [' + @ColumnName + '] LIKE ''%' + @SearchStr + '%'''

    EXEC sp_executesql @SQLQuery

    FETCH NEXT FROM SearchCursor INTO @TableName, @ColumnName
END

CLOSE SearchCursor
DEALLOCATE SearchCursor

-- Clean up
DROP TABLE #Results
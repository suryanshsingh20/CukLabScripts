function words = escapeReservedWords(words, dbSourceName)
% ESCAPERESERVEDWORDS escapes reserved column and table names into a 
% format that is accepted by an SQL query. The specific set of reserved 
% words and the escape sequence depends on the database source.
%
% words = escapeReservedWords(words, dbSourceName)
%   Escapes words (char or cell array of char) with a dbSourceName specific
%   escape sequence only if the word element is part of the reserved word 
%   list. The list matching is not case sensitive. Words are always 
%   returned as a cell array of char.
%
% Currently supported dbSourceNames:
%   'ACCESS' escapes reserved words with [], 
%       e.g. TimeStamp -> [TimeStamp]
%   'MySQL' escapes reserved words with ``
%       e.g. Group -> `Group`
%
% See Also: database

if ~iscell(words)
    words = {words};
end

switch dbSourceName
    case 'ACCESS'
        wordsList = {'ADD', 'ALL', 'Alphanumeric', 'ALTER', 'AND', 'ANY', 'Application', 'AS', 'ASC', 'Assistant', 'AUTOINCREMENT', 'Avg',...
                     'BETWEEN', 'BINARY', 'BIT', 'BOOLEAN', 'BY', 'BYTE',...
                     'CHAR', 'CHARACTER', 'COLUMN', 'CompactDatabase', 'CONSTRAINT', 'Container', 'Count', 'COUNTER', 'CREATE', 'CreateDatabase', 'CreateField', 'CreateGroup', 'CreateIndex', 'CreateObject', 'CreateProperty', 'CreateRelation', 'CreateTableDef', 'CreateUser', 'CreateWorkspace', 'CURRENCY', 'CurrentUser',...
                     'DATABASE', 'DATE', 'DATETIME', 'DELETE', 'DESC', 'Description', 'DISALLOW', 'DISTINCT', 'DISTINCTROW', 'Document', 'DOUBLE', 'DROP',...
                     'Echo', 'Else', 'End', 'Eqv', 'Error', 'EXISTS', 'Exit',...
                     'FALSE', 'Field', 'Fields', 'FillCache', 'FLOAT', 'FLOAT4', 'FLOAT8', 'FOREIGN', 'Form', 'Forms', 'FROM', 'Full', 'FUNCTION',...
                     'GENERAL', 'GetObject', 'GetOption', 'GotoPage', 'GROUP', 'GROUP BY', 'GUID',...
                     'HAVING',... 
                     'Idle', 'IEEEDOUBLE', 'IEEESINGLE', 'If', 'IGNORE', 'Imp', 'IN', 'INDEX', 'Index', 'Indexes', 'INNER', 'INSERT', 'InsertText', 'INT', 'INTEGER', 'INTEGER1', 'INTEGER2', 'INTEGER4', 'INTO', 'IS',...
                     'JOIN',...
                     'KEY',...
                     'LastModified', 'LEFT', 'Level', 'Like', 'LOGICAL', 'LOGICAL1', 'LONG', 'LONGBINARY', 'LONGTEXT',...
                     'Macro', 'Match', 'Max', 'Min', 'Mod', 'MEMO', 'Module', 'MONEY', 'Move',...
                     'NAME', 'NewPassword', 'NO', 'Not', 'Note', 'NULL', 'NUMBER', 'NUMERIC',...
                     'Object', 'OLEOBJECT', 'OFF', 'ON', 'OpenRecordset', 'OPTION', 'OR', 'ORDER', 'Orientation', 'Outer', 'OWNERACCESS',...
                     'Parameter', 'PARAMETERS', 'Partial', 'PERCENT', 'PIVOT', 'PRIMARY', 'PROCEDURE', 'Property',...
                     'Queries', 'Query', 'Quit',...
                     'REAL', 'Recalc', 'Recordset', 'REFERENCES', 'Refresh', 'RefreshLink', 'RegisterDatabase', 'Relation', 'Repaint', 'RepairDatabase', 'Report', 'Reports', 'Requery', 'RIGHT',...
                     'SCREEN', 'SECTION', 'SELECT', 'SET', 'SetFocus', 'SetOption', 'SHORT', 'SINGLE', 'SMALLINT', 'SOME', 'SQL', 'StDev', 'StDevP', 'STRING', 'Sum',...
                     'TABLE', 'TableDef', 'TableDefs', 'TableID', 'TEXT', 'TIME', 'TIMESTAMP', 'TOP', 'TRANSFORM', 'TRUE', 'Type',...
                     'UNION', 'UNIQUE', 'UPDATE', 'USER',...
                     'VALUE', 'VALUES', 'Var', 'VarP', 'VARBINARY', 'VARCHAR', 'VERSION',...
                     'WHERE', 'WITH', 'Workspace',...
                     'Xor', 'Year', 'YES', 'YESNO'};
        escapeFrmt = '[%s]';
    case 'MySQL'
        wordsList = {'CONVERT', 'CREATE', 'CROSS', 'CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP', 'CURRENT_USER', 'CURSOR',...
                     'DATABASE', 'DATABASES', 'DAY_HOUR', 'DAY_MICROSECOND', 'DAY_MINUTE', 'DAY_SECOND', 'DEC', 'DECIMAL', 'DECLARE', 'DEFAULT', 'DELAYED', 'DELETE', 'DESC', 'DESCRIBE', 'DETERMINISTIC', 'DISTINCT', 'DISTINCTROW', 'DIV', 'DOUBLE', 'DROP', 'DUAL',...
                     'EACH', 'ELSE', 'ELSEIF', 'ENCLOSED', 'ESCAPED', 'EXISTS', 'EXIT', 'EXPLAIN',...
                     'FALSE', 'FETCH', 'FLOAT', 'FLOAT4', 'FLOAT8', 'FOR', 'FORCE', 'FOREIGN', 'FROM', 'FULLTEXT',...
                     'GENERATED', 'GET', 'GRANT', 'GROUP',...
                     'HAVING', 'HIGH_PRIORITY', 'HOUR_MICROSECOND', 'HOUR_MINUTE', 'HOUR_SECOND',...
                     'IF', 'IGNORE', 'IN', 'INDEX', 'INFILE', 'INNER', 'INOUT', 'INSENSITIVE', 'INSERT', 'INT', 'INT1', 'INT2', 'INT3', 'INT4', 'INT8', 'INTEGER', 'INTERVAL', 'INTO', 'IO_AFTER_GTIDS', 'IO_BEFORE_GTIDS', 'IS', 'ITERATE',...
                     'JOIN', 'KEY', 'KEYS', 'KILL',...
                     'LEADING', 'LEAVE', 'LEFT', 'LIKE', 'LIMIT', 'LINEAR', 'LINES', 'LOAD', 'LOCALTIME', 'LOCALTIMESTAMP', 'LOCK', 'LONG', 'LONGBLOB', 'LONGTEXT', 'LOOP', 'LOW_PRIORITY',...
                     'MASTER_BIND', 'MASTER_SSL_VERIFY_SERVER_CERT', 'MATCH', 'MAXVALUE', 'MEDIUMBLOB', 'MEDIUMINT', 'MEDIUMTEXT', 'MIDDLEINT', 'MINUTE_MICROSECOND', 'MINUTE_SECOND', 'MOD', 'MODIFIES',...
                     'NATURAL', 'NOT', 'NO_WRITE_TO_BINLOG', 'NULL', 'NUMERIC',...
                     'ON', 'OPTIMIZE', 'OPTIMIZER_COSTS', 'OPTION', 'OPTIONALLY', 'OR', 'ORDER', 'OUT', 'OUTER', 'OUTFILE',...
                     'PARTITION', 'PRECISION', 'PRIMARY', 'PROCEDURE', 'PURGE',...
                     'RANGE', 'READ', 'READS', 'READ_WRITE', 'REAL', 'REFERENCES', 'REGEXP', 'RELEASE', 'RENAME', 'REPEAT', 'REPLACE', 'REQUIRE', 'RESIGNAL', 'RESTRICT', 'RETURN', 'REVOKE', 'RIGHT', 'RLIKE',...
                     'SCHEMA', 'SCHEMAS', 'SECOND_MICROSECOND', 'SELECT', 'SENSITIVE', 'SEPARATOR', 'SET', 'SHOW', 'SIGNAL', 'SMALLINT', 'SPATIAL', 'SPECIFIC', 'SQL', 'SQLEXCEPTION', 'SQLSTATE', 'SQLWARNING', 'SQL_BIG_RESULT', 'SQL_CALC_FOUND_ROWS', 'SQL_SMALL_RESULT', 'SSL', 'STARTING', 'STORED', 'STRAIGHT_JOIN',...
                     'TABLE', 'TERMINATED', 'THEN', 'TINYBLOB', 'TINYINT', 'TINYTEXT', 'TO', 'TRAILING', 'TRIGGER', 'TRUE',...
                     'UNDO', 'UNION', 'UNIQUE', 'UNLOCK', 'UNSIGNED', 'UPDATE', 'USAGE', 'USE', 'USING', 'UTC_DATE', 'UTC_TIME', 'UTC_TIMESTAMP',...
                     'VALUES', 'VARBINARY', 'VARCHAR', 'VARCHARACTER', 'VARYING', 'VIRTUAL',...
                     'WHEN', 'WHERE', 'WHILE', 'WITH', 'WRITE',...
                     'XOR',...
                     'YEAR_MONTH',...
                     'ZEROFILL'};
        escapeFrmt = '`%s`';
    otherwise
        warning('Reserved words not available for %s. Returning unescaped list.', dbSourceName);
        wordsList = '';
        escapeFrmt = '%s';
end


for ii = 1:numel(words)
    if any(strcmpi(words{ii},wordsList))
        words{ii} = sprintf(escapeFrmt,words{ii});
    end
end
-- даем все привилегии для SCOTT
sqlplus / AS SYSDBA

GRANT ALL PRIVILEGES TO scott;

-- Создаем директорию
--DROP DIRECTORY DB_FILE;

CREATE OR REPLACE DIRECTORY DB_FILE AS 'C:\Oracle\db_file';
-- grant read, write on directory DB_FILE to scott;

SELECT * FROM All_Directories;

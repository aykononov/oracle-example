-- заходми, как SYSDBA
sqlplus / AS SYSDBA

-- даем все привилегии для SCOTT
GRANT ALL PRIVILEGES TO scott;

grant read, write on directory DB_FILE to scott;

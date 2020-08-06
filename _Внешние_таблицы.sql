/* Внешние таблицы */
SELECT * FROM All_Directories;

/* Создаем директорию */
DROP   DIRECTORY IMPEXP_DIR;
/
CREATE DIRECTORY IMPEXP_DIR AS 'C:\TEMP\IMPEXP_DIR'; -- директория на сервере

/* Создаем внешнюю таблицу */
SELECT * FROM IMPEXP_DIR_TAB;
DROP TABLE IMPEXP_DIR_TAB;
/
CREATE TABLE IMPEXP_DIR_TAB
(
c1 VARCHAR2(1000),
c2 VARCHAR2(1000),
c3 VARCHAR2(1000),
c4 VARCHAR2(1000),
c5 VARCHAR2(1000)
)
ORGANIZATION EXTERNAL 
(
--TYPE ORACLE_LOADER -- позволяет только загружать данные в таблицу
--TYPE ORACLE_DATAPUMP -- загружать и выгружать данные
DEFAULT DIRECTORY IMPEXP_DIR
ACCESS PARAMETERS 
(
RECORDS DELIMITED BY NEWLINE
BADFILE log_file_dir:'bad.log'
LOGFILE log_file_dir:'log.log'
FIELDS TERMINATED BY ";" LDRTRIM
MISSING FIELD VALUES ARE NULL
)
LOCATION ('94055.csv')
);

/* Выгрузка данных в файл */
DECLARE
  fHandle UTL_FILE.FILE_TYPE; --используется при каждом открытии файла операционной системы;
BEGIN
    fHandle := UTL_FILE.FOPEN ('IMPEXP_DIR', '94055_exp5.csv', 'w');
  FOR cur IN (select t.c1,t.c2,t.c3,t.c4,t.c5 from IMPEXP_DIR_TAB t) LOOP
    UTL_FILE.PUT_line (fHandle,cur.c1||';'||cur.c2||';'||cur.c3||';'||cur.c4||';'||cur.c5);
  END LOOP;
  UTL_FILE.FCLOSE (fHandle);
END;

SELECT COUNT(*) FROM All_Objects;

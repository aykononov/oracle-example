Вопросы Oracle.

/* Информация об инстансе БД */
SELECT * FROM v$instance;

/* Динамическое представление производительности */
SELECT * FROM v$undostat;

/* Просмотр сегментов */
SELECT v.segment_name, 
       v.segment_type, 
       v.bytes/1024 AS kb,
       v.blocks,
       v.extents,
       v.initial_extent
  FROM User_Segments v;
  
/* Контекст схемы */
SELECT 
        SYS_CONTEXT ( 'userenv', 'AUTHENTICATION_TYPE' ) authent
      , SYS_CONTEXT ( 'userenv', 'CURRENT_SCHEMA' )      curr_schema
      , SYS_CONTEXT ( 'userenv', 'CURRENT_USER' )        curr_user
      , SYS_CONTEXT ( 'userenv', 'CURRENT_USERID' )      current_userid
      , SYS_CONTEXT ( 'userenv', 'DB_NAME' )             db_name
      , SYS_CONTEXT ( 'userenv', 'DB_DOMAIN' )           db_domain
      , SYS_CONTEXT ( 'userenv', 'HOST' )                host
      , SYS_CONTEXT ( 'userenv', 'IP_ADDRESS' )          ip_address
      , SYS_CONTEXT ( 'userenv', 'OS_USER' )             os_user
      , SYS_CONTEXT ( 'userenv', 'GLOBAL_UID')           global_uid
      , SYS_CONTEXT ( 'userenv', 'SESSION_USER')         session_user
      , SYS_CONTEXT ( 'userenv', 'SESSION_USERID')       session_userid               
      , SYS_CONTEXT ( 'userenv', 'SESSIONID')            sessionid
      , SYS_CONTEXT ( 'userenv', 'SID')                  sid
FROM    dual;

/* HINT - добавление к запросу индексной подсказки */
SELECT /*+ INDEX(<table> <имя индекса>) */
/* HINT - использовать созданный индекс для чтения записей из таблицы через индекс */
SELECT /*+ FIRST_ROWS */ t.empno, t.ename, t.hiredate FROM emp t ORDER BY t.empno;

/* Исключения */
DECLARE
   l_Out VARCHAR2(1);
BEGIN
   SELECT '11' INTO l_Out FROM dual;
   dbms_output.put_line(l_Out);
EXCEPTION
   WHEN OTHERS THEN 
     dbms_output.put_line( dbms_utility.format_call_stack || 
                           '----------------------------' || CHR(10) || 
                           dbms_utility.format_error_backtrace || 
                           dbms_utility.format_error_stack);
END;


/* Соглашения при написании кода  */
CREATE OR REPLACE PACKAGE BODY My_PKG AS
  g_Variable VARCHAR2(25); -- g_ - Глобальная переменная
  PROCEDURE My_РRC(p_Variable_IN IN VARCHAR2) IS -- p_ - Параметр
    l_Variable VARCHAR2(25); -- l_ - Локальная переменная
  BEGIN
    NULL;
  END;
END;


/* Обновить или дополнить записи из другой таблицы */
MERGE INTO person p
USING (SELECT tabn, NAME, age  FROM person1) p1
ON (p.tabn = p1.tabn)
WHEN MATCHED THEN
  UPDATE
     SET p.age = p1.age
WHEN NOT MATCHED THEN
  INSERT
    (p.tabn, p.name, p.age)
  VALUES
    (p1.tabn, p1.name, p1.age);
-- записи в Person будут обновлены и дополнены записями из Person1
                                            
/* Специальные символы */
SELECT CHR(34), -- "
       CHR(38), -- &
       CHR(39), -- '
       CHR(10), -- перевод строки
       ASCII('"') -- код 34
  FROM dual;

/* Функция DUMP в Oracle SQL позволяет отображать код типа данных, 
   длину в байтах и внутреннее представление значения данных (и также дополнительно имя набора символов )*/
SELECT 'Дестяичное' AS Представление, DUMP('a') AS "Кодировка" FROM dual
 UNION
SELECT 'Восмеричное',DUMP('a',8) FROM dual
 UNION
SELECT 'Шестнадцатеричное', DUMP('a',16) FROM dual;

 	ПРЕДСТАВЛЕНИЕ	     Кодировка
-------------------  -----------------
1	Восмеричное	       Typ=96 Len=1: 141
2	Дестяичное	       Typ=96 Len=1: 97
3	Шестнадцатеричное	 Typ=96 Len=1: 61

Значения 97, 141 и 61 - это соответствующие АSСII-коды для символа "а" в десятичной, восьмеричной и шестнадцатеричной форме

/* Дополняет справа количеством символов (удобно для генерации и заполнения данных) */
SELECT rpad('++++',12,'*') AS "Заполнено", 
       LENGTH(rpad('++++',12,'*'))AS "Кол символов"
FROM dual;

  Заполнено    Кол символов
--------------  ------------
1 ++++********            12


/* DECODE (функция декодирования) */
SELECT t.ename AS "Имя",
       t.job,
       DECODE  (t.job
               ,'CLERK'   ,'Клерк'
               ,'SALESMAN','Продавец'
               ,'MANAGER' ,'Менеджер'
               ,'ANALYST' ,'Аналитик'
               ,'Другое'  ) AS "Должность"
  FROM SCOTT.emp t
 ORDER BY (2);

   Имя     JOB       Должность
------------------------------
 1 SCOTT   ANALYST   Аналитик
 2 FORD    ANALYST   Аналитик
 3 MILLER  CLERK     Клерк
 4 JAMES   CLERK     Клерк
 5 SMITH   CLERK     Клерк
 6 ADAMS   CLERK     Клерк
 7 BLAKE   MANAGER   Менеджер
 8 JONES   MANAGER   Менеджер
 9 CLARK   MANAGER   Менеджер
10 KING    PRESIDENT Другое
11 TURNER  SALESMAN  Продавец
12 MARTIN  SALESMAN  Продавец
13 WARD    SALESMAN  Продавец
14 ALLEN   SALESMAN  Продавец

/* COALESCE - возвращает первое ненулевое выражение из списка */
SELECT COALESCE(t.comm, 1) AS comm FROM SCOTT.emp t;
COMM
-------
 1    1
 2  300
 3  500
 4    1
 5 1400
 6    1
 7    1
 8    1
 9    1
10    0
11    1
12    1
13    1
14    1

/*  Курсор */
DECLARE
        l_rowCnt NUMBER := 0;

        CURSOR Cur IS
        SELECT /*+ first_rows */ t.empno, t.ename, t.hiredate
          FROM emp t 
         ORDER BY t.empno;
        
        l_recCur Cur%ROWTYPE; -- столбцы из курсора
BEGIN
        OPEN Cur;
        LOOP
             FETCH Cur INTO l_recCur;
             EXIT WHEN cur%NOTFOUND;
             l_rowcnt := l_rowcnt + 1;
             dbms_output.put_line(to_char(l_rowCnt,'09')||' '||
                                  l_recCur.empno||' '||
                                  l_recCur.ename||' '||
                                  TRUNC(l_recCur.hiredate));
         END LOOP;
       CLOSE cur;
END;

/* REF CURSOR курсорная переменная */
DECLARE
  TYPE l_refCur IS REF CURSOR;
  var_refCur    l_refCur;
  v_out         SCOTT.EMP%ROWTYPE;
BEGIN
  OPEN var_refCur FOR
    SELECT t.*
      FROM SCOTT.EMP t;
  LOOP
    FETCH var_refCur
     INTO v_out;
     EXIT WHEN var_refCur%NOTFOUND;
    dbms_output.put_line(v_out.empno||' '||v_out.ename||' '||v_out.hiredate);
  END LOOP;
  CLOSE var_refCur;
END;

/* Интервальные промежутки (10мин) */


/* Предыдущее, Текущее, Следующее  */
WITH t AS
          (SELECT TRUNC(SYSDATE - 1) + LEVEL sdate
             FROM dual
          CONNECT BY LEVEL <= 10
            ORDER BY TRUNC(SYSDATE))
SELECT LAG(t.sdate) OVER(ORDER BY t.sdate)  AS "Предыдущая дата",
       t.sdate                              AS "Текущая дата",
       LEAD(t.sdate) OVER(ORDER BY t.sdate) AS "Следующая дата"
  FROM t;


-- Автоинкремент.
CREATE TABLE t ( id  NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
                 nmr NUMBER(10), text VARCHAR2(10), tdate DATE);
    
/* Иерархические запросы */
  SELECT e.empno, e.ename, e.job, e.mgr,
         PRIOR e.job                     AS by_manager,
         LEVEL                           AS lev,
         connect_by_root e.job           AS by_root,
         sys_connect_by_path(e.job, '/') AS by_path
    FROM SCOTT.EMP e
   START WITH e.mgr IS NULL -- PRESIDENT
 CONNECT BY PRIOR e.empno = e.mgr
   ORDER BY LEVEL;

   EMPNO ENAME   JOB        MGR   BY_MANAGER  LEV  BY_ROOT   BY_PATH
----------------------------------------------------------------------------------------------   
 1 7839  KING    PRESIDENT                    1    PRESIDENT /PRESIDENT
 2 7566  JONES   MANAGER    7839  PRESIDENT   2    PRESIDENT /PRESIDENT/MANAGER
 3 7698  BLAKE   MANAGER    7839  PRESIDENT   2    PRESIDENT /PRESIDENT/MANAGER
 4 7782  CLARK   MANAGER    7839  PRESIDENT   2    PRESIDENT /PRESIDENT/MANAGER
 5 7902  FORD    ANALYST    7566  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/ANALYST
 6 7521  WARD    SALESMAN   7698  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/SALESMAN
 7 7900  JAMES   CLERK      7698  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/CLERK
 8 7934  MILLER  CLERK      7782  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/CLERK
 9 7499  ALLEN   SALESMAN   7698  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/SALESMAN
10 7788  SCOTT   ANALYST    7566  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/ANALYST
11 7654  MARTIN  SALESMAN   7698  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/SALESMAN
12 7844  TURNER  SALESMAN   7698  MANAGER     3    PRESIDENT /PRESIDENT/MANAGER/SALESMAN
13 7876  ADAMS   CLERK      7788  ANALYST     4    PRESIDENT /PRESIDENT/MANAGER/ANALYST/CLERK
14 7369  SMITH   CLERK      7902  ANALYST     4    RESIDENT  /PRESIDENT/MANAGER/ANALYST/CLERK


/* Первые или Последние 10 записей - Oracle 12c */
SELECT *
  FROM pms_pcrf_log
 ORDER BY id ASC -- DESC полседние
 FETCH FIRST 10 ROWS ONLY;
 
/* Последние 5 записей, классика - Oracle 11c */
SELECT rt.*
  FROM (SELECT tab.lev,
               row_number() OVER(ORDER BY (1)) AS rn
          FROM (SELECT LEVEL AS lev
                  FROM dual
               CONNECT BY LEVEL <= 100
                 ORDER BY (1) DESC) tab -- последние 
        ) rt 
 WHERE rt.rn <= 5;

/* Последняя операция */
 SELECT r.*
   FROM (SELECT t.*,
                RANK() OVER(PARTITION BY t.iccid ORDER BY t.request_date DESC) rnk
           FROM pms_rd_ext_sys_log t
          WHERE t.system_name = 'css'
            AND CAST(SUBSTR(t.response, 617, 18) AS VARCHAR2(18)) !=  'Customer not found'
            AND t.request_date >= to_date('01.05.2019', 'dd.mm.yyyy')
        ) r
  WHERE r.rnk = 1;

--Сгенерировать строки с числами Системный тип ODCINumberList VARRAY(32767) OF NUMBER
 SELECT ROWNUM, COLUMN_VALUE, SYSDATE FROM sys.ODCINumberList(10,20,30,40,50);
 SELECT ROWNUM, COLUMN_VALUE, SYSDATE FROM sys.ODCIVarchar2List('A','B','C','D','E');
 SELECT 'A','B','C','D','E' FROM dual;
DECLARE
        iccid sys.odciNumberList := sys.ODCINumberList (10,20,30,40,50);
BEGIN
        FOR x IN iccid.first..iccid.last LOOP
            dbms_output.put_line(iccid(x));
        END LOOP;
END;


-- Создать коллекцию типа таблицы
CREATE OR REPLACE TYPE TEST_NUMBER_TABLE AS TABLE OF NUMBER(20);
-- Выборка из коллекции типа таблицы
SELECT  * FROM TEST_NUMBER_TABLE(1,2,3,4,5,1,2);
--CARDINALITY возвращает число элеметов. Тип возращаемого значения NUMBER.
SELECT CARDINALITY(TEST_NUMBER_TABLE(1,2,3,4,5,1,2)) AS test_count FROM dual;
--SET удаляет дубликаты в наборе данных.
SELECT * FROM TABLE(SET(TEST_NUMBER_TABLE(1,2,3,4,5,1,2)));

/* Использование коллекции типа таблицы */
DECLARE 
        TYPE tabl_t IS TABLE OF NUMBER;
        v_tab_t tabl_t := tabl_t(10,20,30,40,50);
BEGIN
        FOR x IN v_tab_t.first..v_tab_t.last LOOP
            dbms_output.put_line(x ||' '|| v_tab_t(x));
        END LOOP;
END; 

/* пример генерации данных */
WITH t AS (SELECT 'x' AS tex, 2 AS val FROM dual
           UNION ALL SELECT 'y', 3 FROM dual
           UNION ALL SELECT 'z', 4 FROM dual)
SELECT t.*
  FROM t, TABLE(SELECT COLLECT(1) FROM dual CONNECT BY LEVEL <= t.value);   

  TEX VAL
---------
1 x    2
2 x    2
3 y    3
4 y    3
5 y    3
6 z    4
7 z    4
8 z    4
9 z    4

                                                   
                                                   
/* Передача массива в Oracle в качестве входного параметра хранимой процедуры. */
--(1) 
CREATE OR REPLACE TYPE strings_ct AS TABLE OF VARCHAR2(4000);
--(2)
CREATE OR REPLACE PROCEDURE MyProc(in_idset IN my_schema.strings_ct)
--(3)
DECLARE
   inp_data my_schema.strings_ct := my_schema.strings_ct(:p1, :p2, :p3);
BEGIN
   MyProc(inp_data);
END;

/* ПОЛАХАЯ ПРАКТИКА !!!
   Авто COMMIT в цикле, каждые n-строк */
 
DECLARE
        counter PLS_INTEGER DEFAULT 0; -- счетчик 
         vLevel PLS_INTEGER DEFAULT 0; -- общее количество строк
       vCommint PLS_INTEGER DEFAULT 0; -- количество строк для фиксации
BEGIN
         vLevel := 25;
       vCommint := 10;
       
        FOR Curs IN ( SELECT LEVEL FROM dual CONNECT BY LEVEL <= vLevel ) LOOP    
            dbms_output.put_line(Curs.Level ||' UPDATE;');
            counter := counter + 1;

             IF counter = vCommint THEN
                dbms_output.put_line('COMMIT;');
                counter := 0;
            END IF;   

        END LOOP;  
        dbms_output.put_line('LOST COMMIT;');          
END;

/* ПОЛАХАЯ ПРАКТИКА !!!
   Автоподтверждение транзакции через каждые 1000 записей. */
DECLARE
c_limit PLS_INTEGER := 1000;

CURSOR tp_tmp3_cur IS
SELECT element_key
FROM tp_tmp3; -- во временной таблице более 5000 записей
-- определяется ассоциативный массив данных
TYPE tp_tmp3_ids_t IS TABLE OF tp_tmp3.element_key%TYPE;
tp_tmp3_ids tp_tmp3_ids_t;

BEGIN
OPEN tp_tmp3_cur;

LOOP
    FETCH tp_tmp3_cur BULK COLLECT INTO tp_tmp3_ids LIMIT c_limit;
    --This will make sure that every iteration has 1000 records selected

    EXIT WHEN tp_tmp3_ids.COUNT = 0;

    FORALL indx IN 1..tp_tmp3_ids.COUNT SAVE EXCEPTIONS
    UPDATE tp_tmp3 tmp3--Updating 1000 records at 1 go.
    SET tmp3.pool_id = CONCAT('yr_iccid_exclude_', to_char(sysdate, 'yyyy-mm-dd')),
    tmp3.element_type = 4,
    tmp3.element_key = CONCAT('0', tmp3.element_key),
    tmp3.created_at = SYSDATE
    WHERE tmp3.element_key = tp_tmp3_ids(indx);
COMMIT;
END LOOP;

EXCEPTION
WHEN OTHERS THEN
IF SQLCODE = -24381
THEN
    FOR indx IN 1..SQL%BULK_EXCEPTIONS.COUNT
    LOOP
    --Capturing errors occured during update
    DBMS_OUTPUT.put_line (SQL%BULK_EXCEPTIONS (indx).ERROR_INDEX||': '|| SQL%BULK_EXCEPTIONS (indx).ERROR_CODE);
    --<You can inset the error records to a table here>
    END LOOP;
ELSE RAISE;
END IF;
END;



/************* 10.10.2018 Сбер-Технологии ***************/
1) Какой резульат

DECLARE
         t_r1 VARCHAR(2);-- NULL;
         t_r2 VARCHAR(2);-- NULL;
  BEGIN
           IF t_r1 != t_r2 THEN
              dbms_output.put_line('Не равны');
        ELSIF t_r1 = t_r2 THEN
              dbms_output.put_line('Равны');
         ELSE 
              dbms_output.put_line('НЕИЗВЕСТНО');
          END IF;
  END;  

      output
------------
  НЕИЗВЕСТНО

2) Проверка на NULL
SELECT DECODE( NULL
               ,  1
               , 'ONE'
               ,  NULL
               , 'EMPTY' -- Неизвестно это условие будет истинным 
               , 'DEFAULT'
             ) AS res
  FROM dual;

    RES
-------
1	EMPTY


3) Выбрать данные за последние 24 часа и сгруппировать по 17 минут.


4) Индексы 
5) Sequence


-- <CLOB>
SELECT CAST((to_clob('Customer not found') AS VARCHAR2(20) )FROM dual;

select extract(xmltype('<input xmlns="http://google.com/testsystem" 
       xmlns:testsystem="http://test.com/testSystem"          
       xmlns:tns="http://google.com/testService/">
      <ProcessData>      
        <reviewYear>2014-2015</reviewYear>
      </ProcessData>
    </input>'),'/input/ProcessData/reviewYear/text()', 'xmlns="http://google.com/testsystem" xmlns:testsystem="http://test.com/testSystem" xmlns:tns="http://google.com/testService/"').getStringVal() as data 
from dual

для проверки обновлений

select updatexml(xmltype('<input xmlns="http://google.com/testsystem" 
       xmlns:testsystem="http://test.com/testSystem"          
       xmlns:tns="http://google.com/testService/">
       <ProcessData>      
         <reviewYear>2014-2015</reviewYear>
       </ProcessData>
    </input>'), '/input/ProcessData/reviewYear/text()', '2013-2014', 
    'xmlns="http://google.com/testsystem" xmlns:testsystem="http://test.com/testSystem" xmlns:tns="http://google.com/testService/"').getclobval() as data 
from dual


-- MODEL
   SELECT *
     FROM dual
    MODEL DIMENSION BY (0 dimension)
 MEASURES (dummy) 
    RULES (
            dummy[5] = 1,
            dummy[6] = 2,
            dummy[7] = 3
          );


--------------------------------------------------------------------------------------

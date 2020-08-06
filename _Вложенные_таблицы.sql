/* Вложенные таблицы */

Создаем тип сложного объекта.
CREATE OR REPLACE TYPE SCOTT.EMP_TYPE 
AS OBJECT (empno    NUMBER(4),
           ename    VARCHAR2(10),
           job      VARCHAR2(9),
           mgr      NUMBER(4),
           hiredate DATE,
           sal      NUMBER(7,2),
           comm     NUMBER(7,2));

Из него мы создаем тип вложенной таблицы.
CREATE OR REPLACE TYPE SCOTT.EMP_TAB_TYPE 
AS TABLE OF SCOTT.EMP_TYPE;

Далее создаем реальную физическую вложенную таблицу EMPS_NT, отдельную и дополняющую таблицу SCOTT.DEPT_AND_EMP.
CREATE TABLE SCOTT.DEPT_AND_EMP
  (deptno NUMBER(2) PRIMARY KEY,
   dname  VARCHAR2(14),
   loc    VARCHAR2(13),
   emps   SCOTT.EMP_TAB_TYPE)
NESTED TABLE EMPS STORE AS EMPS_NT;

Теперь заполним таблицу SCOTT.DEPT_AND_EMP существующими данными из таблиц ЕМР и DEPT.
MULTISET указывает на то, что подзапрос должен возвращать более одной строки.
Ключевое слово CAST применяется для сообщения Oracle о том, что возвращаемый набор строк 
должен трактоваться как тип коллекции. В этом случае MULTISET с помощью CAST приводится к типу SCOTT.EMP_TAB_TYPE. 

INSERT INTO SCOTT.DEPT_AND_EMP
SELECT SCOTT.DEPT.*,
       CAST(MULTISET(SELECT empno, ename, job, mgr, hiredate, sal, comm
                       FROM SCOTT.EMP
                      WHERE EMP.Deptno = DEPT.Deptno) AS emp_tab_type)
  FROM SCOTT.DEPT;


SELECT * FROM SCOTT.DEPT_AND_EMP;

  DEPTNO  DNAME       LOC       EMPS
--------------------------------------------
1 10      ACCOUNTING  NEW YORK  <Collection>...
2 20      RESEARCH    DALLAS    <Collection>...
3 30      SALES       CHICAGO   <Collection>...
4 40      OPERATIONS  BOSTON    <Collection>...

Все данные здесь находятся в единственном столбце EMPS.
Oracle может привести столбец EMPS к типу таблицы с отменой вложенности.

SELECT d.deptno, d.dname, emp.* FROM SCOTT.DEPT_AND_EMP d, TABLE(d.emps) emp;

    DEPTNO  DNAME       EMPNO ENAME  JOB       MGR   HIREDATE    SAL      COMM
---------------------------------------------------------------------------------    
 1  10      ACCOUNTING  7782  CLARK  MANAGER   7839  09.06.1981  2450,00 
 2  10      ACCOUNTING  7839  KING   PRESIDENT       17.11.1981  5000,00 
 3  10      ACCOUNTING  7934  MILLER CLERK     7782  23.01.1982  1300,00 
 4  20      RESEARCH    7369  SMITH  CLERK     7902  17.12.1980   800,00  
 5  20      RESEARCH    7566  JONES  MANAGER   7839  02.04.1981  2975,00 
 6  20      RESEARCH    7788  SCOTT  ANALYST   7566  09.12.1982  3000,00 
 7  20      RESEARCH    7876  ADAMS  CLERK     7788  12.01.1983  1100,00 
 8  20      RESEARCH    7902  FORD   ANALYST   7566  03.12.1981  3000,00 
 9  30      SALES       7499  ALLEN  SALESMAN  7698  20.02.1981  1600,00   300,00
10  30      SALES       7521  WARD   SALESMAN  7698  22.02.1981  1250,00   500,00
11  30      SALES       7654  MARTIN SALESMAN  7698  28.09.1981  1250,00  1400,00
12  30      SALES       7698  BLAKE  MANAGER   7839  01.05.1981  2850,00 
13  30      SALES       7844  TURNER SALESMAN  7698  08.09.1981  1500,00     0,00
14  30      SALES       7900  JAMES  CLERK     7698  03.12.1981   950,00  

Обновление данных. 
Допустимм, что требуется выдать отделу 10 премию в сумме $ 100.
 
UPDATE TABLE (SELECT emps
                FROM dept_and_emp
               WHERE deptno = 10)
   SET comm = 100;

Вместо обычной таблицы EMPS_NT мы создадим индекс-таблицу EMPS_NT, 
на что указывает наложенная поверх нее структура индекса.

CREATE TABLE SCOTT.DEPT_AND_ЕМР
  (deptno NUMBER(2),
   dname  VARCHAR2(14),
   loc    VARCHAR2(13),
   emps   SCOTT.EMP_TAB_TYPE)
 PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
TABLE SPACE USERS
NESTED TABLE EMPS STORE AS EMPS_NT
( (empno NOT NULL, UNIQUE (empno), PRIMARY KEY (nested_table_id, empno))
  ORGANIZATION INDEX COMPRESS 1 )
RETURN AS VALUE; 

Когда таблица EMPS_NT представляет собой индекс-таблицу, использующую сжатие, 
она будет занимать меньше места, чем первоначальная стандартная вложенная
таблица, и будет иметь индекс, в котором мы крайне нуждаемся.

/* ОЧИСТКА */
DROP TABLE SCOTT.DEPT_AND_EMP PURGE;
DROP TYPE SCOTT.EMP_TAB_TYPE;
DROP TYPE SCOTT.EMP_TYPE;

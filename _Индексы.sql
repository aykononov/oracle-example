/* Индексы */


CREATE TABLE SCOTT.T AS SELECT * FROM ALL_OBJECTS WHERE ROWNUM <= 50000;

ОБЫЧНЫЙ ИНДЕКС (В-ДЕРЕВА).
 Эффективность наступает при обращении к данным значительно меньшем (0,5% - 5%) от общего объема.

CREATE INDEX t_idx ON t(owner,object_type,object_name);

ANALYZE INDEX t_idx VALIDATE STRUCTURE;

Затем создадим таблицу IDX_STATS, в которой будет храниться информация
INDEX_STATS, и пометим строки в этой таблице как noncompressed (несжатые):

CREATE TABLE IDX_STATS AS SELECT 'noncompressed' what, a.* FROM index_stats a;


SELECT 90101, DUMP(90101,16) FROM dual;

БИТОВЫЙ ИНДЕКС.
 Не предназначены для систем OLTP или систем, где данные часто обновляются многочисленными параллельными сеансами.
 Битовые индексы чрезвычайно удобны в средах, где происходит много нерегламентированных запросов, особенно запросов, 
 которые ссылаются на множество столбцов произвольным образом или вычисляют агрегаты вроде COUNT . 
 Они хорошо работают в среде с интенсивным чтением, но очень плохо ведут себя в среде с интенсивной записью.
 Причина в том, что одиночная запись ключа битового и ндекса указывает на множество строк. Если сеанс модифицирует 
 проиндексированные данные, то все строки, на которые указывает запись индекса, в большинстве случаев блокируются.
 Любые другие модификации, которым необходимо обновить ту же самую запись битового индекса, будут заблокированы.

CREATE BITMAP INDEX job_idx ON SCOTT.EMP(job);

Cгенерируем тестовые данные, удовлетворяющие низкой кардинальности, проиндексируем их и соберем статистику.

CREATE TABLE SCOTT.T
(
 gender    NOT NULL,
 locations NOT NULL,
 age_group NOT NULL,
 DATA
) AS
SELECT DECODE(ROUND(dbms_random.value(1,2)),
                                      1,'M',
                                      2,'F') AS gender,
       CEIL(dbms_random.value(1,50))         AS locations,
       DECODE(ROUND(dbms_random.value(1,5)),
                                      1,'18 and under',
                                      2,'19-25',
                                      3,'26-30',
                                      4,'31-40',
                                      5,'41 and over'),
       RPAD('*',20,'*')
  FROM dual CONNECT BY LEVEL <= 100000;

CREATE BITMAP INDEX gender_idx ON T(gender);
CREATE BITMAP INDEX locations_idx ON T(locations);
CREATE BITMAP INDEX age_group_idx ON T(age_group);

BEGIN dbms_stats.gather_table_stats(USER,'T'); END;

Теперь взглянем на планы выполнения показанных ранее специальных запросов:

SELECT COUNT(*)
  FROM SCOTT.T
 WHERE gender = 'M'
   AND locations IN (1,10,30)
   AND age_group = '41 and over';

Этот пример демонстрирует мощь битовых индексов. База данных Oracle способна увидеть конструкцию 
locations in (1,10,30) и знает, что нужно прочитать индекс на столбце locations для этих трех значений 
и с помощью логической операции OR объединить "биты" в битовой карте. Затем она берет результирующую 
битовую карту и посредством логической операции AND складывает ее с битовыми картами для age_group = '41 and over' и gender = 'M' . 
После этого Oracle просто подсчитывает единичные биты - и ответ готов. 

Plan Hash Value  : 554872360 
------------------------------------------------------------------------------------------
| Id  | Operation                       | Name          | Rows | Bytes | Cost | Time     |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                |               |    1 |    13 |    9 | 00:00:01 |
|   1 |   SORT AGGREGATE                |               |    1 |    13 |      |          |
|   2 |    BITMAP CONVERSION COUNT      |               |  608 |  7904 |    9 | 00:00:01 |
|   3 |     BITMAP AND                  |               |      |       |      |          |
|   4 |      BITMAP OR                  |               |      |       |      |          |
| * 5 |       BITMAP INDEX SINGLE VALUE | LOCATIONS_IDX |      |       |      |          |
| * 6 |       BITMAP INDEX SINGLE VALUE | LOCATIONS_IDX |      |       |      |          |
| * 7 |       BITMAP INDEX SINGLE VALUE | LOCATIONS_IDX |      |       |      |          |
| * 8 |      BITMAP INDEX SINGLE VALUE  | AGE_GROUP_IDX |      |       |      |          |
| * 9 |      BITMAP INDEX SINGLE VALUE  | GENDER_IDX    |      |       |      |          |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 5 - access("LOCATIONS"=1)
* 6 - access("LOCATIONS"=10)
* 7 - access("LOCATIONS"=30)
* 8 - access("AGE_GROUP"='41 and over')
* 9 - access("GENDER"='M')

В хранилище данных или крупной системе генерации отчетов, поддерживающей много нерегламентированных SQL-запросов, 
возможность совместного использования такого количества индексов, какое имеет смысл, на самом деле становится очень полезной. 
Применение в этом случае обычных индексов со структурой В-дерева даже близко не сравнится по удобству и эффективности, 
и по мере роста числа столбцов, по которым производится поиск в нерегламентированных запросах,
увеличивается также и количество необходимых комбинаций индексов со структурой В-дерева. 

/* Информация по индексам */
Фактор кластеризации можно также рассматривать как число, представляющее КОЛИЧЕСТВО ЛОГИЧЕСКИХ ОПЕРАЦИЙ ВВОДА-ВЫВОДА в таблице, 
которые должны быть выполнены для чтения всей таблицы через индекс.

SELECT ui.index_name, ui.index_type, ui.last_analyzed, ut.num_rows, ut.blocks, ui.clustering_factor
  FROM USER_INDEXES ui, USER_TABLES ut
 WHERE ui.table_name = ut.table_name
 ORDER BY ui.index_name;
 
   INDEX_NAME    INDEX_TYPE LAST_ANALYZED       NUM_ROWS BLOCKS CLUSTERING_FACTOR
---------------- ---------- ------------------- -------- ------ -----------------
1  AGE_GROUP_IDX BITMAP     17.03.2020 18:57:33 100000   535                   23
2  GENDER_IDX    BITMAP     17.03.2020 18:57:33 100000   535                   10
3  LOCATIONS_IDX BITMAP     17.03.2020 18:57:33 100000   535                   49
4  SYS_C00171904 NORMAL     13.03.2020 09:11:32     14     1                    1
5  SYS_C00171905 NORMAL     13.03.2020 08:57:43      4     1                    1


БИТОВЫЕ ИНДЕКСЫ СОЕДИНЕНИЙ.
  Индекс создается на одиночной таблице с использованием столбцов только из этой таблицы.
  Это предоставляет возможность денормализации данных в индексной структуре вместо того, 
  чтобы проводить денормализацию в самих таблицах (разумеется, в системе, отличной от OLTP).  

Посмотрим план для следующего запроса:

SELECT COUNT(*)
  FROM SCOTT.EMP e, SCOTT.DEPT d
 WHERE e.deptno = d.deptno
   AND d.dname = 'SALES';

Plan Hash Value  : 1546158010 
-----------------------------------------------------------------------
| Id  | Operation             | Name | Rows | Bytes | Cost | Time     |
-----------------------------------------------------------------------
|   0 | SELECT STATEMENT      |      |    1 |    16 |    5 | 00:00:01 |
|   1 |   SORT AGGREGATE      |      |    1 |    16 |      |          |
| * 2 |    HASH JOIN          |      |    5 |    80 |    5 | 00:00:01 |
| * 3 |     TABLE ACCESS FULL | DEPT |    1 |    13 |    2 | 00:00:01 |
|   4 |     TABLE ACCESS FULL | EMP  |   14 |    42 |    2 | 00:00:01 |
-----------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 2 - access("E"."DEPTNO"="D"."DEPTNO")
* 3 - filter("D"."DNAME"='SALES')

Создадим инндекс:

 CREATE BITMAP INDEX emp_bm_idx
     ON SCOTT.EMP(d.dname)         -- Мы видим ссылку на столбец в таблице DEPT:d.dnaмe
   FROM SCOTT.EMP е, SCOTT.DEPT d  -- Конструкция FROM, которая делает этот оператор CREATE INDEX напоминающим запрос.
  WHERE е.deptno = d.deptno;       -- Мы и меем условие соединения между несколькими таблицами.

Посмотрим план для следующего запроса:

SELECT COUNT(*)
  FROM SCOTT.EMP e, SCOTT.DEPT d
 WHERE e.deptno = d.deptno
   AND d.dname = 'SALES';

Plan Hash Value  : 2538954156 
-------------------------------------------------------------------------------------
| Id  | Operation                     | Name       | Rows | Bytes | Cost | Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT              |            |    1 |     3 |    1 | 00:00:01 |
|   1 |   SORT AGGREGATE              |            |    1 |     3 |      |          |
|   2 |    BITMAP CONVERSION COUNT    |            |    5 |    15 |    1 | 00:00:01 |
| * 3 |     BITMAP INDEX SINGLE VALUE | EMP_BM_IDX |      |       |      |          |
-------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
------------------------------------------
* 3 - access("E"."SYS_NC00009$"='SALES')

Только путем экспериментирования можно определить, насколько полезен битовый индекс в конкретном случае!!!

ИНДЕКСЫ НА ОСНОВЕ ФУНКЦИЙ.
   И ндексы на основе функций легко создавать и использовать, и они предоставляют немедленное значение. 
 Они могут применяться для ускорения существующих приложений без изменения их логики или запросов. 
 При этом могут наблюдаться существенные усовершенствования. Их можно использовать для предварительного
 вычисления сложных значений, не прибегая к триггерам. Вдобавок оптимизатор может более точно оценивать селективность, 
 если выражения реализованы в индексе на основе функции. И ндексы на основе функций можно применять для избирательной 
 индексации только тех строк, которые представляют интерес.

   И ндексы на основе функций будут влиять на производительность вставок и обновлений. С другой стороны, имейте в виду, что
 вставка строки обычно производится однажды, а ее запрос - тысячи раз. Снижение производительности при вставке 
(которое конечные пользователи, возможно, никогда не заметят) может быть тысячекратно перекрыто ускорением запросов.

НЕВИДИМЫЕ ИНДЕКСЫ.
 Невидимые индексы являются невидимыми только в том смысле, что оптимизатор не рассматривает их применение 
 при генерации планов выполнения, если только он не проинструктирован о необходимости их использовать. 
 
 Итак, в чем состоит польза от невидимых индексов? Такие индексы все равно будут поддерживаться (отсюда и снижение 
 производительности), но не могут использоваться запросами, которые не способны видеть их (поэтому производительность никогда 
 не повышается). Одним примерам может служить ситуация, когда вы хотите удалить индекс в производственной системе. 
 Идея заключается в том, что вы можете сделать индекс невидимым и посмотреть, не пострадала ли в результате производительность. 
 В этом случае перед удалением и ндекса важно также проверить, не размещен ли он на столбце внешнего ключа либо не задействован ли 
 он для принудительного применения ограничения уникальности. Другой пример связан с необходимостью добавления индекса в 
 производственной системе и прогона тестов, чтобы выяснить, улучшилась ли производительность. Вы можете добавить индекс как 
 невидимый и выборочно сделать его видимым на протяжении сеанса, чтобы определить пользу от него. И снова вы должны помнить о том, 
 что хотя индекс является невидимым, он будет занимать пространство и требовать ресурсов для поддержания. 

ВОПРОСЫ.

Работают ли индексы в представлениях?
  Любые индексы, которые могли использоваться в запросе, написанном в отношении к базовым таблицам, будут учитываться 
  во время применения представления. Чтобы проиндексировать представление , нужно просто проиндексировать его базовые таблицы.

Могут ли значения NULL и индексы работать вместе?
  Индексы со структурой В-дерева, за исключением особого случая кластерных индексов со структурой В-дерева, не хранят записи,
  содержащие NULL, но битовые и кластерные индексы сохраняют их. Чтобы увидеть влияние от того факта, что значения NULL не сохраняются , 
  рассмотрим следующий пример:

CREATE TABLE SCOTT.T (x INT, y INT);
CREATE UNIQUE INDEX t_idx ON SCOTT.T (x,y);
INSERT INTO SCOTT.T VALUES(1,1);
INSERT INTO SCOTT.T VALUES(1,NULL);
INSERT INTO SCOTT.T VALUES(NULL,1);
INSERT INTO SCOTT.T VALUES(NULL,NULL);
-- проанализируем индекс
ANALYZE INDEX t_idx VALIDATE STRUCTURE;


SELECT NAME, lf_rows FROM Index_Stats;

 	NAME	LF_ROWS
------- -------
1	T_IDX	     3

Таблица имеет четыре строки, тогда как индекс - только три. Первые три строки, в которых хотя бы один элемент ключа индекса 
не равен NULL, находятся в индексе. Последняя строка со значениями ( NULL , NULL ) в индекс не попадает.
Это то, что следует принимать во внимание: каждое ограничение уникальности ДОЛЖНО ИМЕТЬ, ПО МЕНЬШЕЙ МЕРЕ, ОДИН СТОЛБЕЦ NOT NULL, 
чтобы быть по-настоящему УНИКАЛЬНЫМ. 
                    
/* Очистка */
DROP TABLE SCOTT.T PURGE;
DROP TABLE IDX_STATS PURGE;
DROP INDEX emp_bm_idx;


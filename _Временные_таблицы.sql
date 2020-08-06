/* Временные таблицы */
   
   Временные таблицы Oracle похожи на временные таблицы в других реляционных базах данных, 
но с важным отличием: они определяются статически. 
Вы создаете их один раз для базы данных, а не один раз для каждой хранимой процедуры в этой базе данных. 
Временные таблицы существуют всегда - они будут присутствовать в словаре данных как объекты, но будут 
всегда выглядеть nустыми до тех пор, пока ваш сеанс не поместит в них данные. 
Тот факт, что они определены статически, позволяет создавать представления, которые ссылаются на них, 
хранимые nроцедуры, которые используют статический SQL для ссылки на них, и т.д.
   Временные таблицы могут быть основаны на сеансе (данные сохраняются в таблице между фиксациями, 
но не между отключением и повторным подключением).
   Временные таблицы также могут быть основаны на транзакции (данные исчезают после фиксации). 
Ниже приведен nример того и другого поведения. В качестве шаблона применяется таблица SCOTT.EMP.

CREATE GLOBAL TEMPORARY TABLE TEMP_TABLE_SESSION
ON COMMIT PRESERVE ROWS
AS SELECT * FROM SCOTT.EMP WHERE 1=0;

Конструкция ON COMMIT PRESERVE ROWS делает временную таблицу основанной на сеансе. 
Строки будут оставаться в этой таблице до тех пор, пока сеанс не отключится или пока 
они не будут физически удалены с помощью DELETE или TRUNCATE . Эти строки доступны только текущему сеансу, 
никакой другой сеанс не будет их видеть даже после выполнения фиксации.

CREATE GLOBAL TEMPORARY TABLE TEMP_TABLE_TRANSACTION
ON COMMIT DELETE ROWS
AS SELECT * FROM SCOTT.EMP WHERE 1=0;

Конструкция ON COMMIT DELETE ROWS делает временную таблицу основанной на транзакции. 
Когда сеанс производит фиксацию, строки исчезают. Строки пропадают за счет возвращения обратно временных экстентов, 
выделенных для таблицы - никаких накладных расходов с автоматической очисткой временных таблиц не связано. 
Теперь давайте посмотрим на отличия между этими двумя типами таблиц:

INSERT INTO TEMP_TABLE_SESSION SELECT * FROM SCOTT.EMP;
SELECT * FROM TEMP_TABLE_SESSION;

INSERT INTO TEMP_TABLE_TRANSACTION SELECT * FROM SCOTT.EMP;
SELECT * FROM TEMP_TABLE_TRANSACTION;

В каждую из двух временных таблиц помещено по 14 строк, и мы можем в этом убедиться:

SELECT session_cnt, transaction_cnt
  FROM (SELECT COUNT(*) session_cnt FROM TEMP_TABLE_SESSION),
       (SELECT COUNT(*) transaction_cnt FROM TEMP_TABLE_TRANSACTION);

 	SESSION_CNT	TRANSACTION_CNT
-----------------------------
1	         14	             14

COMMIT;

Так как произведена фиксация, мы увидим строки во временной таблице, основанной на сеансе, 
но не строки во временной таблице, основанной на транзакции: 

SELECT session_cnt, transaction_cnt
  FROM (SELECT COUNT(*) session_cnt FROM TEMP_TABLE_SESSION),
       (SELECT COUNT(*) transaction_cnt FROM TEMP_TABLE_TRANSACTION);
       
 	SESSION_CNT	TRANSACTION_CNT
-----------------------------
1	         14	              0

Чтобы проверить, была ли таблица создана как временная, а также продолжительность хранения данных в ней 
(в течение сеанса или транзакции), можно запросить:

SELECT table_name, temporary, duration FROM USER_TABLES;

  TABLE_NAME              TEMPORARY  DURATION
----------------------------------------------------  
1 EMP                     N 
2 DEPT                    N 
3 TEMP_TABLE_SESSION      Y          SYS$SESSION
4 TEMP_TABLE_TRANSACTION  Y          SYS$TRANSACTION


/* ОЧИСТКА */
DROP TABLE SCOTT.TEMP_TABLE_SESSION PURGE;
DROP TABLE SCOTT.TEMP_TABLE_TRANSACTION PURGE;

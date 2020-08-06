/* ERROR_LOG */

Единственным по-настоящему допустимым использованием Автономных Транзакций является Протоколирование Ошибок!!!

Создадим таблицу Протоколирование Ошибок
CREATE TABLE SCOTT.ERROR_LOG (ts   TIMESTAMP,
                              err1 CLOB,
                              err2 CLOB );
Создадим процедуру Протоколирование Ошибок
CREATE OR REPLACE PROCEDURE SCOTT.Log_Error_PRC 
       (p_Err1 IN VARCHAR2, p_Err2 IN VARCHAR2) 
    IS
       PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO SCOTT.ERROR_LOG (ts, err1, err2)
  VALUES (SYSTIMESTAMP, p_Err1, p_Err2);
  COMMIT;
END;

Выполним тетсирование.

CREATE TABLE SCOTT.T (x INT CHECK (x > 0));

Создадим пару процедур, которые будут вызывать друг друга: 

CREATE OR REPLACE PROCEDURE  SCOTT.p1 (p_n IN NUMBER)
    IS
 BEGIN
       INSERT INTO t(x) VALUES(p_n);
   END;

CREATE OR REPLACE PROCEDURE SCOTT.p2 (p_n NUMBER)
    IS
 BEGIN
       SCOTT.p1(p_n);
   END;

Теперь вызовем эти процедуры из анонимного блока:
BEGIN
  SCOTT.p2(1);
  SCOTT.p2(2);
  SCOTT.p2(-1);
  EXCEPTION
    WHEN OTHERS THEN
      SCOTT.Log_Error_PRC(SQLERRM, dbms_utility.format_error_backtrace);
      RAISE;
END;

SELECT * FROM SCOTT.t;

ROLLBACK;

Можно убедиться, что информация в журнале ошибок сохранена и зафиксирована.

SELECT * FROM SCOTT.ERROR_LOG;
	TS	                      ERR1	  ERR2
------------------------------------------
1	20.02.20 14:25:45,272807	<CLOB>	<CLOB>

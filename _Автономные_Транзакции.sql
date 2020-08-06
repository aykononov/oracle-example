/* Автономные транзакции */

Прагма (pragma) сообщает базе данных, что процедура должна выполняться 
как новая автономная транзакция, не зависящая от ее родительской транзакции.

CREATE TABLE SCOTT.T(msg VARCHAR2(25));

CREATE OR REPLACE PROCEDURE SCOTT.Autonomous_Insert IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO t VALUES ('Autonomous_Insert');
  COMMIT;
END;

CREATE OR REPLACE PROCEDURE SCOTT.NonAutonomous_Insert IS
BEGIN
  INSERT INTO t VALUES ('NonAutonomous_Insert');
  COMMIT;
END;

Как видите, работа, выполненная анонимным блоком (его оператор INSERT) 
была зафиксирована процедурой 'SCOTT.NonAutonomous_Insert' . 
Зафиксированы обе строки данных, так что команде ROLLBACK откатывать нечего.

BEGIN
  INSERT INTO t VALUES ('Anonymous_Block');
  SCOTT.NONAUTONOMOUS_INSERT;
  ROLLBACK;
END;

SELECT * FROM SCOTT.T;
MSG
----------------------
1 Anonymous_Block
2 NonAutonomous_Insert

--------------------------------------------------------------------------

DELETE FROM SCOTT.T;

Здесь сохраняется только работа, сделанная и зафиксированная в автономной транзакции. 
Оператор INSERT, выполненный в анонимном блоке, откатывается оператором ROLLBACK в строке 4. 
Оператор COMMIT процедуры Автономной Транзакции не оказывает никакого воздействия на родительскую транзакцию, 
которая стартовала в Анонимном блоке.

BEGIN
  INSERT INTO t VALUES ('Anonymous_Block');
  SCOTT.AUTONOMOUS_INSERT;
  ROLLBACK;
END;

SELECT * FROM SCOTT.T;
MSG
----------------------
1 Autonomous_Insert

Вывод.
Если выполняется оператор COMMIT внутри "нормальной" процедуры, то он касается не только ее собственной работы, 
но также всей незавершенной работы, произведенной в данном сеансе. Тем не менее, оператор COMMIT, выполненный 
в процедуре с Автономной Транзакцией, распространяется только на работу этой процедуры.

-----------------------------------------------------------------------------
/* Логирование */
CREATE TABLE logtab 
(
  ID NUMBER, code INTEGER, text VARCHAR2(4000), created_on DATE, created_by VARCHAR2(100), changed_on DATE, changed_by VARCHAR2(100)
);

CREATE OR REPLACE PACKAGE logtab_pkg IS
PROCEDURE putline  (code_in IN INTEGER, text_in IN VARCHAR2);
PROCEDURE saveline (code_in IN INTEGER, text_in IN VARCHAR2);
END;
/
CREATE OR REPLACE PACKAGE BODY logtab_pkg IS
   PROCEDURE putline (
      code_in IN INTEGER, text_in IN VARCHAR2)
   IS
   BEGIN
      INSERT INTO logtab VALUES ( code_in, text_in,
         SYSDATE,
         USER,
         SYSDATE,
         USER
      );
   END;

   PROCEDURE saveline (
      code_in IN INTEGER, text_in IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      putline (code_in, text_in);
      COMMIT;
      EXCEPTION WHEN OTHERS THEN ROLLBACK;
   END;
END;

EXCEPTION
   WHEN OTHERS THEN
   logtab_pkg.saveline (SQLCODE, SQLERRM);
END;

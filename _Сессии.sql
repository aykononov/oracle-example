/* Посмотреть текущие сессии к базе данных. */
 SELECT t.SID, t.SERIAL#, t.osuser as "User", t.MACHINE as "PC", t.PROGRAM as "Program"
   FROM v$session t
--WHERE (NLS_LOWER(t.PROGRAM) = 'cash.exe') -- посмотреть сессии от программы cash.exe
--WHERE status='ACTIVE' and osuser!='SYSTEM' -- посмотреть пользовательские сессии
--WHERE username = 'схема' -- посмотреть сессии к схеме (пользователь)
  ORDER BY 4 ASC;

/* Найти блокирующую сессию. */
SELECT status, SECONDS_IN_WAIT, BLOCKING_SESSION, SEQ#
  FROM v$session
 WHERE username= upper('scott');

/* Убить сессию. */
ALTER SYSTEM KILL SESSION 'SID,Serial#' IMMEDIATE;
--Заменить ‘SID’ и ‘Serial#’ на текущие значения сессии.

/* Убийство всех сессий к определенной схеме. */
define USERNAME = "USER_NAME"

begin
  for i in (select SID, SERIAL# from V$SESSION where USERNAME = upper('&&USERNAME')) loop
    execute immediate 'alter system kill session '''||i.SID||','||i.SERIAL#||''' immediate';
   end loop;
end;
/

/* 
   ORA-01427: подзапрос одиночной строки возвращает более одной строки!!!
   Лучше использовать запрос вида:
*/
SELECT
       (SELECT DECODE(COUNT(*), 0,NULL, 1,MAX(t2.column), 'ORA-01427')
          FROM table2
         WHERE ...)
  FROM table1 t1
 WHERE ...

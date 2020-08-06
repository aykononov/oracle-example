/* Ассоциативный массив */
DECLARE
  -- Создаем тип ассоциативного массива,
  -- где ЗНАЧЕНИЕ = SCOTT.EMP.ename%TYPE, а PLS_INTEGER это ключ.
  TYPE ENAME_T IS TABLE OF SCOTT.EMP.ename%TYPE INDEX BY PLS_INTEGER;
  TYPE LOC_T   IS TABLE OF SCOTT.DEPT.loc%TYPE  INDEX BY PLS_INTEGER;
  -- Объявление колллекции на базе типа.
  l_ename_t ENAME_T;
  l_loc_t   LOC_T;

  l_row PLS_INTEGER;

  -- Объявление курсора
  CURSOR ename_loc_cur IS
    SELECT e.ename,
           d.loc
      FROM SCOTT.EMP  e,
           SCOTT.DEPT d
     WHERE e.deptno = d.deptno;

BEGIN
  -- Заполнение колллекции
  FOR i IN ename_loc_cur
  LOOP
    l_ename_t(ename_loc_cur%ROWCOUNT) := i.ename;
  
    l_loc_t(ename_loc_cur%ROWCOUNT) := i.loc;
  END LOOP;

  -- Первый индекс колллекции (1)
  l_row := l_ename_t.FIRST;

  dbms_output.put_line(rpad('   ENAME', 10, ' ') || 'LOCATION');
  dbms_output.put_line('-------------------');

  -- Вывод коллекции
  WHILE (l_row IS NOT NULL)
  LOOP
    dbms_output.put_line(lpad(l_row, 2, ' ') || ' ' ||
                         rpad(l_ename_t(l_row), 7, ' ') || l_loc_t(l_row));
    l_row := l_ename_t.NEXT(l_row);
  END LOOP;
END;

   ENAME  LOCATION
-------------------
 1 SMITH  DALLAS
 2 ALLEN  CHICAGO
 3 WARD   CHICAGO
 4 JONES  DALLAS
 5 MARTIN CHICAGO
 6 BLAKE  CHICAGO
 7 CLARK  NEW YORK
 8 SCOTT  DALLAS
 9 KING   NEW YORK
10 TURNER CHICAGO
11 ADAMS  DALLAS
12 JAMES  CHICAGO
13 FORD   DALLAS
14 MILLER NEW YORK

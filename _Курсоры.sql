/* Курсор с параметрами */
DECLARE
  CURSOR A(c_tab IN VARCHAR2) IS
    SELECT TABLE_NAME
      FROM USER_TABLES
     WHERE TABLE_NAME LIKE c_tab;
  l_table VARCHAR2(30);
BEGIN
  OPEN A(c_tab => 'A%');
  LOOP
    FETCH A
      INTO l_table;
    EXIT WHEN A%NOTFOUND;
    dbms_output.put_line(l_table);
  END LOOP;
  CLOSE A;
END;

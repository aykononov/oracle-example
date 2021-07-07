/* Каскадное удаление всех пользователей по маске */
BEGIN
  FOR i IN (
    SELECT t.username
    FROM DBA_USERS t
    WHERE t.username LIKE 'WIN%') 
  LOOP
    EXECUTE IMMEDIATE 'DROP USER '|| i.username || ' CASCADE';
  END LOOP;
 EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line(sqlerrm);
END;
/

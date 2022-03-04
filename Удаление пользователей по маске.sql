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

-- Смотрим пользователей(схемы)
SELECT t.user_id, t.username, t.account_status, t.created
FROM DBA_USERS t
WHERE t.username LIKE 'INTEGRATION_TEST_%'
  AND TRUNC(t.created) <= TRUNC(SYSDATE)
ORDER BY t.created DESC;

-- Удаление пользователей по маске
BEGIN
    FOR i IN (SELECT t.username
              FROM DBA_USERS t
              WHERE t.username LIKE 'INTEGRATION_TEST_%'
                AND TRUNC(t.created) <= TRUNC(SYSDATE))
        LOOP
            EXECUTE IMMEDIATE 'DROP USER ' || i.username || ' CASCADE';
        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
END;

/*
SELECT 'DROP USER ' || username || ' CASCADE;', t.*
FROM All_Users t
WHERE t.username LIKE 'INTEGRATION_TEST_%'
  AND TRUNC(t.created) < TRUNC(SYSDATE)
ORDER BY t.created DESC;
*/

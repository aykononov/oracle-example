/*
  Внешнее соединение (+)
*/

Человек старой закалки (кто видел СУБД Oracle версии меньше чем 9) на вопрос о внешнем соединении в SQL запросе уверенно ответит, что где то нужно поставить "плюсик".
И это правда. 
Не смотря на появившийся в 9-й версии синтаксис ANSI для внешних соединений, "плюсик" привычнее и роднее. Вот, только, не всегда помнишь куда ж его нужно поставить. Собственно далее идет памятка о постановке "плюсика" во внешнем соединении.
Предположим есть у нас две таблицы: FND_USER и HR_EMPLOYEES. Вообще-то, HR_EMPLOYEES это view, но пусть для упрощения немного побудет таблицей. Соединяются они по столбцу EMPLOYEE_ID, который присутствует в обеих. Причем в HR_EMPLOYEES это еще и первичный ключ, а в FND_USER этот столбец не является обязательным.
Соединение этих таблиц в запросе выглядит так:

SELECT fu.*
      ,he.*
  FROM hr_employees he
      ,fnd_user fu
 WHERE he.employee_id = fu.employee_id

А теперь вопрос.
Где же ставить "плюсик"?
Ответ оказывается не однозначным и всё зависит от того, что мы хотим получить в запросе.

Допустим, нам нужно для ряда пользователей (скажем, имя которых начинается с 'S') определить их Фамилию Имя Отчество. Информация о ФИО содержится в столбце HR_EMPLOYEES.full_name
В этом случае запрос будет выглядеть так:

SELECT fu.user_name
      ,he.full_name
  FROM hr_employees he
      ,fnd_user fu
 WHERE he.employee_id(+) = fu.employee_id
   AND fu.user_name LIKE 'S%'

Правило гласящее о том, что "плюсик" ставится с той стороны где может отсутствовать значение, иногда вводит в заблуждение.

Ведь в таблице HR_EMPLOYEES столбец employee_id является первичным ключом, и значение в нем отсутствовать не может в принципе. Однако "плюсик" нужно поставить именно с этой стороны.
В чём же дело.
В данном случае, мы говорим о том, что в указанной постановке задачи (для пользователя найти ФИО) таблица FND_USER "главнее". Мы изначально имеем дело со списком пользователей, для части из которых, нужно найти дополнительную информацию (ФИО), если она существует.
Почему она может не существовать?
Да потому, что у пользователя в таблице FND_USER может отсутствовать значение в столбце EMPLOYEE_ID. Значит для ряда записей в FND_USER (где employee_id IS NULL) в HR_EMPLOYEES можно ничего и не искать. Именно поэтому "плюсик" ставится со стороны таблицы HR_EMPLOYEES

Кстати.
Аналогом этого запроса является:

SELECT fu.user_name
      ,(SELECT he.full_name
          FROM hr_employees he
         WHERE he.employee_id = fu.employee_id)
  FROM fnd_user fu
 WHERE fu.user_name LIKE 'S%'

В таком виде наиболее очевидно, что справочник пользователей "главнее". Ведь FND_USER единственная таблица во фразе FROM. А информация о ФИО вытаскивается подзапросом, который либо её найдет, либо нет.
Основным минусом такого запроса является то, что подзапрос позволяет вернуть только одно значение. А ведь нас могло бы интересовать не только full_name, но и employee_num, creation_date и т.д.

Другая ситуация.
Для ряда сотрудников, у которых фамилия начинается на 'А' нужно найти имена пользователей, с которыми они работают в системе. Имена пользователей содержатся в столбце FND_USER.user_name.
В этом случае запрос будет выглядеть так:

SELECT fu.user_name
      ,he.full_name
  FROM hr_employees he
      ,fnd_user fu
 WHERE he.employee_id = fu.employee_id(+)
   AND he.full_name LIKE 'А%'

Запрос вроде похожий, однако "плюсик" переехал к таблице FND_USER.
В данном случае, мы говорим о том, что в указанной постановке задачи (для ряда сотрудников найти user_name) таблица HR_EMPLOYEES "главнее". Мы изначально имеем дело со списком сотрудников, для части из которых, нужно найти дополнительную информацию (user_name), если она существует.
Почему она может не существовать?
Да потому, что для сотрудника из таблицы HR_EMPLOYEES может отсутствовать запись в таблице FND_USER с соответствующим значением столбца EMPLOYEE_ID. Значит для ряда записей в HR_EMPLOYEES мы ничего не найдем в FND_USER. Именно поэтому "плюсик" ставится со стороны таблицы FND_USER.

Однако и это еще не всё.
А что если мы хотим получить полный список и сотрудников, и пользователей зарегистрированных в системе. Теперь мы уже знаем, что для ряда сотрудников могут быть не найдены пользователи, а для ряда пользователей могут быть не найдены сотрудники. Т.е. "плюсик" нужен как бы с обеих сторон. Однако такой синтаксис команды не поддерживается.

Существуют разные способы переписать этот запрос по другому(без внешнего соединения), однако наша цель до конца разобраться именно во внешнем соединении.
Для реализации такого запроса необходимо полное внешнее соединение (FULL OUTER JOIN). И в этом случае придется воспользоваться синтаксисом ANSI.
А выглядеть это будет так:

SELECT fu.user_name
      ,he.full_name
  FROM hr_employees he FULL OUTER JOIN fnd_user fu
    ON he.employee_id = fu.employee_id

Подводя итоги, можно сказать следующее.
Если речь не идет о полном внешнем соединении, то нужно понять какая из таблиц является главной, а какая дополняющей. "Плюсик" в условии соединения таблиц (фраза WHERE) ставим со стороны дополняющей таблицы.

Ну и напоследок, чтобы окончательно запутаться.
А что если в запросе больше чем две таблицы? Допустим нам нужно для текущего пользователя (функция FND_GLOBAL.user_id) найти номер рабочего телефона сотрудника.
Информация о телефонах хранится в таблице PER_PHONES. Эта таблица связывается с HR_EMPLOYEES по условию:

   per_phones.parent_table = 'PER_ALL_PEOPLE_F'
   AND per_phones.parent_id = hr_employees.employee_id

Но при этом очевидно, что не у всех сотрудников есть записи о телефонах.
Итоговый запрос будет выглядеть так:

SELECT fu.user_name
      ,he.full_name
      ,pp.phone_number
  FROM fnd_user fu
      ,hr_employees he
      ,per_phones pp
 WHERE /* Соединяем fnd_user и hr_employees */
       he.employee_id(+) = fu.employee_id
       /* Соединяем hr_employees и per_phones */
   AND pp.parent_id(+) = he.employee_id
   AND pp.parent_table(+) = 'PER_ALL_PEOPLE_F'
       /* Прочие ограничения */
   AND pp.phone_type(+) = 'W1' -- рабочий телефон
   AND SYSDATE BETWEEN pp.date_from(+) AND NVL(pp.date_to(+), SYSDATE) -- актуальная запись
   AND fu.user_id = FND_GLOBAL.user_id -- для текущего пользователя

Отметим следующее.
Таблицы соединяем попарно.
В каждой паре определяем главную и дополняющую таблицу.
В паре fnd_user и hr_employees главная - fnd_user, поэтому "плюсик" со стороны hr_employees.
В паре hr_employees и per_phones главная hr_employees, поэтому "плюсик" ставится со стороны per_phones и что особенно важно "плюсик" не ставится со стороны hr_employees.
В прочих условиях "плюсик" ставится для тех таблиц, которые хоть где-нибудь были дополнительными и не ставится у главной таблицы запроса.


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


/* 
   У такого подхода есть существенный минус - для каждой записи из SELECT, 
   ORACLE приходиться менять контекст выполнения с SQL на PLSQL. 
*/
BEGIN
  FOR i IN (SELECT empno FROM SCOTT.EMP)
	LOOP 
	UPDATE SCOTT.EMP
		 SET sal = sal + (sal * .01)
   WHERE empno = i.empno;
	 dbms_output.put_line (i.empno);
  END LOOP;
  COMMIT;
END;


/* 
   Использование BULK COLLECT и FORALL 
   Внутри FORALL может быть только одни DML запрос. 
	 Если нужно несколько запросов, то нужно использовать несколько FORALL
*/
DECLARE
   -- Создаем тип ассоциативного массива,
   -- где ЗНАЧЕНИЕ = SCOTT.EMP.empno%TYPE, а PLS_INTEGER это ключ.
	 TYPE EMPNO_T IS TABLE OF SCOTT.EMP.empno%TYPE
	 INDEX BY PLS_INTEGER;
	 -- Объявляем переменную l_empno_t типа EMPNO_T
	 l_empno_t EMPNO_T;
BEGIN
   -- Поместить все записи разом в коллекцию
	 SELECT empno 
	   BULK COLLECT INTO l_empno_t
	   FROM SCOTT.EMP;
	 -- Конструкция FORALL выполняет весь UPDATE за один раз
	 FORALL i IN 1..l_empno_t.COUNT
	 	UPDATE SCOTT.EMP
		   SET sal = sal + (sal * .01)
     WHERE empno = l_empno_t(i);
	 COMMIT;
END;

SELECT * FROM SCOTT.emp;

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

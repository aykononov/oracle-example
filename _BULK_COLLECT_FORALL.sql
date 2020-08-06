/* ======================================================================
   У такого подхода есть существенный минус - для каждой записи из SELECT, 
   ORACLE приходиться менять контекст выполнения с SQL на PLSQL. 
*/
BEGIN
  FOR i IN (SELECT empno FROM SCOTT.EMP)
  LOOP 
  UPDATE SCOTT.EMP
     SET sal   = sal + (sal * .01)
         WHERE empno = i.empno;
   dbms_output.put_line (i.empno);
  END LOOP;
  COMMIT;
END;


/* =====================================================================
   Использование BULK COLLECT и FORALL 
   Внутри FORALL может быть только одни DML запрос. 
   Если нужно несколько запросов, то нужно использовать несколько FORALL
*/
DECLARE
  -- Создаем тип ассоциативного массива,
  -- где ЗНАЧЕНИЕ = SCOTT.EMP.empno%TYPE, а PLS_INTEGER это ключ.
  TYPE EMPNO_T IS TABLE OF SCOTT.EMP.empno%TYPE INDEX BY PLS_INTEGER;
  -- Объявляем переменную l_empno типа EMPNO_T
  l_empno EMPNO_T;
BEGIN
  -- Поместить все записи разом в коллекцию
  SELECT empno BULK COLLECT INTO l_empno FROM SCOTT.EMP;
  -- Конструкция FORALL выполняет весь UPDATE за один раз
  FORALL i IN 1 .. l_empno.COUNT
    UPDATE SCOTT.EMP 
       SET sal   = sal + (sal * .01) 
     WHERE empno = l_empno(i);
  COMMIT;
END;


/* Создаем структуру для обновления двух таблиц */
CREATE TABLE SCOTT.EMP1 AS (SELECT * FROM SCOTT.EMP);
CREATE TABLE SCOTT.EMP2 AS (SELECT * FROM SCOTT.EMP);
--DROP TABLE SCOTT.EMP1 PURGE;
--DROP TABLE SCOTT.EMP2 PURGE;

/* Обновляем сразу в двух таблицах*/
DECLARE
  TYPE EMPNO_T IS TABLE OF SCOTT.EMP1.empno%TYPE INDEX BY PLS_INTEGER;
  TYPE SAL_T   IS TABLE OF SCOTT.EMP1.sal%TYPE;
  l_empno EMPNO_T;
  l_sal SAL_T;

BEGIN
  SELECT empno, sal BULK COLLECT 
    INTO l_empno, l_sal 
    FROM SCOTT.EMP1;

  FORALL i IN 1..l_empno.COUNT SAVE EXCEPTIONS
  UPDATE SCOTT.EMP1
     SET sal   = l_sal(i) + (l_sal(i) * .01)
   WHERE empno = l_empno(i);

  FORALL i IN 1..l_empno.COUNT SAVE EXCEPTIONS  
  UPDATE SCOTT.EMP2
     SET sal   = l_sal(i) + (l_sal(i) / .02)  -- здесь будут ОШИБКИ!!!
   WHERE empno = l_empno(i);

COMMIT;  

EXCEPTION
   WHEN OTHERS THEN
   dbms_output.put_line(sqlerrm);
   dbms_output.put_line('Number of ERRORS: ' || SQL%BULK_EXCEPTIONS.COUNT);
   FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      dbms_output.put_line('Error ' || i || ' occurred during iteration ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Oracle error is ' ||SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP; 

ROLLBACK;
                                                        
END;

/*
Вывод ОШИБОК, здесь номера строк с ошибками:
--------------------------------------------
ORA-24381: error(s) in array DML
Number of ERRORS: 6
Error 1 occurred during iteration 4
Oracle error is ORA-01438: value larger than specified precision allowed for this column
Error 2 occurred during iteration 6
Oracle error is ORA-01438: value larger than specified precision allowed for this column
Error 3 occurred during iteration 7
Oracle error is ORA-01438: value larger than specified precision allowed for this column
Error 4 occurred during iteration 8
Oracle error is ORA-01438: value larger than specified precision allowed for this column
Error 5 occurred during iteration 9
Oracle error is ORA-01438: value larger than specified precision allowed for this column
Error 6 occurred during iteration 13
Oracle error is ORA-01438: value larger than specified precision allowed for this column
*/


/* Проверяем */
SELECT t.empno, t.sal, t1.sal AS sal_1, t2.sal AS sal2 
  FROM SCOTT.EMP t, SCOTT.EMP1 t1, SCOTT.EMP2 t2
 WHERE t.empno  = t1.empno
   AND t.empno  = t2.empno
   AND t1.empno = t2.empno;
   
  EMPNO      SAL   SAL_1   SAL_2
-------  ------- ------- -------
 1 7369   800,00  808,00 40800,00
 2 7499  1600,00 1616,00 81600,00
 3 7521  1250,00 1262,50 63750,00
 4 7566  2975,00 3004,75  2975,00
 5 7654  1250,00 1262,50 63750,00
 6 7698  2850,00 2878,50  2850,00
 7 7782  2450,00 2474,50  2450,00
 8 7788  3000,00 3030,00  3000,00
 9 7839  5000,00 5050,00  5000,00
10 7844  1500,00 1515,00 76500,00
11 7876  1100,00 1111,00 56100,00
12 7900   950,00  959,50 48450,00
13 7902  3000,00 3030,00  3000,00
14 7934  1300,00 1313,00 66300,00

/* ====================================================================== */
http://www.orahome.ru/ora-artic/48

Если для Вас выборка большого количества данных и помещение их в переменную PL/SQL важнее чем циклический проход по результирующей выборке, то Вы можете использовать выражение BULK COLLECT. Если в Вашей выборке всего несколько колонок, то каждую из них Вы можете сохранить в отдельную переменную - коллекцию. Если Вы выбираете все колонки таблицы, то можете сохранить результат выборки в коллекции записей. Такая коллекция весьма удобна для циклического перебора результирующих записей, поля которых ссылаются на колонки таблицы.

Пример
DECLARE
 TYPE  IdsTab IS TABLE OF employees.employee_id%TYPE;
 TYPE  NameTab IS TABLE OF employees.last_name%TYPE;
 ids   IdsTab;
 names NameTab;
 CURSOR c1 IS
 SELECT employee_id, last_name
    FROM employees
  WHERE job_id = 'ST_CLERK';
BEGIN
 OPEN c1;
 FETCH c1 BULK COLLECT INTO ids, names;
 CLOsE c1;
-- Обработка элементов коллекции
FOR i IN ids.FIRST..ids.LAST
LOOP
  IF ids(i) > 140 THEN
   DBMS_OUTPUT.PUT_LINE(ids(i));
  END IF;
END LOOP;
FOR i IN names.FIRST..names.LAST
LOOP
  IF names(i) LIKE '%Ma%' THEN
   DBMS_OUTPUT.PUT_LINE(names(i));
  END IF;
END LOOP;
END;
/
Эта технология может быть не только очень быстрой, то и требовательной к памяти.

Используя BULK COLLECT, Вы можете улучшить код, выполняя больше работы в SQL:
Если Вам надо пройти по результирующей выборке только один раз, используйте цикл For. Этот подход позволяет избежать выделение памяти на хранение копии результирующих данных.
Если из результирующих данных Вам требуется выбрать определенные значения и поместить их в меньшую выборку, используйте фильтрацию в основном выражении. В простом случае используйте условия WHERE. Для сравнения двух и более наборов данных применяйте выражения INTERSECT и MINUS.
Если Вы циклически проходите по результирующей выборке и для каждого ряда выполняете DML-выражение или делаете другую выборку, используйте более эффективных подход. Попробуйте вложенную выборку переделать в подзапрос основной выборки, если возможно, используйте выражения EXISTS или NOT EXISTS. Для DML, рассмотрите возможность использования выражения FORALL, который значительно более быстрый, чем аналогичное выражение, выполненное внутри цикла.
Еще один пример использования BULK COLLECT
DECLARE
 TYPE EmployeeSet IS TABLE OF employees%ROWTYPE;
 underpaid EmployeeSet; -- Набор рядов таблицы EMPLOYEES.

 CURSOR c1 IS SELECT first_name, last_name FROM employees;
 TYPE NameSet IS TABLE OF c1%ROWTYPE;
  some_names NameSet; -- Набор неполных рядов таблицы EMPLOYEES

BEGIN

-- С помощью одного запроса мы извлекаем все данные, соответствующие условиям, в коллекцию записей

SELECT * BULK COLLECT
  INTO underpaid
  FROM employees
 WHERE salary < 5000
ORDER BY salary DESC;

-- Сейчас мы можем обработать данные, выбранные запросом, или передать их в отдельную процедуру.

 DBMS_OUTPUT.PUT_LINE(underpaid.COUNT || ' people make less than 5000.');
 FOR i IN underpaid.FIRST..underpaid.LAST
 LOOP
  DBMS_OUTPUT.PUT_LINE(underpaid(i).last_name || ' makes ' || underpaid(i).salary);
 END LOOP;

-- А сейчас мы сделаем выборку только по некоторым полям таблицы.
-- Получим фамилию и имя десяти случайных сотрудников.

 SELECT first_name, last_name BULK COLLECT
    INTO some_names
    FROM employees
   WHERE ROWNUM < 11;

FOR i IN some_names.FIRST..some_names.LAST
LOOP
  DBMS_OUTPUT.PUT_LINE('Employee = ' || some_names(i).first_name || ' ' ||
  some_names(i).last_name);
END LOOP;
END;
/

Извлечение результатов выборки в коллекции, используя выражение BULK COLLECT.

Использование ключевых слов BULK COLLECT в выборках - очень эффективный способ получения результирующих данных. Вместо циклической обработки каждого ряда, Вы сохраняете результат в одной или нескольких коллекциях, все это делается в рамках одной операцией. Это ключевое слово может использоваться совместно с выражениями SELECT INTO, FETCH INTO и RETURNING INTO.

При использовании ключевых слов BULK COLLECT все переменные в списке INTO должны быть коллекциями. Колонки таблицы могут быть как скалярными значениями так и структурами, включая объектные типы.

Пример
DECLARE

 TYPE NumTab IS TABLE OF employees.employee_id%TYPE;
 TYPE NameTab IS TABLE OF employees.last_name%TYPE;
 enums NumTab;  -- Нет необходимости инициализировать коллекцию.
 names NameTab; -- Значения будут заполнены выражением SELECT INTO.

PROCEDURE print_results IS
BEGIN
 IF enums.COUNT = 0 THEN
   DBMS_OUTPUT.PUT_LINE('No results!');
 ELSE
  DBMS_OUTPUT.PUT_LINE('Results:');
  FOR i IN enums.FIRST..enums.LAST
  LOOP
    DBMS_OUTPUT.PUT_LINE(' Employee #' || enums(i) || ': ' || names(i));
  END LOOP;
 END IF;
END;

BEGIN

-- Извлечение данных по сотрудникам, идентификатор которых больше 1000

SELECT employee_id, last_name BULK COLLECT
   INTO enums, names FROM employees
 WHERE employee_id > 1000;

-- Все данные помещены в память выражением BULK COLLECT
-- Нет необходимости выполнять FETCH для каждого ряда результирующих данных

print_results();

-- Выборка приблизительно 20% всех рядов

SELECT employee_id, last_name BULK COLLECT
   INTO enums, names
   FROM employees SAMPLE (20);

print_results();
END;
/

Коллекции инициализируются автоматически. Вложенные таблицы и ассоциативные массивы расширяются для сохранения необходимого количества элементов. Если Вы используете массивы с фиксированным размером, убедитесь, что декларируемый размер массива соответствует объемам выбираемых данных. Элементы вставляются в коллекции, начиная с индекса 1, при этом все существующие значения перезаписываются.

Т.к. обработка выражения BULK COLLECT INTO подобна циклу FETCH, не генерируется исключение NO_DATA_FOUND, если не выбран ни один ряд. Если требуется, наличие выбранных данных надо проверять вручную.

Чтобы предотвратить переполнение памяти данными выборки, Вы можете использовать выражение LIMIT или псевдоколонку ROWNUM для ограничения числа записей в выборке. Кроме того возможно использование выражения SAMPLE для получения набора случайных записей.

Пример
DECLARE
 TYPE SalList IS TABLE OF employees.salary%TYPE;
 sals SalList;
BEGIN
-- Ограничение числа выбираемых записей до 50
SELECT salary BULK COLLECT
   INTO sals
   FROM employees
  WHERE ROWNUM <= 50;

-- Получение 10% (приблизительно) записей в таблице
 SELECT salary BULK COLLECT
   INTO sals
   FROM employees SAMPLE (10);
END;
/

Вы можете обрабатывать большие объемы результирующих данных, указав количество записей, которые будут выбраны из курсора за один раз.

Пример
DECLARE
 TYPE NameList IS TABLE OF employees.last_name%TYPE;
 TYPE SalList  IS TABLE OF employees.salary%TYPE;
 CURSOR c1 IS
  SELECT last_name, salary
     FROM employees
   WHERE salary > 10000;
 names NameList;
 sals  SalList;
 TYPE RecList IS TABLE OF c1%ROWTYPE;
 recs RecList;
 v_limit PLS_INTEGER := 10;

 PROCEDURE print_results IS
 BEGIN
  IF names IS NULL OR names.COUNT = 0 THEN -- проверка, не пустая ли коллекция
   DBMS_OUTPUT.PUT_LINE('No results!');
  ELSE
   DBMS_OUTPUT.PUT_LINE('Results: ');
   FOR i IN names.FIRST..names.LAST
   LOOP
    DBMS_OUTPUT.PUT_LINE(' Employee ' || names(i) || ': $' || sals(i));
   END LOOP;
  END IF;
END;

BEGIN
 DBMS_OUTPUT.PUT_LINE('--- Обрабатываем все результаты за раз ---');
 OPEN c1;
 FETCH c1 BULK COLLECT INTO names, sals;
 CLOSE c1;
 print_results();
 DBMS_OUTPUT.PUT_LINE('--- Обрабатываем ' || v_limit || ' рядов за раз ---');
 OPEN c1;
 LOOP
  FETCH c1 BULK COLLECT INTO names, sals LIMIT v_limit;
  EXIT WHEN names.COUNT = 0;
  print_results();
 END LOOP;
 CLOSE c1;
 DBMS_OUTPUT.PUT_LINE('--- Извлекаем ряды вместо отдельных колонок ---');
 OPEN c1;
 FETCH c1 BULK COLLECT INTO recs;
 FOR i IN recs.FIRST..recs.LAST
 LOOP
-- Сейчас все колонки берем сразу из результирующего набора данных
  DBMS_OUTPUT.PUT_LINE(' Employee ' || recs(i).last_name || ': $'|| recs(i).salary);
 END LOOP;
END;
/
Ограничение числа рядов в выборке с помощью условия Limit

Дополнительное условие LIMIT может использоваться только с выражением FETCH и ограничивает число рядов, выбираемых из баз данных. В следующем примере на каждой итерации цикла извлекается не больше десяти рядов и помещается в таблицу empids. Предыдущие значения перетираются. Обратите внимание на использование empids.count как условия выхода из цикла.

Пример
DECLARE
 TYPE numtab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
 CURSOR c1 IS
  SELECT employee_id
     FROM employees
    WHERE department_id = 80;

 empids numtab;
 rows PLS_INTEGER := 10;
BEGIN
 OPEN c1;
 LOOP -- следующее выражение извлекает не больше 10 рядов за одну итерацию
  FETCH c1 BULK COLLECT INTO empids LIMIT rows;
  EXIT WHEN empids.COUNT = 0;
  -- EXIT WHEN c1%NOTFOUND; -- это условие некорректно, можно потерять часть данных
 DBMS_OUTPUT.PUT_LINE('------- Results from Each Bulk Fetch --------');
  FOR i IN 1..empids.COUNT
  LOOP
   DBMS_OUTPUT.PUT_LINE( 'Employee Id: ' || empids(i));
  END LOOP;
 END LOOP;
 CLOSE c1;
END;
/
Передача результатов операций DML в коллекцию, используя выражение RETURNING INTO

Вы можете использовать BULK COLLECT в условии RETURNING INTO выражений INSERT, UPDATE, DELETE.

Пример
CREATE TABLE emp_temp AS SELECT * FROM employees;

DECLARE
 TYPE NumList IS TABLE OF employees.employee_id%TYPE;
 enums NumList;
 TYPE NameList IS TABLE OF employees.last_name%TYPE;
 names NameList;
BEGIN
 DELETE FROM emp_temp WHERE department_id = 30
 RETURNING employee_id, last_name BULK COLLECT INTO enums, names;
 DBMS_OUTPUT.PUT_LINE('Deleted ' || SQL%ROWCOUNT || ' rows:');
 FOR i IN enums.FIRST..enums.LAST
 LOOP
  DBMS_OUTPUT.PUT_LINE('Employee #' || enums(i) || ': ' || names(i));
 END LOOP;
END;
/
Совместное использование FORALL и BULK COLLECT

Вы можете объединить условие BULK COLLECT и выражение FORALL. Результирующая коллекция будет заполнена итерациями выражения FORALL. В следующем примере для каждого удаленного ряда значение employee_id сохраняется в коллекцию e_ids. Коллекция depts хранит три элемента, таким образом выражение FORALL выполнит три итерации. Если каждый оператор DELTE выполненный выражением FORALL удалит пять рядов, то в результате коллекция e_ids, которая хранит значения из удаленных рядов, будет содержать 15 элементов.

Пример
CREATE TABLE emp_temp AS SELECT * FROM employees;

DECLARE
 TYPE NumList IS TABLE OF NUMBER;
 depts NumList := NumList(10,20,30);
 TYPE enum_t IS TABLE OF employees.employee_id%TYPE;
 TYPE dept_t IS TABLE OF employees.department_id%TYPE;
 e_ids enum_t;
 d_ids dept_t;
BEGIN
 FORALL j IN depts.FIRST..depts.LAST
  DELETE FROM emp_temp WHERE department_id = depts(j)
     RETURNING employee_id, department_id BULK COLLECT INTO e_ids, d_ids;
  DBMS_OUTPUT.PUT_LINE('Deleted ' || SQL%ROWCOUNT || ' rows:');
 FOR i IN e_ids.FIRST .. e_ids.LAST
 LOOP
  DBMS_OUTPUT.PUT_LINE('Employee #' || e_ids(i) || ' from dept #' || d_ids(i));
 END LOOP;
END;
/
Значения столбцов, удаленных каждой итерацией, добавляются к ранее полученным значениям коллекций. Если бы использовался цикл FOR вместо выражения FORALL, то набор результирующих значений перетирался бы следующим выполнением выражения DELETE. Не допускается использование конструкции SELECT ... BULK COLLECT в выражении FORALL.

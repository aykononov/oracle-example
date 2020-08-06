Полезные_примеры.

/* Конкатенация значений поля без использования wm_concat */
select substr(sys_connect_by_path(col1, ','), 2)
from
(
       select rownum r, rownum col1 from dual
       connect by rownum < 5
)
where connect_by_isleaf=1
connect by prior r=r-1
start with r=1

/* Агрегация по интервалу времени */
select a3.d1, a3.d2, sum(t.val)
  from test2 t,
       (select a1.dt d1, a2.dt d2
          from (select dt, rownum rn
            from (select dt
                from test2
               where mod(to_number(to_char(dt, 'MI')) +
                         to_number(to_char(dt, 'HH24')) * 60,
                         20) = 0 --20 минут
               order by dt)) a1,
               (select dt, rn
            from (select dt, rownum rn
                    from (select dt
                      from test2
                     where mod(to_number(to_char(dt, 'MI')) +
                               to_number(to_char(dt, 'HH24')) * 60,
                               20) = 0 --20 минут
                     order by dt))) a2
        --соединяем записи со сдвигом
         where a1.rn + 1 = a2.rn
         order by a2.dt) a3
 where t.dt between a3.d1 and a3.d2
 group by a3.d1, a3.d2
--интервал вывода
having a3.d1 between 
       to_date('02.01.2012 00:00', 'DD.MM.YYYY HH24:MI') and 
       to_date('02.01.2012 23:59', 'DD.MM.YYYY HH24:MI')
 order by a3.d1;
Формируем два одинаковых набора дат, упорядоченных по возрастанию, каждый следующий элемент = предыдущий + 20 минут. 
Соединяем их со сдвигом, получаем последовательные пары интервалов. Суммируем поле val, указываем в условии интервал дат. 
Результирующий набор фильтруем по интервалу в 1 сутки.

/* Удаление полных дубликатов */
delete from emp
 where rowid in 
 (select rwd
      from (select rowid rwd,
           row_number() 
           over(partition by empno, 
                             last_name, 
                             first_name, 
                             job_id, 
                             dept_id, 
                             salary 
                    order by empno, 
                             last_name, 
                             first_name, 
                             job_id, 
                             dept_id, 
                             salary) rn
              from emp)
 where rn > 1)
Группируем с помощью аналитической функции PARTITION OVER по всем полям (полный дубликат), нумеруем записи в группах. 
Отбираем все, у которых порядковый номер больше 1 и удаляем по ROWID

/* Вынесение второй записи группы в отдельное поле */
select empno,
       sum(decode(rn, 1, a_value, null)),
       sum(decode(rn, 2, a_value, null)) from(
select ev1.empno,
       ev1.a_value,
       row_number() over
        (partition by ev1.empno order by ev1.empno) rn
      from Alex.Emp_Values ev1
      order by rn, ev1.a_value)
      group by empno
      order by empno
пример: если у гражданина, кроме паспорта, есть загранпаспорт, то он выводится во вторую колонку

/* Формирование поля из ряда чисел от 1 до 10 */
select rownum from dual connect by rownum < 10;
--Cоздание временной таблицы с объектным типом колонки
CREATE TYPE SCOTT.PERSON_T
AS
OBJECT (
name VARCHAR2(100),
ssn NUMBER
);
 CREATE GLOBAL TEMPORARY
TABLE SCOTT.TMP_OBJ    
(
PERSON PERSON_T
)    
ON COMMIT DELETE ROWS;
--Cоздание и обращение к переменной в стандартном контексте CLIENTCONTEXT
begin 
  dbms_session.set_context('CLIENTCONTEXT', 'n_param', 1); 
  dbms_session.set_context('CLIENTCONTEXT', 'v_param', 'Y'); 
end;
select sys_context('CLIENTCONTEXT', 'n_param') from dual;
select sys_context('CLIENTCONTEXT', 'v_param') from dual;
/* Cоздание и ображение к переменной в пользовательском контексте
Создаем пользовательский контекст. MY_CONTEXT_API - пакет, функциям которого при инициализации контекста выдаются write-права на контекст. */
create or replace context MY_CONTEXT using MY_CONTEXT_API;
--Теперь мы можем проинициализировать переменную в пользовательском контексте MY_CONTEXT с помощью процедуры
procedure set_my_context(p_var  varchar2,
                         p_val  varchar2)
is
begin
   dbms_session.set_context('MY_CONTEXT', p_var, p_val);
end;
-- Создание и обращение будут выглядеть так:
begin
   MY_CONTEXT_API.set_my_context(p_var => 'p_var', p_val => 'Y');
end;
select sys_context('MY_CONTEXT', 'p_var') from dual;
--Пример использования PIVOT, UNPIVOT
with a as (
      select 1 pk, 'Answer1' answr, 'Y' flag from dual
      union
      select 1, 'Answer2', 'Y' from dual
      union
      select 1, 'Answer3', 'N' from dual
      union
      select 1, 'Answer4', 'N' from dual
    ) 
    select pk, 
           "'Answer1'_ANS" Answer1W,
           "'Answer2'_ANS" Answer2W,
           "'Answer3'_ANS" Answer3W,
           "'Answer4'_ANS" Answer4W
    from (
    select * from a
     pivot (max(flag) ans FOR answr IN ('Answer1', 
                                        'Answer2', 
                                        'Answer3', 
                                        'Answer4'
                                       ))
     );
--И наоборот:
select *
  from XXIP310_pivotview_tmp
  unpivot(flag for answr in(answer1w as
                           'Answer1',
                           answer2w as
                           'Answer2',
                           answer3w as
                           'Answer3',
                           answer4w as
                           'Answer4'))
/* Просмотр текущих блокировок */
select c.owner,
       c.object_name,
       c.object_type,
       b.sid,
       b.serial#,
       b.status,
       b.osuser,
       b.machine,
       decode(a.locked_mode,
              0, 'None',
              1, 'Null (NULL)',
              2, 'Row-S (SS)',
              3, 'Row-X (SX)',
              4, 'Share (S)',
              5, 'S/Row-X (SSX)',
              6, 'Exclusive (X)',
              a.locked_mode) locked_mode
  from v$locked_object a, v$session b, dba_objects c
 where b.sid = a.session_id
   and a.object_id = c.object_id
   and object_name like '%XXXX%';
/*
lockmode Clause
Specify one of the following modes:
ROW SHARE ROW SHARE permits concurrent access to the locked table but prohibits users from locking the entire table for exclusive access. ROW SHARE is synonymous with SHARE UPDATE, which is included for compatibility with earlier versions of Oracle Database.
ROW EXCLUSIVE ROW EXCLUSIVE is the same as ROW SHARE, but it also prohibits locking in SHARE mode. ROW EXCLUSIVE locks are automatically obtained when updating, inserting, or deleting.
SHARE UPDATE See ROW SHARE.
SHARE SHAREpermits concurrent queries but prohibits updates to the locked table.
SHARE ROW EXCLUSIVE SHARE ROW EXCLUSIVE is used to look at a whole table and to allow others to look at rows in the table but to prohibit others from locking the table in SHARE mode or from updating rows.
EXCLUSIVE EXCLUSIVE permits queries on the locked table but prohibits any other activity on it.
*/

/* Генерация псевдослучайных данных */
select rownum rn,
         DBMS_RANDOM.STRING('a', 8) str_rnd,
         round(DBMS_RANDOM.value(1, 5)) num_rnd,
         trunc(sysdate - DBMS_RANDOM.value(1, 1000)) date_rnd
    from dual

/* Римские цифры */
select 
  rownum ara
 ,to_char(rownum,'fmrn') rom
from all_objects where rownum < 4000 

/* Курсор с параметрами */
declare
    CURSOR A(c_tab IN varchar2) IS SELECT TABLE_NAME FROM USER_TABLES
      WHERE TABLE_NAME LIKE c_tab;
    l_table varchar2(30);
  begin
    open A(c_tab => 'A%');
    loop
      fetch A into l_table;
      exit when A%NOTFOUND;
      dbms_output.put_line(l_table);
    end loop;
    close A;
  end;

/* Время с миллисекундами */
select to_char(systimestamp, 'HH24:MI:SSXFF') from dual;

/* Языковые настройки экземпляра */
select DECODE(parameter, 'NLS_CHARACTERSET', 'CHARACTER SET',
'NLS_LANGUAGE', 'LANGUAGE',
'NLS_TERRITORY', 'TERRITORY') name,
value from v$nls_parameters
WHERE parameter IN ( 'NLS_CHARACTERSET', 'NLS_LANGUAGE', 'NLS_TERRITORY') 

/* Время с миллисекундами */
select to_char(systimestamp, 'HH24:MI:SSXFF') from dual;

/* Выгрузка RU-объектов OeBS */
export NLS_LANG=RUSSIAN_RUSSIA.CL8MSWIN1251
Predefined Inquiry Directives
Dbms_Output.put_line($$PLSQL_UNIT); --текущая процедура 
Dbms_Output.put_line($$PLSQL_LINE); --текущая строка

/* Импорт документа XML в таблицу с использованием пакета DBMS_XMLSAVE */
procedure upload(p_xml in clob)
  is
    l_context   number;
    l_inserted  number;
  begin
    l_context  := DBMS_XMLSAVE.newContext('XLS_UPLOAD_DATA'); // имя таблица
    DBMS_XMLSAVE.setrowtag (l_context, 'LINE'); //имя XML-тега, в котором находится кортеж данных
    l_inserted := DBMS_XMLSAVE.insertXML(l_context, p_xml);
    DBMS_XMLSAVE.closecontext(l_context);
end upload;

/* Расчет фин.показателя ВНД(IRR) */
with t as
 (select year dt, ncf summ from table(self.l_step2_year))
select round(irr * 100, 2)
  into res
  from (select *
          from t model dimension by(row_number() over(order by dt) rn) 
          measures(dt - first_value(dt) 
          over(order by dt) dt, summ s, 0 ss, 0 irr, power(10, -4) rate_step, 0 disc_summ) 
          rules iterate(100000) 
          until(s [ 1 ] + disc_summ [ 1 ] < 0)(ss [ any ] = s [ CV() ] / power(1 + IRR [ 1 ], dt [ CV() ] / 365), 
          disc_summ [ 1 ] = sum(ss) [ rn > 1 ], irr [ 1 ] = irr [ 1 ] + rate_step [ 1 ]))
 where rn = 1;
Foreign key references для таблицы
select table_name, constraint_name, status, owner
from all_constraints
where constraint_type = 'R'
and r_constraint_name in
 (
   select constraint_name from all_constraints
   where constraint_type in ('P', 'U')
   and table_name = &TABLE_NAME
 )
order by table_name, constraint_name

/* парсинг строки с разделителями */
declare
  l_args      varchar2(50) := 'a1, b1, c1';
  l_aliases   varchar2(50) := 'a2, b2, c2';
  l_delimeter varchar2(1)  := ',';
begin
  for current_row in (
      with str as
        (select l_args from dual),
           str_aliases as
        (select l_aliases from dual)
        select regexp_substr(l_args, '[^' || l_delimeter || ']+', 1, rownum) split,
               regexp_substr(l_aliases, '[^' || l_delimeter || ']+', 1, rownum) split_aliases
        from str, str_aliases
        connect by level <= length (regexp_replace(l_args, '[^,]+')) + 1)
   loop
     dbms_output.put_line(current_row.split);
     dbms_output.put_line(current_row.split_aliases);
   end loop;
end;

/* просмотр сессий, блокирующих GTT */
select --+rule
       s.INST_ID, s.SID, s.SERIAL#, s.USERNAME, s.STATUS, s.MACHINE 
  from gv$lock l, gv$session s 
 where l.INST_ID=s.INST_ID
   and l.TYPE='TO'
   and l.SID=s.SID
   and l.id1 in (select o.object_id from dba_objects o 
                  where o.object_name = Upper('your_table_here'))

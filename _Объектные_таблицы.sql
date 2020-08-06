/* Объектные таблицы */
CREATE OR REPLACE TYPE ADDRESS_TYPE
AS OBJECT (city   VARCHAR2(30),
           street VARCHAR2(30),
           state  VARCHAR2(2),
           zip    NUMBER);
/
CREATE OR REPLACE TYPE PERSON_TYPE
AS OBJECT (cname        VARCHAR2(30),
           dob          DATE,
           home_address address_type,
           work_address address_type);
/
CREATE TABLE SCOTT.PEOPLE OF PERSON_TYPE;

-- Структура таблицы
SELECT t.TABLE_NAME, t.COLUMN_NAME, t.DATA_TYPE
  FROM USER_TAB_COLUMNS t
 WHERE t.TABLE_NAME = 'PEOPLE';
 
   TABLE_NAME  COLUMN_NAME   DATA_TYPE
   ----------  ------------  ------------
1  PEOPLE      CNAME         VARCHAR2
2  PEOPLE      DOB           DATE
3  PEOPLE      HOME_ADDRESS  ADDRESS_TYPE 
4  PEOPLE      WORK_ADDRESS  ADDRESS_TYPE


DМL-операторы в отношении этой объектной таблицы для создания и запрашивания данных:

INSERT INTO SCOTT.PEOPLE 
VALUES ('Tom',
        '13.03.2020',
        address_type('Denver','123 Street','Co','12345'),
        address_type('Redwood','45 Wayout','Ca','23456') );

SELECT cname, dob, p.home_address AS Home, p.work_address AS WORK 
  FROM SCOTT.PEOPLE p;

   CNAME DOB        HOME.CITY HOME.STREET HOME.STATE HOME.ZIP WORK.CITY WORK.STREET WORK.STATE WORK.ZIP
   ----- ---------- --------- ----------- ---------- -------- --------- ----------- ---------- --------
1	 Tom	 13.03.2020	Denver	  123 Street	Co	       12345	  Redwood	  45 Wayout   Ca	       23456

Теперь, если судить о внешней стороне таблицы, то в ней есть четыре столбца. После того как мы наблюдали "магию", 
скрытую во вложенных таблицах, можно предположить, что здесь происходит что-то еще. Все объектно-реляционные данные 
Oracle хранит в обычных реляционных таблицах - к концу дня все они заполнены строками и столбцами. 
Заглянув в реальный словарь данных, можно увидеть, как в действительности выглядит наша таблица: 

SELECT NAME,
       segcollength
  FROM SYS.COL$
 WHERE obj# = (SELECT object_id
                 FROM USER_OBJECTS
                WHERE object_name = 'PEOPLE');

    NAME            SEGCOLLENGTH
    --------------- ------------ 
 1  SYS_NC_OID$     16           
 2  SYS_NC_ROWINFO$ 1
 3  CNAME           30
 4  DOB             7
 5  HOME_ADDRESS    1
 6  SYS_NC00006$    30
 7  SYS_NC00007$    30
 8  SYS_NC00008$    2
 9  SYS_NC00009$    22
10  WORK_ADDRESS    1
11  SYS_NC00011$    30
12  SYS_NC00012$    30
13  SYS_NC00013$    2
14  SYS_NC00014$    22

SYS_NC_OID$. 
Это сгенерированный системой объектный идентификатор таблицы. Представляет собой уникальный столбец типа RAW(16). 
Он имеет ограничение уникальности и на нем также создан соответствующий уникальный индекс.

SYS_NC_ROWINFO$. 
Это та же самая "магическая" функция, которую мы наблюдали во вложенных таблицах. 
Выбор данного столбца из таблицы приводит к возвращению всей строки как единственного столбца:

SELECT SYS_NC_ROWINFO$ FROM SCOTT.PEOPLE;

SYS_NC_ROWINFO$(CNAME, 
                DOB, 
                HOME_ADDRESS.CITY, HOME_ADDRESS.STREET, HOME_ADDRESS.STATE, HOME_ADDRESS.ZIP, 
                WORK_ADDRESS.CITY, WORK_ADDRESS.STREET, WORK_ADDRESS.STATE, WORK_ADDRESS.ZIP)
---------------------------------------------------------------------------------------------
1    Tom    13.03.2020    Denver    123 Street    Co    12345    Redwood   1 Way   Ca   23456


CNAME, DOB. 
Это скалярные атрибуты нашей объектной таблицы. Как и ожидалось, они хранятся в виде обычных столбцов.

НОМЕ_ADDRESS, WORK_ADDRESS. 
Это также "магические" функции. Они возвращают коллекцию столбцов, которые представляют одиночный объект. 
Они не потребляют реальное пространство за исключением указания NULL или NOT NULL для сущности.

SYS_NCnnnnn$. 
Это скалярные реализации наших встроенных объектных типов. Поскольку тип PERSON_TYPE имеет встроенный тип ADDRESS_TYPE, 
требуется предусмотреть место для сохранения такого объекта в столбцах соответствующего типа. Сгенерированные системой 
имена являются обязательными, т.к. имя столбца должно быть уникальным, а один и тот же объектный тип может использоваться 
более одного раза, что и было сделано. Если бы эти имена не генерировались, столбец ZIP встретился бы дважды. 

Заключительные соображения по поводу объектных таблиц.
Объектные таблицы используются для реализации объектно-реляционной модели в Oracle. Одиночная объектная таблица обычно 
будет приводить к созданию множества физических объектов в базе данных и добавлению в схему дополнительных столбцов, 
предназначенных для управлен ия ими. С объектными таблицами связана определенная "магия". Объектные представления позволяют 
получить преимущества от применения синтаксиса и семантики объектов, одновременно обладая полным контролем над физическим 
хранением данн ых и позволяя реляционный доступ к лежащим в основе данным.

/* ОЧИСТКА */
DROP TABLE people PURGE;
DROP TYPE person_type;
DROP TYPE address_type;

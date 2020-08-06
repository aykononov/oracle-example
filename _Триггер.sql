CREATE TABLE TABL (id INT , x INT, y INT, flg VARCHAR2(10));

-- Создаем последовательность
CREATE SEQUENCE TABL_SEQ1
MINVALUE     1
START WITH   1
INCREMENT BY 1
NOCACHE;

-- Создаем триггер для INSERT
CREATE OR REPLACE TRIGGER TABL_BRI
BEFORE INSERT ON TABL 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
WHEN (new.id IS NULL)
BEGIN
        SELECT TABL_SEQ1.nextval, 'INSERTING'
          INTO :new.id, :new.flg
          FROM dual;
END;

-- Создаем триггер для UPDATE
CREATE OR REPLACE TRIGGER TABL_BRU
BEFORE UPDATE ON TABL 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
        SELECT 'UPDATING'
          INTO :new.flg
          FROM dual;
        
        dbms_output.put_line
          ('old.x = ' || :old.x || ', old.y = ' || :old.y);
        dbms_output.put_line
          ('new.x = ' || :new.x || ', new.y = ' || :new.y);
END;

-- Выполняем INSERT
INSERT INTO TABL(x, y) VALUES (1,1);
INSERT INTO TABL(x, y) VALUES (11,11);
COMMIT;

-- Проверяем
SELECT * FROM TABL;

 ID   X   Y  FLG
---------------------
 1   1   1  INSERTING
 2  11  11  INSERTING

-- Выполняем UPDATE
UPDATE TABL SET x = x + 1, y = y + x WHERE ID = 2;
COMMIT;
ыввод:
old.x = 11, old.y = 11
new.x = 12, new.y = 22

-- Проверяем
SELECT * FROM TABL;

ID   X   Y  FLG
---------------------
 1   1   1  INSERTING
 2  12  22  UPDATING

-- Отключаем триггеры
ALTER TRIGGER TABL_BRI DISABLE;
ALTER TRIGGER TABL_BRU DISABLE;


-- Создаем новый (объединяем)  
CREATE OR REPLACE TRIGGER TABL_BRIU
BEFORE 
INSERT OR UPDATE ON TABL
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW

BEGIN
      IF INSERTING THEN
      
        SELECT TABL_SEQ1.nextval, 'INSERTING'
          INTO :new.id, :new.flg
          FROM dual;
      
      ELSIF UPDATING THEN
      
        SELECT 'UPDATING'
          INTO :new.flg
          FROM dual;
        
        dbms_output.put_line
          ('old.x = ' || :old.x || ', old.y = ' || :old.y);
        dbms_output.put_line
          ('new.x = ' || :new.x || ', new.y = ' || :new.y);
      
      END IF;
END;

-- Выполняем INSERT и UPDATE
INSERT INTO TABL(x, y) VALUES (1,1);
INSERT INTO TABL(x, y) VALUES (11,11);
UPDATE TABL SET x = x + 1, y = y + x WHERE ID = 1;
COMMIT;
выввод:
old.x = 1, old.y = 1
new.x = 2, new.y = 2

-- Проверяем
SELECT * FROM TABL;

ID   X   Y  FLG
---------------------
 1   2   2  UPDATING
 2  12  22  UPDATING
 3   1   1  INSERTING
 4  11  11  INSERTING

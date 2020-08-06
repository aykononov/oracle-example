/* »ндекс-таблицы */
ќпции доступный дл€ индекс-таблицу:
CREATE TABLE t1 (x INT PRIMARY KEY,
                 y VARCHAR2(25),
                 z DATE)
ORGANIZATION INDEX;

CREATE TABLE t2 (x INT PRIMARY KEY,
                 y VARCHAR2(25),
                 z DATE)
ORGANIZATION INDEX OVERFLOW;

CREATE TABLE t3 (x INT PRIMARY KEY,
                 y VARCHAR2(25),
                 z DATE)
ORGANIZATION INDEX OVERFLOW INCLUDING y;

SELECT dbms_metadata.get_ddl('TABLE', 'T1')
  FROM dual;
--------------------------------------------------------------------------------

“еперь дл€ начала анализа создадим индекс-таблицу без сжати€:
CREATE TABLE iot ( owner, object_type, object_name,
                   CONSTRAINT iot_pk PRIMARY KEY (owner, object_type, object_name) )
ORGANIZATION INDEX NOCOMPRESS
AS
SELECT DISTINCT owner, object_type, object_name FROM All_Objects;

“еперь можно измерить используемое пространство.
ƒл€ этого мы применим команду ANALYZE INDEX VALIDATE STRUCTURE . 
Ёта команда заполн€ет динамическое представление производительности по имени INDEX_STATS, 
которое будет содержать самое большее одну строку с информацией из последнего выполнени€ команды ANALYZE .

ANALYZE INDEX iot_pk VALIDATE STRUCTURE;

¬ывод показывает, что индекс в текуший момент использует 398 листовых блоков (где наход€тс€ наши данные) 
и 3 блока ветвлени€ (такие блоки в Oracle примен€ютс€ дл€ навигации по структуре и ндекса) дл€ нахождени€ листовых блоков.
»спользуемое пространство составл€ет около 2,9 ћбайт (2859716 байтов).

SELECT v.lf_blks, v.br_blks, v.used_space, v.opt_cmpr_count, v.opt_cmpr_pctsave 
  FROM Index_Stats v;
	LF_BLKS	BR_BLKS	USED_SPACE	OPT_CMPR_COUNT	OPT_CMPR_PCTSAVE
--------------------------------------------------------------
1	398	    3	      2859716	    2	              33

—толбец OPT_CMPR_COUNT ( optimum compression count - оптимальна€ степень сжати€) говорит следующее: 
"≈сли вы сделаете этот и ндекс COMPRESS 2, то сможете получить лучшую степень сжати€". 
—толбец OPT_CMPR_PCTSAVE (optimum compression percentage saved - процент экономии при оптимальной степени сжати€) 
говорит о том, что если указать COMPRESS 2, то можно было бы сэкономить примерно одну
треть объема хранилища, а индекс занимал бы всего две трети того дискового пространства, которое он занимает сейчас.

„тобы проверить эту теорию, перестроим индекс-таблицу с опцией COMPRESS 1:

ALTER TABLE iot MOVE COMPRESS 1;

ANALYZE INDEX iot_pk VALIDATE STRUCTURE;

SELECT v.lf_blks, v.br_blks, v.used_space, v.opt_cmpr_count, v.opt_cmpr_pctsave 
  FROM Index_Stats v;
	LF_BLKS	BR_BLKS	USED_SPACE	OPT_CMPR_COUNT	OPT_CMPR_PCTSAVE
-------------------------------------------------------------- 
1	346	    3	      2486742	    2	              23


ALTER TABLE iot MOVE COMPRESS 2;

ANALYZE INDEX iot_pk VALIDATE STRUCTURE;

SELECT v.lf_blks, v.br_blks, v.used_space, v.opt_cmpr_count, v.opt_cmpr_pctsave 
  FROM Index_Stats v;
	LF_BLKS	BR_BLKS	USED_SPACE	OPT_CMPR_COUNT	OPT_CMPR_PCTSAVE
--------------------------------------------------------------  
1	266	    3	      1906515	    2	              0

“еперь мы значительно сократили размер за счет как количества листовых блоков, 
так и общего объема занимаемого пространства до примерно l,9 ћбайт.

ƒанный пример раскрывает один очень интересный факт об индекс-таблицах:
- они €вл€ютс€ таблицами, но только по названию;
- их сегмент на самом деле представл€ет собой индексный сегмент. 

BEGIN dbms_metadata.set_transform_param (dbms_metadata.SESSION_TRANSFORM, 'STORAGE', FALSE); END;

SELECT dbms_metadata.get_ddl('TABLE','T2') FROM dual;
<CLOB>
---------------------------
1 CREATE TABLE "SCOTT"."T2" 
   ( "X" NUMBER(*,0), 
	   "Y" VARCHAR2(25), 
	   "Z" DATE, 
	   PRIMARY KEY ("X") ENABLE
   ) ORGANIZATION INDEX NOCOMPRESS PCTFREE 10 INITRANS 2 MAXTRANS 255 LOGGING
     TABLESPACE "SYSTEM" 
     PCTTHRESHOLD 50 OVERFLOW
     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
     TABLESPACE "SYSTEM"


SELECT dbms_metadata.get_ddl('TABLE','T3') FROM dual;
<CLOB>
--------------------------
 CREATE TABLE "SCOTT"."T3" 
   ( "X" NUMBER(*,0), 
	   "Y" VARCHAR2(25), 
	   "Z" DATE, 
	   PRIMARY KEY ("X") ENABLE
   ) ORGANIZATION INDEX NOCOMPRESS PCTFREE 10 INITRANS 2 MAXTRANS 255 LOGGING
     TABLESPACE "SYSTEM" 
     PCTTHRESHOLD 50 INCLUDING "Y" OVERFLOW
     PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 LOGGING
     TABLESPACE "SYSTEM" 




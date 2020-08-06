/* Статистика по таблицам */
SELECT t.TABLE_NAME,
       t.TEMPORARY,
       t.LAST_ANALYZED,
       t.NUM_ROWS,
       t.GLOBAL_STATS,
       t.DURATION,
       t.MONITORING
  FROM USER_TABLES t
 ORDER BY t.LAST_ANALYZED DESC;
 
/* Сбор статистики */
BEGIN 
  -- Сбор статистики по таблице.
  dbms_stats.gather_table_stats ('SCOTT','EMP'); 
  dbms_stats.gather_table_stats (USER, 'EMP');
  
  -- Блокировать статистику для того, чтобы исключить объекты с реально большим количеством неизменных справочников.
  dbms_stats.lock_table_stats ('SCOTT','EMP'); 
  
  -- Снять блокировку.
  dbms_stats.unlock_table_stats('SCOTT','EMP');
END;

/* Сбор статистики по ВСЕМ объектам схемы */
BEGIN 
  dbms_stats.gather_schema_stats (USER); 
END;

/* Собрать статистику для индекса */
BEGIN
  dbms_stats.gather_index_stats('OWNER','INDEX_NAME');
END;

/* Статистика на секцию */
BEGIN
  dbms_stats.gather_table_stats(ownname => p_owner, tabname => p_table_name, partname => p_partition_name, DEGREE=> 4, no_invalidate=>TRUE );
END;

/* Cтатистика по таблицам */
SELECT t.table_name,
       t.last_analyzed,
       t.owner,
       t.num_rows,
       t.sample_size
  FROM DBA_TABLES t
 WHERE 1=1
   AND t.OWNER = 'SCOTT'
 ORDER BY t.last_analyzed;

/* Cтатистические данные по таблицам */
SELECT *
  FROM DBA_TAB_STATISTICS t
 WHERE 1=1
   AND t.OWNER = 'SCOTT';

/* Cтатистические данные по столбцам */
SELECT *
  FROM DBA_TAB_COL_STATISTICS t
 WHERE 1=1
   AND t.OWNER = 'SCOTT';

/* Какой в текущий момент режим оптимизатора в базе данных */
SELECT NAME,
       VALUE
  FROM V$PARAMETER
 WHERE NAME = 'optimizer_mode';

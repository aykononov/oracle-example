-- Синонимы
GRANT ALL PRIVILEGES TO hr; -- даем все права
-- Создать публичный синоним 
CREATE PUBLIC SYNONYM hr_employees FOR hr.employees@xe;
-- Удалить публичный синоним
DROP PUBLIC SYNONYM hr_employees;

SELECT * FROM hr_employees;

SELECT * FROM All_Objects ao WHERE ao.OBJECT_TYPE = 'SYNONYM' AND LOWER(ao.OBJECT_NAME) = LOWER('hr_employees');
SELECT * FROM All_Synonyms s WHERE s.SYNONYM_NAME = 'HR_EMPLOYEES';

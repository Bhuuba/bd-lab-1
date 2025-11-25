-- ІНСТРУКЦІЯ: Запустіть ці SQL скрипти в SSMS поспіль

-- 1. Спочатку запустіть DB_Schema_Full.sql (створює схему)
-- 2. Потім запустіть DB_Procedures_Views_Triggers.sql (додає SP, Views, Triggers)

-- Порядок виконання:
-- A) USE master; DROP DATABASE IF EXISTS TourismDb;
-- B) Запустіть DB_Schema_Full.sql повністю
-- C) Запустіть DB_Procedures_Views_Triggers.sql повністю

-- Перевірка:
/*
USE TourismDb;
GO

-- Перевірте таблиці
SELECT name FROM sys.tables ORDER BY name;

-- Перевірте процедури
SELECT name FROM sys.procedures WHERE type = 'P' ORDER BY name;

-- Перевірте views
SELECT name FROM sys.views WHERE type = 'V' ORDER BY name;

-- Перевірте функції
SELECT name FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') ORDER BY name;

-- Перевірте тригери
SELECT name FROM sys.triggers ORDER BY name;

-- Перевірте індекси
EXEC sp_helpindex 'Tours';
EXEC sp_helpindex 'Bookings';
*/

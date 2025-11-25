@echo off
REM Загружаем схему БД
sqlcmd -S DESKTOP-Q512LK2 -E -d TourismDb -i DB_Schema_Full.sql -b

REM Загружаем процедуры и триггеры
sqlcmd -S DESKTOP-Q512LK2 -E -d TourismDb -i DB_Procedures_Views_Triggers.sql -b

echo.
echo === Database loaded successfully ===
pause

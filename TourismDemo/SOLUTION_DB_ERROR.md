# 🔧 РІШЕННЯ: Login failed for user 'DESKTOP-Q512LK2\Влад'

## Причина помилки

Одна з причин:

1. ❌ База даних `TourismDb` не створена
2. ❌ Користувач не має дозволу на доступ до БД
3. ❌ SQL Server не запущений
4. ❌ Сервер має іншу назву (не `DESKTOP-Q512LK2`)

---

## ✅ РІШЕННЯ (Крок за кроком)

### Крок 1: Відкрити SQL Server Management Studio

1. Запустіть **SQL Server Management Studio** (SSMS)
2. У вікні "Connect to Server":
   - **Server name:** введіть назву вашого сервера
   - Якщо ви не знаєте назву, залиште `(local)` або `.`
   - **Authentication:** виберіть `Windows Authentication`
   - Натисніть **Connect**

### Крок 2: Отримати точну назву сервера

Якщо ви підключилися, у SSMS:

1. Знайдіть на верхній частині вікна назву сервера (справа від логотипу)
2. Скопіюйте цю назву (наприклад: `LAPTOP-ABC123\SQLEXPRESS` або `(local)`)

### Крок 3: Перевірити/Створити базу даних

У SSMS виконайте SQL скрипт:

```sql
-- Створити базу даних (якщо не існує)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TourismDb')
BEGIN
    CREATE DATABASE TourismDb;
END
GO

-- Перейти до бази
USE TourismDb;
GO

-- Створити таблиці тестових даних
CREATE TABLE Tours (
    TourId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Rating DECIMAL(3, 1) NOT NULL,
    IsActive BIT DEFAULT 1
);

CREATE TABLE Bookings (
    BookingId INT PRIMARY KEY IDENTITY(1,1),
    TourId INT NOT NULL,
    TouristId INT NOT NULL,
    TravelDate DATE NOT NULL,
    BookingDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TourId) REFERENCES Tours(TourId)
);

-- Вставити тестові дані
INSERT INTO Tours (Name, Country, City, Price, Rating, IsActive) VALUES
('Європейський тур', 'Франція', 'Париж', 1500.00, 4.8, 1),
('Подорож на Карпати', 'Україна', 'Львів', 500.00, 4.5, 1),
('Італійський відпочинок', 'Італія', 'Рим', 2000.00, 4.9, 1),
('Пляжний рай', 'Греція', 'Афіни', 1200.00, 4.7, 1),
('Азійське дослідження', 'Таїланд', 'Бангкок', 800.00, 4.6, 1);

-- Створити view
CREATE VIEW vw_ActiveTours AS
SELECT TourId, Name, Country, City, Price, Rating
FROM Tours
WHERE IsActive = 1;

-- Створити stored procedure
CREATE PROCEDURE sp_CreateBooking
    @TourId INT,
    @TouristId INT,
    @TravelDate DATE,
    @BookingId INT OUTPUT
AS
BEGIN
    BEGIN TRY
        INSERT INTO Bookings (TourId, TouristId, TravelDate)
        VALUES (@TourId, @TouristId, @TravelDate);

        SET @BookingId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
```

### Крок 4: Оновити connection string в проєкті

1. Відкрийте файл `appsettings.json` у проєкті
2. Замініть `Server=DESKTOP-Q512LK2` на вашу назву сервера:

**Приклади:**

- Якщо сервер називається `LAPTOP-XYZ\SQLEXPRESS`:

  ```json
  "Server=LAPTOP-XYZ\\SQLEXPRESS;Database=TourismDb;Trusted_Connection=True;TrustServerCertificate=True;"
  ```

- Якщо це локальний сервер:

  ```json
  "Server=(local);Database=TourismDb;Trusted_Connection=True;TrustServerCertificate=True;"
  ```

- Або просто точка (`.`):
  ```json
  "Server=.;Database=TourismDb;Trusted_Connection=True;TrustServerCertificate=True;"
  ```

### Крок 5: Знайти точну назву сервера (PowerShell)

Якщо ви не знаєте назву сервера, запустіть у PowerShell:

```powershell
# Перевірити доступні SQL Server екземпляри
$instances = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -Name | Where-Object { $_ -ne "CurrentVersion" }
$instances

# Або за допомогою командного рядка
sqlcmd -L
```

### Крок 6: Запустити проект знову

```bash
cd "C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo"
dotnet run
```

---

## 🆘 ЯКЩО ПРОБЛЕМА ЗАЛИШИЛАСЬ

### ✓ Перевірити статус SQL Server

```powershell
# Перевірити статус служби
Get-Service -Name MSSQLSERVER
# Якщо статус "Stopped", запустити:
Start-Service -Name MSSQLSERVER
```

### ✓ Перевірити з'єднання через PowerShell

```powershell
# Спробувати підключитись
sqlcmd -S . -E

# Якщо запитує пароль, то спробуйте через SSMS
```

### ✓ Дозволи на БД

Якщо ви створили БД, але користувач не має дозволу:

```sql
-- У SSMS під адміністратором виконайте:
USE TourismDb;
GO

CREATE USER [DESKTOP-Q512LK2\Влад] FOR LOGIN [DESKTOP-Q512LK2\Влад];
ALTER ROLE db_owner ADD MEMBER [DESKTOP-Q512LK2\Влад];
GO
```

---

## 📝 ВЕРСІЯ З SQL AUTHENTICATION (Альтернатива)

Якщо Trusted_Connection не працює, можна використовувати SQL порт:

1. **У SSMS** створіть користувача:

   ```sql
   CREATE LOGIN [sa_demo] WITH PASSWORD = 'Password123!';
   CREATE USER [sa_demo] FOR LOGIN [sa_demo];
   ALTER ROLE db_owner ADD MEMBER [sa_demo];
   GO
   ```

2. **У `appsettings.json`** змініть:
   ```json
   "Server=.;Database=TourismDb;User Id=sa_demo;Password=Password123!;"
   ```

---

## ✅ ЧЕКЛИСТ

- [ ] SQL Server Management Studio встановлений
- [ ] Підключився до SQL Server
- [ ] Створена база даних `TourismDb`
- [ ] Виконав SQL скрипт (таблиці + view + SP)
- [ ] Знайшов точну назву сервера
- [ ] Оновив `appsettings.json` з правильним сервером
- [ ] Перевірив дозволи користувача
- [ ] SQL Server служба запущена

---

## 📍 МІСЦЕЗНАХОДЖЕННЯ ФАЙЛУ

Файл для редагування:

```
C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo\appsettings.json
```

---

Після того як виконаєте ці кроки, запустіть проект знову!

**Якщо все ще не працює, розповіді:**

1. Яка точна назва SQL Server сервера?
2. Під яким користувачем ви працюєте?
3. Яку версію SSMS ви маєте?

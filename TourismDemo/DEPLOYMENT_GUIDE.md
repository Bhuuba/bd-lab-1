# ІНСТРУКЦІЯ РОЗГОРТАННЯ - Екосистема туризму

**Статус:** Готовий до розгортання на SQL Server  
**Версія:** 2.0 Production Ready

---

## ⚠️ ВАЖЛИВО - Перш ніж запускати

### Вимоги системи:

- ✅ Windows 10+ або Windows Server
- ✅ SQL Server 2016+ (Express, Developer, Enterprise)
- ✅ .NET 8.0 Runtime/SDK
- ✅ Visual Studio 2022 або VS Code + C# Extension

### Перевірка SQL Server:

**Варіант 1: Перевірити через SQL Server Management Studio**

```
1. Відкрити SSMS
2. Connect to: DESKTOP-Q512LK2 (за замовчуванням)
3. Authentication: Windows Authentication
4. Click Connect
```

**Варіант 2: Перевірити через PowerShell**

```powershell
# Перевірити SQL Server сервіси
Get-Service | Where-Object {$_.Name -like "*SQL*"} | Select Name, Status

# Повинен вивести щось на кшталт:
# Name                    Status
# ---- -----
# MSSQLSERVER             Running
# SQLBrowser              Running
```

---

## 🚀 КРОК ЗА КРОКОМ - Розгортання

### КРОК 1: Створити базу даних (SQL Server)

Виконайте **DB_Schema_Full.sql** в SSMS:

```sql
-- Файл: TourismDemo/SQL/DB_Schema_Full.sql
-- Дія: Створить базу даних TourismDb з 16 таблицями
-- Час виконання: ~5 секунд
-- Результат: 16 таблиць + 10+ індексів + тестові дані
```

**Инструкция:**

1. Відкрити SSMS
2. Нові запит (New Query)
3. Скопіювати вміст `DB_Schema_Full.sql`
4. Виконати (Execute або F5)
5. Переконатися, що вивід: "Команда (і команди) виконана успішно"

**Перевірка:**

```sql
-- Перевірити таблиці
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo';

-- Повинен вивести 16 таблиць:
-- Users
-- Countries
-- Regions
-- Cities
-- TourCategories
-- Tours
-- TourSchedules
-- Guides
-- GuideAssignments
-- TouristProfiles
-- PaymentMethods
-- Bookings
-- Payments
-- Reviews
-- TourCategoryMaps
-- AuditLog
```

---

### КРОК 2: Створити об'єкти БД (Procedures, Views, Triggers)

Виконайте **DB_Procedures_Views_Triggers.sql** в SSMS:

```sql
-- Файл: TourismDemo/SQL/DB_Procedures_Views_Triggers.sql
-- Дія: Створить 5 SP + 2 Functions + 5 Views + 3 Triggers
-- Час виконання: ~3 секунди
-- Результат: 15 SQL об'єктів готових до роботи
```

**Инструкция:**

1. Відкрити нові запит
2. Скопіювати вміст `DB_Procedures_Views_Triggers.sql`
3. Виконати (F5)
4. Результат: "Команда (і команди) виконана успішно"

**Перевірка:**

```sql
-- Перевірити процедури
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE';

-- Повинен вивести:
-- sp_CreateBooking
-- sp_DeleteBooking
-- sp_GetUserBookings
-- sp_CreateReview
-- sp_ConfirmPayment

-- Перевірити представлення
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='VIEW';

-- Повинен вивести:
-- vw_UserBookingDetails
-- vw_ActiveGuides
-- vw_PopularTours
-- vw_AllActiveTours
-- vw_ConfirmedBookings
```

---

### КРОК 3: Запустити .NET додаток

```bash
# Перейти в папку проекту
cd "C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo"

# Запустити додаток
dotnet run

# Очікуваний вивід:
# Now listening on: http://localhost:5026
# Application started. Press Ctrl+C to shut down.
```

---

### КРОК 4: Тестування API

**Варіант A: Через Swagger UI (рекомендується)**

```
1. Відкрити браузер
2. Перейти на: https://localhost:5026/swagger
3. Розглянути всі endpoints
4. Натиснути "Try it out" для тестування
```

**Варіант B: Через PowerShell**

```powershell
# Отримати всі тури
Invoke-WebRequest -Uri "http://localhost:5026/api/tours" -Method Get | Select-Object StatusCode

# Отримати всі бронювання
Invoke-WebRequest -Uri "http://localhost:5026/api/bookings" -Method Get | Select-Object StatusCode

# Створити нове бронювання
$body = @{
    tourId = 1
    touristId = 1
    travelDate = "2024-06-15"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:5026/api/bookings" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body | Select-Object StatusCode

# Отримати рецензії туру
Invoke-WebRequest -Uri "http://localhost:5026/api/tours/1/reviews" -Method Get | Select-Object StatusCode
```

**Варіант C: Через cURL**

```bash
# Отримати тури
curl http://localhost:5026/api/tours

# Отримати бронювання
curl http://localhost:5026/api/bookings
```

---

## 📊 Тестові дані

### Передбачені дані в БД:

**Користувачі:**

- ID 1: Іван Петрович (ivan@tourism.ua)
- ID 2: Марія Сергіївна (maria@tourism.ua)
- ID 3: Петро Іванович (petro@tourism.ua)

**Країни:**

- ID 1: Ukraine
- ID 2: Poland
- ID 3: Germany
- ID 4: France
- ID 5: Italy

**Міста:**

- Kyiv, Lviv, Kharkiv (Ukraine)
- Warsaw (Poland)
- Berlin (Germany)

**Тури:**

- ID 1: "Kyiv City Tour" - 2000 UAH
- ID 2: "Carpathian Mountains Trek" - 3500 UAH
- ID 3: "Lviv Old Town" - 1500 UAH
- ID 4: "Black Sea Resort" - 2500 UAH
- ID 5: "Danube River Cruise" - 5000 UAH

---

## 🔍 Основні SQL запити для перевірки

```sql
-- 1. Див. всі тури
SELECT * FROM vw_AllActiveTours;

-- 2. Див. популярні тури
SELECT TOP 5 * FROM vw_PopularTours;

-- 3. Див. всі бронювання з деталями
SELECT * FROM vw_UserBookingDetails;

-- 4. Див. активних гайдів
SELECT * FROM vw_ActiveGuides;

-- 5. Див. аудит-логи
SELECT TOP 10 * FROM AuditLog ORDER BY ModifiedDate DESC;

-- 6. Отримати середній рейтинг туру #1
SELECT dbo.fn_GetAverageRating(1) AS AverageRating;

-- 7. Отримати кількість бронювань за період
SELECT dbo.fn_GetBookingCount('2024-01-01', '2024-12-31') AS BookingCount;
```

---

## 🚨 Усунення проблем

### Проблема: "Cannot open database TourismDb"

**Рішення:**

```
1. Переконатися, що SQL Server запущений
   - Services > SQL Server (MSSQLSERVER) = Started

2. Переконатися, що БД TourismDb існує
   - Виконати DB_Schema_Full.sql ще раз

3. Перевірити connection string в appsettings.json
   - Server=DESKTOP-Q512LK2;Database=TourismDb;
   - TrustServerCertificate=True;
```

### Проблема: "Login failed for user 'DESKTOP-Q512LK2\Влад'"

**Рішення:**

```
1. Виконати SQL скрипт як адміністратор
2. Переконатися, що використовується Windows Authentication
3. Перевірити права користувача на SQL Server
```

### Проблема: "Named Pipes Provider could not open a connection"

**Рішення:**

```
1. Переконатися, що Named Pipes включений
   - SQL Server Configuration Manager > Protocols > Named Pipes = Enabled

2. Перезапустити SQL Server
   - Services > SQL Server (MSSQLSERVER) > Restart

3. Перезапустити додаток
```

### Проблема: Додаток запускається, але API повертає помилку

**Рішення:**

```
1. Перевірити логи в консолі
2. Переконатися, що БД таблиці заповнені тестовими даними
3. Перевірити connection string у appsettings.json
```

---

## 📁 Список файлів для розгортання

```
Обов'язкові файли:
✅ TourismDemo.csproj          - Конфігурація проекту
✅ Program.cs                  - API endpoints
✅ appsettings.json            - Connection string
✅ Data/DTOs/AllDtos.cs        - DTOs
✅ Data/Repositories/          - Repository implementations
✅ Data/UnitOfWork/            - UoW pattern
✅ wwwroot/index.html          - Frontend

SQL скрипти:
✅ SQL/DB_Schema_Full.sql                    - Схема БД
✅ SQL/DB_Procedures_Views_Triggers.sql      - SQL об'єкти
```

---

## 📈 Архітектура розгортання

```
┌─────────────────────────┐
│   Windows System        │
│  (DESKTOP-Q512LK2)      │
├─────────────────────────┤
│  SQL Server             │
│  (TourismDb)            │
│  - 16 Tables            │
│  - 5 Procedures         │
│  - 2 Functions          │
│  - 5 Views              │
│  - 3 Triggers           │
├─────────────────────────┤
│  .NET 8 Runtime         │
│  (dotnet run)           │
├─────────────────────────┤
│  ASP.NET Core App       │
│  (localhost:5026)       │
├─────────────────────────┤
│  Browser / API Client   │
│  (Swagger/cURL/PowerShell)
└─────────────────────────┘
```

---

## ✅ Контрольний список розгортання

- [ ] SQL Server перевірений і запущений
- [ ] DB_Schema_Full.sql виконаний
- [ ] DB_Procedures_Views_Triggers.sql виконаний
- [ ] Таблиці створені (16 таблиць)
- [ ] Процедури створені (5 SP)
- [ ] Представлення створені (5 Views)
- [ ] Тестові дані завантажені
- [ ] .NET додаток зібраний (dotnet build)
- [ ] Додаток запущений (dotnet run)
- [ ] Swagger доступний (localhost:5026/swagger)
- [ ] GET /api/tours повертає дані
- [ ] Бронювання могли бути створені

---

## 📞 Підтримка

Якщо виникнуть проблеми:

1. **Перевірити логи:**

   ```bash
   Див. консоль dotnet run
   ```

2. **Перевірити БД:**

   ```sql
   -- В SSMS
   SELECT * FROM Tours;
   SELECT * FROM Bookings;
   ```

3. **Перевірити connection string:**
   ```json
   // appsettings.json
   "Server=DESKTOP-Q512LK2;Database=TourismDb;..."
   ```

---

**Версія:** 2.0  
**Остання оновлення:** 2024  
**Статус:** Production Ready ✅

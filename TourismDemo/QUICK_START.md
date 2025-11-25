## 🚀 QUICK START - ШВИДКИЙ СТАРТ

### Варіант 1: Через PowerShell скрипт (найпростіший)

```powershell
# Виконати скрипт в PowerShell
C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo\run.ps1
```

### Варіант 2: Вручну через Terminal в VS Code

1. **Відкрити VS Code**

   ```bash
   code "C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo"
   ```

2. **Відкрити Terminal** (`Ctrl+` або меню Terminal → New Terminal)

3. **Запустити проект**

   ```bash
   dotnet run
   ```

4. **Дочекатися запуску** (займе ~3-5 секунд)

   - Побачите щось на кшталт:

   ```
   info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:5001
   info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
   ```

5. **Відкрити браузер** та перейти на одну з адрес:
   - 🌐 Веб-сайт: `https://localhost:5001`
   - 📚 API документація: `https://localhost:5001/swagger`

---

## ✅ ЩО БУДЕ ПРАЦЮВАТИ

### На сторінці https://localhost:5001:

**✓ Таблиця "Доступні тури"**

- Автоматично завантажує дані з БД при відкритті сторінки
- Виконує GET запит: `GET /api/tours`
- Отримує список турів з view `vw_ActiveTours`

**✓ Форма "Забронювати тур"**

- Поля: Tour ID, Tourist ID, Travel Date
- При сабміту виконує: `POST /api/bookings`
- Викликає stored procedure `sp_CreateBooking`
- Отримує ID нового бронювання

### На сторінці https://localhost:5001/swagger:

**✓ API Документація**

- GET /api/tours - список турів
- POST /api/bookings - створити бронювання
- Можна тестувати прямо в Swagger UI

---

## 🔧 НАЛАШТУВАННЯ БД

Перед запуском переконайтесь, що у MS SQL Server:

1. **Існує база даних `TourismDb`**

2. **Створена view `vw_ActiveTours`:**

   ```sql
   CREATE VIEW vw_ActiveTours AS
   SELECT
       TourId,
       Name,
       Country,
       City,
       Price,
       Rating
   FROM Tours
   WHERE IsActive = 1; -- або інша умова активності
   ```

3. **Створена stored procedure `sp_CreateBooking`:**
   ```sql
   CREATE PROCEDURE sp_CreateBooking
       @TourId INT,
       @TouristId INT,
       @TravelDate DATE,
       @BookingId INT OUTPUT
   AS
   BEGIN
       INSERT INTO Bookings (TourId, TouristId, TravelDate, BookingDate)
       VALUES (@TourId, @TouristId, @TravelDate, GETDATE());

       SET @BookingId = SCOPE_IDENTITY();
   END;
   ```

---

## 📁 СТРУКТУРА ФАЙЛІВ

```
TourismDemo/
├── 📁 Data/
│   ├── 📁 DTOs/
│   │   └── TourDto.cs                  # Модель туру
│   ├── 📁 Repositories/
│   │   ├── 📁 Interfaces/
│   │   │   ├── ITourRepository.cs      # Інтерфейс для турів
│   │   │   └── IBookingRepository.cs   # Інтерфейс для бронювань
│   │   ├── SqlTourRepository.cs        # Реалізація - читання турів
│   │   └── SqlBookingRepository.cs     # Реалізація - бронювання
│   └── 📁 UnitOfWork/
│       ├── 📁 Interfaces/
│       │   └── IUnitOfWork.cs          # Координатор репозиторіїв
│       └── SqlUnitOfWork.cs            # Реалізація Unit of Work
├── 📁 wwwroot/
│   └── index.html                      # Фронтенд (HTML + JS)
├── 📁 Properties/
│   └── launchSettings.json             # Налаштування запуску
├── Program.cs                          # Точка входу + конфігурація
├── appsettings.json                    # Connection string
├── TourismDemo.csproj                  # Файл проєкту
├── README.md                           # Документація (укр.)
├── CODE_REFERENCE.md                   # Повний код файлів
└── run.ps1                             # Скрипт запуску
```

---

## 🛠️ ТЕХНІЧНИЙ СТЕК

- ✅ .NET 8.0 (LTS)
- ✅ ASP.NET Core Minimal APIs
- ✅ ADO.NET (System.Data.SqlClient)
- ✅ MS SQL Server
- ✅ Swagger / OpenAPI
- ✅ Dependency Injection
- ✅ Repository Pattern + Unit of Work
- ✅ HTML 5 + Vanilla JavaScript
- ✅ CSS 3 (Flexbox + Grid)

---

## 🎓 НАВЧАЛЬНІ ЦІЛІ

Проект демонструє:

1. **Підключення до БД** через ADO.NET (без ORM)
2. **Design Pattern'и**: Repository, Unit of Work, DI
3. **Async/Await** для асинхронних операцій
4. **Minimal APIs** в ASP.NET Core
5. **SQL запити** до view та stored procedures
6. **REST API** з правильними HTTP методами
7. **Фронтенд** з fetch API
8. **Обробка помилок** та вивід повідомлень

---

## ⚠️ ВАЖЛИВО

- Проект **НЕ** використовує Entity Framework Core
- Усі запити виконуються через **view** та **stored procedures**
- SqlConnection заповідувач з DI контейнера як `Scoped`
- При розробці Swagger доступний на `/swagger`
- Connection string для HTTPS налаштований як `TrustServerCertificate=True`

---

## 🐛 МОЖЛИВІ ПРОБЛЕМИ

### Помилка: "Cannot connect to database"

→ Перевірте:

- MS SQL Server запущений
- Сервер: `DESKTOP-Q512LK2` доступний
- База даних `TourismDb` існує
- Користувач має дозвіл на доступ

### Помилка: "Connection string not found"

→ Перевірте `appsettings.json` має правильний `ConnectionStrings`

### HTTPS помилка в браузері

→ Це нормально для localhost. Натисніть "Advanced" → "Continue"

### Port занятий (5001)

→ Змініть порт в `Properties/launchSettings.json`

---

## 📚 КОРИСНІ ПОСИЛАННЯ

- https://localhost:5001 - Веб-додаток
- https://localhost:5001/swagger - API документація
- Код в: `CODE_REFERENCE.md`
- Детальна документація: `README.md`

---

## 💡 ПОДАЛЬШІ РОЗШИРЕННЯ

- [ ] Додати аутентифікацію
- [ ] Реалізувати транзакції
- [ ] Додати логування (Serilog)
- [ ] Unit/Integration тести
- [ ] Лучший фронтенд (React/Vue)
- [ ] Валідація вхідних даних
- [ ] Кеширування
- [ ] API версіонування

---

**Готово! 🎉 Тепер можете запускати проект і тестувати БД!**

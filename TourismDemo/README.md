# TourismDemo - Навчальний проєкт для демонстрації БД туризму

## Опис

Навчальний проект .NET 8 Minimal API для демонстрації роботи бази даних туризму. Проект демонструє:

- Connecting до SQL Server через ADO.NET
- Роботу з Dependency Injection
- Repository Pattern та Unit of Work
- Minimal APIs в ASP.NET Core
- Взаємодію з view та stored procedures

## Структура проєкту

```
TourismDemo/
├── Data/
│   ├── DTOs/
│   │   └── TourDto.cs
│   ├── Repositories/
│   │   ├── Interfaces/
│   │   │   ├── ITourRepository.cs
│   │   │   └── IBookingRepository.cs
│   │   ├── SqlTourRepository.cs
│   │   └── SqlBookingRepository.cs
│   └── UnitOfWork/
│       ├── Interfaces/
│       │   └── IUnitOfWork.cs
│       └── SqlUnitOfWork.cs
├── wwwroot/
│   └── index.html
├── Program.cs
├── appsettings.json
└── TourismDemo.csproj
```

## Вимоги

- .NET 8.0 SDK
- MS SQL Server (DESKTOP-Q512LK2)
- База даних `TourismDb` з об'єктами:
  - View: `vw_ActiveTours(TourId, Name, Country, City, Price, Rating)`
  - Stored Procedure: `sp_CreateBooking(@TourId INT, @TouristId INT, @TravelDate DATE, @BookingId INT OUTPUT)`

## Встановлення та запуск

### 1. Відкрити папку проєкту в VS Code

```bash
code "C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo"
```

### 2. Восстановити залежності (опціонально, `dotnet run` робить це автоматично)

```bash
dotnet restore
```

### 3. Запустити проект

```bash
dotnet run
```

Проект автоматично завантажиться на `https://localhost:5001` (або інший port, дивіться консоль).

## Использование

### Веб-інтерфейс

Відкрийте в браузері: `https://localhost:5001`

На сторінці ви побачите:

- **Таблиця "Доступні тури"** - відображає всі активні тури з БД
- **Форма "Забронювати тур"** - для створення нового бронювання

### Swagger API документація

Для тестування API перейдіть на: `https://localhost:5001/swagger`

Доступні ендпойнти:

#### GET /api/tours

Отримати список усіх активних турів.

**Response (200 OK):**

```json
[
  {
    "tourId": 1,
    "name": "Європейський тур",
    "country": "Франція",
    "city": "Париж",
    "price": 1500.0,
    "rating": 4.8
  }
]
```

#### POST /api/bookings

Створити нове бронювання.

**Request:**

```json
{
  "tourId": 1,
  "touristId": 123,
  "travelDate": "2024-12-25"
}
```

**Response (200 OK):**

```json
{
  "bookingId": 42
}
```

**Response (400 Bad Request):**

```json
{
  "error": "Опис помилки"
}
```

## Архітектура

### Шари

1. **Program.cs**

   - Налаштування DI контейнеру
   - Реєстрація маршрутів (Minimal APIs)
   - Налаштування Swagger

2. **Data Layer**

   - **DTOs**: `TourDto` - моделі для передачі даних
   - **Repositories**:
     - `ITourRepository` - интерфейс для роботи з турами
     - `IBookingRepository` - інтерфейс для роботи з бронюваннями
   - **Unit of Work**:
     - `IUnitOfWork` - координує роботу репозиторіїв
     - `SqlUnitOfWork` - реалізація для SQL Server

3. **Frontend**
   - `wwwroot/index.html` - простий HTML + JavaScript
   - Fetch API для взаємодії з бекендом
   - Таблиця для відображення турів
   - Форма для бронювання

## Деталі реалізації

### SqlTourRepository

- Читає дані з view `vw_ActiveTours`
- Використовує `SqlCommand` з `SELECT`
- Відповідає за маппінг результатів у `TourDto`

### SqlBookingRepository

- Викликає stored procedure `sp_CreateBooking`
- Передає параметри: `@TourId`, `@TouristId`, `@TravelDate`
- Отримує OUTPUT параметр `@BookingId`

### SqlUnitOfWork

- Зберігає єдиний `SqlConnection`
- Ліниво ініціалізує репозиторії (Lazy Initialization)
- Реалізує `IAsyncDisposable` для правильного закриття з'єднання

## Налаштування підключення

Рядок підключення зберігається в `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "TourismDb": "Server=DESKTOP-Q512LK2;Database=TourismDb;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

Якщо потрібно змінити сервер, відредагуйте значення `Server=DESKTOP-Q512LK2`.

## Примітки

- Проект використовує `System.Data.SqlClient` (замість Entity Framework Core)
- Усі запити виконуються через views та stored procedures
- Підключення реєструється в DI як `Scoped` (одне на request)
- Middleware `UseDefaultFiles()` та `UseStaticFiles()` дозволяють роздачу статичних файлів
- Swagger увімкнено в режимі розробки

## Можливі розширення

- Додати аутентифікацію
- Реалізувати паралельні операції
- Додати логування
- Покрити unit-тестами
- Розширити фронтенд з більшою функціональністю

## Автор та ліцензія

Навчальний проект для демонстрації роботи з БД.

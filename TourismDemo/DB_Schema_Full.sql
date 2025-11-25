-- ========================================
-- ЕКОСИСТЕМА ТУРИЗМУ - ПОВНА СХЕМА БД
-- Мінімум 15 сутностей з усіма властивостями
-- ========================================

USE TourismDb;
GO

-- ========================================
-- ОЧИСТКА (для переустановлення)
-- ========================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Users_Audit')
    DROP TRIGGER trg_Users_Audit;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Bookings_Audit')
    DROP TRIGGER trg_Bookings_Audit;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Reviews_UpdateModified')
    DROP TRIGGER trg_Reviews_UpdateModified;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DeleteBooking')
    DROP PROCEDURE sp_DeleteBooking;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GetUserBookings')
    DROP PROCEDURE sp_GetUserBookings;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CreateReview')
    DROP PROCEDURE sp_CreateReview;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_GetAverageRating')
    DROP FUNCTION fn_GetAverageRating;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_UserBookingDetails')
    DROP VIEW vw_UserBookingDetails;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_ActiveGuides')
    DROP VIEW vw_ActiveGuides;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_PopularTours')
    DROP VIEW vw_PopularTours;

-- Drop tables (в зворотному порядку через FK)
DROP TABLE IF EXISTS GuideAssignments;
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS TourCategoryMaps;
DROP TABLE IF EXISTS TourSchedules;
DROP TABLE IF EXISTS Tours;
DROP TABLE IF EXISTS Guides;
DROP TABLE IF EXISTS TouristProfiles;
DROP TABLE IF EXISTS PaymentMethods;
DROP TABLE IF EXISTS TourCategories;
DROP TABLE IF EXISTS Cities;
DROP TABLE IF EXISTS Regions;
DROP TABLE IF EXISTS Countries;
DROP TABLE IF EXISTS Users;

GO

-- ========================================
-- 1. USERS - користувачі системи
-- ========================================
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    PhoneNumber NVARCHAR(20),
    UserRole NVARCHAR(50) NOT NULL, -- Admin, Tourist, Guide
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    CreatedBy NVARCHAR(100) DEFAULT 'SYSTEM',
    ModifiedDate DATETIME NULL,
    ModifiedBy NVARCHAR(100) NULL,
    CONSTRAINT chk_UserRole CHECK (UserRole IN ('Admin', 'Tourist', 'Guide'))
);

-- ========================================
-- 2. COUNTRIES - країни
-- ========================================
CREATE TABLE Countries (
    CountryId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Code NVARCHAR(3) NOT NULL UNIQUE, -- ISO код
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- ========================================
-- 3. REGIONS - регіони
-- ========================================
CREATE TABLE Regions (
    RegionId INT PRIMARY KEY IDENTITY(1,1),
    CountryId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CountryId) REFERENCES Countries(CountryId)
);

-- ========================================
-- 4. CITIES - міста
-- ========================================
CREATE TABLE Cities (
    CityId INT PRIMARY KEY IDENTITY(1,1),
    RegionId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Latitude DECIMAL(10, 8),
    Longitude DECIMAL(11, 8),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (RegionId) REFERENCES Regions(RegionId)
);

-- ========================================
-- 5. TOUSCATEGORIES - категорії турів
-- ========================================
CREATE TABLE TourCategories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE, -- Adventure, Cultural, Beach, etc.
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- ========================================
-- 6. TOURS - основна таблиця турів
-- ========================================
CREATE TABLE Tours (
    TourId INT PRIMARY KEY IDENTITY(1,1),
    DestinationCityId INT NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    DurationDays INT NOT NULL,
    MaxParticipants INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Difficulty NVARCHAR(50) NOT NULL, -- Easy, Medium, Hard
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    CreatedBy NVARCHAR(100) DEFAULT 'SYSTEM',
    ModifiedDate DATETIME NULL,
    ModifiedBy NVARCHAR(100) NULL,
    FOREIGN KEY (DestinationCityId) REFERENCES Cities(CityId),
    CONSTRAINT chk_Difficulty CHECK (Difficulty IN ('Easy', 'Medium', 'Hard')),
    CONSTRAINT chk_MaxParticipants CHECK (MaxParticipants > 0),
    CONSTRAINT chk_DurationDays CHECK (DurationDays > 0)
);

-- ========================================
-- 7. TOURSCHEDULES - розклад турів
-- ========================================
CREATE TABLE TourSchedules (
    ScheduleId INT PRIMARY KEY IDENTITY(1,1),
    TourId INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    AvailableSpots INT NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Open', -- Open, Closed, Cancelled
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TourId) REFERENCES Tours(TourId),
    CONSTRAINT chk_ScheduleStatus CHECK (Status IN ('Open', 'Closed', 'Cancelled')),
    CONSTRAINT chk_DateRange CHECK (EndDate >= StartDate)
);

-- ========================================
-- 8. GUIDES - гіди
-- ========================================
CREATE TABLE Guides (
    GuideId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL UNIQUE,
    Specialization NVARCHAR(100),
    Experience INT, -- років досвіду
    Languages NVARCHAR(MAX), -- JSON або CSV
    AverageRating DECIMAL(3, 1),
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- ========================================
-- 9. GUIDEASSIGNMENTS - призначення гідів
-- ========================================
CREATE TABLE GuideAssignments (
    AssignmentId INT PRIMARY KEY IDENTITY(1,1),
    ScheduleId INT NOT NULL,
    GuideId INT NOT NULL,
    AssignmentDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ScheduleId) REFERENCES TourSchedules(ScheduleId),
    FOREIGN KEY (GuideId) REFERENCES Guides(GuideId),
    UNIQUE(ScheduleId, GuideId)
);

-- ========================================
-- 10. TOURISTPROFILES - профілі туристів
-- ========================================
CREATE TABLE TouristProfiles (
    TouristId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL UNIQUE,
    Nationality NVARCHAR(100),
    PassportNumber NVARCHAR(50),
    DateOfBirth DATE,
    PreferredLanguage NVARCHAR(20) DEFAULT 'en',
    SpecialRequirements NVARCHAR(MAX),
    Allergies NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- ========================================
-- 11. PAYMENTMETHODS - методи оплати
-- ========================================
CREATE TABLE PaymentMethods (
    PaymentMethodId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE, -- CreditCard, PayPal, BankTransfer
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- ========================================
-- 12. BOOKINGS - бронювання
-- ========================================
CREATE TABLE Bookings (
    BookingId INT PRIMARY KEY IDENTITY(1,1),
    ScheduleId INT NOT NULL,
    TouristId INT NOT NULL,
    BookingDate DATETIME DEFAULT GETDATE(),
    NumberOfPeople INT NOT NULL,
    TotalPrice DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Confirmed, Cancelled
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    CreatedBy NVARCHAR(100) DEFAULT 'SYSTEM',
    ModifiedDate DATETIME NULL,
    ModifiedBy NVARCHAR(100) NULL,
    FOREIGN KEY (ScheduleId) REFERENCES TourSchedules(ScheduleId),
    FOREIGN KEY (TouristId) REFERENCES TouristProfiles(TouristId),
    CONSTRAINT chk_BookingStatus CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    CONSTRAINT chk_NumberOfPeople CHECK (NumberOfPeople > 0)
);

-- ========================================
-- 13. PAYMENTS - платежі
-- ========================================
CREATE TABLE Payments (
    PaymentId INT PRIMARY KEY IDENTITY(1,1),
    BookingId INT NOT NULL,
    PaymentMethodId INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    TransactionId NVARCHAR(100),
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending', -- Pending, Completed, Failed
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BookingId) REFERENCES Bookings(BookingId),
    FOREIGN KEY (PaymentMethodId) REFERENCES PaymentMethods(PaymentMethodId),
    CONSTRAINT chk_PaymentStatus CHECK (Status IN ('Pending', 'Completed', 'Failed')),
    CONSTRAINT chk_Amount CHECK (Amount > 0)
);

-- ========================================
-- 14. REVIEWS - відгуки про тури
-- ========================================
CREATE TABLE Reviews (
    ReviewId INT PRIMARY KEY IDENTITY(1,1),
    TourId INT NOT NULL,
    TouristId INT NOT NULL,
    Rating INT NOT NULL,
    Title NVARCHAR(200),
    Comment NVARCHAR(MAX),
    IsDeleted BIT DEFAULT 0, -- Soft Delete
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME NULL,
    ModifiedBy NVARCHAR(100) NULL,
    FOREIGN KEY (TourId) REFERENCES Tours(TourId),
    FOREIGN KEY (TouristId) REFERENCES TouristProfiles(TouristId),
    CONSTRAINT chk_Rating CHECK (Rating >= 1 AND Rating <= 5)
);

-- ========================================
-- 15. TOURTATEGORYMAPS - зв'язок турів та категорій
-- ========================================
CREATE TABLE TourCategoryMaps (
    MapId INT PRIMARY KEY IDENTITY(1,1),
    TourId INT NOT NULL,
    CategoryId INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TourId) REFERENCES Tours(TourId),
    FOREIGN KEY (CategoryId) REFERENCES TourCategories(CategoryId),
    UNIQUE(TourId, CategoryId)
);

-- ========================================
-- 16. AUDITLOG - журнал аудиту
-- ========================================
CREATE TABLE AuditLog (
    AuditId INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100) NOT NULL,
    RecordId INT NOT NULL,
    Action NVARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ModifiedBy NVARCHAR(100) NOT NULL,
    ModifiedDate DATETIME DEFAULT GETDATE()
);

GO

-- ========================================
-- ІНДЕКСИ (КРОК 4)
-- ========================================

-- Non-clustered Index на часто користуваних полях
CREATE NONCLUSTERED INDEX idx_Users_Email ON Users(Email);
CREATE NONCLUSTERED INDEX idx_Users_IsDeleted ON Users(IsDeleted, IsActive);
CREATE NONCLUSTERED INDEX idx_Bookings_ScheduleId ON Bookings(ScheduleId);
CREATE NONCLUSTERED INDEX idx_Bookings_TouristId ON Bookings(TouristId);
CREATE NONCLUSTERED INDEX idx_Bookings_Status ON Bookings(Status);

-- Composite Index (кілька колонок)
CREATE NONCLUSTERED INDEX idx_Tours_Active_Deleted ON Tours(IsActive, IsDeleted);
CREATE NONCLUSTERED INDEX idx_TourSchedules_TourId_StartDate ON TourSchedules(TourId, StartDate);
CREATE NONCLUSTERED INDEX idx_Reviews_TourId_Rating ON Reviews(TourId, Rating);
CREATE NONCLUSTERED INDEX idx_Bookings_BookingDate_Status ON Bookings(BookingDate, Status);

-- Full-text Search Index (на текстові поля)
CREATE NONCLUSTERED INDEX idx_Tours_Name ON Tours(Name);
CREATE NONCLUSTERED INDEX idx_TourCategories_Name ON TourCategories(Name);

GO

-- ========================================
-- ВСТАВКА ТЕСТОВИХ ДАНИХ
-- ========================================

-- Countries
INSERT INTO Countries (Name, Code, Description) VALUES
(N'Україна', 'UKR', N'Незалежна держава в Європі'),
(N'Францовія', 'FRA', N'Європейська країна'),
(N'Греція', 'GRC', N'Середземноморська країна'),
(N'Таїланд', 'THA', N'Південно-східна Азія'),
(N'Японія', 'JPN', N'Східна Азія');

-- Regions
INSERT INTO Regions (CountryId, Name, Description) VALUES
(1, N'Київ', N'Столиця'),
(1, N'Львів', N'Західний регіон'),
(2, N'Іль-де-Франс', N'Регіон Парижа'),
(3, N'Аттика', N'Регіон Афін'),
(4, N'Бангкок', N'Столична область');

-- Cities
INSERT INTO Cities (RegionId, Name, Latitude, Longitude) VALUES
(1, N'Київ', 50.4501, 30.5234),
(2, N'Львів', 49.8397, 24.0297),
(3, N'Париж', 48.8566, 2.3522),
(4, N'Афіни', 37.9838, 23.7275),
(5, N'Бангкок', 13.7563, 100.5018);

-- TourCategories
INSERT INTO TourCategories (Name, Description) VALUES
(N'Пригоди', N'Екстремальні та активні тури'),
(N'Культурне', N'Історичні та культурні місця'),
(N'Пляжний', N'Відпочинок на пляжах'),
(N'Природа', N'Екотуризм та природа'),
(N'Гастрономія', N'Кулінарні тури');

-- Users
INSERT INTO Users (Username, Email, PasswordHash, FirstName, LastName, PhoneNumber, UserRole) VALUES
(N'admin1', N'admin@tourism.com', N'hash123', N'Адмін', N'Системи', N'+380123456789', 'Admin'),
(N'guide_ivan', N'ivan@guides.com', N'hash456', N'Іван', N'Петренко', N'+380987654321', 'Guide'),
(N'guide_maria', N'maria@guides.com', N'hash789', N'Марія', N'Сідоренко', N'+380666666666', 'Guide'),
(N'tourist_alex', N'alex@tourist.com', N'hashABC', N'Олександр', N'Коваленко', N'+380555555555', 'Tourist'),
(N'tourist_anna', N'anna@tourist.com', N'hashDEF', N'Анна', N'Василенко', N'+380777777777', 'Tourist'),
(N'tourist_john', N'john@tourist.com', N'hashGHI', N'John', N'Doe', N'+14155552671', 'Tourist');

-- Tours
INSERT INTO Tours (DestinationCityId, Name, Description, DurationDays, MaxParticipants, Price, Difficulty) VALUES
(1, N'Київська архітектура', N'Експресний тур по історичним пам''ятникам Києва', 2, 20, 500.00, 'Easy'),
(2, N'Львівський мистецький тур', N'Відкриття мистецького спадку Львова', 3, 15, 800.00, 'Medium'),
(3, N'Париж - місто кохання', N'Класичний тур по Парижу з Ейфелевою вежею', 4, 25, 1500.00, 'Easy'),
(4, N'Грецька архітектура', N'Давня Греція та Акрополь', 5, 20, 2000.00, 'Medium'),
(5, N'Таїландський джунглі', N'Екзотичний тур по природі Таїланду', 6, 15, 1200.00, 'Hard');

-- TourSchedules
INSERT INTO TourSchedules (TourId, StartDate, EndDate, AvailableSpots, Status) VALUES
(1, '2024-12-01', '2024-12-02', 20, 'Open'),
(2, '2024-12-10', '2024-12-12', 15, 'Open'),
(3, '2024-12-20', '2024-12-23', 25, 'Open'),
(4, '2025-01-05', '2025-01-09', 20, 'Open'),
(5, '2025-01-15', '2025-01-20', 14, 'Open');

-- Guides
INSERT INTO Guides (UserId, Specialization, Experience, Languages, AverageRating) VALUES
(2, N'Історія', 5, N'Українська, Російська, Англійська', 4.8),
(3, N'Мистецтво', 7, N'Українська, Англійська, Французька', 4.9);

-- GuideAssignments
INSERT INTO GuideAssignments (ScheduleId, GuideId) VALUES
(1, 1),
(2, 2),
(3, 1),
(4, 2),
(5, 1);

-- TouristProfiles
INSERT INTO TouristProfiles (UserId, Nationality, PassportNumber, DateOfBirth, PreferredLanguage) VALUES
(4, N'Українець', N'AA123456', '1990-05-15', 'uk'),
(5, N'Українець', N'AA654321', '1995-08-20', 'uk'),
(6, N'American', N'US123456', '1988-03-10', 'en');

-- PaymentMethods
INSERT INTO PaymentMethods (Name, Description) VALUES
(N'Кредитна карта', N'Visa, Mastercard'),
(N'PayPal', N'Електронний гаманець'),
(N'Банківський переказ', N'Переказ між рахунками'),
(N'Готівка', N'Оплата готівкою на місці');

-- Bookings
INSERT INTO Bookings (ScheduleId, TouristId, NumberOfPeople, TotalPrice, Status) VALUES
(1, 1, 2, 1000.00, 'Confirmed'),
(2, 2, 1, 800.00, 'Confirmed'),
(3, 3, 4, 6000.00, 'Pending'),
(4, 1, 2, 4000.00, 'Confirmed'),
(5, 2, 3, 3600.00, 'Pending');

-- Payments
INSERT INTO Payments (BookingId, PaymentMethodId, Amount, Status) VALUES
(1, 1, 1000.00, 'Completed'),
(2, 2, 800.00, 'Completed'),
(3, 1, 6000.00, 'Pending'),
(4, 1, 4000.00, 'Completed'),
(5, 3, 3600.00, 'Pending');

-- Reviews
INSERT INTO Reviews (TourId, TouristId, Rating, Title, Comment) VALUES
(1, 1, 5, N'Чудовий тур!', N'Іван був вправним та дружелюбним гідом. Дуже задоволений!'),
(2, 2, 4, N'Гарна подорож', N'Цікава інформація про мистецтво. Жалко, що було трохи поспішно.'),
(3, 3, 5, N'Неймовірна Франція', N'Все було ідеально організовано. Рекомендую!'),
(1, 2, 4, N'Хорошо', N'Загалом мені сподобалося, проте було б краще з більшим часом.');

-- TourCategoryMaps
INSERT INTO TourCategoryMaps (TourId, CategoryId) VALUES
(1, 2), -- Київськиий -> Культурне
(2, 2), -- Львів -> Культурне
(3, 2), -- Париж -> Культурне
(4, 2), -- Греція -> Культурне
(5, 4), -- Таїланд -> Природа
(1, 4), -- Київ -> Природа також
(5, 1); -- Таїланд -> Пригоди також

GO

PRINT N'✅ База даних створена успішно з 16 таблицями та індексами!';

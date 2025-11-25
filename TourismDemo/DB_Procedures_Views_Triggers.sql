-- ========================================
-- STORED PROCEDURES, VIEWS, FUNCTIONS, TRIGGERS
-- Мінімум 10 об'єктів для роботи з сутностями
-- ========================================

USE TourismDb;
GO

-- ========================================
-- ОЧИСТКА (видалення старих об'єктів)
-- ========================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Users_Audit')
    DROP TRIGGER trg_Users_Audit;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Bookings_Audit')
    DROP TRIGGER trg_Bookings_Audit;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'trg_Reviews_UpdateModified')
    DROP TRIGGER trg_Reviews_UpdateModified;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CreateBooking')
    DROP PROCEDURE sp_CreateBooking;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DeleteBooking')
    DROP PROCEDURE sp_DeleteBooking;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GetUserBookings')
    DROP PROCEDURE sp_GetUserBookings;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_CreateReview')
    DROP PROCEDURE sp_CreateReview;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_ConfirmPayment')
    DROP PROCEDURE sp_ConfirmPayment;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_GetAverageRating')
    DROP FUNCTION fn_GetAverageRating;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_GetBookingCount')
    DROP FUNCTION fn_GetBookingCount;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_UserBookingDetails')
    DROP VIEW vw_UserBookingDetails;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_ActiveGuides')
    DROP VIEW vw_ActiveGuides;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_PopularTours')
    DROP VIEW vw_PopularTours;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_AllActiveTours')
    DROP VIEW vw_AllActiveTours;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'V' AND name = 'vw_ConfirmedBookings')
    DROP VIEW vw_ConfirmedBookings;

GO

-- ========================================
-- STORED PROCEDURES (5 шт)
-- ========================================

-- 1. sp_CreateBooking - Видалене оновлення підтримки OUTPUT параметра
CREATE PROCEDURE sp_CreateBooking
    @TourId INT,
    @TouristId INT,
    @TravelDate DATE,
    @NumberOfPeople INT = 1,
    @CreatedBy NVARCHAR(100) = 'Web'
AS
BEGIN
    BEGIN TRY
        -- Отримати розклад для туру з найближчою датою
        DECLARE @ScheduleId INT = (
            SELECT TOP 1 ScheduleId
            FROM TourSchedules
            WHERE TourId = @TourId 
                AND StartDate >= @TravelDate
                AND Status = 'Open'
                AND AvailableSpots >= @NumberOfPeople
            ORDER BY StartDate
        );

        IF @ScheduleId IS NULL
        BEGIN
            RAISERROR('Розклад неактивний, не знайдений або немає вільних місць.', 16, 1);
        END

        IF NOT EXISTS (SELECT 1 FROM TouristProfiles WHERE TouristId = @TouristId AND IsDeleted = 0)
        BEGIN
            RAISERROR('Профіль туриста не знайдений.', 16, 1);
        END

        -- Отримати ціну туру
        DECLARE @TourPrice DECIMAL(10, 2) = (SELECT Price FROM Tours WHERE TourId = @TourId);
        DECLARE @TotalPrice DECIMAL(10, 2) = @TourPrice * @NumberOfPeople;

        INSERT INTO Bookings (ScheduleId, TouristId, NumberOfPeople, TotalPrice, Status, CreatedBy)
        VALUES (@ScheduleId, @TouristId, @NumberOfPeople, @TotalPrice, 'Pending', @CreatedBy);

        -- Повернути ID новоствореного бронювання
        SELECT SCOPE_IDENTITY() AS BookingId;

        UPDATE TourSchedules
        SET AvailableSpots = AvailableSpots - @NumberOfPeople
        WHERE ScheduleId = @ScheduleId;
    END TRY
    BEGIN CATCH
        RAISERROR('Помилка при створенні бронювання.', 16, 1);
    END CATCH
END;
GO

-- 2. sp_DeleteBooking - м'яко видалити бронювання
CREATE PROCEDURE sp_DeleteBooking
    @BookingId INT,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingId = @BookingId AND IsDeleted = 0)
        BEGIN
            RAISERROR('Бронювання не знайдено.', 16, 1);
        END

        UPDATE Bookings
        SET IsDeleted = 1,
            ModifiedDate = GETDATE(),
            ModifiedBy = @ModifiedBy
        WHERE BookingId = @BookingId;

        PRINT N'✅ Бронювання видалено (Soft Delete).';
    END TRY
    BEGIN CATCH
        RAISERROR('Помилка при видаленні бронювання.', 16, 1);
    END CATCH
END;
GO

-- 3. sp_GetUserBookings - отримати бронювання користувача
CREATE PROCEDURE sp_GetUserBookings
    @TouristId INT
AS
BEGIN
    SELECT 
        b.BookingId,
        b.BookingDate,
        t.Name AS TourName,
        c.Name AS DestinationCity,
        ts.StartDate,
        ts.EndDate,
        b.NumberOfPeople,
        b.TotalPrice,
        b.Status
    FROM Bookings b
    INNER JOIN TourSchedules ts ON b.ScheduleId = ts.ScheduleId
    INNER JOIN Tours t ON ts.TourId = t.TourId
    INNER JOIN Cities c ON t.DestinationCityId = c.CityId
    WHERE b.TouristId = @TouristId AND b.IsDeleted = 0
    ORDER BY b.BookingDate DESC;
END;
GO

-- 4. sp_CreateReview - створити відгук
CREATE PROCEDURE sp_CreateReview
    @TourId INT,
    @TouristId INT,
    @Rating INT,
    @Title NVARCHAR(200),
    @Comment NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        IF @Rating < 1 OR @Rating > 5
        BEGIN
            RAISERROR('Рейтинг повинен бути від 1 до 5.', 16, 1);
        END

        INSERT INTO Reviews (TourId, TouristId, Rating, Title, Comment)
        VALUES (@TourId, @TouristId, @Rating, @Title, @Comment);

        PRINT N'✅ Відгук успішно створено.';
    END TRY
    BEGIN CATCH
        RAISERROR('Помилка при створенні відгуку.', 16, 1);
    END CATCH
END;
GO

-- 5. sp_ConfirmPayment - підтвердити платіж
CREATE PROCEDURE sp_ConfirmPayment
    @PaymentId INT,
    @TransactionId NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        UPDATE Payments
        SET Status = 'Completed',
            TransactionId = @TransactionId
        WHERE PaymentId = @PaymentId;

        DECLARE @BookingId INT = (SELECT BookingId FROM Payments WHERE PaymentId = @PaymentId);

        UPDATE Bookings
        SET Status = 'Confirmed'
        WHERE BookingId = @BookingId;

        PRINT N'✅ Платіж підтверджено.';
    END TRY
    BEGIN CATCH
        RAISERROR('Помилка при підтвердженні платежу.', 16, 1);
    END CATCH
END;
GO

-- ========================================
-- USER-DEFINED FUNCTIONS (2 шт)
-- ========================================

-- 1. fn_GetAverageRating - отримати середній рейтинг туру
CREATE FUNCTION fn_GetAverageRating (@TourId INT)
RETURNS DECIMAL(3, 1)
AS
BEGIN
    DECLARE @AverageRating DECIMAL(3, 1);
    
    SELECT @AverageRating = AVG(CAST(Rating AS DECIMAL(3, 1)))
    FROM Reviews
    WHERE TourId = @TourId AND IsDeleted = 0;

    RETURN ISNULL(@AverageRating, 0);
END;
GO

-- 2. fn_GetBookingCount - отримати кількість бронювань за період
CREATE FUNCTION fn_GetBookingCount (@StartDate DATE, @EndDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @BookingCount INT;
    
    SELECT @BookingCount = COUNT(*)
    FROM Bookings
    WHERE CAST(BookingDate AS DATE) BETWEEN @StartDate AND @EndDate
    AND IsDeleted = 0;

    RETURN ISNULL(@BookingCount, 0);
END;
GO

-- ========================================
-- VIEWS (3 шт)
-- ========================================

-- 1. vw_UserBookingDetails - деталі бронювань користувачів
CREATE VIEW vw_UserBookingDetails
AS
SELECT 
    u.Username,
    u.Email,
    b.BookingId,
    b.BookingDate,
    t.Name AS TourName,
    c.Name AS DestinationCity,
    ts.StartDate,
    ts.EndDate,
    b.NumberOfPeople,
    b.TotalPrice,
    b.Status,
    dbo.fn_GetAverageRating(t.TourId) AS TourRating
FROM Users u
INNER JOIN TouristProfiles tp ON u.UserId = tp.UserId
INNER JOIN Bookings b ON tp.TouristId = b.TouristId
INNER JOIN TourSchedules ts ON b.ScheduleId = ts.ScheduleId
INNER JOIN Tours t ON ts.TourId = t.TourId
INNER JOIN Cities c ON t.DestinationCityId = c.CityId
WHERE b.IsDeleted = 0 AND u.IsDeleted = 0;
GO

-- 2. vw_ActiveGuides - активні гіди з інформацією
CREATE VIEW vw_ActiveGuides
AS
SELECT 
    g.GuideId,
    u.Username,
    u.FirstName,
    u.LastName,
    u.PhoneNumber,
    u.Email,
    g.Specialization,
    g.Experience,
    g.Languages,
    g.AverageRating,
    COUNT(DISTINCT ga.ScheduleId) AS TotalAssignments
FROM Guides g
INNER JOIN Users u ON g.UserId = u.UserId
LEFT JOIN GuideAssignments ga ON g.GuideId = ga.GuideId
WHERE g.IsActive = 1 AND g.IsDeleted = 0 AND u.IsActive = 1
GROUP BY g.GuideId, u.Username, u.FirstName, u.LastName, u.PhoneNumber, u.Email,
         g.Specialization, g.Experience, g.Languages, g.AverageRating;
GO

-- 3. vw_PopularTours - популярні тури за кількістю бронювань
CREATE VIEW vw_PopularTours
AS
SELECT TOP 50
    t.TourId,
    t.Name,
    c.Name AS DestinationCity,
    t.DurationDays,
    t.Price,
    COUNT(b.BookingId) AS TotalBookings,
    SUM(b.NumberOfPeople) AS TotalParticipants,
    dbo.fn_GetAverageRating(t.TourId) AS AverageRating,
    t.IsActive
FROM Tours t
LEFT JOIN TourSchedules ts ON t.TourId = ts.TourId
LEFT JOIN Bookings b ON ts.ScheduleId = b.ScheduleId
INNER JOIN Cities c ON t.DestinationCityId = c.CityId
WHERE t.IsActive = 1 AND t.IsDeleted = 0 AND (b.IsDeleted = 0 OR b.BookingId IS NULL)
GROUP BY t.TourId, t.Name, c.Name, t.DurationDays, t.Price, t.IsActive
ORDER BY TotalBookings DESC;
GO

-- ========================================
-- TRIGGERS (3 шт)
-- ========================================

-- 1. trg_Users_Audit - аудит змін користувачів
CREATE TRIGGER trg_Users_Audit
ON Users
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditLog (TableName, RecordId, Action, OldValue, NewValue, ModifiedBy)
    SELECT 
        'Users',
        INSERTED.UserId,
        'UPDATE',
        CONCAT('Email: ', DELETED.Email, ', IsActive: ', DELETED.IsActive),
        CONCAT('Email: ', INSERTED.Email, ', IsActive: ', INSERTED.IsActive),
        INSERTED.ModifiedBy
    FROM INSERTED
    INNER JOIN DELETED ON INSERTED.UserId = DELETED.UserId;
END;
GO

-- 2. trg_Bookings_Audit - аудит змін бронювань
CREATE TRIGGER trg_Bookings_Audit
ON Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INSERTED)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValue, NewValue, ModifiedBy)
        SELECT 
            'Bookings',
            INSERTED.BookingId,
            CASE WHEN DELETED.BookingId IS NULL THEN 'INSERT' ELSE 'UPDATE' END,
            CASE WHEN DELETED.BookingId IS NULL THEN NULL 
                 ELSE CONCAT('Status: ', DELETED.Status, ', Price: ', DELETED.TotalPrice) END,
            CONCAT('Status: ', INSERTED.Status, ', Price: ', INSERTED.TotalPrice),
            INSERTED.ModifiedBy
        FROM INSERTED
        LEFT JOIN DELETED ON INSERTED.BookingId = DELETED.BookingId;
    END
    ELSE IF EXISTS (SELECT 1 FROM DELETED)
    BEGIN
        INSERT INTO AuditLog (TableName, RecordId, Action, OldValue, NewValue, ModifiedBy)
        SELECT 
            'Bookings',
            DELETED.BookingId,
            'DELETE',
            CONCAT('Status: ', DELETED.Status, ', Price: ', DELETED.TotalPrice),
            NULL,
            DELETED.ModifiedBy
        FROM DELETED;
    END
END;
GO

-- 3. trg_Reviews_UpdateModified - оновити ModifiedDate при редагуванні відгуку
CREATE TRIGGER trg_Reviews_UpdateModified
ON Reviews
AFTER UPDATE
AS
BEGIN
    UPDATE Reviews
    SET ModifiedDate = GETDATE()
    WHERE ReviewId IN (SELECT ReviewId FROM INSERTED);
END;
GO

-- ========================================
-- VIEWS для SOFT DELETE (2 додаткові)
-- ========================================

-- 4. vw_AllActiveTours - всі активні тури
CREATE VIEW vw_AllActiveTours
AS
SELECT 
    t.TourId,
    t.Name,
    c.Name AS DestinationCity,
    r.Name AS Region,
    co.Name AS Country,
    t.DurationDays,
    t.MaxParticipants,
    t.Price,
    t.Difficulty,
    dbo.fn_GetAverageRating(t.TourId) AS AverageRating,
    COUNT(DISTINCT ts.ScheduleId) AS UpcomingSchedules
FROM Tours t
INNER JOIN Cities c ON t.DestinationCityId = c.CityId
INNER JOIN Regions r ON c.RegionId = r.RegionId
INNER JOIN Countries co ON r.CountryId = co.CountryId
LEFT JOIN TourSchedules ts ON t.TourId = ts.TourId AND ts.Status = 'Open'
WHERE t.IsActive = 1 AND t.IsDeleted = 0
GROUP BY t.TourId, t.Name, c.Name, r.Name, co.Name, t.DurationDays, 
         t.MaxParticipants, t.Price, t.Difficulty;
GO

-- 5. vw_ConfirmedBookings - підтверджені бронювання
CREATE VIEW vw_ConfirmedBookings
AS
SELECT 
    b.BookingId,
    u.FirstName,
    u.LastName,
    u.Email,
    t.Name AS TourName,
    ts.StartDate,
    ts.EndDate,
    b.NumberOfPeople,
    b.TotalPrice,
    p.Amount AS PaidAmount,
    p.Status AS PaymentStatus,
    b.BookingDate
FROM Bookings b
INNER JOIN TouristProfiles tp ON b.TouristId = tp.TouristId
INNER JOIN Users u ON tp.UserId = u.UserId
INNER JOIN TourSchedules ts ON b.ScheduleId = ts.ScheduleId
INNER JOIN Tours t ON ts.TourId = t.TourId
LEFT JOIN Payments p ON b.BookingId = p.BookingId
WHERE b.Status = 'Confirmed' AND b.IsDeleted = 0;
GO

GO

PRINT N'✅ Створено 5 SP, 2 Functions, 5 Views та 3 Triggers!';

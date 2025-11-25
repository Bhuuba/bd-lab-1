using System.Data.SqlClient;
using TourismDemo.Data.Repositories.Interfaces;
using TourismDemo.Data.UnitOfWork;
using TourismDemo.Data.UnitOfWork.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Register SqlConnection with DI
builder.Services.AddScoped<SqlConnection>(_ =>
{
    var connectionString = builder.Configuration.GetConnectionString("TourismDb");
    return new SqlConnection(connectionString);
});

// Register UnitOfWork
builder.Services.AddScoped<IUnitOfWork, SqlUnitOfWork>();

var app = builder.Build();

// Enable static files middleware
app.UseDefaultFiles();
app.UseStaticFiles();

// Enable Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// GET /api/tours - Get all active tours
app.MapGet("/api/tours", async (IUnitOfWork unitOfWork) =>
{
    var tours = await unitOfWork.Tours.GetActiveToursAsync();
    return Results.Ok(tours);
})
.Produces(200)
.WithName("GetActiveTours");

// POST /api/tours - Create a new tour
app.MapPost("/api/tours", async (CreateTourRequest request, IConfiguration config) =>
{
    try
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Results.BadRequest(new { error = "Назва туру обов'язкова" });
        
        if (request.DestinationCityId <= 0)
            return Results.BadRequest(new { error = "Дійсний ID міста обов'язковий" });
        
        if (request.Price <= 0)
            return Results.BadRequest(new { error = "Ціна повинна бути більше 0" });

        // Вставити напряму у базу данних через SQL
        using (var connection = new System.Data.SqlClient.SqlConnection(
            config.GetConnectionString("TourismDb")))
        {
            await connection.OpenAsync();
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"
                    INSERT INTO Tours (Name, Description, DestinationCityId, DurationDays, MaxParticipants, Price, Difficulty, IsActive, CreatedBy)
                    VALUES (@Name, @Description, @DestinationCityId, @DurationDays, @MaxParticipants, @Price, @Difficulty, 1, 'WebAPI');
                    SELECT CAST(SCOPE_IDENTITY() as int);";
                
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", request.Description ?? "");
                command.Parameters.AddWithValue("@DestinationCityId", request.DestinationCityId);
                command.Parameters.AddWithValue("@DurationDays", request.DurationDays);
                command.Parameters.AddWithValue("@MaxParticipants", request.MaxParticipants);
                command.Parameters.AddWithValue("@Price", request.Price);
                command.Parameters.AddWithValue("@Difficulty", request.Difficulty);

                var tourId = (int)await command.ExecuteScalarAsync();
                return Results.Ok(new { tourId, message = "Тур успішно створено" });
            }
        }
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("CreateTour");

// GET /api/tours/popular - Get popular tours
app.MapGet("/api/tours/popular", async (IUnitOfWork unitOfWork) =>
{
    var tours = await unitOfWork.Tours.GetPopularToursAsync();
    return Results.Ok(tours);
})
.Produces(200)
.WithName("GetPopularTours");

// POST /api/bookings - Create a new booking
app.MapPost("/api/bookings", async (BookingRequest request, IConfiguration config) =>
{
    try
    {
        if (request.TourId <= 0)
            return Results.BadRequest(new { error = "Дійсний ID туру обов'язковий" });
        
        if (request.TouristId <= 0)
            return Results.BadRequest(new { error = "Дійсний ID туриста обов'язковий" });

        // Вставити напряму у базу данних через SQL
        using (var connection = new System.Data.SqlClient.SqlConnection(
            config.GetConnectionString("TourismDb")))
        {
            await connection.OpenAsync();
            
            // Спочатку перевіримо наявність туру і користувача
            using (var checkCommand = connection.CreateCommand())
            {
                checkCommand.CommandText = @"
                    SELECT COUNT(*) FROM Tours WHERE TourId = @TourId AND IsDeleted = 0;
                    SELECT COUNT(*) FROM TouristProfiles WHERE TouristId = @TouristId AND IsDeleted = 0 AND IsActive = 1;";
                
                checkCommand.Parameters.AddWithValue("@TourId", request.TourId);
                checkCommand.Parameters.AddWithValue("@TouristId", request.TouristId);
                
                // Перевіримо дані
                var tourExists = false;
                var touristExists = false;
                
                using (var reader = await checkCommand.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                        tourExists = reader.GetInt32(0) > 0;
                    
                    if (await reader.NextResultAsync() && await reader.ReadAsync())
                        touristExists = reader.GetInt32(0) > 0;
                }
                
                if (!tourExists)
                    return Results.BadRequest(new { error = "Тур не знайдений" });
                
                  if (!touristExists)
                    return Results.BadRequest(new { error = "Користувач не знайдений" });
            }

            // Тепер запустимо процедуру бронювання
            using (var command = connection.CreateCommand())
            {
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.CommandText = "sp_CreateBooking";
                
                command.Parameters.AddWithValue("@TourId", request.TourId);
                command.Parameters.AddWithValue("@TouristId", request.TouristId);
                command.Parameters.AddWithValue("@TravelDate", request.TravelDate.Date);
                command.Parameters.AddWithValue("@NumberOfPeople", request.NumberOfPeople);
                command.Parameters.AddWithValue("@CreatedBy", "WebAPI");

                try
                {
                    var result = await command.ExecuteScalarAsync();
                    if (result != null && int.TryParse(result.ToString(), out var bookingId))
                    {
                        return Results.Ok(new { bookingId, message = "Бронювання успішне" });
                    }
                    else
                    {
                        return Results.BadRequest(new { error = "Помилка при створенні бронювання - розклад не знайдений або немає вільних місць" });
                    }
                }
                catch (Exception procEx)
                {
                    return Results.BadRequest(new { error = procEx.Message });
                }
            }
        }
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("CreateBooking");

// GET /api/tours/{tourId}/schedules - Get tour schedules
app.MapGet("/api/tours/{tourId}/schedules", async (int tourId, IConfiguration config) =>
{
    try
    {
        using (var connection = new System.Data.SqlClient.SqlConnection(
            config.GetConnectionString("TourismDb")))
        {
            await connection.OpenAsync();
            var schedules = new List<object>();
            
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"
                    SELECT ScheduleId, TourId, StartDate, EndDate, AvailableSpots, Status
                    FROM TourSchedules
                    WHERE TourId = @TourId
                    ORDER BY StartDate";
                
                command.Parameters.AddWithValue("@TourId", tourId);
                
                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        schedules.Add(new
                        {
                            scheduleId = reader.GetInt32(0),
                            tourId = reader.GetInt32(1),
                            startDate = reader.GetDateTime(2),
                            endDate = reader.GetDateTime(3),
                            availableSpots = reader.GetInt32(4),
                            status = reader.GetString(5)
                        });
                    }
                }
            }
            
            return Results.Ok(schedules);
        }
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("GetTourSchedules");

// GET /api/tourists - Get all available tourists
app.MapGet("/api/tourists", async (IConfiguration config) =>
{
    try
    {
        using (var connection = new System.Data.SqlClient.SqlConnection(
            config.GetConnectionString("TourismDb")))
        {
            await connection.OpenAsync();
            var tourists = new List<object>();
            
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"
                    SELECT TOP 100 
                        tp.TouristId,
                        u.FirstName,
                        u.LastName,
                        u.Email
                    FROM TouristProfiles tp
                    INNER JOIN Users u ON tp.UserId = u.UserId
                    WHERE tp.IsDeleted = 0 
                        AND tp.IsActive = 1
                        AND u.IsDeleted = 0
                        AND u.IsActive = 1
                    ORDER BY u.FirstName";
                
                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        tourists.Add(new
                        {
                            touristId = reader.GetInt32(0),
                            firstName = reader.IsDBNull(1) ? "N/A" : reader.GetString(1),
                            lastName = reader.IsDBNull(2) ? "N/A" : reader.GetString(2),
                            email = reader.IsDBNull(3) ? "" : reader.GetString(3)
                        });
                    }
                }
            }
            
            return Results.Ok(tourists);
        }
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = $"Error: {ex.Message}" });
    }
})
.Produces(200)
.Produces(400)
.WithName("GetTourists");

// GET /api/bookings - Get all bookings
app.MapGet("/api/bookings", async (IUnitOfWork unitOfWork) =>
{
    var bookings = await unitOfWork.Bookings.GetAllBookingsAsync();
    return Results.Ok(bookings);
})
.Produces(200)
.WithName("GetAllBookings");

// DELETE /api/bookings/{id} - Delete booking
app.MapDelete("/api/bookings/{id}", async (int id, IUnitOfWork unitOfWork) =>
{
    try
    {
        var deleted = await unitOfWork.Bookings.DeleteBookingAsync(id);
        if (!deleted)
            return Results.NotFound(new { error = "Бронювання не знайдено" });

        await unitOfWork.CommitAsync();
        return Results.Ok(new { message = "Бронювання видалено" });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(404)
.Produces(400)
.WithName("DeleteBooking");

// ======== REVIEWS ENDPOINTS ========

// GET /api/tours/{tourId}/reviews - Get reviews for a tour
app.MapGet("/api/tours/{tourId}/reviews", async (int tourId, IUnitOfWork unitOfWork) =>
{
    var reviews = await unitOfWork.Reviews.GetTourReviewsAsync(tourId);
    return Results.Ok(reviews);
})
.Produces(200)
.WithName("GetTourReviews");

// POST /api/reviews - Create review
app.MapPost("/api/reviews", async (CreateReviewRequest request, IUnitOfWork unitOfWork) =>
{
    try
    {
        await unitOfWork.Reviews.CreateReviewAsync(
            request.TourId,
            request.TouristId,
            request.Rating,
            request.Title,
            request.Comment);

        await unitOfWork.CommitAsync();

        return Results.Ok(new { message = "Відгук створено успішно" });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("CreateReview");

// GET /api/tours/{tourId}/average-rating - Get average rating for tour
app.MapGet("/api/tours/{tourId}/average-rating", async (int tourId, IUnitOfWork unitOfWork) =>
{
    var avgRating = await unitOfWork.Reviews.GetAverageRatingAsync(tourId);
    return Results.Ok(new { tourId, averageRating = avgRating });
})
.Produces(200)
.WithName("GetAverageRating");

// ======== PAYMENTS ENDPOINTS ========

// GET /api/bookings/{bookingId}/payments - Get payments for booking
app.MapGet("/api/bookings/{bookingId}/payments", async (int bookingId, IUnitOfWork unitOfWork) =>
{
    var payments = await unitOfWork.Payments.GetBookingPaymentsAsync(bookingId);
    return Results.Ok(payments);
})
.Produces(200)
.WithName("GetBookingPayments");

// POST /api/payments - Create payment
app.MapPost("/api/payments", async (CreatePaymentRequest request, IUnitOfWork unitOfWork) =>
{
    try
    {
        var paymentId = await unitOfWork.Payments.CreatePaymentAsync(
            request.BookingId,
            request.PaymentMethodId,
            request.Amount);

        await unitOfWork.CommitAsync();

        return Results.Ok(new { paymentId, message = "Платіж створено" });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("CreatePayment");

// POST /api/payments/{paymentId}/confirm - Confirm payment
app.MapPost("/api/payments/{paymentId}/confirm", async (int paymentId, ConfirmPaymentRequest request, IUnitOfWork unitOfWork) =>
{
    try
    {
        await unitOfWork.Payments.ConfirmPaymentAsync(paymentId, request.TransactionId);
        await unitOfWork.CommitAsync();

        return Results.Ok(new { message = "Платіж підтверджено" });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("ConfirmPayment");

// ======== AUDIT LOG ENDPOINTS ========

// GET /api/audit-logs/table/{tableName}/record/{recordId} - Get audit log for specific record
app.MapGet("/api/audit-logs/table/{tableName}/record/{recordId}", async (string tableName, int recordId, IUnitOfWork unitOfWork) =>
{
    var auditLogs = await unitOfWork.AuditLogs.GetAuditLogsAsync(tableName, recordId);
    return Results.Ok(auditLogs);
})
.Produces(200)
.WithName("GetAuditLogs");

// GET /api/audit-logs/user/{userId} - Get audit logs for specific user
app.MapGet("/api/audit-logs/user/{userId}", async (string userId, IUnitOfWork unitOfWork) =>
{
    var auditLogs = await unitOfWork.AuditLogs.GetUserAuditLogsAsync(userId);
    return Results.Ok(auditLogs);
})
.Produces(200)
.WithName("GetUserAuditLogs");

app.Run();

// Request DTOs
public class BookingRequest
{
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public DateTime TravelDate { get; set; }
    public int NumberOfPeople { get; set; } = 1;
}

public class CreateTourRequest
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public int DestinationCityId { get; set; }
    public int DurationDays { get; set; }
    public int MaxParticipants { get; set; }
    public decimal Price { get; set; }
    public string? Difficulty { get; set; }
}

public class CreateReviewRequest
{
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public int Rating { get; set; }
    public string? Title { get; set; }
    public string? Comment { get; set; }
}

public class CreatePaymentRequest
{
    public int BookingId { get; set; }
    public int PaymentMethodId { get; set; }
    public decimal Amount { get; set; }
}

public class ConfirmPaymentRequest
{
    public string? TransactionId { get; set; }
}

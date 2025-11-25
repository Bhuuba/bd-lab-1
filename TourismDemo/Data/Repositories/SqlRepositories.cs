namespace TourismDemo.Data.Repositories;

using System.Data;
using System.Data.SqlClient;
using TourismDemo.Data.DTOs;
using TourismDemo.Data.Repositories.Interfaces;

// ========================================
// 1. SQL TOUR REPOSITORY - Розширений
// ========================================

public class SqlTourRepository : ITourRepository
{
    private readonly SqlConnection _connection;

    public SqlTourRepository(SqlConnection connection) => _connection = connection;

    public async Task<IEnumerable<TourDto>> GetActiveToursAsync()
    {
        var tours = new List<TourDto>();
        
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("SELECT TourId, Name, Country, City, Price, Rating FROM vw_ActiveTours", _connection))
        {
            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    tours.Add(new TourDto
                    {
                        TourId = reader.GetInt32(0),
                        Name = reader.GetString(1),
                        Country = reader.GetString(2),
                        City = reader.GetString(3),
                        Price = reader.GetDecimal(4),
                        Rating = reader.GetDecimal(5)
                    });
                }
            }
        }
        return tours;
    }

    public async Task<IEnumerable<PopularTourDto>> GetPopularToursAsync()
    {
        var tours = new List<PopularTourDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("SELECT * FROM vw_PopularTours", _connection))
        {
            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    tours.Add(new PopularTourDto
                    {
                        TourId = reader.IsDBNull(0) ? 0 : reader.GetInt32(0),
                        Name = reader.IsDBNull(1) ? "" : reader.GetString(1),
                        DestinationCity = reader.IsDBNull(2) ? "" : reader.GetString(2),
                        DurationDays = reader.IsDBNull(3) ? 0 : reader.GetInt32(3),
                        Price = reader.IsDBNull(4) ? 0 : reader.GetDecimal(4),
                        TotalBookings = reader.IsDBNull(5) ? 0 : reader.GetInt32(5),
                        TotalParticipants = reader.IsDBNull(6) ? 0 : reader.GetInt32(6),
                        AverageRating = reader.IsDBNull(7) ? 0 : reader.GetDecimal(7)
                    });
                }
            }
        }
        return tours;
    }

    public async Task<TourDto> GetTourByIdAsync(int tourId)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT TourId, Name, Country, City, Price, Rating FROM vw_ActiveTours WHERE TourId = @TourId",
            _connection))
        {
            command.Parameters.AddWithValue("@TourId", tourId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    return new TourDto
                    {
                        TourId = reader.GetInt32(0),
                        Name = reader.GetString(1),
                        Country = reader.GetString(2),
                        City = reader.GetString(3),
                        Price = reader.GetDecimal(4),
                        Rating = reader.GetDecimal(5)
                    };
                }
            }
        }
        return null;
    }
}

// ========================================
// 2. SQL BOOKING REPOSITORY - Розширений
// ========================================

public class SqlBookingRepository : IBookingRepository
{
    private readonly SqlConnection _connection;

    public SqlBookingRepository(SqlConnection connection) => _connection = connection;

    public async Task<int> CreateBookingAsync(int tourId, int touristId, DateTime travelDate, int numberOfPeople = 1)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("sp_CreateBooking", _connection))
        {
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@TourId", tourId);
            command.Parameters.AddWithValue("@TouristId", touristId);
            command.Parameters.AddWithValue("@TravelDate", travelDate);
            command.Parameters.AddWithValue("@NumberOfPeople", numberOfPeople);

            var result = await command.ExecuteScalarAsync();
            return result != null ? Convert.ToInt32(result) : 0;
        }
    }

    public async Task<IEnumerable<BookingDto>> GetAllBookingsAsync()
    {
        var bookings = new List<BookingDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(@"
            SELECT 
                b.BookingId,
                b.BookingDate,
                t.Name AS TourName,
                b.TouristId,
                ts.StartDate
            FROM Bookings b
            INNER JOIN TourSchedules ts ON b.ScheduleId = ts.ScheduleId
            INNER JOIN Tours t ON ts.TourId = t.TourId
            WHERE b.IsDeleted = 0
            ORDER BY b.BookingDate DESC", _connection))
        {
            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    bookings.Add(new BookingDto
                    {
                        BookingId = reader.GetInt32(0),
                        BookingDate = reader.GetDateTime(1),
                        TourName = reader.GetString(2),
                        TouristId = reader.GetInt32(3),
                        TravelDate = reader.GetDateTime(4)
                    });
                }
            }
        }
        return bookings;
    }

    public async Task<bool> DeleteBookingAsync(int bookingId)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("sp_DeleteBooking", _connection))
        {
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@BookingId", bookingId);
            command.Parameters.AddWithValue("@ModifiedBy", "SYSTEM");

            var result = await command.ExecuteNonQueryAsync();
            return result > 0;
        }
    }

    public async Task<IEnumerable<UserBookingDetailDto>> GetUserBookingsAsync(int touristId)
    {
        var bookings = new List<UserBookingDetailDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("sp_GetUserBookings", _connection))
        {
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@TouristId", touristId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    bookings.Add(new UserBookingDetailDto
                    {
                        BookingId = reader.GetInt32(0),
                        BookingDate = reader.GetDateTime(1),
                        TourName = reader.GetString(2),
                        DestinationCity = reader.GetString(3),
                        StartDate = reader.GetDateTime(4),
                        EndDate = reader.GetDateTime(5),
                        NumberOfPeople = reader.GetInt32(6),
                        TotalPrice = reader.GetDecimal(7),
                        Status = reader.GetString(8)
                    });
                }
            }
        }
        return bookings;
    }
}

// ========================================
// 3. SQL REVIEW REPOSITORY
// ========================================

public class SqlReviewRepository : IReviewRepository
{
    private readonly SqlConnection _connection;

    public SqlReviewRepository(SqlConnection connection) => _connection = connection;

    public async Task<IEnumerable<ReviewDto>> GetTourReviewsAsync(int tourId)
    {
        var reviews = new List<ReviewDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT ReviewId, TourId, Rating, Title, Comment, CreatedDate FROM Reviews WHERE TourId = @TourId AND IsDeleted = 0",
            _connection))
        {
            command.Parameters.AddWithValue("@TourId", tourId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    reviews.Add(new ReviewDto
                    {
                        ReviewId = reader.GetInt32(0),
                        TourId = reader.GetInt32(1),
                        Rating = reader.GetInt32(2),
                        Title = reader.IsDBNull(3) ? "" : reader.GetString(3),
                        Comment = reader.IsDBNull(4) ? "" : reader.GetString(4),
                        CreatedDate = reader.GetDateTime(5)
                    });
                }
            }
        }
        return reviews;
    }

    public async Task CreateReviewAsync(int tourId, int touristId, int rating, string title, string comment)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("sp_CreateReview", _connection))
        {
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@TourId", tourId);
            command.Parameters.AddWithValue("@TouristId", touristId);
            command.Parameters.AddWithValue("@Rating", rating);
            command.Parameters.AddWithValue("@Title", title ?? "");
            command.Parameters.AddWithValue("@Comment", comment ?? "");

            await command.ExecuteNonQueryAsync();
        }
    }

    public async Task<decimal> GetAverageRatingAsync(int tourId)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT dbo.fn_GetAverageRating(@TourId)",
            _connection))
        {
            command.Parameters.AddWithValue("@TourId", tourId);
            var result = await command.ExecuteScalarAsync();
            return result == null || result == DBNull.Value ? 0 : (decimal)result;
        }
    }
}

// ========================================
// 4. SQL PAYMENT REPOSITORY
// ========================================

public class SqlPaymentRepository : IPaymentRepository
{
    private readonly SqlConnection _connection;

    public SqlPaymentRepository(SqlConnection connection) => _connection = connection;

    public async Task<IEnumerable<PaymentDto>> GetBookingPaymentsAsync(int bookingId)
    {
        var payments = new List<PaymentDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT PaymentId, BookingId, Amount, PaymentDate, p.Status, pm.Name FROM Payments p INNER JOIN PaymentMethods pm ON p.PaymentMethodId = pm.PaymentMethodId WHERE BookingId = @BookingId",
            _connection))
        {
            command.Parameters.AddWithValue("@BookingId", bookingId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    payments.Add(new PaymentDto
                    {
                        PaymentId = reader.GetInt32(0),
                        BookingId = reader.GetInt32(1),
                        Amount = reader.GetDecimal(2),
                        PaymentDate = reader.GetDateTime(3),
                        Status = reader.GetString(4),
                        PaymentMethod = reader.GetString(5)
                    });
                }
            }
        }
        return payments;
    }

    public async Task<int> CreatePaymentAsync(int bookingId, int paymentMethodId, decimal amount)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "INSERT INTO Payments (BookingId, PaymentMethodId, Amount) VALUES (@BookingId, @PaymentMethodId, @Amount); SELECT SCOPE_IDENTITY();",
            _connection))
        {
            command.Parameters.AddWithValue("@BookingId", bookingId);
            command.Parameters.AddWithValue("@PaymentMethodId", paymentMethodId);
            command.Parameters.AddWithValue("@Amount", amount);

            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }
    }

    public async Task ConfirmPaymentAsync(int paymentId, string transactionId)
    {
        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand("sp_ConfirmPayment", _connection))
        {
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@PaymentId", paymentId);
            command.Parameters.AddWithValue("@TransactionId", transactionId);

            await command.ExecuteNonQueryAsync();
        }
    }
}

// ========================================
// 5. SQL AUDIT LOG REPOSITORY
// ========================================

public class SqlAuditLogRepository : IAuditLogRepository
{
    private readonly SqlConnection _connection;

    public SqlAuditLogRepository(SqlConnection connection) => _connection = connection;

    public async Task<IEnumerable<AuditLogDto>> GetAuditLogsAsync(string tableName, int recordId)
    {
        var logs = new List<AuditLogDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT AuditId, TableName, RecordId, Action, OldValue, NewValue, ModifiedBy, ModifiedDate FROM AuditLog WHERE TableName = @TableName AND RecordId = @RecordId ORDER BY ModifiedDate DESC",
            _connection))
        {
            command.Parameters.AddWithValue("@TableName", tableName);
            command.Parameters.AddWithValue("@RecordId", recordId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    logs.Add(new AuditLogDto
                    {
                        AuditId = reader.GetInt32(0),
                        TableName = reader.GetString(1),
                        RecordId = reader.GetInt32(2),
                        Action = reader.GetString(3),
                        OldValue = reader.IsDBNull(4) ? "" : reader.GetString(4),
                        NewValue = reader.IsDBNull(5) ? "" : reader.GetString(5),
                        ModifiedBy = reader.GetString(6),
                        ModifiedDate = reader.GetDateTime(7)
                    });
                }
            }
        }
        return logs;
    }

    public async Task<IEnumerable<AuditLogDto>> GetUserAuditLogsAsync(string userId)
    {
        var logs = new List<AuditLogDto>();

        if (_connection.State != ConnectionState.Open)
            await _connection.OpenAsync();

        using (var command = new SqlCommand(
            "SELECT AuditId, TableName, RecordId, Action, OldValue, NewValue, ModifiedBy, ModifiedDate FROM AuditLog WHERE ModifiedBy = @ModifiedBy ORDER BY ModifiedDate DESC",
            _connection))
        {
            command.Parameters.AddWithValue("@ModifiedBy", userId);

            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    logs.Add(new AuditLogDto
                    {
                        AuditId = reader.GetInt32(0),
                        TableName = reader.GetString(1),
                        RecordId = reader.GetInt32(2),
                        Action = reader.GetString(3),
                        OldValue = reader.IsDBNull(4) ? "" : reader.GetString(4),
                        NewValue = reader.IsDBNull(5) ? "" : reader.GetString(5),
                        ModifiedBy = reader.GetString(6),
                        ModifiedDate = reader.GetDateTime(7)
                    });
                }
            }
        }
        return logs;
    }
}

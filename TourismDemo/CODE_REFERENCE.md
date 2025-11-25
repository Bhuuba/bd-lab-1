# Повний код основних файлів

## Program.cs

```csharp
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

// POST /api/bookings - Create a new booking
app.MapPost("/api/bookings", async (BookingRequest request, IUnitOfWork unitOfWork) =>
{
    try
    {
        var bookingId = await unitOfWork.Bookings.CreateBookingAsync(
            request.TourId,
            request.TouristId,
            request.TravelDate);

        await unitOfWork.CommitAsync();

        return Results.Ok(new { bookingId });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
})
.Produces(200)
.Produces(400)
.WithName("CreateBooking");

app.Run();

// Request DTOs
public class BookingRequest
{
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public DateTime TravelDate { get; set; }
}
```

## Data/DTOs/TourDto.cs

```csharp
namespace TourismDemo.Data.DTOs;

public class TourDto
{
    public int TourId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal Rating { get; set; }
}
```

## Data/Repositories/Interfaces/ITourRepository.cs

```csharp
namespace TourismDemo.Data.Repositories.Interfaces;

using TourismDemo.Data.DTOs;

public interface ITourRepository
{
    Task<IEnumerable<TourDto>> GetActiveToursAsync();
}
```

## Data/Repositories/Interfaces/IBookingRepository.cs

```csharp
namespace TourismDemo.Data.Repositories.Interfaces;

public interface IBookingRepository
{
    Task<int> CreateBookingAsync(int tourId, int touristId, DateTime travelDate);
}
```

## Data/Repositories/SqlTourRepository.cs

```csharp
namespace TourismDemo.Data.Repositories;

using System.Data;
using System.Data.SqlClient;
using TourismDemo.Data.DTOs;
using TourismDemo.Data.Repositories.Interfaces;

public class SqlTourRepository : ITourRepository
{
    private readonly SqlConnection _connection;

    public SqlTourRepository(SqlConnection connection)
    {
        _connection = connection;
    }

    public async Task<IEnumerable<TourDto>> GetActiveToursAsync()
    {
        var tours = new List<TourDto>();

        try
        {
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
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching active tours: {ex.Message}");
            throw;
        }

        return tours;
    }
}
```

## Data/Repositories/SqlBookingRepository.cs

```csharp
namespace TourismDemo.Data.Repositories;

using System.Data;
using System.Data.SqlClient;
using TourismDemo.Data.Repositories.Interfaces;

public class SqlBookingRepository : IBookingRepository
{
    private readonly SqlConnection _connection;

    public SqlBookingRepository(SqlConnection connection)
    {
        _connection = connection;
    }

    public async Task<int> CreateBookingAsync(int tourId, int touristId, DateTime travelDate)
    {
        try
        {
            if (_connection.State != ConnectionState.Open)
                await _connection.OpenAsync();

            using (var command = new SqlCommand("sp_CreateBooking", _connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@TourId", tourId);
                command.Parameters.AddWithValue("@TouristId", touristId);
                command.Parameters.AddWithValue("@TravelDate", travelDate);

                var bookingIdParam = new SqlParameter("@BookingId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                command.Parameters.Add(bookingIdParam);

                await command.ExecuteNonQueryAsync();

                return (int)bookingIdParam.Value;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating booking: {ex.Message}");
            throw;
        }
    }
}
```

## Data/UnitOfWork/Interfaces/IUnitOfWork.cs

```csharp
namespace TourismDemo.Data.UnitOfWork.Interfaces;

using TourismDemo.Data.Repositories.Interfaces;

public interface IUnitOfWork
{
    ITourRepository Tours { get; }
    IBookingRepository Bookings { get; }
    Task CommitAsync();
}
```

## Data/UnitOfWork/SqlUnitOfWork.cs

```csharp
namespace TourismDemo.Data.UnitOfWork;

using System.Data;
using System.Data.SqlClient;
using TourismDemo.Data.Repositories;
using TourismDemo.Data.Repositories.Interfaces;
using TourismDemo.Data.UnitOfWork.Interfaces;

public class SqlUnitOfWork : IUnitOfWork, IAsyncDisposable
{
    private readonly SqlConnection _connection;
    private ITourRepository? _tourRepository;
    private IBookingRepository? _bookingRepository;

    public SqlUnitOfWork(SqlConnection connection)
    {
        _connection = connection;
    }

    public ITourRepository Tours
    {
        get
        {
            _tourRepository ??= new SqlTourRepository(_connection);
            return _tourRepository;
        }
    }

    public IBookingRepository Bookings
    {
        get
        {
            _bookingRepository ??= new SqlBookingRepository(_connection);
            return _bookingRepository;
        }
    }

    public async Task CommitAsync()
    {
        // Мінімальна реалізація для транзакцій при необхідності
        // Поточно - просто операції комітяться одразу
        await Task.CompletedTask;
    }

    public async ValueTask DisposeAsync()
    {
        if (_connection.State == ConnectionState.Open)
        {
            await _connection.CloseAsync();
        }
        _connection?.Dispose();
    }
}
```

## wwwroot/index.html

HTML сторінка з таблицею турів та формою бронювання вже розташована у файлі.
Вона автоматично завантажує тури при відкритті та відправляє запити через fetch API.

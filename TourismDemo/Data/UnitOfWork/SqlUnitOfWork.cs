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
    private IReviewRepository? _reviewRepository;
    private IPaymentRepository? _paymentRepository;
    private IAuditLogRepository? _auditLogRepository;

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

    public IReviewRepository Reviews
    {
        get
        {
            _reviewRepository ??= new SqlReviewRepository(_connection);
            return _reviewRepository;
        }
    }

    public IPaymentRepository Payments
    {
        get
        {
            _paymentRepository ??= new SqlPaymentRepository(_connection);
            return _paymentRepository;
        }
    }

    public IAuditLogRepository AuditLogs
    {
        get
        {
            _auditLogRepository ??= new SqlAuditLogRepository(_connection);
            return _auditLogRepository;
        }
    }

    public async Task CommitAsync()
    {
        // Мінімальна реалізація для транзакцій при необхідності
        // Поточно - просто операції комітяються одразу
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

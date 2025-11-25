namespace TourismDemo.Data.UnitOfWork.Interfaces;

using TourismDemo.Data.Repositories.Interfaces;

public interface IUnitOfWork
{
    ITourRepository Tours { get; }
    IBookingRepository Bookings { get; }
    IReviewRepository Reviews { get; }
    IPaymentRepository Payments { get; }
    IAuditLogRepository AuditLogs { get; }
    Task CommitAsync();
}

namespace TourismDemo.Data.Repositories.Interfaces;

using TourismDemo.Data.DTOs;

// ========================================
// ІНТЕРФЕЙСИ РЕПОЗИТОРІЇВ
// ========================================

public interface ITourRepository
{
    Task<IEnumerable<TourDto>> GetActiveToursAsync();
    Task<IEnumerable<PopularTourDto>> GetPopularToursAsync();
    Task<TourDto> GetTourByIdAsync(int tourId);
}

public interface IBookingRepository
{
    Task<int> CreateBookingAsync(int tourId, int touristId, DateTime travelDate, int numberOfPeople = 1);
    Task<IEnumerable<BookingDto>> GetAllBookingsAsync();
    Task<bool> DeleteBookingAsync(int bookingId);
    Task<IEnumerable<UserBookingDetailDto>> GetUserBookingsAsync(int touristId);
}

public interface IReviewRepository
{
    Task<IEnumerable<ReviewDto>> GetTourReviewsAsync(int tourId);
    Task CreateReviewAsync(int tourId, int touristId, int rating, string title, string comment);
    Task<decimal> GetAverageRatingAsync(int tourId);
}

public interface IUserRepository
{
    Task<UserDto> GetUserByIdAsync(int userId);
    Task<IEnumerable<UserDto>> GetAllUsersAsync();
    Task<UserDto> GetUserByEmailAsync(string email);
}

public interface IGuideRepository
{
    Task<IEnumerable<GuideDto>> GetActiveGuidesAsync();
    Task<GuideDto> GetGuideByIdAsync(int guideId);
}

public interface ITouristProfileRepository
{
    Task<TouristProfileDto> GetProfileByUserIdAsync(int userId);
    Task<TouristProfileDto> GetProfileByIdAsync(int touristId);
}

public interface IPaymentRepository
{
    Task<IEnumerable<PaymentDto>> GetBookingPaymentsAsync(int bookingId);
    Task<int> CreatePaymentAsync(int bookingId, int paymentMethodId, decimal amount);
    Task ConfirmPaymentAsync(int paymentId, string transactionId);
}

public interface ITourScheduleRepository
{
    Task<IEnumerable<TourScheduleDto>> GetUpcomingSchedulesAsync();
    Task<TourScheduleDto> GetScheduleByIdAsync(int scheduleId);
}

public interface IAuditLogRepository
{
    Task<IEnumerable<AuditLogDto>> GetAuditLogsAsync(string tableName, int recordId);
    Task<IEnumerable<AuditLogDto>> GetUserAuditLogsAsync(string userId);
}

public interface ICategoryRepository
{
    Task<IEnumerable<TourCategoryDto>> GetAllCategoriesAsync();
}

public interface ILocationRepository
{
    Task<IEnumerable<CountryDto>> GetAllCountriesAsync();
    Task<IEnumerable<CityDto>> GetCitiesByCountryAsync(int countryId);
}

namespace TourismDemo.Data.DTOs;

// Існуючі DTOs
public class TourDto
{
    public int TourId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Country { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal Rating { get; set; }
}

public class BookingDto
{
    public int BookingId { get; set; }
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public DateTime TravelDate { get; set; }
    public DateTime BookingDate { get; set; }
    public string TourName { get; set; } = string.Empty;
}

// ========================================
// НОВІ DTOs для розширених сутностей
// ========================================

public class UserDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string UserRole { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
}

public class CountryDto
{
    public int CountryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class RegionDto
{
    public int RegionId { get; set; }
    public int CountryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
}

public class CityDto
{
    public int CityId { get; set; }
    public int RegionId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string RegionName { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
}

public class TourCategoryDto
{
    public int CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class GuideDto
{
    public int GuideId { get; set; }
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public int Experience { get; set; }
    public string Languages { get; set; } = string.Empty;
    public decimal AverageRating { get; set; }
}

public class TouristProfileDto
{
    public int TouristId { get; set; }
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Nationality { get; set; } = string.Empty;
}

public class PaymentDto
{
    public int PaymentId { get; set; }
    public int BookingId { get; set; }
    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
}

public class ReviewDto
{
    public int ReviewId { get; set; }
    public int TourId { get; set; }
    public string TourName { get; set; } = string.Empty;
    public string TouristName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
}

public class TourScheduleDto
{
    public int ScheduleId { get; set; }
    public int TourId { get; set; }
    public string TourName { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int AvailableSpots { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class UserBookingDetailDto
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int BookingId { get; set; }
    public DateTime BookingDate { get; set; }
    public string TourName { get; set; } = string.Empty;
    public string DestinationCity { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int NumberOfPeople { get; set; }
    public decimal TotalPrice { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal TourRating { get; set; }
}

public class PopularTourDto
{
    public int TourId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string DestinationCity { get; set; } = string.Empty;
    public int DurationDays { get; set; }
    public decimal Price { get; set; }
    public int TotalBookings { get; set; }
    public int TotalParticipants { get; set; }
    public decimal AverageRating { get; set; }
}

public class AuditLogDto
{
    public int AuditId { get; set; }
    public string TableName { get; set; } = string.Empty;
    public int RecordId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string OldValue { get; set; } = string.Empty;
    public string NewValue { get; set; } = string.Empty;
    public string ModifiedBy { get; set; } = string.Empty;
    public DateTime ModifiedDate { get; set; }
}

// ========================================
// REQUEST DTOs
// ========================================

public class BookingRequest
{
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public DateTime TravelDate { get; set; }
    public int NumberOfPeople { get; set; } = 1;
}

public class CreateReviewRequest
{
    public int TourId { get; set; }
    public int TouristId { get; set; }
    public int Rating { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Comment { get; set; } = string.Empty;
}

public class CreatePaymentRequest
{
    public int BookingId { get; set; }
    public int PaymentMethodId { get; set; }
    public decimal Amount { get; set; }
}

public class ConfirmPaymentRequest
{
    public string TransactionId { get; set; } = string.Empty;
}

public class CreateTourRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int DestinationCityId { get; set; }
    public int DurationDays { get; set; }
    public int MaxParticipants { get; set; }
    public decimal Price { get; set; }
    public string Difficulty { get; set; } = "Medium";
}

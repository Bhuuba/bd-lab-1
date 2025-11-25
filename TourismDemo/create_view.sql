IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name='vw_ActiveTours')
BEGIN
    CREATE VIEW vw_ActiveTours AS
    SELECT 
        t.TourId, 
        t.Name, 
        c.Name AS Country, 
        ct.Name AS City, 
        t.Price, 
        dbo.fn_GetAverageRating(t.TourId) AS Rating
    FROM Tours t
    INNER JOIN Cities ct ON t.DestinationCityId = ct.CityId
    INNER JOIN Regions r ON ct.RegionId = r.RegionId
    INNER JOIN Countries c ON r.CountryId = c.CountryId
    WHERE t.IsActive = 1 AND t.IsDeleted = 0
END

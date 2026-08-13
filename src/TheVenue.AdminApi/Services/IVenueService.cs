using TheVenue.Domain.Locations;
using TheVenue.Domain.Venues;

namespace TheVenue.AdminApi.Services;

public interface IVenueService
{
    Task<IReadOnlyCollection<Zone>> GetZones(VenueId venueId);
    Task<ZoneId> CreateZone(VenueId venueId, Zone zone);
    
}

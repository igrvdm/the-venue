using TheVenue.Domain.Locations;
using TheVenue.Domain.Venues;

namespace TheVenue.AdminApi.Services;

public class StubVenueService : IVenueService
{
    public Task<IReadOnlyCollection<Zone>> GetZones(VenueId venueId)
    {
        var tableA1 = new ZoneTable(Capacity: new(4));
        var tableA2 = new ZoneTable(Capacity: new(4));
        var tableA3 = new ZoneTable(Capacity: new(4));

        IReadOnlyCollection<Zone> zones =
        [
            new(
                Id: new(Guid.NewGuid()),
                Name: new("first-A-1"),
                Tables: new()
                {
                    [new(1)] = tableA1,
                    [new(2)] = tableA2,
                    [new(3)] = tableA3,
                })
        ];

        return Task.FromResult(zones);
    }

    public Task<ZoneId> CreateZone(VenueId venueId, Zone zone)
    {
        return Task.FromResult(zone.Id);
    }
}
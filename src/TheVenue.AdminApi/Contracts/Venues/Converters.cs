using TheVenue.Domain.Locations;

namespace TheVenue.AdminApi.Contracts.Venues;

public static class Converters
{
    public static ZoneResponse ToResponse(this Zone zone)
    {
        var tables = zone.Tables.Select(kv =>
            new ZoneTableResponse(Number: kv.Key.Value, Capacity: kv.Value.Capacity.Value)).ToArray();

        return new ZoneResponse(zone.Id.Value, zone.Name.Value, tables
        );
    }
}
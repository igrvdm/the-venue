using TheVenue.Domain.Locations;
using TheVenue.Domain.Venues;

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

    public static Zone ToZone(this CreateZoneRequest createRequest)
    {
        Dictionary<TableNumber, ZoneTable> tables = createRequest.Tables
            .SelectMany(entry => Enumerable.Range(0, entry.Amount)
                .Select(_ => new ZoneTable(new(entry.Capacity)))
            )
            .Select((table, index) => new { Number = new TableNumber(index + 1), Table = table })
            .ToDictionary(entry => entry.Number, entry => entry.Table);
        return new Zone(Name: new(createRequest.Name), Id: new(Guid.NewGuid()), Tables: tables);
    }
}
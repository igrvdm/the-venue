namespace TheVenue.Domain.Locations;

public sealed record Zone(ZoneId Id, ZoneName Name, Dictionary<TableNumber, ZoneTable> Tables);

public readonly record struct ZoneId(Guid Value);

public readonly record struct ZoneName(string Value);

public readonly record struct TableNumber(int Value);
namespace TheVenue.Domain.Locations;

public sealed record ZoneTable(TableCapacity Capacity);

public readonly record struct TableCapacity(int Value);

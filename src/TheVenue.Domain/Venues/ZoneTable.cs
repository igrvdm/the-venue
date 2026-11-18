namespace TheVenue.Domain.Venues;

public sealed record ZoneTable(TableCapacity Capacity);

public readonly record struct TableCapacity(int Value);

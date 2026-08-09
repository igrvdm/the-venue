namespace TheVenue.Domain.Locations;

public sealed record Location(Latitude Latitude, Longitude Longitude, string Address);

public readonly record struct Latitude(double Value);

public readonly record struct Longitude(double Value);
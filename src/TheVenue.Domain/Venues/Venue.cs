using TheVenue.Domain.Locations;

namespace TheVenue.Domain.Venues;

public sealed record Venue(
    VenueId Id,
    VenueName Name,
    Location Location,
    VenueKind Kind,
    IReadOnlyList<Zone> Zones);

public readonly record struct VenueName(string Value);

public readonly record struct VenueId(Guid Value);

public enum VenueKind
{
    Generic = 0,
    Restaurant,
    Cafe,
    Bistro,
    Bar,
}
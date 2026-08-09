namespace TheVenue.AdminApi.Contracts.Venues;

public sealed record ZoneResponse(
    Guid Id,
    string Name,
    IReadOnlyCollection<ZoneTableResponse> Tables);

public sealed record ZoneTableResponse(
    int Number,
    int Capacity);


    
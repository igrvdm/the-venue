using TheVenue.Domain.Locations;
using TheVenue.Domain.Venues;

namespace TheVenue.AdminApi.Contracts.Venues;

public sealed record CreateZoneRequest(string Name, IReadOnlyCollection<TableSetRequest> Tables);

public sealed record TableSetRequest(int Amount, int Capacity);
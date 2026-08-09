using TheVenue.AdminApi.Contracts.Venues;
using TheVenue.AdminApi.Services;

namespace TheVenue.AdminApi.Endpoints;

public static class EndpointMapping
{
    public static void ConfigureEndpoints(this WebApplication app)
    {
        app.MapGet(
            pattern: "/admin/venue/{venueId}/zones",
            handler: async (Guid venueId, IVenueService service) =>
            {
                var zones = await service.GetZones(new(venueId));
                return Results.Ok(zones.Select(z => z.ToResponse()));
            }
        );
    }
}
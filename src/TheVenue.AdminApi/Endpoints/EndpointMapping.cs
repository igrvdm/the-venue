using TheVenue.AdminApi.Contracts.Venues;
using TheVenue.AdminApi.Services;
using TheVenue.Domain.Venues;

namespace TheVenue.AdminApi.Endpoints;

public static class EndpointMapping
{
    public static void ConfigureEndpoints(this WebApplication app)
    {
        app.MapGet(
            pattern: "/admin/venues/{venueId:guid}/zones",
            handler: async (Guid venueId, IVenueService service) =>
            {
                var zones = await service.GetZones(new(venueId));
                return Results.Ok(zones.Select(z => z.ToResponse()));
            }
        );

        app.MapDelete(pattern: "/admin/venues/{id:guid}/zones/{createdId:guid}",
            handler: async (Guid venueId, Guid zoneId, IVenueService service) =>
            {
                await service.DeleteZone(new(venueId), new(zoneId));
                return Results.NoContent();
            });

        app.MapPost(pattern: "/admin/venues/{venueId:guid}/zones",
            handler: async (Guid venueId, CreateZoneRequest createRequest, IVenueService service) =>
            {
                var zone = createRequest.ToZone();
                var createdId = await service.CreateZone(venueId: new(venueId), zone);
                return Results.Created($"/admin/venues/{venueId}/zones/{createdId.Value}", new { id = createdId });
            }
        );
    }
}
using System.Runtime.InteropServices;

namespace TheVenue.AdminApi.Services;

public static class ServiceRegistration
{
    public static IServiceCollection AddAdminApiServices(this IServiceCollection services)
    {
        return services.AddScoped<IVenueService, StubVenueService>();
    }
}
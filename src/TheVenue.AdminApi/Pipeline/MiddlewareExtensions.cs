namespace TheVenue.AdminApi.Pipeline;

public static class MiddlewareExtensions
{
    public static void ConfigurePipeline(this WebApplication app)
    {
        app.UseHttpsRedirection();
        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();

        }
    }
}
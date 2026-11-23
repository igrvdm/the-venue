using TheVenue.AdminApi.Endpoints;
using TheVenue.AdminApi.Pipeline;
using TheVenue.AdminApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddAdminApiServices();

var adminApp = builder.Build();

adminApp.ConfigurePipeline();
adminApp.ConfigureEndpoints();

adminApp.Run();
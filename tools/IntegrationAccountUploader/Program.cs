using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;

static string? GetArg(string[] args, string name)
{
    var idx = Array.FindIndex(args, a => a.Equals(name, StringComparison.OrdinalIgnoreCase));
    return (idx >= 0 && idx + 1 < args.Length) ? args[idx + 1] : null;
}

var subscriptionId = GetArg(args, "--subscriptionId") ?? Environment.GetEnvironmentVariable("AZURE_SUBSCRIPTION_ID");
var resourceGroup = GetArg(args, "--resourceGroup");
var integrationAccount = GetArg(args, "--integrationAccount");
var location = GetArg(args, "--location");
var mapFile = GetArg(args, "--mapFile");
var mapName = GetArg(args, "--mapName") ?? "hello-xml-to-json";

if (string.IsNullOrWhiteSpace(subscriptionId) || string.IsNullOrWhiteSpace(resourceGroup) ||
    string.IsNullOrWhiteSpace(integrationAccount) || string.IsNullOrWhiteSpace(location) ||
    string.IsNullOrWhiteSpace(mapFile))
{
    Console.WriteLine("Usage:\n" +
        "  dotnet run -- --subscriptionId <subId> --resourceGroup <rg> --integrationAccount <iaName> --location <region> --mapFile <path> [--mapName <name>] [--cloud usgov|public]\n\n" +
        "Cloud: defaults to Azure Government (usgov). Use --cloud public or AZURE_CLOUD=public for commercial.\n" +
        "Auth: DefaultAzureCredential (az login / VS / MI). You can set AZURE_SUBSCRIPTION_ID env var.\n");
    return;
}

var cloud = (GetArg(args, "--cloud") ?? Environment.GetEnvironmentVariable("AZURE_CLOUD") ?? "usgov").ToLowerInvariant();
var isGov = cloud is not ("public" or "azurecloud" or "commercial");
var armEndpoint = isGov ? "https://management.usgovcloudapi.net" : "https://management.azure.com";

var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    AuthorityHost = isGov ? AzureAuthorityHosts.AzureGovernment : AzureAuthorityHosts.AzurePublicCloud
});
var token = await credential.GetTokenAsync(new TokenRequestContext(new[] { $"{armEndpoint}/.default" }));

using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);

var mapContent = await File.ReadAllTextAsync(mapFile);

var uri = $"{armEndpoint}/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationAccounts/{integrationAccount}/maps/{mapName}?api-version=2019-05-01";

var payload = new
{
    location,
    properties = new
    {
        mapType = "Liquid",
        content = mapContent
    }
};

var json = JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true });

var resp = await http.PutAsync(uri, new StringContent(json, Encoding.UTF8, "application/json"));
var respText = await resp.Content.ReadAsStringAsync();

if (!resp.IsSuccessStatusCode)
{
    Console.Error.WriteLine($"Upload failed ({(int)resp.StatusCode} {resp.ReasonPhrase}){Environment.NewLine}{respText}");
    Environment.ExitCode = 1;
    return;
}

Console.WriteLine($"Uploaded map '{mapName}' to Integration Account '{integrationAccount}'.");

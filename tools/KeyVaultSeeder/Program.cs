using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

static string? GetArg(string[] args, string name)
{
    var idx = Array.FindIndex(args, a => a.Equals(name, StringComparison.OrdinalIgnoreCase));
    return (idx >= 0 && idx + 1 < args.Length) ? args[idx + 1] : null;
}

var vaultName = GetArg(args, "--vault") ?? GetArg(args, "--vaultName");
var secretName = GetArg(args, "--name");
var secretValue = GetArg(args, "--value");

if (string.IsNullOrWhiteSpace(vaultName) || string.IsNullOrWhiteSpace(secretName) || secretValue is null)
{
    Console.WriteLine("Usage:\n" +
        "  dotnet run -- --vault <kvName> --name <secretName> --value <secretValue> [--cloud usgov|public]\n\n" +
        "Cloud: defaults to Azure Government (usgov). Use --cloud public or AZURE_CLOUD=public for commercial.\n" +
        "Auth: DefaultAzureCredential (az login / VS / MI).\n");
    return;
}

var cloud = (GetArg(args, "--cloud") ?? Environment.GetEnvironmentVariable("AZURE_CLOUD") ?? "usgov").ToLowerInvariant();
var isGov = cloud is not ("public" or "azurecloud" or "commercial");
var vaultSuffix = isGov ? "vault.usgovcloudapi.net" : "vault.azure.net";

var uri = new Uri($"https://{vaultName}.{vaultSuffix}/");
var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    AuthorityHost = isGov ? AzureAuthorityHosts.AzureGovernment : AzureAuthorityHosts.AzurePublicCloud
});
var client = new SecretClient(uri, credential);

await client.SetSecretAsync(secretName, secretValue);
Console.WriteLine($"Set secret '{secretName}' in vault '{vaultName}'.");

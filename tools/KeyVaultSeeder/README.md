# KeyVaultSeeder (C#)

Sets a secret in an Azure Key Vault.

```bash
dotnet restore

dotnet run --   --vault <KEY_VAULT_NAME>   --name my-setting   --value my-value
```

Auth uses `DefaultAzureCredential`. The tool targets **Azure Government** (`vault.usgovcloudapi.net`) by default; use `--cloud public` or `AZURE_CLOUD=public` for commercial Azure (`vault.azure.net`).

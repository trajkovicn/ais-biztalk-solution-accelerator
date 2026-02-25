# KeyVaultSeeder (C#)

Sets a secret in an Azure Key Vault.

```bash
dotnet restore

dotnet run --   --vault <KEY_VAULT_NAME>   --name my-setting   --value my-value
```

Auth uses `DefaultAzureCredential`.

# Integration Account Uploader (C#)

Uploads a **Liquid map** to an Azure Integration Account using the Logic Apps ARM REST API.

```bash
dotnet restore

dotnet run --   --subscriptionId <SUBSCRIPTION_ID>   --resourceGroup <RESOURCE_GROUP>   --integrationAccount <INTEGRATION_ACCOUNT_NAME>   --location <usgovvirginia|usgovarizona|usgovtexas>   --mapFile ../../integration/maps/liquid/hello-xml-to-json.liquid   --mapName hello-xml-to-json
```

The tool targets **Azure Government** (management.usgovcloudapi.net) by default. Use `--cloud public` or `AZURE_CLOUD=public` for commercial Azure.

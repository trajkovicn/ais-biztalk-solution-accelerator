# Integration Account Uploader (C#)

Uploads a **Liquid map** to an Azure Integration Account using the Logic Apps ARM REST API.

```bash
dotnet restore

dotnet run --   --subscriptionId <SUBSCRIPTION_ID>   --resourceGroup <RESOURCE_GROUP>   --integrationAccount <INTEGRATION_ACCOUNT_NAME>   --location <eastus|westus2>   --mapFile ../../integration/maps/liquid/hello-xml-to-json.liquid   --mapName hello-xml-to-json
```

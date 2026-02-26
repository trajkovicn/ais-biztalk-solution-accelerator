![Azure Integration Services](https://img.shields.io/badge/Azure-Integration%20Services-blue)
![BizTalk](https://img.shields.io/badge/BizTalk-Server-orange)
![BizTalk Migration](https://img.shields.io/badge/BizTalk-Migration-orange)
![CSharp](https://img.shields.io/badge/C%23-.NET%208.0-blueviolet)
![License](https://img.shields.io/badge/License-MIT-green)

# AIS BizTalk Solution Accelerator

A VS Code–friendly starter accelerator that provisions an Azure Integration Services (AIS) baseline to help customers begin migrating from BizTalk Server.

## What this deploys (DEV baseline)

- Logic App (Consumption) **Hello World** workflow: HTTP POST accepts **XML**, writes to `xml-store`, sends message to Service Bus, returns 200.
- **Key Vault**: stores generated connection strings/keys as secrets (Storage key, Storage name, Service Bus connection string).
- Optional Integration Account + starter **Liquid map** (XML → JSON) and a sample **Liquid Logic App**.
- Service Bus namespace + `inbound` queue
- Storage Account (ADLS Gen2 enabled) + Blob container `xml-store` + Azure Files shares `drop` and `pickup`
- Log Analytics workspace

## Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftrajkovicn%2Fais-biztalk-solution-accelerator%2Fmain%2Finfra%2Farm%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftrajkovicn%2Fais-biztalk-solution-accelerator%2Fmain%2Finfra%2Farm%2FcreateUiDefinition.json)

## Hello World test

```bash
curl -X POST "<CALLBACK_URL>"   -H "Content-Type: application/xml"   --data '<Hello><From>BizTalk</From><Message>World</Message></Hello>'
```

## Liquid sample test

If you deployed the Integration Account, you will also get a second Logic App named `...-liquid`.
Trigger it with the same XML payload to see a JSON response.

## Tools (C#)

- `tools/IntegrationAccountUploader` — uploads Liquid maps to Integration Account via ARM REST.
- `tools/KeyVaultSeeder` — sets a Key Vault secret.

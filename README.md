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
- Optional **Virtual Network** with pre-defined subnets (`snet-private-endpoints`, `snet-servicebus`, `snet-keyvault`, `snet-storage`) and optional DNS Private Resolver subnets

## Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftrajkovicn%2Fais-biztalk-solution-accelerator%2Fmain%2Finfra%2Farm%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftrajkovicn%2Fais-biztalk-solution-accelerator%2Fmain%2Finfra%2Farm%2FcreateUiDefinition.json)

## Hello World test

After the deployment completes, a Consumption Logic App named `la-<ou>-<biz>-<app>-<env>-<region>-<instance>` is created with an HTTP POST trigger. This is a fully wired end-to-end sample that demonstrates a typical BizTalk-style "receive → persist → queue" pattern using Azure Integration Services.

### What the workflow does

1. **Receives** an HTTP POST with an XML body.
2. **Generates** a unique Correlation ID (`guid`) for tracing.
3. **Validates** the `Content-Type` header — only `application/xml` and `text/xml` are accepted.
4. **Writes** the raw XML payload as a blob to the `xml-store` container in ADLS Gen2 (filename: `hello-<correlationId>.xml`).
5. **Sends** the Base64-encoded XML as a message to the Service Bus `inbound` queue, tagged with the same Correlation ID.
6. **Returns** a `200 OK` JSON response confirming storage and queuing, or `415 Unsupported Media Type` if the content type is wrong.

### Getting the callback URL

1. Open the [Azure portal](https://portal.azure.com) and navigate to the deployed Logic App.
2. On the **Overview** blade, click the **trigger** (`When_a_HTTP_request_is_received`).
3. Copy the **HTTP POST URL** — this is the `<CALLBACK_URL>` you'll use below.

### Running the test

```bash
curl -X POST "<CALLBACK_URL>" \
  -H "Content-Type: application/xml" \
  --data '<Hello><From>BizTalk</From><Message>World</Message></Hello>'
```

### Expected response (`200 OK`)

```json
{
  "message": "Hello from AIS BizTalk Accelerator (DEV)",
  "correlationId": "<guid>",
  "storedIn": "xml-store",
  "queuedTo": "inbound"
}
```

### What to verify after the call

| Where to look                               | What you should see                                                                     |
| ------------------------------------------- | --------------------------------------------------------------------------------------- |
| **Storage Account** → `xml-store` container | A new blob named `hello-<correlationId>.xml` containing the XML payload.                |
| **Service Bus** → `inbound` queue           | A new message with `ContentData` (Base64-encoded XML) and the matching `CorrelationId`. |

### Error case

If you omit the `Content-Type` header or send a non-XML content type, the Logic App returns:

```json
{
  "message": "Unsupported Media Type. Send XML with Content-Type application/xml or text/xml.",
  "correlationId": "<guid>"
}
```

(HTTP `415 Unsupported Media Type`)

---

## Liquid sample test

If you deployed the Integration Account, you will also get a second Logic App named `la-...-liquid`. This workflow accepts the same XML payload, transforms it to JSON using the `hello-xml-to-json` Liquid map stored in the Integration Account, and returns the JSON result.

### Running the Liquid test

```bash
curl -X POST "<LIQUID_CALLBACK_URL>" \
  -H "Content-Type: application/xml" \
  --data '<Hello><From>BizTalk</From><Message>World</Message></Hello>'
```

### Expected response

```json
{
  "from": "BizTalk",
  "message": "World"
}
```

This demonstrates how Integration Account maps (Liquid/XSLT) can be used in Logic Apps as a replacement for BizTalk Server map functoids.

## Tools (C#)

- `tools/IntegrationAccountUploader` — uploads Liquid maps to Integration Account via ARM REST.
- `tools/KeyVaultSeeder` — sets a Key Vault secret.

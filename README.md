![Azure Integration Services](https://img.shields.io/badge/Azure-Integration%20Services-blue)
![BizTalk](https://img.shields.io/badge/BizTalk-Server-orange)
![BizTalk Migration](https://img.shields.io/badge/BizTalk-Migration-orange)
![CSharp](https://img.shields.io/badge/C%23-.NET%208.0-blueviolet)
![License](https://img.shields.io/badge/License-MIT-green)

# AIS BizTalk Solution Accelerator

A VS Code–friendly starter accelerator that provisions an Azure Integration Services (AIS) baseline to help customers begin migrating from BizTalk Server.

## Why this accelerator exists

### BizTalk Server end-of-support

Microsoft has announced that **BizTalk Server will reach end of mainstream support in April 2030**. After that date, BizTalk Server will no longer receive feature updates, and extended support will be limited. Organizations that depend on BizTalk for B2B, EDI, EAI, and messaging workloads need to begin planning their migration path now — not when the clock runs out.

### Azure Integration Services: the cloud-native successor

**Azure Integration Services (AIS)** is Microsoft's cloud-native integration platform and the natural progression for BizTalk Server customers moving to Azure. AIS is not a single product — it's a suite of fully managed services that, together, replace and extend BizTalk's capabilities:

| AIS Service                      | What it does                                                                                                                                                             | BizTalk equivalent                            |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- |
| **Logic Apps**                   | Visual workflow orchestration with 1,000+ connectors. Available in Consumption (serverless, pay-per-execution) and Standard (dedicated, VNet-integrated) hosting models. | Orchestrations, ports, pipelines              |
| **Service Bus**                  | Enterprise messaging with queues, topics, sessions, and dead-lettering.                                                                                                  | MessageBox, direct-bound ports                |
| **API Management**               | API gateway with policies, rate limiting, OAuth, and developer portal.                                                                                                   | WCF/REST endpoints, adapters                  |
| **Event Grid**                   | Event-driven pub/sub for reactive integrations.                                                                                                                          | Polling receive locations                     |
| **Integration Account**          | B2B hub for trading partners, agreements, schemas (XSD), and maps (XSLT/Liquid).                                                                                         | BizTalk Admin Console, parties, maps, schemas |
| **Azure Data Factory / Synapse** | Data movement and transformation at scale.                                                                                                                               | Flat-file pipelines, large batch processing   |

### What problems does AIS solve?

- **Infrastructure overhead** — BizTalk requires Windows Server VMs, SQL Server databases, SSO, and host instances. AIS is fully managed; there are no servers to patch or scale.
- **Scaling limitations** — BizTalk scales vertically (bigger VMs) or through manual host-instance configuration. Logic Apps (Consumption) scale automatically per-execution; Standard hosting supports scaling rules.
- **Connector ecosystem** — BizTalk adapters are finite and require custom development for new systems. Logic Apps provides 1,000+ managed connectors out of the box (SAP, Salesforce, Oracle, IBM MQ, file systems, and more).
- **Deployment agility** — BizTalk deployments involve MSI packages, binding files, and manual steps. AIS supports ARM/Bicep templates, CI/CD pipelines, and one-click deployment (see the button below).
- **Cost model** — BizTalk licensing is per-core. AIS offers pay-per-use (Consumption) or predictable hosting (Standard), allowing customers to right-size costs to actual workload volumes.

### Where this accelerator fits in

This repository provides a **ready-to-deploy DEV baseline** that provisions core AIS services in a single click. It is designed to give BizTalk teams a hands-on starting point — not a production architecture — so they can:

1. **Explore** the AIS service landscape with real, deployed resources.
2. **Validate** integration patterns (receive → persist → queue → transform) against familiar BizTalk concepts.
3. **Extend** the baseline with their own schemas, maps, trading partners, and workflows.
4. **Estimate** costs using actual Azure meters before committing to a full migration plan.

## What this deploys (DEV baseline)

- Logic App (Consumption) **Hello World** workflow: HTTP POST accepts **XML**, writes to `xml-store`, sends message to Service Bus, returns 200.
- **Key Vault**: stores generated connection strings/keys as secrets (Storage key, Storage name, Service Bus connection string).
- Optional Integration Account + starter **Liquid map** (XML → JSON) and a sample **Liquid Logic App**.
- Service Bus namespace + `inbound` queue
- Storage Account (ADLS Gen2 enabled) + Blob container `xml-store` + Azure Files shares `drop` and `pickup`
- Log Analytics workspace
- Optional **Virtual Network** with pre-defined subnets (`snet-private-endpoints`, `snet-servicebus`, `snet-keyvault`, `snet-storage`) and optional DNS Private Resolver subnets
- Optional **Private Endpoints** for Service Bus, Storage (Blob + File), and Key Vault — placed in the `snet-private-endpoints` subnet with corresponding Private DNS Zones

---

## Resource deep dive

### Logic App (Consumption) — the heart of the accelerator

In BizTalk Server, an **Orchestration** is the central artefact: a compiled XLANG/s schedule that coordinates receive ports, send ports, maps, business rules, and exception handling inside a dehydratable state machine. Building even a simple "receive → transform → send" flow requires Visual Studio, a BizTalk project, strong-name signing, GAC deployment, binding files, and host-instance restarts.

**Logic Apps replace Orchestrations** — and much more. A single Logic App can:

| BizTalk concept                    | Logic App equivalent                                                                      |
| ---------------------------------- | ----------------------------------------------------------------------------------------- |
| Orchestration (XLANG/s)            | Workflow definition (ARM/Bicep JSON or designer canvas)                                   |
| Receive Port / Receive Location    | **Trigger** (HTTP, Service Bus, File, Timer, Event Grid, etc.)                            |
| Send Port / Send Port Group        | **Action** — any of the 1,000+ managed connectors                                         |
| Map (XSLT / functoids)             | **Transform XML/JSON** action + Integration Account maps (XSLT or Liquid)                 |
| Business Rules Engine (BRE)        | Condition / Switch / Until control-flow actions, or Azure Functions for complex rule sets |
| Promoted properties / context      | Tracked properties, `triggerBody()`, variables, and correlation tokens                    |
| Convoy / sequential convoy         | Service Bus sessions + peek-lock patterns                                                 |
| Dehydration / rehydration          | Built-in — Consumption Logic Apps automatically persist state between actions             |
| Exception handling (scope / catch) | **Scope** with `runAfter` conditions (`Failed`, `TimedOut`)                               |
| Compensation                       | Scope-based rollback logic with `runAfter: Failed` paths                                  |
| Correlation sets                   | Workflow-managed correlation via connector properties or tracked properties               |

#### The Hello World workflow as a learning tool

The accelerator deploys a small but complete workflow that mirrors a classic BizTalk receive-persist-queue pattern:

```
HTTP POST (XML) ──▶ Generate Correlation ID
                        │
                        ▼
                   Validate Content-Type
                        │
              ┌─────────┴──────────┐
              │ XML                 │ Other
              ▼                     ▼
     Write blob to ADLS Gen2   Return 415
     (hello-<guid>.xml)
              │
              ▼
     Send message to Service Bus
     (inbound queue, with CorrelationId)
              │
              ▼
     Return 200 JSON response
```

In BizTalk, implementing this same flow would require:

1. An **HTTP Receive Location** bound to an isolated host (IIS).
2. A **custom pipeline component** (or XML Disassembler) to validate and promote the content type.
3. A **Send Port** with a FILE adapter to persist the message.
4. A second **Send Port** with the SB-Messaging adapter (or WCF-Custom) to publish to Service Bus.
5. An **Orchestration** to coordinate steps 2 – 4, with a correlation set for the GUID.
6. **Binding files**, **BTSTask** deployment, and **host-instance restarts**.

In Logic Apps, all of this is expressed in a single JSON workflow definition — deployed in seconds via ARM/Bicep, editable in the portal designer or VS Code, and auto-scaled by the platform.

#### Moving beyond Hello World

Because Logic Apps are additive, extending the workflow is straightforward:

- **Add a transform step** — insert a "Transform XML" action that calls an Integration Account XSLT or Liquid map, replicating BizTalk map execution inside a pipeline.
- **Add conditional routing** — use a Switch or Condition action to route messages to different queues or endpoints, replacing BizTalk filter expressions on send ports.
- **Add error handling** — wrap actions in a Scope, configure `runAfter: Failed`, and send failures to a dead-letter queue or alert — replacing BizTalk's exception-handling shapes.
- **Add approval / long-running patterns** — Consumption Logic Apps natively support waiting for external callbacks (webhooks), replacing BizTalk's listen/delay shapes and human-interaction patterns.
- **Chain workflows** — call one Logic App from another, replicating BizTalk's "Start Orchestration" and "Call Orchestration" shapes.

### Service Bus — replacing the MessageBox

In BizTalk, the **MessageBox** (a SQL Server database) is the central publish-subscribe hub: every message passes through it, and subscriptions (filters) route messages to orchestrations and send ports. This is powerful but creates a SQL dependency, requires careful throttling, and is difficult to scale independently.

**Azure Service Bus** provides enterprise messaging without the database overhead:

- **Queues** act as point-to-point channels (like BizTalk direct-bound ports).
- **Topics + Subscriptions** enable publish-subscribe with SQL-like filter rules — conceptually identical to BizTalk MessageBox subscriptions, but fully managed and independently scalable.
- **Sessions** guarantee ordered, exactly-once processing — replacing BizTalk ordered delivery and sequential convoys.
- **Dead-letter queues** capture failed messages automatically, replacing BizTalk's suspended-instance model with an inspectable, replayable queue.

The accelerator creates a `Standard` namespace with an `inbound` queue, giving you immediate messaging infrastructure to receive, inspect, and replay messages.

### Storage Account (ADLS Gen2) — replacing file adapters and archive stores

BizTalk's **FILE adapter** and **FTP/SFTP adapters** write messages to disk or remote shares. Archive copies are handled by pipeline configuration or custom components. There is no built-in data-lake capability.

The accelerator provisions an **Azure Data Lake Storage Gen2** account with:

- A **Blob container** (`xml-store`) — the Hello World workflow writes received XML here, demonstrating the "archive a copy" pattern that BizTalk teams typically implement via a passthrough send port.
- **Azure Files shares** (`drop` and `pickup`) — SMB-mountable shares that replicate the familiar file-drop pattern. On-premises BizTalk FILE receive locations can be pointed at these shares (via Azure File Sync or VPN), enabling a gradual, side-by-side migration.
- **Hierarchical namespace** enabled — supporting folder-level ACLs and Spark/Synapse interoperability for future data workloads.

### Key Vault — centralised secret management

BizTalk typically stores connection strings in **binding files** (XML), SSO affiliate applications, or custom config stores — all requiring manual management and often leading to secrets embedded in deployment packages.

**Azure Key Vault** provides:

- Centralised, audited storage for secrets, keys, and certificates.
- Managed identity integration — Logic Apps, Functions, and other AIS services retrieve secrets at runtime without storing credentials in code or config.
- Automatic rotation capabilities — replacing the manual key-rotation processes common in BizTalk environments.

The accelerator seeds Key Vault with the Storage key, Storage account name, and Service Bus connection string, demonstrating the recommended pattern for secret management in AIS.

### Integration Account — replacing BizTalk Admin Console artefacts

The BizTalk Admin Console manages **schemas** (XSD), **maps** (XSLT), **pipelines**, **trading partners**, **agreements**, and **certificates**. All of these are deployed via BizTalk Server and tightly coupled to the runtime.

The **Integration Account** is the AIS equivalent — a cloud-hosted repository for:

| Artefact type         | BizTalk equivalent                         | How the accelerator uses it                                                              |
| --------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------- |
| Schemas (XSD)         | BizTalk schemas                            | Upload via the `IntegrationAccountUploader` tool                                         |
| Maps (XSLT / Liquid)  | BizTalk maps (functoid-based XSLT)         | A starter `hello-xml-to-json.liquid` map is deployed and invoked by the Liquid Logic App |
| Partners & Agreements | BizTalk parties & agreements               | Not yet provisioned — ready for you to add your own B2B/EDI trading partners             |
| Certificates          | BizTalk certificates (signing, encryption) | Upload via Azure portal or ARM when you need AS2/X12 signing                             |

The Liquid map deployed with this accelerator transforms XML to JSON — a common BizTalk-to-AIS migration step, since many downstream systems prefer JSON while legacy sources still send XML.

### Log Analytics — replacing BAM and health monitoring

BizTalk provides **Business Activity Monitoring (BAM)** for tracking, **Health and Activity Tracking (HAT)** for debugging, and **MOM / SCOM** integration for operational monitoring. These require separate databases, OLAP cubes, and portal configuration.

**Log Analytics** replaces all three with a single workspace:

- **Diagnostic logs** from every AIS resource (Logic App runs, Service Bus metrics, Key Vault access events) stream into one place.
- **KQL queries** let you build custom dashboards, replacing BAM views with far more flexibility.
- **Alerts** can be configured on any metric or log pattern, replacing SCOM-based health monitoring.

### Virtual Network (optional) — network isolation

BizTalk Server typically sits inside a corporate network, with firewall rules controlling access to adapters and endpoints. There is no built-in cloud networking.

When enabled, the accelerator deploys a **Virtual Network** with purpose-built subnets and optional **Private Endpoints** that place Service Bus, Storage, and Key Vault traffic on the private network — ensuring that no data traverses the public internet. This replicates the network-isolation posture that BizTalk teams expect in regulated environments.

---

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

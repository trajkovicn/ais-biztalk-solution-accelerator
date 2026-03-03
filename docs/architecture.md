# Architecture

This accelerator deploys an Azure Integration Services (AIS) baseline to begin BizTalk migrations.

## Core resources

- Logic Apps (Consumption): Hello World XML ingress, plus optional Liquid sample.
- Service Bus: namespace + queues.
- Storage: ADLS Gen2 (HNS enabled) + blob container `xml-store` + file shares.
- Integration Account (optional): maps/schemas including Liquid maps.
- Key Vault: stores generated connection strings/keys as secrets for later use.
- Log Analytics workspace.

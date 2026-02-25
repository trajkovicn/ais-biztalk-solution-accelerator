@description('Key Vault name. Must be 3-24 chars, start with a letter.')
param name string

@description('Azure region')
param location string

@description('Tenant ID (Microsoft Entra)')
param tenantId string

@description('Object ID (GUID) for a user or group granted secret permissions (DEV convenience).')
param adminObjectId string

resource vault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: adminObjectId
        permissions: {
          secrets: [ 'get', 'list', 'set', 'delete' ]
          keys: []
          certificates: []
          storage: []
        }
      }
    ]
  }
}

output id string = vault.id
output name string = vault.name

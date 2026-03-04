@description('Azure region for all resources.')
param location string

@description('Resource ID of the snet-private-endpoints subnet.')
param privateEndpointsSubnetId string

@description('Resource ID of the VNet (used for DNS zone links).')
param vnetId string

@description('VNet name (used for DNS zone virtual-network-link naming).')
param vnetName string

// ── Storage Account ──────────────────────────────────────────
@description('Resource ID of the Storage Account.')
param storageAccountId string

@description('Storage Account name (used in PE naming).')
param storageAccountName string

// ── Key Vault ────────────────────────────────────────────────
@description('Resource ID of the Key Vault.')
param keyVaultId string

@description('Key Vault name (used in PE naming).')
param keyVaultName string

// ══════════════════════════════════════════════════════════════
// Private DNS Zones
// ══════════════════════════════════════════════════════════════

resource dnsBlob 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource dnsFile 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

resource dnsVault 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

// ══════════════════════════════════════════════════════════════
// VNet links (so DNS queries inside the VNet resolve to PEs)
// ══════════════════════════════════════════════════════════════

resource linkBlob 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsBlob
  name: '${vnetName}-blob'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource linkFile 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsFile
  name: '${vnetName}-file'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource linkVault 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsVault
  name: '${vnetName}-vault'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

// ══════════════════════════════════════════════════════════════
// Private Endpoints
// ══════════════════════════════════════════════════════════════

resource peBlob 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${storageAccountName}-blob'
  location: location
  properties: {
    subnet: { id: privateEndpointsSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'pe-${storageAccountName}-blob'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource peFile 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${storageAccountName}-file'
  location: location
  properties: {
    subnet: { id: privateEndpointsSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'pe-${storageAccountName}-file'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: ['file']
        }
      }
    ]
  }
}

resource peVault 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${keyVaultName}'
  location: location
  properties: {
    subnet: { id: privateEndpointsSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'pe-${keyVaultName}'
        properties: {
          privateLinkServiceId: keyVaultId
          groupIds: ['vault']
        }
      }
    ]
  }
}

// ══════════════════════════════════════════════════════════════
// DNS Zone Groups (auto-register PE IP in the private DNS zone)
// ══════════════════════════════════════════════════════════════

resource dnsGroupBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: peBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: dnsBlob.id
        }
      }
    ]
  }
}

resource dnsGroupFile 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: peFile
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'file'
        properties: {
          privateDnsZoneId: dnsFile.id
        }
      }
    ]
  }
}

resource dnsGroupVault 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: peVault
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault'
        properties: {
          privateDnsZoneId: dnsVault.id
        }
      }
    ]
  }
}

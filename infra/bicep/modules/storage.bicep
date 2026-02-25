@description('Storage account name (must be 3-24 chars, lowercase letters/numbers only)')
param name string

@description('Azure region')
param location string

@description('Create these blob containers')
param containers array = [
  'xml-store'
  'audit'
]

@description('Create these file shares')
param fileShares array = [
  'drop'
  'pickup'
]

resource st 'Microsoft.Storage/storageAccounts@2025-06-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-06-01' = {
  name: '${name}/default'
  dependsOn: [ st ]
  properties: {}
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-06-01' = [for c in containers: {
  name: '${name}/default/${c}'
  dependsOn: [ blobService ]
  properties: {
    publicAccess: 'None'
  }
}]

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2025-06-01' = {
  name: '${name}/default'
  dependsOn: [ st ]
  properties: {}
}

resource shares 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-06-01' = [for s in fileShares: {
  name: '${name}/default/${s}'
  dependsOn: [ fileService ]
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}]

output id string = st.id

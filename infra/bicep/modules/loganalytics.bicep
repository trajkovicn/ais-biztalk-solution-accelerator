@description('Log Analytics workspace name')
param name string

@description('Azure region')
param location string

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

output id string = law.id

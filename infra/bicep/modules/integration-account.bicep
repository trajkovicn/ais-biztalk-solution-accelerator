@description('Name of the Integration Account.')
param name string

@description('Azure region for the Integration Account. Must match the region of Logic Apps that will link to it.')
param location string

@allowed([
  'Free'
  'Basic'
  'Standard'
])
@description('Integration Account pricing tier.')
param skuName string = 'Basic'

resource integrationAccount 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {}
}

output id string = integrationAccount.id

@description('Service Bus namespace name')
param namespaceName string

@description('Azure region')
param location string

@description('Queue names to create')
param queueNames array = [
  'inbound'
  'outbound'
  'errors'
]

resource sb 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {}
}

// ── Queues ───────────────────────────────────────────────────
resource queues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [
  for q in queueNames: {
    parent: sb
    name: q
    properties: {
      lockDuration: 'PT1M'
      maxSizeInMegabytes: 1024
      defaultMessageTimeToLive: 'P14D'
      deadLetteringOnMessageExpiration: true
    }
  }
]

resource auth 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' = {
  parent: sb
  name: 'logicapps-dev'
  properties: {
    rights: ['Manage', 'Send', 'Listen']
  }
}

output namespaceId string = sb.id
output authRuleId string = auth.id

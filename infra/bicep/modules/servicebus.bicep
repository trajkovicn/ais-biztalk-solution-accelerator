@description('Service Bus namespace name')
param namespaceName string

@description('Azure region')
param location string

@description('Premium messaging units (1, 2, 4, 8, or 16).')
@allowed([1, 2, 4, 8, 16])
param capacity int = 1

@description('Queue names to create')
param queueNames array = [
  'inbound'
  'outbound'
  'errors'
]

@description('Topic names to create (Premium SKU supports topics).')
param topicNames array = [
  'events'
  'notifications'
]

@description('Default subscription name created on each topic.')
param defaultSubscriptionName string = 'default'

@description('Subnet resource ID for VNet integration (leave empty to skip network rules).')
param subnetId string = ''

resource sb 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: capacity
  }
  properties: {}
}

// ── VNet network rule (only when a subnet ID is provided) ────
resource networkRuleSet 'Microsoft.ServiceBus/namespaces/networkRuleSets@2022-10-01-preview' = if (!empty(subnetId)) {
  parent: sb
  name: 'default'
  properties: {
    defaultAction: 'Deny'
    publicNetworkAccess: 'Enabled'
    virtualNetworkRules: [
      {
        subnet: {
          id: subnetId
        }
        ignoreMissingVnetServiceEndpoint: false
      }
    ]
    ipRules: []
  }
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

// ── Topics ───────────────────────────────────────────────────
resource topics 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [
  for t in topicNames: {
    parent: sb
    name: t
    properties: {
      maxSizeInMegabytes: 1024
      defaultMessageTimeToLive: 'P14D'
    }
  }
]

// ── Default subscription on each topic ───────────────────────
resource subscriptions 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = [
  for (t, i) in topicNames: {
    parent: topics[i]
    name: defaultSubscriptionName
    properties: {
      lockDuration: 'PT1M'
      defaultMessageTimeToLive: 'P14D'
      deadLetteringOnMessageExpiration: true
      maxDeliveryCount: 10
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

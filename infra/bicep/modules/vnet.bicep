@description('Virtual Network name')
param name string

@description('Azure region')
param location string

@description('VNet address space (CIDR)')
param addressPrefix string = '10.0.0.0/22'

@description('Deploy optional Azure DNS Private Resolver subnets')
param deployDnsResolverSubnets bool = false

@description('Subnet CIDR for Private Endpoints')
param snetPrivateEndpointsPrefix string = '10.0.0.0/27'

@description('Subnet CIDR for Service Bus workload')
param snetServiceBusPrefix string = '10.0.0.64/26'

@description('Subnet CIDR for Key Vault workload')
param snetKeyVaultPrefix string = '10.0.0.128/26'

@description('Subnet CIDR for Storage workload')
param snetStoragePrefix string = '10.0.0.192/26'

@description('Subnet CIDR for DNS Private Resolver inbound endpoint (optional)')
param snetDnsInboundPrefix string = '10.0.1.0/28'

@description('Subnet CIDR for DNS Private Resolver outbound endpoint (optional)')
param snetDnsOutboundPrefix string = '10.0.1.16/28'

var requiredSubnets = [
  {
    name: 'snet-private-endpoints'
    properties: {
      addressPrefix: snetPrivateEndpointsPrefix
      privateEndpointNetworkPolicies: 'Disabled'
    }
  }
  {
    name: 'snet-servicebus'
    properties: {
      addressPrefix: snetServiceBusPrefix
    }
  }
  {
    name: 'snet-keyvault'
    properties: {
      addressPrefix: snetKeyVaultPrefix
    }
  }
  {
    name: 'snet-storage'
    properties: {
      addressPrefix: snetStoragePrefix
    }
  }
]

var dnsSubnets = deployDnsResolverSubnets
  ? [
      {
        name: 'snet-dns-inbound'
        properties: {
          addressPrefix: snetDnsInboundPrefix
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: 'snet-dns-outbound'
        properties: {
          addressPrefix: snetDnsOutboundPrefix
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  : []

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: concat(requiredSubnets, dnsSubnets)
  }
}

output id string = vnet.id
output name string = vnet.name
output privateEndpointsSubnetId string = vnet.properties.subnets[0].id
output serviceBusSubnetId string = vnet.properties.subnets[1].id
output keyVaultSubnetId string = vnet.properties.subnets[2].id
output storageSubnetId string = vnet.properties.subnets[3].id

/* Parameters */
param location string = resourceGroup().location
param serviceBusQueuesNames array = []
param serviceBusTopicNames array = []
param keyVaultName string
param privateEndpoint bool = false
param vnetName string = ''
param vnetResourceGroup string = ''
param subNetName string = ''
param serviceBusName string
param privateEndpointName string = ''
param tags object 

var abbreviations = loadJsonContent('../abbreviations.json')

/* Resources */
// Service Bus Namespace
resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Service Bus Queues
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in serviceBusQueuesNames: {
  parent: serviceBus
  name: '${abbreviations.serviceBusNamespacesQueues}${queueName}'
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}]

// Service Bus Topics
resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' =  [for topic in serviceBusTopicNames: {
  parent: serviceBus
  name: '${abbreviations.serviceBusNamespacesTopics}${topic.topicName}'
  properties: {
  }
}]

// Service Bus Subscriptions
module serviceBusSubscription 'servicebus-subscriptions.bicep' =  [for topic in serviceBusTopicNames: {
  name: topic.topicName
  params: {
    topicName: '${abbreviations.serviceBusNamespacesTopics}${topic.topicName}'
    serviceBusName: serviceBusName
    subscriptions: topic.subscriptions
  }
  dependsOn:  [
    serviceBusTopic
  ]
}]

// Add RootManageSharedAccessKey to KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
  resource secret 'secrets' = {  
    name: 'ServiceBusSharedAccessKey'  
    properties: {
      value: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
    }
  }
}

// Create Private Endpoint
module privateEndPoint 'private-endpoint.bicep' = if (privateEndpoint == true) {
  name: 'privateEndPoint'
  scope: resourceGroup()
  params: {
    tags: tags
    serviceId: resourceId('Microsoft.ServiceBus/namespaces', serviceBusName)
    serviceType: 'namespace'
    subNetName: subNetName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateEndpointName: privateEndpointName
  }
  dependsOn: [
    serviceBus
  ]
}

/* Outputs */
output serviceBusNamespaceName string =  serviceBus.name
output serviceBusNamespaceFullQualifiedName string = '${serviceBus.name}.servicebus.windows.net'


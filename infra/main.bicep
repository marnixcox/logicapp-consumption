targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Application
@description('Application name to be used in components')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))
@description('Application resource group')
param resourceGroupName string = ''

// Service Bus 
@description('Name of queues to configure in the service bus')
param serviceBusQueuesNames array = []
@description('Name of topics to configure in the service bus')
param serviceBusTopicNames array = []
@description('Resource group where service bus is hosted')
param serviceBusResourceGroup string = 'rg-${environmentName}-${resourceToken}'
@description('Service Bus subscription')


// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param apiManagementName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param functionsName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param storageAccountName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${environmentName}-${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}-${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${environmentName}-${resourceToken}'
  }
}

// Keyvault
module keyVault './corelocal/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${resourceToken}'
    location: location
    tags: tags
    principalId: principalId 
  }
} 

// Service Bus instance
module serviceBus './app/servicebus.bicep' = {
  name: 'serviceBus'
  scope: rg
  params: {
    tags: tags
    serviceBusName: '${abbrs.serviceBusNamespaces}${resourceToken}-${environmentName}'
    location: location
    serviceBusQueuesNames: serviceBusQueuesNames
    serviceBusTopicNames: serviceBusTopicNames
    keyVaultName: keyVault.outputs.name
  }
  dependsOn: [
    keyVault
  ]
}

// Azure Blob Storage
module azureBlob './core/storage/storage-account.bicep' = {
 name: 'azureBlob'
  scope: rg
  params: {
 name: '${abbrs.storageStorageAccounts}${resourceToken}${environmentName}' 
   location: location
    allowBlobPublicAccess: true
  }
}

// Logic App Consumption
module logicapp './app/logicapp.bicep' = {
 name: 'logicapp'
 scope: rg
  params: {
    definition: json(loadTextContent('../src/workflows//test/test.json'))
    parameters: json(loadTextContent('../src/workflows/test/test.parameters.dev.json'))
     name: '${abbrs.logicWorkflows}${resourceToken}-${environmentName}' 
     tags: tags
     location: location
     azureblob: true
     storageAccountName: '${abbrs.storageStorageAccounts}${resourceToken}${environmentName}' 
     sharepointonline: true
     servicebus: true
     serviceBusName: '${abbrs.serviceBusNamespaces}${resourceToken}-${environmentName}'
  }
}

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

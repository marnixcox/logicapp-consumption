targetScope = 'subscription'

@minLength(1)
@maxLength(5)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
@allowed([
  'dev', 'tst', 'acc', 'prd'
])
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Application
@description('Application name to be used in components')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))
@description('Application resource group')
param resourceGroupName string = ''

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }

param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${resourceToken}-con-${environmentName}'
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
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}-con-${environmentName}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}-con-${environmentName}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}-con-${environmentName}'
  }
}

// Keyvault
module keyVault './avm/key-vault/vault/main.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}con${environmentName}'
    location: location
    sku: 'standard'
    enablePurgeProtection: false
    tags: tags
  }
}

var parameterEnvironmentMapping = environmentName == 'prd' ? 3
  : environmentName == 'acc' ? 2: environmentName == 'tst' ? 1 : 0

// Logic App SalesOrder
var laSalesorderParameters = [
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.dev.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.tst.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.acc.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.prd.json'))
]
module logicappla01 './app/logicapp.bicep' = {
  name: 'logicappla01'
  scope: rg
   params: {
     definition: json(loadTextContent('../src/workflows/SalesOrder/workflow.json'))
     parameters: laSalesorderParameters[parameterEnvironmentMapping]
      name: '${abbrs.logicWorkflows}${resourceToken}-con-salesorder-${environmentName}' 
      tags: tags
      location: location
      commondataservice: true
   }
 }

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

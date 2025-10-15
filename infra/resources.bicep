@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

var abbrs = loadJsonContent('./abbreviations.json')

// Monitor application with Azure Monitor
module monitoring './monitoring.bicep' = {
  name: '${deployment().name}-monitoring'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
  }
}

// KeyVault 
module keyvault './keyvault.bicep' = {
  name: '${deployment().name}-keyvault'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    environmentName: environmentName
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
  }
}

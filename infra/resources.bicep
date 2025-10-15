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
<<<<<<< HEAD
module keyvault './keyvault/keyvault.bicep' = {
=======
module keyvault './keyvault.bicep' = {
>>>>>>> 355390027c682bf8d853fd046992daa1c07fd6d7
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
<<<<<<< HEAD

// Logic App parameter file mapping
var parameterEnvironmentMapping = environmentName == 'prd'
  ? 3
  : environmentName == 'acc' ? 2 : environmentName == 'tst' ? 1 : 0

// Logic App parameters
var laSalesorderParameters = [
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.dev.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.tst.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.acc.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.prd.json'))
]

// Logic App definition
module logicappla01 './logicapp/consumption.bicep' = {
  name: 'logicappla01'
  params: {
    definition: json(loadTextContent('../src/workflows/SalesOrder/workflow.json'))
    parameters: laSalesorderParameters[parameterEnvironmentMapping]
    name: '${abbrs.logicWorkflows}${resourceToken}-salesorder-${environmentName}'
    tags: tags
    location: location
    commondataservice: true
  }
}
=======
>>>>>>> 355390027c682bf8d853fd046992daa1c07fd6d7

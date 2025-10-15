targetScope = 'subscription'

@minLength(1)
@maxLength(3)
@description('Name of the environment that can be used as part of naming resource convention')
@allowed([
  'dev', 'tst', 'acc', 'prd'
])
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Type of the user or app to assign application roles')
@allowed(['User', 'ServicePrincipal'])
param principalType string = 'User'

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

// The principal parameters are available for role assignments if needed in the future
// Currently, the application uses managed identity for secure access

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceToken}-${environmentName}'
  location: location
  tags: tags
}

<<<<<<< HEAD
// Deploy all resources into the resource group
=======
>>>>>>> 355390027c682bf8d853fd046992daa1c07fd6d7
module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    environmentName: environmentName
    resourceToken: resourceToken
  }
}

<<<<<<< HEAD
=======
var abbrs = loadJsonContent('./abbreviations.json')

// Logic App parameter file mapping
var parameterEnvironmentMapping = environmentName == 'prd' ? 3
  : environmentName == 'acc' ? 2: environmentName == 'tst' ? 1 : 0

// Logic App parameters
var laSalesorderParameters = [
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.dev.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.tst.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.acc.json'))
  json(loadTextContent('../src/workflows/SalesOrder/workflow.parameters.prd.json'))
]

// Logic App definition
module logicappla01 './logicapp.bicep' = {
  name: 'logicappla01'
  scope: rg
   params: {
     definition: json(loadTextContent('../src/workflows/SalesOrder/workflow.json'))
     parameters: laSalesorderParameters[parameterEnvironmentMapping]
      name: '${abbrs.logicWorkflows}${resourceToken}-salesorder-${environmentName}' 
      tags: tags
      location: location
      commondataservice: true
   }
 }

>>>>>>> 355390027c682bf8d853fd046992daa1c07fd6d7
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

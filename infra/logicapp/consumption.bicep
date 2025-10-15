
@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Logic App name')
param name string

@description('Logic App definition')
param definition object

@description('Logic App parameters')
param parameters object

@description('Create office365 connection')
param office365 bool = false

@description('Create sharepointonline connection')
param sharepointonline bool = false

@description('Create azureblob connection')
param azureblob bool = false

@description('Create commondataservice connection')
param commondataservice bool = false

@description('Create sql connection')
param sql bool = false

@description('Create servicebus connection')
param servicebus bool = false

@description('Create servicebus connection')
param serviceBusName string = ''

// Logic App
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'workflows' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: definition.definition
    parameters: union(parameters.parameters, serviceBusParameters, office365Parameters, azureblobParameters, sharepointonlineParameters, commondataserviceParameters, sqlParameters) 
  }
} 

// office365
resource office365Connection 'Microsoft.Web/connections@2016-06-01' = if (office365)  {
  name: 'office365'
  location: location
  properties: {
    displayName: 'office365'
    api: {
      description: 'connect to office 365'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
    }
    parameterValues: {
    }
  }
}

var office365Parameters = office365 ? {
  '$connections': {
    value: {
      office365: {
        connectionId: office365Connection.id
        connectionName: office365Connection.name
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
      }
    }
  }
} : {}

// sql
resource sqlConnection 'Microsoft.Web/connections@2016-06-01' = if (sql)  {
  name: 'sql'
  location: location
  properties: {
    displayName: 'sql'
    api: {
      description: 'connect to sql'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
    }
    parameterValues: {
    }
  }
}

var sqlParameters = sql ? {
  '$connections': {
    value: {
      sql: {
        connectionId: sqlConnection.id
        connectionName: sqlConnection.name
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
      }
    }
  }
} : {}

// common data service
resource commondataserviceConnection 'Microsoft.Web/connections@2016-06-01' = if (commondataservice)  {
  name: 'commondataservice'
  location: location
  properties: {
    displayName: 'commondataservice'
    api: {
      description: 'connect to commondataservice'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/commondataservice'
    }
    parameterValues: {
    }
  }
}

var commondataserviceParameters = commondataservice ? {
  '$connections': {
    value: {
      commondataservice: {
        connectionId: commondataserviceConnection.id
        connectionName: commondataserviceConnection.name
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/commondataservice'
      }
    }
  }
} : {}

// sharepointonline
resource sharepointonlineConnection 'Microsoft.Web/connections@2016-06-01' = if (sharepointonline)  {
  name: 'sharepointonline'
  location: location
  properties: {
    displayName: 'sharepointonline'
    api: {
      description: 'connect to sharepointonline'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sharepointonline'
    }
    parameterValues: {
    }
  }
}

var sharepointonlineParameters = sharepointonline ? {
  '$connections': {
    value: {
      office365: {
        connectionId: sharepointonlineConnection.id
        connectionName: sharepointonlineConnection.name
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sharepointonline'
      }
    }
  }
} : {}

// azureblob
resource azureblobconnection 'Microsoft.Web/connections@2018-07-01-preview' = if (azureblob) {
  name: 'azureblob'
  location: location
  kind: 'V1'
  properties: {   
    displayName: 'azureblob'
    api: {
      description: 'Azure Blob Storage'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
    }  
    parameterValueSet: {
      name: 'managedIdentityAuth'
    }  
  }
}

var azureblobParameters = azureblob ? {
  '$connections': {
    value: {
      azureblob: {
        connectionId: azureblobconnection.id
        connectionName: azureblobconnection.name
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
        connectionProperties: {
          authentication: {
            type: 'ManagedServiceIdentity'
          }
        }
      }
    }
  }
} : {}

// service bus
resource servicebusConnection 'Microsoft.Web/connections@2018-07-01-preview' = if (servicebus) {
  name: 'servicebus'
  location: location
  kind: 'V1'
  properties: {
    displayName: 'servicebus'
    api: {
      description: 'Connect to Azure Service Bus to send and receive messages.'
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
    }
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {
        namespaceEndpoint: {
          value: 'sb://${serviceBusName}.servicebus.windows.net'
        }
      } 
    }  
  }
}

var serviceBusParameters = servicebus ? {
  '$connections': {
    value: {
      servicebus: {
        connectionId: servicebusConnection.id
        connectionName: servicebusConnection.name
        connectionProperties: {
          authentication: {
            type: 'ManagedServiceIdentity'
          }
        }
        id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
      }
    }
  }
} : {} 

// Outputs for use by other modules
@description('Logic App managed identity')
output logicAppManagedIdentityId string = logicApp.identity.principalId

@description('Logic App name')
output logicAppName string = name

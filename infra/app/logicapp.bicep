/* Parameters */
param name string
param location string = resourceGroup().location
param tags object
param definition object
param parameters object
param office365 bool = false
param sharepointonline bool = false
param azureblob bool = false
param servicebus bool = false
param commondataservice bool = false
param sql bool = false
param serviceBusName string = ''
param storageAccountName string = ''

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

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing =  {
  name: storageAccountName
} 

var storageblobdataowner = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
resource azureblobRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if (azureblob) {
  name: guid('ra-logic-${storageblobdataowner}')
  scope: storage
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageblobdataowner) 
    principalId: logicApp.identity.principalId
  }
}

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

resource servicebusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing =  {
  name: serviceBusName
} 

var servicebusdataowner = '090c5cfd-751d-490a-894a-3ce6f1109419' //Azure Service Bus Data Owner
resource servicebusRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if (servicebus) {
  name: guid('ra-logic-${servicebusdataowner}')
  scope: servicebusNamespace
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', servicebusdataowner) 
    principalId: logicApp.identity.principalId
  }
}

/* Outputs */
output logicAppManagedIdentityId string = logicApp.identity.principalId
output logicAppName string = name

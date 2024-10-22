param name string
param location string = resourceGroup().location
param tags object 
param swagger object
param apiType string
param serviceUrl string

resource customApi 'Microsoft.Web/customApis@2016-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    apiType: apiType
    backendService: {
      serviceUrl: serviceUrl
    }
    swagger: swagger
  }
}

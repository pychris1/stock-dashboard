@description('Location for storage and key vault')
param locationEast string = 'eastus'

@description('Location for function app and static web app')
param locationWest string = 'westus2'

@secure()
param alphaVantageKey string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'stockdashstorage'
  location: locationEast
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'stock-dashboard-project'
  location: locationEast
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

resource apiKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'AlphaVantageKey'
  properties: { value: alphaVantageKey }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'stock-dashboard-plan'
  location: locationWest
  sku: { name: 'Y1', tier: 'Dynamic' }
  kind: 'linux'
  properties: { reserved: true }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'stock-dashboard-func'
  location: locationWest
  kind: 'functionapp,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'python' }
      ]
    }
    httpsOnly: true
  }
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: '6ecbb327-1ced-4853-bcbe-5a923e2b95c5'
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'stock-dashboard-ui'
  location: locationWest
  sku: { name: 'Free', tier: 'Free' }
  properties: {}
}

output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output keyVaultName string = keyVault.name

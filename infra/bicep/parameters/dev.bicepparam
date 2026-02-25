using '../main.bicep'

param ou = 'fin'
param biz = 'tax'
param app = 'btmigr'
param env = 'dev'
param regionCode = 'eus'
param instance = '001'

param deployIntegrationAccount = true
param integrationAccountSku = 'Basic'

// Object ID (GUID) of a user or group to administer secrets in the Key Vault
param keyVaultAdminObjectId = '00000000-0000-0000-0000-000000000000'

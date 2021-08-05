$azureAppId = (Get-AzADApplication -DisplayName 'ArkoseLabsConnectingToAzureAD').ApplicationId.ToString()
 $azureAppIdPasswordFilePath = '/Users/Bernard/.Azure/AzureAppPassword.txt'
 $azureAppCred = (New-Object System.Management.Automation.PSCredential $azureAppId, (Get-Content -Path $azureAppIdPasswordFilePath | ConvertTo-SecureString))
 $subscriptionId = '0892a31b-4124-4301-b110-2c415315be46'
 $tenantId = 'f0b24c76-8e72-47e9-b4c2-9022e59e0b5c'
 Connect-AzAccount -ServicePrincipal -SubscriptionId $subscriptionId -TenantId $tenantId -Credential $azureAppCred
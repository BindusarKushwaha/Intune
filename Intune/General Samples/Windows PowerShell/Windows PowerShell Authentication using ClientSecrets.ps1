Function Get-AuthToken
{
	<#
	.SYNOPSIS
	This function is used to get an auth_token for the Microsoft Graph API
	.DESCRIPTION
	The function authenticates with the Graph API Interface with client credentials to get an access_token for working with the REST API
	.EXAMPLE
	Authenticates you with the Graph API interface and creates the AuthHeader to use when invoking REST Requests
	.NOTES
	NAME: Get-AuthToken
	#>
	param(
		[Parameter(Mandatory=$true)]
		$TenantID,
		[Parameter(Mandatory=$true)]
		$ClientID,
		[Parameter(Mandatory=$true)]
		$ClientSecret
	)
	try{
		Write-Output "Defining parameters for Microsoft Graph access token retrieval"
		# Define parameters for Microsoft Graph access token retrieval
		$resource = "https://graph.microsoft.com"
		$authority = "https://login.microsoftonline.com/$TenantID"
		$tokenEndpointUri = "$authority/oauth2/token"

		Write-Output "Getting the access token using grant type client_credentials for Application Permissions"
		# Get the access token using grant type client_credentials for Application Permissions
		$content = "grant_type=client_credentials&client_id=$ClientID&client_secret=$ClientSecret&resource=$resource"
		$response = Invoke-RestMethod -Uri $tokenEndpointUri -Body $content -Method Post -UseBasicParsing
		Write-Output "Got new Access Token!"
		# If the accesstoken is valid then create the authentication header
		if($response.access_token){
			Write-Output "Creating header for Authorization token"
			# Creating header for Authorization token
			$authHeader = @{
				'Content-Type'='application/json'
				'Authorization'="Bearer " + $response.access_token
				'ExpiresOn'=$response.expires_on
			}
			return $authHeader
		}
		else{
			Write-Output "Authorization Access Token is null, check that the client_id and client_secret is correct..."
			break
		}
	}
	catch{
		Write-Output "Error occurred in Get-AuthToken function"
		FatalWebError -Exeption $_.Exception -Function "Get-AuthToken"
	}
}

try {
	Write-Output "Connecting to Azure account using managed identity"
	$connection = Connect-AzAccount -Identity
	Write-Output "Retrieving ClientSecret from Key Vault"
	$ClientSecret = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "ClientSecret" -AsPlainText
	Write-Output "Retrieving ClientID from Key Vault"
	$ClientID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "AppID" -AsPlainText
	Write-Output "Retrieving TenantID from Key Vault"
	$TenantID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "TenantID" -AsPlainText
	Write-Output "Retrieving StorageKey from Key Vault"
	$StorageKey = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "intuenbackupandrestore" -AsPlainText
}
catch {
	$errorMessage = $_
	Write-Output "Error occurred while retrieving secrets from Key Vault: $errorMessage"
	$ErrorActionPreference = "Stop"
}

Write-Output "Getting App Details to Authenticate"
$authToken = Get-AuthToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
$token =  ($authToken.Authorization |ConvertTo-SecureString -AsPlainText -Force)
Write-Output "Connecting to Microsoft Graph with Access Token"
Connect-MgGraph -AccessToken $token | Out-Null

Write-Output "Starting Intune backup"
# Perform the backup
$backupPath = Join-Path -Path $env:TEMP -ChildPath "IntuneBackup.zip"
Start-IntuneBackup -Path $backupPath

Write-Output "Uploading the backup to Azure Blob Storage"
# Upload the backup to Azure Blob Storage
$storageAccountName = "intunebackup1"
$storageAccountKey = $StorageKey
$containerName = "backups"

Write-Output "Creating a context for the storage account"
# Create a context for the storage account
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

Write-Output "Uploading the backup file to Azure Blob Storage"
# Upload the backup file
Set-AzStorageBlobContent -File $backupPath -Container $containerName -Blob "IntuneBackup.zip" -Context $context
Import-Module IntuneBackupAndRestore


try {
	Write-Output "Connecting to Azure account using managed identity"
	$connection = Connect-AzAccount -Identity
	Write-Output "Retrieving ClientSecret from Key Vault"
	$ClientSecret = (Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "ClientSecret" -AsPlainText).SecretValueText

	Write-Output "Retrieving ClientID from Key Vault"
	$ClientID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "AppID" -AsPlainText
	Write-Output "Retrieving TenantID from Key Vault"
	$TenantID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "TenantID" -AsPlainText
	Write-output "Retrieving Tenant from Key Vault"
	$tenant = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "Tenant" -AsPlainText

	Write-Output "Retrieving StorageKey from Key Vault"
	$StorageKey = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "intuenbackupandrestore" -AsPlainText
}
catch {
	$errorMessage = $_
	Write-Output "Error occurred while retrieving secrets from Key Vault: $errorMessage"
	$ErrorActionPreference = "Stop"
}



$authority = "https://login.windows.net/$tenant"
## Connect to Microsoft Graph using the new MgGraph module
Connect-MgGraph -ClientID $ClientID  -TenantId $TenantID -Authority $authority


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
Import-Module IntuneBackupAndRestore

try {
	Write-Output "Connecting to Azure account using managed identity"
	$connection = Connect-AzAccount -Identity
}
catch {
	Write-Output "Error occurred while connecting to Azure account: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Retrieving ClientSecret from Key Vault"
	$ClientSecret = (Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "ClientSecret" -AsPlainText).SecretValueText
}
catch {
	Write-Output "Error occurred while retrieving ClientSecret from Key Vault: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Retrieving ClientID from Key Vault"
	$ClientID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "AppID" -AsPlainText
}
catch {
	Write-Output "Error occurred while retrieving ClientID from Key Vault: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Retrieving TenantID from Key Vault"
	$TenantID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "TenantID" -AsPlainText
}
catch {
	Write-Output "Error occurred while retrieving TenantID from Key Vault: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-output "Retrieving Tenant from Key Vault"
	$tenant = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "Tenant" -AsPlainText
}
catch {
	Write-Output "Error occurred while retrieving Tenant from Key Vault: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Retrieving StorageKey from Key Vault"
	$StorageKey = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "intuenbackupandrestore" -AsPlainText
}
catch {
	Write-Output "Error occurred while retrieving StorageKey from Key Vault: $_"
	$ErrorActionPreference = "Stop"
}

$authority = "https://login.windows.net/$tenant"

try {
	Write-Output "Connecting to Microsoft Graph"
	Connect-MgGraph -Identity
}
catch {
	Write-Output "Error occurred while connecting to Microsoft Graph: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Starting Intune backup"
	$backupPath = Join-Path -Path $env:TEMP -ChildPath "IntuneBackup.zip"
	Write-Output "Backup path: $backupPath"
	Start-IntuneBackup -Path $backupPath
}
catch {
	Write-Output "Error occurred while performing Intune backup: $_"
	$ErrorActionPreference = "Stop"
}

try {
	Write-Output "Uploading the backup to Azure Blob Storage"
	$storageAccountName = "intunebackup1"
	$storageAccountKey = $StorageKey
	$containerName = "backups"

	Write-Output "Creating a context for the storage account"
	$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

	Write-Output "Uploading the backup file to Azure Blob Storage"
	$BackupResult=Set-AzStorageBlobContent -File $backupPath -Container $containerName -Blob "IntuneBackup.zip" -Context $context
	Write-Output "Backup uploaded successfully"
}
catch {
	Write-Output "Error occurred while uploading the backup to Azure Blob Storage: $_"
	$ErrorActionPreference = "Stop"
}


$devices = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
$devices1 = $devices.Content | ConvertFrom-Json
Write-Output $devices
Write-Output $devices1
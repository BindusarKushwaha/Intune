# Import the IntuneBackupAndRestore module
Import-Module IntuneBackupAndRestore

try {
    # Output message indicating connection to Azure account using managed identity
    Write-Output "Connecting to Azure account using managed identity"
    # Connect to Azure account using managed identity
    $connection = Connect-AzAccount -Identity
}
catch {
    # Output error message if connection to Azure account fails
    Write-Output "Error occurred while connecting to Azure account: $_"
    # Set error action preference to stop on error
    $ErrorActionPreference = "Stop"
}

try {
    # Output message indicating connection to Microsoft Graph
    Write-Output "Connecting to Microsoft Graph"
    # Connect to Microsoft Graph using managed identity
    Connect-MgGraph -Identity -ContextScope Process
}
catch {
    # Output error message if connection to Microsoft Graph fails
    Write-Output "Error occurred while connecting to Microsoft Graph: $_"
    # Set error action preference to stop on error
    $ErrorActionPreference = "Stop"
}

# Clear any existing errors
$Error.clear()
# Set global error action preference to silently continue on error
$global:ErrorActionPreference = "SilentlyContinue"

# Output message indicating start of Intune backup
Write-Output "Starting Intune backup"

# Get the current date in ddMMyyyy format
$date = get-date -format "ddMMyyyy"

# Create a temporary folder for the backup
$dir = $env:temp + "\intunebackup" + $date
$tempFolder = New-Item -Type Directory -Force -Path $dir

# Output the backup path and temporary folder path
Write-Output "Backup path: $dir"
Write-Output "TempFolder: $tempFolder"
# Define the location for the zip file
$ziplocation="$env:temp"+"\intunebackup$date.zip"
# Output the zip file location
Write-Output "Zip Location: $ziplocation"

# Output message indicating start of backup
Write-Output "Starting backup"
# Start the Intune backup and save it to the temporary folder
Start-IntuneBackup -Path $tempFolder -ErrorAction "SilentlyContinue"

try {
    # Output message indicating listing of temporary folder contents
    Write-output "Listing tempfolder"
    # List the contents of the temporary folder recursively
    Get-ChildItem -Path "$tempFolder" -Recurse
    
    # Output message indicating start of compression
    Write-output "Compressing..."
    # Compress the temporary folder into a zip file
    Compress-Archive -Path $tempFolder -DestinationPath "$ziplocation"

    # Output message indicating upload of backup to Azure Blob Storage
    Write-Output "Uploading the backup to Azure Blob Storage"
    # Define the storage account name and container name
    $storageAccountName = "intunebackup1"
    $containerName = "backups"

    # Output message indicating creation of storage account context
    Write-Output "Creating a context for the storage account"
    # Create a context for the storage account
    $context = New-AzStorageContext -StorageAccountName $storageAccountName

    # Output message indicating upload of backup file to Azure Blob Storage
    Write-Output "Uploading the backup file to Azure Blob Storage"
    # Upload the zip file to the specified container in Azure Blob Storage
    Get-Item -Path $ziplocation | Set-AzStorageBlobContent -Container $containerName -Context $context -Force 
    # Output message indicating successful upload of backup
    Write-Output "Backup uploaded successfully"
}
catch {
    # Output error message if upload to Azure Blob Storage fails
    Write-Output "Error occurred while uploading the backup to Azure Blob Storage: $_"
    # Set error action preference to stop on error
    $ErrorActionPreference = "Stop"
}

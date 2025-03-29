Function Write-Host()
{
    <#
    .SYNOPSIS
    This function is used to configure the logging.
    .DESCRIPTION
    This function is used to configure the logging.
    .EXAMPLE
    Logging -Message "Starting installation" -severity 1 -component "Installation"
    Logging -Message "Something went wrong" -severity 2 -component "Installation"
    Logging -Message "BIG Error Message" -severity 3 -component "Installation"
    .NOTES
    NAME: Logging
    #>
    PARAM(
        [Parameter(Mandatory=$true)]$Message,
         #[String]$Path = "c:\Windows\Temp\Autopilot_Custom.log",
         [int]$severity=1,
         [string]$component="AskPIN"
         )

         $logdir="C:\Temp\Logs"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\BitLockerStartupPIN_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

# Prompt user for the device serial number
Write-Host -Message "Prompting user for the device serial number." -severity 1 -component "DeviceExitStrategy"
$SerialNumber = Read-Host -Prompt "Enter the Device Serial Number"

try {
    # Connect to Microsoft Graph API (requires proper permissions and authentication)
    Write-Host -Message "Connecting to Microsoft Graph API." -severity 1 -component "DeviceExitStrategy"
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All", "Directory.AccessAsUser.All"

    # Remove the device from Autopilot
    Write-Host -Message "Attempting to remove the device from Autopilot." -severity 1 -component "DeviceExitStrategy"
    $AutopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq '$SerialNumber'"
    if ($AutopilotDevice) {
        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $AutopilotDevice.Id
        Write-Host -Message "Device removed from Autopilot." -severity 1 -component "DeviceExitStrategy"
    } else {
        Write-Host -Message "Device not found in Autopilot." -severity 1 -component "DeviceExitStrategy"
    }

    # Find the device in Intune
    Write-Host -Message "Searching for the device in Intune." -severity 1 -component "DeviceExitStrategy"
    $Device = Get-MgDeviceManagementManagedDevice -Filter "serialNumber eq '$SerialNumber'"
    if ($Device) {
        # Trigger a wipe request
        Write-Host -Message "Triggering a wipe request for the device." -severity 1 -component "DeviceExitStrategy"
        Invoke-MgDeviceManagementManagedDeviceWipe -ManagedDeviceId $Device.Id -KeepEnrollmentData $false -KeepUserData $false -MacOsUnlockCode ""

        # Delete the device from Intune
        Write-Host -Message "Deleting the device from Intune." -severity 1 -component "DeviceExitStrategy"
        Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.Id
        Write-Host -Message "Device wiped and removed from Intune." -severity 1 -component "DeviceExitStrategy"
    } else {
        Write-Host -Message "Device not found in Intune." -severity 1 -component "DeviceExitStrategy"
    }

    # Find the device in Entra ID (Azure AD)
    Write-Host -Message "Searching for the device in Entra ID (Azure AD)." -severity 1 -component "DeviceExitStrategy"
    $EntraDevice = Get-MgDevice -Filter "deviceId eq '$SerialNumber'"
    if ($EntraDevice) {
        # Delete the device from Entra ID
        Write-Host -Message "Deleting the device from Entra ID." -severity 1 -component "DeviceExitStrategy"
        Remove-MgDevice -DeviceId $EntraDevice.Id
        Write-Host -Message "Device removed from Entra ID." -severity 1 -component "DeviceExitStrategy"
    } else {
        Write-Host -Message "Device not found in Entra ID." -severity 1 -component "DeviceExitStrategy"
    }
} catch {
    Write-Host -Message "An error occurred: $_" -severity 2 -component "DeviceExitStrategy"
} finally {
    # Disconnect from Microsoft Graph
    Write-Host -Message "Disconnecting from Microsoft Graph API." -severity 1 -component "DeviceExitStrategy"
    Disconnect-MgGraph
}
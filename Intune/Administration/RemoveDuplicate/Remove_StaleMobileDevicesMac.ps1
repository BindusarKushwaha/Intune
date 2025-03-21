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
         [int]$severity=1,
         [string]$component="StaleMacDevices"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\StaleMacDevices_$StartTime.log"
        
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Remove_StaleRecordMac()
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Yes", "No")]
        $ShouldBeRemoved
         )

    $CurrentDate=Get-Date
    Write-Host "Today's date and time on record: $CurrentDate"

    $RefDate=$CurrentDate.AddDays(-60)
    Write-Host "Checking for devices older than $RefDate"

    $DaysRangeZ = Get-Date($RefDate) -format s
    $DaysRangeZ=$DaysRangeZ+"Z"


    Write-Host "Getting Information using Graph API"

    try {
        Connect-MgGraph -ErrorAction Stop| Out-Null
    }
    catch {
        Write-Host "$Error[0]"
        Exit 1
    }


    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=((lastSyncDateTime lt $DaysRangeZ) and (deviceType eq 'MacMDM') and (enrolledDateTime lt $DaysRangeZ))&`$select=id,deviceName,osVersion,lastSyncDateTime,ownerType,serialNumber,wiFiMacAddress,ethernetMacAddress,complianceState,userPrincipalName,enrolledDateTime,emailAddress,deviceType,manufacturer,model"


    $authToken = ""
    $authHeader = @{
            Authorization = "Bearer $authToken"
        }

    Write-Host "Initiating the Connection with Intune..."
    try {
        $dev = Invoke-RestMethod -Method Get -Uri $uri -Headers $authHeader -ErrorAction Stop
    }
    catch {
        Write-Host "$Error[0]"
        Exit 1
    }


    $Devices=$dev.value
    $devicesNextLink=$dev."@odata.nextlink"
    while($devicesNextLink -ne $null)
    {
        $dev=(Invoke-RestMethod -Uri $devicesNextLink -Headers $authHeader -Method Get)
        $devicesNextLink=$dev."@odata.nextLink"
        $Devices+=$dev.value
        Write-host $Devices.count
    }

    Write-host "Number of devices older than $RefDate"
    Write-host $Devices.count
    Write-Host " "

    If($($Devices.count) -gt 0)
    {
        Write-Host "Devices which are expected to be removed..."
        Foreach($Device in $devices)
        {
            Write-Host "$($device.id):$($device.DeviceName):$($device.osVersion):$($device.lastSyncDateTime):$($device.ownerType):$($device.serialNumber):$($device.wiFiMacAddress):$($device.ethernetMacAddress):$($device.complianceState):$($device.userPrincipalName):$($device.enrolledDateTime)"
            If($ShouldBeRemoved -eq "Yes")
            {
                Write-Host "Deleting above record from Intune..."
                try {
                    #Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$device.id" -Headers $authHeader -ErrorAction Stop
                }
                catch {
                    Write-Host "$Error[0]"
                    Exit 1
                }
            }
        }
    }
}

$Error.Clear()

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"
Write-Host "This will only check for Stale Mac devices..."

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = "This action will list the Mac machines which are stale. Do you want to delete those devices as well?"
$msgTitle = "Confirm Deletion"
$msgButton = 'YesNo'
$msgImage = 'Question'
$Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)

Write-Host "User selected $Result to delete the objects."

Remove_StaleRecordMac -ShouldBeRemoved $Result
Write-Host "====================ENding the Script $($MyInvocation.MyCommand.Name)"
Exit 0
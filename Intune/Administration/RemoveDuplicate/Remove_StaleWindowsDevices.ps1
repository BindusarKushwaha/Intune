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
         [string]$component="Main"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\DuplicateDevicesAndroid_$StartTime.log"
        
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 
}


Function Remove_DuplicateAndroidDevices()
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Yes", "No")]
        $ShouldBeRemoved
         )

    Write-Host "Getting Information using Graph API"

    try {
        Connect-MgGraph -ErrorAction Stop| Out-Null
    }
    catch {
        Write-Host "$Error[0]"
        Exit 1
    }

    $CurrentDate=Get-Date
    Write-Host "Today's date and time on record: $CurrentDate"

    $RefDate=$CurrentDate.AddDays(-30)
    Write-Host "Checking for devices older than $RefDate"

    $DaysRangeZ = Get-Date($RefDate) -format s
    $DaysRangeZ=$DaysRangeZ+"Z"

    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=((deviceType eq 'androidForWork') and (lastSyncDateTime lt $DaysRangeZ))"

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

    Write-Host "Grouping devices based on user name, manufacturer and model"
    $deviceGroups = $Devices | Where-Object { -not [String]::IsNullOrWhiteSpace($_.userID) } | Group-Object -Property userId, manufacturer, model

    Write-Host "Identifying objects with more than one entries"
    $duplicatedDevices = $deviceGroups | Where-Object {$_.Count -gt 1 }

    If($duplicatedDevices -eq $null)
    {
        Write-Host "No Duplicate Record Found... Great Job!!!"
    }
    Else
    {
        Write-Host "Duplicate Devices are: $($duplicatedDevices.group.deviceName)" -severity 2
    }




    Write-Host "Checking records which can be deleted..."
    foreach($duplicatedDevice in $duplicatedDevices)
    {
        Write-Host "Working on : $($duplicatedDevice.group.deviceName)"

        #$newestDevice = $duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
        foreach($oldDevice in ($duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1)) 
        {
            Write-Host "$($oldDevice.id):$($oldDevice.DeviceName):$($oldDevice.osVersion):$($oldDevice.lastSyncDateTime):$($oldDevice.ownerType):$($oldDevice.model):$($oldDevice.manufacturer):$($oldDevice.userPrincipalName)"
            
            if(($oldDevice.lastSyncDateTime -lt $DaysRangeZ) -and ($ShouldBeRemoved -eq "Yes"))
            {
                Write-host "Machine: $($oldDevice.managedDeviceName) will be deleted."

                try {
                    #Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($oldDevice.id)" -Headers $authHeader -ErrorAction Stop
                }
                catch {
                    Write-Host "$Error[0]"
                }

            }
            else
            {
                Write-Host "Machine: $($oldDevice.managedDeviceName) will NOT be deleted."
            }
        }
    }
}

$Error.Clear()

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"
Write-Host "This will only check for Duplicate Android devices..."

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = "This action will list duplicate Android Devices. Do you want to delete those devices as well?"
$msgTitle = "Confirm Deletion"
$msgButton = 'YesNo'
$msgImage = 'Question'
$Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)

Write-Host "User selected $Result to delete the objects."

Remove_DuplicateAndroidDevices -ShouldBeRemoved $Result

Write-Host "====================ENding the Script $($MyInvocation.MyCommand.Name)"
Exit 0
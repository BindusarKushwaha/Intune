<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>

<#PSScriptInfo
 
.VERSION 1.0
 
.GUID
 
.AUTHOR Bindusar Kushwaha
 
.COMPANYNAME Microsoft
 
.COPYRIGHT
 
.TAGS
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
To remove Duplicate devices from Intune for Mac machines.
#>

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
         [string]$component="DuplicateMac"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
           $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\DuplicateRecordMac_$StartTime.log"
        
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Remove-MacDuplicate()
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Yes", "No")]
        $ShouldBeRemoved
         )

    $ImpactedDevices=0
    $CurrentDate=Get-Date
    Write-Host "Today's date and time on record: $CurrentDate"

    $RefDate=$CurrentDate.AddDays(-30)
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


    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=(deviceType eq 'MacMDM')"


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


    Write-Host "Grouping devices based on serial number"
    $deviceGroups = $devices | Where-Object { -not [String]::IsNullOrWhiteSpace($_.serialNumber) } | Group-Object -Property serialNumber

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
        Write-Host "Working on : $($duplicatedDevice.group.deviceName) with Serial Number $($duplicatedDevice.group.serialNumber)"

        #$newestDevice = $duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
        foreach($oldDevice in ($duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1)) #dont forget to add skip1
        {
            $ImpactedDevices+=$ImpactedDevices+1
            if(($oldDevice.lastSyncDateTime -lt $DaysRangeZ) -and ($ShouldBeRemoved -eq "Yes"))
            {
                    Write-host "Machine: $($oldDevice.managedDeviceName) will be deleted"
                    #Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/`$oldDevice.id" -Headers $authHeader -ErrorAction Stop
            }
            else
            {
                Write-Host "Machine: $($oldDevice.managedDeviceName) will NOT be deleted."
            }
        }
    }
    Write-Host "Impacted devices are $ImpactedDevices"
}


$Error.Clear()

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"
Write-Host "This will only check for Duplicate Mac devices..."

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = "This action will list Mac machines which are duplicate. Do you want to delete those devices as well?"
$msgTitle = "Confirm Deletion"
$msgButton = 'YesNo'
$msgImage = 'Question'
$Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)

Write-Host "User selected $Result to delete the objects."

Remove-MacDuplicate -ShouldBeRemoved $Result
Write-Host "====================ENding the Script $($MyInvocation.MyCommand.Name)"
Exit 0
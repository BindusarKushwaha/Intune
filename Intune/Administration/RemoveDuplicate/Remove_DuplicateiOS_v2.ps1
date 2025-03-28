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
         [string]$component="DuplicateiOS"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
           $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\DuplicateRecordIOS_$StartTime.log"
        
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Remove-iOSDuplicate()
{

    $CurrentDate=Get-Date
    Write-Host "Today's date and time on record: $CurrentDate"

    $RefDate=$CurrentDate.AddDays(-7)
    Write-Host "Checking for devices older than $RefDate"

    $DaysRangeZ = Get-Date($RefDate) -format s
    $DaysRangeZ=$DaysRangeZ+"Z"



    #Write-Host "Getting Information using Graph API"

    try {
        Connect-MgGraph -ErrorAction Stop| Out-Null
    }
    catch {
        Write-Host "$Error[0]"
        Exit 1
    }


    $uriUserID = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=((deviceType eq 'iPhone') or (deviceType eq 'iPad'))&`$select=serialNumber"

    $authToken = ""
    $authHeader = @{
        Authorization = "Bearer $authToken"
    }

    #Write-Host "Initiating the Connection with Intune..."
    try {
        $UsrsJSON = Invoke-RestMethod -Method Get -Uri $uriUserID -Headers $authHeader -ErrorAction Stop
    }
    catch {
        Write-Host "$Error[0]"
        Exit 1
    }

    #Write-host "Setting limiter to 0"
    $limiter=0

    $UsrIDs=$UsrsJSON.value
    $devicesNextLink=$UsrsJSON."@odata.nextlink"
    while($limiter -lt 2) #$devicesNextLink -ne $null)
    {
        $UsrsJSON=(Invoke-RestMethod -Uri $devicesNextLink -Headers $authHeader -Method Get)
        $devicesNextLink=$UsrsJSON."@odata.nextLink"
        $UsrIDs+=$UsrsJSON.value
        $limiter = $limiter+1
        #Write-host $UsrIDs.count
    }

    $UsrIDs = $UsrIDs | Where-Object { -not [String]::IsNullOrWhiteSpace($_.serialNumber) } | Sort-Object serialNumber -Unique
    Write-host "Total users in Scope: $($UsrIDs.Count)"
    $DeleteCount=0
    $Progress=0

    Foreach($usr in $UsrIDs.serialNumber)
    {
        $Progress=$Progress+1
        Write-host "Progress: $Progress"

        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=((serialNumber eq '$usr') and (deviceType eq 'iPhone') or (deviceType eq 'iPad'))&`$select=id,deviceName,osVersion,lastSyncDateTime,ownerType,serialNumber,wiFiMacAddress,ethernetMacAddress,complianceState,userPrincipalName,enrolledDateTime,emailAddress,deviceType,manufacturer,model"
        $DevJSON=Invoke-RestMethod -Method Get -Uri $uri -Headers $authHeader -ErrorAction Stop
        #Write-host $($DevJSON.value)
    
        $DevGroup=$DevJSON.value | Group-Object -Property serialNumber
        $duplicatedDevices = $DevGroup | Where-Object {$_.Count -gt 1 }

        foreach($duplicatedDevice in $duplicatedDevices)
        {
            foreach($oldDevices in ($duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1))
            {
                foreach($Device in $oldDevices)
                {
                    if($Device.lastSyncDateTime -lt $DaysRangeZ)
                    {
                        Try{
                            $DeleteCount = $DeleteCount +1
                            Write-host $DeleteCount
                            Write-Host "Duplicate and Eligible to Delete|$($device.DeviceName)|$($device.id)|$($device.lastSyncDateTime)|$($device.enrolledDateTime)|$($device.manufacturer)|$($device.model)" #-DeviceID "$($device.id)" -DeviceName "$($device.DeviceName)" -OSVersion "$($device.osVersion)" -LastSyncDateTime "$($device.lastSyncDateTime)" -OwnerType "$($device.ownerType)" -SerialNumber "$($device.serialNumber)" -WifiMacAddress "$($device.wiFiMacAddress)" -EthernetMacAddress "$($device.ethernetMacAddress)" -ComplianceState "$($device.complianceState)" -UPN "$($device.userPrincipalName)" -EnrolledDateTime "$($device.enrolledDateTime)" -emailAddress "$($device.emailAddress)" -Action "Deleting" -Component "Invoke Delete" -Severity 2
                            #Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($oldDevice.id)" -Headers $authHeader -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Host "$Error[0]" -Severity 3 -Component "Failed to Run Delete Graph Query" -Action "Exiting"
                        }
                    }
                    else
                    {
                        Write-Host "Duplicate but Not Eligible to Delete as SyncTime is in Range|$($device.DeviceName)|$($device.id)|$($device.lastSyncDateTime)|$($device.enrolledDateTime)|$($device.manufacturer)|$($device.model)" #-DeviceID "$($device.id)" -DeviceName "$($device.DeviceName)" -OSVersion "$($device.osVersion)" -LastSyncDateTime "$($device.lastSyncDateTime)" -OwnerType "$($device.ownerType)" -SerialNumber "$($device.serialNumber)" -WifiMacAddress "$($device.wiFiMacAddress)" -EthernetMacAddress "$($device.ethernetMacAddress)" -ComplianceState "$($device.complianceState)" -UPN "$($device.userPrincipalName)" -EnrolledDateTime "$($device.enrolledDateTime)" -emailAddress "$($device.emailAddress)" -Action "Not Deleting" -Component "Invoke Delete" -Severity 2
                    }
                }

            }
        }
    }
}

Remove-iOSDuplicate
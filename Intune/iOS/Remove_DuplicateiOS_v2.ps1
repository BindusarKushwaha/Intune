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

    $authToken = "eyJ0eXAiOiJKV1QiLCJub25jZSI6InpJUE5pYTYyYXZMYVhPMlNsalFGYjhWcnF2eWpoTTJDLUhRbWNmZHFrU0kiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyIsImtpZCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTAwMDAtYzAwMC0wMDAwMDAwMDAwMDAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9lMDMyZmFjYy0wYmYzLTRkMzktYTU3Ny0yMDEwMmU3MTRjZWYvIiwiaWF0IjoxNjg2Mjg5OTAzLCJuYmYiOjE2ODYyODk5MDMsImV4cCI6MTY4NjM3NjYwMywiYWNjdCI6MCwiYWNyIjoiMSIsImFpbyI6IkFWUUFxLzhUQUFBQXRpMlBuUVcyR1QwU20wZ09ROFBmMktDOHVTdWdvWUdyeG51R2pmczdSSWJiQVNKUHFJSnQzd1Q5YkhTYzdMaWcydU1pWEtJR1NUbUdCUmwzNkFUYi9vVVFJazdxcGVIMDAydUxlQ1JrNG40PSIsImFtciI6WyJwd2QiLCJtZmEiXSwiYXBwX2Rpc3BsYXluYW1lIjoiR3JhcGggRXhwbG9yZXIiLCJhcHBpZCI6ImRlOGJjOGI1LWQ5ZjktNDhiMS1hOGFkLWI3NDhkYTcyNTA2NCIsImFwcGlkYWNyIjoiMCIsImZhbWlseV9uYW1lIjoiS3VzaHdhaGEiLCJnaXZlbl9uYW1lIjoiQmluZHVzYXIiLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIyNDAxOjQ5MDA6MWM1YzozZDEyOjk5MmQ6N2NiZTphODBkOmUyNmEiLCJuYW1lIjoiQmluZHVzYXIiLCJvaWQiOiI2NWFiOWVmZi05N2FmLTRjMzktOWYwMS05NTJhMDM4NWI0ZWUiLCJwbGF0ZiI6IjMiLCJwdWlkIjoiMTAwMzIwMDE3MTRCMjM2OCIsInJoIjoiMC5BVVlBelBveTRQTUxPVTJsZHlBUUxuRk03d01BQUFBQUFBQUF3QUFBQUFBQUFBQkdBTzAuIiwic2NwIjoiQVBJQ29ubmVjdG9ycy5SZWFkLkFsbCBBUElDb25uZWN0b3JzLlJlYWRXcml0ZS5BbGwgQml0bG9ja2VyS2V5LlJlYWQuQWxsIEJpdGxvY2tlcktleS5SZWFkQmFzaWMuQWxsIENhbGVuZGFycy5SZWFkV3JpdGUgQ2hhdC5SZWFkIENoYXQuUmVhZEJhc2ljIENvbnRhY3RzLlJlYWRXcml0ZSBEZXZpY2UuUmVhZC5BbGwgRGV2aWNlTWFuYWdlbWVudEFwcHMuUmVhZC5BbGwgRGV2aWNlTWFuYWdlbWVudEFwcHMuUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50Q29uZmlndXJhdGlvbi5SZWFkLkFsbCBEZXZpY2VNYW5hZ2VtZW50Q29uZmlndXJhdGlvbi5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRNYW5hZ2VkRGV2aWNlcy5SZWFkLkFsbCBEZXZpY2VNYW5hZ2VtZW50TWFuYWdlZERldmljZXMuUmVhZFdyaXRlLkFsbCBEZXZpY2VNYW5hZ2VtZW50UkJBQy5SZWFkLkFsbCBEZXZpY2VNYW5hZ2VtZW50UkJBQy5SZWFkV3JpdGUuQWxsIERldmljZU1hbmFnZW1lbnRTZXJ2aWNlQ29uZmlnLlJlYWQuQWxsIERldmljZU1hbmFnZW1lbnRTZXJ2aWNlQ29uZmlnLlJlYWRXcml0ZS5BbGwgRGlyZWN0b3J5LkFjY2Vzc0FzVXNlci5BbGwgRGlyZWN0b3J5LlJlYWRXcml0ZS5BbGwgRGlyZWN0b3J5LldyaXRlLlJlc3RyaWN0ZWQgRmlsZXMuUmVhZFdyaXRlLkFsbCBHcm91cC5SZWFkV3JpdGUuQWxsIElkZW50aXR5Umlza0V2ZW50LlJlYWQuQWxsIE1haWwuUmVhZCBNYWlsLlJlYWRXcml0ZSBNYWlsYm94U2V0dGluZ3MuUmVhZFdyaXRlIE5vdGVzLlJlYWRXcml0ZS5BbGwgb3BlbmlkIFBlb3BsZS5SZWFkIFBsYWNlLlJlYWQgUHJlc2VuY2UuUmVhZCBQcmVzZW5jZS5SZWFkLkFsbCBQcmludGVyU2hhcmUuUmVhZEJhc2ljLkFsbCBQcmludEpvYi5DcmVhdGUgUHJpbnRKb2IuUmVhZEJhc2ljIHByb2ZpbGUgUmVwb3J0cy5SZWFkLkFsbCBTaXRlcy5SZWFkV3JpdGUuQWxsIFRhc2tzLlJlYWRXcml0ZSBVc2VyLlJlYWQgVXNlci5SZWFkQmFzaWMuQWxsIFVzZXIuUmVhZFdyaXRlIFVzZXIuUmVhZFdyaXRlLkFsbCBlbWFpbCIsInNpZ25pbl9zdGF0ZSI6WyJrbXNpIl0sInN1YiI6IkdNUGhPWDl5WHU4WXo2aDNZWFRnel8waVlaRGU2ZEJvRURxTmc1cDB1bjAiLCJ0ZW5hbnRfcmVnaW9uX3Njb3BlIjoiTkEiLCJ0aWQiOiJlMDMyZmFjYy0wYmYzLTRkMzktYTU3Ny0yMDEwMmU3MTRjZWYiLCJ1bmlxdWVfbmFtZSI6IkJpbmR1c2FyQGJpbmxhYnMuaW4iLCJ1cG4iOiJCaW5kdXNhckBiaW5sYWJzLmluIiwidXRpIjoiRHpMUzkxUFFiVUNLRF9qT25MdENBQSIsInZlciI6IjEuMCIsIndpZHMiOlsiOWYwNjIwNGQtNzNjMS00ZDRjLTg4MGEtNmVkYjkwNjA2ZmQ4IiwiNjJlOTAzOTQtNjlmNS00MjM3LTkxOTAtMDEyMTc3MTQ1ZTEwIiwiYjc5ZmJmNGQtM2VmOS00Njg5LTgxNDMtNzZiMTk0ZTg1NTA5Il0sInhtc19jYyI6WyJDUDEiXSwieG1zX3NzbSI6IjEiLCJ4bXNfc3QiOnsic3ViIjoiMFpXZXdIZUJvTno1ci1pSnpfZ0xuVTVrT2RqVzdJdnRjcHhtODFlZWhldyJ9LCJ4bXNfdGNkdCI6MTYyODQzOTUxNH0.G53jbPTHnMoPj5p9FZ3RCBvvGAnKK20OCDXvU30RRjxvA1IfjukMsFoIJhJqdffeXn3hRN_wWqXykXmUms8CVlrGMykt8UpepMjkLaKUqRlVtGs31Oy9SKEnNGex_PUT4vRw2gwq-_X1wfOzmF58UOQZV2IhDUpsMJtKSXRmgu0ISuZ_4TVAzYmyk8I3jZ3b7kqswMohs1uvxVAndGNnKhCfUzBN7-idjZy2nxlvYwNEoY65lifrHa34cYeN6TC0fUhnbvj6fc4iMTBJ4nTW1E8k4IBS9mx3M2H6lAAZ_AJC12nYVEuOiIcGFSo6zSFa_EVYPJpM8HIEe6NF1_POEw"
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
<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
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
         #[String]$Path = "c:\Windows\Temp\Autopilot_Custom.log",
         [int]$severity=1,
         [string]$component="DeleteMachineCert"
         )

         $logdir="C:\colt\Logs"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\Autopilot_Custom_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}
$scriptExitCode = 0
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
$aUser = $((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)
Write-Host "Running under: $([char]34)$aUser$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"
$realUser = $false
if($aUser -notlike "*\defaultuser0")
    {
    $realUser = $true
    Write-Host "ESP stage is over ..."
    }
    
$Error.Clear()
Write-Host "checking if its Right time to Delete the Machine Cert"
If((Get-Process -Name StartMenuExperienceHost -ErrorAction SilentlyContinue) -and $realUser)
{
    Write-Host "User is already landed on desktop... Proceeding further..."
    Write-Host "Checking Certificate issued to machine account by Internal Issuing CA2 v2"
    $Error.Clear()
    Try
    {
        $autopilotCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object{($_.Issuer -eq "CN=Internal Colt Issuing CA2 V2, DC=INTERNAL, DC=COLT, DC=NET") -and ($_.Subject -notlike "CN=$env:computername*")}
        If($autopilotCert -ne $null)
        {
            Write-Host "Found $($autopilotCert.count) Certificate(s) to delete..."
            Foreach($aCert in $autopilotCert)
                {
                Write-Host "Backing-up $($aCert.Thumbprint) Certificate..."
                Export-Certificate -Cert $aCert -FilePath "c:\colt\logs\Autopilot_Custom_$($aCert.Thumbprint).p7b" -ErrorAction SilentlyContinue
                Write-Host "Deleting $($aCert.Thumbprint) Certificate..."
                Remove-Item -Path "cert:\LocalMachine\My\$($aCert.thumbprint)" -Force -ErrorAction SilentlyContinue
                }
            #Get-ChildItem Cert:\LocalMachine\My | Where-Object{($_.Issuer -eq "CN=Internal Colt Issuing CA2 V2, DC=INTERNAL, DC=COLT, DC=NET") -and ($_.Subject -notlike "CN=$env:computername*")} | Remove-Item
        }
        Else
        {
            Write-Host "Did not find any certificate to delete... Exiting the Script..." -severity 2
            Write-Error "Did not find any certificate to delete... Exiting the Script..." -Category OperationStopped
            Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
            $scriptExitCode = -1
            Exit $scriptExitCode
        }
    }
    Catch
    {
        Write-Host "Failed to delete certificate(s)" - severity 3
        Write-Host $Error[0]
        Write-Error "Failed to delete certificate(s)" -Category OperationStopped
        Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
        $scriptExitCode = -1
        Exit $scriptExitCode
    }
    Write-Host "Ping Active Directory Certificate Services Request interface"
    $pingCA = certutil -ping
    if($Error.Count -gt 0)
        {
        Write-Host "AD CSR error" -severity 2
        Write-Host "Error $Error[0]" -severity 2
        $Error.Clear()
        }


    Write-Host "Restarting IME Service on this machine"
    Restart-Service -Name IntuneManagementExtension -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 20
    if($Error.Count -gt 0)
        {
        Write-Host "Failed to restart IntuneManagementExtension" -severity 2
        Write-Host "Error $Error[0]" -severity 2
        $Error.Clear()
        }

    Try
    {
        Write-Host "Triggering Sync PushLaunch..."
        Get-ScheduledTask | Where-Object{$_.TaskName -eq "PushLaunch"} | Start-ScheduledTask

        Write-Host "Triggering Sync Schedule to run OMADMClient by client..."
        Get-ScheduledTask | Where-Object{$_.TaskName -eq "Schedule to run OMADMClient by client"} | Start-ScheduledTask
    }
    catch
    {
        Write-Host "Failed to start task... Please logoff and log back in to verify..." -severity 2
        Write-Host "Error $Error[0]" -severity 2
        Write-Error "Error $Error[0]" -Category OperationStopped
        $scriptExitCode = -1
    }
}
Else
{
    Write-Host "Seems like its not the right time to start the script... Will try again later..." -severity 2
    Write-Error "Seems like its not the right time to start the script... Will try again later..." -Category OperationStopped
    $scriptExitCode = -1
}
Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
Exit $scriptExitCode
<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>
# 24-Sep-2021 Adrian 
#             added code to suppress output in folder creation
#             added -ErrorAction SilentlyContinue where action can fail
#             removed files we do not touch from being displayed on log
# 24-Sep-2021 Adrian
#             removed "failed" word form first message
# 28-Sep-2021 Adrian
#             added comment for future improvement
#             added -Category OperationStopped
# 29-Sep-2021 Adrian
#             added info about current user

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
         [string]$component="ReRunFailedScripts"
         )

         $logdir="C:\colt\Logs"        If(!(Test-Path $logdir))        {            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue        }
                $StartTime = Get-Date -Format "dd-MM-yyyy"        [String]$Path = "$Logdir\Autopilot_Custom_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 


}

Function Delete_Oldlogs()
{
    #Delete Old Log files.
    $logdir="C:\colt\Logs"
    Write-Host "Setting Logs dir to delete from $logdir"
    
    $LogFiles= Get-ChildItem "$logdir"

    Foreach($logfile in $LogFiles)
    {
        If(($logfile.name -match "Autopilot_Custom") -and ($logfile.CreationTime -lt $(Get-Date).AddMonths(-1)))
        {
         Write-Host "Checking file name $($logfile.name)"
           Try
            {
                Write-Host "this file $($logfile.name) should be deleted."
                Remove-Item "$Logdir\$logfile"
            }
            catch
            {
                Write-Host "failed to delete $($logfile.name)..."
                Write-Host "$error[0]"
                Write-Error "failed to delete the file... Please check the logs..."
            }
        }
    }
}

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
$Error.Clear()
Write-Host "Resetting the PowerShell Execution Attempts for scripts with more that 2 downloads."
$acnts=Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies"

foreach($acnt in $acnts)
{
    Write-Host "Checking under $($acnt.PSPath)"
    $Policies=Get-ChildItem -Path "$($acnt.PSPath)"
    foreach($Policy in $Policies)
    {
        if(((Get-ItemPropertyValue -Path "$($Policy.PSPath)" -Name Result) -eq "Failed") -and ((Get-ItemPropertyValue -Path "$($Policy.PSPath)" -Name DownloadCount) -gt 2))
        {
            Write-Host "Conditions for $($Policy.PSPath) are met."
            Write-Host "Script failed to run for more than 2 times... Resetting values..."
            
            Set-ItemProperty -Path "$($Policy.PSPath)" -Name DownloadCount -Value 0
            Set-ItemProperty -Path "$($Policy.PSPath)" -Name ErrorCode -Value 0
            Set-ItemProperty -Path "$($Policy.PSPath)" -Name Result -Value ""
            Set-ItemProperty -Path "$($Policy.PSPath)" -Name ResultDetails -Value ""
        }
    }
#the IntuneManagementExtension service should be restarted now to re-reun failed scripts we just changed ...
#Restart-Service -Name IntuneManagementExtension
}

Write-Host "Setting self to Failed state to re-run" -severity 2
Write-Error "Planned to re-run" -Category OperationStopped

Delete_Oldlogs

Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
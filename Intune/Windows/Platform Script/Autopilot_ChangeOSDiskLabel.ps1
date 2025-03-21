<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>
<#
22-Sep-2021 Adrian 
            added code to suppress output in folder creation
            added -ErrorAction SilentlyContinue where action can fail
            added protection for multiple changes
            added code for exception on changing the name
07-Oct-2021 Adrian
            added $scriptExitCode
            added info about current user
            added info about hostname
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
         [string]$component="ChangeOSDiskLabel"
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


$scriptExitCode = 0
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"

Write-Host "Identifying the OS Drive on this machine"
$OSDrive=(Get-CimInstance -ClassName Win32_OperatingSystem).SystemDrive

If($OSDrive -eq $null)
{
    Write-Host "Failed to find OS Drive"
    Write-Error "Failed to find OS Drive"
    Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
    $scriptExitCode = 1
    Exit $scriptExitCode
}

Write-Host "OS is installed on $OSDrive"
Write-Host "Updating the Label of $OSDrive to OSDisk"

$Error.Clear()

Try
{
    $Drive = (Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$OSDrive'")
    if($Drive.Label -ne 'OSDisk')
        {
        $Drive | Set-CimInstance -Property @{Label= 'OSDisk'}
        if($Error.Count -gt 0){throw}
        Write-Host "Successfully updated the Label OSDisk on $OSDrive"

        #Testing
        Write-Host "Reset Counter was called..."
        Write-host "ScriptGUID: $($MyInvocation.MyCommand.Name)"
        }
        else
            {
            Write-Host "Label OSDisk on $OSDrive already in place ..." -severity 2
            }
}
Catch
{
    Write-Host "Failed to update the OSDisk on $OSDrive due to exception"
    Write-Host $Error[0]
    Write-Error "Failed to update the OSDisk on $OSDrive due to exception"
    $scriptExitCode = 1
    $Error.Clear()
}

Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
Exit $scriptExitCode
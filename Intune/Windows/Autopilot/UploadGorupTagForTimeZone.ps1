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
         [string]$component="AddGroupTag"
         )

         $logdir="C:\colt\Logs"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\AddGroupTag_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}


if((Get-Module Microsoft.Graph.Intune) -eq $null)
{
    Write-Host "Intune Module is missing. Installing Microsoft.Graph.Intune"
    Install-Module -Name Microsoft.Graph.Intune
}


Write-Host "Connecting to MS Graph..."
Connect-MSGraph -ForceInteractive

$Resource = "deviceManagement/windowsAutopilotDeviceIdentities"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"

##### Grabbing all registered Autopilot devices
$APMachines = Invoke-MSGraphRequest -HttpMethod GET -Url $uri | Get-MSGraphAllPages
$Machines=Import-Csv -Path "C:\Temp\Tag.csv"


##### Below command will change the group tag on all devices in Autopilot
Foreach ($APMachine in $APMachines)
{
    #Write-Host "Checking AP Machine $($APMachine.serialNumber)"
    Foreach($machine in $Machines)
    {
        #Write-Host "Checking CSV Machine $($Machine.SerialNumber)"
        If(($APMachine.groupTag -eq "") -and ($machine.SerialNumber -eq $APMachine.serialNumber))
        {
            $NewGroupTag = "$($machine.GroupTag)"
            $JSONFile = @{"groupTag"="$($NewGroupTag)"}
            Invoke-MSGraphRequest -HttpMethod POST -Url https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($APMachine.id)/UpdateDeviceProperties -Content $JSONFile
            Write-Host "Updated GroupTag:$NewGroupTag for SerialNumber:$($APMachine.serialNumber)"
            $Flag=1
        }
    }
}
If($Flag -ne 1)
{
    Write-Host "Did not find anything to change... Exiting..."
}
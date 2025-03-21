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
The purpose of this script is to Start, Stop, Enable, Disable Any Service in bulk. By default, it is set to IntuneManagementExtension which is a SideCar for Intune.

#>

###########################################
######  Specify Service Name below  #######

# You can get a service name by running following powershell command.
# Get-Service | Format-Table -Property DisplayName, Name
# Once Name is identified from second column, you can copy and paste that name in below command. By replacing IntuneManagementExtension with your service name.
# Please make sure NOT to use Display Name column. This script only accepts Name (Second Column).

$ServiceName="IntuneManagementExtension", "AppInfo" 
$ServiceStatus="Running", "Stopped" #Can only accept "Paused","Stopped","Running"
$ServiceStartUpType= "Automatic", "Automatic" #Can only accept "Automatic","Boot","Disabled","Manual","System"

###########################################



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
         [string]$component="ServiceChange"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
           $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\ServiceChange_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Set_Service()
{
    Param(
        [Parameter(Mandatory=$True)]$ServiceName,
        [ValidateSet("Paused","Stopped","Running")]$Status="Running",
        [ValidateSet("Automatic","Boot","Disabled","Manual","System")]$StartupType=$null
    )

    $Error.Clear()

    Write-Host "Received Service Status change for $ServiceName"

    Try{

        If($StartupType -eq $null)
        {
            Write-Host "Startup Type is not provided"

            If((Get-Service -Name $ServiceName).Status -eq $Status)
            {
                Write-Host "Service $ServiceName is already in $Status Status"
            }
            Else
            {
                Try
                {
                    Write-Host "Setting Service $ServiceName to $Status Status"
                    Set-Service -Name $ServiceName -Status $Status
                    Write-Host "Successfully completed the task..."
                }
                Catch
                {
                    Write-Host "Failed to set service $ServiceName to $Status status due to following error."
                    Write-Host "$Error[0]"
                }
            }
        }
        Else
        {
            Write-Host "Startup Type is provided. Will Consider that as well"

            If(((Get-Service -Name $ServiceName).Status -eq $Status) -and (Get-Service -Name $ServiceName).StartType -eq $StartupType)
            {
                Write-Host "Service $ServiceName is already in $Status Status"
            }
            Else
            {
                Try
                {
                    Write-Host "Setting Service $ServiceName to $Status Status and StartupType to $StartupType"
                    Set-Service -Name $ServiceName -Status $Status -StartupType $StartupType
                    Write-Host "Successfully completed the task..."
                }
                Catch
                {
                    Write-Host "Failed to set service $ServiceName to $Status status and startup type $StartupType due to following error."
                    Write-Host "$Error[0]"
                }
            }
        }
    }

    Catch
    {
        Write-Host "Failed to complete the task due to following error"
        Write-Host "$Error[0]"
    }
}



$Error.Clear()

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"
Write-Host "Trying to start the service"



For($i=0; $i -lt $ServiceName.Count; $i++)
{
    Set_Service -ServiceName $ServiceName[$i] -Status $ServiceStatus[$i] -StartupType $ServiceStartUpType[$i]
}

Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"

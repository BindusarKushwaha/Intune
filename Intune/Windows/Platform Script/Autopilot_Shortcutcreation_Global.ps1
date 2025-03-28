﻿<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>
# 24-Sep-2021 Adrian 
#             added code to suppress output in folder creation
#             added -ErrorAction SilentlyContinue where action can fail
#             changed PasswordSafe install location

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
         [string]$component="ShortCutCreation_Global"
         )

         $logdir="C:\Colt\Logs"        If(!(Test-Path $logdir))        {            $null = New-Item -Path $logdir -ItemType Directory -Force-ErrorAction SilentlyContinue        }
                $StartTime = Get-Date -Format "dd-MM-yyyy"        [String]$Path = "$Logdir\Autopilot_Custom_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Create_Shortcut()
{
    PARAM
    (
        [Parameter(Mandatory=$true)]$Link,
        [Parameter(Mandatory=$true)]$Source
    )

    Write-Host "Creating Desktop shortcut $Link"
    Write-Host "Verifying the source location $Source"

    if(Test-Path "$Source")
    {
        If(Test-Path "$Link")
        {
            Write-Host "Shortcut is already created... Exiting" -severity 2
        }
        Else
        {
            $Error.Clear()
            Write-Host "$Source is valid location... Proceeding to create a shortcut for that."
            Try
            {
                $ws=new-object -comobject Wscript.shell
                $s = $ws.CreateShortcut("$Link")
                $s.TargetPath="$Source"
                $s.Save()
                Write-Host "Successfully created the shortcut."
            }
            Catch
            {
                Write-Host "Failed to create shortcut for $Source" -severity 3
                Write-Host "$Error[0]" -severity 3
                Write-Error "$Error[0]"
            }
        }
    }
    Else
    {
        Write-Host "The source path provided is Invalid." -severity 3
        Write-Error "The source path provided is Invalid."
    }
}

Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running under: $([char]34)$(whoami)$([char]34)"
Create_Shortcut -Link "C:\Users\Public\Desktop\Password Safe.lnk" -Source "C:\Program Files\Password Safe\pwsafe.exe"
Create_Shortcut -Link "C:\Users\Public\Desktop\Outlook 2016.lnk" -Source "C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE"
Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
$filesToFind =
    "npp.8.7.7.Installer.x64.exe", 
    "VSCodeUserSetup-x64-1.97.2.exe", 
    "MDEEClient-Adobe.log",
    "AADJoin.json",
    "300039.pdf"

<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>

<#PSScriptInfo
 
.VERSION 1.3
 
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
 
.SYNOPSIS
This PowerShell script searches for specific files across all available drives and deletes them if found. 
It logs the script's progress, errors, and actions to a log file for auditing and troubleshooting purposes.
#>

Function Write-Host()
{
    <#This function is used to configure the logging.
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
         [string]$component="DeleteFiles"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
           $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\DeleteFiles_$StartTime.log"
        
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

$Error.Clear()
$scriptExitCode = 0
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"

$foundFiles = @()

Try
{
    Write-Host "Getting drives..."
    $drives=Get-PSDrive -PSProvider FileSystem
}
Catch
{
    Write-Host "Error getting drives: $($_.Exception.Message)"
    Write-Host "Exiting script..." -severity 3 -component "GettingDrives"
    $scriptExitCode = 1
}

Write-Host "Found $($drives.Count) drives..."

Foreach($drive in $drives)
{
    Write-Host "Searching for files in $($drive.Root)"
    $foundFiles+=Get-ChildItem -Path "$($drive.Root)" -Recurse -Include $filesToFind -Depth 5 -ErrorAction SilentlyContinue   
}

# Output the found files
if ($foundFiles.Count -gt 0) 
{
    Write-Host "Found $($foundFiles.Count) files to delete..."

    foreach ($file in $foundFiles) 
    {
        Try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Host "Deleted file: $($file.FullName)"
        } 
        Catch 
        {
            Write-Host "Failed to delete file: $($file.FullName). Error: $($_.Exception.Message)" -severity 2 -component "DeleteFiles"
            Write-Host "Exiting script..." -severity 3 -component "DeleteFiles"
            $scriptExitCode = 1
        }
    }
    Write-Host "Files deleted successfully..."
} 
else 
{
    Write-Host "No files found..."
}
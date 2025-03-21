#App3

<#
.COPYRIGHT

Copyright (c) Microsoft Corporation. All rights reserved.

.SYNOPSIS 

This script is created to Set BITLocker PIN using Intune

AUTHOR
Bindusar Kushwaha
Microsoft Cloud Solution Architect
bikush@microsoft.com  


Version 2.2
Added a process to check if TPMPIN is already set. Then update pinchanged flag.

.EXAMPLE

.PARAMETER

#>

<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS 
#>

#######################
#Detection Logic
#
#ChangePIN.txt SHOULD BE present
#
#######################


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
         [string]$component="SetPIN"
         )

         $logdir="C:\TCS\Logs"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\BitLockerStartupPIN_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

$scriptExitCode = 0
$filePIN = "C:\TCS\Temp\IME\Logs\ChangePIN.txt"
$filePinChanged = "C:\TCS\Temp\IME\Logs\PINChanged.txt"
#PINDetection
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"


$volu=Get-BitLockerVolume -MountPoint 'C:'

<#If($volu.KeyProtector.keyprotectorType -contains "TpmPin")
{
    Write-Host "Device is already equiped with TPMPIN. Setting flag to not ask for PIN from user."
    New-Item -Path "C:\TCS\Temp\IME\Logs\" -ItemType File -Force -Name "PINChanged.txt"
}
#>

$localTPM = Get-Tpm -ErrorAction SilentlyContinue
if($localTPM.TpmPresent)
    {
    $localKeyprotectorType = 'TpmPin'
    $noTPMorPTT = $false
    Write-Host "TPM is present"
    }
    else
        {
        $localKeyprotectorType = 'Password'
        $noTPMorPTT = $true
        Write-Host "TPM is NOT present"
       }
Write-Host "TpmPresent=$($localTPM.TpmPresent) TpmReady=$($localTPM.TpmReady) TpmEnabled=$($localTPM.TpmEnabled) TpmActivated=$($localTPM.TpmActivated) TpmOwned=$($localTPM.TpmOwned) ManagedAuthLevel=$($localTPM.ManagedAuthLevel) AutoProvisioning=$($localTPM.AutoProvisioning)"
                    

Write-Host "Checking if ChangePIN file is there in IME"
If(Test-Path -Path $filePIN -PathType Leaf)
{
    Write-Host "User has Provided the PIN... Proceeding..."

    if($volu.encryptionPercentage -lt '100')
    {
        if($noTPMorPTT -and $volu.encryptionPercentage -eq '0')
        {
        Write-Host "Drive C: 0% Encrypted."
            $Error.Clear()
            Try
                {
                Write-Host "Reading Password from $((Get-Item($filePIN) -ErrorAction SilentlyContinue).CreationTime)"
                $PIN=Get-Content -Path $filePIN
                $SecureString = ConvertTo-SecureString "$PIN" -AsPlainText -Force
                Write-Host "Setting Password..."
                $volumes = Get-BitLockerVolume -ErrorAction Continue
                Foreach($aVol in $volumes)
                    { 
                    if((Add-BitLockerKeyProtector -MountPoint $aVol.MountPoint -Password $SecureString -PasswordProtector) -eq $null) {throw}
                    if((Enable-BitLocker -MountPoint $aVol.MountPoint -RecoveryPasswordProtector -SkipHardwareTest) -eq $null) {throw}
                    Write-Host "Password set for $([char]34)$aVol.MountPoint$([char]34)"
                    if(($aVol.MountPoint) -ne 'C:')
                        {
                        Enable-BitLockerAutoUnlock -MountPoint $aVol.MountPoint
                        Write-Host "Enable AutoUnlock for $([char]34)$aVol.MountPoint$([char]34)"
                        }
                    }
                $Error.Clear()
                }
            Catch
                {
                Write-Host "Deleting ChangePIN.txt as password does not meet the complexity requirements"
                try
                    {
                    Remove-Item -Path $filePIN -Force
                    }
                    Catch
                        {
                        Write-Host "Failed to delete the file changePIN $error[0]" -severity 3
                        Write-Error "Failed to delete the file ChangePIN" -Category OperationStopped
                        }
                Write-Host "Failed to Set Password due to Exception $Error[0]" -severity 3
                Write-Error "Failed to Set Password due to Exception $Error[0]" -Category OperationStopped
                Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
                $scriptExitCode = 1
                Return $scriptExitCode
                }
         Write-Host "Deleting ChangePIN.txt"
        try
            {
            Remove-Item -Path $filePIN -Force
            if($error.count -gt 0) {throw}
            }
        Catch
            {
            Write-Host "Failed to delete the file changePIN $error[0]" -severity 3
            Write-Error "Failed to delete the file ChangePIN" -Category OperationStopped
            $scriptExitCode = 0
            }
       }
        else
            {
            Write-Host "Encryption is at $($volu.encryptionPercentage)%. Will try again." -severity 2
            #Write-Error "Encryption is at $($volu.encryptionPercentage)%. Will try again." -Category OperationStopped
            $scriptExitCode = 1618
            }
    }
    else
    {
        Write-Host "Drive C: is 100% Encrypted."
        #if($volu.KeyProtector.KeyprotectorType -notcontains 'TpmPin' -and $volu.encryptionPercentage -eq '100')
        if($volu.KeyProtector.KeyprotectorType -notcontains $localKeyprotectorType)
            {
            Write-Host "PIN is NOT Set."
            $Error.Clear()
            Try
                {
                Write-Host "Reading PIN from $((Get-Item($filePIN) -ErrorAction SilentlyContinue).CreationTime)"
                $PIN=Get-Content -Path $filePIN
                $SecureString = ConvertTo-SecureString "$PIN" -AsPlainText -Force
                Write-Host "Setting PIN..."
                if($noTPMorPTT)
                        {
                        if((Add-BitLockerKeyProtector -MountPoint "C:" -Password $SecureString -PasswordProtector) -eq $null) {throw}
                        }
                        else
                            {
                            if((Add-BitLockerKeyProtector -MountPoint "C:" -Pin $SecureString -TPMandPinProtector) -eq $null) {throw}
                            }
                }
            Catch
                {
                Write-Host "Failed to Set PIN due to Exception $Error[0]" -severity 3
                Write-Error "Failed to Set PIN due to Exception $Error[0]" -Category OperationStopped
                Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
                $scriptExitCode = 1
                Return $scriptExitCode
                }
            }
            else
                {
                Write-Host "Different PIN/Password is Set. Clearing OLD one."
                $Error.Clear()
                Try
                    {
                    Write-Host "Clearing OLD PIN/Password..."
                    $TpmOldPinKeyProtector = $volu.KeyProtector | Where-Object {$PSItem.KeyProtectorType -eq $localKeyprotectorType}
                    if((Remove-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $TpmOldPinKeyProtector.KeyProtectorId) -eq $null) {throw}
                    Write-Host "Reading NEW PIN/Password from $((Get-Item($filePIN) -ErrorAction SilentlyContinue).CreationTime)"
                    $PIN=Get-Content -Path $filePIN
                    $SecureString = ConvertTo-SecureString "$PIN" -AsPlainText -Force
                    Write-Host "Setting NEW PIN/Password..."
                    if($noTPMorPTT)
                        {
                        if((Add-BitLockerKeyProtector -MountPoint "C:" -Password $SecureString -PasswordProtector) -eq $null) {throw}
                        }
                        else
                            {
                            if((Add-BitLockerKeyProtector -MountPoint "C:" -Pin $SecureString -TPMandPinProtector) -eq $null) {throw}
                            }
                    }
                Catch
                    {
                    Write-Host "Failed to Set New PIN due to Exception $Error[0]" -severity 3
                    Write-Error "Failed to Set New PIN due to Exception $Error[0]" -Category OperationStopped
                    Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
                    $scriptExitCode = 1618
                    Return $scriptExitCode
                    }
                }
        Write-Host "Deleting ChangePIN.txt"
        try
            {
            Remove-Item -Path $filePIN -Force
            if($error.count -gt 0) {throw}
            }
        Catch
            {
            Write-Host "Failed to delete the file changePIN $error[0]" -severity 3
            Write-Error "Failed to delete the file ChangePIN" -Category OperationStopped
            $scriptExitCode = 0
            }

        Write-Host "Deleting PINChanged.txt"
        try
            {
            Remove-Item -Path $filePinChanged -Force
            if($error.count -gt 0) {throw}
            }
        Catch
            {
            Write-Host "Failed to delete the file PINChanged $error[0]" -severity 3
            Write-Error "Failed to delete the file PINChanged" -Category OperationStopped
            $scriptExitCode = 0
            }
   }

}
Else
{
    #check if we can create and remove files in IME folder
    $createIMEFolder = $False
    $testPermFile = 'C:\TCS\Temp\IME\Logs\permissionTesting_SetPIN.txt'
    Try 
        { 
        if(Test-Path -Path $testPermFile -PathType Leaf)
        {
            Remove-Item $testPermFile -Force -ErrorAction SilentlyContinue
            if($error.count -gt 0)
            {
                Write-Host "Cannot remove old test file on IME folder ..." -severity 2
                throw
            }
            if((New-Item -Path "C:\TCS\Temp\IME\Logs\" -ItemType File -Force -Name "permissionTesting_SetPIN.txt") -eq $null) {trow}
        }
        else
        {
            if((New-Item -Path "C:\TCS\Temp\IME\Logs\" -ItemType File -Force -Name "permissionTesting_SetPIN.txt") -eq $null) {trow}
        }
        Remove-Item $testPermFile -Force -ErrorAction SilentlyContinue
        if($error.count -gt 0)
            {
            Write-Host "Cannot remove test file from IME folder ..." -severity 2
            throw 
            }

        $createIMEFolder = $True
        }
    Catch 
        {
        $error.clear()
        Write-Host "Not enough priviledges on IME folder ..." -severity 2
        } 

    Try
        {
        Write-Host "Creating a landmark for TPM/PTT chip..."
        if($noTPMorPTT)
            {                     
            if ((New-Item -Path "C:\TCS\Temp\IME\Logs\" -ItemType File -Force -Name "0.BitLocker") -eq $null) {throw}
            if(Test-Path -Path "C:\TCS\Temp\IME\Logs\1.BitLocker" -PathType Leaf)
                {
                Remove-Item "C:\TCS\Temp\IME\Logs\1.BitLocker" -Force -ErrorAction SilentlyContinue
                if($error.count -gt 0)
                    {
                    Write-Host "Cannot remove test file from IME folder ..." -severity 2
                    throw 
                    }
                }
            }
            else
                {
                if ((New-Item -Path "C:\TCS\Temp\IME\Logs\" -ItemType File -Force -Name "1.BitLocker") -eq $null) {throw}
                if(Test-Path -Path "C:\TCS\Temp\IME\Logs\0.BitLocker" -PathType Leaf)
                    {
                    Remove-Item "C:\TCS\Temp\IME\Logs\0.BitLocker" -Force -ErrorAction SilentlyContinue
                    if($error.count -gt 0)
                        {
                        Write-Host "Cannot remove test file from IME folder ..." -severity 2
                        throw 
                        }
                    }
                }
        }
        Catch
            {
            Write-Host "$Error[0]" -severity 3
            Write-Error "Cannot raise the flag for TPM/PTT chip ... Will try again later" -Category OperationStopped
            $scriptExitCode = 1
            }



    Write-Host "User has not updated the PIN... Will try again..." -severity 3
    Write-Error "User has not updated the PIN... Will try again..." -Category OperationStopped
    $scriptExitCode = 1618
}
Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
Exit $scriptExitCode
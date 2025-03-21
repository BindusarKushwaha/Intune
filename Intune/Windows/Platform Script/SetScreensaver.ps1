<# 

.SYNOPSIS
This script has been created to Deploy configure Wallpaper and screen saver on Intune Devices.

AUTHOR
Satyandra Vishwakarma 
Microsoft IGD Consultant 
SaVishwa@microsoft.com  
   
RELEASENOTES 
June 19, 2020  - VERSION 1.0 - Draft release - Satyandra Vishwakarma 

.DESCRIPTION

The scipt has below intended functions:
1) Copy  TCS_SS.SCR & ALLWallpaper.jpg from PS executed folder to C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\$Version
2) Update registry to set TCS_SS.SCR & ALLWallpaper.jpg path and settings
3) Capture logs under C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\TCS_Wallpaper_ScreenSaver_$StartTime.log failed events

Instructions:
1) Replace TCS_SS.SCR & ALLWallpaper.jpg with the desired Screensaver, wallpaper 
2) Update and Increment $version value, Update Screensaver activate period in $activateMinutes & TimeOut in $timeoutMinutes
3) Detection logic needs to be appended with Version mentioned in the script
4) If Version is "06302020" detection logic would be C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\06302020\TCS_SS.SCR (or ALLWallpaper.jpg)
5) If Version is "07312020" detection logic would be C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\07312020\TCS_SS.SCR (or ALLWallpaper.jpg)
6) Version logic above will avoid uninstallation of previous package for new deployment (Wallpaper & Screensaver rotation) 


DISCLAIMER 
The provided script is not supported under any Microsoft standard support program or service.
The script is provided AS IS without warranty of any kind. 
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
The entire risk arising out of the use or performance of the script and documentation remains with you. 
In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever 
(including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) 
arising out of the use of or inability to use the script or documentation, even if Microsoft has been advised of the possibility of such damages.

#>

#Set Log Variables
$ExecutionTime = Get-Date 
$StartTime = Get-Date $ExecutionTime -Format "dd-MM-yyyy"
$LogFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\TCS_Wallpaper_ScreenSaver_$StartTime.log"

#ScreenSaver time settings
$activateMinutes = "1"
$timeoutMinutes = "180"
#setting secured to "1" will require user to login again during screensaver
$secured = "1"

#Version for script
$Version = "12192020"
$Status = "C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver_Status_" + $Version + ".txt"
$LocalRepo = "C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\" + "$Version"

function Copy-file {
    $Source = $args[0]
    $Destination = $args[1]

    If (!(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force -ErrorAction SilentlyContinue
    } 
    Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction SilentlyContinue
}

function Set-ScreenSaver
{
    $path = $args[0]
    $active = $args[1]
    $timeout = $args[2]
    $Users = Get-ChildItem Registry::HKEY_USERS -ErrorAction SilentlyContinue 

    foreach ($user in $Users )
    {
        $RegPath = "Registry::$($user.name)\Control Panel\Desktop"
        if (Test-Path $RegPath)
        {
            try
            {
                Set-ItemProperty -Path $RegPath -Name ScreenSaveActive -Value $active 
                Set-ItemProperty -Path $RegPath -Name ScreenSaveTimeOut -Value $timeout 
                Set-ItemProperty -Path $RegPath -Name ScreenSaverIsSecure -Value $secured
                Set-ItemProperty -Path $RegPath -Name scrnsave.exe -Value $path           
            }
            Catch 
            {
                Add-Content -Path $LogFile -Value "Registry edit failed for ScreenSaver : $($_.Exception.Message)" 
                Rename-Item -Path $path -NewName "TCS_SS_RegFailed_" + $StartTime + ".SCR" -Force
            }
        }
    }
}

<#function Set-Wallpaper {
    $path = $args[0]
    $Users = Get-ChildItem Registry::HKEY_USERS -ErrorAction SilentlyContinue 

foreach ($user in $Users )
    {
    $RegPath = "Registry::$($user.name)\Control Panel\Desktop"
    
    if (Test-Path $RegPath)
    {
    try {
            Set-ItemProperty -Path $RegPath -Name wallpaper -Value $path
	        Set-ItemProperty -Path $RegPath -Name Wallpaperstyle -Value 0           
        }
   Catch 
        {
            Add-Content -Path $LogFile -Value "Registry edit failed for Wallpaper : $($_.Exception.Message)" 
            Rename-Item -Path $path -NewName "ALLWallpaper_RegFailed_" + $StartTime + ".jpg" -Force
        }
    }
    }
    
                       }
function Set-LockScreenWallpaper {
    
    $LockScreenImageValue = $args[0]
    $StatusValue = "1"

     try {
        $RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
        if (!(Test-Path $RegKeyPath))
            {
                New-Item -Path $RegKeyPath -Force | Out-Null
            }
        New-ItemProperty -Path $RegKeyPath -Name "LockScreenImageStatus" -Value $StatusValue -PropertyType DWORD -Force  | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name "LockScreenImagePath" -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name "LockScreenImageUrl" -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null     
        }
   Catch 
        {
            Add-Content -Path $LogFile -Value "Registry edit failed for LockScreenWallpaper : $($_.Exception.Message)"             
        }

                              }#>

#copy files to local storage C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\version
$files = Get-ChildItem $PSScriptRoot -Exclude *.ps1, *.bat
Foreach ($file in $files)
{
    Copy-file $file.FullName $LocalRepo
}

#setScreenSaver
$screenSaver =  "C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\" + "$Version" + "\TCS_SS.SCR"
if([System.IO.File]::Exists($screenSaver))
{
    Set-ScreenSaver $screenSaver $activateMinutes $timeoutMinutes
}
else
{
    Add-Content -Path $LogFile -Value "Could not find ScreenSaver file: $screenSaver "
}


<#set Wallpaper
$Wallpaper = "C:\ProgramData\TCS\TCS_Wallpaper_ScreenSaver\" + "$Version" + "\ALLWallpaper.jpg"

if([System.IO.File]::Exists($Wallpaper)) { 

Set-Wallpaper  $Wallpaper 
Set-LockScreenWallpaper $Wallpaper 

}
else {Add-Content -Path $LogFile -Value "Could not find Wallpaper file: $Wallpaper " }#>
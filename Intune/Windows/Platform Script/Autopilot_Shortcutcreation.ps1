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
         [string]$component="ShortCutCreation"
         )

         $logdir="$env:TEMP"        If(!(Test-Path $logdir))        {            New-Item -Path $logdir -ItemType Directory -Force        }
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
            }
        }
    }
    Else
    {
        Write-Host "The source path provided is Invalid." -severity 3
    }
}

Write-Host "==============Starting the Script=============="
Write-Host "Machine Name: $Env:COMPUTERNAME"
Create_Shortcut -Link "C:\Users\Public\Desktop\Password Safe.lnk" -Source "C:\Program Files (x86)\Password Safe\pwsafe.exe"
Create_Shortcut -Link "C:\Users\Public\Desktop\Outlook 2016.lnk" -Source "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
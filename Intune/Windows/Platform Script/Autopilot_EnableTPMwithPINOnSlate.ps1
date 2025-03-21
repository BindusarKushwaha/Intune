<#
Registry Hive	HKEY_LOCAL_MACHINE
Registry Path	Software\Policies\Microsoft\FVE
Value Name	OSEnablePrebootInputProtectorsOnSlates
Value Type	REG_DWORD
Enabled Value	1
Disabled Value	0
#>
# 24-Sep-2021 Adrian 
#             added code to suppress output in folder creation
#             added -ErrorAction SilentlyContinue where action can fail

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
         [string]$component="EnableTPMPINonSlate"
         )

         $logdir="C:\Colt\Logs"        If(!(Test-Path $logdir))        {            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue        }
                $StartTime = Get-Date -Format "dd-MM-yyyy"        [String]$Path = "$Logdir\Autopilot_Custom_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}
##### Registry Changes #####
Function Add_Reg()
{
    Param(
        [Parameter(Mandatory=$True)]$Path,
        [Parameter(Mandatory=$True)]$Name,
        [Parameter(Mandatory=$True)]$Value,
        [Parameter(Mandatory=$True)]$PropertyType
    )
    $ErrorActionPreference="SilentlyContinue"

    Write-Host "Initiating the function to add registry under $path"
    Write-Host "Reg name $Name will have value $Value"

    If(Test-Path -Path $Path)
    {
        Write-Host "Found Reg Path already there..."
        If(((Get-ItemProperty -Path "$Path").$Name) -eq "$Value")
        {
            Write-Host "Regsitry name is also correct with appropriate value..."
            Write-Host "Going to Main Script..."
        }
        Else
        {
            Write-Host "Error in finding the appropriate value" -severity 2
            If(((Get-ItemProperty -Path "$Path").$Name))
            {
                Write-Host "Reg value of $Name is not matching with $Value... Updating it..."
                Set-ItemProperty -Path "$Path" -Name "$Name" -Value "$Value"
            }
            Else
            {
                Write-Host "Reg does not exist... Creating one with name $Name and setting $Value"
                New-ItemProperty -Path "$Path" -Name "$Name" -PropertyType $PropertyType -Value "$Value"
            }
        }
    }
    else
    {
        Write-Host "Failed to find the path $Path" -severity 2
        Write-Host "Creating the new Path $Path"

        New-Item -Path "$Path" | Out-Null

        Write-Host "Starting the Function..."
        Add_Reg -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType
    }
}


Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running under: $([char]34)$(whoami)$([char]34)"
If(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\FVE)
{
    Add_Reg -Path "HKLM:\Software\Policies\Microsoft\FVE" -Name "OSEnablePrebootInputProtectorsOnSlates" -Value "1" -PropertyType "DWord"
}
Else
{
    Write-Host "HKLM:\SOFTWARE\Policies\Microsoft\FVE itself is missing... will try again..."
    Write-Error "HKLM:\SOFTWARE\Policies\Microsoft\FVE itself is missing... will try again..."
}
Write-Host "====================Ending the Script $($MyInvocation.MyCommand.Name)"
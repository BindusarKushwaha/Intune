##########################################
$username="Test1"
$computerName=$env:COMPUTERNAME
$Privilege="SeDenyBatchLogonRight"
##########################################

<#
Privilege	PrivilegeName
SeAssignPrimaryTokenPrivilege	Replace a process level token
SeAuditPrivilege	Generate security audits
SeBackupPrivilege	Back up files and directories
SeBatchLogonRight	Log on as a batch job
SeChangeNotifyPrivilege	Bypass traverse checking
SeCreateGlobalPrivilege	Create global objects
SeCreatePagefilePrivilege	Create a pagefile
SeCreatePermanentPrivilege	Create permanent shared objects
SeCreateSymbolicLinkPrivilege	Create symbolic links
SeCreateTokenPrivilege	Create a token object
SeDebugPrivilege	Debug programs
SeDelegateSessionUserImpersonatePrivilege	Obtain an impersonation token for another user in the same session
SeDenyBatchLogonRight	Deny log on as a batch job
SeDenyInteractiveLogonRight	Deny log on locally
SeDenyNetworkLogonRight	Deny access to this computer from the network
SeDenyRemoteInteractiveLogonRight	Deny log on through Remote Desktop Services
SeDenyServiceLogonRight	Deny log on as a service
SeEnableDelegationPrivilege	Enable computer and user accounts to be trusted for delegation
SeImpersonatePrivilege	Impersonate a client after authentication
SeIncreaseBasePriorityPrivilege	Increase scheduling priority
SeIncreaseQuotaPrivilege	Adjust memory quotas for a process
SeIncreaseWorkingSetPrivilege	Increase a process working set
SeInteractiveLogonRight	Allow log on locally
SeLoadDriverPrivilege	Load and unload device drivers
SeLockMemoryPrivilege	Lock pages in memory
SeMachineAccountPrivilege	Add workstations to domain
SeManageVolumePrivilege	Perform volume maintenance tasks
SeNetworkLogonRight	Access this computer from the network
SeProfileSingleProcessPrivilege	Profile single process
SeRelabelPrivilege	Modify an object label
SeRemoteInteractiveLogonRight	Allow log on through Remote Desktop Services
SeRemoteShutdownPrivilege	Force shutdown from a remote system
SeRestorePrivilege	Restore files and directories
SeSecurityPrivilege	Manage auditing and security log
SeServiceLogonRight	Log on as a service
SeShutdownPrivilege	Shut down the system
SeSyncAgentPrivilege	Synchronize directory service data
SeSystemEnvironmentPrivilege	Modify firmware environment values
SeSystemProfilePrivilege	Profile system performance
SeSystemtimePrivilege	Change the system time
SeTakeOwnershipPrivilege	Take ownership of files or other objects
SeTcbPrivilege	Act as part of the operating system
SeTimeZonePrivilege	Change the time zone
SeTrustedCredManAccessPrivilege	Access Credential Manager as a trusted caller
SeUndockPrivilege	Remove computer from docking station

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
         [int]$severity=1,
         [string]$component="Main"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\UserRightsAssignment_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Set-USerRight
{
    param(
    [string] $computerName = ("{0}.{1}" -f $env:COMPUTERNAME.ToLower(), $env:USERDNSDOMAIN.ToLower()),
    [string] $username = ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME),
    [Parameter(Mandatory=$true)]$Privilege
    )

    $ErrorActionPreference="stop"

    Write-Host "Removing Previous Temp Files if any..." -component Set-USerRight
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"

    if(Test-Path $import)
    {
        Remove-Item -Path $import -Force
    }

    $export = Join-Path -Path $tempPath -ChildPath "export.inf"

    if(Test-Path $export)
    {
        Remove-Item -Path $export -Force
    }
  
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"

    if(Test-Path $secedt)
    {
        Remove-Item -Path $secedt -Force
    }

    Write-Host "Trying to set the permissions as requested..."
    try
    {
        Write-Host "Granting $Privilege to user account $username on host $computerName"
        $sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
        secedit /export /cfg $export
        
        $sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
        foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$sid"))
        {
            Add-Content $import $line
        }

        secedit /import /db $secedt /cfg $import
        secedit /configure /db $secedt

        Write-Host "Triggering GP update..." -component Set-USerRight
        gpupdate /force

        Write-Host "Successfully updated the settings" -component Set-USerRight

        Write-Host "Removing the temp files which were created during the script execution" -component Set-USerRight
        Remove-Item -Path $import -Force
        Remove-Item -Path $export -Force
        Remove-Item -Path $secedt -Force
        Return 0
    }
    catch
    {
        Write-Host "Failed to grant $Privilege to user account $username on host $computerName"
        $error[0]
        Return 1
    }
}


$Error.Clear()
$scriptExitCode = 0
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"

Write-Host "Setting $Privilege to $username on $computerName"
$Res=Set-USerRight -username $username -computerName $computerName -Privilege $Privilege

Write-Host "Please check details below as well...
-------------------------------------------------------
$Res
-------------------------------------------------------"

Write-Host "====================ENding the Script $($MyInvocation.MyCommand.Name)"
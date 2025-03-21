<#
FileSystemAccessRule(String, FileSystemRights, AccessControlType)
FileSystemAccessRule(IdentityReference, FileSystemRights, InheritanceFlags, PropagationFlags, AccessControlType)
--------------------------------
InheritanceFlags
ContainerInherit	1	The ACE is inherited by child container objects.
None	0	The ACE is not inherited by child objects.
ObjectInherit	2	The ACE is inherited by child leaf objects.
--------------------------------
PropagationFlags 
InheritOnly	2	Specifies that the ACE is propagated only to child objects. This includes both container and leaf child objects.
None	0	Specifies that no inheritance flags are set.
NoPropagateInherit	1	Specifies that the ACE is not propagated to child objects.
#>

########################################
$Path="C:\a"
$User="Test1"
$Permission="Read"
#Possible values: "ListDirectory","ReadData","WriteData","CreateFiles","CreateDirectories","AppendData","ReadExtendedAttributes","WriteExtendedAttributes","Traverse","ExecuteFile","DeleteSubdirectoriesAndFiles","ReadAttributes","WriteAttributes","Write","Delete","ReadPermissions","Read","ReadAndExecute","Modify","ChangePermissions","TakeOwnership","Synchronize","FullControl"

$InheritanceFlag="ContainerInherit,ObjectInherit"            
#Possible Values: ContainerInherit, None, ObjectInherit
#https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags?view=net-7.0

$PropagationFlag="None"           
#Possible Values: InheritOnly, None, NoPropagateInherit
#https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags?view=net-7.0

$Type="Allow" 
#Possible Values: Allow, Deny
########################################
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
         [string]$component="Main"
         )

         $logdir="C:\Temp"

        If(!(Test-Path $logdir))
        {
            $null = New-Item -Path $logdir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        
        $StartTime = Get-Date -Format "dd-MM-yyyy"
        [String]$Path = "$Logdir\ChangePermission_$StartTime.log"
        
        $today=Get-Date -Format yyyyMMdd-HH
        $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
        $Date = Get-Date -Format "HH:mm:ss.fff"
        $Date2 = Get-Date -Format "MM-dd-yyyy"
        #$type =1

         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default 

}

Function Change_Permission
{
    PARAM(
        [Parameter(Mandatory=$true)]$Path,

         [Parameter(Mandatory=$true)]$User,

          [Parameter(Mandatory=$true)]
          [ValidateSet("ListDirectory","ReadData","WriteData","CreateFiles","CreateDirectories","AppendData","ReadExtendedAttributes","WriteExtendedAttributes","Traverse","ExecuteFile","DeleteSubdirectoriesAndFiles","ReadAttributes","WriteAttributes","Write","Delete","ReadPermissions","Read","ReadAndExecute","Modify","ChangePermissions","TakeOwnership","Synchronize","FullControl")]$Permission,

           $InheritanceFlag="ContainerInherit,ObjectInherit",
           #Possible Values: ContainerInherit, None, ObjectInherit
           
           $PropagationFlag="None",
           #Possible Values: InheritOnly, None, NoPropagateInherit
            [Parameter(Mandatory=$true)]
            [ValidateSet("Allow","Deny")]$Type
            )
    $ErrorActionPreference="Stop"

    Try
    {
        If(Test-Path $Path)
        {
            $ACL = Get-Acl -Path $Path -ErrorAction Stop
            $ACL_Rule = new-object System.Security.AccessControl.FileSystemAccessRule ($User, $Permission, $InheritanceFlag, $PropagationFlag, $Type)
    
            $ACL.SetAccessRule($ACL_Rule)
            Set-Acl -Path $Path -AclObject $ACL -ErrorAction Stop
            Write-Host "Successfully Applied the permission" -component Change_Permission
            $scriptExitCode = 0
        }
        Else
        {
            Write-Host "Path not found" -severity 2 -component Change_Permission
        }
    }
    Catch
    {
        Write-Host "Failed to apply permission. exiting the function..." -severity 3 -component Change_Permission
        Write-Host $Error[0] -severity 3 -component Change_Permission
        $scriptExitCode = 1
    }
}


$Error.Clear()
$scriptExitCode = 0
Write-Host "====================Starting the Script $($MyInvocation.MyCommand.Name)"
Write-Host "Running as: $([char]34)$(whoami)$([char]34)"
Write-Host "Running under: $([char]34)$((Get-WMIObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName)$([char]34)"
Write-Host "Running on: $([char]34)$(hostname)$([char]34)"

Write-Host "Triggering change permission for user $User at $Path to $Type $Permission"
Change_Permission -Path $Path -User $User -Permission $Permission -Type $Type

Write-Host "====================ENding the Script $($MyInvocation.MyCommand.Name)"
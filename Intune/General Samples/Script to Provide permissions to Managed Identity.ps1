
    [string]$managedIdentityName = "B-IntuneAuto"
    [string[]]$appPermissionsList = ("EntitlementManagement.ReadWrite.All", "DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All")


    # Connect to Microsoft Graph with high privileges to be able to set the required permissions
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"
# Get managed identity
$managedIdentity = Get-MgServicePrincipal -Filter "displayName eq '$managedIdentityName'"
# Get Microsoft Graph service principal to be able to "copy" the required permissions from there
$graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"  
# Set the required permissions for the managed identity
foreach ($appPermission in $appPermissionsList)
{
    $appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $appPermission -and $_.AllowedMemberTypes -contains "Application" }
    $params = @{
        ServicePrincipalId = $managedIdentity.Id
        PrincipalId = $managedIdentity.Id
        ResourceId = $graphServicePrincipal.Id
        AppRoleId = $appRole.Id
    }
    New-MgServicePrincipalAppRoleAssignment @params
}


$global:ErrorActionPreference = "SilentlyContinue"
#############################################
<#
.COPYRIGHT

Copyright (c) Microsoft Corporation. All rights reserved.

.SYNOPSIS 

This script is created to Automate the client machines completing autopilot to add in another group where policies which are not supposed to apply during autopilot are applied.

AUTHOR
Bindusar Kushwaha
bikush@Microsoft.com

Version 1.8


.EXAMPLE

.PARAMETER

#>

<#
DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a 
production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS"
WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We 
grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and 
distribute the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits,including attorneys’ fees,
that arise or result from the use or distribution of the Sample Code."  
DISCLAIMER ENDS 
#>
Function Get-AuthToken
{
	<#
	.SYNOPSIS
	This function is used to get an auth_token for the Microsoft Graph API
	.DESCRIPTION
	The function authenticates with the Graph API Interface with client credentials to get an access_token for working with the REST API
	.EXAMPLE
	Authenticates you with the Graph API interface and creates the AuthHeader to use when invoking REST Requests
	.NOTES
	NAME: Get-AuthToken
	#>
	param(
		[Parameter(Mandatory=$true)]
		$TenantID,
		[Parameter(Mandatory=$true)]
		$ClientID,
		[Parameter(Mandatory=$true)]
		$ClientSecret
	)
	try{
		# Define parameters for Microsoft Graph access token retrieval
		$resource = "https://graph.microsoft.com"
		$authority = "https://login.microsoftonline.com/$TenantID"
		$tokenEndpointUri = "$authority/oauth2/token"

		# Get the access token using grant type client_credentials for Application Permissions
		$content = "grant_type=client_credentials&client_id=$ClientID&client_secret=$ClientSecret&resource=$resource"
		$response = Invoke-RestMethod -Uri $tokenEndpointUri -Body $content -Method Post -UseBasicParsing
		Write-Host "Got new Access Token!" -severity 2
		# If the accesstoken is valid then create the authentication header
		if($response.access_token){
		# Creating header for Authorization token
		$authHeader = @{
			'Content-Type'='application/json'
			'Authorization'="Bearer " + $response.access_token
			'ExpiresOn'=$response.expires_on
			}
		return $authHeader
		}
		else{
			Write-host "Authorization Access Token is null, check that the client_id and client_secret is correct..." -severity 3
			break
		}
	}
	catch{
		FatalWebError -Exeption $_.Exception -Function "Get-AuthToken"
	}
}

try {
	$connection = Connect-AzAccount -Identity
    $ClientSecret = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "ClientSecret" -AsPlainText
    $ClientID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "AppID" -AsPlainText
    $TenantID = Get-AzKeyVaultSecret -VaultName "AppCreds" -Name "TenantID" -AsPlainText
    $groupId = Get-AutomationVariable -Name GroupID
}
catch {
    $errorMessage = $_
    Write-Output $errorMessage
    $ErrorActionPreference = "Stop"
}


#Get App Details to Authenticate

$authToken = Get-AuthToken -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret
$token =  ($authToken.Authorization |ConvertTo-SecureString -AsPlainText -Force)
Connect-MgGraph -AccessToken $token | Out-Null


# Filter Autopilot events for successful deployments in the last 24 hours
$RecentAutopilotEvents_URL = "https://graph.microsoft.com/beta/deviceManagement/autopilotEvents?`$filter=deploymentState eq 'success' and deploymentEndDateTime ge " + (Get-Date).AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$RecentAutopilotEvents_info = Invoke-WebRequest -Uri $RecentAutopilotEvents_URL -Method GET -Headers $authToken -UseBasicParsing
$Get_RecentAutopilotEvents = ($RecentAutopilotEvents_info.Content | ConvertFrom-Json).value

# Iterate through recent Autopilot events and fetch records based on DeviceID in Intune
foreach ($event in $Get_RecentAutopilotEvents) 
{
	$intuneDeviceId = $event.deviceId

	try 
	{
		$Intune_Device_URL = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$intuneDeviceId"
		$Intune_Device_info = Invoke-WebRequest -Uri $Intune_Device_URL -Method GET -Headers $authToken -UseBasicParsing
		$Intune_Device = $Intune_Device_info.Content | ConvertFrom-Json
	}
	catch 
	{
		Write-Output "Failed to retrieve device information for Intune Device ID $intuneDeviceId as it does not exists."
		$Intune_Device = $null
		Continue
	}

	if ($Intune_Device)
	{
		Write-Output "Found Intune Device ID: $intuneDeviceId mapping to EntraID: $($Intune_Device.azureADDeviceId)"
		$EntraID = $Intune_Device.azureADDeviceId

		# Get the device object ID from Azure AD
		$AzureAD_DeviceObject_URL = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$EntraID'"
		$AzureAD_DeviceObject_info = Invoke-WebRequest -Uri $AzureAD_DeviceObject_URL -Method GET -Headers $authToken -UseBasicParsing
		$AzureAD_DeviceObject = ($AzureAD_DeviceObject_info.Content | ConvertFrom-Json).value

		if ($AzureAD_DeviceObject) 
		{
			$ObjID = $AzureAD_DeviceObject.id
			Write-Output "Found device object information for EntraID: $EntraID with Object ID: $ObjID"
		} 
		else 
		{
			Write-Output "Failed to retrieve device object information for EntraID: $EntraID"
		}

		$addMemberUrl = "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$ref"
		$body = @{
			"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$ObjID"
		} | ConvertTo-Json

		try 
		{
			Invoke-RestMethod -Uri $addMemberUrl -Method Post -Headers $authToken -Body $body -ContentType "application/json"
			Write-Output "Device with ObjectID:$objID and EntraID:$entraID added to group $groupId successfully."
		} 
		catch 
		{
			Write-Output "Failed to add device with ObjID $ObjID to group $groupId. Error: $_"
		}
	} 
	else 
	{
		Write-Output "No Microsoft Entra Device ID found for Intune Device ID $intuneDeviceId"
	}
}
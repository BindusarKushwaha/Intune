<#

DISCLAIMER STARTS

This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code."

"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages"

DISCLAIMER ENDS

#>

<#PSScriptInfo

.VERSION 2.0

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

.RELEASENOTES

The purpose of this script is to capture customized information from client machine and upload it to Log analytics workspace.

#>

Function Write-Host()
{
    PARAM(
        [Parameter(Mandatory=$true)]$Message,
        $Info="Information"
         )
    [System.Diagnostics.EventLog]::WriteEntry("CompanyPortal", "$Message", $Info, 606)
}


Try
{
    Write-Host "Attempting to read the application data"
    $app=(Get-AppxPackage -AllUsers| where-object {$_.name -like "*CompanyPortal"} -ErrorAction Stop)
    Write-Host "Attempt Successful"
}
Catch
{
    Write-Host "failed to check application information due to $error[0]"
    return $error[0]
}


If($app.name)
{
    return $app.name
}
Else
{
    Write-Host "App not found..."
    return "Company Portal missing"
}
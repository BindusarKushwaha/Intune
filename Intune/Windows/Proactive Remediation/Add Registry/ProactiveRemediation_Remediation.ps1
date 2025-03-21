<# DISCLAIMER STARTS 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a #production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" #WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO #THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We #grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and #distribute the object code form of the Sample Code, provided that You agree:(i) to not use Our name, #logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to #include a valid copyright notice on Your software product in which the Sample Code is embedded; and #(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or #lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code." 
"This sample script is not supported under any Microsoft standard support program or service. The #sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied #warranties including, without limitation, any implied warranties of merchantability or of fitness for a #particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in #the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or #documentation, even if Microsoft has been advised of the possibility of such damages" 
DISCLAIMER ENDS #>

<#PSScriptInfo
 
.VERSION 1.0
 
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
The purpose of this script is to use in Remediation of registry.

If, following is se to true under object declaration of each object, it will be remediated, else, it will only be discovered.

RemediateForce= $True

The creation of registry object section must be copied and pasted from discovery Script as it is.

#>

############################################################
### TO BE USED IN BOTH DETECTION AND REMEDIATION ###########

$RegObject=@()

$RegObject += [PSCustomObject]@{
    RegPath     = "HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control"
    RegName = "Permission Required"
    RegType  = "DWord" #"String", ExpandString, Binary, DWord, MultiString, Qword, Unknown
    RegValue = 0
    RemediateForce= $True
}


$RegObject += [PSCustomObject]@{
    RegPath     = "HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control"
    RegName = "Permission Required2"
    RegType  = "String" #"String", ExpandString, Binary, DWord, MultiString, Qword, Unknown
    RegValue = 0
    RemediateForce= $True
}

$RegObject += [PSCustomObject]@{
    RegPath     = "HKLM:\SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control"
    RegName = "Permission Required3"
    RegType  = "Binary" #"String", ExpandString, Binary, DWord, MultiString, Qword, Unknown
    RegValue = 0
    RemediateForce= $True
}


############################################################


##Adding Loop for Multiple values


Foreach($Reg in $RegObject)
{
    try
    {

        if (Test-Path -Path $Reg.RegPath)
        {
            $RegCurrentValue = (Get-ItemProperty -Path $($Reg.RegPath)).$($Reg.RegName)

            if ($RegCurrentValue -ne $Reg.RegValue -and $RegCurrentValue -ne $null)
            {
                #Value Mismatch
                Set-ItemProperty -Path $Reg.RegPath -Name $Reg.RegName -Value $Reg.RegValue -Force -ErrorAction SilentlyContinue
            }
            ElseIf($RegCurrentValue -eq $null)
            {
                #Value Missing
                New-ItemProperty -Path $Reg.RegPath -Name $Reg.RegName -Value $Reg.RegValue -PropertyType $Reg.RegType -Force #-ErrorAction SilentlyContinue
                #created
            }
        }

        else
        {
            #Make sure the key exists
            New-Item $Reg.RegPath -Force | Out-Null
            #Remove-ItemProperty -Path $RegPath -Name $RegName -Force -ErrorAction SilentlyContinue
            New-ItemProperty -Path $Reg.RegPath -Name $Reg.RegName -Value $Reg.RegValue -PropertyType $Reg.RegType -Force #-ErrorAction SilentlyContinue
        }
    } 
    catch
    {
        $errMsg = $_.Exception.Message
        Write-Error $errMsg
        #exit 1
    }
}
#Filter domain will filter all user logon events based on your domain, set the domain to find users in that domain
$FilterDomain = "MICROSOFT.COM"
$StartTime = (Get-Date).AddDays(-30)

#Hash table to filter for logon events in security log
$FilterHash1 = @{
  Logname='Microsoft-Windows-BitLocker/BitLocker Management'
  ID='875'
  StartTime=$StartTime
}

$FilterHashError = @{
  Logname='Microsoft-Windows-BitLocker/BitLocker Management'
  Level='2'
  StartTime=$StartTime
}


#Get all logon events from last 7 days
$LogHistory = Get-WinEvent -FilterHashtable $FilterHash1 | Select TimeCreated,Properties

$LogHistory = Get-WinEvent -FilterHashtable $FilterHashError | Select TimeCreated,Properties


<#
845 > Key backed up to AAD
775 > Key protector was created
817 > Sealed a Key to TPM
768 > Encryption started
864 > Recovery pass rotation initiated
770 > Decryption Started
840 > Trusted WMI was added for volume


Failed
846 > Failed to backup in AAD
875 > Failed to recover key from AAD


#>
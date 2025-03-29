#####################################################################################################
# ALL THE SCRIPTS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED                   #
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR         #
# FITNESS FOR A PARTICULAR PURPOSE.                                                                 #
#                                                                                                   #
# This script is not supported under any Microsoft standard support program or service.             #
# The script is provided AS IS without warranty of any kind.                                        #
#                                                                                                   #
# Script Name : RenamePC.PS1                                                                        #
# Purpose     : The script is used to derive machine name from csv stored in container  + Hybrid Azure AD Join #
# Version     : v1.0                                                                                #
#####################################################################################################

cls

#Clear previosly stored variables
$vars = (Get-variable | Select-Object name).name
foreach($var in $vars)
    {
        Try
            {
                Clear-Variable -Name $var -Force -ErrorAction SilentlyContinue
            }
        catch
            {}
    }
function Decrypt-String($Encrypted, $Passphrase, $salt="SaltCrypto", $init="IV_Password") 
{ 
    # If the value in the Encrypted is a string, convert it to Base64 
    if($Encrypted -is [string]){ 
        $Encrypted = [Convert]::FromBase64String($Encrypted) 
       } 
 
    # Create a COM Object for RijndaelManaged Cryptography 
    $r = new-Object System.Security.Cryptography.RijndaelManaged
    # Convert the Passphrase to UTF8 Bytes 
    $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase) 
    # Convert the Salt to UTF Bytes 
    $salt = [Text.Encoding]::UTF8.GetBytes($salt) 
 
    # Create the Encryption Key using the passphrase, salt and SHA1 algorithm at 256 bits 
    $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8 
    # Create the Intersecting Vector Cryptology Hash with the init 
    $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15] 
 
 
    # Create a new Decryptor 
    $d = $r.CreateDecryptor() 
    # Create a New memory stream with the encrypted value. 
    $ms = new-Object IO.MemoryStream @(,$Encrypted) 
    # Read the new memory stream and read it in the cryptology stream 
    $cs = new-Object Security.Cryptography.CryptoStream $ms,$d,"Read" 
    # Read the new decrypted stream 
    $sr = new-Object IO.StreamReader $cs 
    # Return from the function the stream 
    Write-Output $sr.ReadToEnd() 
    # Stops the stream     
    $sr.Close() 
    # Stops the crypology stream 
    $cs.Close() 
    # Stops the memory stream 
    $ms.Close() 
    # Clears the RijndaelManaged Cryptology IV and Key 
    $r.Clear() 
} 

# Define Variables
$root = "C:\Windows\Temp"
$storageAccName = "storageaccount"  # "UPDATE STORAGE ACCOUNT NAME" #
$container = "Container name" # UPDATE CONTAINER NAME
$sas = "SAStoken"        
$destination = $root + "\" + $container 
$csvblob = "file.csv"  # UPDATE CSV
$domaincontroller = "domaincontroller" # UPDATE DC NAME

<###########################################################
$obj = (gwmi win32_ntdomain).domaincontrollername
$domaincontroller =  "$obj".Split("\\") | select -last 1
###########################################################>

#LogWrite function
Function Write-Log
{

    PARAM(
         [String]$Message,
         [String]$Path = "$root\RenamePC.log",
         [int]$severity,
         [string]$component
         )
         
         $TimeZoneBias = Get-CimInstance -Query "Select Bias from Win32_TimeZone"
         $Date = Get-Date -Format "HH:mm:ss.fff"
         $Date2 = Get-Date -Format "MM-dd-yyyy"
         $type =1
         
         "<![LOG[$Message]LOG]!><time=$([char]34)$date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $Path -Append -NoClobber -Encoding default
}

Write-Log -Message " " -severity 1 -component "Initialize Script"
Write-Log -Message "*****************************************" -severity 1 -component "Initialize Script"
Write-Log -Message "Script start time: $(get-date -format g)" -severity 1 -component "Initialize Script"
Write-Log -Message "*****************************************" -severity 1 -component "Initialize Script"
Write-Log -Message "Destination folder: $destination" -severity 1 -component "Read Variables"
Write-Log -Message "Storage Account: $storageAccName" -severity 1 -component "Read Variables"
Write-Log -Message "Container: $container " -severity 1 -component "Read Variables"

#########################
##### Test Folder
#########################
# Check if  folder exists, if not create, if yes, clear existing folders and files
Function Test-DestinationFolder
    {
         param
            (
                [Parameter(Mandatory)]
                [string] $folder
            )

        $testpath = test-path $folder
        If(($testpath -eq 'True'))
            {
                Write-Log -Message "Folder exists. Clearing existing files and folders" -severity 1 -component "Test-Folder"
                Remove-Item $folder -Recurse -Force -Confirm:$false
            }
        else
            {
                Write-Log -Message "Created $container folder" -severity 1 -component "Test-Folder"
                New-Item $folder -ItemType Directory -Force | Out-Null
            }
    }

#create folder
Test-DestinationFolder -folder $destination

################################
##### Function to Download blobs
################################
Function Get-AzureBlobFromAPI {
    param(
        [Parameter(Mandatory)]
        [string] $StorageAccountName,
        [Parameter(Mandatory)]
        [string] $Container,
        [Parameter(Mandatory)]
        [string] $Blob,
        [Parameter(Mandatory)]
        [string] $SASToken,
        [Parameter(Mandatory)]
        [string] $File
    )

    # documentation: https://docs.microsoft.com/en-us/azure/storage/common/storage-dotnet-shared-access-signature-part-1
    Invoke-WebRequest -Uri "https://$StorageAccountName.blob.core.windows.net/$Container/$($Blob)$($SASToken)" -OutFile $File

}

#############################
##### Invoke download of blob
#############################
sleep 1
try
    {
        Write-Log -Message "Downloading $($csvblob)..." -severity 1 -component "Downloadfiles"
        Get-AzureBlobFromAPI -StorageAccountName $storageAccName -Container $container -Blob $($csvblob) -SASToken $sas -File $($destination + "\" + $($csvblob))
        
    }
catch [system.exception]
{
    Write-Log -Message "ERROR: Could not download blob. $($_.exception.message)" -severity 3 -component "Downloadfiles"
}

Write-Log -Message "Download of blob content completed." -severity 1 -component "Downloadfiles"

####################
#Creating PSCredential object
####################

$encryptedUser = "enctrypted username"
$encryptedPassword = "encrypted password"

$pdecrypted = Decrypt-String $encryptedPassword "P_MyStrongPassword"
$udecrypted = Decrypt-String $encryptedUser "U_MyStrongPassword"
                                                        
$password = ConvertTo-SecureString $pdecrypted -AsPlainText -Force -Verbose

$PSCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($udecrypted, $password) -Verbose

#########################
##### Rename PC
#########################
Function RenamePC
    {
        PARAM (
                [String]$oldname,
                [String]$newname
              )

        try
            {
                Rename-Computer -ComputerName $oldname -NewName $newname -DomainCredential $PSCredential -ErrorAction Stop -ErrorVariable err
                Write-Log -Message "Renamed computer. Restart PC for changes to take effect" -severity 1 -component "RenamePC" 
            }
        catch [system.exception]
            {
                if($err.count -ne 0)
                    {
                        Write-Log -Message "ERROR: Could not rename computer with error '$($_.exception.message)'. Exiting" -severity 3 -component "RenamePC"
                        Copy-Item -Path "C:\Windows\Temp\RenameDevice_RB.Log" -Destination "C:\Windows\Temp\RenameDevice_RB_copy.Log"
                        Remove-item "C:\Windows\Temp\RenameDevice_RB.Log" -Force
                        Exit
                    }
            }
    }

####################
#Fetch serial number
####################
$serial = Get-WmiObject win32_bios | select -ExpandProperty serialnumber

################################
# Prereq - Check if in domain
################################
$ComputerInfo = Get-ComputerInfo
$InDomain = ($ComputerInfo).CsPartOfDomain
If($InDomain -eq "True")
    {
        Write-Log -Message "Machine joined to domain: $(($ComputerInfo).CsDomain)" -severity 1 -component "Prereq" 
    }
else
    {
        Write-Log -Message "Machine not joined to domain. Exiting" -severity 3 -component "Prereq" 
        Exit
    }

# Check if DC can be reached
try
    {
        $result = Test-ComputerSecureChannel -Server $domaincontroller 
        if($result -eq "True")
            {
                Write-Log -Message "Successful connection to domain controller: $($domaincontroller)" -severity 1 -component "Prereq"
            }
    }
catch [System.Exception]
    {
        Write-Log -Message "ERROR: Could not connect to domain controller $($domaincontroller) with error $($_.exception.message). Exiting" -severity 3 -component "Prereq"
        Exit
    }

#####################################
# Step 1 - Get Machine name from CSV
#####################################
$NewName = Import-Csv $destination\$csvblob | where{$_.TxtAssetSerialNo -eq $serial} | select -ExpandProperty txtMachineName
Write-Log -Message "New name derived from csv: $NewName" -severity 3 -component "RenamePC" 

# Step 2 - Rename PC
RenamePC -oldname $($env:COMPUTERNAME) -newname $NewName

#delete folder
Test-DestinationFolder -folder $destination

Exit 1000
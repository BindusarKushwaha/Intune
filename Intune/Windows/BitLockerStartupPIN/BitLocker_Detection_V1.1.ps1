<#
 Detection Script to check below
1) Bit locker is enabled(Drive c:) is 100 % encrypted
2) TPM Pin is set

The output is boolean ($true/$false)

if the drive is Encrypted 100% AND Keyprotector is TPMPIn ----->Output is true

If any of above condition is false output is False
#>




#check if c: is fully encrypted

$success=$false

$BitInfo=Get-BitLockerVolume -MountPoint $env:SystemDrive


if ($bitinfo.EncryptionPercentage -eq 100)

 { 
            If("Tpmpin" -in $BitInfo.KeyProtector.keyprotectortype)
        
            {$success=$true
                    
             }

            else
            {$success=$false
            }
    
 }

 Else

    {$success=$False

    }

 if ($success -eq $true)

 {
 Write-Output $success
 }

 


#Write-Output $(Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where { $_.KeyProtectorType -eq 'TpmPin' }

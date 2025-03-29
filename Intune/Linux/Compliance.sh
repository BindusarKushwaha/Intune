#!/bin/bash
#set -x

############################################################################################
##
## Extension Attribute script to return the version of an installed App
##
############################################################################################

## Copyright (c) 2020 Microsoft Corp. All rights reserved.
## Scripts are not supported under any Microsoft standard support program or service. The scripts are provided AS IS without warranty of any kind.
## Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a
## particular purpose. The entire risk arising out of the use or performance of the scripts and documentation remains with you. In no event shall
## Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
## (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary
## loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility
## of such damages.
## Feedback: bikush@microsoft.com

#Please specify the Application names
declare -a apps=("Google Drive.app" "Microsoft Outlook.app" "Pages.app")

#Please specify the application locations in same order as mentioned above
declare -a applocs=("/Applications" "/Applications" "/Applications")

#Please specify the processess to check if they are running
declare -a proc=("IntuneMdmAgent" "USBAgent" "secd")

j=0
appcomp=1

for i in "${apps[@]}"
do
    #echo "Changing Dir to ${applocs[$j]}"
    cd ${applocs[$j]}


    #echo "$i"
    #echo "${applocs[$j]}"

    if [ -e "$i" ]; then
        #$echo "$app found at location $loc"
        appcomp=$((appcomp * 1))
        #echo $appcomp
    else
        appcomp=$((appcomp * 0))
    fi
    #echo "out side If"

    j=$j+1

done
#echo "Apps=$appcomp"


#ProComp=1

for k in "${proc[@]}"
do
    if pgrep -x "$k" >/dev/null
    then
        ProComp=$((appcomp * 1))
    
    else
        ProComp=$((appcomp * 0))

    fi
done
echo "$appcomp"
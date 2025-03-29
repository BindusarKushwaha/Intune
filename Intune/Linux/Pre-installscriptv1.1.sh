#!/bin/bash
## Description: Checks for global preferences file and populates
## it with the default portal if needed.
## Body ###########################################################
## Declare Variables ##############################################

# Log file
log_file="/var/log/gp_script.log"

# Function to log messages
log_message() {
   echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $log_file
}

# Get current Console user
active_user=$(stat -f "%Su" /dev/console)
log_message "Current console user: $active_user"

gploc=/Applications/GlobalProtect.app/Contents/MacOS/GlobalProtect
if [[ -e $gploc ]]; then
   log_message "Uninstalling existing version of GP"
   sh "/Applications/GlobalProtect.app/Contents/Resources/uninstall_gp.sh"
   sleep 30
   number=$(ps aux | grep -v grep | grep -ci PanGPS)
   if [ $number -gt 0 ]; then
      log_message "GP is Running - retrying uninstall"
      sh "/Applications/GlobalProtect.app/Contents/Resources/uninstall_gp.sh"
      sleep 45
      log_message "Uninstalled GP"
   fi
else
   log_message "GlobalProtect not found"
fi

gPrefs=/Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist
if [[ -e $gPrefs ]]; then
   log_message "Default global portal already exists. Skipping."
else
   log_message "Setting default global portal to: gp2885.gp.panclouddev.com"
   echo '<?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
      <key>Palo Alto Networks</key>
      <dict>
         <key>GlobalProtect</key>
         <dict> 
            <key>PanSetup</key>
            <dict>
               <key>Portal</key>
               <string>air-india-portal.gp.com</string>
               <key>Prelogon</key>
               <string>0</string>
            </dict>
            <key>Settings</key>
            <dict>
               <key>connect-method</key>
               <string>on-demand</string>
            </dict>
         </dict>
      </dict>
   </dict>
   </plist>
   ' > $gPrefs
   log_message "Created global preferences file with default portal"
   killall cfprefsd
   log_message "Killed cfprefsd to prevent overwriting changes"
fi

# Check exit code.
exit_code=$?
log_message "Script exited with code $exit_code"
exit $exit_code
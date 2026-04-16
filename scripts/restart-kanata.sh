#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart Kanata
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ⌨️

# Documentation:
# @raycast.author Jack D. Douglas

sudo launchctl unload /Library/LaunchDaemons/com.jackdouglas.kanata.plist
sudo launchctl load /Library/LaunchDaemons/com.jackdouglas.kanata.plist

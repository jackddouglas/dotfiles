#!/bin/bash

# @tuna.name Restart Kanata
# @tuna.subtitle Unload and reload kanata daemon
# @tuna.mode inline

sudo launchctl unload /Library/LaunchDaemons/com.jackdouglas.kanata.plist
sudo launchctl load /Library/LaunchDaemons/com.jackdouglas.kanata.plist

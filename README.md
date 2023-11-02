# CalSync
## Installation
1. Download the CalSync executable from one of the releases (the one just called `CalSync` in the Assets section)
2. Open a terminal wherever you downloaded the executable
3. Move the executable with `mv CalSync /usr/local/bin/`
4. Make it executable with `chmod +x /usr/local/bin/CalSync`
5. Verify that the installation is working by executing `CalSync` in any terminal
6. You're done!

## Scheduling the Sync
1. Download the `com.tpreece101.calsync.plist` file
2. Open a terminal and move the file with `mv com.tpreece101.calsync.plist ~/Library/LaunchAgents/`
3. Load it is a launch agent using `launchctl load ~/Library/LaunchAgents/com.tpreece101.calsync.plist`
4. Start the launch agent with `launchctl start com.tpreece101.calsync.plist`

This will schedule the sync to run every 15 minutes

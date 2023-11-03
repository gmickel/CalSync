# CalSync
## Installation
1. Download the CalSync executable from the most recent release [here](https://github.com/TPreece101/CalSync/releases) (the one just called `CalSync` in the Assets section)
2. Open a terminal wherever you downloaded the executable
3. Make it executable with `chmod +x CalSync`
4. Open the folder in Finder, right click CalSync and click Open
5. There will be an unidentified developer warning - click Open (this is because I don't want to pay £79 for an Apple Developer Account 😅) if the application is working you should see the CalSync logo
6. Move the executable with `mv CalSync /usr/local/bin/`
7. Verify that the installation is working by executing `CalSync` in any terminal
8. You're done!

## Scheduling the Sync
1. Download the `com.tpreece101.calsync.plist` file
2. Open a terminal and move the file with `mv com.tpreece101.calsync.plist ~/Library/LaunchAgents/`
3. Load it is a launch agent using `launchctl load ~/Library/LaunchAgents/com.tpreece101.calsync.plist`
4. Start the launch agent with `launchctl start com.tpreece101.calsync.plist`

This will schedule the sync to run every 15 minutes

## Development
Build the executable using
```sh
swift build -c release
```

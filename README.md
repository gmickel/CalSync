# CalSync
## Requirements
* macOS 14+ (Sonoma)
## Installation
1. Download the calsync-x.x.x.pkg from the most recent release [here](https://github.com/TPreece101/CalSync/releases)
2. Install from the `.pkg` file by opening it from the finder
3. Verify that the installation is working by executing `CalSync` in any terminal - if it is working you should see the CalSync logo

## Usage
```
   ____     _       _           ____      __   __  _   _      ____
U /"___|U  /"\  u  |"|         / __"| u   \ \ / / | \ |"|  U /"___|
\| | u   \/ _ \/ U | | u      <\___ \/     \ V / <|  \| |> \| | u
 | |/__  / ___ \  \| |/__      u___) |    U_|"|_uU| |\  |u  | |/__
  \____|/_/   \_\  |_____|     |____/>>     |_|   |_| \_|    \____|
 _// \\  \\    >>  //  \\       )(  (__).-,//|(_  ||   \\,-._// \\
(__)(__)(__)  (__)("_")("_)     (__)      \_) (__) ("_)  (_/(__)(__)


OVERVIEW: A utility for syncing calendars in a way that keeps event details
private

USAGE: CalSync <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  run                     Run configured syncs
  list                    Lists configured syncs
  add                     Add a sync
  remove                  Remove a sync

  See 'CalSync help <subcommand>' for detailed help.
```
### What is a Sync?
A Sync in the terms of CalSync is a job that will copy events from one calendar into another with a specific event name, ignoring any event details beyone the start and end time of the event. It will have the following properties:
* Which calendar to pull events from
* Which calendar to push events to
* What horizon do you want to copy events for (in days) e.g. 7 would sync the next 7 days (including the whole of today)
* What do you want the copied event to be called?

**Note a Sync is only one-way** if you want to sync two ways you will need two syncs (you can just add another by running `CalSync add` again)

You can set up a Sync between any two calendars that have been added to your Apple Calendar app. When you run the `CalSync add` command it will list your available calendars and ask you which one you want to pull from and push to.
### Run
`CalSync run` will run all configured syncs, if you've just installed CalSync you won't have any so you'll need to configure some using `CalSync add`

### List
`CalSync list` will list any configured syncs, including the `"id"` that you'll need if you want to remove a sync later

### Add
`CalSync add` will walk you through adding a Sync

### Remove
`CalSync remove <id>` will remove a configured Sync e.g. `CalSync remove 3E2A80DA-2EF9-4A19-92ED-174A7DCABB3D`

## Scheduling the Sync
1. Download the `com.tpreece101.calsync.plist` file
2. Open a terminal and move the file with `mv com.tpreece101.calsync.plist ~/Library/LaunchAgents/`
3. Load it as a launch agent using `launchctl load ~/Library/LaunchAgents/com.tpreece101.calsync.plist`
4. Start the launch agent with `launchctl start com.tpreece101.calsync.plist`

This will run the `CalSync run` command every 15 minutes in the background with any logs going to `/tmp/CalSync_output.log`

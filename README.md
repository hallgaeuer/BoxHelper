# BoxHelper

Addon for World of Warcraft 2.4.3.

Adds two frames that list all party/raid members that currently either..
* do not face their target
* do get GTFO alerts

Depends on the addon GTFO.  
Currently probably only works on the english client.

## Commands

### `/boxhelper test` or `/bh test`

Simulates both a "not facing target" event and a "GTFO" event to briefly display your character in your frames and your party members frames.

## Notes

"Not facing a target" is detected by reading messages in the error frame.  
So it will only work when someone is trying to cast a spell and gets a "Target needs to be in front of you." message.
# Monolithic jb.sh

This repository builds the infamous `jb.sh` script used by [currently unnamed jailbreak] (backported to WinterBreak)  

## What
The idea behind `jb.sh` was to eliminate the `hotfix` as it was defunct and cumbersome in favour for having the jailbreak simply run `curl -L kindlemodding.org/jb.sh | sh`  
Hosting it online also means that during re-runs of the script it will always be up to date, circumventing any potential countermeasures (to an extent)

## Additions
In addition to everything the Universal Hotfix did, the monolithic jb.sh script also performs a handful of post-jb steps, such as `ota renamer` and installing `KPM`

## How
The final `jb.sh` script is built from many smaller scripts (see: `src/jobs`) and files (see: `src/kmc`)


## Notes
- jb.sh unpacks /var/local/kmc and runs patch_system.sh
- patch_system.sh is where the bulk of the logic happens - it is also run every boot - just in case
- persistence is handled the same as the hotfix - appreg.db hook uses run_patch.sh which calls gandalf to run patch_system.sh
- some JB methods have jb.sh run every like 5 minutes or smth stupid - this is probably fine and won't kill the eMMC
# Monolithic jb.sh

This repository builds the infamous `jb.sh` script used by [currently unnamed jailbreak] (backported to WinterBreak)  

## What
The idea behind `jb.sh` was to eliminate the `hotfix` as it was defunct and cumbersome in favour for having the jailbreak simply run `curl -L kindlemodding.org/jb.sh | sh`  
Hosting it online also means that during re-runs of the script it will always be up to date, circumventing any potential countermeasures (to an extent)

## Additions
In addition to everything the Universal Hotfix did, the monolithic jb.sh script also performs a handful of post-jb steps, such as `ota renamer` and installing `KPM`

## How
The final `jb.sh` script is built from many smaller scripts (see: `src/jobs`) and files (see: `src/kmc`)
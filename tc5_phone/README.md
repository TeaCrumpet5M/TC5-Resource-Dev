# tc5_phone fixed drop-in

This is a cleaned drop-in build of tc5_phone.

## Fixes included
- Removes invalid pasted markdown/text from `server/main.lua`
- Restores a valid `BuildState` function
- Keeps contacts, messages, profile, jobs, garage, bank, and settings working
- Adds safer mechanic scan fallback for `tc5_mechanicshops` and legacy `tc5_mechanicjob`

## Install
- Replace your existing `tc5_phone` resource with this folder
- Restart the resource:
  - `restart tc5_phone`

## Commands
- `/phone`
- Keybind: `F1`

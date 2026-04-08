# tc5_bossmenu dynamic

Built for your TC5 stack with:
- E interaction at boss locations
- tc5_jobs auth via GetPlayerJob
- hire nearby player
- employee management
- salary management
- society cash account
- boss stash
- society inventory

## Storage
This resource uses tc5_inventory stashes:
- boss_<job>_stash
- society_<job>_inventory

## Important note
This version authenticates against tc5_jobs through GetPlayerJob.
For live job writeback it tries these exports if they exist:
- SetPlayerJob
- SetJob
- SetPlayerJobGrade

If your tc5_jobs dynamic resource uses different export names, add your exact export into `trySetPlayerJob()` in `server/main.lua`.

## Resource order
ensure tc5_ui
ensure tc5_core
ensure tc5_inventory
ensure tc5_jobs
ensure tc5_bossmenu

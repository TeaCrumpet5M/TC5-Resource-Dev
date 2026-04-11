# tc5_mechanicjob

Fresh TC5 mechanic job resource.

## Included
- full NUI for crafting
- full NUI for repairs and diagnostics
- boss menu NUI
- stock shop NUI scaffold
- tc5_jobs integration kept
- no tablet integration
- no phone integration
- no modding menu
- chat-command access and E-interact locations
- multi-shop support from one config

## Commands
- `/mech` or `/mech scan` - quick scan of nearby vehicle
- `/mech duty` - toggle duty
- `/mech repair` - open repair bay UI
- `/mech craft` - open crafting UI
- `/mech shop` - open parts shop UI
- `/mech boss` - open boss UI
- `/mech_craft [recipeId]` - direct craft by recipe id
- `/mech_hire [id]`
- `/mech_fire [id]`
- `/mech_promote [id]`
- `/mech_demote [id]`

## Interacts
Each shop can have these points in `shared/config.lua`:
- `duty`
- `crafting`
- `repair`
- `boss`
- `shop`

## Notes
The parts shop is visually complete but purchase charging is intentionally left as a scaffold because the uploaded resource set did not include a known TC5 economy/money export. The placeholder is inside:
- `server/main.lua` -> `tc5_mechanicjob:server:purchaseStock`

Once you wire your money export there, the shop can be made fully transactional.

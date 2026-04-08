# tc5_admintools v2.4

## Added
- Job manager tab
- Dev mode with live coords and heading
- Vehicle catalog tab with categories, search, visual vehicle cards, and one-click spawn/register
- Permanent key handout attempt for admin-spawned registered vehicles
- Fallback admin vehicle registry table: `tc5_admin_spawned_vehicles`

## Commands
- /admin
- /givekeys
- /devmode

## Notes
- The vehicle catalog uses configurable entries in `shared/config.lua`.
- Registered admin vehicles are always written to `tc5_admin_spawned_vehicles`.
- If you want them inserted into your main owned-vehicles table too, set `TC5Admin.Config.VehicleSpawner.SaveToOwnedVehicles = true` and edit `OwnedVehiclesInsertQuery` to match your schema.
- Permanent keys are attempted through `tc5_vehiclekeys`. If your keys resource only supports temporary access, it falls back to temp keys for 1440 minutes by default.

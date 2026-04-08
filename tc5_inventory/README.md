# tc5_inventory

Base TC5 inventory resource with a red/black/white theme.

## Includes
- Player inventory
- SQL persistence
- Weight system
- Item definitions
- Use / drop / give hooks
- Basic drag and drop NUI

## SQL
Import `tc5_inventory.sql`.

## server.cfg
ensure oxmysql
ensure tc5_ui
ensure tc5_core
ensure tc5_inventory

## Notes
This is a base implementation. It does not yet include:
- stack splitting
- item images
- real ground drops
- shops
- trunks / gloveboxes openers
- durability

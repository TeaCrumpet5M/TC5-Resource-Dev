TC5 Inventory (cash-item compatible)

What changed:
- UI kept the same
- drag/drop preserved in the inventory UI
- hotbar client file is now loaded
- cash is now supported as a real inventory item
- shop purchases now remove inventory cash instead of core cash
- added exports:
  GetCash(src)
  AddCash(src, amount)
  RemoveCash(src, amount)
  GetItemCount(src, itemName)
- added /cashcount command

Important:
- Your old core cash still exists for legacy scripts.
- For new scripts, use tc5_inventory cash exports instead of tc5_core cash.
- tc5_banking deposits and withdrawals should use tc5_inventory cash exports.

Recommended ensure order:
ensure oxmysql
ensure tc5_core
ensure tc5_ui
ensure tc5_inventory
ensure tc5_jobs
ensure tc5_banking

Useful commands:
/inventory
/hotbar
/trunk
/glovebox
/cashcount

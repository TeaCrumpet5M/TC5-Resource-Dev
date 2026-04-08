TC5 Tablet v2
==============

This resource replaces tc5_tablet with a fresh modular tablet system.

What is included
----------------
- In-hand tablet prop + looping tablet animation
- Fullscreen NUI styled like a physical tablet
- USB-gated app loading
- Example basic Boosting app
- Random boost contracts with payout + rep progression
- /tablet command and item-use support

Install
-------
1. Remove or rename your old tc5_tablet resource.
2. Drop this folder in your resources list as tc5_tablet.
3. Ensure it starts after tc5_core, tc5_inventory and tc5_ui.
4. Add the inventory items below if they are not already in tc5_inventory/shared/items.lua
5. Restart the server.

Suggested item entries
----------------------
tablet = {
    label = 'Encrypted Tablet',
    weight = 1200,
    stack = false,
    image = 'tablet.png',
    description = 'A modular tablet that can load USB software.',
    useEvent = 'tc5_tablet:client:useTablet'
},
usb_boosting = {
    label = 'Boosting USB',
    weight = 100,
    stack = false,
    image = 'usb_boosting.png',
    description = 'Contains a boosting application for your tablet.'
}

Notes
-----
- The example boosting app is intentionally basic so you can expand it.
- More apps can be added in shared/config.lua under TC5Tablet.Config.Apps.
- The server currently keeps boost rep in memory only. If you want, this can be wired into your character database later.

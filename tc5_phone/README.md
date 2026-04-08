# tc5_phone

A TC5-native starter phone inspired by NPWD's app-based UX, built as a lighter Lua + NUI implementation.

## Included in this build

### Phase 1
- Phone shell / home screen
- Contacts
- Messages
- Profile
- Settings
- Character-owned phone number
- Runtime app registration export

### Phase 2
- Basic Calls app shell
- Jobs app integration (reads `tc5_jobs` if installed)
- Garage app shell
- Bank app shell using tc5_core character balances

## Commands
- `/phone`
- Keybind: `F1`

## Exports
```lua
exports['tc5_phone']:RegisterApp({
    id = 'myapp',
    label = 'My App',
    icon = '🧩',
    color = '#1f1f1f'
})

exports['tc5_phone']:GetPhoneNumber(source)
```

## Notes
- Calls are a Phase 2 UI shell and not yet connected to voice routing.
- Garage app is ready to connect to your vehicle module.
- Messages persist in MySQL per character.
- This uses `tc5_core` for player / character data and `tc5_ui` for notifications.

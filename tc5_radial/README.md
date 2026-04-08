# tc5_radial

TC5 radial menu.

## Default key
- M

## Exports
```lua
exports['tc5_radial']:RegisterItem({
    id = 'billing',
    label = 'Billing',
    icon = '💵',
    event = 'myresource:client:billing'
})

exports['tc5_radial']:RemoveItem('billing')
exports['tc5_radial']:OpenMenu()
```

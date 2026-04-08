# tc5_eye

TC5 third-eye interaction system using LEFT ALT like ox-style targeting.

## Features
- Hold LEFT ALT to open eye menu
- zone interactions
- entity interactions
- model interactions
- garage integration demo included

## Exports
```lua
exports['tc5_eye']:AddBoxZone({
    id = 'my_zone',
    coords = vector3(0.0, 0.0, 0.0),
    radius = 2.0,
    options = {
        {
            id = 'my_option',
            label = 'Open Action',
            icon = '⚙️',
            event = 'myresource:client:open'
        }
    }
})

exports['tc5_eye']:AddEntityOption(entity, {
    {
        id = 'talk_npc',
        label = 'Talk',
        icon = '💬',
        event = 'myresource:client:talk'
    }
})

exports['tc5_eye']:AddModelOption('s_m_m_security_01', {
    {
        id = 'talk_guard',
        label = 'Talk to Guard',
        icon = '🛡️',
        event = 'myresource:client:guardTalk'
    }
})
```

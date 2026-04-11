TC5Phone = TC5Phone or {}
TC5Phone.Config = {}
TC5Phone.Config.Debug = true
TC5Phone.Config.OpenCommand = 'phone'
TC5Phone.Config.OpenKey = 'F1'
TC5Phone.Config.DefaultWallpaper = 'linear-gradient(180deg, #15090b 0%, #090909 55%, #000000 100%)'
TC5Phone.Config.TimeFormat24h = true
TC5Phone.Config.MaxContacts = 100
TC5Phone.Config.MaxMessagesPerThread = 150
TC5Phone.Config.Theme = {
    primary = '#b10f1f',
    primarySoft = 'rgba(177, 15, 31, 0.16)',
    background = '#090909',
    panel = '#121212',
    panelAlt = '#1a1a1a',
    border = 'rgba(255,255,255,0.08)',
    text = '#ffffff',
    muted = '#c6c6c6',
    success = '#2ecc71',
    error = '#ff4d4f',
    warning = '#f4b400',
    info = '#ffffff'
}
TC5Phone.Config.DefaultApps = {
    { id = 'contacts', label = 'Contacts', icon = '👥', color = '#1f1f1f' },
    { id = 'messages', label = 'Messages', icon = '💬', color = '#1f1f1f' },
    { id = 'calls', label = 'Calls', icon = '📞', color = '#1f1f1f' },
    { id = 'profile', label = 'Profile', icon = '🪪', color = '#1f1f1f' },
    { id = 'jobs', label = 'Jobs', icon = '💼', color = '#1f1f1f' },
    { id = 'garage', label = 'Garage', icon = '🚗', color = '#1f1f1f' },
    { id = 'bank', label = 'Bank', icon = '🏦', color = '#1f1f1f' },
    { id = 'settings', label = 'Settings', icon = '⚙️', color = '#1f1f1f' }
}

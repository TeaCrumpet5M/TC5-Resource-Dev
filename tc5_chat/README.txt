TC5 Chat install
================

The default FiveM chat resource must be stopped or you will see two chat windows.

Recommended server.cfg order:

    ensure chat
    ensure tc5_chat
    stop chat

Simpler option:
- remove or comment out: ensure chat
- keep: ensure tc5_chat

Important:
- If any other resource uses exports['chat']:addSuggestion or similar, those exports belong to the default resource name "chat".
- In that case, the safest setup is to rename this tc5_chat folder to chat, then ensure chat instead.
- If your other resources only use chat events like TriggerEvent('chat:addMessage', ...) or TriggerClientEvent('chat:addSuggestion', ...), tc5_chat will still work fine.

Quick fix for duplicate chat:
1. Open server.cfg
2. Remove or comment out ensure chat
3. Keep ensure tc5_chat
4. Restart server

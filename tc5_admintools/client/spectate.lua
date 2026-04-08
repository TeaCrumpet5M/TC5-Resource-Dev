local spectating = false
local lastCoords = nil

RegisterNetEvent('tc5_admintools:client:startSpectate', function(target)
    local player = GetPlayerFromServerId(target)
    if player == -1 then return end
    local targetPed = GetPlayerPed(player)
    if targetPed == 0 then return end
    local ped = PlayerPedId()
    if not spectating then lastCoords = GetEntityCoords(ped) end
    spectating = true
    NetworkSetInSpectatorMode(true, targetPed)
end)

RegisterNetEvent('tc5_admintools:client:stopSpectate', function()
    if not spectating then return end
    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    if lastCoords then SetEntityCoords(ped, lastCoords.x, lastCoords.y, lastCoords.z) end
    spectating = false
end)

local godmodeEnabled = false

local function applyGodmode(state)
    local playerId = PlayerId()
    local ped = PlayerPedId()
    godmodeEnabled = state == true

    SetPlayerInvincible(playerId, godmodeEnabled)
    SetEntityInvincible(ped, godmodeEnabled)
    SetPedCanRagdoll(ped, not godmodeEnabled)

    if godmodeEnabled then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
    end
end

RegisterNetEvent('tc5_admintools:client:toggleGodmode', function()
    applyGodmode(not godmodeEnabled)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if godmodeEnabled then
        applyGodmode(false)
    end
end)

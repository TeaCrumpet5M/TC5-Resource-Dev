RegisterNetEvent('tc5_core:client:spawnPlayer', function(coords)
    if not coords then return end

    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
    FreezeEntityPosition(ped, false)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    Wait(500)
    DoScreenFadeIn(800)

    if exports['tc5_ui'] and exports['tc5_ui'].Notify then
        exports['tc5_ui']:Notify({
            title = 'Spawn',
            message = 'Character spawned successfully.',
            type = 'success',
            duration = 2500
        })
    end
end)

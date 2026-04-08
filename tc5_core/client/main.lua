RegisterNetEvent('tc5_core:client:userLoaded', function(data)
    print(('[tc5_core] User loaded | userId=%s | name=%s'):format(
        tostring(data.userId),
        tostring(data.name)
    ))

    if data.character then
        print(('[tc5_core] Character loaded | charId=%s | fullName=%s | cash=%s | bank=%s'):format(
            tostring(data.character.id),
            tostring(data.character.fullName),
            tostring(data.character.cash),
            tostring(data.character.bank)
        ))
    end
end)

RegisterNetEvent('tc5_core:client:spawnPlayer', function(coords)
    local ped = PlayerPedId()

    TriggerEvent('tc5_creator:client:forceClose')
    TriggerEvent('tc5_spawn:client:forceClose')

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    DoScreenFadeOut(500)
    Wait(500)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)

    Wait(500)
    DoScreenFadeIn(1000)
end)
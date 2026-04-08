local noclipEnabled = false
local speedIndex = 2
local speeds = {
    TC5Admin.Config.Noclip.Slow,
    TC5Admin.Config.Noclip.Normal,
    TC5Admin.Config.Noclip.Fast
}

RegisterNetEvent('tc5_admintools:client:toggleNoclip', function()
    noclipEnabled = not noclipEnabled
    local ped = PlayerPedId()
    SetEntityInvincible(ped, noclipEnabled)
    SetEntityCollision(ped, not noclipEnabled, not noclipEnabled)
    SetEntityVisible(ped, not noclipEnabled, false)
end)

CreateThread(function()
    while true do
        if not noclipEnabled then
            Wait(500)
        else
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local speed = speeds[speedIndex]
            if IsControlJustPressed(0, 21) then
                speedIndex = speedIndex + 1
                if speedIndex > #speeds then speedIndex = 1 end
            end
            if IsControlPressed(0, 32) then coords = coords + (forward * speed) end
            if IsControlPressed(0, 33) then coords = coords - (forward * speed) end
            if IsControlPressed(0, 22) then coords = vector3(coords.x, coords.y, coords.z + speed) end
            if IsControlPressed(0, 36) then coords = vector3(coords.x, coords.y, coords.z - speed) end
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
        end
    end
end)

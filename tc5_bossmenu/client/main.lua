TC5BossMenu = TC5BossMenu or {}
TC5BossMenu.Client = TC5BossMenu.Client or {}
TC5BossMenu.Client.Open = false

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function setOpen(state)
    TC5BossMenu.Client.Open = state == true
    SetNuiFocus(TC5BossMenu.Client.Open, TC5BossMenu.Client.Open)
    SetNuiFocusKeepInput(false)
end

local function draw3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.34, 0.34)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterNetEvent('tc5_bossmenu:client:open', function(state)
    setOpen(true)
    send('open', state)
end)

RegisterNetEvent('tc5_bossmenu:client:refresh', function(state)
    send('refresh', state)
end)

RegisterNetEvent('tc5_bossmenu:client:setNearbyPlayers', function(players)
    send('setNearbyPlayers', { players = players or {} })
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    send('close', {})
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('tc5_bossmenu:server:refresh')
    cb({ ok = true })
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    TriggerServerEvent('tc5_bossmenu:server:getNearbyPlayers')
    cb({ ok = true })
end)

RegisterNUICallback('hireNearby', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:hireNearby', data and data.source)
    cb({ ok = true })
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:deposit', data and data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:withdraw', data and data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('updateGrade', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:updateGrade', data and data.characterId, data and data.grade)
    cb({ ok = true })
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:fireEmployee', data and data.characterId)
    cb({ ok = true })
end)

RegisterNUICallback('setSalary', function(data, cb)
    TriggerServerEvent('tc5_bossmenu:server:setSalary', data and data.grade, data and data.salary)
    cb({ ok = true })
end)

RegisterNUICallback('openBossStash', function(_, cb)
    TriggerServerEvent('tc5_bossmenu:server:openBossStash')
    cb({ ok = true })
end)

RegisterNUICallback('openSocietyInventory', function(_, cb)
    TriggerServerEvent('tc5_bossmenu:server:openSocietyInventory')
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for jobName, info in pairs(TC5BossMenu.Config.JobMenus or {}) do
            local dist = #(coords - info.coords)
            if dist <= (TC5BossMenu.Config.MarkerDistance or 8.0) then
                sleep = 0
                DrawMarker(2, info.coords.x, info.coords.y, info.coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.28, 0.28, 0.28, 177, 15, 31, 150, false, true, 2, false, nil, nil, false)

                if dist <= (TC5BossMenu.Config.InteractDistance or 2.0) then
                    draw3D(info.coords + vector3(0.0, 0.0, 0.35), '[E] ' .. (info.label or 'Boss Menu'))
                    if IsControlJustReleased(0, TC5BossMenu.Config.InteractKey or 38) then
                        TriggerServerEvent('tc5_bossmenu:server:open', jobName)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

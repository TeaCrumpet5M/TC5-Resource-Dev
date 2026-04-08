local apartment = nil
local insideApartment = false
local selectionOpen = false

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

local function notify(title, message, kind)
    exports.tc5_ui:Notify({
        title = title,
        message = message,
        type = kind or 'info'
    })
end

local function getPoint(name)
    local localPoint = TC5Apartment.Config.InteriorPoints[name]
    if not localPoint then return nil end
    return vector3(localPoint.x, localPoint.y, localPoint.z)
end

local function openSelectionUI(choices)
    selectionOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'openSelection',
        data = {
            choices = choices or {}
        }
    })
end

local function closeSelectionUI()
    selectionOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'closeSelection',
        data = {}
    })
end

RegisterNetEvent('tc5_apartment:client:setApartment', function(data)
    apartment = data
end)

RegisterNetEvent('tc5_apartment:client:openSelection', function(choices)
    openSelectionUI(choices)
end)

RegisterNetEvent('tc5_apartment:client:selectionComplete', function(data)
    apartment = data
    closeSelectionUI()
    notify('Apartment', 'Apartment assigned successfully.', 'success')
end)

RegisterNetEvent('tc5_apartment:client:enter', function(data)
    apartment = data
    insideApartment = true
    notify('Apartment', 'Entered your apartment.', 'success')
    TriggerEvent('tc5_core:client:spawnPlayer', apartment.interior)
end)

RegisterNetEvent('tc5_apartment:client:exit', function(data)
    apartment = data
    insideApartment = false
    notify('Apartment', 'Exited your apartment.', 'info')
    TriggerEvent('tc5_core:client:spawnPlayer', apartment.entrance)
end)

RegisterNetEvent('tc5_apartment:client:wardrobeFallback', function()
    notify('Wardrobe', 'No supported clothing/outfit resource found.', 'error')
end)

RegisterNUICallback('selectApartment', function(data, cb)
    TriggerServerEvent('tc5_apartment:server:selectApartment', data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('closeApartmentSelection', function(_, cb)
    closeSelectionUI()
    cb({ ok = true })
end)

AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        Wait(2000)
        TriggerServerEvent('tc5_apartment:server:request')
    end
end)

CreateThread(function()
    while true do
        local sleep = 1500

        if apartment then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            if insideApartment then
                local exitTarget = getPoint('exit') or vector3(apartment.interior.x, apartment.interior.y, apartment.interior.z)
                local exitDist = #(pos - exitTarget)

                if exitDist < 8.0 then
                    sleep = 0
                    draw3D(exitTarget + vector3(0.0, 0.0, 0.3), '[E] Exit Apartment')
                    if exitDist < TC5Apartment.Config.InteractionDistance and IsControlJustReleased(0, 38) then
                        TriggerServerEvent('tc5_apartment:server:exit')
                    end
                end

                local stashTarget = getPoint('stash')
                if stashTarget then
                    local stashDist = #(pos - stashTarget)
                    if stashDist < 8.0 then
                        sleep = 0
                        draw3D(stashTarget + vector3(0.0, 0.0, 0.3), '[E] Open Apartment Stash')
                        if stashDist < TC5Apartment.Config.InteractionDistance and IsControlJustReleased(0, 38) then
                            TriggerServerEvent('tc5_apartment:server:openStash')
                        end
                    end
                end

                local wardrobeTarget = getPoint('wardrobe')
                if wardrobeTarget then
                    local wardrobeDist = #(pos - wardrobeTarget)
                    if wardrobeDist < 8.0 then
                        sleep = 0
                        draw3D(wardrobeTarget + vector3(0.0, 0.0, 0.3), '[E] Change Outfit')
                        if wardrobeDist < TC5Apartment.Config.InteractionDistance and IsControlJustReleased(0, 38) then
                            TriggerServerEvent('tc5_apartment:server:openWardrobe')
                        end
                    end
                end
            else
                local entryTarget = vector3(apartment.entrance.x, apartment.entrance.y, apartment.entrance.z)
                local dist = #(pos - entryTarget)

                if dist < 8.0 then
                    sleep = 0
                    draw3D(entryTarget + vector3(0.0, 0.0, 0.3), '[E] Enter Apartment')
                    if dist < TC5Apartment.Config.InteractionDistance and IsControlJustReleased(0, 38) then
                        TriggerServerEvent('tc5_apartment:server:enter')
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

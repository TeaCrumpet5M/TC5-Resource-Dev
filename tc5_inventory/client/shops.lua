CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())

        for id, shop in pairs(TC5Shops) do
            if #(coords - shop.coords) < 2.0 then
                sleep = 0

                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('tc5_inventory:server:openInventory', {
                        type = 'shop',
                        owner = id
                    })
                end
            end
        end

        Wait(sleep)
    end
end)
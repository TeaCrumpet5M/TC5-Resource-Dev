TC5Radial = TC5Radial or {}
TC5Radial.Client = TC5Radial.Client or {}
TC5Radial.Client.Items = {}
TC5Radial.Client.IsOpen = false

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function setOpen(state)
    TC5Radial.Client.IsOpen = state == true
    SetNuiFocus(TC5Radial.Client.IsOpen, TC5Radial.Client.IsOpen)
    SetNuiFocusKeepInput(false)
    send(state and 'open' or 'close', {})
    if state then
        send('setItems', { items = TC5Radial.Client.Items })
    end
end

local function addDefaultItems()
    TC5Radial.Client.Items = {
        {
            id = 'phone',
            label = 'Phone',
            icon = '📱',
            command = 'phone'
        },
        {
            id = 'vehiclelock',
            label = 'Vehicle Lock',
            icon = '🔒',
            command = 'tc5_vehiclelock'
        },
        {
            id = 'garage',
            label = 'Nearest Garage',
            icon = '🚗',
            command = 'tc5_garage'
        },
        {
            id = 'job',
            label = 'Job',
            icon = '💼',
            command = 'tc5_job'
        },
        {
            id = 'duty',
            label = 'Duty',
            icon = '🧰',
            command = 'tc5_duty'
        },
        {
            id = 'engine',
            label = 'Engine',
            icon = '⚙️',
            command = 'tc5_engine'
        }
    }
end

local function executeItem(itemId)
    local selected
    for i = 1, #TC5Radial.Client.Items do
        if tostring(TC5Radial.Client.Items[i].id) == tostring(itemId) then
            selected = TC5Radial.Client.Items[i]
            break
        end
    end

    if not selected then return end

    if selected.event then
        TriggerEvent(selected.event, selected)
    elseif selected.serverEvent then
        TriggerServerEvent(selected.serverEvent, selected)
    elseif selected.command then
        ExecuteCommand(selected.command)
    end
end

exports('RegisterItem', function(item)
    TC5Radial.Client.Items[#TC5Radial.Client.Items + 1] = item
    return true
end)

exports('RemoveItem', function(itemId)
    for i = #TC5Radial.Client.Items, 1, -1 do
        if tostring(TC5Radial.Client.Items[i].id) == tostring(itemId) then
            table.remove(TC5Radial.Client.Items, i)
        end
    end
end)

exports('OpenMenu', function()
    setOpen(true)
end)

RegisterNUICallback('select', function(data, cb)
    setOpen(false)
    executeItem(data and data.id)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({ ok = true })
end)

CreateThread(function()
    addDefaultItems()
    while true do
        if IsControlJustReleased(0, TC5Radial.Config.OpenKey) then
            setOpen(not TC5Radial.Client.IsOpen)
        end
        Wait(0)
    end
end)

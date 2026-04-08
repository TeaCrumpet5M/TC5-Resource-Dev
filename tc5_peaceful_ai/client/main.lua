local processedPeds = {}

local combatAttributesToDisable = {
    5,   -- Can fight armed peds when not armed
    13,  -- Aggressive
    17,  -- Always flee
    21,  -- Can chase target on foot
    27,  -- Perfect accuracy
    46,  -- Can fight without line of sight
    58,  -- Disable fleeing from combat? keep off for passive behavior
    86,  -- Use proximity firing rate
    142  -- Can attack from vehicles
}

local function shouldSkipPed(ped)
    if ped == 0 or not DoesEntityExist(ped) then
        return true
    end

    if IsPedAPlayer(ped) then
        return true
    end

    if Config.IgnoreMissionPeds and IsPedAMissionEntity(ped) then
        return true
    end

    if not Config.IncludeCops and IsPedCop(ped) then
        return true
    end

    local model = GetEntityModel(ped)
    if Config.ModelBlacklist[model] then
        return true
    end

    return false
end

local function pacifyPed(ped)
    if processedPeds[ped] and processedPeds[ped] > GetGameTimer() then
        return
    end

    processedPeds[ped] = GetGameTimer() + 15000

    SetPedDropsWeaponsWhenDead(ped, false)
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)

    SetPedAsEnemy(ped, false)
    SetPedCanSwitchWeapon(ped, false)
    SetPedCombatMovement(ped, 0)
    SetPedCombatAbility(ped, 0)
    SetPedCombatRange(ped, 0)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedAlertness(ped, 0)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetCanAttackFriendly(ped, false, false)

    for _, attr in ipairs(combatAttributesToDisable) do
        SetPedCombatAttributes(ped, attr, false)
    end

    if IsPedInCombat(ped, PlayerPedId()) or GetPedAlertness(ped) > 0 then
        ClearPedTasksImmediately(ped)
        TaskWanderStandard(ped, 10.0, 10)
    end
end

local function cleanupProcessedPeds()
    local now = GetGameTimer()

    for ped, expiry in pairs(processedPeds) do
        if expiry <= now or not DoesEntityExist(ped) then
            processedPeds[ped] = nil
        end
    end
end

local function disableWantedSystem()
    local player = PlayerId()

    SetMaxWantedLevel(0)
    SetPoliceIgnorePlayer(player, true)
    SetDispatchCopsForPlayer(player, false)
    ClearPlayerWantedLevel(player)

    if GetPlayerWantedLevel(player) ~= 0 then
        SetPlayerWantedLevel(player, 0, false)
        SetPlayerWantedLevelNow(player, false)
        ClearPlayerWantedLevel(player)
    end

    for _, service in ipairs(Config.DisabledDispatchServices) do
        EnableDispatchService(service, false)
    end
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local peds = GetGamePool('CPed')

        for i = 1, #peds do
            local ped = peds[i]

            if not shouldSkipPed(ped) then
                local pedCoords = GetEntityCoords(ped)
                if #(playerCoords - pedCoords) <= Config.ScanRadius then
                    pacifyPed(ped)
                end
            end
        end

        cleanupProcessedPeds()
        Wait(Config.ScanInterval)
    end
end)

CreateThread(function()
    if not Config.DisableWantedSystem then
        return
    end

    while true do
        disableWantedSystem()
        Wait(Config.WantedTick)
    end
end)

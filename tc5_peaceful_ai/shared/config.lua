Config = {}

-- How often nearby peds are processed.
Config.ScanInterval = 2000

-- How far from the player peds should be processed.
Config.ScanRadius = 180.0

-- If true, cops are also disarmed / pacified.
Config.IncludeCops = true

-- If true, mission peds are skipped to reduce the chance of breaking scripted content.
Config.IgnoreMissionPeds = true

-- If true, the GTA wanted/star system is disabled for the local player.
Config.DisableWantedSystem = true

-- How often the wanted level / dispatch suppression loop runs.
Config.WantedTick = 250

-- Dispatch services to disable when DisableWantedSystem is true.
-- 1-15 covers the standard GTA V dispatch groups used by police / emergency AI.
Config.DisabledDispatchServices = {
    1, 2, 3, 4, 5,
    6, 7, 8, 9, 10,
    11, 12, 13, 14, 15
}

-- Models that should never be modified.
Config.ModelBlacklist = {
    -- [`s_m_y_swat_01`] = true,
}

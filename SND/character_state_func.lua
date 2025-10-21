----------------------------------------------------------------------------------------------------------------------------
-- CHARACTER STATE TRACKER
-- Tracks helper character reward status for daily automation rotation
-- Format: {helperName, mainToon, status, level}
-- Status: 0 = Reward still needed, 1 = Reward received
-- Level: Character level (used for trial duty farming)
-- Last Updated: 2025-10-19
-- Added: Level tracking for trial duty farming system
----------------------------------------------------------------------------------------------------------------------------

-- Global variable to store last reset timestamp (loaded from file)
local lastResetTimestamp = nil

local function GetConfigPath()
    local userprofile = os.getenv("USERPROFILE")
    if not userprofile or userprofile == "" then
        local username = os.getenv("USERNAME") or ""
        if username == "" then return nil end
        userprofile = "C:\\Users\\" .. username
    end
    return userprofile .. [[\AppData\Roaming\XIVLauncher\pluginConfigs\SomethingNeedDoing\character_state.lua]]
end

-- ===============================================
-- Save Character State to File
-- ===============================================
local function SaveCharacterState(characterTable)
    if not characterTable or type(characterTable) ~= "table" then
        CureEcho("[CharState] ERROR: Invalid character table provided")
        return false
    end
    
    local configPath = GetConfigPath()
    if not configPath then
        CureEcho("[CharState] ERROR: Could not resolve config path")
        return false
    end
    
    -- Format as Lua table with metadata
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local completed = 0
    local pending = 0
    
    for _, entry in ipairs(characterTable) do
        if entry[3] == 1 then
            completed = completed + 1
        else
            pending = pending + 1
        end
    end
    
    -- Include reset timestamp in file header
    local resetTimeStr = lastResetTimestamp or "Never"
    local output = string.format("-- Character State (Last saved: %s)\n-- Last Reset: %s\n-- Completed: %d, Pending: %d\nreturn {\n", 
        timestamp, resetTimeStr, completed, pending)
    
    for _, entry in ipairs(characterTable) do
        local helperChar = tostring(entry[1][1])
        local mainToon = tostring(entry[2])
        local status = entry[3]
        local level = entry[4] or 90  -- Default to 90 if not present
        output = output .. string.format('  {{"%s"}, "%s", %d, %d},\n', helperChar, mainToon, status, level)
    end
    
    output = output .. "}\n"
    
    local file, err = io.open(configPath, "w")
    if not file then
        CureEcho("[CharState] ERROR: Could not open file for writing - " .. tostring(err))
        return false
    end
    
    local success, writeErr = pcall(function()
        file:write(output)
        file:close()
    end)
    
    if not success then
        CureEcho("[CharState] ERROR: Failed to write state file - " .. tostring(writeErr))
        return false
    end
    
    CureEcho("[CharState] ✓ Saved state (" .. completed .. " completed, " .. pending .. " pending)")
    return true
end

-- ===============================================
-- Create Character State from Config
-- ===============================================
local function CreateCharacterStateFromConfig(helperConfigs)
    local characterState = {}
    
    for _, config in ipairs(helperConfigs) do
        if config[1] and config[1][1] and config[2] then
            -- Format: {helperName, mainToon, status, level}
            -- Default level is 90 if not specified in config
            local level = (config[4] and tonumber(config[4])) or 90
            table.insert(characterState, {config[1], config[2], 0, level})
        end
    end
    
    -- Save immediately
    SaveCharacterState(characterState)
    CureEcho("[CharState] Created new state with " .. #characterState .. " helpers")
    
    return characterState
end

-- ===============================================
-- Load Character State from File
-- ===============================================
local function LoadCharacterState(helperConfigs)
    local configPath = GetConfigPath()
    if not configPath then
        CureEcho("[CharState] ERROR: Could not resolve config path")
        return {}
    end
    
    local file, err = io.open(configPath, "r")
    
    -- If file doesn't exist, create it with all helpers set to status 0
    if not file then
        CureEcho("[CharState] State file not found - creating new one at: " .. configPath)
        return CreateCharacterStateFromConfig(helperConfigs)
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content or content == "" then
        CureEcho("[CharState] State file is empty - reinitializing")
        return CreateCharacterStateFromConfig(helperConfigs)
    end
    
    -- Extract reset timestamp from file comments
    local resetTime = content:match("%-%-%-* Last Reset: ([^\n]+)")
    if resetTime and resetTime ~= "Never" then
        lastResetTimestamp = resetTime
        CureEcho("[CharState] Last reset timestamp: " .. resetTime)
    else
        lastResetTimestamp = nil
        CureEcho("[CharState] No reset timestamp found (first run or old format)")
    end
    
    local characterState = {}
    local success, result = pcall(function()
        -- File already contains 'return', so just load it directly
        local loadFunc = load(content)
        if loadFunc then
            characterState = loadFunc()
        end
    end)
    
    if not success or not characterState or type(characterState) ~= "table" then
        CureEcho("[CharState] WARNING: Failed to parse state file - creating fresh state")
        CureEcho("[CharState] Parse error: " .. tostring(result))
        return CreateCharacterStateFromConfig(helperConfigs)
    end
    
    CureEcho("[CharState] ✓ Successfully loaded character state from file")
    return characterState
end

-- ===============================================
-- Update Character Status
-- ===============================================
local function UpdateCharacterStatus(characterTable, helperName, newStatus)
    if not helperName or helperName == "" then
        CureEcho("[CharState] ERROR: No helper name provided")
        return false
    end
    
    CureEcho("[CharState] DEBUG: Updating status for: " .. helperName .. " to " .. newStatus)
    helperName = tostring(helperName):lower()
    
    for i, entry in ipairs(characterTable) do
        if entry[1] and entry[1][1] then
            local entryName = tostring(entry[1][1]):lower()
            if entryName == helperName then
                CureEcho("[CharState] DEBUG: Found match at index " .. i)
                entry[3] = newStatus
                local saveSuccess = SaveCharacterState(characterTable)
                if saveSuccess then
                    CureEcho("[CharState] ✓ Updated: " .. helperName .. " - Status: " .. newStatus)
                else
                    CureEcho("[CharState] ERROR: Failed to save after update")
                end
                return saveSuccess
            end
        end
    end
    
    CureEcho("[CharState] WARNING: Could not find helper: " .. helperName)
    CureEcho("[CharState] DEBUG: Searched for: '" .. helperName .. "'")
    return false
end

-- ===============================================
-- Get Pending Characters (Status 0)
-- ===============================================
local function GetPendingCharacters(characterTable)
    local pending = {}
    
    for _, entry in ipairs(characterTable) do
        if entry[3] == 0 then
            table.insert(pending, entry)
        end
    end
    
    return pending
end

-- ===============================================
-- Get Completed Characters (Status 1)
-- ===============================================
local function GetCompletedCharacters(characterTable)
    local completed = {}
    
    for _, entry in ipairs(characterTable) do
        if entry[3] == 1 then
            table.insert(completed, entry)
        end
    end
    
    return completed
end

-- ===============================================
-- Save Reset Timestamp
-- ===============================================
local function SaveResetTimestamp(characterTable, timestamp)
    if not timestamp or timestamp == "" then
        CureEcho("[CharState] ERROR: Invalid timestamp provided")
        return false
    end
    
    -- Update global timestamp variable
    lastResetTimestamp = timestamp
    
    -- Save the character state with updated timestamp
    local success = SaveCharacterState(characterTable)
    if success then
        CureEcho("[CharState] ✓ Reset timestamp saved: " .. timestamp)
    else
        CureEcho("[CharState] ERROR: Failed to save reset timestamp")
    end
    
    return success
end

-- ===============================================
-- Get Last Reset Time
-- ===============================================
local function GetLastResetTime()
    return lastResetTimestamp
end

-- ===============================================
-- Check if Reset Occurred Today
-- ===============================================
local function HasResetOccurredToday(characterTable, resetHour)
    if not lastResetTimestamp or lastResetTimestamp == "Never" then
        CureEcho("[CharState] No reset timestamp found - reset has not occurred yet")
        return false
    end
    
    -- Parse the reset timestamp (format: "YYYY-MM-DD HH:MM:SS")
    local year, month, day, hour, min, sec = lastResetTimestamp:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    
    if not year then
        CureEcho("[CharState] WARNING: Could not parse reset timestamp: " .. lastResetTimestamp)
        return false
    end
    
    -- Get current time
    local currentTime = os.date("*t")
    local currentYear = currentTime.year
    local currentMonth = currentTime.month
    local currentDay = currentTime.day
    local currentHour = currentTime.hour
    
    -- Convert to numbers
    year = tonumber(year)
    month = tonumber(month)
    day = tonumber(day)
    hour = tonumber(hour)
    
    -- Check if reset happened today
    if year == currentYear and month == currentMonth and day == currentDay then
        -- Reset timestamp is from today
        CureEcho("[CharState] ✓ Reset already occurred today at " .. lastResetTimestamp)
        return true
    end
    
    -- Check if we're past the reset hour today (and reset was from yesterday or earlier)
    if currentHour >= resetHour then
        -- We're past reset time today, but reset timestamp is from a previous day
        CureEcho("[CharState] Reset timestamp is from " .. lastResetTimestamp .. " (not today)")
        CureEcho("[CharState] Current time is past reset hour (" .. resetHour .. ":00) - reset needed")
        return false
    end
    
    -- We're before reset time today, check if reset was from yesterday after reset hour
    -- If reset was yesterday after reset hour, it counts as "today's" reset
    local resetDate = os.time({year=year, month=month, day=day, hour=hour, min=tonumber(min), sec=tonumber(sec)})
    local currentDate = os.time(currentTime)
    local hoursSinceReset = (currentDate - resetDate) / 3600
    
    if hoursSinceReset < 24 and hour >= resetHour then
        -- Reset was within last 24 hours and after reset hour
        CureEcho("[CharState] ✓ Reset occurred " .. string.format("%.1f", hoursSinceReset) .. " hours ago (still valid)")
        return true
    end
    
    CureEcho("[CharState] Reset timestamp is old (" .. lastResetTimestamp .. ") - reset needed")
    return false
end

-- ===============================================
-- Reset All Character Status to 0
-- ===============================================
local function ResetAllCharacterStatus(characterTable, confirmCallback)
    if confirmCallback and type(confirmCallback) == "function" then
        local confirmed = confirmCallback()
        if not confirmed then
            CureEcho("[CharState] Reset cancelled by user")
            return false
        end
    end
    
    local timestamp = os.date("%H:%M:%S")
    
    for _, entry in ipairs(characterTable) do
        entry[3] = 0
    end
    
    -- Save reset timestamp
    local currentTimestamp = os.date("%Y-%m-%d %H:%M:%S")
    SaveResetTimestamp(characterTable, currentTimestamp)
    
    CureEcho("[CharState] === RESET: All " .. #characterTable .. " characters reset to status 0 at " .. timestamp .. " ===")
    return true
end

-- ===============================================
-- Display Character State
-- ===============================================
local function DisplayCharacterState(characterTable)
    if not characterTable or #characterTable == 0 then
        CureEcho("[CharState] No character state data available")
        return
    end
    
    local completed = 0
    local pending = 0
    
    CureEcho("[CharState] ========== CHARACTER STATE ==========")
    
    for i, entry in ipairs(characterTable) do
        local helper = tostring(entry[1][1])
        local main = tostring(entry[2])
        local status = entry[3]
        local level = entry[4] or 90
        local statusStr = status == 1 and "✓ DONE" or "✗ PENDING"
        
        if status == 1 then
            completed = completed + 1
        else
            pending = pending + 1
        end
        
        CureEcho(string.format("[CharState] %d. %s -> %s [%s] (Lvl %d)", i, helper, main, statusStr, level))
    end
    
    CureEcho("[CharState] ====================================")
    CureEcho(string.format("[CharState] Summary: %d completed, %d pending", completed, pending))
end

-- ===============================================
-- Validate and Sync with Config
-- ===============================================
local function ValidateAndSyncCharacterState(characterTable, helperConfigs)
    local configHelpers = {}
    
    -- Map all helpers from config
    for _, config in ipairs(helperConfigs) do
        if config[1] and config[1][1] then
            configHelpers[tostring(config[1][1]):lower()] = config
        end
    end
    
    local addedCount = 0
    
    -- Check for new helpers in config not in state
    for _, config in ipairs(helperConfigs) do
        if config[1] and config[1][1] and config[2] then
            local helperLower = tostring(config[1][1]):lower()
            local found = false
            
            for _, entry in ipairs(characterTable) do
                if entry[1] and entry[1][1] and tostring(entry[1][1]):lower() == helperLower then
                    found = true
                    break
                end
            end
            
            if not found then
                local level = (config[4] and tonumber(config[4])) or 90
                table.insert(characterTable, {config[1], config[2], 0, level})
                CureEcho("[CharState] Added new helper: " .. config[1][1] .. " (Lvl " .. level .. ")")
                addedCount = addedCount + 1
            end
        end
    end
    
    if addedCount > 0 then
        SaveCharacterState(characterTable)
        CureEcho("[CharState] Synced with config - added " .. addedCount .. " new helper(s)")
    end
    
    return characterTable
end

-- ===============================================
-- Trial Duty Farming Functions
-- ===============================================

-- Get character with lowest level (ignores status)
local function GetLowestLevelCharacter(characterTable)
    if not characterTable or #characterTable == 0 then
        CureEcho("[TrialDuty] ERROR: No characters in table")
        return nil
    end
    
    local lowestLevel = nil
    local lowestChar = nil
    local lowestIndex = nil
    
    for i, entry in ipairs(characterTable) do
        local level = entry[4] or 90
        local charName = entry[1] and entry[1][1]
        
        if charName then
            if not lowestLevel or level < lowestLevel then
                lowestLevel = level
                lowestChar = charName
                lowestIndex = i
            end
        end
    end
    
    if lowestChar then
        CureEcho("[TrialDuty] Selected lowest level character: " .. lowestChar .. " (Level " .. lowestLevel .. ")")
        return {characterName = lowestChar, level = lowestLevel, index = lowestIndex}
    end
    
    return nil
end

-- Update character level in state
local function UpdateCharacterLevel(characterTable, helperName)
    if not helperName or helperName == "" then
        CureEcho("[TrialDuty] ERROR: No helper name provided for level update")
        return nil
    end
    
    -- Get current level from game
    local currentLevel = CureGetCurrentLevel()
    if not currentLevel then
        CureEcho("[TrialDuty] WARNING: Could not retrieve current level")
        return nil
    end
    
    helperName = tostring(helperName):lower()
    
    for i, entry in ipairs(characterTable) do
        if entry[1] and entry[1][1] then
            local entryName = tostring(entry[1][1]):lower()
            if entryName == helperName then
                local oldLevel = entry[4] or 90
                entry[4] = currentLevel
                
                local saveSuccess = SaveCharacterState(characterTable)
                if saveSuccess then
                    CureEcho("[TrialDuty] Updated level for " .. helperName .. ": " .. oldLevel .. " -> " .. currentLevel)
                else
                    CureEcho("[TrialDuty] ERROR: Failed to save level update")
                end
                
                return currentLevel
            end
        end
    end
    
    CureEcho("[TrialDuty] WARNING: Could not find helper: " .. helperName)
    return nil
end

-- Log character level for duty tracking
local function LogCharacterLevelForDuty(characterTable, helperName)
    if not helperName or helperName == "" then
        CureEcho("[TrialDuty] ERROR: No helper name provided for logging")
        return
    end
    
    helperName = tostring(helperName):lower()
    
    for _, entry in ipairs(characterTable) do
        if entry[1] and entry[1][1] then
            local entryName = tostring(entry[1][1]):lower()
            if entryName == helperName then
                local level = entry[4] or 90
                CureEcho("[TrialDuty] Character: " .. entry[1][1] .. ", Level: " .. level)
                return
            end
        end
    end
    
    CureEcho("[TrialDuty] WARNING: Could not find helper: " .. helperName)
end

-- ===============================================
-- NAMESPACE EXPORT
-- ===============================================
CureCharacterState = {
    Load = LoadCharacterState,
    Save = SaveCharacterState,
    UpdateStatus = UpdateCharacterStatus,
    GetPending = GetPendingCharacters,
    GetCompleted = GetCompletedCharacters,
    ResetAll = ResetAllCharacterStatus,
    Display = DisplayCharacterState,
    ValidateAndSync = ValidateAndSyncCharacterState,
    HasResetOccurredToday = HasResetOccurredToday,
    GetLastResetTime = GetLastResetTime,
    SaveResetTimestamp = SaveResetTimestamp,
    -- Trial Duty Functions
    GetLowestLevelCharacter = GetLowestLevelCharacter,
    UpdateCharacterLevel = UpdateCharacterLevel,
    LogCharacterLevelForDuty = LogCharacterLevelForDuty
}

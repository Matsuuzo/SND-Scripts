----------------------------------------------------------------------------------------------------------------------------
-- 
-- ██████╗ ██████╗ ███████╗ █████╗ ███╗   ███╗
-- ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗ ████║
-- ██║  ██║██████╔╝█████╗  ███████║██╔████╔██║
-- ██║  ██║██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
-- ██████╔╝██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
-- ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
--                                                                          
--  █████╗ ██████╗      █████╗ ██╗   ██╗████████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
-- ██╔══██╗██╔══██╗    ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
-- ███████║██║  ██║    ███████║██║   ██║   ██║   ██║   ██║██╔████╔██║███████║   ██║   ██║██║   ██║██╔██╗ ██║
-- ██╔══██║██║  ██║    ██╔══██║██║   ██║   ██║   ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
-- ██║  ██║██████╔╝    ██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
-- ╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
--                                                                                                              
-- ██╗  ██╗███████╗██╗     ██████╗ ██╗███╗   ██╗ ██████╗ 
-- ██║  ██║██╔════╝██║     ██╔══██╗██║████╗  ██║██╔════╝ 
-- ███████║█████╗  ██║     ██████╔╝██║██╔██╗ ██║██║  ███╗
-- ██╔══██║██╔══╝  ██║     ██╔═══╝ ██║██║╚██╗██║██║   ██║
-- ██║  ██║███████╗███████╗██║     ██║██║ ╚████║╚██████╔╝
-- ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
--
-- Automatically handles character rotation, DC travel, party verification, and duty automation
-- Version: 1.1.0
-- Last Updated: 2025-10-12
-- Added: Death handler, improved daily reset handling, midnight flag reset

----------------------------------------------------------------------------------------------------------------------------
---- PLUGIN REQUIREMENTS ----
----------------------------------------------------------------------------------------------------------------------------
-- REQUIRED PLUGINS:
-- • TextAdvance - For automatic text interaction
-- • Autoduty - For Automatic Duty handling
-- • AutoRetainer - For character switching and relog functionality
-- • Lifestream - For world travel and DC travel systems
-- • BossMod (Veyn) - For combat mechanics handling
-- • vnav - For navigation and pathfinding capabilities
-- • BardToolbox (BTB) - For party management

-- Dalamud Profile called "BTB" only using BardToolBox

require("dfunc")
require("xafunc")

-- ===============================================
-- Configuration
-- ===============================================

-- Helper character list with assigned main character - Format: {{"HelperChar@World"}, "Inviting Char"}
local helperConfigs = {
{{"Helper One@World"}, "Inviting CharOne"},
{{"Helper Two@World"}, "Inviting CharTwo"},
{{"Helper Three@World"}, "Inviting CharThree"}
}

-- DC Travel Configuration
local dcTravelWorld = "World"              -- Target world for DC travel

-- Party Verification Settings
local partyCheckInterval = 5                   -- Seconds between party checks
local partyCheckTimeout = 1500                 -- Maximum wait time for party invite (30 minutes)

-- Submarine monitoring state
local enableSubmarineCheck = true
local submarineCheckInterval = 90
local lastSubmarineCheck = 0
local submarinesPaused = false
local submarineReloginInProgress = false
local submarineReloginAttempts = 0
local maxSubmarineReloginAttempts = 3
local originalHelperForSubmarines = nil         -- Track which helper we need to return to

-- Daily Reset Configuration
local dailyResetHour = 17                     -- Reset hour in UTC+1 (17:00 = 5 PM)
local dailyResetCheckInterval = 10            -- Check every 10 seconds when waiting for reset
local lastDailyResetCheck = 0
local dailyResetTriggered = false            -- Track if reset has been triggered today (resets at midnight)
local lastMidnightCheck = 0
local midnightCheckInterval = 60             -- Check for midnight every 60 seconds
local allHelpersCompleted = false            -- Track if all helpers are done

-- =======================================
-- DO NOT TOUCH ANYTHING BELOW THIS
-- =======================================

-- Relog settings
local relogWaitTime = 3
local maxRelogAttempts = 3
local dutyDelay = 3

-- Movement check interval (in seconds)
local movementCheckInterval = 60
local lastMovementCheck = 0

-- Death tracking
local lastDeathCheck = 0
local deathCheckInterval = 1  -- Check every second

-- Internal state tracking
local currentHelper = helperConfigs[1] and helperConfigs[1][1] and helperConfigs[1][1][1] and tostring(helperConfigs[1][1][1]):lower() or ""
local currentToon = helperConfigs[1] and helperConfigs[1][2] and tostring(helperConfigs[1][2]) or ""
local idx = 1
local rotationStarted = true
local wasInDuty = false
local adRunActive = false
local failedHelpers = {}          -- Hard failures (login failed, etc)
local skippedHelpers = {}         -- Soft failures (no invite timeout)
local completedHelpers = {}
local dcTravelCompleted = false
local waitingForInvite = false
local consecutiveTimeouts = 0     -- Track consecutive timeout skips
local maxConsecutiveTimeouts = 2  -- Allow 2 timeouts before Multi Mode

-- ===============================================
-- Death Handler Functions
-- ===============================================

local function IsPlayerDead()
    if Svc and Svc.Condition then
        if type(Svc.Condition.IsDeath) == "function" then
            local ok, res = pcall(Svc.Condition.IsDeath, Svc.Condition)
            if ok then return res end
        end
        -- fallback: condition index 2
        return Svc.Condition[2] == true
    end
    return false
end

local function HandleDeath()
    EchoXA("[Death] Player death detected - initiating revival...")
    
    -- Wait for SelectYesno dialog to appear
    SleepXA(1.5)
    
    -- Click Yes on revival prompt
    SelectYesnoXA()
    
    -- Wait for player to be alive again
    local attempts = 0
    local maxAttempts = 30  -- 30 seconds timeout
    
    while IsPlayerDead() and attempts < maxAttempts do
        SleepXA(1)
        attempts = attempts + 1
    end
    
    if attempts >= maxAttempts then
        EchoXA("[Death] WARNING: Revival timeout - player may still be dead")
        return false
    end
    
    EchoXA("[Death] Player revived successfully")
    
    -- Wait for character to stabilize
    SleepXA(2)
    
    -- Restart AutoDuty if we were in a duty
    if adRunActive then
        EchoXA("[Death] Restarting AutoDuty after death...")
        adXA("start")
        SleepXA(1)
    end
    
    return true
end

-- ===============================================
-- Party Verification Functions
-- ===============================================

local function GetPartyMemberNames()
    local members = {}
    
    if not Svc or not Svc.Party then
        EchoXA("[Helper] ERROR: Svc.Party not available")
        return members
    end
    
    local partySize = Svc.Party.Length
    
    for i = 0, partySize - 1 do
        local member = Svc.Party[i]
        if member and member.Name and member.Name.TextValue then
            local memberName = tostring(member.Name.TextValue)
            if memberName and memberName ~= "" then
                table.insert(members, memberName)
            end
        end
    end
    
    return members
end

local function IsToonInParty(toonName)
    if not toonName or toonName == "" then
        EchoXA("[Helper] No toon specified - skipping verification")
        return false
    end
    
    local members = GetPartyMemberNames()
    local toonLower = tostring(toonName):lower()
    
    for _, memberName in ipairs(members) do
        if memberName and tostring(memberName):lower() == toonLower then
            return true
        end
    end
    
    return false
end

local function IsInParty()
    if not Svc or not Svc.Party then
        return false
    end
    
    return Svc.Party.Length > 1
end

local function ListPartyMembers()
    local members = GetPartyMemberNames()
    local partySize = #members
    
    if partySize == 0 then
        EchoXA("[Helper] Solo (no party members)")
        return
    end
    
    EchoXA("[Helper] Party has " .. partySize .. " member(s):")
    for i, name in ipairs(members) do
        EchoXA("[Helper]   " .. i .. ". " .. name)
    end
end

local function FindHelperForMainCharacter(mainCharName)
    if not mainCharName or mainCharName == "" then
        return nil, nil
    end
    
    local mainCharLower = tostring(mainCharName):lower()
    
    for i, config in ipairs(helperConfigs) do
        local assignedMain = config[2] and tostring(config[2]):lower() or ""
        if assignedMain == mainCharLower then
            return i, config[1][1]
        end
    end
    
    return nil, nil
end

local function WaitForPartyInvite(timeout)
    EchoXA("[Helper] === WAITING FOR PARTY INVITE ===")
    EchoXA("[Helper] Will accept ANY party invite and determine correct helper")
    EchoXA("[Helper] Timeout: " .. timeout .. " seconds")
    
    local startTime = os.time()
    local lastCheck = 0
    
    while os.time() - startTime < timeout do
        -- Check if we're in a party
        if IsInParty() then
            EchoXA("[Helper] ✓ Party invite received!")
            SleepXA(2)
            
            -- Get all party members
            local members = GetPartyMemberNames()
            ListPartyMembers()
            
            -- Find which main character is in the party
            local foundMainChar = nil
            local foundHelperIdx = nil
            local foundHelperName = nil
            
            for _, memberName in ipairs(members) do
                local helperIdx, helperName = FindHelperForMainCharacter(memberName)
                if helperIdx then
                    foundMainChar = memberName
                    foundHelperIdx = helperIdx
                    foundHelperName = helperName
                    break
                end
            end
            
            if foundMainChar then
                EchoXA("[Helper] ✓ Found main character in party: " .. foundMainChar)
                EchoXA("[Helper] ✓ This party needs helper: " .. foundHelperName)
                return true, "found", foundMainChar, foundHelperIdx, foundHelperName
            else
                EchoXA("[Helper] ✗ No recognized main character in party!")
                EchoXA("[Helper] Party members are not in the helper configuration")
                return true, "unknown", nil, nil, nil
            end
        end
        
        -- Progress update every 30 seconds
        local elapsed = os.time() - startTime
        if elapsed - lastCheck >= 30 then
            local remaining = timeout - elapsed
            EchoXA("[Helper] Still waiting for invite... (" .. remaining .. " seconds remaining)")
            lastCheck = elapsed
        end
        
        SleepXA(1)
    end
    
    EchoXA("[Helper] ✗ TIMEOUT: No party invite received after " .. timeout .. " seconds")
    return false, "timeout", nil, nil, nil
end

-- ===============================================
-- Daily Reset Functions
-- ===============================================

local function CheckMidnight()
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    -- Reset the dailyResetTriggered flag after midnight (when hour < dailyResetHour)
    if currentHour < dailyResetHour and dailyResetTriggered then
        EchoXA("[DailyReset] === MIDNIGHT PASSED - RESET FLAG CLEARED ===")
        EchoXA("[DailyReset] Daily reset will be available again at " .. dailyResetHour .. ":00")
        dailyResetTriggered = false
        return true
    end
    
    return false
end

local function CheckDailyReset()
    -- Don't trigger if already triggered today
    if dailyResetTriggered then
        return false
    end
    
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    -- Check if it's past 17:00 UTC+1
    if currentHour >= dailyResetHour then
        return true
    end
    
    return false
end

local function ResetRotation()
    EchoXA("[DailyReset] === RESETTING HELPER ROTATION ===")
    
    -- Clear all completion and failure tracking
    failedHelpers = {}
    skippedHelpers = {}
    completedHelpers = {}
    consecutiveTimeouts = 0
    
    -- Reset flags
    allHelpersCompleted = false
    -- Don't reset dailyResetTriggered here - it stays true until midnight
    
    -- Reset to first helper
    idx = 1
    if helperConfigs[1] and helperConfigs[1][1] and helperConfigs[1][1][1] then
        currentHelper = tostring(helperConfigs[1][1][1]):lower()
        currentToon = helperConfigs[1][2] and tostring(helperConfigs[1][2]) or ""
    else
        EchoXA("[DailyReset] ERROR: First helper configuration is invalid")
        return false
    end
    
    EchoXA("[DailyReset] Rotation reset complete - starting from first helper")
    EchoXA("[DailyReset] First helper: " .. helperConfigs[1][1][1])
    EchoXA("[DailyReset] Expected toon: " .. currentToon)
    
    -- Relog to first helper
    if PerformCharacterRelog(helperConfigs[1][1][1], maxRelogAttempts) then
        EnableTextAdvanceXA()
        SleepXA(2)
        return true
    else
        EchoXA("[DailyReset] ERROR: Failed to relog to first helper")
        return false
    end
end

-- ===============================================
-- Submarine Monitoring Functions
-- ===============================================

local function GetConfigPath()
    local userprofile = os.getenv("USERPROFILE")
    if not userprofile or userprofile == "" then
        local username = os.getenv("USERNAME") or ""
        if username == "" then return nil end
        userprofile = "C:\\Users\\" .. username
    end
    return userprofile .. [[\AppData\Roaming\XIVLauncher\pluginConfigs\AutoRetainer\DefaultConfig.json]]
end

local function CheckSubmarines()
    if not enableSubmarineCheck then return false end
    
    local configPath = GetConfigPath()
    if not configPath then
        EchoXA("[Subs] Could not resolve config path")
        return false
    end
    
    local file, err = io.open(configPath, "r")
    if not file then
        EchoXA("[Subs] Could not open config: " .. tostring(err))
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content or content == "" then
        EchoXA("[Subs] Config file is empty")
        return false
    end
    
    local returnTimes = {}
    for ts in content:gmatch([["ReturnTime"%s*:%s*(%d+)]]) do
        returnTimes[#returnTimes+1] = tonumber(ts)
    end
    
    if #returnTimes == 0 then
        return false
    end
    
    local now = os.time()
    local available = 0
    local minDelta = nil
    
    for _, ts in ipairs(returnTimes) do
        local d = ts - now
        if d <= 0 then
            available = available + 1
        else
            if not minDelta or d < minDelta then minDelta = d end
        end
    end
    
    if available > 0 then
        local plural = available == 1 and "Sub" or "Subs"
        EchoXA(string.format("[Subs] %d %s available - submarine mode activated!", available, plural))
        return true
    end
    
    if minDelta and minDelta > 0 then
        local minutes = math.max(0, math.ceil(minDelta / 60))
        local plural = minutes == 1 and "minute" or "minutes"
        EchoXA(string.format("[Subs] Next submarine in %d %s", minutes, plural))
    end
    
    return false
end

local function CheckSubmarineReloginComplete()
    if not submarineReloginInProgress then
        return true
    end
    
    -- Check if we have a valid original helper stored
    if not originalHelperForSubmarines or originalHelperForSubmarines == "" then
        EchoXA("[Subs] WARNING: No original helper stored, marking submarine relogin as complete")
        submarineReloginInProgress = false
        return true
    end
    
    -- Verify current character matches original
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedName = originalHelperForSubmarines:match("^([^@]+)")
    
    if not expectedName then
        EchoXA("[Subs] WARNING: Could not extract expected name, marking submarine relogin as complete")
        submarineReloginInProgress = false
        originalHelperForSubmarines = nil
        return true
    end
    
    local actualLower = tostring(actualName):lower()
    local expectedLower = tostring(expectedName):lower()
    
    if actualLower == expectedLower then
        EchoXA("[Subs] Submarine relogin verification passed")
        submarineReloginInProgress = false
        submarineReloginAttempts = 0
        originalHelperForSubmarines = nil  -- Reset after successful verification
        
        CharacterSafeWaitXA()
        
        submarinesPaused = false
        
        EchoXA("[Subs] === SAFETY VALIDATION COMPLETE ===")
        EchoXA("[Subs] Resuming normal rotation on original helper")
        
        return true
    else
        EchoXA("[Subs] WARNING: Character mismatch after submarines. Expected: " .. expectedName .. ", Actual: " .. actualName)
        EchoXA("[Subs] Marking submarine relogin as complete anyway to continue rotation")
        submarineReloginInProgress = false
        originalHelperForSubmarines = nil
        return true
    end
end

-- ===============================================
-- Duty Roulette Check Functions
-- ===============================================

local function CheckDutyRouletteReward()
    EchoXA("[Helper] === CHECKING DUTY ROULETTE REWARD STATUS ===")
    
    yield("/dutyfinder")
    SleepXA(2)
    
    callbackXA("ContentsFinder true 2 2 0")
    SleepXA(1)
    
    local rewardReceived = nil
    local success, err = pcall(function()
        local addon = Addons.GetAddon("JournalDetail")
        if addon then
            local node = addon:GetNode(1, 29, 30)
            if node and node.Text then
                rewardReceived = tostring(node.Text)
            end
        end
    end)
    
    if not success then
        EchoXA("[Helper] ERROR: Failed to read reward status - " .. tostring(err))
        callbackXA("ContentsFinder true -1")
        SleepXA(1)
        return false, "error"
    end
    
    EchoXA("[Helper] Reward Text: [" .. tostring(rewardReceived) .. "]")
    
    callbackXA("ContentsFinder true -1")
    SleepXA(1)
    
    if rewardReceived and rewardReceived ~= "" then
        EchoXA("[Helper] === ROULETTE COMPLETED (TEXT FOUND) ===")
        return true, "completed"
    else
        EchoXA("[Helper] === ROULETTE AVAILABLE (NO TEXT) ===")
        return true, "available"
    end
end

-- ===============================================
-- DC Travel Functions
-- ===============================================

local function PerformDCTravel()
    if dcTravelCompleted then
        EchoXA("[Helper] DC Travel already completed for this character")
        return true
    end
    
    EchoXA("[Helper] === INITIATING DATA CENTER TRAVEL ===")
    EchoXA("[Helper] Target world: " .. dcTravelWorld)
    
    LifestreamCmdXA(dcTravelWorld)
    
    EchoXA("[Helper] === DATA CENTER TRAVEL COMPLETE ===")
    EchoXA("[Helper] Now on world: " .. dcTravelWorld)
    
    EchoXA("[Helper] Teleporting to Summerford...")
    yield("/li Summerford")
    SleepXA(10)
    
    dcTravelCompleted = true
    return true
end

local function ReturnToHomeworld()
    if not dcTravelCompleted then
        EchoXA("[Helper] No DC travel was performed - skipping homeworld return")
        return true
    end
    
    EchoXA("[Helper] === RETURNING TO HOMEWORLD ===")
    
    return_to_homeworldXA()
    
    EchoXA("[Helper] === HOMEWORLD RETURN COMPLETE ===")
    dcTravelCompleted = false
    return true
end

-- ===============================================
-- Character Management Functions
-- ===============================================

local function VerifyCharacterSwitch(expectedName)
    if not expectedName or expectedName == "" then
        EchoXA("[Helper] ERROR: No expected name provided for verification")
        return false
    end
    
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedLower = tostring(expectedName):lower()
    local actualLower = tostring(actualName):lower()
    
    if actualLower == expectedLower then
        EchoXA("[Helper] Character switch verified: Now playing as " .. actualName)
        return true
    end
    
    EchoXA("[Helper] ERROR: Character switch failed! Expected: " .. expectedName .. ", Actual: " .. actualName)
    return false
end

local function PerformCharacterRelog(targetChar, maxRetries)
    if not targetChar or targetChar == "" then
        EchoXA("[Helper] ERROR: No target character specified")
        return false
    end
    
    maxRetries = maxRetries or maxRelogAttempts
    local expectedName = targetChar:match("^([^@]+)")
    
    if not expectedName then
        EchoXA("[Helper] ERROR: Could not extract character name from: " .. targetChar)
        return false
    end

    for attempt = 1, maxRetries do
        if attempt == 1 then
            EchoXA("[Helper] Relogging to " .. targetChar)
        else
            EchoXA("[Helper] Retry " .. (attempt-1) .. " - Relogging to " .. targetChar)
        end
        
        -- Use xafunc ARRelogXA which includes all necessary waits
        if ARRelogXA(targetChar) then
            if VerifyCharacterSwitch(expectedName) then
                dcTravelCompleted = false
                wasInDuty = false
                adRunActive = false
                waitingForInvite = false
                EchoXA("[Helper] Character state reset complete")
                return true
            end
        end
        
        if attempt < maxRetries then
            EchoXA("[Helper] Retrying relog in 5 seconds...")
            SleepXA(5)
        end
    end
    
    EchoXA("[Helper] FATAL: Character switch failed after " .. maxRetries .. " attempts!")
    return false
end

local function getHelperIndex(name)
    if not name or name == "" then
        return nil
    end
    
    name = tostring(name):lower()
    for i, c in ipairs(helperConfigs) do
        if c[1] and c[1][1] and tostring(c[1][1]):lower() == name then
            return i
        end
    end
    return nil
end

local function getNextAvailableHelper(currentIdx)
    local attempts = 0
    local nextIdx = currentIdx or 0
    
    EchoXA("[Helper] DEBUG: Looking for next helper. Current idx: " .. (currentIdx or "nil"))
    
    while attempts < #helperConfigs do
        nextIdx = nextIdx + 1
        if nextIdx > #helperConfigs then
            -- Reached end of rotation
            EchoXA("[Helper] DEBUG: Reached end of helper list")
            return nil, nil
        end
        
        local helperName = helperConfigs[nextIdx][1][1]
        local isFailed = failedHelpers[helperName] or false
        local isSkipped = skippedHelpers[helperName] or false
        local isCompleted = completedHelpers[helperName] or false
        
        EchoXA("[Helper] DEBUG: Checking helper " .. nextIdx .. ": " .. helperName .. 
               " (Failed: " .. tostring(isFailed) .. ", Skipped: " .. tostring(isSkipped) .. ", Completed: " .. tostring(isCompleted) .. ")")
        
        -- Available if: not failed AND not completed (skipped is okay!)
        if not isFailed and not isCompleted then
            EchoXA("[Helper] DEBUG: Found available helper: " .. helperName)
            return nextIdx, helperName
        end
        
        attempts = attempts + 1
    end
    
    EchoXA("[Helper] DEBUG: No available helpers found in remaining list")
    return nil, nil
end

local function attemptHelperLogin(targetIdx)
    local targetHelper = helperConfigs[targetIdx][1][1]
    EchoXA("[Helper] Attempting to log into: " .. targetHelper)
    
    if PerformCharacterRelog(targetHelper, maxRelogAttempts) then
        return true
    else
        failedHelpers[targetHelper] = true
        EchoXA("[Helper] FAILED: Helper " .. targetHelper .. " marked as failed after " .. maxRelogAttempts .. " attempts")
        return false
    end
end

local function reportRotationStatus()
    local totalHelpers = #helperConfigs
    local failedCount = 0
    local skippedCount = 0
    local completedCount = 0
    
    for _ in pairs(failedHelpers) do
        failedCount = failedCount + 1
    end
    
    for _ in pairs(skippedHelpers) do
        skippedCount = skippedCount + 1
    end
    
    for _ in pairs(completedHelpers) do
        completedCount = completedCount + 1
    end
    
    local remainingCount = totalHelpers - failedCount - completedCount
    
    EchoXA(string.format("[Helper] Rotation Status: %d/%d runs remaining (%d completed, %d failed, %d skipped)", 
        remainingCount, totalHelpers, completedCount, failedCount, skippedCount))
end

local function switchToNextHelper()
    reportRotationStatus()
    
    -- Check if we hit 2 consecutive timeouts
    if consecutiveTimeouts >= maxConsecutiveTimeouts then
        EchoXA("[Helper] === 2 CONSECUTIVE TIMEOUTS REACHED ===")
        EchoXA("[Helper] Main account stopped inviting")
        EchoXA("[Helper] Activating Multi Mode until daily reset...")
        
        EnableARMultiXA()
        allHelpersCompleted = true
        
        EchoXA("[Helper] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    -- Try to find next available helper
    local nextIdx, nextHelper = getNextAvailableHelper(idx)
    
    if not nextIdx then
        -- Reached end of helper list
        EchoXA("[Helper] === LAST CHARACTER REACHED ===")
        EchoXA("[Helper] Completed rotation through all helpers")
        EchoXA("[Helper] Activating Multi Mode until daily reset...")
        
        EnableARMultiXA()
        allHelpersCompleted = true
        
        EchoXA("[Helper] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    EchoXA("[Helper] Switching to next run: " .. nextHelper .. " (for " .. helperConfigs[nextIdx][2] .. ")")
    
    if attemptHelperLogin(nextIdx) then
        EchoXA("[Helper] DEBUG: Updating idx from " .. (idx or "nil") .. " to " .. nextIdx)
        if helperConfigs[nextIdx] and helperConfigs[nextIdx][1] and helperConfigs[nextIdx][1][1] then
            currentHelper = tostring(nextHelper):lower()
            currentToon = helperConfigs[nextIdx][2] and tostring(helperConfigs[nextIdx][2]) or ""
            idx = nextIdx
            
            EchoXA("[Helper] DEBUG: Current helper updated to: " .. currentHelper .. " (idx: " .. idx .. ")")
            EchoXA("[Helper] DEBUG: Expected toon: " .. currentToon)
        else
            EchoXA("[Helper] ERROR: Invalid helper configuration at index " .. nextIdx)
            return false
        end
        
        EnableTextAdvanceXA()
        SleepXA(2)
        
        return true
    else
        return switchToNextHelper()
    end
end

-- ===============================================
-- Helper Initialization
-- ===============================================

local function InitializeHelper()
    EchoXA("[Helper] === INITIALIZING HELPER ===")
    EchoXA("[Helper] Current Helper: " .. helperConfigs[idx][1][1])
    
    -- Step 1: Check if Duty Roulette reward already received
    EchoXA("[Helper] Step 1: Checking Duty Roulette reward status...")
    local checkSuccess, rewardStatus = CheckDutyRouletteReward()
    
    if not checkSuccess then
        EchoXA("[Helper] ERROR: Failed to check roulette status - marking helper as failed")
        local actualHelperName = helperConfigs[idx][1][1]
        failedHelpers[actualHelperName] = true
        EchoXA("[Helper] === HELPER INITIALIZATION ABORTED (ERROR) ===")
        return false
    end
    
    if rewardStatus == "completed" then
        EchoXA("[Helper] *** REWARD ALREADY RECEIVED - SKIPPING HELPER ***")
        local actualHelperName = helperConfigs[idx][1][1]
        completedHelpers[actualHelperName] = true
        EchoXA("[Helper] === HELPER INITIALIZATION ABORTED (COMPLETED) ===")
        return false
    end
    
    EchoXA("[Helper] Roulette available - proceeding with DC Travel and party wait")
    
    -- Step 2: Disable BTB (if enabled)
    EchoXA("[Helper] Step 2: Disabling BTB...")
    yield("/xldisableprofile BTB")
    SleepXA(2)
    CharacterSafeWaitXA()
    
    -- Step 3: Perform DC Travel
    EchoXA("[Helper] Step 3: Performing Data Center Travel...")
    PerformDCTravel()
    CharacterSafeWaitXA()
    
    -- Step 4: Enable BTB
    EchoXA("[Helper] Step 4: Enabling BTB...")
    yield("/xlenableprofile BTB")
    SleepXA(2)
    CharacterSafeWaitXA()
    
    -- Step 5: Wait for party invite and determine correct helper
    EchoXA("[Helper] Step 5: Waiting for party invite...")
    waitingForInvite = true
    local invited, status, foundMain, foundIdx, foundHelper = WaitForPartyInvite(partyCheckTimeout)
    waitingForInvite = false
    
    if not invited then
        EchoXA("[Helper] ERROR: No party invite received - marking current helper as SKIPPED (can retry later)")
        local actualHelperName = helperConfigs[idx][1][1]
        skippedHelpers[actualHelperName] = true
        consecutiveTimeouts = consecutiveTimeouts + 1
        EchoXA("[Helper] Consecutive timeouts: " .. consecutiveTimeouts .. "/" .. maxConsecutiveTimeouts)
        EchoXA("[Helper] === HELPER INITIALIZATION ABORTED (NO INVITE) ===")
        
        yield("/xldisableprofile BTB")
        SleepXA(2)
        ReturnToHomeworld()
        return false
    end
    
    if status == "unknown" then
        EchoXA("[Helper] ERROR: Party member not recognized in configuration")
        EchoXA("[Helper] === HELPER INITIALIZATION ABORTED (UNKNOWN MAIN) ===")
        EchoXA("[Helper] Marking as SKIPPED (can retry if needed)")
        
        local actualHelperName = helperConfigs[idx][1][1]
        skippedHelpers[actualHelperName] = true
        consecutiveTimeouts = consecutiveTimeouts + 1
        EchoXA("[Helper] Consecutive timeouts: " .. consecutiveTimeouts .. "/" .. maxConsecutiveTimeouts)
        
        yield("/xldisableprofile BTB")
        SleepXA(2)
        yield("/leave")
        SleepXA(2)
        ReturnToHomeworld()
        return false
    end
    
    -- Successfully got a valid invite - reset timeout counter
    consecutiveTimeouts = 0
    EchoXA("[Helper] Valid invite received - timeout counter reset")
    
    -- Check if we need to switch to a different helper
    if foundIdx ~= idx then
        EchoXA("[Helper] ✓ Party has main character: " .. foundMain)
        EchoXA("[Helper] ✓ This requires helper: " .. foundHelper)
        EchoXA("[Helper] ⚠ Current helper is wrong - switching now...")
        
        -- Leave party and return home
        yield("/xldisableprofile BTB")
        SleepXA(2)
        yield("/leave")
        SleepXA(2)
        ReturnToHomeworld()
        
        -- Check if target helper is already completed or failed
        if completedHelpers[foundHelper] then
            EchoXA("[Helper] ✗ Required helper already completed: " .. foundHelper)
            EchoXA("[Helper] Cannot switch to completed helper")
            EchoXA("[Helper] Marking current helper as SKIPPED")
            local actualHelperName = helperConfigs[idx][1][1]
            skippedHelpers[actualHelperName] = true
            return false
        end
        
        if failedHelpers[foundHelper] then
            EchoXA("[Helper] ✗ Required helper marked as HARD FAILED: " .. foundHelper)
            EchoXA("[Helper] Cannot switch to hard failed helper")
            EchoXA("[Helper] Marking current helper as SKIPPED")
            local actualHelperName = helperConfigs[idx][1][1]
            skippedHelpers[actualHelperName] = true
            return false
        end
        
        -- Check if target helper was skipped - if so, CLEAR the skip flag!
        if skippedHelpers[foundHelper] then
            EchoXA("[Helper] ✓ Required helper was SKIPPED earlier: " .. foundHelper)
            EchoXA("[Helper] Clearing skip flag - this helper is now needed!")
            skippedHelpers[foundHelper] = nil
        end
        
        -- Switch to the correct helper
        EchoXA("[Helper] Switching to correct helper: " .. foundHelper)
        if PerformCharacterRelog(foundHelper, maxRelogAttempts) then
            -- Clear skip flag if it was set
            if skippedHelpers[foundHelper] then
                EchoXA("[Helper] Clearing skip flag for: " .. foundHelper)
                skippedHelpers[foundHelper] = nil
            end
            
            idx = foundIdx
            currentHelper = tostring(foundHelper):lower()
            currentToon = foundMain
            
            EchoXA("[Helper] ✓ Successfully switched to correct helper!")
            EchoXA("[Helper] Now running as: " .. foundHelper)
            EchoXA("[Helper] For main character: " .. foundMain)
            
            EnableTextAdvanceXA()
            SleepXA(2)
            
            -- Restart initialization with correct helper
            return InitializeHelper()
        else
            EchoXA("[Helper] ERROR: Failed to switch to correct helper")
            failedHelpers[foundHelper] = true
            return false
        end
    end
    
    -- Current helper is correct
    EchoXA("[Helper] ✓ Correct helper for main character: " .. foundMain)
    EchoXA("[Helper] === HELPER INITIALIZATION COMPLETE ===")
    EchoXA("[Helper] Ready for duty!")
    return true
end

-- ===============================================
-- Initialize rotation
-- ===============================================

idx = getHelperIndex(currentHelper)
if not idx then
    EchoXA("[Helper] Start helper not in rotation: " .. currentHelper)
    -- Try to start with first helper
    idx = 1
    currentHelper = helperConfigs[1][1][1] and tostring(helperConfigs[1][1][1]):lower() or ""
    currentToon = helperConfigs[1][2] and tostring(helperConfigs[1][2]) or ""
end

local loginSuccess = false
local currentIdx = idx

EchoXA("[Helper] === STARTING HELPER AUTOMATION WITH ROTATION ===")
EchoXA("[Helper] Daily Reset Time: " .. dailyResetHour .. ":00 UTC+1")
EchoXA("[Helper] Starting helper rotation...")
reportRotationStatus()

-- Initial login
while not loginSuccess and #failedHelpers < #helperConfigs do
    if attemptHelperLogin(currentIdx) then
        loginSuccess = true
        idx = currentIdx
        currentToon = helperConfigs[idx][2] and tostring(helperConfigs[idx][2]) or ""
        EchoXA("[Helper] Successfully logged into: " .. helperConfigs[idx][1][1])
        EchoXA("[Helper] Expected toon: " .. currentToon)
    else
        local nextIdx, nextHelper = getNextAvailableHelper(currentIdx)
        if nextIdx then
            EchoXA("[Helper] Trying next helper: " .. nextHelper)
            currentIdx = nextIdx
        else
            EchoXA("[Helper] FATAL: All helpers have failed login attempts!")
            return
        end
    end
end

if not loginSuccess then
    EchoXA("[Helper] FATAL: Unable to log into any helper. Stopping script.")
    return
end

-- Initialize first helper
CharacterSafeWaitXA()
EnableTextAdvanceXA()
SleepXA(2)

local initSuccess = InitializeHelper()

-- If first helper initialization failed, keep trying
while not initSuccess and rotationStarted do
    EchoXA("[Helper] Initialization failed - trying next helper")
    if not switchToNextHelper() then
        EchoXA("[Helper] No more helpers available. Stopping script.")
        return
    end
    initSuccess = InitializeHelper()
end

if not initSuccess then
    EchoXA("[Helper] All helpers failed initialization. Stopping script.")
    return
end

-- ===============================================
-- Main Loop
-- ===============================================

EchoXA("[Helper] === ENTERING MAIN LOOP ===")

while rotationStarted do
    local inDuty = false
    
    -- === DEATH CHECK ===
    if IsPlayerDead() then
        EchoXA("[Death] === DEATH DETECTED ===")
        HandleDeath()
    end
    
    -- === MIDNIGHT CHECK (Reset the dailyResetTriggered flag) ===
    local currentTime = os.time()
    if currentTime - lastMidnightCheck >= midnightCheckInterval then
        lastMidnightCheck = currentTime
        CheckMidnight()
    end
    
    -- === DAILY RESET CHECK (when all helpers are done and waiting) ===
    if allHelpersCompleted then
        if currentTime - lastDailyResetCheck >= dailyResetCheckInterval then
            lastDailyResetCheck = currentTime
            
            if CheckDailyReset() and not dailyResetTriggered then
                EchoXA("[DailyReset] === DAILY RESET TRIGGERED (All Helpers Idle) ===")
                dailyResetTriggered = true
                
                DisableARMultiXA()
                SleepXA(2)
                
                if ResetRotation() then
                    allHelpersCompleted = false
                    
                    local initSuccess = InitializeHelper()
                    
                    while not initSuccess and rotationStarted do
                        EchoXA("[Helper] Helper skipped after reset - trying next helper...")
                        if not switchToNextHelper() then
                            EchoXA("[Helper] All helpers already completed after reset.")
                            allHelpersCompleted = true
                            break
                        end
                        initSuccess = InitializeHelper()
                    end
                else
                    EchoXA("[DailyReset] ERROR: Failed to reset rotation")
                end
            end
        end
        
        -- If all helpers completed, just sleep and continue checking for reset
        SleepXA(5)
        goto continue_loop
    end
    
    -- Check duty status
    if Player ~= nil and Player.IsInDuty ~= nil then
        if type(Player.IsInDuty) == "function" then
            inDuty = Player.IsInDuty()
        else
            inDuty = Player.IsInDuty
        end
    end

    -- Handle duty state changes
    if inDuty and not wasInDuty then
        EchoXA("[Helper] === ENTERED DUTY ===")
        SleepXA(dutyDelay)
        
        if not adRunActive then
            adXA("start")
            adRunActive = true
            EchoXA("[Helper] AutoDuty started after entering duty")
        end
        
        vbmaiXA("on")
        SleepXA(3)
        FullStopMovementXA()
        EchoXA("[Helper] Movement stopped after entering duty")
        
        lastMovementCheck = os.time()
        
    elseif not inDuty and wasInDuty then
        EchoXA("[Helper] === LEFT DUTY ===")
        adRunActive = false
        SleepXA(1)
        adXA("stop")
        EchoXA("[Helper] Left duty - AutoDuty reset")
        
        EchoXA("[Helper] Disabling BTB...")
        yield("/xldisableprofile BTB")
        SleepXA(2)
        
        EchoXA("[Helper] Disbanding party...")
        BTBDisbandXA()
        SleepXA(5)
        
        EchoXA("[Helper] Returning to homeworld...")
        ReturnToHomeworld()
        SleepXA(2)
        
        -- === CHECK FOR DAILY RESET AFTER DUTY ===
        if CheckDailyReset() and not dailyResetTriggered then
            EchoXA("[DailyReset] === DAILY RESET DETECTED AFTER DUTY COMPLETION ===")
            dailyResetTriggered = true
            
            EchoXA("[DailyReset] Current helper completed duty after reset time")
            EchoXA("[DailyReset] Marking current helper as completed for today...")
            local actualHelperName = helperConfigs[idx][1][1]
            completedHelpers[actualHelperName] = true
            
            EchoXA("[DailyReset] Resetting rotation to first helper...")
            if allHelpersCompleted then
                DisableARMultiXA()
                SleepXA(2)
            end
            
            if ResetRotation() then
                allHelpersCompleted = false
                
                local initSuccess = InitializeHelper()
                
                while not initSuccess and rotationStarted do
                    EchoXA("[Helper] Helper skipped after reset - trying next helper...")
                    if not switchToNextHelper() then
                        EchoXA("[Helper] All helpers already completed after reset.")
                        allHelpersCompleted = true
                        break
                    end
                    initSuccess = InitializeHelper()
                end
                
                goto continue_loop
            else
                EchoXA("[DailyReset] ERROR: Failed to reset rotation")
            end
        end
        
        -- === DUTY COMPLETION VERIFICATION ===
        EchoXA("[Helper] === VERIFYING DUTY COMPLETION ===")
        local checkSuccess, rewardStatus = CheckDutyRouletteReward()
        
        if not checkSuccess then
            EchoXA("[Helper] ERROR: Failed to verify duty completion")
            -- Continue anyway to avoid getting stuck
        elseif rewardStatus == "available" then
            EchoXA("[Helper] WARNING: DUTY INCOMPLETE - REWARD NOT RECEIVED!")
            EchoXA("[Helper] Character got stuck or duty failed - retrying...")
            
            -- Don't mark as completed, retry the duty
            EchoXA("[Helper] Performing DC Travel again...")
            PerformDCTravel()
            CharacterSafeWaitXA()
            
            EchoXA("[Helper] Enabling BTB...")
            yield("/xlenableprofile BTB")
            SleepXA(2)
            CharacterSafeWaitXA()
            
            EchoXA("[Helper] Waiting for party invite again...")
            waitingForInvite = true
            local invited, status, foundMain, foundIdx, foundHelper = WaitForPartyInvite(partyCheckTimeout)
            waitingForInvite = false
            
            if not invited or status == "unknown" then
                EchoXA("[Helper] ERROR: Party verification failed on retry!")
                EchoXA("[Helper] Marking helper as SKIPPED (timeout/unknown party)...")
                local actualHelperName = helperConfigs[idx][1][1]
                skippedHelpers[actualHelperName] = true
                
                yield("/xldisableprofile BTB")
                SleepXA(2)
                if IsInParty() then
                    yield("/leave")
                    SleepXA(2)
                end
                ReturnToHomeworld()
                
                EchoXA("[Helper] Switching to next helper...")
                if not switchToNextHelper() then
                    EchoXA("[Helper] No more helpers available.")
                    break
                end
                
                local initSuccess = InitializeHelper()
                while not initSuccess and rotationStarted do
                    EchoXA("[Helper] Initialization failed - trying next helper...")
                    if not switchToNextHelper() then
                        EchoXA("[Helper] No more helpers available.")
                        rotationStarted = false
                        break
                    end
                    initSuccess = InitializeHelper()
                end
                goto continue_loop
            end
            
            -- Check if we need to switch helpers for retry
            if foundIdx ~= idx then
                EchoXA("[Helper] Party requires different helper: " .. foundHelper)
                EchoXA("[Helper] Current helper cannot complete this duty")
                
                yield("/xldisableprofile BTB")
                SleepXA(2)
                yield("/leave")
                SleepXA(2)
                ReturnToHomeworld()
                
                if completedHelpers[foundHelper] or failedHelpers[foundHelper] then
                    EchoXA("[Helper] Required helper unavailable - marking current as SKIPPED")
                    local actualHelperName = helperConfigs[idx][1][1]
                    skippedHelpers[actualHelperName] = true
                    
                    if not switchToNextHelper() then
                        EchoXA("[Helper] No more helpers available.")
                        break
                    end
                    
                    local initSuccess = InitializeHelper()
                    while not initSuccess and rotationStarted do
                        EchoXA("[Helper] Initialization failed - trying next helper...")
                        if not switchToNextHelper() then
                            EchoXA("[Helper] No more helpers available.")
                            rotationStarted = false
                            break
                        end
                        initSuccess = InitializeHelper()
                    end
                    goto continue_loop
                end
                
                -- Switch to correct helper
                if PerformCharacterRelog(foundHelper, maxRelogAttempts) then
                    -- Clear skip flag if it was set
                    if skippedHelpers[foundHelper] then
                        EchoXA("[Helper] Clearing skip flag for: " .. foundHelper)
                        skippedHelpers[foundHelper] = nil
                    end
                    
                    idx = foundIdx
                    currentHelper = tostring(foundHelper):lower()
                    currentToon = foundMain
                    
                    EnableTextAdvanceXA()
                    SleepXA(2)
                    
                    -- Initialize with correct helper
                    local initSuccess = InitializeHelper()
                    if not initSuccess then
                        EchoXA("[Helper] Failed to initialize correct helper")
                        if not switchToNextHelper() then
                            EchoXA("[Helper] No more helpers available.")
                            break
                        end
                        initSuccess = InitializeHelper()
                        while not initSuccess and rotationStarted do
                            if not switchToNextHelper() then
                                rotationStarted = false
                                break
                            end
                            initSuccess = InitializeHelper()
                        end
                    end
                    goto continue_loop
                else
                    failedHelpers[foundHelper] = true
                    local actualHelperName = helperConfigs[idx][1][1]
                    failedHelpers[actualHelperName] = true
                    
                    if not switchToNextHelper() then
                        break
                    end
                    
                    local initSuccess = InitializeHelper()
                    while not initSuccess and rotationStarted do
                        if not switchToNextHelper() then
                            rotationStarted = false
                            break
                        end
                        initSuccess = InitializeHelper()
                    end
                    goto continue_loop
                end
            end
            
            EchoXA("[Helper] === DUTY RETRY INITIATED - WAITING FOR QUEUE ===")
            goto continue_loop
        else
            EchoXA("[Helper] ✓ Duty completion verified - reward received")
        end
        
        local actualHelperName = helperConfigs[idx][1][1]
        if not completedHelpers[actualHelperName] then
            completedHelpers[actualHelperName] = true
            EchoXA("[Helper] Helper run " .. actualHelperName .. " marked as completed")
        end
        
        -- === SUBMARINE CHECK POINT ===
        EchoXA("[Subs] === CHECKING SUBMARINE STATUS BEFORE HELPER SWITCH ===")
        local subsReady = CheckSubmarines()
        
        if subsReady and not submarinesPaused then
            EchoXA("[Subs] === SUBMARINES READY - ACTIVATING MULTI MODE ===")
            EchoXA("[Subs] Helper rotation will resume after submarines complete")
            
            -- Store current helper for later verification
            originalHelperForSubmarines = helperConfigs[idx][1][1]
            EchoXA("[Subs] Stored original helper: " .. originalHelperForSubmarines)
            
            EnableARMultiXA()
            EchoXA("[Subs] Multi mode enabled - submarines will now run")
            submarinesPaused = true
            
            EchoXA("[Subs] Waiting for submarines to complete...")
            
        else
            EchoXA("[Subs] No submarines ready - continuing with helper rotation")
            
            EchoXA("[Helper] Switching to next helper...")
            if not switchToNextHelper() then
                EchoXA("[Helper] Rotation complete - Multi Mode active until reset.")
                break
            end
            
            local initSuccess = InitializeHelper()
            
            while not initSuccess and rotationStarted do
                EchoXA("[Helper] Initialization failed - trying next helper...")
                if not switchToNextHelper() then
                    EchoXA("[Helper] Rotation complete - Multi Mode active until reset.")
                    rotationStarted = false
                    break
                end
                initSuccess = InitializeHelper()
            end
        end
    end
    
    wasInDuty = inDuty
    
    -- === SUBMARINE BACKGROUND MONITORING ===
    if submarinesPaused then
        local currentTime = os.time()
        if currentTime - lastSubmarineCheck >= submarineCheckInterval then
            lastSubmarineCheck = currentTime
            
            local subsStillReady = CheckSubmarines()
            
            if not subsStillReady then
                EchoXA("[Subs] === NO SUBMARINES READY - CONTINUING ROTATION ===")
                SleepXA(1)
                DisableARMultiXA()
                EchoXA("[Subs] Multi mode disabled - continuing with next helper")
                
                submarinesPaused = false
                submarineReloginInProgress = true
                submarineReloginAttempts = 0
            end
        end
    end
    
    -- Handle submarine completion and continue to next helper
    if submarineReloginInProgress then
        if CheckSubmarineReloginComplete() then
            EchoXA("[Subs] === CONTINUING TO NEXT HELPER ===")
            
            EchoXA("[Helper] Switching to next helper...")
            local switched = switchToNextHelper()
            
            if not switched then
                allHelpersCompleted = true
            else
                local initSuccess = InitializeHelper()
                
                while not initSuccess and rotationStarted and not allHelpersCompleted do
                    EchoXA("[Helper] Initialization failed - trying next helper...")
                    switched = switchToNextHelper()
                    if not switched then
                        allHelpersCompleted = true
                        break
                    end
                    initSuccess = InitializeHelper()
                end
            end
        else
            SleepXA(1)
        end
    end
    
    -- Periodic movement check while in duty (once per minute)
    if inDuty then
        local currentTime = os.time()
        if currentTime - lastMovementCheck >= movementCheckInterval then
            EchoXA("[Helper] Executing periodic movement check...")
            FullStopMovementXA()
            lastMovementCheck = currentTime
        end
    end
    
    ::continue_loop::
    
    SleepXA(1)
end

EchoXA("[Helper] === HELPER AUTOMATION ENDED ===")
EchoXA("[Helper] All runs completed or script manually stopped")

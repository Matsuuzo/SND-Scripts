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
-- ██╗███╗   ██╗██╗   ██╗██╗████████╗██╗███╗   ██╗ ██████╗ 
-- ██║████╗  ██║██║   ██║██║╚══██╔══╝██║████╗  ██║██╔════╝ 
-- ██║██╔██╗ ██║██║   ██║██║   ██║   ██║██╔██╗ ██║██║  ███╗
-- ██║██║╚██╗██║╚██╗ ██╔╝██║   ██║   ██║██║╚██╗██║██║   ██║
-- ██║██║ ╚████║ ╚████╔╝ ██║   ██║   ██║██║ ╚████║╚██████╔╝
-- ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
--
-- Advanced multi-character AD roulette automation script with intelligent party management and DC travel.
-- Automatically handles character rotation, DC travel, duty roulette queuing, and multi-helper verification.
--
-- Version: 1.2.1
-- Last Updated: 2025-10-12
-- Fixed: nil value error with .lower() method

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
-- • BardToolbox (BTB) - For party invite/disband functionality


-- Dalamud Profile called "BTB" only using BardToolBox

require("dfunc")
require("xafunc")

-- ===============================================
-- Configuration
-- ===============================================

-- Character list with assigned rotating helper - Format: {"Inviting Char@World", "Helper Name"}
local charConfigs = {
{{"Inviting CharOne@World"}, "Helper One"},
{{"Inviting CharTwo@World"}, "Helper Two"},
{{"Inviting CharThee@World"}, "Helper Three"} 
}

-- DC Travel Configuration
local enableDCTravel = true                    -- Toggle: Enable/Disable DC Travel feature
local dcTravelWorld = "World"              -- Target world for DC travel

-- Duty Roulette ID (1 = Leveling Roulette,2 = High-Level Dungeons, 3 = Main Scenario, 5 = Expert, 8 = Level Cap Dungeons )
local dutyRouletteID = 1

-- Party Verification Settings
local enablePartyVerification = true          -- Toggle: Enable/Disable helper verification
local partyCheckMaxRetries = 60                -- Number of retry attempts (60 retries = 60 minutes)
local partyCheckRetryInterval = 60             -- Seconds between retry attempts
local requiredPartySize = 4                    -- Required party size (including main character)

-- Submarine monitoring state
local enableSubmarineCheck = true
local submarineCheckInterval = 90
local lastSubmarineCheck = 0
local submarinesPaused = false
local submarineReloginInProgress = false
local submarineReloginAttempts = 0
local maxSubmarineReloginAttempts = 3
local originalCharForSubmarines = nil         -- Track which character we need to return to

-- Daily Reset Configuration
local dailyResetHour = 17                     -- Reset hour in UTC+1 (17:00 = 5 PM)
local dailyResetCheckInterval = 60           -- Check every 60 seconds
local lastDailyResetCheck = 0
local dailyResetTriggered = false            -- Track if reset has been triggered today
local allCharactersCompleted = false         -- Track if all characters are done

-- ==========================================
-- DO NOT TOUCH ANYTHING BELOW
-- ==========================================

-- Relog settings
local relogWaitTime = 3
local maxRelogattempts = 3
local dutyDelay = 3

-- Movement check interval (in seconds)
local movementCheckInterval = 60
local lastMovementCheck = 0

-- Internal state tracking
local currentChar = charConfigs[1] and charConfigs[1][1] and charConfigs[1][1][1] and tostring(charConfigs[1][1][1]):lower() or ""
local currentHelper = charConfigs[1] and charConfigs[1][2] and tostring(charConfigs[1][2]) or ""
local idx = 1
local rotationStarted = true
local wasInDuty = false
local adRunActive = false
local failedCharacters = {}
local completedCharacters = {}
local dcTravelCompleted = false               -- Track if DC travel has been done for current character

-- ===============================================
-- Party Verification Functions
-- ===============================================

local function GetPartyMemberNames()
    local members = {}
    
    if not Svc or not Svc.Party then
        EchoXA("[Party] ERROR: Svc.Party not available")
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

local function IsHelperInParty(helperName)
    if not helperName or helperName == "" then
        EchoXA("[Party] No rotating helper specified - skipping verification")
        return true
    end
    
    local members = GetPartyMemberNames()
    local helperLower = tostring(helperName):lower()
    
    for _, memberName in ipairs(members) do
        if memberName and tostring(memberName):lower() == helperLower then
            return true
        end
    end
    
    return false
end

local function IsPartyComplete(rotatingHelper)
    local partySize = Svc.Party.Length
    
    -- Check party size
    if partySize ~= requiredPartySize then
        EchoXA("[Party] Party size incorrect: " .. partySize .. "/" .. requiredPartySize)
        return false
    end
    
    -- Check if rotating helper is present (only if specified)
    if rotatingHelper and rotatingHelper ~= "" then
        if not IsHelperInParty(rotatingHelper) then
            EchoXA("[Party] Rotating helper " .. rotatingHelper .. " not found")
            return false
        end
    end
    
    return true
end

local function ListPartyMembers()
    local members = GetPartyMemberNames()
    local partySize = #members
    
    if partySize == 0 then
        EchoXA("[Party] Solo (no party members)")
        return
    end
    
    EchoXA("[Party] Party has " .. partySize .. " member(s):")
    for i, name in ipairs(members) do
        EchoXA("[Party]   " .. i .. ". " .. name)
    end
end

local function WaitForCompleteParty(rotatingHelper, maxRetries)
    if not enablePartyVerification then
        EchoXA("[Party] Party verification disabled - skipping party check")
        return true
    end
    
    EchoXA("[Party] === WAITING FOR COMPLETE PARTY ===")
    if rotatingHelper and rotatingHelper ~= "" then
        EchoXA("[Party] Required rotating helper: " .. rotatingHelper)
    end
    EchoXA("[Party] Required party size: " .. requiredPartySize)
    
    local retryCount = 0
    
    while retryCount < maxRetries do
        -- Check if party is complete
        if IsPartyComplete(rotatingHelper) then
            EchoXA("[Party] ✓ Party is complete!")
            ListPartyMembers()
            return true
        end
        
        -- Party not complete, send invite again
        retryCount = retryCount + 1
        EchoXA("[Party] Party incomplete - Retry " .. retryCount .. "/" .. maxRetries)
        EchoXA("[Party] Sending party invite again...")
        
        EnableBTBandInviteXA()
        SleepXA(3)
        
        -- Check again immediately after invite
        if IsPartyComplete(rotatingHelper) then
            EchoXA("[Party] ✓ Party is complete!")
            ListPartyMembers()
            return true
        end
        
        -- If not complete, wait before next retry
        if retryCount < maxRetries then
            local remainingRetries = maxRetries - retryCount
            EchoXA("[Party] Waiting " .. partyCheckRetryInterval .. " seconds before next retry (" .. remainingRetries .. " retries remaining)...")
            SleepXA(partyCheckRetryInterval)
        end
    end
    
    EchoXA("[Party] ✗ FAILED: Party did not complete after " .. maxRetries .. " retries (" .. (maxRetries * partyCheckRetryInterval / 60) .. " minutes)")
    ListPartyMembers()
    return false
end

-- ===============================================
-- Daily Reset Functions
-- ===============================================

local function CheckDailyReset()
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    local currentMinute = currentTime.min
    
    -- Check if it's 17:00 UTC+1 (5 PM)
    if currentHour == dailyResetHour and currentMinute == 0 then
        if not dailyResetTriggered then
            EchoXA("[DailyReset] === DAILY RESET TIME DETECTED (17:00 UTC+1) ===")
            return true
        end
    end
    
    -- Reset the trigger flag after 17:00 has passed
    if currentHour ~= dailyResetHour then
        dailyResetTriggered = false
    end
    
    return false
end

local function ResetRotation()
    EchoXA("[DailyReset] === RESETTING CHARACTER ROTATION ===")
    
    -- Clear all completion and failure tracking
    failedCharacters = {}
    completedCharacters = {}
    
    -- Reset flags
    allCharactersCompleted = false
    dailyResetTriggered = true
    
    -- Reset to first character
    idx = 1
    if charConfigs[1] and charConfigs[1][1] and charConfigs[1][1][1] then
        currentChar = tostring(charConfigs[1][1][1]):lower()
        currentHelper = charConfigs[1][2] and tostring(charConfigs[1][2]) or ""
    else
        EchoXA("[DailyReset] ERROR: First character configuration is invalid")
        return false
    end
    
    EchoXA("[DailyReset] Rotation reset complete - starting from first character")
    EchoXA("[DailyReset] First character: " .. charConfigs[1][1][1])
    EchoXA("[DailyReset] Required helper: " .. currentHelper)
    
    -- Relog to first character
    if PerformCharacterRelog(charConfigs[1][1][1], maxRelogattempts) then
        EnableTextAdvanceXA()
        SleepXA(2)
        return true
    else
        EchoXA("[DailyReset] ERROR: Failed to relog to first character")
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

local function AttemptSubmarineRelogin()
    return false
end

local function CheckSubmarineReloginComplete()
    if not submarineReloginInProgress then
        return true
    end
    
    -- Check if we have a valid original character stored
    if not originalCharForSubmarines or originalCharForSubmarines == "" then
        EchoXA("[Subs] WARNING: No original character stored, marking submarine relogin as complete")
        submarineReloginInProgress = false
        return true
    end
    
    -- Verify current character matches original
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedName = originalCharForSubmarines:match("^([^@]+)")
    
    if not expectedName then
        EchoXA("[Subs] WARNING: Could not extract expected name, marking submarine relogin as complete")
        submarineReloginInProgress = false
        originalCharForSubmarines = nil
        return true
    end
    
    local actualLower = tostring(actualName):lower()
    local expectedLower = tostring(expectedName):lower()
    
    if actualLower == expectedLower then
        EchoXA("[Subs] Submarine relogin verification passed")
        submarineReloginInProgress = false
        submarineReloginAttempts = 0
        originalCharForSubmarines = nil  -- Reset after successful verification
        
        CharacterSafeWaitXA()
        
        submarinesPaused = false
        
        EchoXA("[Subs] === SAFETY VALIDATION COMPLETE ===")
        EchoXA("[Subs] Resuming normal rotation on original character")
        
        return true
    else
        EchoXA("[Subs] WARNING: Character mismatch after submarines. Expected: " .. expectedName .. ", Actual: " .. actualName)
        EchoXA("[Subs] Marking submarine relogin as complete anyway to continue rotation")
        submarineReloginInProgress = false
        originalCharForSubmarines = nil
        return true
    end
end

-- ===============================================
-- Duty Roulette Check Functions
-- ===============================================

local function CheckDutyRouletteReward()
    EchoXA("[RouletteCheck] === CHECKING DUTY ROULETTE REWARD STATUS ===")
    
    yield("/dutyfinder")
    SleepXA(2)
    
    yield("/callback ContentsFinder true 2 2 0")
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
        EchoXA("[RouletteCheck] ERROR: Failed to read reward status - " .. tostring(err))
        yield("/callback ContentsFinder true -1")
        SleepXA(1)
        return false, "error"
    end
    
    EchoXA("[RouletteCheck] Reward Text: [" .. tostring(rewardReceived) .. "]")
    
    yield("/callback ContentsFinder true -1")
    SleepXA(1)
    
    if rewardReceived and rewardReceived ~= "" then
        EchoXA("[RouletteCheck] === ROULETTE ALREADY COMPLETED (TEXT FOUND) ===")
        return true, "completed"
    else
        EchoXA("[RouletteCheck] === ROULETTE AVAILABLE (NO TEXT) ===")
        return true, "available"
    end
end

-- ===============================================
-- DC Travel Functions
-- ===============================================

local function PerformDCTravel()
    if dcTravelCompleted then
        EchoXA("[DCTravel] DC Travel already completed for this character")
        return true
    end
    
    if not enableDCTravel then
        EchoXA("[DCTravel] DC Travel is disabled - skipping")
        dcTravelCompleted = true
        return true
    end
    
    EchoXA("[DCTravel] === INITIATING DATA CENTER TRAVEL ===")
    EchoXA("[DCTravel] Target world: " .. dcTravelWorld)
    
    LifestreamCmdXA(dcTravelWorld)
    WaitForLifestreamXA()
    CharacterSafeWaitXA()
    
    EchoXA("[DCTravel] === DATA CENTER TRAVEL COMPLETE ===")
    EchoXA("[DCTravel] Now on world: " .. dcTravelWorld)
    
    EchoXA("[DCTravel] Teleporting to Horizon...")
    yield("/li Horizon")
    SleepXA(10)
    
    dcTravelCompleted = true
    return true
end

local function ReturnToHomeworld()
    if not dcTravelCompleted then
        EchoXA("[DCTravel] No DC travel was performed - skipping homeworld return")
        return true
    end
    
    EchoXA("[DCTravel] === RETURNING TO HOMEWORLD ===")
    
    return_to_homeworldXA()
    
    EchoXA("[DCTravel] === HOMEWORLD RETURN COMPLETE ===")
    return true
end

-- ===============================================
-- Character Management Functions
-- ===============================================

local function VerifyCharacterSwitch(expectedName)
    if not expectedName or expectedName == "" then
        EchoXA("[RelogAuto] ERROR: No expected name provided for verification")
        return false
    end
    
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedLower = tostring(expectedName):lower()
    local actualLower = tostring(actualName):lower()
    
    if actualLower == expectedLower then
        EchoXA("[RelogAuto] Character switch verified: Now playing as " .. actualName)
        return true
    end
    
    EchoXA("[RelogAuto] ERROR: Character switch failed! Expected: " .. expectedName .. ", Actual: " .. actualName)
    return false
end

local function PerformCharacterRelog(targetChar, maxRetries)
    if not targetChar or targetChar == "" then
        EchoXA("[RelogAuto] ERROR: No target character specified")
        return false
    end
    
    maxRetries = maxRetries or maxRelogattempts
    local expectedName = targetChar:match("^([^@]+)")
    
    if not expectedName then
        EchoXA("[RelogAuto] ERROR: Could not extract character name from: " .. targetChar)
        return false
    end

    for attempt = 1, maxRetries do
        ARRelogXA(targetChar)
        EchoXA("[RelogAuto] " .. (attempt == 1 and "Relogging to " or "Retry " .. (attempt-1) .. " - Relogging to ") .. targetChar)
        SleepXA(relogWaitTime)
        WaitForARToFinishXA()
        CharacterSafeWaitXA()
        
        if VerifyCharacterSwitch(expectedName) then
            dcTravelCompleted = false
            wasInDuty = false
            adRunActive = false
            EchoXA("[RelogAuto] Character state reset complete")
            return true
        end
        
        if attempt < maxRetries then
            EchoXA("[RelogAuto] Retrying relog in 5 seconds...")
            SleepXA(5)
        end
    end
    
    EchoXA("[RelogAuto] FATAL: Character switch failed after " .. maxRetries .. " attempts!")
    return false
end

local function getCharIndex(name)
    if not name or name == "" then
        return nil
    end
    
    name = tostring(name):lower()
    for i, c in ipairs(charConfigs) do
        if c[1] and c[1][1] and tostring(c[1][1]):lower() == name then
            return i
        end
    end
    return nil
end

local function getNextAvailableCharacter(currentIdx)
    local attempts = 0
    local nextIdx = currentIdx or 0
    
    EchoXA("[RelogAuto] DEBUG: Looking for next character. Current idx: " .. (currentIdx or "nil"))
    
    while attempts < #charConfigs do
        nextIdx = nextIdx + 1
        if nextIdx > #charConfigs then
            nextIdx = 1
        end
        
        local charName = charConfigs[nextIdx][1][1]
        local isFailed = failedCharacters[charName] or false
        local isCompleted = completedCharacters[charName] or false
        
        EchoXA("[RelogAuto] DEBUG: Checking character " .. nextIdx .. ": " .. charName .. 
               " (Failed: " .. tostring(isFailed) .. ", Completed: " .. tostring(isCompleted) .. ")")
        
        if not isFailed and not isCompleted then
            EchoXA("[RelogAuto] DEBUG: Found available character: " .. charName)
            return nextIdx, charName
        end
        
        attempts = attempts + 1
    end
    
    EchoXA("[RelogAuto] DEBUG: No available characters found")
    return nil, nil
end

local function attemptCharacterLogin(targetIdx)
    local targetChar = charConfigs[targetIdx][1][1]
    EchoXA("[RelogAuto] Attempting to log into: " .. targetChar)
    
    if PerformCharacterRelog(targetChar, maxRelogattempts) then
        return true
    else
        failedCharacters[targetChar] = true
        EchoXA("[RelogAuto] FAILED: Character " .. targetChar .. " marked as failed after " .. maxRelogattempts .. " attempts")
        return false
    end
end

local function reportRotationStatus()
    local totalChars = #charConfigs
    local failedCount = 0
    local completedCount = 0
    
    for _ in pairs(failedCharacters) do
        failedCount = failedCount + 1
    end
    
    for _ in pairs(completedCharacters) do
        completedCount = completedCount + 1
    end
    
    local remainingCount = totalChars - failedCount - completedCount
    
    EchoXA(string.format("[RelogAuto] Rotation Status: %d/%d characters remaining (%d completed, %d failed)", 
        remainingCount, totalChars, completedCount, failedCount))
end

local function switchToNextCharacter()
    reportRotationStatus()
    
    local doneCount = 0
    for _ in pairs(failedCharacters) do
        doneCount = doneCount + 1
    end
    for _ in pairs(completedCharacters) do
        doneCount = doneCount + 1
    end
    
    if doneCount >= #charConfigs then
        EchoXA("[RelogAuto] === ALL CHARACTERS PROCESSED ===")
        EchoXA("[RelogAuto] Enabling AutoRetainer Multi Mode...")
        
        EnableARMultiXA()
        allCharactersCompleted = true
        
        EchoXA("[RelogAuto] Multi Mode enabled - waiting for daily reset at 17:00 UTC+1")
        return false
    end
    
    local nextIdx, nextCharacter = getNextAvailableCharacter(idx)
    if not nextIdx then
        EchoXA("[RelogAuto] No more available characters.")
        
        EnableARMultiXA()
        allCharactersCompleted = true
        
        EchoXA("[RelogAuto] Multi Mode enabled - waiting for daily reset at 17:00 UTC+1")
        return false
    end
    
    EchoXA("[RelogAuto] Switching to next character: " .. nextCharacter)
    
    if attemptCharacterLogin(nextIdx) then
        EchoXA("[RelogAuto] DEBUG: Updating idx from " .. (idx or "nil") .. " to " .. nextIdx)
        if charConfigs[nextIdx] and charConfigs[nextIdx][1] and charConfigs[nextIdx][1][1] then
            currentChar = tostring(nextCharacter):lower()
            currentHelper = charConfigs[nextIdx][2] and tostring(charConfigs[nextIdx][2]) or ""
            idx = nextIdx
            
            EchoXA("[RelogAuto] DEBUG: Current character updated to: " .. currentChar .. " (idx: " .. idx .. ")")
            EchoXA("[RelogAuto] DEBUG: Required helper: " .. currentHelper)
        else
            EchoXA("[RelogAuto] ERROR: Invalid character configuration at index " .. nextIdx)
            return false
        end
        
        EnableTextAdvanceXA()
        SleepXA(2)
        
        return true
    else
        return switchToNextCharacter()
    end
end

-- ===============================================
-- Duty Queue Functions
-- ===============================================

local function QueueDutyRoulette()
    EchoXA("[RelogAuto] Queueing Duty Roulette ID: " .. dutyRouletteID)
    
    if wasInDuty then
        EchoXA("[RelogAuto] Already in duty, skipping queue")
        return false
    end
    
    local success, err = pcall(function()
        Instances.DutyFinder:QueueRoulette(dutyRouletteID)
    end)
    
    if success then
        EchoXA("[RelogAuto] Successfully queued for Duty Roulette")
        return true
    else
        EchoXA("[RelogAuto] ERROR: Failed to queue - " .. tostring(err))
        return false
    end
end

-- ===============================================
-- Character Initialization
-- ===============================================

local function InitializeCharacter()
    EchoXA("[RelogAuto] === INITIALIZING CHARACTER ===")
    EchoXA("[RelogAuto] Character: " .. charConfigs[idx][1][1])
    EchoXA("[RelogAuto] Required Helper: " .. currentHelper)
    
    -- Step 1: Check if Duty Roulette reward already received
    EchoXA("[RelogAuto] Step 1: Checking Duty Roulette reward status...")
    local checkSuccess, rewardStatus = CheckDutyRouletteReward()
    
    if not checkSuccess then
        EchoXA("[RelogAuto] ERROR: Failed to check roulette status - marking character as failed")
        local actualCharName = charConfigs[idx][1][1]
        failedCharacters[actualCharName] = true
        EchoXA("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (ERROR) ===")
        return false
    end
    
    if rewardStatus == "completed" then
        EchoXA("[RelogAuto] *** REWARD ALREADY RECEIVED - SKIPPING CHARACTER ***")
        local actualCharName = charConfigs[idx][1][1]
        completedCharacters[actualCharName] = true
        EchoXA("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (COMPLETED) ===")
        return false
    end
    
    EchoXA("[RelogAuto] Roulette available - proceeding with DC Travel and queue")
    
    -- Step 2: Perform DC Travel
    EchoXA("[RelogAuto] Step 2: Performing Data Center Travel...")
    PerformDCTravel()
    CharacterSafeWaitXA()
    
    -- Step 3: Enable BTB and send invite
    EchoXA("[RelogAuto] Step 3: Enabling BTB and sending party invite...")
    EnableBTBandInviteXA()
    CharacterSafeWaitXA()
    
    -- Step 4: Wait for complete party (rotating helper + static members + correct size)
    EchoXA("[RelogAuto] Step 4: Verifying party composition...")
    if not WaitForCompleteParty(currentHelper, partyCheckMaxRetries) then
        EchoXA("[RelogAuto] ERROR: Party verification failed after " .. partyCheckMaxRetries .. " retries!")
        EchoXA("[RelogAuto] Marking character as failed...")
        local actualCharName = charConfigs[idx][1]
        failedCharacters[actualCharName] = true
        
        -- Disband party before moving to next character
        BTBDisbandXA()
        SleepXA(2)
        
        EchoXA("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (PARTY VERIFICATION FAILED) ===")
        return false
    end
    
    -- Step 5: Queue Duty Roulette
    EchoXA("[RelogAuto] Step 5: Queueing Duty Roulette...")
    QueueDutyRoulette()
    SleepXA(2)
    
    EchoXA("[RelogAuto] === CHARACTER INITIALIZATION COMPLETE ===")
    return true
end

-- ===============================================
-- Initialize rotation
-- ===============================================

idx = getCharIndex(currentChar)
if not idx then
    EchoXA("[RelogAuto] Start character not in rotation: " .. currentChar)
    return
end

local loginSuccess = false
local currentIdx = idx

EchoXA("[RelogAuto] === STARTING AD RELOG AUTOMATION WITH DC TRAVEL ===")
EchoXA("[RelogAuto] Party Verification: " .. (enablePartyVerification and "ENABLED" or "DISABLED"))
EchoXA("[RelogAuto] Starting character rotation...")
reportRotationStatus()

-- Initial login
while not loginSuccess and #failedCharacters < #charConfigs do
    if attemptCharacterLogin(currentIdx) then
        loginSuccess = true
        idx = currentIdx
        currentHelper = charConfigs[idx][2] and tostring(charConfigs[idx][2]) or ""
        EchoXA("[RelogAuto] Successfully logged into: " .. charConfigs[idx][1][1])
        EchoXA("[RelogAuto] Required helper: " .. currentHelper)
    else
        local nextIdx, nextChar = getNextAvailableCharacter(currentIdx)
        if nextIdx then
            EchoXA("[RelogAuto] Trying next character: " .. nextChar)
            currentIdx = nextIdx
        else
            EchoXA("[RelogAuto] FATAL: All characters have failed login attempts!")
            return
        end
    end
end

if not loginSuccess then
    EchoXA("[RelogAuto] FATAL: Unable to log into any character. Stopping script.")
    return
end

-- Initialize first character
CharacterSafeWaitXA()
EnableTextAdvanceXA()
SleepXA(2)

local initSuccess = InitializeCharacter()

-- If first character already completed, keep trying until we find an available one
while not initSuccess and rotationStarted do
    EchoXA("[RelogAuto] First character skipped - trying next")
    if not switchToNextCharacter() then
        EchoXA("[RelogAuto] No more characters available. Stopping script.")
        return
    end
    initSuccess = InitializeCharacter()
end

if not initSuccess then
    EchoXA("[RelogAuto] All characters already completed or failed. Stopping script.")
    return
end

-- ===============================================
-- Main Loop
-- ===============================================

EchoXA("[RelogAuto] === ENTERING MAIN LOOP ===")

while rotationStarted do
    local inDuty = false
    
    -- === DAILY RESET CHECK ===
    local currentTime = os.time()
    if currentTime - lastDailyResetCheck >= dailyResetCheckInterval then
        lastDailyResetCheck = currentTime
        
        if CheckDailyReset() then
            EchoXA("[DailyReset] === DAILY RESET TRIGGERED ===")
            
            if allCharactersCompleted then
                DisableARMultiXA()
                SleepXA(2)
            end
            
            if ResetRotation() then
                allCharactersCompleted = false
                
                local initSuccess = InitializeCharacter()
                
                while not initSuccess and rotationStarted do
                    EchoXA("[RelogAuto] Character skipped after reset - trying next character...")
                    if not switchToNextCharacter() then
                        EchoXA("[RelogAuto] All characters already completed after reset.")
                        allCharactersCompleted = true
                        break
                    end
                    initSuccess = InitializeCharacter()
                end
            else
                EchoXA("[DailyReset] ERROR: Failed to reset rotation")
            end
        end
    end
    
    if allCharactersCompleted then
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
        EchoXA("[RelogAuto] === ENTERED DUTY ===")
        SleepXA(dutyDelay)
        
        if not adRunActive then
            adXA("start")
            adRunActive = true
            EchoXA("[RelogAuto] AutoDuty started after entering duty")
        end
        
        vbmaiXA("on")
        SleepXA(3)
        FullStopMovementXA()
        EchoXA("[RelogAuto] Movement stopped after entering duty")
        
        lastMovementCheck = os.time()
        
    elseif not inDuty and wasInDuty then
        EchoXA("[RelogAuto] === LEFT DUTY ===")
        adRunActive = false
        SleepXA(1)
        adXA("stop")
        EchoXA("[RelogAuto] Left duty - AutoDuty reset")
        
        EchoXA("[RelogAuto] Disbanding party...")
        BTBDisbandXA()
        SleepXA(5)
        
        EchoXA("[RelogAuto] Returning to homeworld...")
        ReturnToHomeworld()
        SleepXA(2)
        
        -- === DUTY COMPLETION VERIFICATION ===
        EchoXA("[RelogAuto] === VERIFYING DUTY COMPLETION ===")
        local checkSuccess, rewardStatus = CheckDutyRouletteReward()
        
        if not checkSuccess then
            EchoXA("[RelogAuto] ERROR: Failed to verify duty completion")
            -- Continue anyway to avoid getting stuck
        elseif rewardStatus == "available" then
            EchoXA("[RelogAuto] ⚠ WARNING: DUTY INCOMPLETE - REWARD NOT RECEIVED!")
            EchoXA("[RelogAuto] Character got stuck or duty failed - retrying...")
            
            -- Don't mark as completed, retry the duty
            EchoXA("[RelogAuto] Re-enabling BTB and sending party invite...")
            EnableBTBandInviteXA()
            CharacterSafeWaitXA()
            
            EchoXA("[RelogAuto] Verifying party composition...")
            if not WaitForCompleteParty(currentHelper, partyCheckMaxRetries) then
                EchoXA("[RelogAuto] ERROR: Party verification failed on retry!")
                EchoXA("[RelogAuto] Marking character as failed...")
                local actualCharName = charConfigs[idx][1][1]
                failedCharacters[actualCharName] = true
                
                BTBDisbandXA()
                SleepXA(2)
                
                EchoXA("[RelogAuto] Switching to next character...")
                if not switchToNextCharacter() then
                    EchoXA("[RelogAuto] No more characters available.")
                    break
                end
                
                local initSuccess = InitializeCharacter()
                while not initSuccess and rotationStarted do
                    EchoXA("[RelogAuto] Character skipped - trying next character...")
                    if not switchToNextCharacter() then
                        EchoXA("[RelogAuto] No more characters available.")
                        rotationStarted = false
                        break
                    end
                    initSuccess = InitializeCharacter()
                end
                goto continue_loop
            end
            
            EchoXA("[RelogAuto] Party verified - re-queueing for duty...")
            QueueDutyRoulette()
            SleepXA(2)
            
            EchoXA("[RelogAuto] === DUTY RETRY INITIATED ===")
            goto continue_loop
        else
            EchoXA("[RelogAuto] ✓ Duty completion verified - reward received")
        end
        
        local actualCharName = charConfigs[idx][1][1]
        if not completedCharacters[actualCharName] then
            completedCharacters[actualCharName] = true
            EchoXA("[RelogAuto] Character " .. actualCharName .. " marked as completed")
        end
        
        -- === SUBMARINE CHECK POINT ===
        EchoXA("[Subs] === CHECKING SUBMARINE STATUS BEFORE CHARACTER SWITCH ===")
        local subsReady = CheckSubmarines()
        
        if subsReady and not submarinesPaused then
            EchoXA("[Subs] === SUBMARINES READY - ACTIVATING MULTI MODE ===")
            EchoXA("[Subs] Character rotation will resume after submarines complete")
            
            -- Store current character for later verification
            originalCharForSubmarines = charConfigs[idx][1][1]
            EchoXA("[Subs] Stored original character: " .. originalCharForSubmarines)
            
            EnableARMultiXA()
            EchoXA("[Subs] Multi mode enabled - submarines will now run")
            submarinesPaused = true
            
            EchoXA("[Subs] Waiting for submarines to complete...")
            
        else
            EchoXA("[Subs] No submarines ready - continuing with character rotation")
            
            EchoXA("[RelogAuto] Switching to next character...")
            if not switchToNextCharacter() then
                EchoXA("[RelogAuto] No more characters available. Stopping script.")
                break
            end
            
            local initSuccess = InitializeCharacter()
            
            while not initSuccess and rotationStarted do
                EchoXA("[RelogAuto] Character skipped - trying next character...")
                if not switchToNextCharacter() then
                    EchoXA("[RelogAuto] No more characters available. Stopping script.")
                    rotationStarted = false
                    break
                end
                initSuccess = InitializeCharacter()
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
                EchoXA("[Subs] Multi mode disabled - continuing with next character")
                
                submarinesPaused = false
                submarineReloginInProgress = true
                submarineReloginAttempts = 0
            end
        end
    end
    
    -- Handle submarine completion and continue to next character
    if submarineReloginInProgress then
        if CheckSubmarineReloginComplete() then
            EchoXA("[Subs] === CONTINUING TO NEXT CHARACTER ===")
            
            EchoXA("[RelogAuto] Switching to next character...")
            local switched = switchToNextCharacter()
            
            if not switched then
                allCharactersCompleted = true
            else
                local initSuccess = InitializeCharacter()
                
                while not initSuccess and rotationStarted and not allCharactersCompleted do
                    EchoXA("[RelogAuto] Character skipped - trying next character...")
                    switched = switchToNextCharacter()
                    if not switched then
                        allCharactersCompleted = true
                        break
                    end
                    initSuccess = InitializeCharacter()
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
            EchoXA("[RelogAuto] Executing periodic movement check...")
            FullStopMovementXA()
            lastMovementCheck = currentTime
        end
    end
    
    ::continue_loop::
    
    SleepXA(1)
end

EchoXA("[RelogAuto] === AD RELOG AUTOMATION ENDED ===")

EchoXA("[RelogAuto] All characters processed or script manually stopped")



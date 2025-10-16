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
-- Version: 1.3.0
-- Last Updated: 2025-10-12
-- Added: Improved daily reset handling with midnight flag reset
-- Added: Death handler with automatic revival and AutoDuty restart

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

require("curefunc")

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
local dcTravelWorld = "Omega"              -- Target world for DC travel

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
local dailyResetCheckInterval = 10            -- Check every 10 seconds when waiting for reset
local lastDailyResetCheck = 0
local dailyResetTriggered = false            -- Track if reset has been triggered today (resets at midnight)
local lastMidnightCheck = 0
local midnightCheckInterval = 60             -- Check for midnight every 60 seconds
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

-- Death tracking
local lastDeathCheck = 0
local deathCheckInterval = 1  -- Check every second

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
    CureEcho("[Death] Player death detected - initiating revival...")
    
    -- Wait for SelectYesno dialog to appear
    CureSleep(1.5)
    
    -- Click Yes on revival prompt
    CureSelectYesno()
    
    -- Wait for player to be alive again
    local attempts = 0
    local maxAttempts = 30  -- 30 seconds timeout
    
    while IsPlayerDead() and attempts < maxAttempts do
        CureSleep(1)
        attempts = attempts + 1
    end
    
    if attempts >= maxAttempts then
        CureEcho("[Death] WARNING: Revival timeout - player may still be dead")
        return false
    end
    
    CureEcho("[Death] Player revived successfully")
    
    -- Wait for character to stabilize
    CureSleep(2)
    
    -- Restart AutoDuty if we were in a duty
    if adRunActive then
        CureEcho("[Death] Restarting AutoDuty after death...")
        CureAd("start")
        CureSleep(1)
    end
    
    return true
end

-- ===============================================
-- Party Verification Functions
-- ===============================================

local function GetPartyMemberNames()
    local members = {}
    
    if not Svc or not Svc.Party then
        CureEcho("[Party] ERROR: Svc.Party not available")
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
        CureEcho("[Party] No rotating helper specified - skipping verification")
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
        CureEcho("[Party] Party size incorrect: " .. partySize .. "/" .. requiredPartySize)
        return false
    end
    
    -- Check if rotating helper is present (only if specified)
    if rotatingHelper and rotatingHelper ~= "" then
        if not IsHelperInParty(rotatingHelper) then
            CureEcho("[Party] Rotating helper " .. rotatingHelper .. " not found")
            return false
        end
    end
    
    return true
end

local function ListPartyMembers()
    local members = GetPartyMemberNames()
    local partySize = #members
    
    if partySize == 0 then
        CureEcho("[Party] Solo (no party members)")
        return
    end
    
    CureEcho("[Party] Party has " .. partySize .. " member(s):")
    for i, name in ipairs(members) do
        CureEcho("[Party]   " .. i .. ". " .. name)
    end
end

local function WaitForCompleteParty(rotatingHelper, maxRetries)
    if not enablePartyVerification then
        CureEcho("[Party] Party verification disabled - skipping party check")
        return true
    end
    
    CureEcho("[Party] === WAITING FOR COMPLETE PARTY ===")
    if rotatingHelper and rotatingHelper ~= "" then
        CureEcho("[Party] Required rotating helper: " .. rotatingHelper)
    end
    CureEcho("[Party] Required party size: " .. requiredPartySize)
    
    local retryCount = 0
    
    while retryCount < maxRetries do
        -- Check if party is complete
        if IsPartyComplete(rotatingHelper) then
            CureEcho("[Party] Party is complete!")
            ListPartyMembers()
            return true
        end
        
        -- Party not complete, send invite again
        retryCount = retryCount + 1
        CureEcho("[Party] Party incomplete - Retry " .. retryCount .. "/" .. maxRetries)
        CureEcho("[Party] Sending party invite again...")
        
        CureEnableBTBandInvite()
        CureSleep(3)
        
        -- Check again immediately after invite
        if IsPartyComplete(rotatingHelper) then
            CureEcho("[Party] Party is complete!")
            ListPartyMembers()
            return true
        end
        
        -- If not complete, wait before next retry
        if retryCount < maxRetries then
            local remainingRetries = maxRetries - retryCount
            CureEcho("[Party] Waiting " .. partyCheckRetryInterval .. " seconds before next retry (" .. remainingRetries .. " retries remaining)...")
            CureSleep(partyCheckRetryInterval)
        end
    end
    
    CureEcho("[Party] FAILED: Party did not complete after " .. maxRetries .. " retries (" .. (maxRetries * partyCheckRetryInterval / 60) .. " minutes)")
    ListPartyMembers()
    return false
end

-- ===============================================
-- Daily Reset Functions
-- ===============================================

local function CheckMidnight()
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    -- Reset the dailyResetTriggered flag after midnight (when hour < dailyResetHour)
    if currentHour < dailyResetHour and dailyResetTriggered then
        CureEcho("[DailyReset] === MIDNIGHT PASSED - RESET FLAG CLEARED ===")
        CureEcho("[DailyReset] Daily reset will be available again at " .. dailyResetHour .. ":00")
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
    
    -- Check if it's past reset hour UTC+1
    if currentHour >= dailyResetHour then
        CureEcho("[DailyReset] === DAILY RESET CONDITIONS MET ===")
        CureEcho("[DailyReset] Current hour: " .. currentHour .. ":XX")
        CureEcho("[DailyReset] Reset hour: " .. dailyResetHour .. ":00")
        return true
    end
    
    return false
end

local function ResetRotation()
    CureEcho("[DailyReset] === RESETTING CHARACTER ROTATION ===")
    
    -- Clear all completion and failure tracking
    failedCharacters = {}
    completedCharacters = {}
    
    -- Reset flags
    allCharactersCompleted = false
    dcTravelCompleted = false
    wasInDuty = false
    adRunActive = false
    -- Don't reset dailyResetTriggered here - it stays true until midnight
    
    -- Reset to first character
    idx = 1
    if charConfigs[1] and charConfigs[1][1] and charConfigs[1][1][1] then
        currentChar = tostring(charConfigs[1][1][1]):lower()
        currentHelper = charConfigs[1][2] and tostring(charConfigs[1][2]) or ""
    else
        CureEcho("[DailyReset] ERROR: First character configuration is invalid")
        return false
    end
    
    CureEcho("[DailyReset] Rotation reset complete - starting from first character")
    CureEcho("[DailyReset] First character: " .. charConfigs[1][1][1])
    CureEcho("[DailyReset] Required helper: " .. currentHelper)
    
    -- Relog to first character
    if CureARRelog(charConfigs[1][1][1]) then
        CureEnableTextAdvance()
        CureSleep(2)
        return true
    else
        CureEcho("[DailyReset] ERROR: Failed to relog to first character")
        return false
    end
end

local function InitializeDailyResetState()
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    -- Wenn Script nach Reset-Zeit gestartet wird, markiere Reset als "bereits erfolgt"
    if currentHour >= dailyResetHour then
        dailyResetTriggered = true
        CureEcho("[DailyReset] === INITIALIZATION ===")
        CureEcho("[DailyReset] Script started after " .. dailyResetHour .. ":00 - Reset already occurred today")
        CureEcho("[DailyReset] Daily reset will be available tomorrow at " .. dailyResetHour .. ":00")
        CureEcho("[DailyReset] Current rotation will complete normally")
    else
        dailyResetTriggered = false
        local hoursUntilReset = dailyResetHour - currentHour
        CureEcho("[DailyReset] === INITIALIZATION ===")
        CureEcho("[DailyReset] Script started before " .. dailyResetHour .. ":00")
        CureEcho("[DailyReset] Daily reset will trigger in ~" .. hoursUntilReset .. " hours")
        CureEcho("[DailyReset] After reset, rotation will restart from first character")
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
        CureEcho("[Subs] Could not resolve config path")
        return false
    end
    
    local file, err = io.open(configPath, "r")
    if not file then
        CureEcho("[Subs] Could not open config: " .. tostring(err))
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content or content == "" then
        CureEcho("[Subs] Config file is empty")
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
        CureEcho(string.format("[Subs] %d %s available - submarine mode activated!", available, plural))
        return true
    end
    
    if minDelta and minDelta > 0 then
        local minutes = math.max(0, math.ceil(minDelta / 60))
        local plural = minutes == 1 and "minute" or "minutes"
        CureEcho(string.format("[Subs] Next submarine in %d %s", minutes, plural))
    end
    
    return false
end

-- FIXED: Now properly attempts to relog to original character
local function AttemptSubmarineRelogin()
    if not originalCharForSubmarines or originalCharForSubmarines == "" then
        CureEcho("[Subs] ERROR: No original character stored for submarine relogin")
        return false
    end
    
    CureEcho("[Subs] === ATTEMPTING SUBMARINE RELOGIN ===")
    CureEcho("[Subs] Attempting to return to: " .. originalCharForSubmarines)
    
    submarineReloginAttempts = submarineReloginAttempts + 1
    
    if submarineReloginAttempts > maxSubmarineReloginAttempts then
        CureEcho("[Subs] ERROR: Maximum relogin attempts reached (" .. maxSubmarineReloginAttempts .. ")")
        CureEcho("[Subs] Marking submarine relogin as failed and continuing rotation")
        submarineReloginInProgress = false
        submarineReloginAttempts = 0
        originalCharForSubmarines = nil
        return false
    end
    
    CureEcho("[Subs] Relogin attempt " .. submarineReloginAttempts .. "/" .. maxSubmarineReloginAttempts)
    
    local success = CureARRelog(originalCharForSubmarines)
    
    if success then
        CureEcho("[Subs] Relogin command sent successfully")
        CureCharacterSafeWait()
        return true
    else
        CureEcho("[Subs] Relogin command failed, will retry...")
        CureSleep(5)
        return false
    end
end

local function CheckSubmarineReloginComplete()
    if not submarineReloginInProgress then
        return true
    end
    
    -- Check if we have a valid original character stored
    if not originalCharForSubmarines or originalCharForSubmarines == "" then
        CureEcho("[Subs] WARNING: No original character stored, marking submarine relogin as complete")
        submarineReloginInProgress = false
        return true
    end
    
    -- Verify current character matches original
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedName = originalCharForSubmarines:match("^([^@]+)")
    
    if not expectedName then
        CureEcho("[Subs] WARNING: Could not extract expected name, marking submarine relogin as complete")
        submarineReloginInProgress = false
        originalCharForSubmarines = nil
        return true
    end
    
    local actualLower = tostring(actualName):lower()
    local expectedLower = tostring(expectedName):lower()
    
    if actualLower == expectedLower then
        CureEcho("[Subs] Submarine relogin verification passed")
        submarineReloginInProgress = false
        submarineReloginAttempts = 0
        originalCharForSubmarines = nil  -- Reset after successful verification
        
        CureCharacterSafeWait()
        
        submarinesPaused = false
        
        CureEcho("[Subs] === SAFETY VALIDATION COMPLETE ===")
        CureEcho("[Subs] Resuming normal rotation on original character")
        
        return true
    else
        CureEcho("[Subs] WARNING: Character mismatch after submarines. Expected: " .. expectedName .. ", Actual: " .. actualName)
        
        -- Attempt relogin again
        if AttemptSubmarineRelogin() then
            CureEcho("[Subs] Relogin reattempted, will verify again next cycle")
            return false
        else
            CureEcho("[Subs] Relogin failed, marking as complete to continue rotation")
            submarineReloginInProgress = false
            originalCharForSubmarines = nil
            return true
        end
    end
end

-- ===============================================
-- Duty Roulette Check Functions
-- ===============================================

local function CheckDutyRouletteReward()
    CureEcho("[RouletteCheck] === CHECKING DUTY ROULETTE REWARD STATUS ===")
    
    yield("/dutyfinder")
    CureSleep(2)
    
    yield("/callback ContentsFinder true 2 2 0")
    CureSleep(1)
    
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
        CureEcho("[RouletteCheck] ERROR: Failed to read reward status - " .. tostring(err))
        yield("/callback ContentsFinder true -1")
        CureSleep(1)
        return false, "error"
    end
    
    CureEcho("[RouletteCheck] Reward Text: [" .. tostring(rewardReceived) .. "]")
    
    yield("/callback ContentsFinder true -1")
    CureSleep(1)
    
    if rewardReceived and rewardReceived ~= "" then
        CureEcho("[RouletteCheck] === ROULETTE ALREADY COMPLETED (TEXT FOUND) ===")
        return true, "completed"
    else
        CureEcho("[RouletteCheck] === ROULETTE AVAILABLE (NO TEXT) ===")
        return true, "available"
    end
end

-- ===============================================
-- DC Travel Functions
-- ===============================================

local function PerformDCTravel()
    if dcTravelCompleted then
        CureEcho("[DCTravel] DC Travel already completed for this character")
        return true
    end
    
    if not enableDCTravel then
        CureEcho("[DCTravel] DC Travel is disabled - skipping")
        dcTravelCompleted = true
        return true
    end
    
    -- Check current world before traveling
    local currentWorld = CureGetWorldName()
    CureEcho("[DCTravel] Current world: " .. tostring(currentWorld))
    CureEcho("[DCTravel] Target world: " .. dcTravelWorld)
    
    if tostring(currentWorld):lower() == tostring(dcTravelWorld):lower() then
        CureEcho("[DCTravel] Already on target world - skipping travel")
        dcTravelCompleted = true
        
        CureEcho("[DCTravel] Teleporting to Horizon...")
        yield("/li Horizon")
        CureSleep(10)
        
        return true
    end
    
    CureEcho("[DCTravel] === INITIATING DATA CENTER TRAVEL ===")
    
    CureLifestreamCmd(dcTravelWorld)
    CureWaitForLifestream()
    CureCharacterSafeWait()
    
    CureEcho("[DCTravel] === DATA CENTER TRAVEL COMPLETE ===")
    CureEcho("[DCTravel] Now on world: " .. dcTravelWorld)
    
    CureEcho("[DCTravel] Teleporting to Horizon...")
    yield("/li Horizon")
    CureSleep(10)
    
    dcTravelCompleted = true
    return true
end

local function ReturnToHomeworld()
    if not dcTravelCompleted then
        CureEcho("[DCTravel] No DC travel was performed - skipping homeworld return")
        return true
    end
    
    CureEcho("[DCTravel] === RETURNING TO HOMEWORLD ===")
    
    CureReturnToHomeworld()
    
    CureEcho("[DCTravel] === HOMEWORLD RETURN COMPLETE ===")
    return true
end

-- ===============================================
-- Character Management Functions
-- ===============================================

local function VerifyCharacterSwitch(expectedName)
    if not expectedName or expectedName == "" then
        CureEcho("[RelogAuto] ERROR: No expected name provided for verification")
        return false
    end
    
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedLower = tostring(expectedName):lower()
    local actualLower = tostring(actualName):lower()
    
    if actualLower == expectedLower then
        CureEcho("[RelogAuto] Character switch verified: Now playing as " .. actualName)
        return true
    end
    
    CureEcho("[RelogAuto] ERROR: Character switch failed! Expected: " .. expectedName .. ", Actual: " .. actualName)
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

-- FIXED: Now properly returns nil values when no characters available
local function getNextAvailableCharacter(currentIdx)
    local attempts = 0
    local nextIdx = currentIdx or 0
    
    CureEcho("[RelogAuto] DEBUG: Looking for next character. Current idx: " .. (currentIdx or "nil"))
    
    while attempts < #charConfigs do
        nextIdx = nextIdx + 1
        if nextIdx > #charConfigs then
            nextIdx = 1
        end
        
        local charName = charConfigs[nextIdx][1][1]
        local isFailed = failedCharacters[charName] or false
        local isCompleted = completedCharacters[charName] or false
        
        CureEcho("[RelogAuto] DEBUG: Checking character " .. nextIdx .. ": " .. charName .. 
               " (Failed: " .. tostring(isFailed) .. ", Completed: " .. tostring(isCompleted) .. ")")
        
        if not isFailed and not isCompleted then
            CureEcho("[RelogAuto] DEBUG: Found available character: " .. charName)
            return nextIdx, charName
        end
        
        attempts = attempts + 1
    end
    
    -- FIXED: Properly return nil when no characters available
    CureEcho("[RelogAuto] DEBUG: No available characters found")
    return nil, nil
end

local function attemptCharacterLogin(targetIdx)
    local targetChar = charConfigs[targetIdx][1][1]
    CureEcho("[RelogAuto] Attempting to log into: " .. targetChar)
    
    if CureARRelog(targetChar) then
        return true
    else
        failedCharacters[targetChar] = true
        CureEcho("[RelogAuto] FAILED: Character " .. targetChar .. " marked as failed after " .. maxRelogattempts .. " attempts")
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
    
    CureEcho(string.format("[RelogAuto] Rotation Status: %d/%d characters remaining (%d completed, %d failed)", 
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
        CureEcho("[RelogAuto] === ALL CHARACTERS PROCESSED ===")
        CureEcho("[RelogAuto] Enabling AutoRetainer Multi Mode...")
        
        CureEnableARMulti()
        allCharactersCompleted = true
        
        CureEcho("[RelogAuto] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    local nextIdx, nextCharacter = getNextAvailableCharacter(idx)
    if not nextIdx then
        CureEcho("[RelogAuto] No more available characters.")
        
        CureEnableARMulti()
        allCharactersCompleted = true
        
        CureEcho("[RelogAuto] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    CureEcho("[RelogAuto] Switching to next character: " .. nextCharacter)
    
    if attemptCharacterLogin(nextIdx) then
        CureEcho("[RelogAuto] DEBUG: Updating idx from " .. (idx or "nil") .. " to " .. nextIdx)
        if charConfigs[nextIdx] and charConfigs[nextIdx][1] and charConfigs[nextIdx][1][1] then
            currentChar = tostring(nextCharacter):lower()
            currentHelper = charConfigs[nextIdx][2] and tostring(charConfigs[nextIdx][2]) or ""
            idx = nextIdx
            
            -- CRITICAL: Reset flags for new character
            dcTravelCompleted = false
            wasInDuty = false
            adRunActive = false
            
            CureEcho("[RelogAuto] DEBUG: Current character updated to: " .. currentChar .. " (idx: " .. idx .. ")")
            CureEcho("[RelogAuto] DEBUG: Required helper: " .. currentHelper)
            CureEcho("[RelogAuto] DEBUG: Flags reset - dcTravelCompleted: false, wasInDuty: false, adRunActive: false")
        else
            CureEcho("[RelogAuto] ERROR: Invalid character configuration at index " .. nextIdx)
            return false
        end
        
        CureEnableTextAdvance()
        CureSleep(2)
        
        return true
    else
        return switchToNextCharacter()
    end
end

-- ===============================================
-- Duty Queue Functions
-- ===============================================

local function QueueDutyRoulette()
    CureEcho("[RelogAuto] Queueing Duty Roulette ID: " .. dutyRouletteID)
    
    if wasInDuty then
        CureEcho("[RelogAuto] Already in duty, skipping queue")
        return false
    end
    
    local success, err = pcall(function()
        Instances.DutyFinder:QueueRoulette(dutyRouletteID)
    end)
    
    if success then
        CureEcho("[RelogAuto] Successfully queued for Duty Roulette")
        return true
    else
        CureEcho("[RelogAuto] ERROR: Failed to queue - " .. tostring(err))
        return false
    end
end

-- ===============================================
-- Character Initialization
-- ===============================================

local function InitializeCharacter()
    CureEcho("[RelogAuto] === INITIALIZING CHARACTER ===")
    CureEcho("[RelogAuto] Character: " .. charConfigs[idx][1][1])
    CureEcho("[RelogAuto] Required Helper: " .. currentHelper)
    
    -- Step 1: Check if Duty Roulette reward already received
    CureEcho("[RelogAuto] Step 1: Checking Duty Roulette reward status...")
    local checkSuccess, rewardStatus = CheckDutyRouletteReward()
    
    if not checkSuccess then
        CureEcho("[RelogAuto] ERROR: Failed to check roulette status - marking character as failed")
        local actualCharName = charConfigs[idx][1][1]
        failedCharacters[actualCharName] = true
        CureEcho("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (ERROR) ===")
        return false
    end
    
    if rewardStatus == "completed" then
        CureEcho("[RelogAuto] *** REWARD ALREADY RECEIVED - SKIPPING CHARACTER ***")
        local actualCharName = charConfigs[idx][1][1]
        completedCharacters[actualCharName] = true
        CureEcho("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (COMPLETED) ===")
        return false
    end
    
    CureEcho("[RelogAuto] Roulette available - proceeding with DC Travel and queue")
    
    -- Step 2: Perform DC Travel
    CureEcho("[RelogAuto] Step 2: Performing Data Center Travel...")
    PerformDCTravel()
    CureCharacterSafeWait()
    
    -- Step 3: Enable BTB and send invite
    CureEcho("[RelogAuto] Step 3: Enabling BTB and sending party invite...")
    CureEnableBTBandInvite()
    CureCharacterSafeWait()
    
    -- Step 4: Wait for complete party (rotating helper + static members + correct size)
    CureEcho("[RelogAuto] Step 4: Verifying party composition...")
    if not WaitForCompleteParty(currentHelper, partyCheckMaxRetries) then
        CureEcho("[RelogAuto] ERROR: Party verification failed after " .. partyCheckMaxRetries .. " retries!")
        CureEcho("[RelogAuto] Marking character as failed...")
        local actualCharName = charConfigs[idx][1][1]
        failedCharacters[actualCharName] = true
        
        -- Disband party before moving to next character
        CureBTBDisband()
        CureSleep(2)
        
        CureEcho("[RelogAuto] === CHARACTER INITIALIZATION ABORTED (PARTY VERIFICATION FAILED) ===")
        return false
    end
    
    -- Step 5: Queue Duty Roulette
    CureEcho("[RelogAuto] Step 5: Queueing Duty Roulette...")
    QueueDutyRoulette()
    CureSleep(2)
    
    CureEcho("[RelogAuto] === CHARACTER INITIALIZATION COMPLETE ===")
    return true
end

-- ===============================================
-- Initialize rotation
-- ===============================================

idx = getCharIndex(currentChar)
if not idx then
    CureEcho("[RelogAuto] Start character not in rotation: " .. currentChar)
    return
end

local loginSuccess = false
local currentIdx = idx

CureEcho("[RelogAuto] === STARTING AD RELOG AUTOMATION WITH DC TRAVEL ===")
CureEcho("[RelogAuto] Party Verification: " .. (enablePartyVerification and "ENABLED" or "DISABLED"))
InitializeDailyResetState()
CureEcho("[RelogAuto] Daily Reset Time: " .. dailyResetHour .. ":00 UTC+1")
CureEcho("[RelogAuto] Starting character rotation...")
reportRotationStatus()

-- Initial login
while not loginSuccess and #failedCharacters < #charConfigs do
    if attemptCharacterLogin(currentIdx) then
        loginSuccess = true
        idx = currentIdx
        currentHelper = charConfigs[idx][2] and tostring(charConfigs[idx][2]) or ""
        CureEcho("[RelogAuto] Successfully logged into: " .. charConfigs[idx][1][1])
        CureEcho("[RelogAuto] Required helper: " .. currentHelper)
    else
        local nextIdx, nextChar = getNextAvailableCharacter(currentIdx)
        if nextIdx then
            CureEcho("[RelogAuto] Trying next character: " .. nextChar)
            currentIdx = nextIdx
        else
            CureEcho("[RelogAuto] FATAL: All characters have failed login attempts!")
            return
        end
    end
end

if not loginSuccess then
    CureEcho("[RelogAuto] FATAL: Unable to log into any character. Stopping script.")
    return
end

-- Initialize first character
CureCharacterSafeWait()
CureEnableTextAdvance()
CureSleep(2)

local initSuccess = InitializeCharacter()

-- If first character already completed, keep trying until we find an available one
while not initSuccess and rotationStarted do
    CureEcho("[RelogAuto] First character skipped - trying next")
    if not switchToNextCharacter() then
        CureEcho("[RelogAuto] No more characters available. Stopping script.")
        return
    end
    initSuccess = InitializeCharacter()
end

if not initSuccess then
    CureEcho("[RelogAuto] All characters already completed or failed. Stopping script.")
    return
end

-- ===============================================
-- Main Loop
-- ===============================================

CureEcho("[RelogAuto] === ENTERING MAIN LOOP ===")

while rotationStarted do
    local inDuty = false
    
    -- === DEATH CHECK ===
    if IsPlayerDead() then
        CureEcho("[Death] === DEATH DETECTED ===")
        HandleDeath()
    end
    
    -- === MIDNIGHT CHECK (Reset the dailyResetTriggered flag) ===
    local currentTime = os.time()
    if currentTime - lastMidnightCheck >= midnightCheckInterval then
        lastMidnightCheck = currentTime
        CheckMidnight()
    end
    
    -- === DAILY RESET CHECK (when all characters are done and waiting) ===
    if allCharactersCompleted then
        if currentTime - lastDailyResetCheck >= dailyResetCheckInterval then
            lastDailyResetCheck = currentTime
            
            if CheckDailyReset() and not dailyResetTriggered then
                CureEcho("[DailyReset] === DAILY RESET TRIGGERED (All Characters Idle) ===")
                dailyResetTriggered = true
                
                CureDisableARMulti()
                CureSleep(2)
                
                if ResetRotation() then
                    allCharactersCompleted = false
                    
                    local initSuccess = InitializeCharacter()
                    
                    while not initSuccess and rotationStarted do
                        CureEcho("[RelogAuto] Character skipped after reset - trying next character...")
                        if not switchToNextCharacter() then
                            CureEcho("[RelogAuto] All characters already completed after reset.")
                            allCharactersCompleted = true
                            break
                        end
                        initSuccess = InitializeCharacter()
                    end
                else
                    CureEcho("[DailyReset] ERROR: Failed to reset rotation")
                end
            end
        end
        
        -- If all characters completed, just sleep and continue checking for reset
        CureSleep(5)
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
        CureEcho("[RelogAuto] === ENTERED DUTY ===")
        CureSleep(dutyDelay)
        
        if not adRunActive then
            CureAd("start")
            adRunActive = true
            CureEcho("[RelogAuto] AutoDuty started after entering duty")
        end
        
        CureVbmai("on")
        CureSleep(3)
        CureFullStopMovement()
        CureEcho("[RelogAuto] Movement stopped after entering duty")
        
        lastMovementCheck = os.time()
        
    elseif not inDuty and wasInDuty then
        CureEcho("[RelogAuto] === LEFT DUTY ===")
        adRunActive = false
        CureSleep(1)
        CureAd("stop")
        CureEcho("[RelogAuto] Left duty - AutoDuty reset")
        
        CureEcho("[RelogAuto] Disbanding party...")
        CureBTBDisband()
        CureSleep(5)
        
        CureEcho("[RelogAuto] Returning to homeworld...")
        ReturnToHomeworld()
        CureSleep(2)
        
        -- === CHECK FOR DAILY RESET AFTER DUTY ===
        if CheckDailyReset() and not dailyResetTriggered then
            CureEcho("[DailyReset] === DAILY RESET DETECTED AFTER DUTY COMPLETION ===")
            dailyResetTriggered = true
            
            CureEcho("[DailyReset] Current character completed duty after reset time")
            CureEcho("[DailyReset] Marking current character as completed for today...")
            local actualCharName = charConfigs[idx][1][1]
            completedCharacters[actualCharName] = true
            
            CureEcho("[DailyReset] Resetting rotation to first character...")
            if allCharactersCompleted then
                CureDisableARMulti()
                CureSleep(2)
            end
            
            if ResetRotation() then
                allCharactersCompleted = false
                
                local initSuccess = InitializeCharacter()
                
                while not initSuccess and rotationStarted do
                    CureEcho("[RelogAuto] Character skipped after reset - trying next character...")
                    if not switchToNextCharacter() then
                        CureEcho("[RelogAuto] All characters already completed after reset.")
                        allCharactersCompleted = true
                        break
                    end
                    initSuccess = InitializeCharacter()
                end
                
                goto continue_loop
            else
                CureEcho("[DailyReset] ERROR: Failed to reset rotation")
            end
        end
        
        -- === DUTY COMPLETION VERIFICATION ===
        CureEcho("[RelogAuto] === VERIFYING DUTY COMPLETION ===")
        local checkSuccess, rewardStatus = CheckDutyRouletteReward()
        
        if not checkSuccess then
            CureEcho("[RelogAuto] ERROR: Failed to verify duty completion")
            -- Continue anyway to avoid getting stuck
        elseif rewardStatus == "available" then
            CureEcho("[RelogAuto] ⚠ WARNING: DUTY INCOMPLETE - REWARD NOT RECEIVED!")
            CureEcho("[RelogAuto] Character got stuck or duty failed - retrying...")
            
            -- Don't mark as completed, retry the duty
            CureEcho("[RelogAuto] Re-enabling BTB and sending party invite...")
            CureEnableBTBandInvite()
            CureCharacterSafeWait()
            
            CureEcho("[RelogAuto] Verifying party composition...")
            if not WaitForCompleteParty(currentHelper, partyCheckMaxRetries) then
                CureEcho("[RelogAuto] ERROR: Party verification failed on retry!")
                CureEcho("[RelogAuto] Marking character as failed...")
                local actualCharName = charConfigs[idx][1][1]
                failedCharacters[actualCharName] = true
                
                CureBTBDisband()
                CureSleep(2)
                
                CureEcho("[RelogAuto] Switching to next character...")
                if not switchToNextCharacter() then
                    CureEcho("[RelogAuto] No more characters available.")
                    break
                end
                
                local initSuccess = InitializeCharacter()
                while not initSuccess and rotationStarted do
                    CureEcho("[RelogAuto] Character skipped - trying next character...")
                    if not switchToNextCharacter() then
                        CureEcho("[RelogAuto] No more characters available.")
                        rotationStarted = false
                        break
                    end
                    initSuccess = InitializeCharacter()
                end
                goto continue_loop
            end
            
            CureEcho("[RelogAuto] Party verified - re-queueing for duty...")
            QueueDutyRoulette()
            CureSleep(2)
            
            CureEcho("[RelogAuto] === DUTY RETRY INITIATED ===")
            goto continue_loop
        else
            CureEcho("[RelogAuto] ✓ Duty completion verified - reward received")
        end
        
        local actualCharName = charConfigs[idx][1][1]
        if not completedCharacters[actualCharName] then
            completedCharacters[actualCharName] = true
            CureEcho("[RelogAuto] Character " .. actualCharName .. " marked as completed")
        end
        
        -- === SUBMARINE CHECK POINT ===
        CureEcho("[Subs] === CHECKING SUBMARINE STATUS BEFORE CHARACTER SWITCH ===")
        local subsReady = CheckSubmarines()
        
        if subsReady and not submarinesPaused then
            CureEcho("[Subs] === SUBMARINES READY - ACTIVATING MULTI MODE ===")
            CureEcho("[Subs] Character rotation will resume after submarines complete")
            
            -- Store current character for later verification
            originalCharForSubmarines = charConfigs[idx][1][1]
            CureEcho("[Subs] Stored original character: " .. originalCharForSubmarines)
            
            CureEnableARMulti()
            CureEcho("[Subs] Multi mode enabled - submarines will now run")
            submarinesPaused = true
            
            CureEcho("[Subs] Waiting for submarines to complete...")
            
        else
            CureEcho("[Subs] No submarines ready - continuing with character rotation")
            
            CureEcho("[RelogAuto] Switching to next character...")
            if not switchToNextCharacter() then
                CureEcho("[RelogAuto] No more characters available. Stopping script.")
                break
            end
            
            local initSuccess = InitializeCharacter()
            
            while not initSuccess and rotationStarted do
                CureEcho("[RelogAuto] Character skipped - trying next character...")
                if not switchToNextCharacter() then
                    CureEcho("[RelogAuto] No more characters available. Stopping script.")
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
                CureEcho("[Subs] === NO SUBMARINES READY - CONTINUING ROTATION ===")
                CureSleep(1)
                CureDisableARMulti()
                CureEcho("[Subs] Multi mode disabled - continuing with next character")
                
                submarinesPaused = false
                submarineReloginInProgress = true
                submarineReloginAttempts = 0
            end
        end
    end
    
    -- Handle submarine completion and continue to next character
    if submarineReloginInProgress then
        if CheckSubmarineReloginComplete() then
            CureEcho("[Subs] === SUBMARINE RELOGIN COMPLETE ===")
            CureEcho("[Subs] Current idx: " .. idx .. ", Character: " .. charConfigs[idx][1][1])
            CureEcho("[Subs] This character already completed duty, moving to next...")
            
            CureEcho("[RelogAuto] Switching to next character...")
            local switched = switchToNextCharacter()
            
            if not switched then
                CureEcho("[Subs] No more characters available after submarine completion")
                allCharactersCompleted = true
            else
                CureEcho("[Subs] Switched to new character, initializing...")
                local initSuccess = InitializeCharacter()
                
                while not initSuccess and rotationStarted and not allCharactersCompleted do
                    CureEcho("[RelogAuto] Character skipped - trying next character...")
                    switched = switchToNextCharacter()
                    if not switched then
                        allCharactersCompleted = true
                        break
                    end
                    initSuccess = InitializeCharacter()
                end
            end
        else
            CureSleep(1)
        end
    end
    
    -- Periodic movement check while in duty (once per minute)
    if inDuty then
        local currentTime = os.time()
        if currentTime - lastMovementCheck >= movementCheckInterval then
            CureEcho("[RelogAuto] Executing periodic movement check...")
            CureFullStopMovement()
            lastMovementCheck = currentTime
        end
    end
    
    ::continue_loop::
    
    CureSleep(1)
end

CureEcho("[RelogAuto] === AD RELOG AUTOMATION ENDED ===")

CureEcho("[RelogAuto] All characters processed or script manually stopped")

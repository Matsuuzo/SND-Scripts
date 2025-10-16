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

require("curefunc")

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
        CureEcho("[Helper] ERROR: Svc.Party not available")
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
        CureEcho("[Helper] No toon specified - skipping verification")
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
        CureEcho("[Helper] Solo (no party members)")
        return
    end
    
    CureEcho("[Helper] Party has " .. partySize .. " member(s):")
    for i, name in ipairs(members) do
        CureEcho("[Helper]   " .. i .. ". " .. name)
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
    CureEcho("[Helper] === WAITING FOR PARTY INVITE ===")
    CureEcho("[Helper] Will accept ANY party invite and determine correct helper")
    CureEcho("[Helper] Timeout: " .. timeout .. " seconds")
    
    local startTime = os.time()
    local lastCheck = 0
    
    while os.time() - startTime < timeout do
        -- Check if we're in a party
        if IsInParty() then
            CureEcho("[Helper] ✓ Party invite received!")
            CureSleep(2)
            
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
                CureEcho("[Helper] ✓ Found main character in party: " .. foundMainChar)
                CureEcho("[Helper] ✓ This party needs helper: " .. foundHelperName)
                return true, "found", foundMainChar, foundHelperIdx, foundHelperName
            else
                CureEcho("[Helper] ✗ No recognized main character in party!")
                CureEcho("[Helper] Party members are not in the helper configuration")
                return true, "unknown", nil, nil, nil
            end
        end
        
        -- Progress update every 30 seconds
        local elapsed = os.time() - startTime
        if elapsed - lastCheck >= 30 then
            local remaining = timeout - elapsed
            CureEcho("[Helper] Still waiting for invite... (" .. remaining .. " seconds remaining)")
            lastCheck = elapsed
        end
        
        CureSleep(1)
    end
    
    CureEcho("[Helper] ✗ TIMEOUT: No party invite received after " .. timeout .. " seconds")
    return false, "timeout", nil, nil, nil
end

-- ===============================================
-- Daily Reset Functions
-- ===============================================

local function CheckMidnight()
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    if currentHour < dailyResetHour and dailyResetTriggered then
        CureEcho("[DailyReset] === MIDNIGHT RESET ===")
        dailyResetTriggered = false
        
        -- WICHTIG: Multi Mode deaktivieren falls aktiv
        if allHelpersCompleted then
            CureEcho("[DailyReset] Deactivating Multi Mode...")
            CureDisableARMulti()
            CureSleep(2)
            
            -- Rotation neu starten
            if ResetRotation() then
                allHelpersCompleted = false
                local initSuccess = InitializeHelper()
                
                while not initSuccess and rotationStarted do
                    if not switchToNextHelper() then
                        allHelpersCompleted = true
                        break
                    end
                    initSuccess = InitializeHelper()
                end
            end
        end
        
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
    CureEcho("[DailyReset] === RESETTING HELPER ROTATION ===")
    
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
        CureEcho("[DailyReset] ERROR: First helper configuration is invalid")
        return false
    end
    
    CureEcho("[DailyReset] Rotation reset complete - starting from first helper")
    CureEcho("[DailyReset] First helper: " .. helperConfigs[1][1][1])
    CureEcho("[DailyReset] Expected toon: " .. currentToon)
    
    -- Relog to first helper
    if CureARRelog(helperConfigs[1][1][1]) then
        CureEnableTextAdvance()
        CureSleep(2)
        return true
    else
        CureEcho("[DailyReset] ERROR: Failed to relog to first helper")
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

local function CheckSubmarineReloginComplete()
    if not submarineReloginInProgress then
        return true
    end
    
    -- Check if we have a valid original helper stored
    if not originalHelperForSubmarines or originalHelperForSubmarines == "" then
        CureEcho("[Subs] WARNING: No original helper stored, marking submarine relogin as complete")
        submarineReloginInProgress = false
        return true
    end
    
    -- Verify current character matches original
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedName = originalHelperForSubmarines:match("^([^@]+)")
    
    if not expectedName then
        CureEcho("[Subs] WARNING: Could not extract expected name, marking submarine relogin as complete")
        submarineReloginInProgress = false
        originalHelperForSubmarines = nil
        return true
    end
    
    local actualLower = tostring(actualName):lower()
    local expectedLower = tostring(expectedName):lower()
    
    if actualLower == expectedLower then
        CureEcho("[Subs] Submarine relogin verification passed")
        submarineReloginInProgress = false
        submarineReloginAttempts = 0
        originalHelperForSubmarines = nil  -- Reset after successful verification
        
        CureCharacterSafeWait()
        
        submarinesPaused = false
        
        CureEcho("[Subs] === SAFETY VALIDATION COMPLETE ===")
        CureEcho("[Subs] Resuming normal rotation on original helper")
        
        return true
    else
        CureEcho("[Subs] WARNING: Character mismatch after submarines. Expected: " .. expectedName .. ", Actual: " .. actualName)
        CureEcho("[Subs] Marking submarine relogin as complete anyway to continue rotation")
        submarineReloginInProgress = false
        originalHelperForSubmarines = nil
        return true
    end
end

-- ===============================================
-- Duty Roulette Check Functions
-- ===============================================

local function CheckDutyRouletteReward()
    CureEcho("[Helper] === CHECKING DUTY ROULETTE REWARD STATUS ===")
    
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
        CureEcho("[Helper] ERROR: Failed to read reward status - " .. tostring(err))
        yield("/callback ContentsFinder true -1")
        CureSleep(1)
        return false, "error"
    end
    
    CureEcho("[Helper] Reward Text: [" .. tostring(rewardReceived) .. "]")
    
    yield("/callback ContentsFinder true -1")
    CureSleep(1)
    
    if rewardReceived and rewardReceived ~= "" then
        CureEcho("[Helper] === ROULETTE COMPLETED (TEXT FOUND) ===")
        return true, "completed"
    else
        CureEcho("[Helper] === ROULETTE AVAILABLE (NO TEXT) ===")
        return true, "available"
    end
end

-- ===============================================
-- DC Travel Functions
-- ===============================================

local function PerformDCTravel()
    if dcTravelCompleted then
        CureEcho("[Helper] DC Travel already completed for this character")
        return true
    end
    
    CureEcho("[Helper] === INITIATING DATA CENTER TRAVEL ===")
    CureEcho("[Helper] Target world: " .. dcTravelWorld)
    
    CureLifestreamCmd(dcTravelWorld)
    CureWaitForLifestream()
    CureCharacterSafeWait()
    
    CureEcho("[Helper] === DATA CENTER TRAVEL COMPLETE ===")
    CureEcho("[Helper] Now on world: " .. dcTravelWorld)
    
    CureEcho("[Helper] Teleporting to Summerford...")
    yield("/li Summerford")
    CureSleep(10)
    
    dcTravelCompleted = true
    return true
end

local function ReturnToHomeworld()
    if not dcTravelCompleted then
        CureEcho("[Helper] No DC travel was performed - skipping homeworld return")
        return true
    end
    
    CureEcho("[Helper] === RETURNING TO HOMEWORLD ===")
    
    CureReturnToHomeworld()
    
    CureEcho("[Helper] === HOMEWORLD RETURN COMPLETE ===")
    dcTravelCompleted = false
    return true
end

-- ===============================================
-- Character Management Functions
-- ===============================================

local function VerifyCharacterSwitch(expectedName)
    if not expectedName or expectedName == "" then
        CureEcho("[Helper] ERROR: No expected name provided for verification")
        return false
    end
    
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedLower = tostring(expectedName):lower()
    local actualLower = tostring(actualName):lower()
    
    if actualLower == expectedLower then
        CureEcho("[Helper] Character switch verified: Now playing as " .. actualName)
        return true
    end
    
    CureEcho("[Helper] ERROR: Character switch failed! Expected: " .. expectedName .. ", Actual: " .. actualName)
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
    
    CureEcho("[Helper] DEBUG: Looking for next helper. Current idx: " .. (currentIdx or "nil"))
    
    while attempts < #helperConfigs do
        nextIdx = nextIdx + 1
        if nextIdx > #helperConfigs then
            -- Reached end of rotation
            CureEcho("[Helper] DEBUG: Reached end of helper list")
            return nil, nil
        end
        
        local helperName = helperConfigs[nextIdx][1][1]
        local isFailed = failedHelpers[helperName] or false
        local isSkipped = skippedHelpers[helperName] or false
        local isCompleted = completedHelpers[helperName] or false
        
        CureEcho("[Helper] DEBUG: Checking helper " .. nextIdx .. ": " .. helperName .. 
               " (Failed: " .. tostring(isFailed) .. ", Skipped: " .. tostring(isSkipped) .. ", Completed: " .. tostring(isCompleted) .. ")")
        
        -- Available if: not failed AND not completed (skipped is okay!)
        if not isFailed and not isCompleted then
            CureEcho("[Helper] DEBUG: Found available helper: " .. helperName)
            return nextIdx, helperName
        end
        
        attempts = attempts + 1
    end
    
    CureEcho("[Helper] DEBUG: No available helpers found in remaining list")
    return nil, nil
end

local function attemptHelperLogin(targetIdx)
    local targetHelper = helperConfigs[targetIdx][1][1]
    CureEcho("[Helper] Attempting to log into: " .. targetHelper)
    
    if CureARRelog(targetHelper) then
        return true
    else
        failedHelpers[targetHelper] = true
        CureEcho("[Helper] FAILED: Helper " .. targetHelper .. " marked as failed after " .. maxRelogAttempts .. " attempts")
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
    
    CureEcho(string.format("[Helper] Rotation Status: %d/%d runs remaining (%d completed, %d failed, %d skipped)", 
        remainingCount, totalHelpers, completedCount, failedCount, skippedCount))
end

local function switchToNextHelper()
    reportRotationStatus()
    
    -- Check if we hit 2 consecutive timeouts
    if consecutiveTimeouts >= maxConsecutiveTimeouts then
        CureEcho("[Helper] === 2 CONSECUTIVE TIMEOUTS REACHED ===")
        CureEcho("[Helper] Main account stopped inviting")
        CureEcho("[Helper] Activating Multi Mode until daily reset...")
        
        CureEnableARMulti()
        allHelpersCompleted = true
        
        CureEcho("[Helper] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    -- Try to find next available helper
    local nextIdx, nextHelper = getNextAvailableHelper(idx)
    
    if not nextIdx then
        -- Reached end of helper list
        CureEcho("[Helper] === LAST CHARACTER REACHED ===")
        CureEcho("[Helper] Completed rotation through all helpers")
        CureEcho("[Helper] Activating Multi Mode until daily reset...")
        
        CureEnableARMulti()
        allHelpersCompleted = true
        
        CureEcho("[Helper] Multi Mode enabled - waiting for daily reset at " .. dailyResetHour .. ":00 UTC+1")
        return false
    end
    
    CureEcho("[Helper] Switching to next run: " .. nextHelper .. " (for " .. helperConfigs[nextIdx][2] .. ")")
    
    if attemptHelperLogin(nextIdx) then
        CureEcho("[Helper] DEBUG: Updating idx from " .. (idx or "nil") .. " to " .. nextIdx)
        if helperConfigs[nextIdx] and helperConfigs[nextIdx][1] and helperConfigs[nextIdx][1][1] then
            currentHelper = tostring(nextHelper):lower()
            currentToon = helperConfigs[nextIdx][2] and tostring(helperConfigs[nextIdx][2]) or ""
            idx = nextIdx
            
            CureEcho("[Helper] DEBUG: Current helper updated to: " .. currentHelper .. " (idx: " .. idx .. ")")
            CureEcho("[Helper] DEBUG: Expected toon: " .. currentToon)
        else
            CureEcho("[Helper] ERROR: Invalid helper configuration at index " .. nextIdx)
            return false
        end
        
        CureEnableTextAdvance()
        CureSleep(2)
        
        return true
    else
        return switchToNextHelper()
    end
end

-- ===============================================
-- Helper Initialization
-- ===============================================

local function InitializeHelper()
    CureEcho("[Helper] === INITIALIZING HELPER ===")
    CureEcho("[Helper] Current Helper: " .. helperConfigs[idx][1][1])
    
    -- Step 1: Check if Duty Roulette reward already received
    CureEcho("[Helper] Step 1: Checking Duty Roulette reward status...")
    local checkSuccess, rewardStatus = CheckDutyRouletteReward()
    
    if not checkSuccess then
        CureEcho("[Helper] ERROR: Failed to check roulette status - marking helper as failed")
        local actualHelperName = helperConfigs[idx][1][1]
        failedHelpers[actualHelperName] = true
        CureEcho("[Helper] === HELPER INITIALIZATION ABORTED (ERROR) ===")
        return false
    end
    
    if rewardStatus == "completed" then
        CureEcho("[Helper] *** REWARD ALREADY RECEIVED - SKIPPING HELPER ***")
        local actualHelperName = helperConfigs[idx][1][1]
        completedHelpers[actualHelperName] = true
        CureEcho("[Helper] === HELPER INITIALIZATION ABORTED (COMPLETED) ===")
        return false
    end
    
    CureEcho("[Helper] Roulette available - proceeding with DC Travel and party wait")
    
    -- Step 2: Disable BTB (if enabled)
    CureEcho("[Helper] Step 2: Disabling BTB...")
    yield("/xldisableprofile BTB")
    CureSleep(2)
    CureCharacterSafeWait()
    
    -- Step 3: Perform DC Travel
    CureEcho("[Helper] Step 3: Performing Data Center Travel...")
    PerformDCTravel()
    CureCharacterSafeWait()
    
    -- Step 4: Enable BTB
    CureEcho("[Helper] Step 4: Enabling BTB...")
    yield("/xlenableprofile BTB")
    CureSleep(2)
    CureCharacterSafeWait()
    
    -- Step 5: Wait for party invite and determine correct helper
    CureEcho("[Helper] Step 5: Waiting for party invite...")
    waitingForInvite = true
    local invited, status, foundMain, foundIdx, foundHelper = WaitForPartyInvite(partyCheckTimeout)
    waitingForInvite = false
    
    if not invited then
        CureEcho("[Helper] ERROR: No party invite received - marking current helper as SKIPPED (can retry later)")
        local actualHelperName = helperConfigs[idx][1][1]
        skippedHelpers[actualHelperName] = true
        consecutiveTimeouts = consecutiveTimeouts + 1
        CureEcho("[Helper] Consecutive timeouts: " .. consecutiveTimeouts .. "/" .. maxConsecutiveTimeouts)
        CureEcho("[Helper] === HELPER INITIALIZATION ABORTED (NO INVITE) ===")
        
        yield("/xldisableprofile BTB")
        CureSleep(2)
        ReturnToHomeworld()
        return false
    end
    
    if status == "unknown" then
        CureEcho("[Helper] ERROR: Party member not recognized in configuration")
        CureEcho("[Helper] === HELPER INITIALIZATION ABORTED (UNKNOWN MAIN) ===")
        CureEcho("[Helper] Marking as SKIPPED (can retry if needed)")
        
        local actualHelperName = helperConfigs[idx][1][1]
        skippedHelpers[actualHelperName] = true
        consecutiveTimeouts = consecutiveTimeouts + 1
        CureEcho("[Helper] Consecutive timeouts: " .. consecutiveTimeouts .. "/" .. maxConsecutiveTimeouts)
        
        yield("/xldisableprofile BTB")
        CureSleep(2)
        yield("/leave")
        CureSleep(2)
        ReturnToHomeworld()
        return false
    end
    
    -- Successfully got a valid invite - reset timeout counter
    consecutiveTimeouts = 0
    CureEcho("[Helper] Valid invite received - timeout counter reset")
    
    -- Check if we need to switch to a different helper
    if foundIdx ~= idx then
        CureEcho("[Helper] ✓ Party has main character: " .. foundMain)
        CureEcho("[Helper] ✓ This requires helper: " .. foundHelper)
        CureEcho("[Helper] ⚠ Current helper is wrong - switching now...")
        
        -- Leave party and return home
        yield("/xldisableprofile BTB")
        CureSleep(2)
        yield("/leave")
        CureSleep(2)
        ReturnToHomeworld()
        
        -- Check if target helper is already completed or failed
        if completedHelpers[foundHelper] then
            CureEcho("[Helper] ✗ Required helper already completed: " .. foundHelper)
            CureEcho("[Helper] Cannot switch to completed helper")
            CureEcho("[Helper] Marking current helper as SKIPPED")
            local actualHelperName = helperConfigs[idx][1][1]
            skippedHelpers[actualHelperName] = true
            return false
        end
        
        if failedHelpers[foundHelper] then
            CureEcho("[Helper] ✗ Required helper marked as HARD FAILED: " .. foundHelper)
            CureEcho("[Helper] Cannot switch to hard failed helper")
            CureEcho("[Helper] Marking current helper as SKIPPED")
            local actualHelperName = helperConfigs[idx][1][1]
            skippedHelpers[actualHelperName] = true
            return false
        end
        
        -- Check if target helper was skipped - if so, CLEAR the skip flag!
        if skippedHelpers[foundHelper] then
            CureEcho("[Helper] ✓ Required helper was SKIPPED earlier: " .. foundHelper)
            CureEcho("[Helper] Clearing skip flag - this helper is now needed!")
            skippedHelpers[foundHelper] = nil
        end
        
        -- Switch to the correct helper
        CureEcho("[Helper] Switching to correct helper: " .. foundHelper)
        if CureARRelog(foundHelper) then
            -- Clear skip flag if it was set
            if skippedHelpers[foundHelper] then
                CureEcho("[Helper] Clearing skip flag for: " .. foundHelper)
                skippedHelpers[foundHelper] = nil
            end
            
            idx = foundIdx
            currentHelper = tostring(foundHelper):lower()
            currentToon = foundMain
            
            CureEcho("[Helper] ✓ Successfully switched to correct helper!")
            CureEcho("[Helper] Now running as: " .. foundHelper)
            CureEcho("[Helper] For main character: " .. foundMain)
            
            CureEnableTextAdvance()
            CureSleep(2)
            
            -- Restart initialization with correct helper
            return InitializeHelper()
        else
            CureEcho("[Helper] ERROR: Failed to switch to correct helper")
            failedHelpers[foundHelper] = true
            return false
        end
    end
    
    -- Current helper is correct
    CureEcho("[Helper] ✓ Correct helper for main character: " .. foundMain)
    CureEcho("[Helper] === HELPER INITIALIZATION COMPLETE ===")
    CureEcho("[Helper] Ready for duty!")
    return true
end

-- ===============================================
-- Initialize rotation
-- ===============================================

idx = getHelperIndex(currentHelper)
if not idx then
    CureEcho("[Helper] Start helper not in rotation: " .. currentHelper)
    -- Try to start with first helper
    idx = 1
    currentHelper = helperConfigs[1][1][1] and tostring(helperConfigs[1][1][1]):lower() or ""
    currentToon = helperConfigs[1][2] and tostring(helperConfigs[1][2]) or ""
end

local loginSuccess = false
local currentIdx = idx

CureEcho("[Helper] === STARTING HELPER AUTOMATION WITH ROTATION ===")
InitializeDailyResetState()
CureEcho("[Helper] Daily Reset Time: " .. dailyResetHour .. ":00 UTC+1")
CureEcho("[Helper] Starting helper rotation...")
reportRotationStatus()

-- Initial login
while not loginSuccess and #failedHelpers < #helperConfigs do
    if attemptHelperLogin(currentIdx) then
        loginSuccess = true
        idx = currentIdx
        currentToon = helperConfigs[idx][2] and tostring(helperConfigs[idx][2]) or ""
        CureEcho("[Helper] Successfully logged into: " .. helperConfigs[idx][1][1])
        CureEcho("[Helper] Expected toon: " .. currentToon)
    else
        local nextIdx, nextHelper = getNextAvailableHelper(currentIdx)
        if nextIdx then
            CureEcho("[Helper] Trying next helper: " .. nextHelper)
            currentIdx = nextIdx
        else
            CureEcho("[Helper] FATAL: All helpers have failed login attempts!")
            return
        end
    end
end

if not loginSuccess then
    CureEcho("[Helper] FATAL: Unable to log into any helper. Stopping script.")
    return
end

-- Initialize first helper
CureCharacterSafeWait()
CureEnableTextAdvance()
CureSleep(2)

local initSuccess = InitializeHelper()

-- If first helper initialization failed, keep trying
while not initSuccess and rotationStarted do
    CureEcho("[Helper] Initialization failed - trying next helper")
    if not switchToNextHelper() then
        CureEcho("[Helper] No more helpers available. Stopping script.")
        return
    end
    initSuccess = InitializeHelper()
end

if not initSuccess then
    CureEcho("[Helper] All helpers failed initialization. Stopping script.")
    return
end

-- ===============================================
-- Main Loop
-- ===============================================

CureEcho("[Helper] === ENTERING MAIN LOOP ===")

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
    
    -- === DAILY RESET CHECK (when all helpers are done and waiting) ===
    if allHelpersCompleted then
        if currentTime - lastDailyResetCheck >= dailyResetCheckInterval then
            lastDailyResetCheck = currentTime
            
            if CheckDailyReset() and not dailyResetTriggered then
                CureEcho("[DailyReset] === DAILY RESET TRIGGERED (All Helpers Idle) ===")
                dailyResetTriggered = true
                
                CureDisableARMulti()
                CureSleep(2)
                
                if ResetRotation() then
                    allHelpersCompleted = false
                    
                    local initSuccess = InitializeHelper()
                    
                    while not initSuccess and rotationStarted do
                        CureEcho("[Helper] Helper skipped after reset - trying next helper...")
                        if not switchToNextHelper() then
                            CureEcho("[Helper] All helpers already completed after reset.")
                            allHelpersCompleted = true
                            break
                        end
                        initSuccess = InitializeHelper()
                    end
                else
                    CureEcho("[DailyReset] ERROR: Failed to reset rotation")
                end
            end
        end
        
        -- If all helpers completed, just sleep and continue checking for reset
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
        CureEcho("[Helper] === ENTERED DUTY ===")
        CureSleep(dutyDelay)
        
        if not adRunActive then
            CureAd("start")
            adRunActive = true
            CureEcho("[Helper] AutoDuty started after entering duty")
        end
        
        CureVbmai("on")
        CureSleep(3)
        CureFullStopMovement()
        CureEcho("[Helper] Movement stopped after entering duty")
        
        lastMovementCheck = os.time()
        
    elseif not inDuty and wasInDuty then
    CureEcho("[Helper] === LEFT DUTY ===")
    adRunActive = false
    CureSleep(1)
    CureAd("stop")
    CureEcho("[Helper] Left duty - AutoDuty reset")
    
    CureEcho("[Helper] Disabling BTB...")
    yield("/xldisableprofile BTB")
    CureSleep(2)
    
    CureEcho("[Helper] Disbanding party...")
    CureBTBDisband()
    CureSleep(5)
    
    CureEcho("[Helper] Returning to homeworld...")
    ReturnToHomeworld()
    CureSleep(2)
    
    if CheckDailyReset() and not dailyResetTriggered then
        CureEcho("[DailyReset] === DAILY RESET DETECTED AFTER DUTY ===")
        dailyResetTriggered = true
        
        local actualHelperName = helperConfigs[idx][1][1]
        completedHelpers[actualHelperName] = true
        
        if allHelpersCompleted then
            CureDisableARMulti()
            CureSleep(2)
        end
        
        if ResetRotation() then
            allHelpersCompleted = false
            local initSuccess = InitializeHelper()
            
            while not initSuccess and rotationStarted do
                if not switchToNextHelper() then
                    allHelpersCompleted = true
                    break
                end
                initSuccess = InitializeHelper()
            end
            goto continue_loop
        end
    end
    
    -- Duty Completion Check 
    CureEcho("[Helper] === VERIFYING DUTY COMPLETION ===")
    local checkSuccess, rewardStatus = CheckDutyRouletteReward()
    
    if not checkSuccess then
        CureEcho("[Helper] WARNING: Could not verify - marking as completed anyway")
        local actualHelperName = helperConfigs[idx][1][1]
        completedHelpers[actualHelperName] = true
    elseif rewardStatus == "completed" then
        CureEcho("[Helper] ✓ Duty completion verified")
        local actualHelperName = helperConfigs[idx][1][1]
        completedHelpers[actualHelperName] = true
    elseif rewardStatus == "available" then
        CureEcho("[Helper] WARNING: Reward not received - will retry once")
        -- NUR 1x Retry, dann als completed markieren
        PerformDCTravel()
        yield("/xlenableprofile BTB")
        CureSleep(2)
        
        waitingForInvite = true
        local invited, status = WaitForPartyInvite(partyCheckTimeout)
        waitingForInvite = false
        
        if not invited or status == "unknown" then
            CureEcho("[Helper] Retry failed - marking as completed to prevent loop")
            local actualHelperName = helperConfigs[idx][1][1]
            completedHelpers[actualHelperName] = true
        else
            goto continue_loop  -- Retry duty
        end
    end
    
    -- SUBMARINES CHECK
    local subsReady = CheckSubmarines()
    if subsReady and not submarinesPaused then
        originalHelperForSubmarines = helperConfigs[idx][1][1]
        CureEnableARMulti()
        submarinesPaused = true
    else
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
                CureEcho("[Subs] Multi mode disabled - continuing with next helper")
                
                submarinesPaused = false
                submarineReloginInProgress = true
                submarineReloginAttempts = 0
            end
        end
    end
    
    -- Handle submarine completion and continue to next helper
    if submarineReloginInProgress then
        if CheckSubmarineReloginComplete() then
            CureEcho("[Subs] === CONTINUING TO NEXT HELPER ===")
            
            CureEcho("[Helper] Switching to next helper...")
            local switched = switchToNextHelper()
            
            if not switched then
                allHelpersCompleted = true
            else
                local initSuccess = InitializeHelper()
                
                while not initSuccess and rotationStarted and not allHelpersCompleted do
                    CureEcho("[Helper] Initialization failed - trying next helper...")
                    switched = switchToNextHelper()
                    if not switched then
                        allHelpersCompleted = true
                        break
                    end
                    initSuccess = InitializeHelper()
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
            CureEcho("[Helper] Executing periodic movement check...")
            CureFullStopMovement()
            lastMovementCheck = currentTime
        end
    end
    
    ::continue_loop::
    
    CureSleep(1)
end

CureEcho("[Helper] === HELPER AUTOMATION ENDED ===")
CureEcho("[Helper] All runs completed or script manually stopped")


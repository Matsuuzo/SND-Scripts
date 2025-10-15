-- ┌-----------------------------------------------------------------------------------------------------------------------
-- |
-- |    ██████╗██╗   ██╗██████╗ ███████╗    ███████╗██╗   ██╗███╗   ██╗ ██████╗
-- |   ██╔════╝██║   ██║██╔══██╗██╔════╝    ██╔════╝██║   ██║████╗  ██║██╔════╝
-- |   ██║     ██║   ██║██████╔╝█████╗      █████╗  ██║   ██║██╔██╗ ██║██║     
-- |   ██║     ██║   ██║██╔══██╗██╔══╝      ██╔══╝  ██║   ██║██║╚██╗██║██║     
-- |   ╚██████╗╚██████╔╝██║  ██║███████╗    ██║     ╚██████╔╝██║ ╚████║╚██████╗
-- |    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝
-- |
-- | Comprehensive Function Library for FFXIV SomethingNeedDoing Automation
-- |
-- | Curefunc provides a robust collection of helper functions for automating FFXIV gameplay through
-- | SomethingNeedDoing scripts. This library includes movement, UI, player management, and world
-- | interaction utilities designed for reliable multi-character automation workflows.
-- |
-- | Version: 2.2
-- | Last Updated: 2025-10-15
-- |
-- └-----------------------------------------------------------------------------------------------------------------------
--┌-----------------------------------------------------------------------------------------------------------------------
--| Installation:
--|   Add the lua scripts manually in SND or use the GitHub Auto updating function.
--|   The SND Script MUST be named: curefunc
--└-----------------------------------------------------------------------------------------------------------------------
--┌-----------------------------------------------------------------------------------------------------------------------
--| Usage:
--|   Add These lines at the start of your script:
--|   require("curefunc")
--|   require("xafunc")
--└-----------------------------------------------------------------------------------------------------------------------
--┌-----------------------------------------------------------------------------------------------------------------------
--| Dependencies:
--|   xafunc (required) - https://github.com/xa-io/ffxiv-tools/blob/main/snd/xafunc.lua
--|   curefunc (this file) - https://github.com/MacaronDream/SND-Scripts/tree/main/curefunc.lua
--└-----------------------------------------------------------------------------------------------------------------------
--┌-----------------------------------------------------------------------------------------------------------------------
--| TABLE OF CONTENTS
--|
--| 1. PLUGIN INTEGRATION FUNCTIONS
--|    - AutoDuty, AutoRetainer, BMR, VBM, RSR, Questionable
--|
--| 2. CHARACTER & ACCOUNT MANAGEMENT (ENHANCED)
--|    - Login, Logout, Character Switching, Rotation Management
--|    - Flexible Config Support: Multiple formats supported
--|    - Character Index/Name Lookup with validation
--|    - Automated Character Switching with retry logic
--|    - Rotation State Management
--|
--| 3. PARTY & SOCIAL FUNCTIONS (ENHANCED)
--|    - Party Management, BTB (Bring The Boys), Member Verification
--|    - Automated Party Waiting with configurable retry
--|    - Flexible helper verification
--|
--| 4. PLAYER STATE & CONDITION
--|    - Death Handling, Availability Checks, Position Data
--|
--| 5. WORLD & NAVIGATION
--|    - Teleportation, Lifestream, Navmesh, Pathfinding
--|
--| 6. UI & ADDON MANAGEMENT
--|    - Addon Checks, Callbacks, Yes/No Selection
--|
--| 7. GAME DATA QUERIES
--|    - Zone Info, Grand Company, Class/Job, World Data
--|
--| 8. TIMING & SCHEDULING
--|    - Daily Resets, Submarine Checks, Duty Roulette Status
--|
--| 9. UTILITY FUNCTIONS
--|    - Echo, Sleep, Target, Movement, Text Advance
--|
--| 10. Quest Functions
--|    - Chocobo Handling, Steps of Faith Handling
--|
--| 11. DATA TABLES
--|    - World/Homeworld Lookup Table
--|
--└-----------------------------------------------------------------------------------------------------------------------
--┌-----------------------------------------------------------------------------------------------------------------------
--| GENERALIZED CHARACTER MANAGEMENT SYSTEM - QUICK START GUIDE
--|
--| The enhanced CureFunc now supports flexible character configuration formats and provides
--| comprehensive functions for managing multi-character rotations in your scripts.
--|
--| SUPPORTED CHARACTER CONFIG FORMATS:
--|   1. Nested with helper:    {{"Name@World"}, "Helper Name"}
--|   2. Flat with helper:       {"Name@World", "Helper Name"}
--|   3. Simple array:           {"Name@World"}
--|   4. Direct string:          "Name@World"
--|
--| BASIC USAGE EXAMPLE:
--|
--|   -- Define your character list (any format works)
--|   local charConfigs = {
--|       {{"John Doe@Omega"}, "Tank Helper"},
--|       {{"Jane Smith@Phoenix"}, "Healer Helper"},
--|       {{"Bob Jones@Cerberus"}, nil}  -- No helper required
--|   }
--|   
--|   -- Initialize rotation
--|   local ok, idx, currentChar, currentHelper, failedChars, completedChars, err = 
--|       CureInitializeRotation(charConfigs)
--|   
--|   if not ok then
--|       CureEcho("Init failed: " .. err)
--|       return
--|   end
--|   
--|   -- Main loop
--|   while true do
--|       -- Do your script logic here
--|       
--|       -- When ready to switch to next character:
--|       local success, newIdx, newChar, newHelper = CureSwitchToNextCharacter(
--|           idx, charConfigs, failedChars, completedChars, 3,
--|           function(charName, helper)
--|               CureEnableTextAdvance()
--|               -- Add any post-switch setup here
--|           end
--|       )
--|       
--|       if not success then
--|           CureEcho("All characters processed!")
--|           break
--|       end
--|       
--|       idx = newIdx
--|       currentChar = newChar
--|       currentHelper = newHelper
--|   end
--|
--| KEY FUNCTIONS:
--|   - CureInitializeRotation()        : Validate config and initialize rotation state
--|   - CureGetCharIndex()              : Find character by name (flexible search)
--|   - CureExtractCharacterName()      : Extract name from any config format
--|   - CureExtractCharacterFullName()  : Extract full "Name@World" from config
--|   - CureExtractCharacterHelper()    : Extract helper name if present
--|   - CureSwitchToNextCharacter()     : Complete character switching workflow
--|   - CureWaitForCompleteParty()      : Wait for party with automatic retry
--|   - CureVerifyCharacterSwitch()     : Verify character switch succeeded
--|
--└-----------------------------------------------------------------------------------------------------------------------

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 1. PLUGIN INTEGRATION FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureAd(text)
--│ Controls AutoDuty plugin commands
--│
--│ Parameters:
--│   text (string) - Command to send to AutoDuty (e.g., "start", "stop")
--│
--│ Usage:
--│   CureAd("start")  -- Starts AutoDuty
--│   CureAd("stop")   -- Stops AutoDuty
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureAd(text)
    yield("/ad " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureARDiscard()
--│ Triggers AutoRetainer's discard function to clean inventory
--│
--│ Returns:
--│   boolean - true when discard operation completes
--│
--│ Usage:
--│   CureARDiscard()  -- Cleans inventory using AR's discard rules
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureARDiscard()
    yield("/ays discard")
    while CureAutoRetainerIsBusy() do
        CureSleep(1)
    end
    return true
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureAutoRetainerIsBusy()
--│ Checks if AutoRetainer is currently performing operations
--│
--│ Returns:
--│   boolean - true if AR is busy, false otherwise
--│
--│ Usage:
--│   if not CureAutoRetainerIsBusy() then
--│       -- Proceed with next action
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureAutoRetainerIsBusy()
    return IPC.AutoRetainer.IsBusy()
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureDisableARMulti()
--│ Disables AutoRetainer's multi-mode
--│
--│ Usage:
--│   CureDisableARMulti()  -- Disables multi-character retainer processing
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureDisableARMulti()
    yield("/ays multi d")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEnableARMulti()
--│ Enables AutoRetainer's multi-mode
--│
--│ Usage:
--│   CureEnableARMulti()  -- Enables multi-character retainer processing
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEnableARMulti()
    yield("/ays multi e")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureBmrai(text)
--│ Controls BossMod Reborn AI commands
--│
--│ Parameters:
--│   text (string) - Command for BMRAI (e.g., "on", "off")
--│
--│ Usage:
--│   CureBmrai("on")   -- Enables BMR AI
--│   CureBmrai("off")  -- Disables BMR AI
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureBmrai(text)
    yield("/bmrai " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureVbmai(text)
--│ Controls VBM AI commands
--│
--│ Parameters:
--│   text (string) - Command for VBM AI
--│
--│ Usage:
--│   CureVbmai("on")   -- Enables VBM AI
--│   CureVbmai("off")  -- Disables VBM AI
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureVbmai(text)
    yield("/vbmai " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureVbmar(text)
--│ Controls VBM Auto Rotation settings
--│
--│ Parameters:
--│   text (string) - AR command (e.g., "enable", "disable")
--│
--│ Usage:
--│   CureVbmar("disable")  -- Disables VBM auto rotation
--│   CureVbmar("enable")   -- Enables VBM auto rotation
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureVbmar(text)
    yield("/vbm ar " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureRSR(text)
--│ Controls Rotation Solver Reborn settings
--│
--│ Parameters:
--│   text (string) - Mode setting ("auto", "manual", "off")
--│
--│ Usage:
--│   CureRSR("auto")    -- Sets RSR to auto mode
--│   CureRSR("manual")  -- Sets RSR to manual mode
--│   CureRSR("off")     -- Disables RSR
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureRSR(text)
    yield("/rsr " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureQSTReload()
--│ Reloads Questionable plugin
--│
--│ Usage:
--│   CureQSTReload()  -- Reloads Questionable quest system
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureQSTReload()
    CureSleep(1)
    yield("/qst reload")
    CureSleep(2)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureQSTStart()
--│ Starts Questionable plugin execution
--│
--│ Usage:
--│   CureQSTStart()  -- Starts Questionable quest automation
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureQSTStart()
    CureSleep(1)
    yield("/qst start")
    CureSleep(2)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureQSTStop()
--│ Stops Questionable plugin execution
--│
--│ Usage:
--│   CureQSTStop()  -- Stops Questionable quest automation
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureQSTStop()
    CureSleep(1)
    yield("/qst stop")
    CureSleep(2)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 2. CHARACTER & ACCOUNT MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureARRelog(name)
--│ Uses AutoRetainer to relog into specified character with full state verification
--│
--│ Parameters:
--│   name (string) - Character name in format "Name@World"
--│
--│ Returns:
--│   boolean - true if relog successful, false otherwise
--│
--│ Usage:
--│   CureARRelog("John Doe@Omega")  -- Relogs to character on Omega
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureARRelog(name)
    local who = (type(name) == "string") and name:match('^%s*(.-)%s*$') or ""
    who = who:gsub('^"(.*)"$', '%1'):gsub("^'(.*)'$", "%1")

    if who == "" then
        CureEcho("ARRelog: No character provided.")
        return false
    end

    CureEcho("Logging into " .. who)
    yield("/ays relog " .. who)
    CureSleep(1)
    CureWaitForARToFinish()
    CureEcho("Sending CharacterSafeWait 1/4")
    CureSafeWait()
    CureSleep(1.01)
    CureEcho("Sending CharacterSafeWait 2/4")
    CureSafeWait()
    CureSleep(1.02)
    CureEcho("Sending CharacterSafeWait 3/4")
    CureSafeWait()
    CureSleep(1.03)
    CureEcho("Sending CharacterSafeWait 4/4")
    CureSafeWait()
    CureSleep(1.04)
    return true
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CurePerformCharacterRelog(targetChar, maxRetries)
--│ Attempts character relog with retry logic and verification
--│
--│ Parameters:
--│   targetChar (string) - Character name in "Name@World" format
--│   maxRetries (number) - Maximum retry attempts (default: 3)
--│
--│ Returns:
--│   boolean - true if relog verified successful, false after max retries
--│
--│ Usage:
--│   if CurePerformCharacterRelog("Jane Doe@Phoenix", 5) then
--│       -- Character switch verified
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CurePerformCharacterRelog(targetChar, maxRetries)
    CureARRelog(targetChar)
    if not targetChar or targetChar == "" then
        CureEcho("ERROR: No target character specified")
        return false
    end
    
    maxRetries = maxRetries or 3
    local expectedName = targetChar:match("^([^@]+)")
    
    if not expectedName then
        CureEcho("ERROR: Could not extract character name from: " .. targetChar)
        return false
    end

    for attempt = 1, maxRetries do
        CureEcho((attempt == 1 and "Relogging to " or "Retry " .. (attempt-1) .. " - Relogging to ") .. targetChar)
        yield("/ays relog " .. targetChar)
        CureSleep(3)
        
        if CureVerifyCharacterSwitch(expectedName) then
            CureEcho("Character state reset complete")
            return true
        end
        
        if attempt < maxRetries then
            CureEcho("Retrying relog in 5 seconds...")
            CureSleep(5)
        end
    end
    
    CureEcho("FATAL: Character switch failed after " .. maxRetries .. " attempts!")
    return false
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureVerifyCharacterSwitch(expectedName)
--│ Verifies that character switch completed successfully
--│
--│ Parameters:
--│   expectedName (string) - Expected character name (without world)
--│
--│ Returns:
--│   boolean - true if current character matches expected name
--│
--│ Usage:
--│   if CureVerifyCharacterSwitch("John Doe") then
--│       -- Switch verified
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureVerifyCharacterSwitch(expectedName)
    if not expectedName or expectedName == "" then
        CureEcho("ERROR: No expected name provided for verification")
        return false
    end
    
    local actualName = (Player and Player.Entity and Player.Entity.Name) or "Unknown"
    local expectedLower = tostring(expectedName):lower()
    local actualLower = tostring(actualName):lower()
    
    if actualLower == expectedLower then
        CureEcho("Character switch verified: Now playing as " .. actualName)
        return true
    end
    
    CureEcho("ERROR: Character switch failed! Expected: " .. expectedName .. ", Actual: " .. actualName)
    return false
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureAttemptCharacterLogin(targetIdx, charConfigs, maxRelogattempts)
--│ Attempts to log into character from config list by index
--│
--│ Parameters:
--│   targetIdx (number) - Index in charConfigs array
--│   charConfigs (table) - Character configuration array
--│   maxRelogattempts (number) - Maximum retry attempts
--│
--│ Returns:
--│   boolean - true if login successful
--│
--│ Usage:
--│   if CureAttemptCharacterLogin(3, myCharList, 5) then
--│       -- Successfully logged into character at index 3
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureAttemptCharacterLogin(targetIdx, charConfigs, maxRelogattempts)
    local targetChar = charConfigs[targetIdx][1][1]
    CureEcho("Attempting to log into: " .. targetChar)
    
    if CurePerformCharacterRelog(targetChar, maxRelogattempts) then
        return true
    else
        CureEcho("FAILED: Character " .. targetChar .. " marked as failed after " .. maxRelogattempts .. " attempts")
        return false
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetCharIndex(name, charConfigs)
--│ Finds character index in config array by name (supports multiple config formats)
--│
--│ Parameters:
--│   name (string) - Character name to find (with or without @World)
--│   charConfigs (table) - Character configuration array
--│
--│ Returns:
--│   number|nil - Character index or nil if not found
--│
--│ Supported Formats:
--│   - {{"Name@World"}, "Helper"}  -- Nested with helper
--│   - {"Name@World", "Helper"}    -- Flat with helper
--│   - {"Name@World"}               -- Simple array
--│   - "Name@World"                 -- Direct string
--│
--│ Usage:
--│   local idx = CureGetCharIndex("John Doe", myCharList)
--│   local idx = CureGetCharIndex("John Doe@Omega", myCharList)
--│   if idx then
--│       CureEcho("Character is at index: " .. idx)
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetCharIndex(name, charConfigs)
    if not name or name == "" or not charConfigs then
        return nil
    end
    
    -- Extract just the character name (before @)
    local searchName = tostring(name):match("^([^@]+)") or tostring(name)
    searchName = searchName:lower():match("^%s*(.-)%s*$") -- trim whitespace
    
    for i, c in ipairs(charConfigs) do
        local charName = CureExtractCharacterName(c)
        if charName and tostring(charName):lower() == searchName then
            return i
        end
    end
    return nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureExtractCharacterName(configEntry)
--│ Extracts character name from various config formats
--│
--│ Parameters:
--│   configEntry (any) - Character config entry (supports multiple formats)
--│
--│ Returns:
--│   string|nil - Character name (without @World) or nil if invalid
--│
--│ Supported Formats:
--│   - {{"Name@World"}, "Helper"}  -- Returns "Name"
--│   - {"Name@World", "Helper"}    -- Returns "Name"
--│   - {"Name@World"}               -- Returns "Name"
--│   - "Name@World"                 -- Returns "Name"
--│
--│ Usage:
--│   local name = CureExtractCharacterName(charConfigs[1])
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureExtractCharacterName(configEntry)
    if not configEntry then return nil end
    
    local fullName = nil
    
    -- Handle different config formats
    if type(configEntry) == "string" then
        -- Direct string: "Name@World"
        fullName = configEntry
    elseif type(configEntry) == "table" then
        if configEntry[1] then
            if type(configEntry[1]) == "table" and configEntry[1][1] then
                -- Nested format: {{"Name@World"}, "Helper"}
                fullName = configEntry[1][1]
            elseif type(configEntry[1]) == "string" then
                -- Flat format: {"Name@World", "Helper"} or {"Name@World"}
                fullName = configEntry[1]
            end
        end
    end
    
    if not fullName then return nil end
    
    -- Extract name before @ symbol
    local name = tostring(fullName):match("^([^@]+)") or tostring(fullName)
    return name:match("^%s*(.-)%s*$") -- trim whitespace
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureExtractCharacterFullName(configEntry)
--│ Extracts full character name with world from config entry
--│
--│ Parameters:
--│   configEntry (any) - Character config entry
--│
--│ Returns:
--│   string|nil - Full name "Name@World" or nil if invalid
--│
--│ Usage:
--│   local fullName = CureExtractCharacterFullName(charConfigs[1])
--│   -- Returns: "John Doe@Omega"
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureExtractCharacterFullName(configEntry)
    if not configEntry then return nil end
    
    local fullName = nil
    
    if type(configEntry) == "string" then
        fullName = configEntry
    elseif type(configEntry) == "table" then
        if configEntry[1] then
            if type(configEntry[1]) == "table" and configEntry[1][1] then
                fullName = configEntry[1][1]
            elseif type(configEntry[1]) == "string" then
                fullName = configEntry[1]
            end
        end
    end
    
    return fullName and tostring(fullName):match("^%s*(.-)%s*$") or nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureExtractCharacterHelper(configEntry)
--│ Extracts helper name from config entry (if present)
--│
--│ Parameters:
--│   configEntry (any) - Character config entry
--│
--│ Returns:
--│   string|nil - Helper name or nil if no helper configured
--│
--│ Supported Formats:
--│   - {{"Name@World"}, "Helper"}  -- Returns "Helper"
--│   - {"Name@World", "Helper"}    -- Returns "Helper"
--│   - {"Name@World"}               -- Returns nil
--│   - "Name@World"                 -- Returns nil
--│
--│ Usage:
--│   local helper = CureExtractCharacterHelper(charConfigs[1])
--│   if helper then
--│       CureEcho("Required helper: " .. helper)
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureExtractCharacterHelper(configEntry)
    if not configEntry or type(configEntry) ~= "table" then
        return nil
    end
    
    -- Check for helper in second position
    if configEntry[2] and type(configEntry[2]) == "string" then
        local helper = tostring(configEntry[2]):match("^%s*(.-)%s*$")
        -- Return nil if empty string after trimming
        if helper == "" then
            return nil
        end
        return helper
    end
    
    return nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetNextAvailableCharacter(currentIdx, charConfigs, failedCharacters, completedCharacters)
--│ Finds next available character in rotation, skipping failed/completed ones
--│
--│ Parameters:
--│   currentIdx (number) - Current character index
--│   charConfigs (table) - Character configuration array
--│   failedCharacters (table) - Dictionary of failed character names
--│   completedCharacters (table) - Dictionary of completed character names
--│
--│ Returns:
--│   number, string - Next character index and name, or nil if none available
--│
--│ Usage:
--│   local nextIdx, nextName = CureGetNextAvailableCharacter(idx, chars, failed, done)
--│   if nextIdx then
--│       -- Switch to nextName
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetNextAvailableCharacter(currentIdx, charConfigs, failedCharacters, completedCharacters)
    local attempts = 0
    local nextIdx = currentIdx or 0
    
    CureEcho("Looking for next character. Current idx: " .. (currentIdx or "nil"))
    
    while attempts < #charConfigs do
        nextIdx = nextIdx + 1
        if nextIdx > #charConfigs then
            nextIdx = 1
        end
        
        local charName = charConfigs[nextIdx][1][1]
        local isFailed = failedCharacters[charName] or false
        local isCompleted = completedCharacters[charName] or false
        
        CureEcho("Checking character " .. nextIdx .. ": " .. charName .. 
               " (Failed: " .. tostring(isFailed) .. ", Completed: " .. tostring(isCompleted) .. ")")
        
        if not isFailed and not isCompleted then
            CureEcho("[CharRotation] Found available character: " .. charName)
            return nextIdx, charName
        end
        
        attempts = attempts + 1
    end
    
    CureEcho("[CharRotation] No available characters found")
    return nil, nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureReportRotationStatus(charConfigs, failedCharacters, completedCharacters)
--│ Reports current status of character rotation
--│
--│ Parameters:
--│   charConfigs (table) - Character configuration array
--│   failedCharacters (table) - Dictionary of failed characters
--│   completedCharacters (table) - Dictionary of completed characters
--│
--│ Usage:
--│   CureReportRotationStatus(myChars, failedList, completedList)
--│   -- Outputs: "Rotation Status: 5/10 characters remaining (3 completed, 2 failed)"
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureReportRotationStatus(charConfigs, failedCharacters, completedCharacters)
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
    
    CureEcho(string.format("Rotation Status: %d/%d characters remaining (%d completed, %d failed)", 
        remainingCount, totalChars, completedCount, failedCount))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureResetRotation(charConfigs)
--│ Resets character rotation to first character, clearing all status flags
--│
--│ Parameters:
--│   charConfigs (table) - Character configuration array
--│
--│ Returns:
--│   boolean - Success status
--│   table - Empty failedCharacters dictionary
--│   table - Empty completedCharacters dictionary
--│   boolean - allCharactersCompleted flag (false)
--│   number - Starting index (1)
--│   string - Current character name
--│   string - Current helper name
--│
--│ Usage:
--│   local success, failed, done, allDone, idx, char, helper = CureResetRotation(myChars)
--│   if success then
--│       -- Rotation reset successfully
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureResetRotation(charConfigs)
    CureEcho("[DailyReset] === RESETTING CHARACTER ROTATION ===")
    
    local failedCharacters = {}
    local completedCharacters = {}
    local allCharactersCompleted = false
    local idx = 1
    
    if charConfigs[1] and charConfigs[1][1] and charConfigs[1][1][1] then
        local currentChar = tostring(charConfigs[1][1][1]):lower()
        local currentHelper = charConfigs[1][2] and tostring(charConfigs[1][2]) or ""
        
        CureEcho("[DailyReset] Rotation reset complete - starting from first character")
        CureEcho("[DailyReset] First character: " .. charConfigs[1][1][1])
        CureEcho("[DailyReset] Required helper: " .. currentHelper)
        
        if CureARRelog(charConfigs[1][1][1]) then
            CureEnableTextAdvance()
            CureSleep(2)
            return true, failedCharacters, completedCharacters, allCharactersCompleted, idx, currentChar, currentHelper
        else
            CureEcho("[DailyReset] ERROR: Failed to relog to first character")
            return false, failedCharacters, completedCharacters, allCharactersCompleted, idx, nil, nil
        end
    else
        CureEcho("[DailyReset] ERROR: First character configuration is invalid")
        return false, {}, {}, false, 1, nil, nil
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureValidateCharConfig(charConfigs)
--│ Validates character configuration array format and contents
--│
--│ Parameters:
--│   charConfigs (table) - Character configuration array to validate
--│
--│ Returns:
--│   boolean - true if valid, false if invalid
--│   string - Error message if invalid, nil if valid
--│
--│ Checks:
--│   - Config is a table
--│   - Config is not empty
--│   - Each entry has valid character name
--│   - Character names are unique
--│
--│ Usage:
--│   local valid, err = CureValidateCharConfig(myCharConfigs)
--│   if not valid then
--│       CureEcho("Config error: " .. err)
--│       return
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureValidateCharConfig(charConfigs)
    if not charConfigs then
        return false, "Character config is nil"
    end
    
    if type(charConfigs) ~= "table" then
        return false, "Character config must be a table"
    end
    
    if #charConfigs == 0 then
        return false, "Character config is empty"
    end
    
    local seenNames = {}
    
    for i, entry in ipairs(charConfigs) do
        local fullName = CureExtractCharacterFullName(entry)
        local charName = CureExtractCharacterName(entry)
        
        if not fullName or fullName == "" then
            return false, "Invalid character entry at index " .. i .. " - no character name found"
        end
        
        if not charName or charName == "" then
            return false, "Invalid character entry at index " .. i .. " - could not extract character name"
        end
        
        -- Check for duplicates (case-insensitive)
        local lowerName = fullName:lower()
        if seenNames[lowerName] then
            return false, "Duplicate character found: " .. fullName .. " (indices " .. seenNames[lowerName] .. " and " .. i .. ")"
        end
        seenNames[lowerName] = i
    end
    
    return true, nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureInitializeRotation(charConfigs, startCharName)
--│ Initializes character rotation state with validation
--│
--│ Parameters:
--│   charConfigs (table) - Character configuration array
--│   startCharName (string) - Starting character name (optional, defaults to first)
--│
--│ Returns:
--│   boolean - Success status
--│   number - Starting index
--│   string - Starting character full name
--│   string - Starting character helper (or nil)
--│   table - Empty failedCharacters dictionary
--│   table - Empty completedCharacters dictionary
--│   string - Error message if failed
--│
--│ Process:
--│   1. Validates character configuration
--│   2. Finds starting character index
--│   3. Initializes tracking dictionaries
--│   4. Returns initial state
--│
--│ Usage:
--│   local ok, idx, char, helper, failed, done, err = CureInitializeRotation(charConfigs)
--│   if not ok then
--│       CureEcho("Initialization failed: " .. err)
--│       return
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureInitializeRotation(charConfigs, startCharName)
    -- Validate configuration
    local valid, err = CureValidateCharConfig(charConfigs)
    if not valid then
        return false, nil, nil, nil, nil, nil, err
    end
    
    CureEcho("[RotationInit] === INITIALIZING CHARACTER ROTATION ===")
    CureEcho("[RotationInit] Total characters: " .. #charConfigs)
    
    -- Determine starting index
    local startIdx = 1
    if startCharName and startCharName ~= "" then
        startIdx = CureGetCharIndex(startCharName, charConfigs)
        if not startIdx then
            return false, nil, nil, nil, nil, nil, "Starting character not found in config: " .. startCharName
        end
    end
    
    -- Extract starting character info
    local startFullName = CureExtractCharacterFullName(charConfigs[startIdx])
    local startHelper = CureExtractCharacterHelper(charConfigs[startIdx])
    
    -- Initialize tracking dictionaries
    local failedCharacters = {}
    local completedCharacters = {}
    
    CureEcho("[RotationInit] Starting character: " .. startFullName .. " (index " .. startIdx .. ")")
    if startHelper then
        CureEcho("[RotationInit] Required helper: " .. startHelper)
    end
    CureEcho("[RotationInit] === INITIALIZATION COMPLETE ===")
    
    return true, startIdx, startFullName, startHelper, failedCharacters, completedCharacters, nil
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureSwitchToNextCharacter(currentIdx, charConfigs, failedCharacters, completedCharacters, maxRelogattempts, postSwitchCallback)
--│ Complete character switching workflow with rotation management
--│
--│ Parameters:
--│   currentIdx (number) - Current character index
--│   charConfigs (table) - Character configuration array
--│   failedCharacters (table) - Dictionary of failed characters (modified in place)
--│   completedCharacters (table) - Dictionary of completed characters (modified in place)
--│   maxRelogattempts (number) - Maximum relog attempts (default: 3)
--│   postSwitchCallback (function) - Optional callback after successful switch
--│
--│ Returns:
--│   boolean - true if switch successful
--│   number - New character index (or nil if failed)
--│   string - New character full name (or nil if failed)
--│   string - New character helper (or nil if no helper)
--│
--│ Process:
--│   1. Reports current rotation status
--│   2. Checks if all characters processed
--│   3. Finds next available character
--│   4. Performs character relog with retry
--│   5. Executes post-switch callback if provided
--│   6. Returns updated state
--│
--│ Usage:
--│   local success, newIdx, newChar, newHelper = CureSwitchToNextCharacter(
--│       idx, charConfigs, failedChars, completedChars, 3,
--│       function(charName, helper)
--│           CureEnableTextAdvance()
--│           CureEcho("Switched to: " .. charName)
--│       end
--│   )
--│   if success then
--│       idx = newIdx
--│       currentChar = newChar
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureSwitchToNextCharacter(currentIdx, charConfigs, failedCharacters, completedCharacters, maxRelogattempts, postSwitchCallback)
    maxRelogattempts = maxRelogattempts or 3
    
    -- Report current status
    CureReportRotationStatus(charConfigs, failedCharacters, completedCharacters)
    
    -- Check if all characters processed
    local doneCount = 0
    for _ in pairs(failedCharacters) do doneCount = doneCount + 1 end
    for _ in pairs(completedCharacters) do doneCount = doneCount + 1 end
    
    if doneCount >= #charConfigs then
        CureEcho("[CharSwitch] All characters have been processed (completed or failed)")
        return false, nil, nil, nil
    end
    
    -- Find next available character
    local nextIdx, nextCharFullName, nextHelper = CureGetNextAvailableCharacter(currentIdx, charConfigs, failedCharacters, completedCharacters)
    
    if not nextIdx then
        CureEcho("[CharSwitch] No more available characters")
        return false, nil, nil, nil
    end
    
    CureEcho("[CharSwitch] Switching to next character: " .. nextCharFullName)
    if nextHelper then
        CureEcho("[CharSwitch] Required helper: " .. nextHelper)
    end
    
    -- Attempt character login
    if CurePerformCharacterRelog(nextCharFullName, maxRelogattempts) then
        CureEcho("[CharSwitch] Successfully switched to: " .. nextCharFullName)
        
        -- Execute post-switch callback if provided
        if postSwitchCallback and type(postSwitchCallback) == "function" then
            local ok, err = pcall(postSwitchCallback, nextCharFullName, nextHelper)
            if not ok then
                CureEcho("[CharSwitch] WARNING: Post-switch callback error: " .. tostring(err))
            end
        end
        
        return true, nextIdx, nextCharFullName, nextHelper
    else
        -- Login failed, mark as failed and try next
        CureEcho("[CharSwitch] FAILED: Character " .. nextCharFullName .. " marked as failed after " .. maxRelogattempts .. " attempts")
        failedCharacters[nextCharFullName] = true
        
        -- Recursively try next character
        return CureSwitchToNextCharacter(nextIdx, charConfigs, failedCharacters, completedCharacters, maxRelogattempts, postSwitchCallback)
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureWaitForCompleteParty(requiredMember, requiredPartySize, maxRetries, retryInterval, enableVerification)
--│ Waits for party to reach required size and composition with automatic retry
--│
--│ Parameters:
--│   requiredMember (string) - Required party member name (optional, can be nil)
--│   requiredPartySize (number) - Required party size 2-8 (default: 4)
--│   maxRetries (number) - Maximum retry attempts (default: 60)
--│   retryInterval (number) - Seconds between retries (default: 60)
--│   enableVerification (boolean) - Enable/disable verification (default: true)
--│
--│ Returns:
--│   boolean - true if party complete, false if max retries reached
--│
--│ Process:
--│   1. Checks if party verification is enabled
--│   2. Sends BTB invite if party incomplete
--│   3. Waits specified interval between retries
--│   4. Lists party members on success/failure
--│
--│ Supports:
--│   - Party sizes from 2 (main + 1 helper) to 8 (main + 7 helpers)
--│   - Optional specific member requirement
--│   - Configurable retry logic
--│
--│ Usage:
--│   -- Wait for 4-person party with specific helper
--│   if CureWaitForCompleteParty("Tank Helper", 4, 30, 60, true) then
--│       -- Party ready
--│   end
--│   
--│   -- Wait for 8-person party without specific member requirement
--│   if CureWaitForCompleteParty(nil, 8, 20, 30, true) then
--│       -- Full 8-person party ready
--│   end
--│
--│   -- Wait for 2-person party (main + 1 helper)
--│   if CureWaitForCompleteParty("Solo Helper", 2, 10, 30, true) then
--│       -- Duo ready
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureWaitForCompleteParty(requiredMember, requiredPartySize, maxRetries, retryInterval, enableVerification)
    -- Set defaults
    requiredPartySize = requiredPartySize or 4
    maxRetries = maxRetries or 60
    retryInterval = retryInterval or 20
    if enableVerification == nil then enableVerification = true end
    
    -- Validate party size
    if requiredPartySize < 2 or requiredPartySize > 8 then
        CureEcho("[Party] ERROR: Invalid party size " .. requiredPartySize .. " (must be 2-8)")
        return false
    end
    
    if not enableVerification then
        CureEcho("[Party] Party verification disabled - skipping party check")
        return true
    end
    
    CureEcho("[Party] === WAITING FOR COMPLETE PARTY ===")
    if requiredMember and requiredMember ~= "" then
        CureEcho("[Party] Required member: " .. requiredMember)
    end
    CureEcho("[Party] Required party size: " .. requiredPartySize)
    
    local retryCount = 0
    
    while retryCount < maxRetries do
        -- Check if party is complete
        if CureIsPartyComplete(requiredMember, requiredPartySize) then
            CureEcho("[Party] ✓ Party is complete!")
            CureListPartyMembers()
            return true
        end
        
        -- Party not complete - disband wrong party and send invite again
        retryCount = retryCount + 1
        CureEcho("[Party] Party incomplete - Retry " .. retryCount .. "/" .. maxRetries)
        
        -- Disband if there's a wrong party
        if Svc.Party.Length > 1 then
            CureEcho("[Party] Disbanding incorrect party...")
            CureBTBDisband()
            CureSleep(2)
        end
        
        CureEcho("[Party] Sending party invite again...")
        CureEnableBTBandInvite()
        CureSleep(3)
        
        -- Check again immediately after invite
        if CureIsPartyComplete(requiredMember, requiredPartySize) then
            CureEcho("[Party] ✓ Party is complete!")
            CureListPartyMembers()
            return true
        end
        
        -- If not complete, wait before next retry
        if retryCount < maxRetries then
            local remainingRetries = maxRetries - retryCount
            CureEcho("[Party] Waiting " .. retryInterval .. " seconds before next retry (" .. remainingRetries .. " retries remaining)...")
            CureSleep(retryInterval)
        end
    end
    
    CureEcho("[Party] ✗ FAILED: Party did not complete after " .. maxRetries .. " retries (" .. (maxRetries * retryInterval / 60) .. " minutes)")
    CureListPartyMembers()
    return false
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureLogout()
--│ Logs out to main menu with confirmation
--│
--│ Usage:
--│   CureLogout()  -- Returns to character selection screen
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureLogout()
    yield("/logout")
    CureSleep(1)
    CureSelectYesno()
    CureSleep(1)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureWaitForARToFinish()
--│ Blocks until AutoRetainer completes all operations
--│
--│ Usage:
--│   CureWaitForARToFinish()  -- Waits for AR to finish before continuing
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureWaitForARToFinish()
    repeat
        CureSleep(1)
    until not IPC.AutoRetainer.IsBusy()
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 3. PARTY & SOCIAL FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureBTBDisband()
--│ Disbands party using BTB plugin or manual party commands
--│
--│ Usage:
--│   CureBTBDisband()  -- Disbands current party completely
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureBTBDisband()
    yield("/btb disband")
    CureSleep(2)
    yield("/pcmd breakup")
    CureSleep(1)
    CureSelectYesno()
    CureSleep(1)
    yield("/leave")
    CureSleep(1)
    CureSelectYesno()
    CureSleep(1)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureBTBInvite()
--│ Disbands current party and sends BTB invites
--│
--│ Usage:
--│   CureBTBInvite()  -- Refreshes party with BTB invitations
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureBTBInvite()
    yield("/btb disband")
    CureSleep(2)
    yield("/btb invite")
    CureSleep(1)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEnableBTBandInvite()
--│ Enables BTB Dalamud profile, sends invites, then disables profile
--│
--│ Usage:
--│   CureEnableBTBandInvite()  -- Automated BTB invite workflow
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEnableBTBandInvite()
    yield("/xlenableprofile BTB")
    CureEcho("BTB collection enabled. Waiting 8 seconds.")
    CureSleep(8)
    CureBTBInvite()
    CureEcho("BTB Invite has been sent. Waiting 3 seconds.")
    CureSleep(3)
    yield("/xldisableprofile BTB")
    CureEcho("BTB collection disabled. Waiting 3 seconds.")
    CureSleep(3)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetPartyMemberNames()
--│ Retrieves list of all current party member names
--│
--│ Returns:
--│   table - Array of party member names (empty if solo)
--│
--│ Usage:
--│   local members = CureGetPartyMemberNames()
--│   for i, name in ipairs(members) do
--│       CureEcho("Member " .. i .. ": " .. name)
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetPartyMemberNames()
    local members = {}
    
    if not Svc or not Svc.Party then
        CureEcho("[Party] ERROR: Not in a Party.")
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

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureListPartyMembers()
--│ Lists all current party members with formatted output
--│
--│ Usage:
--│   CureListPartyMembers()
--│   -- Output: "[Party] Party has 3 member(s):"
--│   --         "[Party]   1. John Doe"
--│   --         "[Party]   2. Jane Smith"
--│   --         "[Party]   3. Bob Jones"
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureListPartyMembers()
    local members = CureGetPartyMemberNames()
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

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsCharacterInParty(helperName)
--│ Checks if specified character is currently in party
--│
--│ Parameters:
--│   helperName (string) - Character name to search for
--│
--│ Returns:
--│   boolean - true if character found in party
--│
--│ Usage:
--│   if CureIsCharacterInParty("Tank Helper") then
--│       -- Helper is present
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsCharacterInParty(helperName)
    if not helperName or helperName == "" then
        CureEcho("[Party] No Character specified - skipping verification")
        return true
    end
    
    local members = CureGetPartyMemberNames()
    local characterLower = tostring(helperName):lower()
    
    for _, memberName in ipairs(members) do
        if memberName and tostring(memberName):lower() == characterLower then
            return true
        end
    end
    
    return false
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsPartyComplete(requiredMember, requiredPartySize)
--│ Verifies party composition meets requirements
--│
--│ Parameters:
--│   requiredMember (string) - Name of required party member (optional)
--│   requiredPartySize (number) - Required total party size
--│
--│ Returns:
--│   boolean - true if party meets all requirements
--│
--│ Usage:
--│   if CureIsPartyComplete("Tank Main", 4) then
--│       -- Party is ready with correct size and member
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsPartyComplete(requiredMember, requiredPartySize)
    local partySize = Svc.Party.Length
    
    if partySize ~= requiredPartySize then
        CureEcho("[Party] Party size incorrect: " .. partySize .. "/" .. requiredPartySize)
        return false
    end
    
    if requiredMember and requiredMember ~= "" then
        if not CureIsCharacterInParty(requiredMember) then
            CureEcho("[Party] Required Member " .. requiredMember .. " not found")
            return false
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 4. PLAYER STATE & CONDITION
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsPlayerAvailable()
--│ Comprehensive check if player is available for actions
--│
--│ Returns:
--│   boolean - true if player can perform actions
--│
--│ Checks:
--│   - Player exists and is available
--│   - Not currently casting
--│   - Not in cutscene or occupied
--│   - Not between areas
--│
--│ Usage:
--│   if CureIsPlayerAvailable() then
--│       -- Safe to issue commands
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsPlayerAvailable()
    if not Player or not Player.Available then return false end
    if Entity and Entity.Player and Entity.Player.IsCasting then return false end
    if Svc and Svc.Condition and not Svc.Condition[1] and not Svc.Condition[4] then return false end
    if Svc and Svc.Condition and Svc.Condition[45] then return false end
    return true
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsPlayerDead()
--│ Checks if player character is currently dead
--│
--│ Returns:
--│   boolean - true if player is dead
--│
--│ Usage:
--│   if CureIsPlayerDead() then
--│       CureHandleDeath()
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsPlayerDead()
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

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureHandleDeath()
--│ Handles player death with revival acceptance and stabilization
--│
--│ Returns:
--│   boolean - false if revival timeout, nothing on success
--│
--│ Process:
--│   1. Accepts revival prompt
--│   2. Waits up to 30 seconds for revival
--│   3. Stabilization delay after revival
--│
--│ Usage:
--│   if CureIsPlayerDead() then
--│       CureHandleDeath()
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureHandleDeath()
    CureEcho("[Death] Player death detected")
    CureSleep(1)
    CureSelectYesno()
    local attempts = 0
    local maxAttempts = 30  -- 30 seconds timeout
    
    while CureIsPlayerDead() and attempts < maxAttempts do
        CureSleep(1)
        attempts = attempts + 1
    end
    
    if attempts >= maxAttempts then
        CureEcho("[Death] Revival timeout - player may still be dead")
        return false
    end
    
    CureEcho("[Death] Player revived successfully")
    
    -- Wait for character to stabilize
    CureSleep(1.5)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetCharacterCondition(number)
--│ Gets specific character condition by index
--│
--│ Parameters:
--│   (number) - Condition index to check
--│
--│ Returns:
--│   boolean - Condition state
--│
--│ Common Conditions:
--│   1 - Normal
--│   2 - Dead
--│   4 - Mounted
--│   26/27/45 - Various zoning states
--│
--│ Usage:
--│   if CureGetCharacterCondition(4) then
--│       -- Player is mounted
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetCharacterCondition(number)
    return Svc.Condition[number]
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEntityPlayerPositionX()
--│ Gets player's current X coordinate
--│
--│ Returns:
--│   number - X position or 0 if unavailable
--│
--│ Usage:
--│   local x = CureEntityPlayerPositionX()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEntityPlayerPositionX()
    if IsPlayerAvailable() then return Entity.Player.Position.X end
    return 0
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEntityPlayerPositionY()
--│ Gets player's current Y coordinate (height)
--│
--│ Returns:
--│   number - Y position or 0 if unavailable
--│
--│ Usage:
--│   local y = CureEntityPlayerPositionY()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEntityPlayerPositionY()
    if IsPlayerAvailable() then return Entity.Player.Position.Y end
    return 0
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEntityPlayerPositionZ()
--│ Gets player's current Z coordinate
--│
--│ Returns:
--│   number - Z position or 0 if unavailable
--│
--│ Usage:
--│   local z = CureEntityPlayerPositionZ()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEntityPlayerPositionZ()
    if IsPlayerAvailable() then return Entity.Player.Position.Z end
    return 0
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetPlayerName()
--│ Gets current player character name
--│
--│ Returns:
--│   string - Player name or nil if unavailable
--│
--│ Usage:
--│   local name = CureGetPlayerName()
--│   CureEcho("Playing as: " .. name)
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetPlayerName()
    if Entity and Entity.Player and Entity.Player.Name then
        local player_name = Entity.Player.Name
        CureEcho(player_name)
        return player_name
    else
        CureEcho("Error: Player data not available")
        return nil
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetPlayerNameAndWorld()
--│ Gets player name with home world in Name@World format
--│
--│ Returns:
--│   string - "Name@World" or nil if unavailable
--│
--│ Usage:
--│   local fullName = CureGetPlayerNameAndWorld()
--│   -- Returns: "John Doe@Omega"
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetPlayerNameAndWorld()
    if Entity and Entity.Player and Entity.Player.Name and Entity.Player.HomeWorld then
        local player_name = Entity.Player.Name
        local world_id = Entity.Player.HomeWorld
        local world_name = homeworld_lookup[world_id] or "Unknown World"
        local full_name = player_name .. "@" .. world_name
        CureEcho(full_name)
        return full_name
    else
        CureEcho("Error: Player data not available")
        return nil
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetClassJobId()
--│ Gets current class/job ID
--│
--│ Returns:
--│   number - Class/Job ID (e.g., 19 = Paladin, 25 = Red Mage)
--│
--│ Usage:
--│   local jobID = CureGetClassJobId()
--│   if jobId == 25 then
--│       -- Player is Red Mage
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetClassJobId()
    return Svc.ClientState.LocalPlayer.ClassJob.RowId
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetCurrentLevel()
--│ Gets current Level
--│
--│ Returns:
--│   number - Level
--│
--│ Usage:
--│   local Player.Job.Level = CureGetCurrentLevel()
--│   if Player.JobLevel == 25 then
--│       -- Player is Level 25
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetCurrentLevel()
    if Player and Player.Job then
        return Player.Job.Level
    end
    return nil
end

--┌─────────────────────────────────────────────────────────────────────────────────
--│ CureBecomeRed()
--│ Checks for Red Mage unlock quest and starts it if eligible (Level 50+)
--│
--│ Returns:
--│   boolean - true if already RDM or quest completed successfully
--│
--│ Process:
--│   1. Checks if player is already Red Mage (Job ID 35)
--│   2. If not RDM, checks if level is 50 or higher
--│   3. If eligible, starts RDM unlock quest (Quest 2576: "Taking the Red")
--│   4. Tracks quest progress until Sequence 255 (completion)
--│   5. Waits with status updates every 5 seconds
--│
--│ Requirements:
--│   - Level 50+ on any combat job
--│   - Not already a Red Mage
--│   - IPC.Questionable must be available
--│
--│ Usage:
--│   if CureBecomeRed() then
--│       -- RDM unlock quest completed or already RDM
--│   end
--└─────────────────────────────────────────────────────────────────────────────────
function CureBecomeRed()
    local currentJobId = CureGetClassJobId()
    
    -- Check if already Red Mage
    if currentJobId == 35 then
        CureEcho("[BecomeRed] Already a Red Mage!")
        return true
    end
    
    -- Check current level
    local currentLevel = CureGetCurrentLevel()
    
    if not currentLevel then
        CureEcho("[BecomeRed] ERROR: Could not retrieve current level")
        return false
    end
    
    -- Check if level requirement met
    if currentLevel < 50 then
        CureEcho("[BecomeRed] Level requirement not met (Current: " .. currentLevel .. ", Required: 50)")
        return false
    end
    
    CureEcho("[BecomeRed] Level requirement met (" .. currentLevel .. ") - starting Red Mage unlock quest")
    
    -- Check if Questionable is available
    if not IPC or not IPC.Questionable then
        CureEcho("[BecomeRed] ERROR: Questionable plugin not available")
        return false
    end
    
    -- Start the Red Mage unlock quest
    CureEcho("[BecomeRed] Starting Quest 2576: Taking the Red")
    yield("/qst next 2576")
    CureSleep(2)
    
    -- Track quest progress until completion
    CureEcho("[BecomeRed] Tracking quest progress until completion (Sequence 255)...")
    
    local questComplete = false
    local checkCounter = 0
    local statusUpdateInterval = 5 -- Update status every 5 seconds
    local maxWaitTime = 3600 -- Maximum 1 hour wait (safety timeout)
    local waitCounter = 0
    
    while not questComplete and waitCounter < maxWaitTime do
        -- Get current quest data
        local currentQuestId = IPC.Questionable.GetCurrentQuestId and IPC.Questionable.GetCurrentQuestId() or nil
        local stepData = IPC.Questionable.GetCurrentStepData and IPC.Questionable.GetCurrentStepData() or nil
        
        if currentQuestId and tonumber(currentQuestId) == 2576 then
            -- Still on quest 2576
            if stepData and stepData.Sequence then
                local currentSequence = tonumber(stepData.Sequence)
                
                -- Check if quest is completed (Sequence 255)
                if currentSequence == 255 then
                    CureEcho("[BecomeRed] Quest 2576 completed (Sequence 255 reached)!")
                    questComplete = true
                    break
                end
                
                -- Status update every 5 seconds
                if checkCounter % statusUpdateInterval == 0 then
                    CureEcho("[BecomeRed] Quest 2576 in progress - Current Sequence: " .. currentSequence)
                end
            else
                -- Status update when no step data
                if checkCounter % statusUpdateInterval == 0 then
                    CureEcho("[BecomeRed] Quest 2576 in progress - waiting for step data...")
                end
            end
        else
            -- Not on quest 2576 anymore - assume completed or abandoned
            if checkCounter % statusUpdateInterval == 0 then
                CureEcho("[BecomeRed] Quest 2576 no longer active - checking completion status...")
            end
            
            -- Check if we became Red Mage
            currentJobId = CureGetClassJobId()
            if currentJobId == 25 then
                CureEcho("[BecomeRed] Quest completed successfully - now a Red Mage!")
                questComplete = true
                break
            end
        end
        
        CureSleep(1)
        checkCounter = checkCounter + 1
        waitCounter = waitCounter + 1
    end
    
    -- Timeout check
    if waitCounter >= maxWaitTime then
        CureEcho("[BecomeRed] WARNING: Quest tracking timeout after " .. (maxWaitTime / 60) .. " minutes")
        return false
    end
    
    -- Final verification
    currentJobId = CureGetClassJobId()
    if currentJobId == 25 then
        CureEcho("[BecomeRed] === RED MAGE UNLOCK COMPLETE ===")
        return true
    else
        CureEcho("[BecomeRed] WARNING: Quest tracked to completion but not Red Mage yet")
        return true -- Quest completed even if not switched to RDM yet
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 5. WORLD & NAVIGATION
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureLifestreamCmd(name)
--│ Teleports to specified location using Lifestream plugin
--│
--│ Parameters:
--│   name (string) - Destination world/location name
--│
--│ Returns:
--│   boolean - true if teleport initiated successfully
--│
--│ Process:
--│   1. Multiple SafeWait checks before teleport
--│   2. Initiates Lifestream teleport
--│   3. Waits for completion
--│   4. Multiple SafeWait checks after arrival
--│
--│ Usage:
--│   CureLifestreamCmd("Omega")      -- Teleport to Omega world
--│   CureLifestreamCmd("Limsa Lominsa")  -- Teleport to city
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureLifestreamCmd(name)
    local dest = (type(name) == "string") and name:match("^%s*(.-)%s*$") or ""
    if dest == "" then
        CureEcho("No Location Set.")
        return false
    end

    CureEcho("Sending CharacterSafeWait 1/5")
    CureSafeWait()
    CureSleep(1)
    CureEcho("Teleporting to " .. dest)
    yield("/li " .. dest)
    CureSleep(1)
    CureWaitForLifestream()
    CureEcho("Sending CharacterSafeWait 2/5")
    CureSafeWait()
    CureSleep(1)
    CureEcho("Sending CharacterSafeWait 3/5")
    CureSafeWait()
    CureSleep(1)
    CureEcho("Sending CharacterSafeWait 4/5")
    CureSafeWait()
    CureSleep(1)
    CureEcho("Sending CharacterSafeWait 5/5")
    CureSafeWait()
    CureSleep(1)
    return true
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureWaitForLifestream()
--│ Blocks until Lifestream completes teleportation
--│
--│ Usage:
--│   yield("/li Omega")
--│   CureWaitForLifestream()  -- Waits for teleport completion
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureWaitForLifestream()
    local konds = 0
    CureEcho("Waiting on lifestream")
    while IPC.Lifestream.IsBusy() do
        konds = konds + 1
        CureSleep(1)
    end
    CureEcho("Lifestream completed")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureReturnToHome()
--│ Returns to Free Company house using Lifestream
--│
--│ Usage:
--│   CureReturnToHome()  -- Teleports to FC house on Homeworld
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureReturnToHome()
    yield("/li home")
    CureSleep(1)
    CureWaitForLifestream()
    CureSleep(2)
    CureSafeWait()
    CureSleep(1)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureReturnToHomeworld()
--│ Returns to character's home world using Lifestream
--│
--│ Usage:
--│   CureReturnToHomeworld()  -- Returns to home world
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureReturnToHomeworld()
    yield("/li")
    CureSleep(1)
    CureWaitForLifestream()
    CureSleep(2)
    CureSafeWait()
    CureSleep(1)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureVnav(text)
--│ Controls VNavmesh navigation commands
--│
--│ Parameters:
--│   text (string) - VNav command (e.g., "stop", "moveto", "flyto")
--│
--│ Usage:
--│   CureVnav("stop")            -- Stops navigation
--│   CureVnav("moveto 100 0 100") -- Navigate to coordinates
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureVnav(text)
    yield("/vnav " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureNavIsReady()
--│ Checks if VNavmesh is ready for pathfinding
--│
--│ Returns:
--│   boolean - true if navmesh ready
--│
--│ Usage:
--│   if CureNavIsReady() then
--│       -- Start navigation
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureNavIsReady()
    return IPC.vnavmesh.IsReady()
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureNavRebuild()
--│ Rebuilds the navmesh for current zone
--│
--│ Usage:
--│   CureNavRebuild()  -- Rebuilds navigation mesh
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureNavRebuild()
    IPC.vnavmesh.Rebuild()
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CurePathfindInProgress()
--│ Checks if pathfinding calculation is in progress
--│
--│ Returns:
--│   boolean - true if calculating path
--│
--│ Usage:
--│   while CurePathfindInProgress() do
--│       CureSleep(0.1)
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CurePathfindInProgress()
    return IPC.vnavmesh.PathfindInProgress()
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CurePathIsRunning()
--│ Checks if character is currently following a path
--│
--│ Returns:
--│   boolean - true if actively navigating
--│
--│ Usage:
--│   if CurePathIsRunning() then
--│       -- Navigation active
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CurePathIsRunning()
    return IPC.vnavmesh.IsRunning()
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CurePeriodicMovementCheck(lastMovementCheck, movementCheckInterval, inDuty)
--│ Periodically stops VNav movement to prevent stuck states
--│
--│ Parameters:
--│   lastMovementCheck (number) - Timestamp of last check
--│   movementCheckInterval (number) - Seconds between checks
--│   inDuty (boolean) - Only performs check if true
--│
--│ Returns:
--│   number - Updated timestamp for next check
--│
--│ Usage:
--│   lastCheck = CurePeriodicMovementCheck(lastCheck, 30, true)
--│   -- Stops movement every 30 seconds while in duty
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CurePeriodicMovementCheck(lastMovementCheck, movementCheckInterval, inDuty)
    if not inDuty then
        return lastMovementCheck
    end
    
    local currentTime = os.time()
    if currentTime - lastMovementCheck >= movementCheckInterval then
        CureEcho("[Movement] Executing periodic movement check...")
        CureVnav("stop")  -- Assuming CureFullStopMovement() calls vnav stop
        return currentTime
    end
    
    return lastMovementCheck
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureWalk()
--│ Walks forward for 2 seconds
--│
--│ Usage:
--│   CureWalk()  -- Simple forward movement
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureWalk()
    yield("/hold W")
    CureSleep(2)
    yield("/release W")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 6. UI & ADDON MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsAddonReady(name)
--│ Checks if addon is loaded and ready
--│
--│ Parameters:
--│   name (string) - Addon name (e.g., "NamePlate", "SelectYesno")
--│
--│ Returns:
--│   boolean - true if addon ready
--│
--│ Usage:
--│   if CureIsAddonReady("SelectYesno") then
--│       -- Can interact with Yes/No dialog
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsAddonReady(name)
    return Addons.GetAddon(name).Ready
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureIsAddonVisible(name)
--│ Checks if addon is currently visible on screen
--│
--│ Parameters:
--│   name (string) - Addon name
--│
--│ Returns:
--│   boolean - true if addon visible
--│
--│ Usage:
--│   if CureIsAddonVisible("Talk") then
--│       -- Dialog window is open
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureIsAddonVisible(name)
    return Addons.GetAddon(name).Exists
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCallback(text)
--│ Executes addon callback commands
--│
--│ Parameters:
--│   text (string) - Callback command string
--│
--│ Usage:
--│   CureCallback("SelectYesno true 0")  -- Click Yes
--│   CureCallback("GrandCompanyExchange true 2 3")  -- GC exchange menu
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCallback(text)
    yield("/callback " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureSelectYesno()
--│ Automatically clicks "Yes" on confirmation dialogs
--│
--│ Usage:
--│   CureLogout()
--│   CureSelectYesno()  -- Confirms logout
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureSelectYesno()
    CureSleep(1.5)
    if CureIsAddonReady("SelectYesno") then
        CureCallback("SelectYesno true 0")
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CurePlayerAndUIReady()
--│ Comprehensive check for player and UI ready state
--│
--│ Returns:
--│   boolean - true if fully loaded and ready
--│
--│ Checks:
--│   - NamePlate addon ready and visible
--│   - Player available
--│   - Not zoning (conditions 26, 27, 45)
--│
--│ Usage:
--│   while not CurePlayerAndUIReady() do
--│       CureSleep(0.5)
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CurePlayerAndUIReady()
    local not_zoning = not (Svc and Svc.Condition and Svc.Condition[45] and Svc.Condition[27] and Svc.Condition[26])
    return CureIsAddonReady("NamePlate")
        and CureIsAddonVisible("NamePlate")
        and CureIsPlayerAvailable()
        and not_zoning
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureSafeWait()
--│ Advanced wait function that blocks until player and UI are fully ready
--│
--│ Returns:
--│   boolean - true when ready
--│
--│ Process:
--│   - Quick check first (returns immediately if ready)
--│   - Polling loop with status logging
--│   - Checks NamePlate addon and player availability
--│
--│ Usage:
--│   CureSafeWait()  -- Essential after teleports, zone changes, logins
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureSafeWait()
    CureSleep(0.01)
    do
        local np = Addons and Addons.GetAddon and Addons.GetAddon("NamePlate")
        local ready, vis = np and np.Ready or false, np and np.Exists or false
        local avail = CureIsPlayerAvailable()
        if ready and vis and avail then
            return true
        end
    end

    while true do
        local zoning = Svc and Svc.Condition and Svc.Condition[45]
        local np = Addons and Addons.GetAddon and Addons.GetAddon("NamePlate")
        local ready, vis = np and np.Ready or false, np and np.Exists or false
        local avail = CureIsPlayerAvailable()

        CureEcho(string.format("[NP %s/%s] [PLR %s] %s",
            tostring(ready), tostring(vis), tostring(avail), zoning and "(zoning)" or ""))

        if ready and vis and avail then
            CureEcho("All ready — stopping loop")
            return true
        end

        CureSleep(0.22)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 7. GAME DATA QUERIES
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetZoneID()
--│ Gets current zone/territory ID
--│
--│ Returns:
--│   number - Zone ID or nil if unavailable
--│
--│ Usage:
--│   local zoneId = CureGetZoneID()
--│   if zoneId == 128 then
--│       -- In Limsa Lominsa Lower Decks
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetZoneID()
    if Svc and Svc.ClientState and Svc.ClientState.TerritoryType then
        local zone_id = Svc.ClientState.TerritoryType
        CureEcho("Zone ID: " .. zone_id)
        return zone_id
    else
        CureEcho("Error: Zone data not available")
        return nil
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetZoneName()
--│ Gets current zone name from territory type
--│
--│ Returns:
--│   string - Zone name
--│   number - Zone ID
--│
--│ Usage:
--│   local name, id = CureGetZoneName()
--│   CureEcho("Currently in: " .. name)
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetZoneName()
    local id = (Svc and Svc.ClientState and Svc.ClientState.TerritoryType) or nil
    local name

    if Excel and id then
        local row = Excel.GetRow("TerritoryType", id)
        if row then
            local place = (row.GetProperty and row:GetProperty("PlaceName")) or nil
            name = place and (place.Name or place.Singular)
            if name and type(name) ~= "string" and name.ToString then
                name = name:ToString()
            end
        end
    end

    if not name or name == "" then name = tostring(id or "?") end
    CureEcho("Zone: " .. tostring(name) .. " [" .. tostring(id or "?") .. "]")
    return name, id
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetWorldName()
--│ Gets current world name
--│
--│ Returns:
--│   string - World name
--│   number - World ID
--│
--│ Usage:
--│   local world, worldId = CureGetWorldName()
--│   CureEcho("On world: " .. world)
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetWorldName()
    local id = (Player and Player.Entity and Player.Entity.CurrentWorld) or nil
    local name = (homeworld_lookup and id and homeworld_lookup[id])
    if not name or name == "" then name = tostring(id or "?") end
    CureEcho("World: " .. name .. " [" .. tostring(id or "?") .. "]")
    return name, id
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetPlayerGC()
--│ Gets player's Grand Company affiliation
--│
--│ Returns:
--│   number - GC ID (1=Maelstrom, 2=Adders, 3=Flames)
--│
--│ Usage:
--│   local gc = CureGetPlayerGC()
--│   if gc == 1 then
--│       -- Maelstrom member
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetPlayerGC()
    return Player.GrandCompany
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetAddersGCRank()
--│ Gets Twin Adder Grand Company rank
--│
--│ Returns:
--│   number - Rank level (0-20)
--│
--│ Usage:
--│   local rank = CureGetAddersGCRank()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetAddersGCRank()
    return Player.GCRankTwinAdders
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetFlamesGCRank()
--│ Gets Immortal Flames Grand Company rank
--│
--│ Returns:
--│   number - Rank level (0-20)
--│
--│ Usage:
--│   local rank = CureGetFlamesGCRank()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetFlamesGCRank()
    return Player.GCRankImmortalFlames
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetMaelstromGCRank()
--│ Gets Maelstrom Grand Company rank
--│
--│ Returns:
--│   number - Rank level (0-20)
--│
--│ Usage:
--│   local rank = CureGetMaelstromGCRank()
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetMaelstromGCRank()
    return Player.GCRankMaelstrom
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetGCRank()
--│ Gets highest Grand Company rank across all three GCs
--│
--│ Returns:
--│   number - Highest rank achieved
--│
--│ Usage:
--│   local highestRank = CureGetGCRank()
--│   -- Returns highest rank regardless of current GC
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetGCRank()
    local ggcr = 0
    if CureGetAddersGCRank() > ggcr then ggcr = CureGetAddersGCRank() end
    if CureGetFlamesGCRank() > ggcr then ggcr = CureGetFlamesGCRank() end
    if CureGetMaelstromGCRank() > ggcr then ggcr = CureGetMaelstromGCRank() end
    return ggcr
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureFreeCompanyCmd()
--│ Opens Free Company menu
--│
--│ Usage:
--│   CureFreeCompanyCmd()  -- Opens FC interface
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureFreeCompanyCmd()
    yield("/freecompanycmd")
    CureSleep(1)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 8. TIMING & SCHEDULING
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckDailyReset()
--│ Checks if daily reset time has been reached
--│
--│ Returns:
--│   boolean - true if past configured reset hour
--│
--│ Notes:
--│   - Requires dailyResetHour and dailyResetTriggered variables configured in script
--│   - Checks against UTC+1 timezone
--│
--│ Usage:
--│   if CureCheckDailyReset() then
--│       -- Time to reset daily activities
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckDailyReset()
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

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckMidnight(dailyResetHour, dailyResetTriggered)
--│ Checks if midnight has passed to clear daily reset flag
--│
--│ Parameters:
--│   dailyResetHour (number) - Configured reset hour
--│   dailyResetTriggered (boolean) - Current reset flag state
--│
--│ Returns:
--│   boolean - true if midnight passed and flag should be cleared
--│
--│ Usage:
--│   if CureCheckMidnight(15, dailyResetTriggered) then
--│       dailyResetTriggered = false  -- Reset the flag
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckMidnight(dailyResetHour, dailyResetTriggered)
    local currentTime = os.date("*t")
    local currentHour = currentTime.hour
    
    if currentHour < dailyResetHour and dailyResetTriggered then
        CureEcho("[DailyReset] === MIDNIGHT PASSED - RESET FLAG CLEARED ===")
        CureEcho("[DailyReset] Daily reset will be available again at " .. dailyResetHour .. ":00")
        return true
    end
    
    return false
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckDutyRouletteRewardLeveling()
--│ Checks if Leveling Duty Roulette has been completed today
--│
--│ Returns:
--│   boolean - Operation success status
--│   string - "completed", "available", or "error"
--│
--│ Process:
--│   1. Opens Duty Finder
--│   2. Navigates to roulette detail view
--│   3. Reads reward text from addon
--│   4. Empty text = available, any text = completed
--│
--│ Usage:
--│   local success, status = CureCheckDutyRouletteRewardLeveling()
--│   if success and status == "available" then
--│       -- Queue for leveling roulette
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckDutyRouletteRewardLeveling()
    CureEcho("=== CHECKING DUTY ROULETTE REWARD STATUS ===")
    
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
        CureEcho("ERROR: Failed to read reward status - " .. tostring(err))
        yield("/callback ContentsFinder true -1")
        CureSleep(1)
        return false, "error"
    end
    
    CureEcho("Reward Text: [" .. tostring(rewardReceived) .. "]")
    
    yield("/callback ContentsFinder true -1")
    CureSleep(1)
    
    if rewardReceived and rewardReceived ~= "" then
        CureEcho("=== ROULETTE ALREADY COMPLETED (TEXT FOUND) ===")
        return true, "completed"
    else
        CureEcho("=== ROULETTE AVAILABLE (NO TEXT) ===")
        return true, "available"
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureQueueDutyRoulette()
--│ Queues for configured Duty Roulette
--│
--│ Returns:
--│   boolean - true if queue successful
--│
--│ Notes:
--│   - Requires dutyRouletteID and wasInDuty variables configured
--│   - Skips queue if already in duty
--│
--│ Usage:
--│   if CureQueueDutyRoulette() then
--│       -- Successfully queued
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureQueueDutyRoulette()
    CureEcho("Queueing Duty Roulette ID: " .. dutyRouletteID)
    
    if wasInDuty then
        CureEcho("Already in duty, skipping queue")
        return false
    end
    
    local success, err = pcall(function()
        Instances.DutyFinder:QueueRoulette(dutyRouletteID)
    end)
    
    if success then
        CureEcho("Successfully queued for Duty Roulette")
        return true
    else
        CureEcho("[RelogAuto] ERROR: Failed to queue - " .. tostring(err))
        return false
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckSubmarines()
--│ Checks AutoRetainer config for available submarines
--│
--│ Returns:
--│   boolean - true if submarines available
--│
--│ Process:
--│   1. Reads AutoRetainer config file
--│   2. Extracts submarine return timestamps
--│   3. Compares with current time
--│   4. Reports availability and next submarine time
--│
--│ Notes:
--│   - Requires enableSubmarineCheck variable set to true
--│   - Reads from AutoRetainer DefaultConfig.json
--│
--│ Usage:
--│   if CureCheckSubmarines() then
--│       -- Submarines ready to deploy
--│   end
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckSubmarines()
    if not enableSubmarineCheck then return false end
    
    local configPath = CureGetConfigPathAR()
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

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureGetConfigPathAR()
--│ Gets file path to AutoRetainer config
--│
--│ Returns:
--│   string - Full path to DefaultConfig.json
--│
--│ Usage:
--│   local path = CureGetConfigPathAR()
--│   -- Returns: "C:\Users\Username\AppData\Roaming\XIVLauncher\pluginConfigs\AutoRetainer\DefaultConfig.json"
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureGetConfigPathAR()
    local userprofile = os.getenv("USERPROFILE")
    if not userprofile or userprofile == "" then
        local username = os.getenv("USERNAME") or ""
        if username == "" then return nil end
        userprofile = "C:\\Users\\" .. username
    end
    return userprofile .. [[\AppData\Roaming\XIVLauncher\pluginConfigs\AutoRetainer\DefaultConfig.json]]
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 9. UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEcho(text)
--│ Outputs message to FFXIV chat log
--│
--│ Parameters:
--│   text (string/any) - Message to display (converted to string)
--│
--│ Usage:
--│   CureEcho("Script starting...")
--│   CureEcho("Current index: " .. idx)
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEcho(text)
    yield("/echo " .. tostring(text))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureSleep(time)
--│ Pauses script execution for specified duration
--│
--│ Parameters:
--│   time (number) - Seconds to wait (supports decimals)
--│
--│ Usage:
--│   CureSleep(1)      -- Wait 1 second
--│   CureSleep(0.5)    -- Wait 500ms
--│   CureSleep(2.5)    -- Wait 2.5 seconds
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureSleep(time)
    yield("/wait " .. tostring(time))
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureTarget(targetname)
--│ Targets entity by name
--│
--│ Parameters:
--│   targetname (string) - Name of entity to target
--│
--│ Usage:
--│   CureTarget("Baderon")        -- Target NPC
--│   CureTarget("Striking Dummy") -- Target training dummy
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureTarget(targetname)
    yield('/target "' .. tostring(targetname) .. '"')
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureFocusTarget()
--│ Sets current target as focus target
--│
--│ Usage:
--│   CureTarget("Boss Enemy")
--│   CureFocusTarget()  -- Boss is now focus target
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureFocusTarget()
    yield("/focustarget")
    CureSleep(0.07)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureClearTarget()
--│ Clears current target
--│
--│ Usage:
--│   CureClearTarget()  -- Deselects current target
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureClearTarget()
    if Entity.Player and Entity.Player.ClearTarget then
        Entity.Player:ClearTarget()
    else
        CureEcho("Failed to clear target: Entity.Player or ClearTarget missing")
    end
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureInteract()
--│ Interacts with current target
--│
--│ Usage:
--│   CureTarget("Aetheryte")
--│   CureInteract()  -- Opens aetheryte menu
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureInteract()
    CureSleep(0.5)
    yield("/interact")
    CureSleep(5)
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureEnableTextAdvance()
--│ Enables TextAdvance plugin (auto-advances dialog)
--│
--│ Usage:
--│   CureEnableTextAdvance()  -- Auto-click through NPC dialog
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureEnableTextAdvance()
    yield("/at y")
    CureEcho("Enabling Text Advance...")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureDisableTextAdvance()
--│ Disables TextAdvance plugin
--│
--│ Usage:
--│   CureDisableTextAdvance()  -- Stop auto-advancing dialog
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureDisableTextAdvance()
    yield("/at n")
    CureEcho("Disabling Text Advance...")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureRemoveSprout()
--│ Removes New Adventurer status icon
--│
--│ Usage:
--│   CureRemoveSprout()  -- Disables sprout icon
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureRemoveSprout()
    yield("/nastatus off")
    CureEcho("Removing New Adventurer Status...")
end

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureNoSprout()
--│ Convenience function: enables text advance and removes sprout
--│
--│ Usage:
--│   CureNoSprout()  -- Enables TA and removes sprout icon
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureNoSprout()
    CureSleep(1)
    CureEnableTextAdvance()
    CureSleep(1)
    CureRemoveSprout()
    CureSleep(1)
end


-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 10. QUEST FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureFillInputString(text)
--│ Fills text input field using InputString addon callback
--│
--│ Parameters:
--│   text (string) - Text to input (e.g., chocobo name)
--│
--│ Returns:
--│   boolean - true if successful, false if addon not found
--│
--│ Usage:
--│   CureFillInputString("MyChocobo")  -- Enters chocobo name
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureFillInputString(text)
    local addon = Addons.GetAddon("InputString")
    if not addon then
        return false
    end
    
    yield("/callback InputString true 0 " .. text)
    CureSleep(0.5)
    
    yield("/callback InputString true 1")
    CureSleep(0.5)
    
    return true
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureVerifyGrandCompanyItem(itemId, maxRetries)
--│ Verifies Grand Company exchange item was received
--│
--│ Parameters:
--│   itemId (number) - Item ID to verify (6017=Maelstrom, 6018=Adder, 6019=Flames)
--│   maxRetries (number) - Maximum verification attempts (default: 3)
--│
--│ Returns:
--│   boolean - true if item found in inventory
--│
--│ Usage:
--│   if CureVerifyGrandCompanyItem(6018, 3) then
--│       -- Chocobo issuance item acquired
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureVerifyGrandCompanyItem(itemId, maxRetries)
    maxRetries = maxRetries or 3
    
    for attempt = 1, maxRetries do
        local itemCount = GetItemCount(itemId)
        
        if itemCount and itemCount > 0 then
            CureEcho("[ChocoboHandler] Grand Company item verified (Item ID: " .. itemId .. ", Count: " .. itemCount .. ")")
            return true
        end
        
        CureEcho("[ChocoboHandler] Grand Company item not found (Attempt " .. attempt .. "/" .. maxRetries .. ")")
        
        if attempt < maxRetries then
            CureSleep(2)
        end
    end
    
    return false
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureHandleTwinAdderChocobo()
--│ Handles Twin Adder (Gridania) Chocobo quest sequence
--│
--│ Returns:
--│   boolean - true if sequence completed successfully
--│
--│ Process:
--│   1. Purchases Company Chocobo Issuance from Serpent Quartermaster
--│   2. Verifies item acquisition (Item ID 6018)
--│   3. Interacts with Chocobo Porter Cingur
--│   4. Names chocobo using configured name
--│   5. Retries up to 3 times on failure
--│
--│ Usage:
--│   if CureHandleTwinAdderChocobo() then
--│       -- Chocobo successfully acquired
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureHandleTwinAdderChocobo()
    CureEcho("[ChocoboHandler] === STARTING TWIN ADDER CHOCOBO SEQUENCE ===")
    
    local maxAttempts = 3
    local attempt = 0
    local success = false
    
    while attempt < maxAttempts and not success do
        attempt = attempt + 1
        CureEcho("[ChocoboHandler] Twin Adder attempt " .. attempt .. "/" .. maxAttempts)
        
        -- First movement and GC exchange
        MoveToXA(-67.112823486328, -0.50180679559708, -8.4076232910156)
        CureTarget("Serpent Quartermaster")
        CureInteract()
        yield("/callback GrandCompanyExchange true 1 0")
        yield("/wait 0.2")
        yield("/callback GrandCompanyExchange true 2 1")
        yield("/wait 1")
        yield("/callback GrandCompanyExchange true 0 6 1")
        CureSelectYesno()
        
        CureSleep(2)
        
        -- Second movement and verification
        MoveToXA(32.108360290527, -0.38360524177551, 68.25846862793)
        
        -- Verify item using GetItemCount
        if CureVerifyGrandCompanyItem(6018) then
            success = true
            CureEcho("[ChocoboHandler] Grand Company exchange successful - proceeding to Chocobo Porter")
            
            CureTarget("Cingur")
            CureInteract()
            CureSleep(7)
            CureTarget("Chocobo")
            CureEcho("pat pat pat you're such a good chocobo")
            CureInteract()
            CureSleep(2)
            
            CureFillInputString(chocoboName)
            CureSleep(2)
            CureSelectYesno()
            
            CureEcho("[ChocoboHandler] === TWIN ADDER CHOCOBO SEQUENCE COMPLETE ===")
        else
            CureEcho("[ChocoboHandler] Grand Company exchange failed - restarting sequence")
            CureSleep(2)
        end
    end
    
    if not success then
        CureEcho("[ChocoboHandler] ERROR: Twin Adder Chocobo sequence failed after " .. maxAttempts .. " attempts")
    end
    
    return success
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureHandleLimsaChocobo()
--│ Handles Maelstrom (Limsa Lominsa) Chocobo quest sequence
--│
--│ Returns:
--│   boolean - true if sequence completed successfully
--│
--│ Process:
--│   1. Travels to Maelstrom Command via Lifestream
--│   2. Purchases Company Chocobo Issuance from Storm Quartermaster
--│   3. Verifies item acquisition (Item ID 6017)
--│   4. Returns to Limsa Lower Decks
--│   5. Interacts with Chocobo Porter Fraegeim
--│   6. Names chocobo using configured name
--│   7. Retries up to 3 times on failure
--│
--│ Usage:
--│   if CureHandleLimsaChocobo() then
--│       -- Chocobo successfully acquired
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureHandleLimsaChocobo()
    CureEcho("[ChocoboHandler] === STARTING LIMSA LOMINSA CHOCOBO SEQUENCE ===")
    
    local maxAttempts = 3
    local attempt = 0
    local success = false
    
    while attempt < maxAttempts and not success do
        attempt = attempt + 1
        CureEcho("[ChocoboHandler] Limsa Lominsa attempt " .. attempt .. "/" .. maxAttempts)
        
        -- First movement and GC exchange
        CureLifestreamCmd("Aftcastle")
        MoveToXA(92.911315917969, 40.249973297119, 76.863349914551)
        CureTarget("Storm Quartermaster")
        CureInteract()
        yield("/callback GrandCompanyExchange true 1 0")
        yield("/wait 0.2")
        yield("/callback GrandCompanyExchange true 2 1")
        yield("/wait 1")
        yield("/callback GrandCompanyExchange true 0 6 1")
        CureSelectYesno()
        
        CureSleep(2)
        
        -- Second movement and verification
        MoveToXA(68.418785095215, 40.0, 72.608085632324)
        CureLifestreamCmd("Limsa")
        MoveToXA(45.647987365723, 20.0, -6.4951529502869)
        
        -- Verify item using GetItemCount
        if CureVerifyGrandCompanyItem(6017) then
            success = true
            CureEcho("[ChocoboHandler] Grand Company exchange successful - proceeding to Chocobo Porter")
            
            CureTarget("Fraegeim")
            CureInteract()
            CureSleep(7)
            CureTarget("Chocobo")
            CureEcho("pat pat pat you're such a good chocobo")
            CureInteract()
            CureSleep(2)
            
            CureFillInputString(chocoboName)
            CureSelectYesno()
            
            CureEcho("[ChocoboHandler] === LIMSA LOMINSA CHOCOBO SEQUENCE COMPLETE ===")
        else
            CureEcho("[ChocoboHandler] Grand Company exchange failed - restarting sequence")
            CureSleep(2)
        end
    end
    
    if not success then
        CureEcho("[ChocoboHandler] ERROR: Limsa Lominsa Chocobo sequence failed after " .. maxAttempts .. " attempts")
    end
    
    return success
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureHandleImmortalFlamesChocobo()
--│ Handles Immortal Flames (Ul'dah) Chocobo quest sequence
--│
--│ Returns:
--│   boolean - true if sequence completed successfully
--│
--│ Process:
--│   1. Purchases Company Chocobo Issuance from Flame Quartermaster
--│   2. Verifies item acquisition (Item ID 6019)
--│   3. Interacts with Chocobo Porter Mimigun
--│   4. Names chocobo using configured name
--│   5. Retries up to 3 times on failure
--│
--│ Usage:
--│   if CureHandleImmortalFlamesChocobo() then
--│       -- Chocobo successfully acquired
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureHandleImmortalFlamesChocobo()
    CureEcho("[ChocoboHandler] === STARTING IMMORTAL FLAMES CHOCOBO SEQUENCE ===")
    
    local maxAttempts = 3
    local attempt = 0
    local success = false
    
    while attempt < maxAttempts and not success do
        attempt = attempt + 1
        CureEcho("[ChocoboHandler] Immortal Flames attempt " .. attempt .. "/" .. maxAttempts)
        
        -- First movement and GC exchange
        MoveToXA(-142.0650177002, 4.0999994277954, -107.41358947754)
        CureTarget("Flame Quartermaster")
        CureInteract()
        yield("/callback GrandCompanyExchange true 1 0")
        yield("/wait 0.2")
        yield("/callback GrandCompanyExchange true 2 1")
        yield("/wait 1")
        yield("/callback GrandCompanyExchange true 0 6 1")
        CureSelectYesno()
        
        CureSleep(2)
        
        -- Second movement and verification
        MoveToXA(54.293140411377, 4.0, -141.64344787598)
        
        -- Verify item using GetItemCount
        if CureVerifyGrandCompanyItem(6019) then
            success = true
            CureEcho("[ChocoboHandler] Grand Company exchange successful - proceeding to Chocobo Porter")
            
            CureTarget("Mimigun")
            CureInteract()
            CureSleep(7)
            CureTarget("Chocobo")
            CureEcho("pat pat pat you're such a good chocobo")
            CureInteract()
            CureSleep(2)
            
            CureFillInputString(chocoboName)
            CureSelectYesno()
            
            CureEcho("[ChocoboHandler] === IMMORTAL FLAMES CHOCOBO SEQUENCE COMPLETE ===")
        else
            CureEcho("[ChocoboHandler] Grand Company exchange failed - restarting sequence")
            CureSleep(2)
        end
    end
    
    if not success then
        CureEcho("[ChocoboHandler] ERROR: Immortal Flames Chocobo sequence failed after " .. maxAttempts .. " attempts")
    end
    
    return success
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckAndHandleChocoboQuest()
--│ Monitors for Chocobo quest triggers and executes appropriate GC handler
--│
--│ Returns:
--│   boolean - true if Chocobo quest was detected and handled
--│
--│ Detects:
--│   - Quest 700 Sequence 1: Twin Adder Chocobo (My Feisty Little Chocobo)
--│   - Quest 701 Sequence 1: Maelstrom Chocobo (My Feisty Little Chocobo)
--│   - Quest 702 Sequence 1: Immortal Flames Chocobo (My Feisty Little Chocobo)
--│
--│ Requirements:
--│   - chocoboHandlerEnabled must be true
--│   - chocoboQuestActive must be false (prevents re-entry)
--│   - IPC.Questionable must be available
--│   - chocoboName variable must be configured
--│
--│ Usage:
--│   -- In main loop:
--│   if CureCheckAndHandleChocoboQuest() then
--│       -- Quest was handled, continue to next iteration
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckAndHandleChocoboQuest()
    if not chocoboHandlerEnabled or chocoboQuestActive then
        return false
    end
    
    if not IPC or not IPC.Questionable then
        return false
    end
    
    local questId = IPC.Questionable.GetCurrentQuestId and IPC.Questionable.GetCurrentQuestId() or nil
    local step = IPC.Questionable.GetCurrentStepData and IPC.Questionable.GetCurrentStepData() or nil
    
    if not questId or not step or not step.Sequence then
        return false
    end
    
    questId = tonumber(questId)
    local sequence = tonumber(step.Sequence)
    
    -- Check for Chocobo quests at Sequence 1
    if sequence == 1 then
        if questId == 700 then
            CureEcho("[ChocoboHandler] Detected Quest 700 Sequence 1 - Twin Adder Chocobo")
            chocoboQuestActive = true
            
            local success = CureHandleTwinAdderChocobo()
            
            chocoboQuestActive = false
            return true
            
        elseif questId == 701 then
            CureEcho("[ChocoboHandler] Detected Quest 701 Sequence 1 - Limsa Lominsa Chocobo")
            chocoboQuestActive = true
            
            local success = CureHandleLimsaChocobo()
            
            chocoboQuestActive = false
            return true
            
        elseif questId == 702 then
            CureEcho("[ChocoboHandler] Detected Quest 702 Sequence 1 - Immortal Flames Chocobo")
            chocoboQuestActive = true
           
            local success = CureHandleImmortalFlamesChocobo()
            
            chocoboQuestActive = false
            
            return true
        end
    end
    
    return false
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureCheckStepsOfFaithEntry()
--│ Monitors for Steps of Faith solo duty entry conditions
--│
--│ Returns:
--│   boolean - true if entry conditions met
--│
--│ Detects:
--│   - Quest 4591 (Steps of Faith)
--│   - Player in duty (Condition 59)
--│   - Solo duty condition (Condition 63)
--│
--│ Requirements:
--│   - stepsOfFaithHandlerEnabled must be true
--│   - stepsOfFaithActive must be false (prevents re-entry)
--│
--│ Usage:
--│   if CureCheckStepsOfFaithEntry() then
--│       CureHandleStepsOfFaithSoloDuty()
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureCheckStepsOfFaithEntry()
    if not stepsOfFaithHandlerEnabled then return false end
    if stepsOfFaithActive then return false end
    
    -- Check if we're on Quest 4591
    if not IPC or not IPC.Questionable then return false end
    
    local questId = IPC.Questionable.GetCurrentQuestId and IPC.Questionable.GetCurrentQuestId() or nil
    if not questId or tonumber(questId) ~= 4591 then return false end
    
    -- Check if in duty (solo duty)
    local inDuty = false
    if Player ~= nil and Player.IsInDuty ~= nil then
        if type(Player.IsInDuty) == "function" then
            inDuty = Player.IsInDuty()
        else
            inDuty = Player.IsInDuty
        end
    end
    
    if not inDuty and HasCondition and HasCondition(59) then
        inDuty = true
    end
    
    -- Check for solo duty condition (Condition 63)
    local inSoloDuty = false
    if Svc and Svc.Condition then
        if type(Svc.Condition[63]) == "boolean" then
            inSoloDuty = Svc.Condition[63]
        elseif HasCondition then
            inSoloDuty = HasCondition(63)
        end
    end
    
    -- If we're in duty and it's a solo duty, trigger the handler
    if inDuty and inSoloDuty then
        CureEcho("[StepsOfFaith] Solo Duty entry detected for Quest 4591")
        return true
    end
    
    return false
end

--┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ CureHandleStepsOfFaithSoloDuty()
--│ Handles Steps of Faith solo duty sequence
--│
--│ Process:
--│   1. Waits for Condition 29 (Occupied) to clear
--│   2. Waits for Condition 63 (Between Areas) to clear
--│   3. Additional 15 second stabilization delay
--│   4. Disables vnavmesh
--│   5. Moves to specific coordinates to complete duty
--│   6. Status updates every 5 seconds during wait
--│   7. 60 second timeout protection
--│
--│ Requirements:
--│   - Must be called when CureCheckStepsOfFaithEntry() returns true
--│   - Sets stepsOfFaithActive flag during execution
--│
--│ Usage:
--│   if CureCheckStepsOfFaithEntry() then
--│       CureHandleStepsOfFaithSoloDuty()
--│   end
--└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
function CureHandleStepsOfFaithSoloDuty()
    stepsOfFaithActive = true
    CureEcho("[StepsOfFaith] === STEPS OF FAITH SOLO DUTY HANDLER ACTIVATED ===")
    CureEcho("[StepsOfFaith] Waiting for Character Conditions 29 and 63 to clear...")
    
    -- Wait for Condition 29 (Occupied) and Condition 63 (Between Areas in a Duty) to clear
    local condition29Cleared = false
    local condition63Cleared = false
    local waitCounter = 0
    local maxWaitTime = 60  -- Maximum 60 seconds wait
    
    while (not condition29Cleared or not condition63Cleared) and waitCounter < maxWaitTime do
        -- Check Condition 29 (Occupied)
        if not condition29Cleared then
            local hasCondition29 = false
            if Svc and Svc.Condition then
                if type(Svc.Condition[29]) == "boolean" then
                    hasCondition29 = Svc.Condition[29]
                elseif HasCondition then
                    hasCondition29 = HasCondition(29)
                end
            end
            
            if not hasCondition29 then
                condition29Cleared = true
                CureEcho("[StepsOfFaith] Condition 29 (Occupied) cleared")
            end
        end
        
        -- Check Condition 63 (Between Areas in a Duty)
        if not condition63Cleared then
            local hasCondition63 = false
            if Svc and Svc.Condition then
                if type(Svc.Condition[63]) == "boolean" then
                    hasCondition63 = Svc.Condition[63]
                elseif HasCondition then
                    hasCondition63 = HasCondition(63)
                end
            end
            
            if not hasCondition63 then
                condition63Cleared = true
                CureEcho("[StepsOfFaith] Condition 63 (Between Areas) cleared")
            end
        end
        
        if not condition29Cleared or not condition63Cleared then
            CureSleep(0.5)
            waitCounter = waitCounter + 0.5
            
            -- Log status every 5 seconds
            if waitCounter % 5 == 0 then
                CureEcho("[StepsOfFaith] Still waiting... (29: " .. tostring(condition29Cleared) .. ", 63: " .. tostring(condition63Cleared) .. ")")
            end
        end
    end
    
    if waitCounter >= maxWaitTime then
        CureEcho("[StepsOfFaith] WARNING: Timeout waiting for conditions to clear")
    else
        CureEcho("[StepsOfFaith] All conditions cleared - executing movement sequence")
    end
    
    -- Execute the movement sequence
    CureSleep(15)
    CureEcho("[StepsOfFaith] Disabling vbmar...")
    CureVbmar("disable")
    CureSleep(1)
    
    yield("/vnav moveto 2.8788917064667 0.0 293.36273193359")
    
    CureEcho("[StepsOfFaith] === STEPS OF FAITH HANDLER COMPLETE ===")
end



-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- 11. DATA TABLES
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ homeworld_lookup
--│ Comprehensive world/server ID to name mapping table
--│
--│ Coverage:
--│   - All NA, EU, JP, and OCE data centers
--│   - Special worlds (crossworld, contents servers)
--│   - Historical/legacy worlds
--│
--│ Usage:
--│   local worldName = homeworld_lookup[66]  -- Returns "Odin"
--│   local worldName = homeworld_lookup[Entity.Player.HomeWorld]
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────
homeworld_lookup = {
    [0] = "crossworld",
    [1] = "reserved1",
    [2] = "c-contents",
    [3] = "c-whiteae",
    [4] = "c-baudinii",
    [5] = "c-contents2",
    [6] = "c-funereus",
    [16] = "",
    [21] = "Ravana",
    [22] = "Bismarck",
    [23] = "Asura",
    [24] = "Belias",
    [25] = "Chaos",
    [26] = "Hecatoncheir",
    [27] = "Moomba",
    [28] = "Pandaemonium",
    [29] = "Shinryu",
    [30] = "Unicorn",
    [31] = "Yojimbo",
    [32] = "Zeromus",
    [33] = "Twintania",
    [34] = "Brynhildr",
    [35] = "Famfrit",
    [36] = "Lich",
    [37] = "Mateus",
    [38] = "Shemhazai",
    [39] = "Omega",
    [40] = "Jenova",
    [41] = "Zalera",
    [42] = "Zodiark",
    [43] = "Alexander",
    [44] = "Anima",
    [45] = "Carbuncle",
    [46] = "Fenrir",
    [47] = "Hades",
    [48] = "Ixion",
    [49] = "Kujata",
    [50] = "Typhon",
    [51] = "Ultima",
    [52] = "Valefor",
    [53] = "Exodus",
    [54] = "Faerie",
    [55] = "Lamia",
    [56] = "Phoenix",
    [57] = "Siren",
    [58] = "Garuda",
    [59] = "Ifrit",
    [60] = "Ramuh",
    [61] = "Titan",
    [62] = "Diabolos",
    [63] = "Gilgamesh",
    [64] = "Leviathan",
    [65] = "Midgardsormr",
    [66] = "Odin",
    [67] = "Shiva",
    [68] = "Atomos",
    [69] = "Bahamut",
    [70] = "Chocobo",
    [71] = "Moogle",
    [72] = "Tonberry",
    [73] = "Adamantoise",
    [74] = "Coeurl",
    [75] = "Malboro",
    [76] = "Tiamat",
    [77] = "Ultros",
    [78] = "Behemoth",
    [79] = "Cactuar",
    [80] = "Cerberus",
    [81] = "Goblin",
    [82] = "Mandragora",
    [83] = "Louisoix",
    [84] = "",
    [85] = "Spriggan",
    [86] = "Sephirot",
    [87] = "Sophia",
    [88] = "Zurvan",
    [90] = "Aegis",
    [91] = "Balmung",
    [92] = "Durandal",
    [93] = "Excalibur",
    [94] = "Gungnir",
    [95] = "Hyperion",
    [96] = "Masamune",
    [97] = "Ragnarok",
    [98] = "Ridill",
    [99] = "Sargatanas",
    [400] = "Sagittarius",
    [401] = "Phantom",
    [402] = "Alpha",
    [403] = "Raiden",
    [404] = "Marilith",
    [405] = "Seraph",
    [406] = "Halicarnassus",
    [407] = "Maduin",
    [408] = "Cuchulainn",
    [409] = "Kraken",
    [410] = "Rafflesia",
    [411] = "Golem",
    [412] = "Titania",
    [413] = "Innocence",
    [414] = "Pixie",
    [415] = "Tycoon",
    [416] = "Wyvern",
    [417] = "Lakshmi",
    [418] = "Eden",
    [419] = "Syldra"
}

--┌─────────────────────────────────────────────────────────────────────────────────────────────────────────
--│ QuestRunMap
--│ AD run Commands for Unsyncing Dungeons when they're reached in Questionable
--│
--│ Coverage:
--│   - ARR, HW Fully and SirenSongSea
--│
--│ Usage:
--|
--|        local key = tostring(questId) .. "-" .. tostring(step.Sequence)
--|        local runCommand = QuestRunMap[key]
--└─────────────────────────────────────────────────────────────────────────────────────────────────────────

QuestRunMap = {
    ["245-4"]  = "/ad run regular 1036 1",
    ["677-2"]  = "/ad run regular 1037 1",
    ["660-3"]  = "/ad run regular 1038 1",
    ["343-4"]  = "/ad run trial 1045 1",
    ["514-2"]  = "/ad run regular 1039 1",
    ["801-2"]  = "/ad run regular 1040 1",
    ["832-3"]  = "/ad run regular 1041 1",
    ["857-2"]  = "/ad run trial 1046 1",
    ["952-3"]  = "/ad run regular 1042 1",
    ["519-2"]  = "/ad run trial 1047 1",
    ["3873-2"] = "/ad run regular 1043 1",
    ["4522-2"] = "/ad run regular 1044 1",
    ["4522-4"] = "/ad run trial 1048 1",
    ["1190-7"] = "/ad run trial 1067 1",
    ["1361-1"] = "/ad run trial 281 1",
    ["3885-5"] = "/ad run trial 374 1",
    ["75-4"]   = "/ad run regular 1062 1",
    ["84-4"]   = "/ad run trial 377 1",
    ["366-3"]  = "/ad run regular 1063 1",
    ["369-3"]  = "/ad run trial 426 1",
    ["1616-3"] = "/ad run trial 432 1",
    ["1617-3"] = "/ad run regular 1064 1",
    ["1634-2"] = "/ad run regular 1065 1",
    ["1640-3"] = "/ad run regular 1066 1",
    ["1660-4"] = "/ad run regular 1109 1",
    ["1669-3"] = "/ad run regular 1110 1",
    ["1669-5"] = "/ad run trial 437 1",
    ["2232-3"] = "/ad run regular 1111 1",
    ["2244-5"] = "/ad run regular 1112 1",
    ["2245-2"] = "/ad run trial 599 1",
    ["2342-3"] = "/ad run regular 1113 1",
    ["2354-6"] = "/ad run regular 1114 1",
    ["2469-4"] = "/ad run regular 1142 1",
}



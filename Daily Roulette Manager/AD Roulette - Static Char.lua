----------------------------------------------------------------------------------------------------------------------------
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
-- ███████╗████████╗ █████╗ ████████╗██╗ ██████╗
-- ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔════╝
-- ███████╗   ██║   ███████║   ██║   ██║██║     
-- ╚════██║   ██║   ██╔══██║   ██║   ██║██║     
-- ███████║   ██║   ██║  ██║   ██║   ██║╚██████╗
-- ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝
--
-- Static helper character script for AD roulette automation.
-- Automatically handles AutoDuty start/stop and movement control when entering/leaving duties.
-- Designed to run continuously on helper characters without relog or submarine handling.
--
-- Dream AD Automation (Static Helper) v1.0.0
-- Last Updated: 2025-10-12
-- Simple duty automation for static helper characters
--
----------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------
---- PLUGIN REQUIREMENTS ----
----------------------------------------------------------------------------------------------------------------------------
-- REQUIRED PLUGINS:
-- • AutoDuty - For automatic dungeon clearing and combat handling
--   Handles all dungeon mechanics, pathing, and boss fights automatically
--
-- • BossMod (Veyn) - For combat mechanics handling and boss fight automation
--   Provides advanced boss mechanic awareness and positioning assistance
--
-- • vnav - For navigation and pathfinding capabilities
--   Required for movement control and stopping navigation on duty entry
--
----------------------------------------------------------------------------------------------------------------------------

-- Configuration
local dutyDelay = 3

-- State tracking
local wasInDuty = false
local adRunActive = false
local lastDeathCheck = 0
local deathCheckInterval = 1

-- Helper Functions (inline, no external dependencies)
local function Echo(msg)
    yield("/echo " .. msg)
end

local function Sleep(seconds)
    yield("/wait " .. seconds)
end

local function SelectYesno()
    yield("/callback SelectYesno true 0")
end

local function StartAutoduty()
    yield("/ad start")
end

local function StopAutoduty()
    yield("/ad stop")
end

local function EnableBossMod()
    yield("/vbmai on")
end

local function StopMovement()
    yield("/vnav stop")
    yield("/automove off")
end

-- Death Handler
local function IsPlayerDead()
    if not Svc or not Svc.Condition then return false end
    if type(Svc.Condition.IsDeath) == "function" then
        local success, result = pcall(Svc.Condition.IsDeath, Svc.Condition)
        if success then return result end
    end
    return Svc.Condition[2] == true
end

local function HandleDeath()
    Echo("[Static] === DEATH DETECTED ===")
    Sleep(1.5)
    SelectYesno()
    Sleep(0.5)
    
    local attempts = 0
    while IsPlayerDead() and attempts < 30 do
        Sleep(1)
        attempts = attempts + 1
        if attempts % 10 == 0 then
            Echo("[Static] Waiting for revival... (" .. attempts .. "s)")
        end
    end
    
    if attempts >= 30 then
        Echo("[Static] WARNING: Revival timeout")
        return false
    end
    
    Echo("[Static] Revived successfully")
    Sleep(2)
    
    if adRunActive then
        Echo("[Static] Restarting AutoDuty...")
        StartAutoduty()
        Sleep(1)
    end
    return true
end

-- Main Loop
Echo("════════════════════════════════════════")
Echo("STATIC HELPER v1.2.0 - STANDALONE")
Echo("NO EXTERNAL DEPENDENCIES")
Echo("════════════════════════════════════════")
yield("/xlenableprofile BTB")

while true do
    local currentTime = os.time()
    
    -- Death check
    if currentTime - lastDeathCheck >= deathCheckInterval then
        lastDeathCheck = currentTime
        if IsPlayerDead() then HandleDeath() end
    end
    
    -- Duty status
    local inDuty = false
    if Player ~= nil and Player.IsInDuty ~= nil then
        if type(Player.IsInDuty) == "function" then
            inDuty = Player.IsInDuty()
        else
            inDuty = Player.IsInDuty
        end
    end

    -- Duty state changes
    if inDuty and not wasInDuty then
        Echo("[Static] === ENTERED DUTY ===")
        wasInDuty = true
        Sleep(dutyDelay)
        
        if not adRunActive then
            StartAutoduty()
            adRunActive = true
            Echo("[Static] AutoDuty started")
            Sleep(1)
        end
        
        EnableBossMod()
        Sleep(3)
        StopMovement()
        Echo("[Static] Combat modules activated")
        
    elseif not inDuty and wasInDuty then
        Echo("[Static] === LEFT DUTY ===")
        wasInDuty = false
        adRunActive = false
        Sleep(1)
        StopAutoduty()
        Echo("[Static] AutoDuty stopped")
    end
    
    Sleep(1)
end

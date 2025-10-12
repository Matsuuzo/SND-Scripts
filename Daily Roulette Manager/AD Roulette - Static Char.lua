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
-- Matsuuzo AD Automation (Static Helper) v1.0.0
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

----------------------------------------------------------------------------------------------------------------------------
---- FUNCTION LIBRARY REQUIREMENTS ----
----------------------------------------------------------------------------------------------------------------------------
-- REQUIRED LIBRARIES:
-- • dfunc - Base function library (https://github.com/McVaxius/dhogsbreakfeast/blob/main/dfunc.lua)
--   Core utility functions and game state checking
--
-- • xafunc - Extended function library (https://github.com/xa-io/ffxiv-tools/blob/main/snd/xafunc.lua)
--   Movement control, sleep functions, and plugin command wrappers
--
-- Add both libraries to SND using GitHub auto-update or manual installation
----------------------------------------------------------------------------------------------------------------------------

require("dfunc")
require("xafunc")

-- ===============================================
-- Configuration
-- ===============================================

local dutyDelay = 3                    -- Seconds to wait after entering duty before starting AutoDuty

-- ==========================================
-- DO NOT TOUCH ANYTHING BELOW
-- ==========================================

-- Internal state tracking
local wasInDuty = false
local adRunActive = false

-- ===============================================
-- Main Loop
-- ===============================================

EchoXA("[STATIC] === MATSUUZO AD AUTOMATION (STATIC HELPER) STARTED ===")
EchoXA("[STATIC] Waiting for duty invites...")

while true do
    -- Check duty status
    local inDuty = false
    if Player ~= nil and Player.IsInDuty ~= nil then
        if type(Player.IsInDuty) == "function" then
            inDuty = Player.IsInDuty()
        else
            inDuty = Player.IsInDuty
        end
    end

    -- Handle duty state changes
    if inDuty and not wasInDuty then
        EchoXA("[STATIC] === ENTERED DUTY ===")
        SleepXA(dutyDelay)
        
        -- Start AutoDuty if not already active
        if not adRunActive then
            adXA("start")
            adRunActive = true
            EchoXA("[STATIC] AutoDuty started")
        end
        
        -- Enable combat modules and stop movement
        vbmaiXA("on")
        SleepXA(3)
        FullStopMovementXA()
        EchoXA("[STATIC] Movement stopped and combat modules activated")
        
    elseif not inDuty and wasInDuty then
        EchoXA("[STATIC] === LEFT DUTY ===")
        adRunActive = false
        SleepXA(1)
        adXA("stop")
        EchoXA("[STATIC] AutoDuty stopped - waiting for next duty invite")
    end
    
    wasInDuty = inDuty
    SleepXA(1)
end

EchoXA("[STATIC] === MATSUUZO AD AUTOMATION (STATIC HELPER) ENDED ===")

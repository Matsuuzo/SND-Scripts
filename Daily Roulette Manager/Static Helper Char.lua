-- Helper Character Duty Script
-- Automatically handles /ad run and /vnav stop when entering duty

require("dfunc")
require("xafunc")

local wasInDuty = false
local adRunActive = false
local dutyDelay = 3 -- seconds to wait after entering duty

-- Main loop
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
        -- Just entered duty
        SleepXA(dutyDelay)
        
        -- Start AutoDuty if not already active
        if not adRunActive then
            adXA("start")
            adRunActive = true
            EchoXA("[HELPER] AutoDuty started after entering duty")
        end
        
        -- Stop vnav after a short delay
        vbmaiXA("on")
        SleepXA(3)
        FullStopMovementXA()
        EchoXA("[HELPER] vNav stopped after entering duty")
        
    elseif not inDuty and wasInDuty then
        -- Just left duty
        adRunActive = false
        SleepXA(1)
        adXA("stop")
        EchoXA("[HELPER] Left duty - AutoDuty reset")
    end
    
    wasInDuty = inDuty
    SleepXA(1) -- Small delay to prevent high CPU usage
end

# FFXIV Leveling Roulette Automation

## Overview

Two complementary scripts for automating daily duty roulette runs across multiple characters and helpers in Final Fantasy XIV. These scripts work together to manage character rotations, party coordination, and submarine management efficiently.

**ONLY USE THIS SCRIPT IF YOU CAN HANDLE RUNNING 4 INSTANCES OF FFXIV AT THE SAME TIME.**

**THIS SCRIPT ONLY WORKS IN A PARTY OF FOUR. IF YOU GO OUT OF YOUR WAY TO EDIT IT IN ANY SHAPE OR FORM THAT CAUSES YOU TO GET BANNED IT'S YOUR FAULT**
---

## Main Character Script (AD Relog Automation)

### Primary Purpose
Automates duty roulette runs for main characters by handling character rotation, DC travel, party formation, and duty queuing.

### Core Features

**Character Rotation**
- Automatically cycles through configured main characters
- Skips characters that have already received their daily roulette reward
- Tracks completed, failed, and remaining characters

**DC Travel & Party Management**
- Travels to specified data center world for party formation
- Enables BardToolbox (BTB) and sends party invites
- Verifies party composition (correct helper + required party size)
- Retries party formation if incomplete

**Duty Automation**
- Queues for duty roulette once party is complete
- Starts AutoDuty upon entering instance
- Verifies reward receipt after duty completion
- Retries failed duties automatically

**Submarine Integration**
- Detects when submarines are ready during rotation
- Pauses character rotation to run AutoRetainer Multi Mode
- Resumes rotation after submarines complete

**Daily Reset System**
- Automatically resets rotation at 17:00 UTC+1
- Clears all completion tracking
- Returns to first character to restart cycle

---

## Helper Character Script

### Primary Purpose
Automates helper characters that support main character runs by managing helper rotation, party acceptance, and duty assistance.

### Core Features

**Helper Rotation**
- Cycles through all configured helper characters
- Each helper is assigned to a specific main character
- Skips helpers that have already completed their daily duty

**Smart Party Detection**
- Accepts any party invite automatically
- Determines which main character sent the invite
- Switches to correct helper if needed
- Handles out-of-order invites intelligently

**Timeout Management**
- Tracks consecutive invitation timeouts
- After 2 consecutive timeouts → activates Multi Mode (assumes main stopped)
- After reaching last helper → activates Multi Mode until daily reset

**DC Travel & Coordination**
- Travels to specified data center for party join
- Enables BTB profile for party acceptance
- Returns to homeworld after duty completion

**Duty Assistance**
- Follows main character through duties
- Runs AutoDuty and BossMod for combat support
- Verifies duty completion and reward receipt

**Submarine Integration**
- Same submarine detection as main script
- Pauses helper rotation when submarines are ready
- Resumes after submarine voyages complete

**Daily Reset System**
- Resets at 17:00 UTC+1 daily
- Clears completion tracking and returns to first helper
- Works independently from main character script

---

## Key Features (Both Scripts)

### Reward Detection
- Checks duty roulette reward status before starting
- Skips characters/helpers that already received daily reward
- Prevents wasted time on completed runs

### Failure Handling
- Hard Failures: Login issues → character/helper marked as failed
- Soft Failures: Timeouts → character/helper marked as skipped (can retry)
- Duty Failures: Incomplete duties detected and automatically retried

### Multi Mode Integration
- Seamlessly switches to AutoRetainer Multi Mode when needed:
  - All characters/helpers completed
  - 2 consecutive timeouts (helper script only)
  - Last character reached
  - Submarines ready
- Automatically disables Multi Mode on daily reset and starts over

### State Tracking
- Tracks completed, failed, and skipped characters/helpers
- Provides regular status updates
- Maintains rotation position across script restarts

---

## Character State Tracking System
**Persistent State File**
- Tracks 4 data points per character:
  1. Character/Helper name and world
  2. Associated main character/helper
  3. Completion status (0 = pending, 1 = completed)
  4. Character level (for trial farming optimization)
---

## Ultimate Weapon Trial Farming Mode

### Overview
After all daily roulettes are complete but before the 17:00 reset, scripts can automatically switch to farming Ultimate Weapon trials for leveling. This mode intelligently selects the lowest-level character to maximize leveling efficiency. Resets Script on Daily Reset

### Activation
**Toggle Control**
```lua
local enableTrialDutyFarming = true  -- Set to false to disable
```
- Set to `true`: Activates trial farming after roulettes complete
- Set to `false`: Uses AR Multi mode instead (original behavior)

---

## Configuration Requirements

### Required Plugins
- **TextAdvance** - Automatic dialog interaction
- **AutoRetainer** - Character switching and relog functionality
- **AutoDuty** - Automatic Duty handling
- **Lifestream** - World travel and DC travel
- **BossMod (Veyn)** - Combat mechanics handling
- **vnav** - Navigation and pathfinding
- **BardToolbox (BTB)** - Party management and invites

### Required Script Files
Download from: https://github.com/MacaronDream/SND-Scripts/tree/main/SND
- **curefunc.lua** - Core utility functions
- **character_state.lua** - Character state persistence and tracking 

### Configuration Files
Both scripts require character/helper configuration at the top of the file:
- Main Script: List of main characters with assigned helpers
- Helper Script: List of helpers with assigned main characters
**If you don't want a Helper to be configured use "" instead of the Name**
---

## Workflow Example

1. **Main Script** logs into first main character
2. Checks if roulette reward already received → if yes, skip to next
3. Travels to DC world and forms party with assigned helper
4. **Helper Script** accepts invite and joins party
5. Main queues duty roulette, both enter instance
6. Both run AutoDuty to complete instance
7. After completion, both verify reward receipt
8. Main switches to next character, Helper switches to next helper
9. Process repeats until all characters complete or daily reset

---

## Future Enhancements

This is an ongoing project with planned additions:
- Multiple duty selection logic per Character
- Enhanced error recovery mechanisms
- Performance optimization for large character rosters
- Advanced party composition validation
- Integration with additional plugins
- Detailed logging and analytics

---

## Version Information

- **Inviting Character (WITH CHARACTER STATE)**: v2.0.0
- **Roulette Helper (WITH CHARACTER STATE)**: v2.0.0
- **character_state.lua**: v1.0.0
- **Last Updated**: 2025-10-21
- **New Features**: Character state tracking, level tracking, Ultimate Weapon trial farming

---

## Notes

- Scripts are designed to work independently but complement each other
- Main script handles queuing, Helper script handles following
- Both scripts share similar architecture for consistency
- Daily reset synchronized between both scripts (17:00 UTC+1)

# Hall of the Novice - Multi Character Script

## Overview
This script automates the Hall of the Novice DPS training for multiple characters. It uses the existing precise timing from the original script and adds character cycling functionality using the curefunc library.
Tanks and Healers are not calibrated for this. I have not tested it out on those Roles!!!

## Files
- **Hall of the Novice.lua** - Original single-character script
- **Hall of the Novice - Multi Character.lua** - Multi-character version with automatic character cycling
- **HotN 1, 2, 3 DPS** - Single "Floor" Script for the DPS Tactical Excercises incase something gets stuck in the Multi Script.

## Requirements
- **vnav** - For movement
- **Textadvance** - For auto-advancing dialog
- **Yesalready** - Set to accept Dutyfinder invites
- **AutoRetainer** - For character switching (multi-character version only)
- **curefunc.lua** - Function library (must be loaded in SND)

## Setup Instructions

### 1. Configure Your Characters
Edit the `charConfigs` section at the top of the script:

```lua
local charConfigs = {
    {{"Your Character1@World"}},
    {{"Your Character2@World"}},
    {{"Your Character3@World"}},
    -- Add more characters as needed
}
```

**Example:**
```lua
local charConfigs = {
    {{"John Doe@Omega"}},
    {{"Jane Smith@Phoenix"}},
    {{"Bob Jones@Cerberus"}},
}
```

### 2. Important Settings
- **Turn OFF "Dungeon Auto Leave" in CBT** - Otherwise you won't receive the ring at the end!
- **Enable Yesalready** - Configure it to auto-accept Dutyfinder invites
- **Enable Textadvance** - The script will enable it automatically with `/at y`

### 3. Starting Position
Make sure your character is in a position where they can access the Hall of the Novice training area. (Sanctuary!!!)

## How It Works

### Main Script (DO NOT MODIFY)
The core script contains precisely timed movements and interactions:
- Movement commands (`CureMovetoXA`)
- NPC interactions (`CureTarget`, `CureInteract`)
- Menu selections (`CureCallback`)
- Precise sleep timings (`CureSleep`)

**⚠️ WARNING:** Do not modify any timings or commands in the main script section! They are calibrated to the exact second.

### Character Cycling (Automatic)
After completing the Hall of the Novice for one character, the script will:
1. Mark the character as completed
2. Report rotation status
3. Switch to the next character using AutoRetainer
4. Enable text advance for the new character
5. Repeat the Hall of the Novice sequence

### Error Handling
- **Failed Character Switch:** If a character fails to log in after 3 attempts, it's marked as failed and the script moves to the next character
- **All Characters Complete:** When all characters have been processed (completed or failed), the script displays a final status report and stops

## Comparison: Single vs Multi Character

### Original Script (Hall of the Novice.lua)
- ✓ Single character only
- ✓ Precise timing (DO NOT MODIFY)
- ✓ No external dependencies beyond plugins
- ✓ Simple and straightforward

### Multi Character Version
- ✓ Supports multiple characters
- ✓ Automatic character cycling
- ✓ Progress tracking
- ✓ Error handling and retry logic
- ✓ Same precise timing as original
- ✓ Requires curefunc.lua and AutoRetainer

## Notes
- The Multi script section is **IDENTICAL** to the original Single Character - only character cycling logic was added
- All timing is preserved exactly as in the original Single Character script
- Character cycling happens **AFTER** the main script completes
- The script will stop when all characters are processed

## Support
If you encounter issues:
1. Verify all requirements are installed
2. Check character configuration format
3. Ensure AutoRetainer is working
4. Review the script output for error messages
5. Test with a single character first

## Credits
- Original Hall of the Novice script timing and movements by MacaronDream
- curefunc.lua library for character management functions by MacaronDream
- AutoRetainer plugin for character switching by NightmareXIV

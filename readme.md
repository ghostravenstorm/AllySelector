# Program: AllySelector 1.7.0
### Author: GhostRavenstorm
### Date: 2016-12-21

---

## Features
### Smart Target Cycling:
   - Allows for the user to quickly select the lowest health ally in range (35m).
   - Selects the next ally in range if no one is below 100% health.
   - Only selects the next target that is in the same PvP state as the user
     (while in PvP, only cycle through allies who are also in PvP, and ignore
     PvP allies if user is not in PvP).
   - Only selects units of the same faction as the player or if in same group as player.
   - Target cycling will skips over units that already have Bolster applied.
     (No absolute filtering controls yet to disable or enable; WIP)

### Bookmark Select Allies:
   - Allows for the user to register a keybind to select a specific ally.


## Notes
   - Ensure the Debug channel in chat window is on to receive messages
   about this addon.
   - Keybind for target cycling is defaulted to tab currently
   - Bookmarks will be erased when ui is reloaded.


## Slash Commands
   - /as-bm     -- Brings up the bookmark manager window.

   - /as-setkey -- Obsolete. The next key press after invoking this command will set the default
                   macro key to that key.

   - /as-setbm  -- Obsolete. The next key press after invoking this command will set the currently
                   selected ally to that key.

   - /as-undo   -- Obsolete. Removes the last target assigned to a keybind (one time only).

   - /as-clear  -- Obsolete. Erases all bookmarks.


## Change Log

### 1.7.0
   - Revamped old bookmarking system with new UI based version that allows
      the user to dynamically create bookmarks and set keybinds.
   - Removed slash commands /as-setbm, /as-undo, /as-clear, /as-setkey.
   - Added slash command /as-bm to bring up the bookmark manager window.
   - Included a new FixedArray class.
   - Moved sorting call to on key event instead of unit created.
   - Included a new WildstarObjectArrayList class.
   - Included a new WildstarUnitArrayList class.


### 1.6.1
   - Code cleanup.

### 1.6
   - Removed the 0 from version control.
   - Included ArrayList class to replace table setup for allies in range and
     other libs.
   - Rewrote algorithmic selection to use the ArrayList class.
   - Included smart selection checks for the Bolster buff.

### 1.05
   - Added check for same faction as player or same group.
   - Added check for if unit is dead.

### 1.04
   - Removed the need for GroupLib to get player references. All friendly
     players loaded in the region are saved and used as references.
   - Added bookmarks to quickly save priority healing targets to a key.

### 1.03
   - Removed Debug code.
   - Reinstated recursive loop for selecting lowest health ally.

### 1.02  
   - Fixed infinite recursive loop.

### 1.01  
   - Resolved a crucial bug that was trying to select players out of range.

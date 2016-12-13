
-- AllySelector v1.05
-- GhostRavenstorm
------------

-- Features
------------
Smart Target Cycling:
   - Allows for the user to quickly select the lowest health ally in range (35m).
   - Selects the next ally in range if no one is below 100% health.
   - Only selects the next target that is in the same PvP state as the user
     (while in PvP, only cycle through allies who are also in PvP, and ignore
     PvP allies if user is not in PvP).
   - Only selects units of the same faction as the player or if in same group as player.

Bookmark Healing Priority Targets:
   - Allows for the user to register a keybind to select a specific ally.


-- Notes
------------
This addon contains no GUI that can be invoked.

Ensure the Debug channel in chat window is on to receive messages
about this addon.

Keybind for target cycling will reset to its default, tab, when ui is reloaded.

Bookmarks will be erased when ui is reloaded.


-- Slash Commands
------------
/as-setkey -- The next key press after invoking this command will set the default
              macro key to that key.

/as-setbm  -- The next key press after invoking this command will set the currently
              selected ally to that key.

/as-undo   -- Removes the last target assigned to a keybind (one time only).

/as-clear  -- Erases all bookmarks.


-- Change Log
------------
1.05 -- Added check for same faction as player.
     --
1.04 -- Removed the need for GroupLib to get player references. All friendly
        players loaded in the region are saved and used as references.
     -- Added bookmarks to quickly save priority healing targets to a key.

1.03 -- Removed Debug code.
     -- Reinstated recursive loop for selecting lowest health ally.

1.02 -- Fixed infinite recursive loop.

1.01 -- Resolved a crucial bug that was trying to select players out of range.

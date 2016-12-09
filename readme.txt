
-- AllySelector v1.03
-- GhostRavenstorm
------------

-- Summary
------------
Addon that makes life better for Espers who use tab targetting for healing.

Pressing the tab key (by default) while in party will select the lowest health ally
(based on percent, not value) in range (35m). 

If all allies in range are at 100%, then this will select a random ally in 
range (self included).


-- Notes
------------
This addons contains no GUI that can be invoked.

Ensure the Debug channel in chat window is on to recieve messages
about this addon.

Setting the macro key to something other than tab doesn't persist
between /reloadui (WIP).


-- Slash Commands
------------
/as-setkey -- The next key press after invoking this command will set the default
              macro key to that key.


-- Change Log
------------
1.03 -- Removed Debug code.
     -- Reinstated recursive loop for selecting lowest health ally.

1.02 -- Fixed infinate recursive loop.

1.01 -- Resolved a crucial bug that was trying to select players out of range.





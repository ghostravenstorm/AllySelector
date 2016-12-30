#### Program: AllySelector 1.7.3
#### Author: GhostRavenstorm
#### Date: 2016-12-23

---

### Summary
- Inspired by addons such as Healie, Heal Buddy, and Grid designed to replace Wildstar's
  default tab-targeting macro for allies with smarter selection choices tailored specially
  for healers.

### Features
#### Smart Selection:
   - Allows for the user to quickly select the lowest health ally in range (35m).
   - Cycles through all allies in range if no one is below 100% health.
   - Only select units of the same faction as the player or if in same group as player.
   - PvP Filter: Only select allies in the same PvP state as you.
   - Bolster Filter: Skip over units that already have Esper's Bolster applied.

#### Bookmarks
   - Save your favorite allies to a bookmark and assign a custom keybind to quickly select
     them in the heat of combat.

#### Stickynotes
   - Project your bookmarks onto your screen as a virtual stickynote complete with
     healthbars to more closely monitor your priorities.
   - Targets of stickynotes can be quickly selected by clicking their portrait on their
     stickynote or by hovering over their portrait.


### Remarks
   - Default keybind for smart selection is set to tab currently.
   - Empty bookmarks will not be saved between sessions.
   - Stickynote selection will not work if both selection methods are enabled in the options window.


### Slash Commands
   - /as        -- Brings up the AllySelector window.


### Change Log

#### 1.7.3
   - Bookmarks save and restore between sessions if there is a unit assigned.
   - Fixed health bars on stickynotes not updating.
   - Code cleanup.

#### 1.7.2
   - Prefs save and load back in between sessions and reload.

#### 1.7.1
   - Added stickynote windows for bookmarks
   - Included new Stickynote class.
   - Added options menu for smart selection and sticknote prefs.
   - Reworked smart selection algorithm into a more condense format.

#### 1.7.0
   - Revamped old bookmarking system with new UI based version that allows
      the user to dynamically create bookmarks and set keybinds.
   - Removed slash commands /as-setbm, /as-undo, /as-clear, /as-setkey.
   - Added slash command /as-bm to bring up the bookmark manager window.
   - Included a new FixedArray class.
   - Moved sorting call to on key event instead of unit created.
   - Included a new WildstarObjectArrayList class.
   - Included a new WildstarUnitArrayList class.


#### 1.6.1
   - Code cleanup.

#### 1.6
   - Removed the 0 from version control.
   - Included ArrayList class to replace table setup for allies in range and
     other libs.
   - Rewrote algorithmic selection to use the ArrayList class.
   - Included smart selection checks for the Bolster buff.

#### 1.05
   - Added check for same faction as player or same group.
   - Added check for if unit is dead.

#### 1.04
   - Removed the need for GroupLib to get player references. All friendly
     players loaded in the region are saved and used as references.
   - Added bookmarks to quickly save priority healing targets to a key.

#### 1.03
   - Removed Debug code.
   - Reinstated recursive loop for selecting lowest health ally.

#### 1.02  
   - Fixed infinite recursive loop.

#### 1.01  
   - Resolved a crucial bug that was trying to select players out of range.

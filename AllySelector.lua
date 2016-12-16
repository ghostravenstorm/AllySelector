-----------------------------------
-- Program: AllySelector 1.7.0
-- Author: GhostRavenstorm
-- Date: 2016-12-15

-- Description: Addon for Wildstar designed to algorithmically select and cycle
-- through a list of priority allies in need of assitance based on health
-- percentages and buffs.
-----------------------------------

-- Datatype prefixes
--   n     = number
--   b     = boolean
--   t     = table
--   str   = string
--   f     = function
--   unit  = Unit
--   list  = ArrayList or FixedArray
--   ulist = UnitArrayList

require "Window"

-- AllySelector Module definition
local AllySelector = {}

-- Module definitions
local ArrayList = Apollo.GetPackage("Lib:ArrayList").tPackage
local FixedArray = Apollo.GetPackage("Lib:FixedArray").tPackage
local UnitArrayList = Apollo.GetPackage("Lib:UnitArrayList").tPackage

-- New instance of Selector
function AllySelector:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	self.nDefaultKey = 9
	self.nDefaultRange = 35

	self.nSelection = 1

	self.tTargetBookmarks = {}
	self.nLastBookmark = nil

	self.ulistAlliesInRegion = UnitArrayList:New()
	self.listAlliesBookmarked = FixedArray:New(5)

	return o
end

------------------------------
-- Constructors and Event Handlers
------------------------------

function AllySelector:Init()
    Apollo.RegisterAddon(self)
end

function AllySelector:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AllySelector.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterSlashCommand("as-setkey", "TraceKey", self)
	Apollo.RegisterSlashCommand("as-bm", "OnBookmarkManager", self)
	--Apollo.RegisterSlashCommand("as-setbm", "SetBookmark", self)
	--Apollo.RegisterSlashCommand("as-clear", "ClearBookmarks", self)
	--Apollo.RegisterSlashCommand("as-undo", "UndoLastBookmark", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	self:ResetKeyDownEventHandlers()
end

function AllySelector:ResetKeyDownEventHandlers()
	Apollo.RegisterEventHandler("SystemKeyDown", "SelectAlly", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "GetBookmark", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "Debug", self)
end

function AllySelector:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BookmarksForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

	    self.wndMain:Show(false, true)
	 end
 end

-- Debug code.
function AllySelector:Debug(nKeyCode)
	if nKeyCode == 70 then
		-- for k, v in pairs(self.tAlliesInRegionByIteration) do
		-- 	Print(tostring(k) .. " " .. v)
		-- end
		-- Print("Allies: " .. tostring(self.nAlliesInRegion))

		--self.wndMain:Invoke()

		self.listAlliesBookmarked:Print()

		-- for i = 1, self.ulistAlliesInRegion:GetLength() do
		-- 	Print(tostring(i) .. ": " .. self.ulistAlliesInRegion:GetFromIndex(i):GetName())
		-- end

		--self.ulistAlliesInRegion:Print()
	end

	if nKeyCode == 71 then
		--self.wndMain:Close()
	end
end

function AllySelector:TraceKey()
	Apollo.RegisterEventHandler("SystemKeyDown", "SetDefaultKey", self)
	Print("AllySelector: Press a key to set macro.")
end

function AllySelector:SetDefaultKey(keycode)
	self.nDefaultKey = keycode
	Print("AllySelector: Default key set to " .. tostring(self.nDefaultKey))
	Apollo.RemoveEventHandler("SystemKeyDown", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "SelectAlly", self)
end

function AllySelector:OnUnitCreated(unit)

	--Print(unit:GetName() .. " created!")
	--Print(tostring(GameLib.GetPlayerUnit()))

	-- Sort units loaded into a table if a player.
	if unit:GetType() == "Player" then

		self.ulistAlliesInRegion:Add(unit)
	end

	-- Note: There seems to be a bug with the UnitCreated event where its triggering
	--       when the user selects a unit.
end

function AllySelector:OnUnitDestroyed(unit)

	if unit:GetType() == "Player" then

		self.ulistAlliesInRegion:Remove(unit)
	end

end

--------------------------------
-- Smart Selection Algorithms
--------------------------------

function AllySelector:SelectAlly(nKeycode)
	-- Main function that is excuted when tab (or some other set binding) is pressed.

	if nKeycode == self.nDefaultKey then

		self.ulistAlliesInRegion:SortByLowestHealth()

		-- Get lowest health ally using the first party memeber, the player, as the first comparision.
		local unitNextTarget = self:GetLowestHealthAllyInRange()

		-- If the first party member is returned and is at 100%, meaning no other party member has
		-- lost any health, then select the next party member in order.
		if self:GetHealthPercent(unitNextTarget) == 1 then
			unitNextTarget = self:GetAllyInRange(self.nSelection)
		end

		-- Select referenced ally.
		if unitNextTarget then
			GameLib.SetTargetUnit(unitNextTarget)
		else
			Print("AllySelector: Error: Member reference is nil.")
		end
	end
end

function AllySelector:GetAllyInRange(nIndex)
	-- Recursively seek a valid ally in range.

	if not nIndex then
		Print("Index is nil.")
		Print("Selection: " .. tostring(self.nSelection))
		return 1
	end

	if nIndex > self.ulistAlliesInRegion:GetLength() then
		nIndex = 1
	end

	local unitAlly = self.ulistAlliesInRegion:GetFromIndex(nIndex)

	if not unitAlly then
		Print("Nil reference; Index: " .. tostring(nIndex))
		--Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	elseif not unitAlly:IsValid() then
		--Print("Invlid unit; Index: " .. tostring(nIndex))
		self.ulistAlliesInRegion:Remove(nil, nIndex)
		return self:GetAllyInRange(nIndex + 1)

	elseif not self:IsAllyInRange(unitAlly, nIndex) then
		--Print(unitAlly:GetName() .. " is not in range; Index: " .. tostring(nIndex))
		--Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	elseif not self:IsSameFactionOrInGroup(unitAlly) then
		--Print(unitAlly():GetName() .. " is not same faction or in same group: Index: " .. tostring(nIndex))
		return self:GetAllyInRange(nIndex + 1)

	elseif GameLib.GetPlayerUnit():IsPvpFlagged() ~= unitAlly:IsPvpFlagged() then
		--Print(unitAlly:GetName() .. " is not in the same PvP state; Index: " .. tostring(nIndex))
		--Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	else
		--Print(unitAlly:GetName() .. " selected; Index: " .. tostring(nIndex))
		--Print("Selection: " .. tostring(self.nSelection))
		self.nSelection = nIndex + 1
		return unitAlly
	end
end

function AllySelector:GetLowestHealthAllyInRange(nIndex)
	-- Get next ally from list assuming the list is already sorted by lowest health.

	nIndex = nIndex or 1

	if nIndex > self.ulistAlliesInRegion:GetLength() then
		return self.ulistAlliesInRegion:Get()
	end

	local unitNext = self.ulistAlliesInRegion:GetFromIndex(nIndex)

	if not self:IsAllyInRange(unitNext, nIndex) then
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	elseif not self:IsSameFactionOrInGroup(unitNext) then
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	elseif unitNext:IsDead() then
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	elseif self:IsBolsterApplied(unitNext) then
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	else
		-- This the lowest health ally that is in range, same faction or group,
		-- is not dead, and does not have a Bolster buff.
		return unitNext

	end
end

-- Depreciated. Get lowest health ally from an unsorted list.
-- function AllySelector:GetLowestHealthAllyInRange(nIteration, unitLowest)
--
-- 	--if nIteration > self.nAlliesInRegion then
-- 	if nIteration > self.ulistAlliesInRegion:GetLength() then
-- 		-- Break recursion and return once the last unit is reached.
-- 		return unitLowest
-- 	end
--
-- 	--local unitNext = self.tAlliesInRegionByName[self.tAlliesInRegionByIteration[nIteration]]
-- 	local unitNext = self.ulistAlliesInRegion:GetFromIndex(nIteration)
--
-- 	if not unitNext then
-- 		-- Iterate to next ally if current reference is nil, meaning the client
-- 		-- doesn't have the current player loaded in scene or is too far out of range.
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif not unitNext:IsValid() then
-- 		-- Check if unit exists, if not then remove it from the list and iterate
-- 		-- to the next one.
-- 		self.ulistAlliesInRegion:Remove(unitNext)
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif not self:IsAllyInRange(unitNext, nIteration) then
-- 		-- If unit is not in self's defined range, iterate to the next one in group.
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif not self:IsSameFactionOrInGroup(unitNext) then
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif unitNext:IsDead() then
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif self:GetHealthPercent(unitLowest) > self:GetHealthPercent(unitNext) then
-- 		-- If the first player's heath is greater than the next player's, set that player
-- 		-- as the lowest health player and recursively compare to the next player in order.
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitNext)
--
-- 	else
-- 		-- If first player's health is lower, then set this player as lowest and recursive compare next
-- 		-- player in order.
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
-- 	end
-- end

function AllySelector:IsSameFactionOrInGroup(unit)
	--Print(tostring(unit:GetFaction()))
	--Print(tostring(GameLib.GetPlayerUnit()))

	if unit:GetFaction() == GameLib.GetPlayerUnit():GetFaction() then
		return true
	elseif unit:IsInYourGroup() then
		return true
	else
		return false
	end
end

function AllySelector:IsBolsterApplied(unitAlly)
	-- Check ally reference for the Bolster buff.
	-- Shameful for-in-pairs loop with no recursion.

	for k, v in pairs( unitAlly:GetBuffs().arBeneficial ) do
		if v.splEffect:GetName() == "Bolster" then
			return true
		end
	end
	return false
end

function AllySelector:IsAllyInRange(unitAlly, nIndex)
	-- Determine if the unit is within range of the player.

	-- Error handling for possible nil reference.
	if not unitAlly then
		Print("AllySelector: Error: Position for unit at index " .. tostring(nIndex) .. " could not be obtained.")
		--Print(unitAlly:GetName() .. " valid: " .. tostring(unitAlly():IsValid()))
		return false
	end

	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
	local tAllyPos = unitAlly:GetPosition()

	-- Error handling for possible nil reference.
	if not tAllyPos then
		Print("AllySelector: Error: Position for unit at index " .. tosting(nIndex) .. " could not be obtained.")
		Print(unitAlly:GetName() .. " valid: " .. tostring(unitAlly():IsValid()))
		return false
	end

	local x, y, z = tPlayerPos.x - tAllyPos.x, tPlayerPos.y - tAllyPos.y, tPlayerPos.z - tAllyPos.z
	local distance = math.sqrt( (x * x) + (y * y) + (z * z) )

	if distance <= self.nDefaultRange then
		return true
	else
		return false
	end
end

function AllySelector:GetHealthPercent(unit)
	-- Convert the health value of a given unit to a percent.

	return ((unit:GetHealth() * 100) / unit:GetMaxHealth()) / 100
end

----------------------------
-- Bookmarking System
----------------------------

function AllySelector:SetAlly(wndHandler, wndControl, eMouseButton)
	local unit = GameLib.GetPlayerUnit():GetTarget()

	-- for k, v in next, getmetatable(button) do
	-- 	--Print(k)
	-- end
	--Print(button:GetContentId())
	--Print(tostring(wndControl))
	--Print(tostring(eMouseButton))
	--Print(tostring(wndHandler:GetContentId()))

	if unit then
		if unit:GetType() == "Player" then
			if self:IsSameFactionOrInGroup(unit) then
				self.wndMain:FindChild("Ally" .. tostring(wndHandler:GetContentId())):FindChild("AllyName"):SetText(unit:GetName())
				self.wndMain:FindChild("TextStatus"):SetText("Slot " .. tostring(wndHandler:GetContentId()) .. " set to " .. unit:GetName())
				self.listAlliesBookmarked:AddToIndex(unit, wndHandler:GetContentId())
			else
				self.wndMain:FindChild("TextStatus"):SetText("Error: Target is not same faction or in group.")
			end
		else
			self.wndMain:FindChild("TextStatus"):SetText("Error: Target is not a player.")
		end
	else
		-- No target.
		self.wndMain:FindChild("TextStatus"):SetText("Error: No valid target selected.")
	end
end

function AllySelector:ClearAlly(wndHandler, wndControl, eMouseButton)
	--Print(button:GetContentId())
	self.wndMain:FindChild("Ally" .. tostring(wndHandler:GetContentId())):FindChild("AllyName"):SetText("Empty")
	self.wndMain:FindChild("TextStatus"):SetText("Slot " .. tostring(wndHandler:GetContentId()) .. " cleared.")
	self.listAlliesBookmarked:RemoveFromIndex(wndHandler:GetContentId())
end

function AllySelector:GetBookmark(nKeycode)

	-- Assign keys F1 through F5 to coresponding indicies in the bookmark list.
	local keys = {
		[112] = 1,
		[113] = 2,
		[114] = 3,
		[115] = 4,
		[116] = 5
	}

	-- Filter for only F1 through F5.
	local keyPressed = keys[nKeycode]
	if not keyPressed then
		return
	end

	-- Grab unit from the appropiate index in the list based on the key.
	local unit = self.listAlliesBookmarked:GetFromIndex(keys[nKeycode])

	-- Check if somthing is there.
	if unit then
		-- Check if unit is valid.
		if unit:IsValid() then
			-- Select Unit.
			GameLib.SetTargetUnit(unit)
		else
			-- Unit is not valid.
			local textmsg = self.wndMain:FindChild("Ally" .. tostring(keys[nKeycode])):FindChild("AllyName"):GetText()
			self.wndMain:FindChild("TextStatus"):SetText("Selection Error: " .. textmsg .. " is not a valid unit. They could be too far out of range.")
		end
	else
		-- Nothing exists in this slot.
		self.wndMain:FindChild("TextStatus"):SetText("Selection Error: Nothing is assigned to Slot " .. tostring(keys[nKeycode]))
	end
end

function AllySelector:OnBookmarkManager()
	self.wndMain:Invoke()
end

function AllySelector:CloseBookmarkManager()
	self.wndMain:Close()
	--self.wndMain:FindChild("TextStatus"):SetText("Bookmark Manager ready.")
end

-- function AllySelector:SetBookmark()
-- 	-- Called when the slash command is invoked.
--
-- 	Print("AllySelector Bookmark: Next key press will bind currently selected player to that key.")
-- 	Apollo.RegisterEventHandler("SystemKeyDown", "OnSetBookmark", self)
-- end
--
-- function AllySelector:ClearBookmarks()
-- 	-- Clears all keys with saved units.
--
-- 	self.tTargetBookmarks = {}
-- 	Print("AllySelector Bookmark: All bookmarks have been cleared.")
-- end
--
-- function AllySelector:UndoLastBookmark()
-- 	-- Clears the last key that a unit was saved to.
--
-- 	local unitLast = self.tTargetBookmarks[self.nLastBookmark]
--
-- 	if unitLast then
-- 		Print("AllySelector Bookmark: " .. unitLast:GetName() .. " has been removed from key " .. tostring(self.nLastBookmark))
-- 		self.tTargetBookmarks[self.nLastBookmark] = nil
-- 	else
-- 		Print("AllySelector Bookmark: There is no unit on key " .. tostring(self.nLastBookmark) .. " to remove.")
-- 	end
-- end
--
-- function AllySelector:OnSetBookmark(nKeycode)
-- 	-- Called on next key press after slash command is invoked.
-- 	-- Sets next key press as macro to selected the currently selected unit
--
-- 	Apollo.RemoveEventHandler("SystemKeyDown", self)
-- 	self:ResetKeyDownEventHandlers()
--
-- 	local unitTarget = GameLib.GetPlayerUnit():GetTarget()
--
-- 	if unitTarget then
-- 		-- If there is a unit selected.
--
-- 		if unitTarget:GetType() == "Player" then
-- 			-- If unit is a player.
--
-- 			self.tTargetBookmarks[nKeycode] = unitTarget
-- 			self.nLastBookmark = nKeycode
-- 			Print("AllySelector Bookmark: " .. unitTarget:GetName() .. " set to key " .. tostring(nKeycode))
-- 		else
-- 			Print("AllySelector Bookmark: No valid target selected to set bookmark.")
-- 		end
-- 	end
-- end
--
-- function AllySelector:GetBookmark(nKeycode)
-- 	-- Called when any key is pressed.
--
-- 	if self.tTargetBookmarks[nKeycode] then
-- 		-- Check if key pressed has a unit saved to it.
-- 		GameLib.SetTargetUnit(self.tTargetBookmarks[nKeycode])
-- 	end
-- end

local AllySelectorInstance = AllySelector:New()
AllySelectorInstance:Init()

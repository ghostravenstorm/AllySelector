--------------------------------------------------------------------------------
-- Program: AllySelector 1.7.0
-- Author: GhostRavenstorm
-- Date: 2016-12-21

-- Description: Addon for Wildstar designed to algorithmically select and cycle
-- through a list of priority allies in need of assitance based on health
-- percentages and buffs.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Datatype prefixes
--   n     = number
--   b     = boolean
--   t     = table
--   str   = string
--   f     = function
--   unit  = Unit
--   list  = ArrayList
--------------------------------------------------------------------------------

require "Window"

-- AllySelector Module definition
local AllySelector = {}

-- Module definitions
local ArrayList = Apollo.GetPackage("Lib:ArrayList").tPackage
local FixedArray = Apollo.GetPackage("Lib:FixedArray").tPackage
local WildstarObjectArrayList = Apollo.GetPackage("Lib:WildstarObjectArrayList").tPackage
local WildstarUnitArrayList = Apollo.GetPackage("Lib:WildstarUnitArrayList").tPackage

local DEBUG = false

-- New instance of Selector
function AllySelector:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.nDefaultKey = 9
	o.nDefaultRange = 35

	o.nSelection = 1

	o.bIsKeybindBeingSet = false

	--o.tTargetBookmarks = {}
	--o.nLastBookmark = nil

	--self.listAlliesBookmarked = FixedArray:New(5)

	-- TODO: Hardcoded for just bookmark 1. Check all.
	--self.nBookmark1Limit = 0
	--self.bIsBookarmark1Priority = false

	o.listAlliesInRegion = WildstarUnitArrayList:New()
	o.listBookmarks = WildstarObjectArrayList:New()

	return o
end

--------------------------------------------------------------------------------
-- Constructors and Event Handlers
--------------------------------------------------------------------------------

function AllySelector:Init()
    Apollo.RegisterAddon(self)
end

function AllySelector:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AllySelector.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	--Apollo.RegisterSlashCommand("as-setkey", "TraceKey", self)
	Apollo.RegisterSlashCommand("as-bm", "OnBookmarkManager", self)
	--Apollo.RegisterSlashCommand("as-setbm", "SetBookmark", self)
	--Apollo.RegisterSlashCommand("as-clear", "ClearBookmarks", self)
	--Apollo.RegisterSlashCommand("as-undo", "UndoLastBookmark", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	self:ResetKeyDownEventHandlers()
end

function AllySelector:ResetKeyDownEventHandlers()
	Apollo.RegisterEventHandler("SystemKeyDown", "OnKeyDown", self)
	--Apollo.RegisterEventHandler("SystemKeyDown", "SelectBookmark", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "Debug", self)
end

function AllySelector:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BookmarkWindow", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

	    self.wndMain:Show(false, true)
	 end
 end

-- Debug code.
function AllySelector:Debug(nKeyCode)
	if DEBUG and nKeyCode == 70 then
		-- for k, v in pairs(self.tAlliesInRegionByIteration) do
		-- 	Print(tostring(k) .. " " .. v)
		-- end
		-- Print("Allies: " .. tostring(self.nAlliesInRegion))

		--self.wndMain:Invoke()

		--self.listAlliesBookmarked:Print()

		for i = 1, self.listAlliesInRegion:GetLength() do
			Print(tostring(i) .. ": " .. self.listAlliesInRegion:GetFromIndex(i):GetName())
		end

		--self.listAlliesInRegion:Print()
	end

	if DEBUG and nKeyCode == 71 then
		for i = 1, self.listBookmarks:GetLength() do
			local thing = self.listBookmarks:GetFromIndex(i)
			Print(tostring(i) .. ": " .. thing:GetName() .. ": " .. tostring(thing:GetData().index))
		end
	end
end

function AllySelector:OnBookmarkManager()
	self.wndMain:Invoke()
end

function AllySelector:OnKeyDown(nKeycode)

	local function CheckBookmarkKeybinds(index)
		-- Recursively check if the key pressed matches a keybind for any of the
		-- bookmarks.

		if index > self.listBookmarks:GetLength() then
			return
		else
			if nKeycode == self.listBookmarks:GetFromIndex(index):GetData().keybind then
				self:SelectBookmark(index)
				return
			else
				return CheckBookmarkKeybinds(index + 1)
			end
		end
	end

	CheckBookmarkKeybinds(1)

	local function SetBookmarkKeybind(index)
		-- Recursively check if any bookmark is looking for a new keybind.

		if index > self.listBookmarks:GetLength() then
			return
		elseif self.listBookmarks:GetFromIndex(index):GetData().isLookingForKey then
			-- If so, set this key as the new keybind for bookmark at index.

			local oldData = self.listBookmarks:GetFromIndex(index):GetData()
			local newData = {unit = oldData.unit, index = oldData.index, keybind = nKeycode, isLookingForKey = false}
			self.listBookmarks:GetFromIndex(index):SetData(newData)
			self.listBookmarks:GetFromIndex(index):FindChild("KeybindBtn"):SetText(enumKeys[nKeycode])
			self.wndMain:FindChild("StatusMsg"):SetText("Keybind set to " .. enumKeys[nKeycode])
			return
		else
			return SetBookmarkKeybind(index + 1)
		end
	end

	SetBookmarkKeybind(1)
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

	-- Sort units loaded into a table if a player.
	if unit:GetType() == "Player" then

		self.listAlliesInRegion:Add(unit)
	end

	-- NOTE: There seems to be a bug with the UnitCreated event where its triggering
	--       when the a unit is selected.
end

function AllySelector:OnUnitDestroyed(unit)

	if unit:GetType() == "Player" then

		self.listAlliesInRegion:Remove(unit)
	end
end

--------------------------------------------------------------------------------
-- Smart Selection Algorithms
--------------------------------------------------------------------------------

function AllySelector:SelectAlly(nKeycode)
	-- Main function that is excuted when tab (or some other set binding) is pressed.

	if nKeycode ~= self.nDefaultKey then return end

	self.listAlliesInRegion:SortByLowestHealth()

	local unitNextTarget

	-- if self:GetBookmarkPriority() then
	-- 	unitNextTarget = self:GetBookmarkPriority()
	-- else
	if self:GetHealthPercent(self.listAlliesInRegion:GetFromIndex(1)) ~= 1 then
		-- Get lowest health ally.
		unitNextTarget = self:GetLowestHealthAllyInRange()
	else
		-- If the first unit the the list is at 100%, then get next unit.
		unitNextTarget = self:GetAllyInRange(self.nSelection)
	end
	-- end

	-- -- Get lowest health ally using the first party memeber, the player, as the first comparision.
	-- unitNextTarget = self:GetLowestHealthAllyInRange()
	--
	-- -- If the first party member is returned and is at 100%, meaning no other party member has
	-- -- lost any health, then select the next party member in order.
	-- if self:GetHealthPercent(unitNextTarget) == 1 then
	-- 	unitNextTarget = self:GetAllyInRange(self.nSelection)
	-- end

	-- Select referenced ally.
	if unitNextTarget then
		GameLib.SetTargetUnit(unitNextTarget)
	else
		Print("AllySelector: Error: Member reference is nil.")
	end
end

function AllySelector:GetAllyInRange(nIndex)
	-- Return the next unit in the list that passes these checks.

	-- Error handling.
	if not nIndex then
		Print("Index is nil.")
		Print("Selection: " .. tostring(self.nSelection))
		return 1
	end

	if nIndex > self.listAlliesInRegion:GetLength() then
		nIndex = 1
	end

	local unitAlly = self.listAlliesInRegion:GetFromIndex(nIndex)

	if not unitAlly then
		--Print("Nil reference; Index: " .. tostring(nIndex))
		--Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	elseif not unitAlly:IsValid() then
		--Print("Invlid unit; Index: " .. tostring(nIndex))
		self.listAlliesInRegion:RemoveFromIndex(nIndex)
		return self:GetAllyInRange(nIndex + 1)

	elseif not self:IsAllyInRange(unitAlly) then
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

	elseif unitAlly:IsDead() then
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
	-- This algorithm starts from the beginning of the list and returns the frist unit
   -- that passes these checks.

	nIndex = nIndex or 1

	if nIndex > self.listAlliesInRegion:GetLength() then
		return self.listAlliesInRegion:GetLast()
	end

	local unitNext = self.listAlliesInRegion:GetFromIndex(nIndex)

	if not unitNext then
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	elseif not unitNext:IsValid() then
		self.listAlliesInRegion:RemoveFromIndex(nIndex)
		return self:GetLowestHealthAllyInRange(nIndex + 1)

	elseif not self:IsAllyInRange(unitNext) then
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

-- TODO: This methods needs tweaking. WIP.
function AllySelector:GetBookmarkPriority(nIndex)

	nIndex = nIndex or 1

	if nIndex > self.listAlliesBookmarked:GetLength() then return end

	local bookmark = self.listAlliesBookmarked:GetFromIndex(nIndex)

	if not bookmark then
		return self:GetBookmarkPriority(nIndex + 1)
	elseif bookmark.bIsPriority then
		if self:IsBookmarkAtThreashold(bookmark) then
			return bookmark.unit
		else
			return self:GetBookmarkPriority(nIndex + 1)
		end
	else
		return self:GetBookmarkPriority(nIndex + 1)
	end
end

-- TODO: Move this inside GetBookmarkPriority.
function AllySelector:IsBookmarkAtThreashold(bookmark)

	if self:GetHealthPercent(bookmark.unit) <= bookmark.nThreashold then
		return true
	else
		return false
	end
end


-- Obsolete. Get lowest health ally from an unsorted list.
-- Keeping for example purposes.
-- function AllySelector:GetLowestHealthAllyInRange(nIteration, unitLowest)
--
-- 	--if nIteration > self.nAlliesInRegion then
-- 	if nIteration > self.listAlliesInRegion:GetLength() then
-- 		-- Break recursion and return once the last unit is reached.
-- 		return unitLowest
-- 	end
--
-- 	--local unitNext = self.tAlliesInRegionByName[self.tAlliesInRegionByIteration[nIteration]]
-- 	local unitNext = self.listAlliesInRegion:GetFromIndex(nIteration)
--
-- 	if not unitNext then
-- 		-- Iterate to next ally if current reference is nil, meaning the client
-- 		-- doesn't have the current player loaded in scene or is too far out of range.
-- 		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
--
-- 	elseif not unitNext:IsValid() then
-- 		-- Check if unit exists, if not then remove it from the list and iterate
-- 		-- to the next one.
-- 		self.listAlliesInRegion:Remove(unitNext)
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

function AllySelector:IsAllyInRange(unitAlly)
	-- Determine if the unit is within range of the player.

	-- Error handling for possible nil reference.
	-- if not unitAlly then
	-- 	Print("AllySelector: Error: Position for unit at index " .. tostring(nIndex) .. " could not be obtained.")
	-- 	--Print(unitAlly:GetName() .. " valid: " .. tostring(unitAlly():IsValid()))
	-- 	return false
	-- end

	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
	local tAllyPos = unitAlly:GetPosition()

	-- Error handling for possible nil reference.
	-- if not tAllyPos then
	-- 	Print("AllySelector: Error: Position for unit at index " .. tosting(nIndex) .. " could not be obtained.")
	-- 	Print(unitAlly:GetName() .. " valid: " .. tostring(unitAlly():IsValid()))
	-- 	return false
	-- end

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

--------------------------------------------------------------------------------
-- GUI Event Handlers
--------------------------------------------------------------------------------

function AllySelector:OnCloseBtn()
	-- Close the bookmark manager.
	self.wndMain:Close()
end

function AllySelector:OnNewBookmarkBtn(wndHandler)
	-- Create a new bookmark node.

	local bookmark = Apollo.LoadForm(self.xmlDoc, "BookmarkModule", self.wndMain:FindChild("Bookmarks"), self)

	-- NOTE: Bookmark data is set to the absolute root of the bookmark module.

	-- Add the new bookmark to the list and set its data.
	self.listBookmarks:Add(bookmark)
	self.listBookmarks:GetLast():SetData({unit = nil, index = self.listBookmarks:GetIndexOfObject(bookmark), keybind = nil, isLookingForKey = false})

	-- Arrange bookmarks to prevent overlap.
	self.wndMain:FindChild("Bookmarks"):ArrangeChildrenVert()

	-- Print status message and set bookmark node's number.
	self.wndMain:FindChild("StatusMsg"):SetText("Bookmark node " .. tostring(bookmark:GetId()) .. " created.")
	self.listBookmarks:GetLast():FindChild("NumberSocket"):SetText(tostring(self.listBookmarks:GetIndexOfObject(bookmark)))

	-- TODO: Condense line length of this code.
end

function AllySelector:OnBookmarkSetBtn(wndHandler)
	-- Set the player's current target to the bookmark of this button event.

	local unit = GameLib.GetPlayerUnit():GetTarget()

	if unit then
		if unit:GetType() == "Player" then
			if self:IsSameFactionOrInGroup(unit) then
				-- Check if unit is there, is a player, and is same faction or in group.

				-- Set the name of the targeted player to the bookmark node of this button.
				wndHandler:GetParent():FindChild("Name"):SetText(unit:GetName())

				-- Set the unit reference that is to be selected to the bookmark.
				local data = wndHandler:GetParent():GetData()
				wndHandler:GetParent():SetData({unit = unit, index = data.index, keybind = data.keybind, isLookingForKey = data.isLookingForKey})

				-- Print status message.
				local msg = "Bookmark " .. tostring(data.index) .. " set to " .. unit:GetName()
				self.wndMain:FindChild("StatusMsg"):SetText(msg)
			else
				-- Print status message.
				self.wndMain:FindChild("StatusMsg"):SetText("Error: Target is not same faction or in group.")
			end
		else
			-- Print status message.
			self.wndMain:FindChild("StatusMsg"):SetText("Error: Target is not a player.")
		end
	else
		-- Print status message.
		self.wndMain:FindChild("StatusMsg"):SetText("Error: No valid target selected.")
	end

	-- TODO: Condense line length of this code.
end

function AllySelector:OnBookmarkClearBtn(wndHandler)
	-- Clear the name field and remove unit refernece from the bookmark of this button.

	wndHandler:GetParent():FindChild("Name"):SetText("")

	-- Remove unit refernece from bookmark.
	local oldData = wndHandler:GetParent():GetData()
	local newData = {unit = nil, index = oldData.index, keybind = oldData.keybind, isLookingForKey = oldData.isLookingForKey}
	wndHandler:GetParent():SetData(newData)

	-- TODO: Condense line length of this code.
end

function AllySelector:OnBookmarkKeybindBtn(wndHandler)
	-- Set keybind to the next key that is press for the bookmark of this button.

	-- This node is now lookng for a new keybind.
	local oldData = wndHandler:GetParent():GetData()
	local newData = {unit = oldData.unit, index = oldData.index, keybind = oldData.keybind, isLookingForKey = true}
	wndHandler:GetParent():SetData(newData)

	-- Print status message.
	self.wndMain:FindChild("StatusMsg"):SetText("Press any key to set a keybind.")

	-- TODO: Condense line length of this code.
end

function AllySelector:OnBookmarkDeleteBtn(wndHandler)
	-- Destroy the bookmark node of this button.

	-- Print status message.
	self.wndMain:FindChild("StatusMsg"):SetText("Bookmark node " .. tostring(wndHandler:GetParent():GetId()) .. " deleted.")

	-- Remove this node from the list, destroy the window component, and re-arrange
	-- all the remaining nodes.
	self.listBookmarks:Remove(wndHandler:GetParent())
	wndHandler:GetParent():Destroy()
	self.wndMain:FindChild("Bookmarks"):ArrangeChildrenVert()

	local function ResetIndicies(index)
		-- Recursively check all bookmarks if their bookmark number matches their
		-- placement in the list.

		if index > self.listBookmarks:GetLength() then
			return
		else
			-- Set the new number of this bookmark to its position in the list.
			local oldData = self.listBookmarks:GetFromIndex(index):GetData()
			local newData = {unit = oldData.unit, index = index, keybind = oldData.keybind, isLookingForKey = oldData.isLookingForKey}
			self.listBookmarks:GetFromIndex(index):SetData(newData)
			self.listBookmarks:GetFromIndex(index):FindChild("NumberSocket"):SetText(tostring(index))

			return ResetIndicies(index + 1)
		end
	end

	ResetIndicies(1)
end

--------------------------------------------------------------------------------
-- Bookmarking System
--------------------------------------------------------------------------------

function AllySelector:SelectBookmark(nIndex)
	-- Select the unit of the bookmark at index in the list.

	local unit = self.listBookmarks:GetFromIndex(nIndex):GetData().unit

	-- Check if somthing is there.
	if unit then
		-- Check if unit is valid.
		if unit:IsValid() then
			-- Select Unit.
			GameLib.SetTargetUnit(unit)
		else
			-- Unit is not valid.
			local name = self.listBookmarks:GetFromIndex(nIndex):FindChild("Name"):GetText()
			self.wndMain:FindChild("StatusMsg"):SetText("Selection Error: " .. name .. " is not valid. They could be too far out of range.")
		end
	else
		-- Nothing exists in this slot.
		self.wndMain:FindChild("StatusMsg"):SetText("Selection Error: Nothing is assigned to Slot " .. tostring(nIndex))
	end
end

-- function AllySelector:SetAlly(wndHandler, wndControl, eMouseButton)
-- 	local unit = GameLib.GetPlayerUnit():GetTarget()
--
-- 	-- for k, v in next, getmetatable(button) do
-- 	-- 	--Print(k)
-- 	-- end
-- 	--Print(button:GetContentId())
-- 	--Print(tostring(wndControl))
-- 	--Print(tostring(eMouseButton))
-- 	--Print(tostring(wndHandler:GetContentId()))
--
-- 	-- Bookmark structure containing the reference unit, is it marked as a priority,
-- 	-- and what its health threashold is.
-- 	local bookmark = {unit = unit, bIsPriority = false, nThreashold = 0}
--
-- 	if unit then
-- 		if unit:GetType() == "Player" then
-- 			if self:IsSameFactionOrInGroup(unit) then
-- 				self.wndMain:FindChild("Ally" .. tostring(wndHandler:GetContentId())):FindChild("Name"):SetText(unit:GetName())
-- 				self.wndMain:FindChild("StatusMsg"):SetText("Slot " .. tostring(wndHandler:GetContentId()) .. " set to " .. unit:GetName())
-- 				self.listAlliesBookmarked:AddToIndex(bookmark, wndHandler:GetContentId())
-- 			else
-- 				self.wndMain:FindChild("StatusMsg"):SetText("Error: Target is not same faction or in group.")
-- 			end
-- 		else
-- 			self.wndMain:FindChild("StatusMsg"):SetText("Error: Target is not a player.")
-- 		end
-- 	else
-- 		-- No target.
-- 		self.wndMain:FindChild("StatusMsg"):SetText("Error: No valid target selected.")
-- 	end
-- end
--
-- function AllySelector:ClearAlly(wndHandler, wndControl, eMouseButton)
-- 	--Print(wndHandler:GetContentId())
-- 	self.wndMain:FindChild("Ally" .. tostring(wndHandler:GetContentId())):FindChild("Name"):SetText("")
-- 	self.wndMain:FindChild("StatusMsg"):SetText("Slot " .. tostring(wndHandler:GetContentId()) .. " cleared.")
-- 	self.listAlliesBookmarked:RemoveFromIndex(wndHandler:GetContentId())
-- end
--
-- function AllySelector:GetBookmark(nKeycode)
--
-- 	-- Assign keys F1 through F5 to coresponding indicies in the bookmark list.
-- 	local keys = {
-- 		[112] = 1,
-- 		[113] = 2,
-- 		[114] = 3,
-- 		[115] = 4,
-- 		[116] = 5
-- 	}
--
-- 	-- Filter for only F1 through F5.
-- 	if not keys[nKeycode] then return end
--
-- 	-- Grab unit from the appropiate index in the list based on the key.
-- 	local unit
-- 	if self.listAlliesBookmarked:GetFromIndex(keys[nKeycode]) then
-- 		unit = self.listAlliesBookmarked:GetFromIndex(keys[nKeycode]).unit
-- 	end
--
-- 	-- Check if somthing is there.
-- 	if unit then
-- 		-- Check if unit is valid.
-- 		if unit:IsValid() then
-- 			-- Select Unit.
-- 			GameLib.SetTargetUnit(unit)
-- 		else
-- 			-- Unit is not valid.
-- 			local textmsg = self.wndMain:FindChild("Ally" .. tostring(keys[nKeycode])):FindChild("Name"):GetText()
-- 			self.wndMain:FindChild("StatusMsg"):SetText("Selection Error: " .. textmsg .. " is not a valid unit. They could be too far out of range.")
-- 		end
-- 	else
-- 		-- Nothing exists in this slot.
-- 		self.wndMain:FindChild("StatusMsg"):SetText("Selection Error: Nothing is assigned to Slot " .. tostring(keys[nKeycode]))
-- 	end
-- end
--
-- function AllySelector:OnPriorityEnable(wndHandler)
-- 	--Print(tostring(param1))
-- 	--Print(tostring(param2))
-- 	--Print(tostring(param3))
-- 	--Print("Bookmark 1 Priority: " .. tostring(wndHandler:IsChecked()))
-- 	--self.bIsBookarmark1Priority = wndHandler:IsChecked()
--
-- 	local bookmark = self.listAlliesBookmarked:GetFromIndex(wndHandler:GetContentId())
--
-- 	if bookmark then
-- 		bookmark.bIsPriority = wndHandler:IsChecked()
-- 	end
--
-- end
--
-- function AllySelector:OnSliderChanging(wndHandler, wndControl, nNewValue, nOldValue, bOkToChange)
--
-- 	wndHandler:SetValue(nNewValue)
--
-- 	-- TODO: Sliders do not have a content ID to get. Find some other way to identify
-- 	--       which slider is changing.
--
-- 	-- self.wndMain:FindChild("Ally" .. tostring(wndHandler:GetContentId())):FindChild("HealthPercent"):SetText(math.floor(nNewValue))
-- 	--
-- 	-- -- listAlliesBookmarked contains bookmark objects defined as
-- 	-- --   {unitPlayer, sIsPriority, nThreashold}
-- 	-- local bookmark = self.listAlliesBookmarked:GetFromIndex(wndHandler:GetContentId())
-- 	-- -- Ideally, each slider would have a number assigned with them to identify which bookmark its part of.
-- 	-- -- This number is then used to fetch the corresponding item from the array.
-- 	--
-- 	-- if bookmark then
-- 	-- 	bookmark.nThreashold = nNewValue
-- 	-- end
-- end
--
-- function AllySelector:CloseBookmarkManager()
-- 	self.wndMain:Close()
-- 	--self.wndMain:FindChild("TextStatus"):SetText("Bookmark Manager ready.")
-- end

--------------------------------------------------------------------------------
-- Obsolete. Non-gui bookmarking system
--------------------------------------------------------------------------------

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

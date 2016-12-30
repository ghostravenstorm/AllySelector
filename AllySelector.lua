--------------------------------------------------------------------------------
-- Program: AllySelector 1.7.3
-- Author: GhostRavenstorm
-- Date: 2016-12-29

-- Description: Addon for Wildstar designed to algorithmically select and cycle
-- through a list of priority allies in need of assitance based on health
-- percentages and buffs.
--------------------------------------------------------------------------------


require "Window"

-- AllySelector Module definition
local AllySelector = {}

-- Module definitions
local ArrayList = Apollo.GetPackage("Lib:ArrayList").tPackage
local WildstarObjectArrayList = Apollo.GetPackage("Lib:WildstarObjectArrayList").tPackage
local WildstarUnitArrayList = Apollo.GetPackage("Lib:WildstarUnitArrayList").tPackage
local Stickynote = Apollo.GetPackage("Mod:Stickynote").tPackage
local Bookmark = Apollo.GetPackage("Mod:Bookmark").tPackage

local DEBUG = false

function AllySelector:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.nDefaultKey = 9
	o.nDefaultRange = 35
	o.nSelection = 0

	o.bUseSmartSelection = true
	o.bUseBolsterFilter = false
	o.bUsePvpFilter = true
	o.bSelectOnMouseButton = true
	o.bSelectOnMouseEnter = false

	-- This list also contains enemy faction players.
	o.listAlliesInRegion = WildstarUnitArrayList:New()
	o.listBookmarks = ArrayList:New()

	-- Placeholder for loading in saved bookmarks.
	o.listCachedBookmarks = ArrayList:New()

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

	Apollo.RegisterSlashCommand("as", "OnBookmarkManager", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "OnKeyDown", self)
	--Apollo.RegisterEventHandler("SystemKeyDown", "Debug", self)
end


function AllySelector:OnSave(eLevel)

	if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		-- Return addon preferences.
		return {
			bUseSmartSelection = self.bUseSmartSelection,
			bUseBolsterFilter = self.bUseBolsterFilter,
			bUsePvpFilter = self.bUsePvpFilter,
			bSelectOnMouseButton = self.bSelectOnMouseButton,
			bSelectOnMouseEnter = self.bSelectOnMouseEnter
		}
	end

	-- Rcursive routine for converting bookmarks to standard lua tables.
	local function SerializeBookmarks(listData, index)
		if index > self.listBookmarks:GetLength() then
			return listData
		else
			-- Get a standard lua table for each bookmark.
			local bookmark = self.listBookmarks:GetFromIndex(index):GetSerializedTable()

			-- Add to list if GetSerializedTable returned something.
			if bookmark then
				listData:AddDuplicate(bookmark)
			end

			return SerializeBookmarks(listData, index + 1)
		end
	end

	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		if self.listBookmarks:GetLength() == 0 then
			if DEBUG then Print("No bookmarks to save.") end
			return {listData = "nothing"}
		else
			-- Convert all bookmarks to a stard lua table, add to arraylist, then
			-- convert arraylist to stard lua table for Wildstar's save routine.
			return {listData = SerializeBookmarks(ArrayList:New(), 1):GetConvertedTable()}
		end
	end
end

function AllySelector:OnRestore(eLevel, tData)

	if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then

		-- Restore addon preferences from last session.
		if tData then
			self.bUseSmartSelection = tData.bUseSmartSelection
			self.bUseBolsterFilter = tData.bUseBolsterFilter
			self.bUsePvpFilter = tData.bUsePvpFilter
			self.bSelectOnMouseButton = tData.bSelectOnMouseButton
			self.bSelectOnMouseEnter = tData.bSelectOnMouseEnter
		end
	end

	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then

		-- Restore bookmark data from last session to a temporary location.
		if type(tData.listData) == "table" then
			self.listCachedBookmarks = ArrayList:New(tData.listData)
			-- NOTE: See OnDocLoaded.
		else
			if DEBUG then Print("Nothing to restore.") end
		end
	end
end


function AllySelector:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BookmarkWindow", nil, self)
		 self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsWindow", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

	    self.wndMain:Show(false, true)
		 self.wndOptions:Show(false, true)

		 self.wndOptions:FindChild("EnableSmartSelectionBtn"):SetCheck(self.bUseSmartSelection)
		 self.wndOptions:FindChild("EnablePvpFilterBtn"):SetCheck(self.bUsePvpFilter)
		 self.wndOptions:FindChild("EnableBolsterFilterBtn"):SetCheck(self.bUseBolsterFilter)
		 self.wndOptions:FindChild("MouseClickBtn"):SetCheck(self.bSelectOnMouseButton)
		 self.wndOptions:FindChild("MouseEnterBtn"):SetCheck(self.bSelectOnMouseEnter)

		-- Restore bookmark modules for each dataset that has been restored.
		if self.listCachedBookmarks:GetLength() > 0 then

			-- Recurive routine for restoring the window modules for saved bookmarks.
			local function RestoreBookmarks(nBookmarkIndex, nUnitIndex)

				if nBookmarkIndex > self.listCachedBookmarks:GetLength() then
					return
				else

					if nUnitIndex > self.listAlliesInRegion:GetLength() then
						return RestoreBookmarks(nBookmarkIndex + 1, 1)
					elseif self.listCachedBookmarks:GetFromIndex(nBookmarkIndex).strUnitName ==
					       self.listAlliesInRegion:GetFromIndex(nUnitIndex):GetName() then
						local bookmark = Bookmark:New(
							self,
							self.listBookmarks:GetLength() + 1,
							self.listAlliesInRegion:GetFromIndex(nUnitIndex),
							self.listCachedBookmarks:GetFromIndex(nBookmarkIndex).nKeybind,
							self.listCachedBookmarks:GetFromIndex(nBookmarkIndex).bHasStickynote
						)

						self.listBookmarks:Add(bookmark)
						self.wndMain:FindChild("Bookmarks"):ArrangeChildrenVert()

						return RestoreBookmarks(nBookmarkIndex + 1, 1)
					else
						return RestoreBookmarks(nBookmarkIndex, nUnitIndex + 1)
					end
				end

			end -- RestoreBookmarks

			RestoreBookmarks(1, 1)

		end -- if self.listCachedBookmarks:GetLength

	end -- if self.xmlDoc
end -- OnDocLoaded

-- Debug code.
-- function AllySelector:Debug(nKeyCode)
-- 	if DEBUG and nKeyCode == 70 then
-- 		-- for k, v in pairs(self.tAlliesInRegionByIteration) do
-- 		-- 	Print(tostring(k) .. " " .. v)
-- 		-- end
-- 		-- Print("Allies: " .. tostring(self.nAlliesInRegion))
--
-- 		--self.wndMain:Invoke()
--
-- 		--self.listAlliesBookmarked:Print()
--
-- 		for i = 1, self.listAlliesInRegion:GetLength() do
-- 			Print(tostring(i) .. ": " .. self.listAlliesInRegion:GetFromIndex(i):GetName())
-- 		end
--
-- 		--self.listAlliesInRegion:Print()
-- 	end
--
-- 	if DEBUG and nKeyCode == 71 then
-- 		for i = 1, self.listBookmarks:GetLength() do
-- 			local thing = self.listBookmarks:GetFromIndex(i)
-- 			Print(tostring(i) .. ": " .. thing:GetName() .. ": " .. tostring(thing:GetData().index))
-- 		end
-- 	end
--
-- 	if DEBUG and nKeyCode == 84 then
--
--
-- 		local savedData = self:OnSave(GameLib.CodeEnumAddonSaveLevel.Character)
-- 		self:OnRestore(GameLib.CodeEnumAddonSaveLevel.Character, savedData)
-- 		self.listCachedBookmarks:Print()
-- 	end
-- end

function AllySelector:OnBookmarkManager()
	self.wndMain:Invoke()
end

function AllySelector:OnKeyDown(nKeycode)

	-- Select an ally if the tab key is pressed.
	if enumKeys[nKeycode] == "tab" then
		-- If smart selection if turned on.
		if self.bUseSmartSelection then
			self:SelectAlly()
		end
	end
end

function AllySelector:OnUnitCreated(unit)

	-- Sort units loaded into a table if a player.
	if unit:GetType() == "Player" then
		if self.bUseSmartSelection then
			self.listAlliesInRegion:Add(unit)
		end
	end

	-- NOTE: There seems to be a bug with the UnitCreated event where its triggering
	--       when the a unit is selected.
end

function AllySelector:OnUnitDestroyed(unit)

	if unit:GetType() == "Player" then
		if self.bUseSmartSelection then
			self.listAlliesInRegion:Remove(unit)
		end
	end
end

--------------------------------------------------------------------------------
-- Smart Selection Algorithms
--------------------------------------------------------------------------------

-- Main function that is excuted when tab (or some other set binding) is pressed.
function AllySelector:SelectAlly()

	-- Sort the list so the lowest health ally is always first.
	self.listAlliesInRegion:SortByLowestHealth()

	local unitNextTarget

	-- TODO: Check bookmarks if their priority threashold has been reached, if so
	--       then select the first occurance.

	-- Check if the first unit in the list has taken damage.
	if self:GetHealthPercent(self.listAlliesInRegion:GetFromIndex(1)) ~= 1 then
		-- Get lowest health ally assuming the list is already sorted by lowest health.
		-- Passing in 1 to start at the beginning of the list.
		unitNextTarget = self:GetNextAlly(1)
	else
		-- If the first unit in the list is at 100%, then get next unit in order.
		unitNextTarget = self:GetNextAlly(self.nSelection + 1)
		-- NOTE: nSeletion saves the last unit that was selected when GetNextAlly
		--       is called. When passed in in this case with +1, the next ally in
		--       the list order will be selected.
	end

	-- Select referenced unit.
	if unitNextTarget then
		GameLib.SetTargetUnit(unitNextTarget)
	else
		Print("AllySelector: Error: No unit reference.")
	end
end

-- Recursively check all units in listAlliesInRegion starting at a given index.
function AllySelector:GetNextAlly(nIndex)
	-- NOTE: This method assumes listAlliesInRegion is sorted by lowest health.
	--       When 1 is passed in as the starting index for this recursive
	--       search, it will return the first unit in the list. If that unit is
	--       not valid for selection based on the following conditions, then Move
	--       on to the next unit in order.

	nIndex = nIndex or 1

	if nIndex > self.listAlliesInRegion:GetLength() then
		-- When the end of the list is reached, reset nSelection to 1, and return
		-- the first unit in the list.

		-- TODO: Remember what nSelection was when it was first passed in and don't
	   --       break until that value is reached again. Rollover to the beginning
		--       when end of list is reached.

		self.nSelection = 1
		local unit = self.listAlliesInRegion:GetFromIndex(1)
		if DEBUG then Print(tostring(1) .. ": " .. unit:GetName() .. " selected.") end

		return self.listAlliesInRegion:GetFromIndex(1)
	end

	local unit = self.listAlliesInRegion:GetFromIndex(nIndex)

	-- If this unit doesn't pass any of the below checks, then check the next one.
	if not unit then
		if DEBUG then Print(tostring(nIndex) .. ": No reference to select.") end
		return self:GetNextAlly(nIndex + 1)

	elseif not unit:IsValid() then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " is not valid.") end
		self.listAlliesInRegion:Remove(unit)
		return self:GetNextAlly(nIndex + 1)

	elseif not self:IsInRange(unit) then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " is not in range.") end
		return self:GetNextAlly(nIndex + 1)

	elseif not self:IsSameFacOrGroup(unit) then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " is not same faction or group.") end
		return self:GetNextAlly(nIndex + 1)

	elseif not self:IsSamePvpState(unit) then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " is same PvP state.") end
		return self:GetNextAlly(nIndex + 1)

	elseif unit:IsDead() then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " is dead.") end
		return self:GetNextAlly(nIndex + 1)

	elseif self:HasBolster(unit) then
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " already has Bolster.") end
		return self:GetNextAlly(nIndex + 1)

	else
		if DEBUG then Print(tostring(nIndex) .. ": " .. unit:GetName() .. " selected.") end
		self.nSelection = nIndex

		-- Return this unit after having passed all the above checks.
		return unit
	end
end

-- TODO: Setup priority threshold system for bookmarks.
-- TODO: This method needs tweaking. WIP.
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

-- Recursively get lowest health ally from an unsorted list. Keep for reference.
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

function AllySelector:IsSameFacOrGroup(unit)

	if unit:GetFaction() == GameLib.GetPlayerUnit():GetFaction() then
		return true
	elseif unit:IsInYourGroup() then
		return true
	else
		return false
	end
end

function AllySelector:IsSamePvpState(unit)
	if not self.bUsePvpFilter then
		return true
	elseif unit:IsPvpFlagged() == GameLib.GetPlayerUnit():IsPvpFlagged() then
		return true
	else
		return false
	end
end

function AllySelector:HasBolster(unit)
	-- Check ally reference for the Bolster buff.

	-- Return false meaning do not filter based on this buff.
	if not self.bUseBolsterFilter then return false end

	for k, v in pairs( unit:GetBuffs().arBeneficial ) do
		if v.splEffect:GetName() == "Bolster" then
			return true
		end
	end
	return false
end

function AllySelector:IsInRange(unit)
	-- Determine if the unit is within range of the player.

	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
	local tAllyPos = unit:GetPosition()

	local x, y, z = tPlayerPos.x - tAllyPos.x, tPlayerPos.y - tAllyPos.y, tPlayerPos.z - tAllyPos.z
	local distance = math.sqrt( (x * x) + (y * y) + (z * z) )

	if distance <= self.nDefaultRange then
		return true
	else
		return false
	end
end

function AllySelector:GetHealthPercent(unit)
	-- Return the health value of a given unit to a decimal value between 0 and 1.
	return ((unit:GetHealth() * 100) / unit:GetMaxHealth()) / 100
end

--------------------------------------------------------------------------------
-- GUI Event Handlers
--------------------------------------------------------------------------------

-- Main Window --

function AllySelector:OnBookmarkDestroyed(oBookmark)
	-- Remove bookmark triggered by this event from the list and reset the indicies
	-- all all the remining bookmarks listed after the one given.

	-- Recursively get every bookmark starting from the one being removed.
	local function ResetIndicies(index)
		if index > self.listBookmarks:GetLength() then
			return
		else
			-- Reduce the index value of this bookmark by 1.
			self.listBookmarks:GetFromIndex(index):SetIndex(index - 1)
			return ResetIndicies(index + 1)
		end
	end

	-- Reset the index value of every bookmark in order listed after this one.
	ResetIndicies(oBookmark.nIndex + 1)

	self.listBookmarks:Remove(oBookmark)
	self.wndMain:FindChild("Bookmarks"):ArrangeChildrenVert()
end

function AllySelector:OnCloseBtn(wndHandler)
	-- Close the parent window.
	wndHandler:GetParent():Close()
end

function AllySelector:OnNewBookmarkBtn(wndHandler)
	-- Create a new bookmark node.

	local bookmark = Bookmark:New(self, self.listBookmarks:GetLength() + 1)

	-- Add the new bookmark to the list and set its data.
	self.listBookmarks:Add(bookmark)

	if DEBUG then self.listBookmarks:Print() end

	self.wndMain:FindChild("Bookmarks"):ArrangeChildrenVert()
end

-- Options Window --

function AllySelector:OnOptionsBtn()

	self.wndOptions:Invoke()
	local x, y = self.wndMain:GetPos()
	self.wndOptions:Move(
		(x + (self.wndMain:GetWidth()/2)) - self.wndOptions:GetWidth()/2,
		(y + (self.wndMain:GetHeight()/2)) - self.wndOptions:GetHeight()/2,
		self.wndOptions:GetWidth(),
		self.wndOptions:GetHeight()
	)

	-- if DEBUG then Print("Smart selection: " .. tostring(self.bUseSmartSelection)) end
	-- if DEBUG then Print("PvP filter: " .. tostring(self.bUsePvpFilter)) end
	-- if DEBUG then Print("Bolster filter: " .. tostring(self.bUseBolsterFilter)) end
	-- if DEBUG then Print("Mouse button: " .. tostring(self.bSelectOnMouseButton)) end
	-- if DEBUG then Print("Mouse enter: " .. tostring(self.bSelectOnMouseEnter)) end
end

function AllySelector:OnSmartSelectionCheck(wndHandler)
	self.bUseSmartSelection = wndHandler:IsChecked()

	-- Print status message.
	if wndHandler:IsChecked() then
		self.wndMain:FindChild("StatusMsg"):SetText("Smart selection enabled.")
	else
		self.wndMain:FindChild("StatusMsg"):SetText("Smart selection disabled.")
	end
end

function AllySelector:OnPvpFilterCheck(wndHandler)
	self.bUsePvpFilter = wndHandler:IsChecked()

	-- Print status message.
	if wndHandler:IsChecked() then
		self.wndMain:FindChild("StatusMsg"):SetText("PvP filter enabled.")
	else
		self.wndMain:FindChild("StatusMsg"):SetText("PvP filter disabled.")
	end
end

function AllySelector:OnBolsterFilterCheck(wndHandler)
	self.bUseBolsterFilter = wndHandler:IsChecked()

	-- Print status message.
	if wndHandler:IsChecked() then
		self.wndMain:FindChild("StatusMsg"):SetText("Bolster filter enabled.")
	else
		self.wndMain:FindChild("StatusMsg"):SetText("Bolster filter disabled.")
	end
end

function AllySelector:OnStickynoteMBBtn(wndHandler)
	self.bSelectOnMouseButton = wndHandler:IsChecked()
	self:ResetStickynoteSelectionMethods(1)
end

function AllySelector:OnStickynoteMEBtn(wndHandler)
	self.bSelectOnMouseEnter = wndHandler:IsChecked()
	self:ResetStickynoteSelectionMethods(1)
end

function AllySelector:ResetStickynoteSelectionMethods(index)

	if index > self.listBookmarks:GetLength() then
		return
	else
		local stickynote = self.listBookmarks:GetFromIndex(index).stickynote
		if stickynote then
			local tOptions = {
				bSelectOnMouseEnter = self.bSelectOnMouseEnter,
				bSelectOnMouseButton = self.bSelectOnMouseButton
			}
			stickynote:SetSelectionMethod(tOptions)
		end
		self:ResetStickynoteSelectionMethods(index + 1)
	end
end


--------------------------------------------------------------------------------
-- Bookmarking System
--------------------------------------------------------------------------------

-- NOTE: All of the Bookmarking system has been moved to the Bookmark class.



local AllySelectorInstance = AllySelector:New()
AllySelectorInstance:Init()

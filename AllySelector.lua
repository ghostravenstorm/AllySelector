
-- AllySelector 1.04
-- GhostRavenstorm

-- Datatype prefixes
--   n = number
--   b = boolean
--   t = table
--   str = string
--   f = function
--   unit = unit


require "Window"

-----
-- Object definition
-----

local AllySelector = {}

-- New instance of Selector
function AllySelector:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.nDefaultKey = 9
	o.nDefaultRange = 35
	o.tAlliesInRange = {}
	o.tAlliesSortedByHealth = {}
	o.nAlliesInRange = 0
	o.tUpdate = nil
	o.nSelection = 1

	o.tAlliesInRegionByName = {}
	o.tAlliesInRegionByIteration = {}
	o.nAlliesInRegion = 0

	o.tTargetBookmarks = {}
	o.nLastBookmark = nil

	return o
end

-- Constructor
function AllySelector:Init()
    Apollo.RegisterAddon(self, false, nil, nil)

    --self.tUpdate = ApolloTimer.Create(1, true, "Update", self)

    -- if GroupLib.InGroup() then
    -- 	self:StartUpdate()
    -- else
    -- 	self:StopUpdate()
    -- end
end

function AllySelector:OnLoad()

	Apollo.RegisterSlashCommand("as-setkey", "TraceKey", self)
	Apollo.RegisterSlashCommand("as-setbm", "SetBookmark", self)
	Apollo.RegisterSlashCommand("as-clear", "ClearBookmarks", self)
	Apollo.RegisterSlashCommand("as-undo", "UndoLastBookmark", self)
	--Apollo.RegisterEventHandler("Group_Join", "StartUpdate", self)
	--Apollo.RegisterEventHandler("Group_Left", "StopUpdate", self)
	--Apollo.RegisterEventHandler("Group_Updated", "GetAlliesInRange", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	self:ResetKeyDownEventHandlers()
end

function AllySelector:ResetKeyDownEventHandlers()
	Apollo.RegisterEventHandler("SystemKeyDown", "SelectAlly", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "GetBookmark", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "Debug", self)
end

function AllySelector:Debug(nKeyCode)
	if nKeyCode == 70 then
		for k, v in pairs(self.tAlliesInRegionByIteration) do
			Print(tostring(k) .. " " .. v)
		end
	end

	if nKeyCode == 71 then
		for k, v in pairs(self.tAlliesInRegionByName) do
			Print(k)
		end
	end
end



-- function AllySelector:StartUpdate()
-- 	Print("AllySelector: Update started")
-- 	self.tUpdate:Start()
-- end
--
-- function AllySelector:StopUpdate()
-- 	Print("AllySelector: Update stopped")
-- 	self.tUpdate:Stop()
-- end

-- function AllySelector:Update()
-- 	self:GetAllAlliesInRange()
-- end

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

	-- Sort units loaded into a table if they're freindly and a player.
	if unit:GetFaction() == Unit.CodeEnumFaction.ExilesPlayer and unit:GetType() == "Player" then
		if self.tAlliesInRegionByName[unit:GetName()] ~= unit then
			-- Check if name already exists.
			--Print(unit:GetName() .. " added.")
			self:AddKeyToIteration(1, unit:GetName())
			self.tAlliesInRegionByName[unit:GetName()] = unit
			self.nAlliesInRegion = self.nAlliesInRegion + 1
		end
	end

	-- Note: There seem to be a bug with the UnitCreated event where its triggering
	--       when the user selects a unit.
end

function AllySelector:OnUnitDestroyed(unit)

	-- Remove unit from table if in table.
	if self.tAlliesInRegionByName[unit:GetName()] then
		--Print(unit:GetName() .. " removed.")
		self.tAlliesInRegionByName[unit:GetName()] = nil
		self:RemoveKeyFromIteration(unit:GetName())
		self.nAlliesInRegion = self.nAlliesInRegion - 1
	end
end

function AllySelector:AddKeyToIteration(nIteration, strKey)
	-- Add the key (player name) from tAlliesInRegionByName to tAlliesInRegionByIteration
	-- to have an ordered list that can be iterated through without a pairs loop.

	if not self.tAlliesInRegionByIteration[nIteration] then
		-- Check if this index is not occupied then add the key.
		--Print("Adding " .. strKey)
		self.tAlliesInRegionByIteration[nIteration] = strKey
	else
		-- Recursively iterate to the next index until an empty one if found.
		return self:AddKeyToIteration(nIteration + 1, strKey)
	end
end

function AllySelector:RemoveKeyFromIteration(strKey)
	-- Remove the key (player name) from the tAlliesInRegionByIteration table.

	for k, v in pairs(self.tAlliesInRegionByIteration) do
		if v == strKey then
			-- Iterate until a match if found then remove it.
			--Print("Removing " .. v)
			self.tAlliesInRegionByIteration[k] = nil
			break
		end
	end
end

function AllySelector:SelectAlly(nKeycode)
	-- Main function that is excuted when tab (or some other set binding) is pressed.

	if nKeycode == self.nDefaultKey then

		-- Get lowest health ally using the first party memeber, the player, as the first comparision.
		--local uNextTarget = self:FindLowestHealthAlly(2, self.tAlliesInRange[1])
		local unitNextTarget = self:GetLowestHealthAllyInRange(2, GameLib.GetPlayerUnit())

		-- If the first party member is returned and is at 100%, meaning no other party member has
		-- lost any health, then select the next party member in order.
		if self:GetHealthPercent(unitNextTarget) == 1 then
			--uNextTarget = self.tAlliesInRange[self.nSelection]
			unitNextTarget = self:GetAllyInRange(self.nSelection)
		end

		--self:IterateSelection()

		-- Select referenced ally.
		if unitNextTarget then
			GameLib.SetTargetUnit(unitNextTarget)
		else
			Print("AllySelector: Error: Member reference is nil.")
		end
	end
end

function AllySelector:GetAllyInRange(nIndex)
	-- Recursively seek a valid party member in range.

	if not nIndex then
		Print("Index is nil.")
		Print("Selection: " .. tostring(self.nSelection))
		return 1
	end

	-- Print("Index: " .. tostring(nIndex))

	--if nIndex > GroupLib.GetMemberCount() then
	if nIndex > self.nAlliesInRegion then
		nIndex = 1
		--self.nSelection = nIndex + 1
		--Print("boops")
	else
		--self.nSelection = nIndex + 1

	end

	--Print("Selection: " .. tostring(self.nSelection))

	--local unitAlly = GroupLib.GetUnitForGroupMember(nIndex)
	local unitAlly = self.tAlliesInRegionByName[self.tAlliesInRegionByIteration[nIndex]]

	if not unitAlly then
		Print("Nil reference; Index: " .. tostring(nIndex))
		Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	elseif not self:IsAllyInRange(unitAlly) then
		Print("Not in range; Index: " .. tostring(nIndex))
		Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	-- Occlusion check to prevent selection through solid object.
	-- IsOccuded() seems buggy in the sense that its return true for some units
	-- right in front of the player.

	-- elseif unitAlly:IsOccluded() then
	-- 	Print(unitAlly:GetName() .. " is occluded: Index: " .. tostring(nIndex))
	-- 	Print("Selection: " .. tostring(self.nSelection))
	-- 	return self:GetAllyInRange(nIndex + 1)

	elseif GameLib.GetPlayerUnit():IsPvpFlagged() ~= unitAlly:IsPvpFlagged() then
		Print(unitAlly:GetName() .. " is not in the same PvP state; Index: " .. tostring(nIndex))
		Print("Selection: " .. tostring(self.nSelection))
		return self:GetAllyInRange(nIndex + 1)

	else
		Print("Selected; Index: " .. tostring(nIndex))
		Print("Selection: " .. tostring(self.nSelection))
		self.nSelection = nIndex + 1
		--return GroupLib.GetUnitForGroupMember(nIndex)
		return unitAlly
	end
end

function AllySelector:GetLowestHealthAllyInRange(nIteration, unitLowest)

	--Print("Iteration: " .. tostring(nIteration))
	--Print("Allies: " .. tostring(self.nAlliesInRegion))

	--if nIteration > GroupLib.GetMemberCount() then
	if nIteration > self.nAlliesInRegion then
		-- Break recursion and return once the last unit is reached.
		return unitLowest
	end

	--local unitNextUnit = GroupLib.GetUnitForGroupMember(nIteration)
	local unitNext = self.tAlliesInRegionByName[self.tAlliesInRegionByIteration[nIteration]]

	--Print(tostring(uNextUnit))
	if not unitNext then
		-- Iterate to next ally if current reference is nil, meaning the client
		-- doesn't have the current player loaded in scene or is too far out of range.
		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
	elseif not self:IsAllyInRange(unitNext) then
		-- If unit is not in self's defined range, iterate to the next one in group.
		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
	end

	if self:GetHealthPercent(unitLowest) > self:GetHealthPercent(unitNext) then
		-- If the first player's heath is greater than the next player's, set that player
		-- as the lowest health player and recursively compare to the next player in order.
		return self:GetLowestHealthAllyInRange(nIteration + 1, unitNext)
	else
		-- If first player's health is lower, then set this player as lowest and recursive compare next
		-- player in order.
		return self:GetLowestHealthAllyInRange(nIteration + 1, unitLowest)
	end

end

function AllySelector:IsBolsterApplied(unitAlly)
	-- Check ally reference for the Bolster buff.

	for k, v in pairs( unitAlly:GetBuffs().arBeneficial ) do
		if v.splEffect:GetName() == "Bolster" then
			return true
		end
	end
	return false
end

-- function AllySelector:FindLowestHealthAlly(nIteration, uLowest) -- Depreciated.
-- 	-- Recursively compare first player's health in party to the next player's.
--
-- 	-- Return ally and break recursion once all possibilities have been iterated through.
-- 	if nIteration > self.nAlliesInRange then
-- 		return uLowest
-- 	end
--
-- 	local uNextUnit = self.tAlliesInRange[nIteration]
--
-- 	--Print("nIteration: " .. tostring(nIteration))
-- 	-- if uLowest then
-- 	-- 	Print("uLowest: " .. uLowest:GetName())
-- 	-- else
-- 	-- 	Print("uLowest is nil")
-- 	-- end
--
-- 	-- if uNextUnit then
-- 	-- 	Print("uNextUnit: " .. uNextUnit:GetName())
-- 	-- else
-- 	-- 	Print("uNextUnit is nil")
-- 	-- end
--
-- 	-- Temporary patch to prevent crashes when uNextUnit turns up nil.
-- 	if not uNextUnit then
-- 		-- Move on to next unit if this one is nil.
-- 		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uLowest)
-- 	end
--
-- 	if self:GetHealthPercent(uLowest) > self:GetHealthPercent(uNextUnit) then
-- 		-- If the first player's heath is greater than the next player's, set that player
-- 		-- as the lowest health player and recursively compare to the next player in order.
-- 		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uNextUnit)
-- 	else
-- 		-- If first player's health is lower, then set this player as lowest and recursive compare next
-- 		-- player in order.
-- 		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uLowest)
-- 	end
-- end

-- function AllySelector:IterateSelection() -- Depreciated.
-- 	-- Interates the selection index to the next index in the table used by a player.
--
-- 	-- Set current index in table to the next index.
-- 	self.nSelection = self.nSelection + 1
--
-- 	-- Reset selection to the first party member when the last party member is reached.
-- 	if self.nSelection > GroupLib.GetMemberCount() then
-- 		self.nSelection = 1
-- 	end
--
-- 	if not self.tAlliesInRange[self.nSelection] then
-- 		-- If current index doesn't contain a player, excute this method again
-- 		self:IterateSelection()
-- 	end
--
-- end

-- function AllySelector:IterateToNextAlly(nIteration) -- Depreciated.
-- 	-- Recursively seek the next player in the reference table skipping nil values.
--
-- 	if not self.tAlliesInRange[nIteration] then
-- 		-- If table at this index doesn't contain a player, recursively iterate to next index.
-- 		return self:IterateToNextAlly(nIteration + 1)
-- 	else
-- 		-- If table at this index contains a player, return player's index.
-- 		Print("Key: " .. tostring(nIteration))
-- 		return nIteration + 1
-- 	end
-- end

function AllySelector:SortAlliesByHealth()
	-- Curently unused.

	local tAllies = {}

	for i = 1, i < GroupLib.GetMemberCount() do
		if GroupLib.GetUnitForGroupMember(i) then
			local unit = GroupLib.GetUnitForGroupMember(i)
			tAllies[self:GetHealthPercent(unit)] = unit
		end
	end

	local tSortedKeys = {}

	for k, v in pairs(tAllies) do
		table.insert(tSortedKeys, k)
	end

	table.sort(tSortedKeys)

	self.tAlliesSortedByHealth = {}

	for _, k in ipairs(tSortedKeys) do
		table.insert(self.tAlliesSortedByHealth, tAllies[k])
	end
end

-- function AllySelector:GetAlliesInRange() -- Depreciated.
-- 	-- Perodically add party members within a set distance to a reference table.
--
-- 	--Print(tostring("Allies in range: " .. self.nAlliesInRange))
--
-- 	if not GroupLib.InGroup() then
-- 		-- Break function if not in party.
--
-- 		Print("AllySelector: ERROR: No group detected.")
-- 		self:StopUpdate()
-- 		return
-- 	end
--
-- 	for i = 1, GroupLib.GetMemberCount() do
-- 		-- Iterate through all party members to determine their distance from the player.
--
-- 		local uMember = GroupLib.GetUnitForGroupMember(i);
--
-- 		if uMember then
-- 			-- Calculate the ranage of uMember only if they are present on the minimap.
--
-- 			if self:CalculateRange(uMember) <= self.nDefaultRange then
-- 				-- Add player to reference table if in range.
--
-- 				if not self.tAlliesInRange[i] then
-- 					-- Don't add the same player twice.
--
-- 					self.nAlliesInRange = self.nAlliesInRange + 1
-- 					self.tAlliesInRange[i] = uMember
-- 				end
-- 			else
-- 				-- Remove player from reference table if out of range.
--
-- 				if self.tAlliesInRange[i] then
-- 					-- Don't remove the same player twice.
--
-- 					self.nAlliesInRange = self.nAlliesInRange - 1
-- 					self.tAlliesInRange[i] = nil
-- 				end
-- 			end
-- 		else
-- 			--Print("AllySelector: Member " .. tostring(i) .. " not on minimap")
-- 		end
-- 	end
--
-- 	self:SortAlliesByHealth()
--
-- end

function AllySelector:IsAllyInRange(unitAlly)
	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
	local tAllyPos = unitAlly:GetPosition()

	local x, y, z = tPlayerPos.x - tAllyPos.x, tPlayerPos.y - tAllyPos.y, tPlayerPos.z - tAllyPos.z
	local distance = math.sqrt( (x * x) + (y * y) + (z * z) )

	if distance <= self.nDefaultRange then
		return true
	else
		return false
	end
end

-- function AllySelector:CalculateRange(uMember) -- Depreciated.
-- 	-- Calculate the distance between the player and a given party member.
--
-- 	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
-- 	local tMemberPos = uMember:GetPosition()
--
-- 	local x, y, z = tPlayerPos.x - tMemberPos.x, tPlayerPos.y - tMemberPos.y, tPlayerPos.z - tMemberPos.z
-- 	local distance = math.sqrt( (x * x) + (y * y) + (z * z) )
--
-- 	return distance
-- end

function AllySelector:GetHealthPercent(unit)
	-- Convert the health value of a given unit to a percent.

	return ((unit:GetHealth() * 100) / unit:GetMaxHealth()) / 100
end

function AllySelector:SetBookmark()
	-- Called when the slash command is invoked.

	Print("AllySelector Bookmark: Next key press will bind currently selected player to that key.")
	Apollo.RegisterEventHandler("SystemKeyDown", "OnSetBookmark", self)
end

function AllySelector:ClearBookmarks()
	-- Clears all keys with saved units.

	self.tTargetBookmarks = {}
	Print("AllySelector Bookmark: All bookmarks have been cleared.")
end

function AllySelector:UndoLastBookmark()
	-- Clears the last key that a unit was saved to.

	local unitLast = self.tTargetBookmarks[self.nLastBookmark]

	if unitLast then
		Print("AllySelector Bookmark: " .. unitLast:GetName() .. " has been removed from key " .. tostring(self.nLastBookmark))
		self.tTargetBookmarks[self.nLastBookmark] = nil
	else
		Print("AllySelector Bookmark: There is no unit on key " .. tostring(self.nLastBookmark) .. " to remove.")
	end
end

function AllySelector:OnSetBookmark(nKeycode)
	-- Called on next key press after slash command is invoked.
	-- Sets next key press as macro to selected the currently selected unit

	Apollo.RemoveEventHandler("SystemKeyDown", self)
	self:ResetKeyDownEventHandlers()

	local unitTarget = GameLib.GetPlayerUnit():GetTarget()

	if unitTarget then
		-- If there is a unit selected.

		if unitTarget:GetType() == "Player" then
			-- If unit is a player.

			self.tTargetBookmarks[nKeycode] = unitTarget
			self.nLastBookmark = nKeycode
			Print("AllySelector Bookmark: " .. unitTarget:GetName() .. " set to key " .. tostring(nKeycode))
		else
			Print("AllySelector Bookmark: No valid target selected to set bookmark.")
		end
	end
end

function AllySelector:GetBookmark(nKeycode)
	-- Called when any key is pressed.

	if self.tTargetBookmarks[nKeycode] then
		-- Check if key pressed has a unit saved to it.
		GameLib.SetTargetUnit(self.tTargetBookmarks[nKey])
	end
end

local AllySelectorInstance = AllySelector:New()
AllySelectorInstance:Init()

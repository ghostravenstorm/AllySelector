
-- AllySelector 1.03
-- GhostRavenstorm

-- Datatype prefixes
--   n = number
--   b = boolean
--   t = table
--   f = function
--   u = userdata


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
	
	return o
end

-- Constructor
function AllySelector:Init()
    Apollo.RegisterAddon(self, false, nil, nil)

    self.tUpdate = ApolloTimer.Create(1, true, "Update", self)

    if GroupLib.InGroup() then
    	self:StartUpdate()
    else
    	self:StopUpdate()
    end
end

function AllySelector:OnLoad()

	Apollo.RegisterSlashCommand("as-setkey", "TraceKey", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "SelectAlly", self)
	Apollo.RegisterEventHandler("Group_Join", "StartUpdate", self)
	Apollo.RegisterEventHandler("Group_Left", "StopUpdate", self)
end

function AllySelector:StartUpdate()
	Print("AllySelector: Update started")
	self.tUpdate:Start()
end

function AllySelector:StopUpdate()
	Print("AllySelector: Update stopped")
	self.tUpdate:Stop()
end

function AllySelector:Update()
	self:GetAllAlliesInRange()
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

function AllySelector:SelectAlly(keycode)
	if keycode == self.nDefaultKey then

		for k, v in pairs( getmetatable(GameLib.GetPlayerUnit():GetBuffs().arBeneficial[1].splEffect) ) do
			--Print(tostring(k))
			--Print(tostring(v))
		end

		--Print( GameLib.GetPlayerUnit():GetBuffs().arBeneficial[1].splEffect:GetName() )

		-- Execute only if in party.
		if not GroupLib.InGroup() then
			Print("AllySelector: No party detected.")
			return
		end

		-- Get lowest health ally using the first party memeber, the player, as the first comparision.
		local uNextTarget = self:FindLowestHealthAlly(2, self.tAlliesInRange[1])

		-- If the first party member is returned and is at 100%, meaning no other party member has
		-- lost any health, then select the next party member in order.
		if self:GetHealthPercent(uNextTarget) == 1 then
			uNextTarget = self.tAlliesInRange[self.nSelection]
		end

		self:IterateSelection()

		-- Select referenced ally.
		if uNextTarget then
			GameLib.SetTargetUnit(uNextTarget)
		else
			Print("AllySelector: No member selected.")
		end
	end
end

function AllySelector:FindLowestHealthAlly(nIteration, uLowest)
	-- Recursively compare first player's health in party to the next player's.

	-- Return ally and break recursion once all possibilities have been iterated through.
	if nIteration > self.nAlliesInRange then 
		return uLowest 
	end

	local uNextUnit = self.tAlliesInRange[nIteration]

	--Print("nIteration: " .. tostring(nIteration))
	-- if uLowest then 
	-- 	Print("uLowest: " .. uLowest:GetName())
	-- else 
	-- 	Print("uLowest is nil")
	-- end

	-- if uNextUnit then 
	-- 	Print("uNextUnit: " .. uNextUnit:GetName())
	-- else 
	-- 	Print("uNextUnit is nil")
	-- end

	-- Temporary patch to prevent crashes when uNextUnit turns up nil. 
	if not uNextUnit then
		-- Move on to next unit if this one is nil.
		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uLowest)
	end

	if self:GetHealthPercent(uLowest) > self:GetHealthPercent(uNextUnit) then
		-- If the first player's heath is greater than the next player's, set that player
		-- as the lowest health player and recursively compare to the next player in order.
		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uNextUnit)
	else
		-- If first player's health is lower, then set this player as lowest and recursive compare next
		-- player in order.
		return self:FindLowestHealthAlly(self:IterateToNextAlly(nIteration), uLowest)
	end
end

function AllySelector:IterateSelection()
	-- Interates the selection index to the next index in the table used by a player.

	-- Set current index in table to the next index.
	self.nSelection = self.nSelection + 1

	-- Reset selection to the first party member when the last party member is reached.
	if self.nSelection > GroupLib.GetMemberCount() then
		self.nSelection = 1
	end

	if not self.tAlliesInRange[self.nSelection] then
		-- If current index doesn't contain a player, excute this method again
		self:IterateSelection()
	end

end

function AllySelector:IterateToNextAlly(nIteration)
	-- Recursively seek the next player in the reference table.

	if not self.tAlliesInRange[nIteration] then
		-- If table at this index doesn't contain a player, recursively iterate to next index.
		return self:IterateToNextAlly(nIteration + 1)
	else
		-- If table at this index contains a player, return player's index.
		Print("Key: " .. tostring(nIteration))
		return nIteration + 1
	end
end

function AllySelector:SortAlliesByHealth()
	local tAllies = {}

	for k, v in pairs(self.tAlliesInRange) do
		tAllies[self:GetHealthPercent(self.tAlliesInRange[k])] = self.tAlliesInRange[k]
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

function AllySelector:GetAllAlliesInRange()
	-- Perodically add party members within a set distance to a reference table.

	--Print(tostring("Allies in range: " .. self.nAlliesInRange))

	if not GroupLib.InGroup() then
		-- Break function if not in party.

		Print("AllySelector: ERROR: No group detected.")
		self:StopUpdate()
		return
	end

	for i = 1, GroupLib.GetMemberCount() do
		-- Iterate through all party members to determine their distance from the player.

		local uMember = GroupLib.GetUnitForGroupMember(i);

		if uMember then 
			-- Calculate the ranage of uMember only if they are present on the minimap.

			if self:CalculateRange(uMember) <= self.nDefaultRange then
				-- Add player to reference table if in range.

				if not self.tAlliesInRange[i] then 
					-- Don't add the same player twice.

					self.nAlliesInRange = self.nAlliesInRange + 1
					self.tAlliesInRange[i] = uMember
				end
			else
				-- Remove player from reference table if out of range.

				if self.tAlliesInRange[i] then 
					-- Don't remove the same player twice.

					self.nAlliesInRange = self.nAlliesInRange - 1
					self.tAlliesInRange[i] = nil
				end
			end
		else
			--Print("AllySelector: Member " .. tostring(i) .. " not on minimap")
		end
	end

	self:SortAlliesByHealth()

end

function AllySelector:CalculateRange(uMember)
	-- Calculate the distance between the player and a given party member.

	local tPlayerPos = GameLib.GetPlayerUnit():GetPosition()
	local tMemberPos = uMember:GetPosition()

	local x, y, z = tPlayerPos.x - tMemberPos.x, tPlayerPos.y - tMemberPos.y, tPlayerPos.z - tMemberPos.z
	local distance = math.sqrt( (x * x) + (y * y) + (z * z) )	

	return distance
end

function AllySelector:GetHealthPercent(uUnit)
	-- Convert the health value of a given player to a percent.

	return ((uUnit:GetHealth() * 100) / uUnit:GetMaxHealth()) / 100
end

local AllySelectorInstance = AllySelector:New()
AllySelectorInstance:Init()


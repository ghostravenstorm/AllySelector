-----------------------------------
-- Program: WildstarUnitArrayList 1.0.1
-- Author: GhostRavenstorm
-- Date: 2016-12-16

-- Description: Special array list designed to help sort this collection by
-- properties in Wildstar's Unit class.
-----------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local WildstarObjectArrayList = Apollo.GetPackage("Lib:WildstarObjectArrayList").tPackage
local MAJOR, MINOR = "Lib:WildstarUnitArrayList", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local WildstarUnitArrayList = APkg and APkg.tPackage or WildstarObjectArrayList:New()

local DEBUG = false

-- New unit array list instance.
function WildstarUnitArrayList:New(o)
	o = o or WildstarObjectArrayList:New()
	setmetatable(o, self)
	self.__index = self

	return o
end

function WildstarUnitArrayList:SortByLowestHealth(nIndex, bIsSorted)
	-- Bubble sort the list by lowest health to greatest.

	nIndex = nIndex or 1

	if nIndex > self._nLength - 1 then
		-- When the second to list unit has been reached.

		if not bIsSorted then
			-- If a swap was executed during this pass, set bIsSorted to true and
			-- run another pass.
			return self:SortByLowestHealth(1, true)
		else
			-- Sorting complete.
			if DEBUG then Print("Unit list sorted.") end
			return
		end

	elseif self:_GetHealthPercent(self._tList[nIndex]) > self:_GetHealthPercent(self._tList[nIndex + 1]) then
		-- Unit at this index has higher health than the next one. Swap their positions.

		local unitLowest = self._tList[nIndex + 1]
		local unitGreatest = self._tList[nIndex]

		self._tList[nIndex] = unitLowest
		self._tList[nIndex + 1] = unitGreatest

		-- A swap was just executed, so set bIsSorted to false.
		return self:SortByLowestHealth(nIndex + 1, false)

	else
		-- No swap was executed. Check next pair of units.
		return self:SortByLowestHealth(nIndex + 1, bIsSorted)

	end
end

function WildstarUnitArrayList:_GetHealthPercent(unit)
	-- Convert the health value of a given unit to a percent.
	return ((unit:GetHealth() * 100) / unit:GetMaxHealth()) / 100
end

Apollo.RegisterPackage(WildstarUnitArrayList, MAJOR, MINOR, {})

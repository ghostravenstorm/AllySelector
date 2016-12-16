-----------------------------------
-- Program: UnitArrayList 1.0.1
-- Author: GhostRavenstorm
-- Date: 2016-12-14

-- Description: Special unit array list that inherits from ArrayList designed to
-- sort and store objects from Wildstar's Unit class.
-----------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local ArrayList = Apollo.GetPackage("Lib:ArrayList").tPackage
local MAJOR, MINOR = "Lib:UnitArrayList", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local UnitArrayList = APkg and APkg.tPackage or ArrayList:New()

-- New unit array list instance.
function UnitArrayList:New(o)
	o = o or ArrayList:New()
	setmetatable(o, self)
	self.__index = self

	--self._tList = tList or {}
	--self._nSize = nSize or 0

	return o
end

function UnitArrayList:SortByLowestHealth(nIndex, bIsSorted)
	-- Bubble sort the list by lowest health to greatest.

	nIndex = nIndex or 1

	if nIndex > self._nLength - 1 then
		-- When the end of the list has been reached.

		if not bIsSorted then
			return self:SortByLowestHealth(1, true)
		else
			-- Sorting complete.
			--Print("List sorted.")
			return
		end

	elseif self:_GetHealthPercent(self._tList[nIndex]) > self:_GetHealthPercent(self._tList[nIndex + 1]) then

		local unitLowest = self._tList[nIndex + 1]
		local unitGreatest = self._tList[nIndex]

		self._tList[nIndex] = unitLowest
		self._tList[nIndex + 1] = unitGreatest

		return self:SortByLowestHealth(nIndex + 1, false)

	else
		return self:SortByLowestHealth(nIndex + 1, bIsSorted)

	end
end

function UnitArrayList:_GetHealthPercent(unit)
	-- Convert the health value of a given unit to a percent.

	return ((unit:GetHealth() * 100) / unit:GetMaxHealth()) / 100
end

Apollo.RegisterPackage(UnitArrayList, MAJOR, MINOR, {})

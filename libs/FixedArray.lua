-----------------------------------
-- Program: FixedArray 1.0
-- Author: GhostRavenstorm
-- Date: 2016-12-15

-- Description: Simple collections class that stores values to a table in an
-- ordered manner emulating a fixed array type of data sctructure
-----------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local MAJOR, MINOR = "Lib:FixedArray", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local FixedArray = APkg and APkg.tPackage or {}

-- New array list instance.
function FixedArray:New(nFixedLength, o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	self._tList = tList or {}
	self._nLength = nFixedLength or 1

	return o
end

function FixedArray:Print(index)
	index = index or 1
	if index > self._nLength then
		return
	else
		Print(tostring(index) .. ": " .. tostring(self._tList[index]))
		return self:Print(index + 1)
	end
end

function FixedArray:Add(item)
	-- Add item to end of list.

	-- WIP
end

function FixedArray:AddToIndex(item, index)
	-- Add item to specific index.
	if index <= self._nLength then
		self._tList[index] = item
		return
	else
		-- Given index is greater than the max length.
		return
	end
end

function FixedArray:Remove(item)
	-- Remove first occurance of item from list.

	-- WIP
end

function FixedArray:RemoveFromIndex(index)
	-- Remove whatever is at a specific index.
	if index <= self._nLength then
		self._tList[index] = nil
		return
	else
		-- Given index is greater than the max length.
		return
	end
end

function FixedArray:Get(item)
	-- Return first occurance of item in the list.

	-- WIP
end

function FixedArray:GetFromIndex(index)
	-- Return whatever is at the specific index.
	if self._tList[index] then
		return self._tList[index]
	else
		-- Nothing exists at this index.
	end
end

function FixedArray:Resize(nNewLength)
	-- Give the list a new length. If sizing down, this will remove all items
	-- beyound the new max length index.

	-- WIP

end

Apollo.RegisterPackage(FixedArray, MAJOR, MINOR, {})

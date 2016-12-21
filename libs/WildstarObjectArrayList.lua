-----------------------------------
-- Program: WildstarObjectArrayList 1.0.2
-- Author: GhostRavenstorm
-- Date: 2016-12-18

-- Description: Simple collections class, specially designed for base objects in
-- Wildstar, that stores values to a table in an ordered manner emulating an
-- arraylist type of data sctructure.
-----------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local MAJOR, MINOR = "Lib:WildstarObjectArrayList", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local WildstarObjectArrayList = APkg and APkg.tPackage or {}

local DEBUG = false

-- New array list instance.
function WildstarObjectArrayList:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o._tList = tList or {}
	o._nLength = nLength or 0

	return o
end

function WildstarObjectArrayList:Print(index)

   index = index or 1

	if self._nLength == 0 then
		Print("List is empty.")
   elseif index > self._nLength then
      return
   else
      Print(tostring(index) .. ": " .. self._tList[index]:GetName() .. " " .. self._tList[index]:GetId())
      return self:Print(index + 1)
   end
end

function WildstarObjectArrayList:Add(object, index)
   -- Add non-duplicate to the end of the list.

	index = index or 1

   if not self:_IsDuplicate(object) then
   	if not self._tList[index] then
   		self._tList[index] = object
   		self._nLength = self._nLength + 1
			if DEBUG then Print("Adding " .. object:GetName() .. " " .. tostring(object:GetId())) end
   	else
   		return self:Add(object, index + 1)
   	end
   end
end

function WildstarObjectArrayList:AddToIndex(object, index)
   -- Add non-duplicate to the specified index.

   if not self._IsDuplicate(object) then
      if index > self._nLength then
         self._tList[self._nLength + 1] = object
         self._nLength = self._nLength + 1
      else
         self._tList[index] = object
      end
   end
end

function WildstarObjectArrayList:AddDuplicate(object, index)
   -- Add to list regardless of duplicates.

   index = index or 1

   if not self._tList[index] then
      self._tList[index] = object
      self._nLength = self._nLength + 1
   else
      return self:AddDuplicate(object, index + 1)
   end
end

function WildstarObjectArrayList:AddDuplicateToIndex(object, index)
   -- Add to the specified index.

   if index > self._nLength then
      self._tList[self._nLength + 1] = object
      self._nLength = self._nLength + 1
   else
      self._tList[index] = object
   end
end

-- Work in progress.
-- function ArrayList:RemoveDuplicates(o, indexOrg, indexDup)
--
--    indexOrg = indexOrg or 1
--    indexDup = indexDup or 1
--    o = o or self._tList[1]
--
--    if indexDup > self._nLength then
--       if indexOrg > self._nLength then
--          return
--       else
--          return self:RemoveDuplicates(self._tList[indexOrg + 1], indexOrg + 1, 1)
--       end
--    elseif o == self._tList[indexDup] then
--       self:Remove(nil, indexDup)
--       return self:RemoveDuplicates(o, indexOrg, indexDup + 1)
--    else
--       return self:RemoveDuplicates(o, indexOrg, indexDup + 1)
--    end
-- end

function WildstarObjectArrayList:Remove(object, index)
   -- Remove first occurance of object in the list

   index = index or 1

   if index > self._nLength then
      -- Nothing matching object was found.
      return

   elseif object:GetId() == self._tList[index]:GetId() then
		-- Match for object is found here, remove it and consense list.
		if DEBUG then Print("Removing " .. self._tList[index]:GetName() .. " " .. self._tList[index]:GetId()) end

		self._tList[index] = nil
		self:_Condense()
		self._nLength = self._nLength - 1
      return
	else
		-- Check next object.
		return self:Remove(object, index + 1)
	end
end

function WildstarObjectArrayList:RemoveLast()
   -- Remove last object in the list.

   if self._nLength ~= 0 then
      self._tList[self._nLength] = nil
      self._nLength = self._nLength - 1
      return
   else
      -- There is nothing in the list to remove.
      return
   end
end

function WildstarObjectArrayList:RemoveFromIndex(index)
   -- Remove object from the given index.

   if index <= self._nLength then
      self._tList[index] = nil
      self._Condense()
      self._nLength = self._nLength - 1
      return
   else
      -- There is nothing at this index to remove.
      return
   end
end

-- Work in progress.
-- function ArrayList:RemoveFromIndexWithoutCondensing(index)
--    -- Remove object from the given index.
--
--    if index <= self._nLength then
--       self._tList[index] = nil
--       self._nLength = self._nLength - 1
--       return
--    else
--       -- There is nothing at this index to remove.
--       return
--    end
-- end

function WildstarObjectArrayList:Get(object, index)
   -- Return first occurance of object in the list.

   index = index or 1

   if index > self._nLength then
      -- The given object doesn't exist in this list.
      return "The given object doesn't exist."
   elseif object:GetId() == self._tList[index]:GetId() then
      -- Match found at this index.
      return self._tList[index]
   else
      -- Check next object.
      return self:Get(object, index + 1)
   end
end

function WildstarObjectArrayList:GetLast()
   if self._nLength ~= 0 then
      return self._tList[self._nLength]
   else
      -- There is nothing in the list to get.
      return "List is emepty."
   end
end

function WildstarObjectArrayList:GetFromIndex(index)
   -- Return whatever is at target index in the list.

   if index > 0 and index <= self._nLength then
      return self._tList[index]
   else
      -- There is nothing at this index.
      return "Nothing at this index."
   end
end

function WildstarObjectArrayList:GetIndexOfObject(object, index)
	-- Returns the index of the first occurance of object.
	index = index or 1

   if index > self._nLength then
      -- The given object doesn't exist in this list.
      return "The given object doesn't exist."
   elseif object:GetId() == self._tList[index]:GetId() then
      -- Match found at this index.
      return index
   else
      -- Check next object.
      return self:GetIndexOfObject(object, index + 1)
   end
end

function WildstarObjectArrayList:GetLength()
   return self._nLength
end

function WildstarObjectArrayList:Purge()
   -- Erases all data from the list.

   self._tList = {}
   self._nLength = 0
end

function WildstarObjectArrayList:_IsDuplicate(object, index)
   -- Check if there is a duplicate of object.

   index = index or 1

   if index > self._nLength then
      return false
   elseif object:GetId() == self._tList[index]:GetId() then
		if DEBUG then Print("Duplicate of " .. object:GetName() .. " found at " .. tostring(index) .. ". Not adding.") end
      return true
   else
      return self:_IsDuplicate(object, index + 1)
   end
end

function WildstarObjectArrayList:_Condense(index)
	-- Move all objects down filling any nil spaces inbetween.
   -- This method must be called before the list length changes.

	index = index or 1

	if index > self._nLength then
		-- End of list has been reached.
		return
	elseif not self._tList[index] then
		-- Something is not here, get next object in list and put it here.
		self._tList[index] = self:_GetNext(index)
		return self:_Condense(index + 1)
	else
		-- Iterate to next index.
		return self:_Condense(index + 1)
	end
end

function WildstarObjectArrayList:_GetNext(index)
	-- Return and remove an object from index.

	if self._tList[index] then
		-- Something is here, return it and set this index to nil.
		local nextObject = self._tList[index]
		self._tList[index] = nil
		return nextObject
	elseif index <= self._nLength then
		-- Iterate to next index until end of list.
		return self:_GetNext(index + 1)
	end
end

Apollo.RegisterPackage(WildstarObjectArrayList, MAJOR, MINOR, {})

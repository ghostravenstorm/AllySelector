-----------------------------------
-- Program: ArrayList 1.2
-- Author: GhostRavenstorm
-- Date: 2016-12-14

-- Description: Simple collections class that stores values to a table in an
-- ordered manner emulating an arraylist type of data sctructure.
-----------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local MAJOR, MINOR = "Lib:ArrayList", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local ArrayList = APkg and APkg.tPackage or {}

-- New array list instance.
function ArrayList:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	self._tList = tList or {}
	self._nLength = nLength or 0

	return o
end

function ArrayList:Print(index)

   index = index or 1

   if index > self._nLength then
      return
   else
      Print(tostring(index) .. ": " .. tostring(self._tList[index]))
      return self:Print(index + 1)
   end
end

function ArrayList:Add(item, index)
   -- Add non-duplicate to the end of the list.

	index = index or 1

   if not self:_IsDuplicate(item) then
   	if not self._tList[index] then
   		self._tList[index] = item
   		self._nLength = self._nLength + 1
   		--Print("Adding " .. tostring(item))
   	else
   		return self:Add(item, index + 1)
   	end
   end
end

function ArrayList:AddToIndex(item, index)
   -- Add non-duplicate to the specified index.

   if not self._IsDuplicate(item) then
      if index > self._nLength then
         self._tList[self._nLength + 1] = item
         self._nLength = self._nLength + 1
      else
         self._tList[index] = item
      end
   end
end

function ArrayList:AddDuplicate(item, index)
   -- Add to list regardless of duplicates.

   index = index or 1

   if not self._tList[index] then
      self._tList[index] = item
      self._nLength = self._nLength + 1
      --Print("Adding: " .. tostring(o))
   else
      return self:AddDuplicate(item, index + 1)
   end
end

function ArrayList:AddDuplicateToIndex(item, index)
   -- Add to the specified index.

   if index > self._nLength then
      self._tList[self._nLength + 1] = item
      self._nLength = self._nLength + 1
   else
      self._tList[index] = item
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

function ArrayList:Remove(item, index)
   -- Remove first occurance of item in the list

   index = index or 1

   if index > self._nLength then
      -- Nothing matching item was found.
      return

   elseif item == self._tList[index] then
		-- Match for item is found here, remove it and consense list.
      --Print("Removing " .. tostring(item))

		self._tList[index] = nil
		self:_Condense()
		self._nLength = self._nLength - 1
      return
	else
		-- Check next item.
		return self:Remove(item, index + 1)
	end
end

function ArrayList:RemoveLast()
   -- Remove last item in the list.

   if self._nLength ~= 0 then
      self._tList[self._nLength] = nil
      self._nLength = self._nLength - 1
      return
   else
      -- There is nothing in the list to remove.
      return
   end
end

function ArrayList:RemoveFromIndex(index)
   -- Remove item from the given index.

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

-- function ArrayList:RemoveFromIndexWithoutCondensing(index)
--    -- Remove item from the given index.
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

function ArrayList:Get(item, index)
   -- Return first occurance of item in the list.

   index = index or 1

   if index > self._nLength then
      -- The given item doesn't exist in this list.
      return
   elseif item == self._tList[index] then
      -- Match found at his index.
      return self._tList[index]
   else
      -- Check next item.
      return self.ArrayList:Get(item, index + 1)
   end
end

function ArrayList:GetLast()
   if self._nLength ~= 0 then
      return self._tList[self._nLength]
   else
      -- There is nothing in the list to get.
      return
   end
end

function ArrayList:GetFromIndex(index)
   -- Return whatever is at target index in the list.

   if index > 0 and index <= self._nLength then
      return self._tList[index]
   else
      -- There is nothing at this index.
      return
   end
end

function ArrayList:GetLength()
   return self._nLength
end

function ArrayList:Purge()
   -- Erases all data from the list.

   self._tList = {}
   self._nLength = 0
end

function ArrayList:_IsDuplicate(item, index)
   -- Check if there is a duplicate of item.

   index = index or 1

   if index > self._nLength then
      return false
   elseif item == self._tList[index] then
      --Print(tostirng(o) .. " already exists in this list.")
      return true
   else
      return self:_IsDuplicate(item, index + 1)
   end
end

function ArrayList:_Condense(index)
	-- Move all items down filling any nil spaces inbetween.
   -- This method must be called before the list length changes.

	index = index or 1

	if index > self._nLength then
		-- End of list has been reached.
		return
	elseif not self._tList[index] then
		-- Something is not here, get next item in list and put it here.
		self._tList[index] = self:_GetNext(index)
		return self:_Condense(index + 1)
	else
		-- Iterate to next index.
		return self:_Condense(index + 1)
	end
end

function ArrayList:_GetNext(index)
	-- Get next element in order.

	if self._tList[index] then
		-- Something is here, return it and set this index to nil.
		local nextItem = self._tList[index]
		self._tList[index] = nil
		return nextItem
	elseif index <= self._nLength then
		-- Iterate to next index until end of list.
		return self:_GetNext(index + 1)
	end
end

Apollo.RegisterPackage(ArrayList, MAJOR, MINOR, {})

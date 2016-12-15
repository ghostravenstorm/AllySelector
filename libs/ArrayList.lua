-----------------------------------
-- Program: ArrayList 1.1
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
	self._nSize = nSize or 0

	return o
end

function ArrayList:Print(index)

   index = index or 1

   if index > self._nSize then
      return
   else
      Print(tostring(index) .. ": " .. tostring(self._tList[index]))
      return self:Print(index + 1)
   end
end

function ArrayList:Add(o, index)
   -- Add non-duplicate to the list.

	index = index or 1

   if not self:_IsDuplicate(o) then
   	if not self._tList[index] then
   		self._tList[index] = o
   		self._nSize = self._nSize + 1
   		--Print("Adding: " .. tostring(o))
   	else
   		return self:Add(o, index + 1)
   	end
   end
end

function ArrayList:AddDuplicate(o, index)
   -- Add to list regardless of duplicates.

   index = index or 1

   if not self._tList[index] then
      self._tList[index] = o
      self._nSize = self._nSize + 1
      --Print("Adding: " .. tostring(o))
   else
      return self:Add(o, index + 1)
   end
end

-- Work in progress.
-- function ArrayList:RemoveDuplicates(o, indexOrg, indexDup)
--
--    indexOrg = indexOrg or 1
--    indexDup = indexDup or 1
--    o = o or self._tList[1]
--
--    if indexDup > self._nSize then
--       if indexOrg > self._nSize then
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

function ArrayList:Remove(o, targetIndex, index)

	if targetIndex then
		-- Remove whatever is at given index.
		if self._tList[targetIndex] then
			--Print("Removing: " .. tostring(self._tList[targetIndex]))
			self._tList[targetIndex] = nil
			self:_Condense()
			self._nSize = self._nSize - 1
		end
	elseif o then
		-- Remove first occurance of o
		index = index or 1
		if o == self._tList[index] then
			-- Match for o is found here, remove it and consense list.
         --Print("Removing: " .. tostring(o))
			self._tList[index] = nil
			self:_Condense()
			self._nSize = self._nSize - 1
		elseif index <= self._nSize then
			-- Iterate to next index until end of list.
			return self:Remove(o, nil, index + 1)
		end
	else
		-- Remove last item in list when called with 0 parameters.
		--print("Removing: " .. tostring(self._tList[self._nSize]))
      if self._nSize == 0 then
         return
      else
         --Print("Removing: " .. tostring(self._tList[self._nSize]))
         self._tList[self._nSize] = nil
         self._nSize = self._nSize - 1
      end
	end
end

function ArrayList:Get(o, index)
   -- Return first occurance of o in the list or last item in the list
   -- when called with 0 parameters.
   index = index or 1

   if index > self._nSize then
      return 1
   elseif not o then
      return self._tList[self._nSize]
   elseif o == self._tList[index] then
      return self._tList[index]
   else
      return self.ArrayList:Get(o, index + 1)
   end
end

function ArrayList:GetAtIndex(targetIndex)
   -- Return whatever is at target index in the list.
   if targetIndex <= self._nSize and targetIndex > 0 then
      return self._tList[targetIndex]
   else
      --return "Index is greater than list size."
      return
   end
end

function ArrayList:GetSize()
   return self._nSize
end

function ArrayList:Purge()
   -- Erases all data from the list.

   self._tList = {}
   self._nSize = 0
end

function ArrayList:_IsDuplicate(o, index)
   -- Check if there is a duplicated of o.

   index = index or 1

   if index > self._nSize then
      return false
   elseif o == self._tList[index] then
      --Print(tostirng(o) .. " already exists in this list.")
      return true
   else
      return self:_IsDuplicate(o, index + 1)
   end
end

function ArrayList:_Condense(index)
	-- Move all items down filling any nil spaces inbetween.

	index = index or 1

	if index > self._nSize then
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
	elseif index <= self._nSize then
		-- Iterate to next index until end of list.
		return self:_GetNext(index + 1)
	end
end

Apollo.RegisterPackage(ArrayList, MAJOR, MINOR, {})

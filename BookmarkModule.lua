--------------------------------------------------------------------------------
-- Program: BookmarkModule 1.0.0
-- Author: GhostRavenstorm
-- Date: 2016-12-25

-- Description: Part of the AllySelector addon that contains class data for
-- bookmark nodes.
--------------------------------------------------------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local MAJOR, MINOR = "Mod:Bookmark", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local Bookmark = APkg and APkg.tPackage or {}

local Stickynote = Apollo.GetPackage("Mod:Stickynote").tPackage

local DEBUG = false

function Bookmark:New(luaHandler, nIndex, unit, nKeybind, bHasStickynote, o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   o.unit = nil
   o.nIndex = nil
   o.nKeybind = nil
   o.stickynote = nil

   o.luaHandler = luaHandler

   o.wndMain = Apollo.LoadForm(luaHandler.xmlDoc, "BookmarkModule", luaHandler.wndMain:FindChild("Bookmarks"), o)

   o.wndMain:FindChild("SetBtn"):AddEventHandler("ButtonSignal", "OnSetButton")
   o.wndMain:FindChild("ClearBtn"):AddEventHandler("ButtonSignal", "ClearUnitReference")
   o.wndMain:FindChild("KeybindBtn"):AddEventHandler("ButtonSignal", "OnKeybindButton")
   o.wndMain:FindChild("ProjectToStickyBtn"):AddEventHandler("ButtonSignal", "OnStickynoteButton")
   o.wndMain:FindChild("DeleteBtn"):AddEventHandler("ButtonSignal", "Destroy")

   o.wndMain:FindChild("NumberSocket"):SetText(nIndex)

   if unit then
      o:SetUnitReference(unit)
   end

   if nIndex then
      o:SetIndex(nIndex)
   end

   if nKeybind then
      o:SetKeybind(nKeybind)
   end

   if bHasStickynote then
      -- TODO: Construct sticknote.
   end

   o:_PrintSysMsg("Bookmark node " .. tostring(o.wndMain:GetId()) .. " created.")

   return o
end

-- Moved to constructor.
-- function Bookmark:Init(nIndex, unit, nKeybind, bHasStickynote)
--    self.nIndex = nIndex
--    self.wndMain:FindChild("NumberSocket"):SetText(nIndex)
--
--    if unit then
--       self:SetUnitReference(unit)
--    end
--
--    if nKeybind then
--       self:SetKeybind(nKeybind)
--    else
--       self.wndMain:FindChild("KeybindBtn"):SetText("No Keybind")
--    end
--
--    if bHasStickynote then
--       -- TODO: Construct stickynote.
--    end
-- end

function Bookmark:SetIndex(nIndex)
   self.nIndex = nIndex
   self.wndMain:FindChild("NumberSocket"):SetText(tostring(nIndex))
end

-- Set the player's target as the reference unit for this bookmark.
function Bookmark:SetUnitReference(unit)

   local unit = unit or GameLib.GetPlayerUnit():GetTarget()
   if unit then
      if unit:GetType() == "Player" then
         if self:_IsSameFacOrGroup(unit) then
            -- Check if unit is there, is a player, and is same faction or in group.

            self.unit = unit

            -- Set player name to this bookmark
            self.wndMain:FindChild("Name"):SetText(unit:GetName())

            -- Remake stickynote for unit refernce if one exists for this bookmark.
            if self.stickynote then
               self.stickynote:Destroy()
               -- TODO: Call stickynote constructor.
               self.stickynote = self:ConstructStickynote()
            end

            self:_PrintSysMsg("Bookmark " .. tostring(self.nIndex) .. " set to " .. unit:GetName() .. ".")
         else
            self:_PrintSysMsg("Error: " .. unit:GetName() .. " is not same faction or in group.")
         end
      else
         self:_PrintSysMsg("Error: " .. unit:GetName() .. " is not a player.")
      end
   else
      self:_PrintSysMsg("Error: No valid unit selected to set bookmark " .. tostring(self.nIndex) .. ".")
   end
end


-- TODO: Destroy stickynote.
-- Clear the unit reference from this bookmark.
function Bookmark:ClearUnitReference()

   self.unit = nil
   self:ClearKeybind()
   if self.stickynote then self.stickynote:Destroy() end
   self.stickynote = nil

   self.wndMain:FindChild("Name"):SetText("")

   self:_PrintSysMsg("Bookmark " .. tostring(self.nIndex) .. " cleared.")
end

-- Key event that selects the unit assigned to this bookmark.
function Bookmark:OnKeybindPressed(nKeycode)
   if nKeycode == self.nKeybind then
      -- Check if this bookmark has a unit.
      if self.unit then
         -- Check if unit is valid
         if self.unit:IsValid() then
            GameLib.SetTargetUnit(self.unit)
         else
            local strName = self.wndMain:FindChild("Name"):GetText()
            self:_PrintSysMsg("Error: Cannot select " .. strName .. ". They're too far out of range.")
         end
      else
         self:_PrintSysMsg("Error: Nothing is assigned to bookmark " .. tostring(self.nIndex) .. ".")
      end
   end
end

function Bookmark:SetKeybind(nKeycode)

   if nKeycode then
      -- Set keybind to given keycode from event handler or manual call.
      self.nKeybind = nKeycode
      self.wndMain:FindChild("KeybindBtn"):SetText(enumKeys[nKeycode])

      Apollo.RemoveEventHandler("SystemKeyDown", self)
      Apollo.RegisterEventHandler("SystemKeyDown", "OnKeybindPressed", self)

      if self.unit then
         self:_PrintSysMsg("Keybind for " .. self.unit:GetName() .. " set to " .. tostring(enumKeys[nKeycode]) .. ".")
      else
         self:_PrintSysMsg("Keybind for Bookmark " .. tostring(self.nIndex) .. " set to " .. tostring(enumKeys[nKeycode]) .. ".")
      end
   else
      -- Set event handler to get next key pressed if no keycode is given.
      Apollo.RegisterEventHandler("SystemKeyDown", "SetKeybind", self)
      if self.unit then
         self:_PrintSysMsg("Press any key to set a keybind for " .. self.unit:GetName() .. ".")
      else
         self:_PrintSysMsg("Press any key to set a keybind for Bookmark " .. tostring(self.nIndex) .. ".")
      end
   end
end

function Bookmark:ClearKeybind()
   self.nKeybind = nil
   self.wndMain:FindChild("KeybindBtn"):SetText("No Keybind")
   Apollo.RemoveEventHandler("SystemKeyDown", self)
end

-- TODO: Re-optimize Stickynote class.
function Bookmark:ConstructStickynote()
   local tOptions = {
      bSelectOnMouseEnter = self.luaHandler.bSelectOnMouseEnter,
      bSelectOnMouseButton = self.luaHandler.bSelectOnMouseButton
   }
   return Stickynote:New(self, tOptions, self.luaHandler.xmlDoc)
end

function Bookmark:Destroy()
   self:ClearUnitReference()

   -- if self.stickynote then self.stickynote:Destroy() end
   -- self.stickynote = nil

   self:_PrintSysMsg("Bookmark node " .. tostring(self.wndMain:GetId()) .. " destroyed.")

   self.wndMain:Destroy()
   self.luaHandler:OnBookmarkDestroyed(self)
end

--------------------------------------------------------------------------------
-- GUI Events
--------------------------------------------------------------------------------

-- Event handler for set button.
function Bookmark:OnSetButton()
   self:SetUnitReference()
end

-- Event handler for keybind button.
function Bookmark:OnKeybindButton()
   self:SetKeybind()
end

-- Event handler for sticknote button.
function Bookmark:OnStickynoteButton()
   if self.unit then
      if self.unit:IsValid() then
         self.stickynote = self:ConstructStickynote()
      else
         self:_PrintSysMsg("Error: " .. self.unit:GetName() .. " is too far out of range to make a stickynote.")
      end
   else
      self:_PrintSysMsg("Error: There is nothing assigned to bookmark " .. tostring(self.nIndex) .. " to make a stickynote from.")
   end
end

--------------------------------------------------------------------------------
-- Private Methods
--------------------------------------------------------------------------------

function Bookmark:_IsSameFacOrGroup(unit)

	if unit:GetFaction() == GameLib.GetPlayerUnit():GetFaction() then
		return true
	elseif unit:IsInYourGroup() then
		return true
	else
		return false
	end
end

function Bookmark:_PrintSysMsg(strMsg)
   self.luaHandler.wndMain:FindChild("StatusMsg"):SetText(strMsg)
end


Apollo.RegisterPackage(Bookmark, MAJOR, MINOR, {})

--------------------------------------------------------------------------------
-- Program: StickynoteModule 1.0.0
-- Author: GhostRavenstorm
-- Date: 2016-12-22

-- Description: Part of the AllySelector addon that contains class data for the
-- bookmark sticky notes.
--------------------------------------------------------------------------------

-- Boilerplate packaging code for Apollo API in Wildstar.
local MAJOR, MINOR = "Mod:Stickynote", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local Stickynote = APkg and APkg.tPackage or {}

local DEBUG = true

-- TODO: Re-optimize for Bookmark format. Remove the need for window control data.
--

function Stickynote:New(luaHandler, tOptions, xmlDoc, o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   --o.selectionOptions = selectionOptions
   --o.bookmarkData = bookmarkData

   o.luaHandler = luaHandler

   o.wndMain = Apollo.LoadForm(xmlDoc, "StickynoteWindow", nil, o)
   --Print(tostring(o.wndMain))
   o.wndMain:Show(true, true)
   --o.wndMain:SetData(bookmarkData)

   if tOptions.bSelectOnMouseButton then
      o.wndMain:FindChild("TargetFrame"):AddEventHandler("MouseButtonDown", "SelectBookmark")
   elseif tOptions.bSelectOnMouseEnter then
      o.wndMain:FindChild("TargetFrame"):AddEventHandler("MouseEnter", "SelectBookmark")
   end

   --o.wndMain:FindChild("NameText"):SetText(bookmarkData.unit:GetName())
   o.wndMain:FindChild("NameText"):SetText(luaHandler.unit:GetName())
   --o.wndMain:FindChild("CostumeWindow"):SetCostume(bookmarkData.unit)
   o.wndMain:FindChild("CostumeWindow"):SetCostume(luaHandler.unit)
   o.wndMain:FindChild("CloseBtn"):AddEventHandler("ButtonSignal", "OnCloseBtn")
   o.wndMain:FindChild("LockBtn"):AddEventHandler("ButtonCheck", "OnLockBtn")
   o.wndMain:FindChild("LockBtn"):AddEventHandler("ButtonUncheck", "OnLockBtn")
   o.wndMain:FindChild("Healthbar"):SetFloor(0)
   --o.wndMain:FindChild("Healthbar"):SetMax(bookmarkData.unit:GetMaxHealth())
   o.wndMain:FindChild("Healthbar"):SetMax(luaHandler.unit:GetMaxHealth())

   -- TODO: Convert to screen percent.
   local left = Apollo.GetDisplaySize().nWidth - 500
   local top = 100 * luaHandler.nIndex
   o.wndMain:Move(left, top, o.wndMain:GetWidth(), o.wndMain:GetHeight())

   --o.wndMain:FindChild("Healthbar"):SetProgress(bookmarkData.unit:GetHealth())
   o.wndMain:FindChild("Healthbar"):SetProgress(luaHandler.unit:GetHealth())

   o.timerUpdate = ApolloTimer.Create(0.5, true, "Update", o)
   o.timerUpdate:Start()

   return o
end


function Stickynote:Update()
   local healthbar = self.wndMain:FindChild("Healthbar")
   --healthbar:SetProgress(self.wndMain:GetData().unit:GetHealth())
   if self.luaHandler.unit:IsValid() then
      healthbar:SetProgress(luaHandler.unit:GetHealth())
   end
end

function Stickynote:SetSelectionMethod(tOptions)
   if DEBUG then Print("Setting selection method.") end
   self.wndMain:FindChild("TargetFrame"):RemoveEventHandler("MouseButtonDown", self)
   self.wndMain:FindChild("TargetFrame"):RemoveEventHandler("MouseEnter", self)

   if tOptions.bSelectOnMouseButton then
      self.wndMain:FindChild("TargetFrame"):AddEventHandler("MouseButtonDown", "SelectBookmark")
   elseif tOptions.bSelectOnMouseEnter then
      self.wndMain:FindChild("TargetFrame"):AddEventHandler("MouseEnter", "SelectBookmark")
   end
end

function Stickynote:Destroy()
   --self.bookmarkData.stickynote = nil
   self.luaHandler.stickynote = nil
   self.timerUpdate:Stop()
   self.wndMain:Close()
   self.wndMain:Destroy()
end

--------------------------------------------------------------------------------
-- GUI Event Handlers
--------------------------------------------------------------------------------

function Stickynote:SelectBookmark()
   --GameLib.SetTargetUnit(self.wndMain:GetData().unit)
   GameLib.SetTargetUnit(self.luaHandler.unit)
end

function Stickynote:OnLockBtn(wndHandler)
   self.wndMain:SetStyle("Moveable", not wndHandler:IsChecked())
end

function Stickynote:OnCloseBtn()
   self:Destroy()
end



Apollo.RegisterPackage(Stickynote, MAJOR, MINOR, {})

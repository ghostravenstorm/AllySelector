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

local DEBUG = false

function Stickynote:New(bookmarkData, tOptions, xmlDoc, o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   o.selectionOptions = selectionOptions
   o.bookmarkData = bookmarkData

   o.wndStickynote = Apollo.LoadForm(xmlDoc, "StickynoteWindow", nil, o)
   --Print(tostring(o.wndStickynote))
   o.wndStickynote:Show(true, true)
   o.wndStickynote:SetData(bookmarkData)

   if tOptions.bSelectOnMouseButton then
      o.wndStickynote:FindChild("TargetFrame"):AddEventHandler("MouseButtonDown", "SelectBookmark")
   elseif tOptions.bSelectOnMouseEnter then
      o.wndStickynote:FindChild("TargetFrame"):AddEventHandler("MouseEnter", "SelectBookmark")
   end

   o.wndStickynote:FindChild("NameText"):SetText(bookmarkData.unit:GetName())
   o.wndStickynote:FindChild("CostumeWindow"):SetCostume(bookmarkData.unit)
   o.wndStickynote:FindChild("CloseBtn"):AddEventHandler("ButtonSignal", "OnCloseBtn")
   o.wndStickynote:FindChild("LockBtn"):AddEventHandler("ButtonCheck", "OnLockBtn")
   o.wndStickynote:FindChild("LockBtn"):AddEventHandler("ButtonUncheck", "OnLockBtn")
   o.wndStickynote:FindChild("Healthbar"):SetFloor(0)
   o.wndStickynote:FindChild("Healthbar"):SetMax(bookmarkData.unit:GetMaxHealth())

   local left = Apollo.GetDisplaySize().nWidth - 500
   o.wndStickynote:Move(left, 100, o.wndStickynote:GetWidth(), o.wndStickynote:GetHeight())

   -- Parameter testing.
   o.wndStickynote:FindChild("Healthbar"):SetProgress(bookmarkData.unit:GetHealth())

   o.timerUpdate = ApolloTimer.Create(0.5, true, "Update", o)
   o.timerUpdate:Start()

   return o
end

--------------------------------------------------------------------------------
-- GUI Event Handlers
--------------------------------------------------------------------------------

function Stickynote:Update()
   local healthbar = self.wndStickynote:FindChild("Healthbar")
   healthbar:SetProgress(self.wndStickynote:GetData().unit:GetHealth())
end

function Stickynote:SetSelectionMethod(tOptions)
   if DEBUG then Print("Setting selection method.") end
   self.wndStickynote:FindChild("TargetFrame"):RemoveEventHandler("MouseButtonDown", self)
   self.wndStickynote:FindChild("TargetFrame"):RemoveEventHandler("MouseEnter", self)

   if tOptions.bSelectOnMouseButton then
      self.wndStickynote:FindChild("TargetFrame"):AddEventHandler("MouseButtonDown", "SelectBookmark")
   elseif tOptions.bSelectOnMouseEnter then
      self.wndStickynote:FindChild("TargetFrame"):AddEventHandler("MouseEnter", "SelectBookmark")
   end
end

function Stickynote:SelectBookmark()
   GameLib.SetTargetUnit(self.wndStickynote:GetData().unit)
end

function Stickynote:OnLockBtn(wndHandler)
   wndHandler:GetParent():SetStyle("Moveable", not wndHandler:IsChecked())
end

function Stickynote:OnCloseBtn()
   self:Kill()
end

function Stickynote:Kill()
   self.bookmarkData.stickynote = nil
   self.timerUpdate:Stop()
   self.wndStickynote:Close()
   self.wndStickynote:Destroy()
end

Apollo.RegisterPackage(Stickynote, MAJOR, MINOR, {})

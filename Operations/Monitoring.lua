
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)






-- handle item memory
local function RememberItem(slot, id)
  if not Addon:GetOption("items", slot, id, "seen") then
    Addon:SetOption(true, "items", slot, id, "seen")
    if Addon:GetOption("defaultItemSettings", "ignored") then
      Addon:SetOption(Addon:GetOption("defaultItemSettings", "ignored"), "items", slot, id, "ignored")
      Addon:SetOption(Addon:IsShown(slot), "items", slot, id, "visible")
    else
      if Addon:GetOption("defaultItemSettings", "forceVisibility") then
        Addon:SetOption(Addon:GetOption("defaultItemSettings", slot), "items", slot, id, "visible")
      else
        Addon:SetOption(Addon:IsShown(slot), "items", slot, id, "visible")
      end
      Addon.ItemCache(id):OnCache(function(item)
        Addon:Printf("%s %s: %s", L["Remembering"], item:GetLink(), Addon:IsShown(slot) and L["Shown"] or L["Hidden"])
      end)
    end
  end
end


-- handle equipment changes
local function OnEquipmentChanged(self, event, slot, isEmpty)
  self:RefreshConfig()
  if not self:GetOption"enabled" then return end
  self:Assert(slot)
  if isEmpty then return end
  if not self.invSlotNames[slot] then return end
  
  local id = self:GetEquippedItemID(slot)
  if id then
    if not self:GetOption("items", slot, id, "ignored") then
      RememberItem(slot, id)
      local visibility = self:GetOption("items", slot, id, "visible")
      if Addon:IsShown(slot) ~= visibility then
        Addon:ShowSlot(slot, visibility)
      end
    end
  end
end

Addon:RegisterAddonEventCallback("ENABLE", function(self)
  self:RegisterEventCallback("PLAYER_EQUIPMENT_CHANGED", OnEquipmentChanged)
  for slot in pairs(self.invSlotNames) do
    local id = self:GetEquippedItemID(slot)
    self:FireEvent("PLAYER_EQUIPMENT_CHANGED", slot, not id)
  end
end)


-- handle item visibility changes
Addon:RegisterAddonEventCallback("ON_EQUIPMENT_SHOWN", function(self, event, slot, isShown, ...)
  self:RefreshConfig()
  if not self:GetOption"enabled" then return end
  local id = self:GetEquippedItemID(slot)
  if id then
    self:SetOption(true, "items", slot, id, "seen")
    if not self:GetOption("items", slot, id, "ignored") then
      self:SetOption(isShown, "items", slot, id, "visible")
      self.ItemCache(id):OnCache(function(item)
        self:Printf("%s %s: %s", L["Remembering"], item:GetLink(), isShown and L["Shown"] or L["Hidden"])
      end)
    end
  end
end)

Addon:RegisterAddonEventCallback("ENABLE", function(self)
  self:SecureHook(nil, "ShowHelm",  function(...) self:FireAddonEvent("ON_EQUIPMENT_SHOWN", self.invSlots.HEAD, ...) end)
  self:SecureHook(nil, "ShowCloak", function(...) self:FireAddonEvent("ON_EQUIPMENT_SHOWN", self.invSlots.BACK, ...) end)
end)







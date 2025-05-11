
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
_G.Hatter = Addon



Addon.ItemCache = LibStub"ItemCache"





do
  Addon.invSlots     = {}
  Addon.invSlotNames = {}
  
  
  
  for name, slot in pairs{
    HEAD = INVSLOT_HEAD,
    BACK = INVSLOT_BACK,
  } do
    Addon.invSlots[name]     = slot
    Addon.invSlotNames[slot] = name
  end
end



function Addon:IsShown(slot)
  if slot == Addon.invSlots.HEAD then
    return ShowingHelm()
  elseif slot == Addon.invSlots.BACK then
    return ShowingCloak()
  end
end

function Addon:ShowSlot(slot, visibility)
  self:SuspendAddonEventWhile("ON_EQUIPMENT_SHOWN", function()
    if slot == Addon.invSlots.HEAD then
      return ShowHelm(visibility)
    elseif slot == Addon.invSlots.BACK then
      return ShowCloak(visibility)
    end
  end)
end


function Addon:GetEquippedItemID(slot)
  local currentEquippedItem = GetInventoryItemLink("player", slot)
  if currentEquippedItem then
    return self.ItemCache(currentEquippedItem):GetID()
  end
end



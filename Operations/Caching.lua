
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)




-- cache all existing db items
Addon:RegisterAddonEventCallback("ENABLE", function(self)
  local ItemCache = Addon.ItemCache
  local items = {}
  
  for slot in pairs(Addon.invSlotNames) do
    for id in pairs(self:GetOptionQuiet("items", slot)) do
      local item = ItemCache(id)
      if item:Exists() and not item:IsCached() then
        items[#items+1] = item
      end
    end
  end
  
  ItemCache:OnCache(items, function() self:RefreshConfig() end)
end)












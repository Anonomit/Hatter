
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)






function Addon:MakeDefaultOptions()
  local default = {
    profile = {
      
      enabled = true,
      
      items = {
        [Addon.invSlots.HEAD] = {
          ["*"] = {
            seen    = false,
            visible = false,
            ignored = false,
          },
        },
        [Addon.invSlots.BACK] = {
          ["*"] = {
            seen    = false,
            visible = false,
            ignored = false,
          },
        },
      },
      
      defaultItemSettings = {
        ignored = false,
        
        forceVisibility       = true,
        [Addon.invSlots.HEAD] = true,
        [Addon.invSlots.BACK] = true,
      },
    },
    
    global = {
      
      -- Debug options
      debug = false,
      
      debugShowLuaErrors   = true,
      debugShowLuaWarnings = true,
        
      debugOutput = {
        ["*"] = false,
      },
    },
  }
  return default
end

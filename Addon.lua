
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)




local strGmatch = string.gmatch

local tinsert   = table.insert
local tblRemove = table.remove
local tblConcat = table.concat




local dbInitFuncs

do
  local self = Addon
  
  local shared = {}
  
  dbInitFuncs = {
    global = {},
    profile = {
      FirstRun = nil,
      
      upgrades = {
        ["2.0.0"] = function()
          local profile = self:GetOptionQuiet()
          
          local visible           = {}
          local ignored           = {}
          local defaultVisibility = {}
          for slot, slotName in pairs(self.invSlotNames) do
            for itemID, visible in pairs(self:CheckTable(profile, slot) or {}) do
              self:SetOption(true,    "items", slot, itemID, "seen")
              self:SetOption(visible, "items", slot, itemID, "visible")
            end
            
            self:SetOption(self:CheckTable(profile, "DefaultVisibility", slot) == nil, "defaultItemSettings", slot)
            
            profile[slot] = nil
          end
          
          self:SetOption(self:CheckTable(profile, "DefaultVisibility", "EnforceDefault") == nil, "defaultItemSettings", "forceVisibility")
          
          profile.DefaultVisibility = nil
        end,
      },
      
      AlwaysRun = function() end,
    },
  }
end



function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({},                          self:MakeDefaultOptions(), true)
  
  self:FireAddonEvent"INITIALIZE"
end

function Addon:OnEnable()
  self.version = self.SemVer(C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB(dbInitFuncs)
  self:GetDB().RegisterCallback(self, "OnProfileChanged",   function() self:OnProfileChanged() end)
  self:GetDB().RegisterCallback(self, "OnProfileCopied",    function() self:OnProfileChanged() end)
  self:GetDB().RegisterCallback(self, "OnProfileReset",     function() self:OnProfileChanged() end)
  self:GetDB().RegisterCallback(self, "OnDatabaseShutdown", function() self:ShutdownDB()       end)
  
  self:InitChatCommands("hatter", "hat", ADDON_NAME:lower())
  
  self:FireAddonEvent"ENABLE"
end

function Addon:OnDisable()
end





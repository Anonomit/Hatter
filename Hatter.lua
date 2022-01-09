

local ADDON_NAME, Data = ...

Hatter = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local AceConfig         = LibStub"AceConfig-3.0"
local AceConfigDialog   = LibStub"AceConfigDialog-3.0"
local AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
local AceDB             = LibStub"AceDB-3.0"
local AceDBOptions      = LibStub"AceDBOptions-3.0"


local ENABLED = true


function Hatter:Toggle()
  ENABLED = not ENABLED
end


function Hatter:IsHidable(slot)
  return Data.HIDABLE_SLOTS[slot] or false
end


function Hatter:GetDB()
  return self.db.profile
end


function Hatter:GetEnforceDefault()
  return self:GetDB().DefaultVisibility.EnforceDefault
end
function Hatter:SetEnforceDefault(state)
  self:GetDB().DefaultVisibility.EnforceDefault = state
end
function Hatter:GetDefaultVisibility(slot)
  return self:GetDB().DefaultVisibility[slot]
end
function Hatter:SetDefaultVisibility(slot, visibility)
  self:GetDB().DefaultVisibility[slot] = visibility
end
function Hatter:GetVisibility(slot, id)
  return self:GetDB()[slot][id]
end
function Hatter:SetVisibility(slot, id, visibility)
  if visibility == nil then
    return self:ForgetVisibility(slot, id)
  end
  local oldVisibility = self:GetVisibility(slot, id)
  self:GetDB()[slot][id] = visibility
  if oldVisibility ~= visibility then
    local function output()
      local name, link = GetItemInfo(id)
      if not link then
        C_Timer.After(0.1, output)
        return
      end
      self:Printf("%s %s: %s", L["Remembering"], link, visibility and L["Shown"] or L["Hidden"])
    end
    output()
  end
end
function Hatter:ForgetVisibility(slot, id)
  self:GetDB()[slot][id] = visibility
  local function output()
    local name, link = GetItemInfo(id)
    if not link then
      C_Timer.After(0.1, output)
      return
    end
    self:Printf("%s %s", L["Forgotten"], link)
  end
  output()
end
function Hatter:ForgetAllVisibility(slot)
  for id in pairs(self:GetDB()[slot]) do
    self:ForgetVisibility(slot, id)
  end
end

function Hatter:SetVisibilityDefault(slot, id)
  if self:GetVisibility(slot, id) == nil then
    if self:GetEnforceDefault() then
      self:SetVisibility(slot, id, self:GetDefaultVisibility(slot))
    else
      self:SetVisibility(slot, id, self:IsShown(slot))
    end
  end
end

function Hatter:IsShown(slot)
  if slot == Data.HEAD then
    return ShowingHelm()
  elseif slot == Data.BACK then
    return ShowingCloak()
  end
end

function Hatter:ShowSlot(slot, visibility)
  if slot == Data.HEAD then
    return self.ShowHelm(visibility)
  elseif slot == Data.BACK then
    return self.ShowCloak(visibility)
  end
end

function Hatter:GetItemId(slot)
  return GetInventoryItemID("player", slot)
end
function Hatter:GetItemLink(slot)
  return GetInventoryItemLink("player", slot)
end


function Hatter:SetShown(slot, visibility)
  if self:IsShown(slot) ~= visibility then
    self:ShowSlot(slot, visibility)
  end
end




function Hatter:OnEquipmentChanged(event, slot, isEmpty)
  if not self:IsHidable(slot) then return end
  if isEmpty then return end
  
  local itemId = self:GetItemId(slot)
  if itemId and self:GetItemLink(slot) then
    self:SetVisibilityDefault(slot, itemId)
    self:SetShown(slot, self:GetVisibility(slot, itemId))
  end
end


function Hatter:OnShown(slot, isShown)
  local itemId = self:GetItemId(slot)
  if itemId and self:GetItemLink(slot) then
    self:SetVisibility(slot, itemId, isShown)
  end
end





function Hatter:PrintUsage()
  self:Printf(L["Usage:"])
  self:Printf("  /hatter config")
  self:Printf("    %s", L["Open options"])
  self:Printf("  /hatter list")
  self:Printf("    %s", L["List items"])
  self:Printf("  /hatter forget [%s]", L["ItemLink"])
  self:Printf("    %s", L["Forget an item"])
end

function Hatter:OpenConfig(category)
  InterfaceAddOnsList_Update()
  InterfaceOptionsFrame_OpenToCategory(category)
end

function Hatter:ListItems(slot, noHeader)
  local items = {visible = {}, invisible = {}}
  local count = 0
  local cached = true
  for itemId, visibility in pairs(self:GetDB()[slot]) do
    local name, link = GetItemInfo(itemId)
    if link then
      table.insert(items[visibility and "visible" or "invisible"], {name = name, link = link, visibility = visibility})
      count = count + 1
    else
      cached = false
    end
  end
  if not cached then
    C_Timer.After(0.1, function() self:ListItems(slot) end)
    return false
  end
  
  table.sort(items.visible,   function(a, b) return a.name < b.name end)
  table.sort(items.invisible, function(a, b) return a.name < b.name end)
  
  if count > 0 then
    if #items.visible > 0 then
      self:Printf(slot == 1 and L["Shown hats:"] or L["Shown cloaks:"])
      for _, item in ipairs(items.visible) do
        self:Printf("  %s", item.link)
      end
    end
    if #items.invisible > 0 then
      self:Printf(slot == 1 and L["Hidden hats:"] or L["Hidden cloaks:"])
      for _, item in ipairs(items.invisible) do
        self:Printf("  %s", item.link)
      end
    end
  else
    self:Printf(slot == 1 and L["No hats are being remembered"] or L["No cloaks are being remembered"])
  end
  
  return true
end

function Hatter:ParseChatCommand(input)
  local command, link = self:GetArgs(input, 2)
  command = command and command:lower() or nil
  if command == "list" then
    self:ListItems(Data.HEAD)
    self:ListItems(Data.BACK)
    return true
  elseif command == "forget" then
    if link then
      local id = link:match"item:(%d+)"
      if id then
        id = tonumber(id)
        if id then
          for slot in pairs(Data.HIDABLE_SLOTS) do
            if self:GetVisibility(slot, id) ~= nil then
              self:SetVisibility(slot, id, nil)
              break
            end
          end
          return true
        end
      end
    end
  elseif command == "clear" then
    for slot in pairs(Data.HIDABLE_SLOTS) do
      for k, v in pairs(self:GetDB()[slot]) do
        self:SetVisibility(slot, itemId, nil)
      end
    end
  elseif command == "config" or command == "options" then
    self:OpenConfig(ADDON_NAME)
    return true
  end
  return false
end

function Hatter:OnChatCommand(input)
  if not self:ParseChatCommand(input) then
    self:PrintUsage()
  end
end



function Hatter:IsWeakAuraFound()
  if WeakAuras then
    if WeakAuras.IsAuraLoaded then
      if WeakAuras.IsAuraLoaded(ADDON_NAME) then
        return true
      end
    elseif WeakAuras.loaded then
      if WeakAuras.loaded[ADDON_NAME] then
        return true
      end
    end
  end
  return false
end



function Hatter:CreateHooks()
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnEquipmentChanged")
  
  self.ShowHelm  = ShowHelm
  self.ShowCloak = ShowCloak
  
  hooksecurefunc("ShowHelm" , function(isShown) return Hatter:OnShown(Data.HEAD, isShown) end)
  hooksecurefunc("ShowCloak", function(isShown) return Hatter:OnShown(Data.BACK, isShown) end)
end



function Hatter:CreateOptions()
  AceConfig:RegisterOptionsTable(ADDON_NAME, Data:MakeOptionsTable(self, L))
  local Panel = AceConfigDialog:AddToBlizOptions(ADDON_NAME)
  Panel.default = function()
    local db = self:GetDB()
    for k, v in pairs(Data:GetDefaultOptions().profile.DefaultVisibility) do
      db.DefaultVisibility[k] = v
    end
    AceConfigRegistry:NotifyChange(ADDON_NAME)
  end
  
  
  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfig:RegisterOptionsTable(ADDON_NAME .. ".Profiles", profiles)
  AceConfigDialog:AddToBlizOptions(ADDON_NAME .. ".Profiles", "Profiles", ADDON_NAME)
  
  
  self:RegisterChatCommand(ADDON_NAME:lower(), "OnChatCommand", true)
end



function Hatter:OnInitialize()  
  self.db = AceDB:New("HatterDB", Data:GetDefaultOptions())
end

function Hatter:OnEnable()
  Data:Init(self, L)
  self:CreateHooks()
  self:CreateOptions()
  
  C_Timer.After(1, function()
    ShowHelm(ShowingHelm())
    ShowCloak(ShowingCloak())
  end)
  
  C_Timer.After(1, function()
    if self:IsWeakAuraFound() then
      
      AceConfig:RegisterOptionsTable(ADDON_NAME .. " WeakAura", Data:MakeWeakAuraOptionsTable(self, L))
      local Panel = AceConfigDialog:AddToBlizOptions(ADDON_NAME .. " WeakAura", "WeakAura", ADDON_NAME)
      
      StaticPopup_Show("HATTER_WEAKAURA_WARN", ADDON_NAME, nil, {Addon = self, Panel = Panel})
    end
  end)
  
end

function Hatter:OnDisable()
  
end

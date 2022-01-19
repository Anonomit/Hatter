

local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
Hatter = Addon
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local AceConfig         = LibStub"AceConfig-3.0"
local AceConfigDialog   = LibStub"AceConfigDialog-3.0"
local AceConfigRegistry = LibStub"AceConfigRegistry-3.0"
local AceDB             = LibStub"AceDB-3.0"
local AceDBOptions      = LibStub"AceDBOptions-3.0"

local SemVer            = LibStub"SemVer"



function Addon:GetDB()
  return self.db
end
function Addon:GetDefaultDB()
  return self.dbDefault
end
function Addon:GetProfile()
  return self:GetDB().profile
end
function Addon:GetDefaultProfile()
  return self:GetDefaultDB().profile
end
local function GetOption(self, db, ...)
  local val = db
  for _, key in ipairs{...} do
    val = val[key]
  end
  return val
end
function Addon:GetOption(...)
  return GetOption(self, self:GetProfile(), ...)
end
function Addon:GetDefaultOption(...)
  return GetOption(self, self:GetDefaultProfile(), ...)
end
local function SetOption(self, db, val, ...)
  local keys = {...}
  local lastKey = table.remove(keys, #keys)
  local tbl = db
  for _, key in ipairs(keys) do
    tbl = tbl[key]
  end
  tbl[lastKey] = val
end
function Addon:SetOption(val, ...)
  return SetOption(self, self:GetProfile(), val, ...)
end
function Addon:ResetOption(...)
  return self:SetOption(val, self:GetDefaultOptions(...))
end






function Addon:GetVisibility(slot, id)
  return self:GetOption(slot, id)
end
function Addon:SetVisibility(slot, id, visibility)
  if visibility == nil then
    return self:ForgetVisibility(slot, id)
  end
  local oldVisibility = self:GetVisibility(slot, id)
  self:SetOption(visibility, slot, id)
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
function Addon:ForgetVisibility(slot, id)
  self:SetOption(nil, slot, id)
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
function Addon:ForgetAllVisibility(slot)
  for id in pairs(self:GetOption(slot)) do
    self:ForgetVisibility(slot, id)
  end
end

function Addon:SetVisibilityDefault(slot, id)
  if self:GetVisibility(slot, id) == nil then
    if self:GetOption("DefaultVisibility", "EnforceDefault") then
      self:SetVisibility(slot, id, self:GetOption("DefaultVisibility", slot))
    else
      self:SetVisibility(slot, id, self:IsShown(slot))
    end
  end
end

function Addon:IsHidable(slot)
  return Data.HIDABLE_SLOTS[slot] or false
end

function Addon:IsShown(slot)
  if slot == Data.HEAD then
    return ShowingHelm()
  elseif slot == Data.BACK then
    return ShowingCloak()
  end
end

function Addon:ShowSlot(slot, visibility)
  if slot == Data.HEAD then
    return self.hooks.ShowHelm(visibility)
  elseif slot == Data.BACK then
    return self.hooks.ShowCloak(visibility)
  end
end

function Addon:GetItemId(slot)
  return GetInventoryItemID("player", slot)
end
function Addon:GetItemLink(slot)
  return GetInventoryItemLink("player", slot)
end


function Addon:SetShown(slot, visibility)
  if self:IsShown(slot) ~= visibility then
    self:ShowSlot(slot, visibility)
  end
end




function Addon:OnEquipmentChanged(event, slot, isEmpty)
  if not self:GetOption("Debug", "enabled") then return end
  if not self:IsHidable(slot) then return end
  if isEmpty then return end
  
  local itemId = self:GetItemId(slot)
  if itemId and self:GetItemLink(slot) then
    self:SetVisibilityDefault(slot, itemId)
    self:SetShown(slot, self:GetVisibility(slot, itemId))
  end
end


function Addon:OnShown(slot, isShown)
  if not self:GetOption("Debug", "enabled") then return end
  local itemId = self:GetItemId(slot)
  if itemId and self:GetItemLink(slot) then
    self:SetVisibility(slot, itemId, isShown)
  end
end

function Addon:OnHelmShown(isShown)
  return Addon:OnShown(Data.HEAD, isShown)
end
function Addon:OnCloakShown(isShown)
  return Addon:OnShown(Data.BACK, isShown)
end





function Addon:PrintUsage()
  self:Printf(L["Usage:"])
  self:Printf("  /%s config", Data.CHAT_COMMAND)
  self:Printf("    %s", L["Open options"])
  self:Printf("  /%s list", Data.CHAT_COMMAND)
  self:Printf("    %s", L["List items"])
  self:Printf("  /%s forget [%s]", Data.CHAT_COMMAND, L["ItemLink"])
  self:Printf("    %s", L["Forget an item"])
end

function Addon:ListItems(slot, noHeader)
  local items = {visible = {}, invisible = {}}
  local count = 0
  local cached = true
  for itemId, visibility in pairs(self:GetOption(slot)) do
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

function Addon:ParseChatCommand(input)
  local command, link = self:GetArgs(input, 2)
  command = command and command:lower() or nil
  if command == "list" then
    self:ListItems(Data.HEAD)
    self:ListItems(Data.BACK)
    return true
  elseif command == "forget" then
    if link then
      local id = tonumber(link)
      if not id then
        id = link:match"item:(%d+)"
      end
      if id then
        id = tonumber(id)
        if id then
          local found = false
          for slot in pairs(Data.HIDABLE_SLOTS) do
            if self:GetVisibility(slot, id) ~= nil then
              self:SetVisibility(slot, id, nil)
              found = true
              break
            end
          end
          if not found then
            self:Printf(L["That item is not being remembered"])
          end
          return true
        end
      else
        return false
      end
    end
  elseif command == "clear" then
    for slot in pairs(Data.HIDABLE_SLOTS) do
      for k, v in pairs(self:GetOption(slot)) do
        self:SetVisibility(slot, itemId, nil)
      end
    end
  elseif command == "config" or command == "options" then
    self:OpenConfig(ADDON_NAME, true)
    return true
  end
  return false
end

function Addon:OnChatCommand(input)
  if not self:ParseChatCommand(input) then
    self:PrintUsage()
  end
end



function Addon:IsWeakAuraFound()
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



function Addon:CreateHooks()
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnEquipmentChanged")
  
  self:Hook(nil, "ShowHelm" , "OnHelmShown" , true)
  self:Hook(nil, "ShowCloak", "OnCloakShown", true)
end




function Addon:OpenConfig(category, expandSection)
  InterfaceAddOnsList_Update()
  InterfaceOptionsFrame_OpenToCategory(category)
  
  if expandSection then
    -- Expand config if it's collapsed
    local i = 1
    while _G["InterfaceOptionsFrameAddOnsButton"..i] do
      local frame = _G["InterfaceOptionsFrameAddOnsButton"..i]
      if frame.element then
        if frame.element.name == ADDON_NAME then
          if frame.element.hasChildren and frame.element.collapsed then
            if _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"] and _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"].Click then
              _G["InterfaceOptionsFrameAddOnsButton"..i.."Toggle"]:Click()
              break
            end
          end
          break
        end
      end
      
      i = i + 1
    end
  end
end
function Addon:MakeDefaultFunc(category)
  return function()
    self:GetDB():ResetProfile()
    self:InitDB()
    self:Printf(L["Profile reset to default."])
    AceConfigRegistry:NotifyChange(category)
  end
end
function Addon:CreateOptionsCategory(categoryName, options)
  local category = ADDON_NAME
  if categoryName then
    category = ("%s.%s"):format(category, categoryName)
  end
  AceConfig:RegisterOptionsTable(category, options)
  local Panel = AceConfigDialog:AddToBlizOptions(category, categoryName, categoryName and ADDON_NAME or nil)
  Panel.default = self:MakeDefaultFunc(category)
  return Panel
end

function Addon:CreateOptions()
  self:CreateOptionsCategory(nil, Data:MakeOptionsTable(ADDON_NAME, self, L))
  
  self:CreateOptionsCategory("Profiles", AceDBOptions:GetOptionsTable(self.db))
  
  if self:GetOption("Debug", "menu") then
    self:CreateOptionsCategory("Debug" , Data:MakeDebugOptionsTable("Debug", self, L))
  end
end



function Addon:InitDB()
  local configVersion = SemVer(self:GetOption"version" or tostring(self.Version))
  -- Update data schema here
  
  self:SetOption(tostring(self.Version), "version")
end


function Addon:OnInitialize()  
  self.db        = AceDB:New(("%sDB"):format(ADDON_NAME)        , Data:MakeDefaultOptions(), true)
  self.dbdefault = AceDB:New(("%sDB_Default"):format(ADDON_NAME), Data:MakeDefaultOptions(), true)
  
  self:RegisterChatCommand(Data.CHAT_COMMAND, "OnChatCommand", true)
end

function Addon:OnEnable()
  self.Version = SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB()
  self:GetDB().RegisterCallback(self, "OnProfileChanged", "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , "InitDB")
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , "InitDB")
  
  Data:Init(self, L)
  
  self:CreateHooks()
  self:CreateOptions()
  
  C_Timer.After(1, function()
    ShowHelm(ShowingHelm())
    ShowCloak(ShowingCloak())
  end)
  
  C_Timer.After(1, function()
    if self:IsWeakAuraFound() then
      local Panel = self:CreateOptionsCategory("WeakAura", Data:MakeWeakAuraOptionsTable("WeakAura", self, L))
      StaticPopup_Show(("%s_WEAKAURA_WARN"):format(ADDON_NAME:upper()), ADDON_NAME, nil, {Addon = self, Panel = Panel})
    end
  end)
  
end

function Addon:OnDisable()
  
end

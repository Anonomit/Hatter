
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



local strGmatch = string.gmatch
local strGsub   = string.gsub
local strByte   = string.byte

local tinsert   = table.insert
local tblConcat = table.concat
local tblSort   = table.sort

local mathMin   = math.min
local mathMax   = math.max







local name, desc, disabled






--   ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ██╗          ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗██║         ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║██║         ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║██║         ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║███████╗    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeGeneralOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:ResetDBType()
  local disabled
  
  GUI:CreateToggle(opts, {"enabled"}, self.L["Enabled"], nil).width = 0.7
  
  
  GUI:ResetDBType()
  return opts
end





--  ██████╗ ███████╗███████╗ █████╗ ██╗   ██╗██╗  ████████╗███████╗
--  ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██║  ╚══██╔══╝██╔════╝
--  ██║  ██║█████╗  █████╗  ███████║██║   ██║██║     ██║   ███████╗
--  ██║  ██║██╔══╝  ██╔══╝  ██╔══██║██║   ██║██║     ██║   ╚════██║
--  ██████╔╝███████╗██║     ██║  ██║╚██████╔╝███████╗██║   ███████║
--  ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚══════╝

local function MakeItemDefaultOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType""
  local disabled
  
  
  GUI:CreateToggle(opts, {"defaultItemSettings", "ignored"}, L["Ignore New Items"], L["This determines whether item visibility should be remembered automatically for new equipment."]).width = 1.5
  GUI:CreateNewline(opts)
  
  local disabled = self:GetOption("defaultItemSettings", "ignored")
  
  GUI:CreateToggle(opts, {"defaultItemSettings", "forceVisibility"}, L["Force Visibility for New Items"], L["This applies to items when they are equipped for the first time.|n|nIf enabled, visibility will be determined by these default settings.|n|nIf disabled, visibility will be the same as the previously equipped item in that slot."], disabled).width = 1.5
  do
    local opts = GUI:CreateGroupBox(opts, L["Visibility for New Equipment"])
    GUI:CreateToggle(opts, {"defaultItemSettings", self.invSlots.HEAD}, SHOW_HELM, L["This determines the visibility of an item when it's equipped for the first time."], disabled or not Addon:GetOption("defaultItemSettings", "forceVisibility"))
    GUI:CreateNewline(opts)
    GUI:CreateToggle(opts, {"defaultItemSettings", self.invSlots.BACK}, SHOW_CLOAK, L["This determines the visibility of an item when it's equipped for the first time."], disabled or not Addon:GetOption("defaultItemSettings", "forceVisibility"))
  end
  
  
  GUI:ResetDBType()
  return opts
end



--  ██╗████████╗███████╗███╗   ███╗███████╗
--  ██║╚══██╔══╝██╔════╝████╗ ████║██╔════╝
--  ██║   ██║   █████╗  ██╔████╔██║███████╗
--  ██║   ██║   ██╔══╝  ██║╚██╔╝██║╚════██║
--  ██║   ██║   ███████╗██║ ╚═╝ ██║███████║
--  ╚═╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚══════╝

local function MakeItemOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType""
  local disabled
  
  for _, data in ipairs{
    {"HEAD", self.L["Head"], self.L["Show Helm"],  format("%s %s", self:MakeIcon"Interface\\FriendsFrame\\InformationIcon", L["Equip a hat to configure it."]),   "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head"},
    {"BACK", self.L["Back"], self.L["Show Cloak"], format("%s %s", self:MakeIcon"Interface\\FriendsFrame\\InformationIcon", L["Equip a cloak to configure it."]), "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"},
  } do
    local slotName               = data[1]
    local slot                   = self.invSlots[slotName]
    local localizedSlotName      = data[2]
    local localizedShownToggle   = data[3]
    local localizedEmptyHint     = data[4]
    local localizedEmptyHintIcon = data[5]
    
    local opts = GUI:CreateGroup(opts, slot, localizedSlotName, nil, "tab")
    
    local ItemCache = Addon.ItemCache
    local currentEquippedItemID = Addon:GetEquippedItemID(slot)
    local equippingItem = false
    local itemCount = 0
    local uniqueItems = {}
    local missing = {}
    for id in pairs(self:GetOptionQuiet("items", slot)) do
      local item = ItemCache(id)
      if item:Exists() then
        if item:GetID() == currentEquippedItemID then
          equippingItem = true
        else
          itemCount = itemCount + 1
        end
        if item:IsCached() then
          uniqueItems[item] = true
        else
          missing[#missing+1] = item
        end
      end
    end
    
    if #missing > 0 then
      self.ItemCache:OnCache(missing, function() self:RefreshConfig() end)
    end
    
    local items = {}
    for item in pairs(uniqueItems) do
      items[#items+1] = item
    end
    tblSort(items, function(a, b)
      if a:GetName() ~= b:GetName() then
        return a:GetName() < b:GetName()
      else
        return a:GetID() < b:GetID()
      end
    end)
    
    
    local itemButtonTooltipText = format("|n|cffffd706%s:|r %s|n|cffffd706%s-%s:|r %s|n|cffffd706%s-%s:|r %s",
      self.L["Left-Click"], self.L["Check out this item!"],
      self.L["SHIFT"], self.L["Left-Click"], self.L["Link Item to Chat"],
      self.L["CTRL"], self.L["Left-Click"], self.L["View in Dressing Room"]
    )
    
    if itemCount > 0 or equippingItem then
      local option = GUI:CreateExecute(opts, "Delete", self.L["Clear All"], nil, function()
        -- only delete items that exist in this game version and are not equipped
        local currentEquippedItemID = Addon:GetEquippedItemID(slot)
        for item in pairs(uniqueItems) do
          if item:GetID() ~= currentEquippedItemID then
            self:SetOption(nil, "items", slot, item:GetID())
          end
        end
      end, itemCount == 0)
      option.width = width
      option.confirm = function() return format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], format("|n" .. self.L["%d Items"], self:ToFormattedNumber(itemCount))) end
    else
      GUI:CreateDescription(opts, localizedEmptyHint).image = localizedEmptyHintIcon
    end
    
    for i, item in ipairs(items) do
      local itemID = item:GetID()
      
      local opts = GUI:CreateGroupBox(opts, " ")
      
      do
        local colorCode = ITEM_QUALITY_COLORS[item:GetQuality()].hex
        local itemName  = format("%s %s%s", self:MakeIcon(item:GetIcon()), colorCode, item:GetName())
        
        local desc = itemButtonTooltipText
        
        GUI:CreateExecute(opts, "item", itemName, desc, function()
          if IsShiftKeyDown() or IsControlKeyDown() then
            HandleModifiedItemClick(item:GetLink())
          else
            ShowUIPanel(ItemRefTooltip)
            if not ItemRefTooltip:IsShown() then
              ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
            end
            ItemRefTooltip:SetHyperlink(item:GetLink())
          end
        end, disabled).width = 2
      end
      
      local option = GUI:CreateExecute(opts, "Delete", self.L["Delete Outfit"], nil, function() self:SetOption(nil, "items", slot, itemID) end, itemID == currentEquippedItemID)
      option.width = width
      option.confirm = function() return format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], "|n" .. item:GetLink()) end
      
      GUI:CreateNewline(opts)
      GUI:CreateToggle(opts, {"items", slot, itemID, "visible"}, localizedShownToggle, nil, self:GetOption("items", slot, itemID, "ignored")).set = function(info, val)
        self:ToggleOption("items", slot, itemID, "visible")
        self:ShowSlot(slot, self:GetOption("items", slot, itemID, "visible"))
      end
      GUI:CreateToggle(opts, {"items", slot, itemID, "ignored"}, self.L["Ignored"], L["Don't change visibility when this item is equipped."], disabled).set = function(info, val)
        self:ToggleOption("items", slot, itemID, "ignored")
        if not self:GetOption("items", slot, itemID, "ignored") then
          self:ShowSlot(slot, self:GetOption("items", slot, itemID, "visible"))
        end
      end
      
    end
  end
  
  
  GUI:ResetDBType()
  return opts
end





--  ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗      ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝      ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeProfileOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  
  local profileOptions = self.AceDBOptions:GetOptionsTable(self:GetDB())
  profileOptions.order = GUI:Order()
  opts.args[categoryName] = profileOptions
  
  return opts
end




--  ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗      ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝     ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝      ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeDebugOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  if not self:IsDebugEnabled() then return end
  GUI:SetDBType"Global"
  
  
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  GUI:CreateExecute(opts, "reload", self.L["Reload UI"], nil, ReloadUI)
  
  -- Enable
  do
    local opts = GUI:CreateGroup(opts, "Enable", self.L["Enable"])
    
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Debug"])
      GUI:CreateToggle(opts, {"debug"}, self.L["Enable"])
      GUI:CreateNewline(opts)
      
      GUI:CreateToggle(opts, {"debugShowLuaErrors"}, self.L["Display Lua Errors"], nil, disabled).width = 2
      GUI:CreateNewline(opts)
      
      local disabled = not self:GetGlobalOption"debugShowLuaErrors"
      GUI:CreateToggle(opts, {"debugShowLuaWarnings"}, self.L["Lua Warning"], nil, disabled).width = 2
    end
  end
  
  -- Debug Output
  do
    local opts = GUI:CreateGroup(opts, "Output", "Output")
    
    local disabled = not self:GetGlobalOption"debug"
    
    do
      local opts = GUI:CreateGroupBox(opts, "Suppress All")
      
      GUI:CreateToggle(opts, {"debugOutput", "suppressAll"}, self.debugPrefix .. " " .. self.L["Hide messages like this one."], nil, disabled).width = 2
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, "Addon Messages")
      
      local disabled = disabled or self:GetGlobalOption("debugOutput", "suppressAll")
      
      for i, data in ipairs{
        {"onEvent",       "WoW event"},
        {"onAddonEvent",  "Addon event"},
        {"optionSet",     "Option Set"},
        {"cvarSet",       "CVar Set"},
        {"configRefresh", "Config window refreshed"},
      } do
        if i ~= 1 then
          GUI:CreateNewline(opts)
        end
        GUI:CreateToggle(opts, {"debugOutput", data[1]}, format("%d: %s", i, data[2]), nil, disabled).width = 2
      end
    end
  end
  
  
  return opts
end




--   █████╗ ██████╗ ██████╗  ██████╗ ███╗   ██╗     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗████╗  ██║    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ███████║██║  ██║██║  ██║██║   ██║██╔██╗ ██║    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██╔══██║██║  ██║██║  ██║██║   ██║██║╚██╗██║    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██║  ██║██████╔╝██████╔╝╚██████╔╝██║ ╚████║    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

function Addon:MakeAddonOptions(chatCmd)
  local title = format("%s %s v%s (/%s)", self:MakeIcon("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Textures\\Addon Image.png"), ADDON_NAME, tostring(self:GetGlobalOption"version"), chatCmd)
  
  local sections = {}
  for _, data in ipairs{
    {MakeGeneralOptions, ADDON_NAME},
    {MakeItemDefaultOptions, self.L["Defaults"], "defaults"},
    {MakeItemOptions,        self.L["Items"],    "items"},
    
    {MakeProfileOptions, "Profiles",      "profiles"},
    {MakeDebugOptions,   self.L["Debug"], "debug"},
  } do
    
    local func = data[1]
    local name = data[2]
    local args = {unpack(data, 3)}
    
    tinsert(sections, function(opts) return func(opts, name) end)
    
    local function OpenOptions() return self:OpenConfig(name) end
    if name == self.L["Debug"] then
      local OpenOptions_Old = OpenOptions
      OpenOptions = function(...)
        if not self:GetGlobalOption"debug" then
          self:SuspendConfigRefreshingWhile(function()
            self:SetGlobalOption(true, "debug")
            self:Debug"Debug mode enabled"
          end)
        end
        return OpenOptions_Old(...)
      end
    end
    
    for _, arg in ipairs(args) do
      self:RegisterChatArgAliases(arg, OpenOptions)
    end
  end
  
  self.AceConfig:RegisterOptionsTable(ADDON_NAME, function()
    self:DebugIfOutput("configRefresh", "Config refreshed")
    
    local GUI = self.GUI:ResetOrder()
    local opts = GUI:CreateOpts(title, "tab")
    
    for _, func in ipairs(sections) do
      GUI:ResetDBType()
      self:xpcall(function()
        func(opts)
      end)
      GUI:ResetDBType()
    end
    
    return opts
  end)
  
  self.AceConfigDialog:SetDefaultSize(ADDON_NAME, 700, 800) -- default is (700, 500)
end


function Addon:MakeBlizzardOptions(chatCmd)
  local title = format("%s %s v%s (/%s)", self:MakeIcon("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Textures\\Addon Image.png"), ADDON_NAME, tostring(self:GetGlobalOption"version"), chatCmd)
  local panel = self:CreateBlizzardOptionsCategory(function()
    local GUI = self.GUI:ResetOrder()
    local opts = GUI:CreateOpts(title, "tab")
    
    GUI:CreateExecute(opts, "key", ADDON_NAME .. " " .. self.L["Options"], nil, function()
      self:CloseBlizzardConfig()
      self:OpenConfig()
    end)
    
    return opts
  end)
end



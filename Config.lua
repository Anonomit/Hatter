
local ADDON_NAME, Data = ...


local buildMajor = tonumber(GetBuildInfo():match"^(%d+)%.")
if buildMajor == 2 then
  Data.WOW_VERSION = "BCC"
elseif buildMajor == 1 then
  Data.WOW_VERSION = "Classic"
end

function Data:IsBCC()
  return Data.WOW_VERSION == "BCC"
end
function Data:IsClassic()
  return Data.WOW_VERSION == "Classic"
end


Data.CHAT_COMMAND = ADDON_NAME:lower()

-- How spread out options are in interface options
local OPTIONS_DIVIDER_HEIGHT = 3


Data.HEAD = 1
Data.BACK = 15

Data.HIDABLE_SLOTS = {
  [Data.HEAD] = true,
  [Data.BACK] = true,
}

function Data:MakeDefaultOptions()
  return {
    profile = {
      ["*"] = {},
      
      DefaultVisibility = {
        EnforceDefault = true,
        
        [Data.HEAD] = true,
        [Data.BACK] = true,
      },
      
      Debug = {
        menu    = false,
        enabled = true,
      },
    },
  }
end



local function GetOptionTableHelpers(Options, Addon)
  local defaultInc = 1000
  local order      = 1000
  
  local GUI = {}
  
  function GUI:GetOrder()
    return order
  end
  function GUI:SetOrder(newOrder)
    order = newOrder
  end
  function GUI:Order(inc)
    self:SetOrder(self:GetOrder() + (inc or defaultInc))
    return self:GetOrder()
  end
  
  function GUI:CreateEntry(key, name, desc, widgetType, order)
    key = widgetType .. "_" .. (key or "")
    Options.args[key] = {name = name, desc = desc, type = widgetType, order = order or self:Order()}
    return Options.args[key]
  end
  
  function GUI:CreateHeader(name)
    local option = self:CreateEntry(self:Order(), name, nil, "header", self:Order(0))
  end
  
  function GUI:CreateDescription(desc, fontSize)
    local option = self:CreateEntry(self:Order(), desc, nil, "description", self:Order(0))
    option.fontSize = fontSize or "large"
  end
  function GUI:CreateDivider(count)
    for i = 1, count or 3 do
      self:CreateDescription("", "small")
    end
  end
  function GUI:CreateNewline()
    return self:CreateDivider(1)
  end
  
  function GUI:CreateToggle(keys, name, desc, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "toggle")
    option.disabled = disabled
    option.set      = function(info, val)        Addon:SetOption(val, unpack(keys)) end
    option.get      = function(info)      return Addon:GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateRange(keys, name, desc, min, max, step, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "range")
    option.disabled = disabled
    option.min      = min
    option.max      = max
    option.step     = step
    option.set      = function(info, val)        Addon:SetOption(val, unpack(keys)) end
    option.get      = function(info)      return Addon:GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateInput(keys, name, desc, multiline, disabled)
    if type(keys) ~= "table" then keys = {keys} end
    local option = self:CreateEntry(table.concat(keys, "."), name, desc, "input")
    option.multiline = multiline
    option.disabled  = disabled
    option.set       = function(info, val)        Addon:SetOption(val, unpack(keys)) end
    option.get       = function(info)      return Addon:GetOption(unpack(keys))      end
    return option
  end
  function GUI:CreateExecute(key, name, desc, func)
    local option = self:CreateEntry(key, name, desc, "execute")
    option.func = func
    return option
  end
  
  return GUI
end


function Data:MakeOptionsTable(title, Addon, L)
  local Options = {
    name = title,
    type = "group",
    args = {}
  }
  local GUI = GetOptionTableHelpers(Options, Addon)
  
  GUI:CreateDescription(L["Defaults for New Equipment"])
  GUI:CreateNewline()
  GUI:CreateToggle({"DefaultVisibility", "EnforceDefault"}, L["Force Default Visibility"], L["This applies to items when they are equipped for the first time. If enabled, visibility will be determined by these default settings. If disabled, visibility will be the same as the previously equipped item in that slot."])
  GUI:CreateNewline()
  GUI:CreateToggle({"DefaultVisibility", Data.HEAD}, SHOW_HELM, L["This determines the visibility of an item when it's equipped for the first time"], function(info) return not Addon:GetOption("DefaultVisibility", "EnforceDefault") end)
  GUI:CreateNewline()
  GUI:CreateToggle({"DefaultVisibility", Data.BACK}, SHOW_CLOAK, L["This determines the visibility of an item when it's equipped for the first time"], function(info) return not Addon:GetOption("DefaultVisibility", "EnforceDefault") end)
  
  GUI:CreateDivider(10)
  GUI:CreateDescription(L["List items"])
  GUI:CreateDescription(("/%s list"):format(Data.CHAT_COMMAND), "small")
  GUI:CreateNewline()
  GUI:CreateExecute("ListHats", L["List Hats"], nil, function() Addon:ListItems(Data.HEAD) end)
  GUI:CreateNewline()
  GUI:CreateExecute("ListCloaks", L["List Cloaks"], nil, function() Addon:ListItems(Data.BACK) end)
  
  GUI:CreateDivider(10)
  GUI:CreateDescription(L["Forget items"])
  GUI:CreateDescription(("/%s forget [%s]"):format(Data.CHAT_COMMAND, L["ItemLink"]), "small")
  GUI:CreateNewline()
  GUI:CreateExecute("ForgetHats", L["Forget Hats"], nil, function() StaticPopup_Show(("%s_CONFIRM_FORGET_ALL_HATS"):format(ADDON_NAME:upper()), nil, nil, Addon) end)
  GUI:CreateNewline()
  GUI:CreateExecute("ForgetCloaks", L["Forget Cloaks"], nil, function() StaticPopup_Show(("%s_CONFIRM_FORGET_ALL_CLOAKS"):format(ADDON_NAME:upper()), nil, nil, Addon) end)
  
  return Options
end



function Data:MakeWeakAuraOptionsTable(title, Addon, L)
  local Options = {
    name = title,
    type = "group",
    args = {}
  }
  local GUI = GetOptionTableHelpers(Options, Addon)
  
  
  GUI:CreateDescription(L["Only one version of %s should be used. You can disable or delete the conflicting WeakAura here."]:format(ADDON_NAME), "small")
  GUI:CreateDivider()
  GUI:CreateExecute("DisableWeakAura", L["Disable WeakAura"], nil, function() StaticPopup_Show(("%s_CONFIRM_DISABLE_WEAKAURA"):format(ADDON_NAME:upper()), ADDON_NAME) end)
  GUI:CreateNewline()
  GUI:CreateExecute("DeleteWeakAura", L["Delete WeakAura"], nil, function() StaticPopup_Show(("%s_CONFIRM_DELETE_WEAKAURA"):format(ADDON_NAME:upper()), ADDON_NAME) end)
  
  return Options
end



function Data:MakeDebugOptionsTable(title, Addon, L)
  local Options = {
    name = title,
    type = "group",
    args = {}
  }
  local GUI = GetOptionTableHelpers(Options, Addon)
  
  GUI:CreateToggle({"Debug", "enabled"}, "Enabled")
  
  return Options
end



function Data:Init(Addon, L)
  StaticPopupDialogs[("%s_CONFIRM_FORGET_ALL_HATS"):format(ADDON_NAME:upper())] =
  {
    text         = L["Are you sure you want to forget all hats?"],
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, Addon)
      Addon:ForgetAllVisibility(Data.HEAD)
    end,
  }
  StaticPopupDialogs[("%s_CONFIRM_FORGET_ALL_CLOAKS"):format(ADDON_NAME:upper())] =
  {
    text         = L["Are you sure you want to forget all cloaks?"],
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, Addon)
      Addon:ForgetAllVisibility(Data.BACK)
    end,
  }
  
  StaticPopupDialogs[("%s_WEAKAURA_WARN"):format(ADDON_NAME:upper())] =
  {
    text         = L["%s WeakAura is active. This may cause unexpected behavior. Would you like to open config?"],
    button1      = OKAY,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self, data)
      data.Addon:OpenConfig(data.Panel)
    end,
  }
  
  StaticPopupDialogs[("%s_CONFIRM_DISABLE_WEAKAURA"):format(ADDON_NAME:upper())] =
  {
    text         = L["Are you sure you want to disable %s WeakAura?"] .. ("\n(%s)"):format(L["Requires reload"]),
    showAlert    = true,
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
      WeakAurasSaved.displays[ADDON_NAME].load.use_never = true
      ReloadUI()
    end,
  }
  
  StaticPopupDialogs[("%s_CONFIRM_DELETE_WEAKAURA"):format(ADDON_NAME:upper())] =
  {
    text         = L["Are you sure you want to delete %s WeakAura?"],
    showAlert    = true,
    button1      = YES,
    button2      = NO,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
      WeakAuras.Delete{id = ADDON_NAME, uid = WeakAurasSaved.displays[ADDON_NAME].uid}
    end,
  }
end



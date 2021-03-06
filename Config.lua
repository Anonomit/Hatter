
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

local OPTION_DEFAULTS = {
  profile = {
    ["*"] = {},
    
    DefaultVisibility = {
      EnforceDefault = true,
      
      [Data.HEAD] = true,
      [Data.BACK] = true,
    },
    
    DEBUG = {
      MENU = false,
    },
  },
}

function Data:GetDefaultOptions()
  return OPTION_DEFAULTS
end




local function GetOptionTableHelpers(Options, defaultOrder)
  local Helpers = {}
  
  local order = defaultOrder or 99
  function Helpers.Order(inc)
    order = order + (inc and inc or 0) + 1
    return order
  end
  
  function Helpers.CreateHeader(name)
    Options.args["divider" .. Helpers.Order()] = {name = name, order = Helpers.Order(-1), type = "header"}
  end
  
  function Helpers.CreateDivider(count)
    for i = 1, count or OPTIONS_DIVIDER_HEIGHT do
      Options.args["divider" .. Helpers.Order()] = {name = "", order = Helpers.Order(-1), type = "description"}
    end
  end
  function Helpers.CreateNewline()
    Helpers.CreateDivider(1)
  end
  function Helpers.CreateDescription(desc, fontSize)
    Options.args["description" .. Helpers.Order()] = {name = desc, fontSize = fontSize or "large", order = Helpers.Order(-1), type = "description"}
  end
  
  return Helpers
end


function Data:MakeOptionsTable(Addon, L)
  local Options = {
    type = "group",
    args = {}
  }
  
  local Helpers           = GetOptionTableHelpers(Options)
  local Order             = Helpers.Order
  local CreateHeader      = Helpers.CreateHeader
  local CreateDivider     = Helpers.CreateDivider
  local CreateNewline     = Helpers.CreateNewline
  local CreateDescription = Helpers.CreateDescription
  
  
  local db = Addon:GetDB()
  
  CreateDescription(L["Defaults for New Equipment"])
  CreateNewline()
  Options.args["EnforceDefault"] = {
    name  = L["Force Default Visibility"],
    desc  = L["This applies to items when they are equipped for the first time. If enabled, visibility will be determined by these default settings. If disabled, visibility will be the same as the previously equipped item in that slot."],
    order = Order(),
    type  = "toggle",
    set   = function(info, val)        Addon:SetEnforceDefault(val) end,
    get   = function(info)      return Addon:GetEnforceDefault()    end,
  }
  CreateNewline()
  Options.args["HatDefaultShown"] = {
    name     = SHOW_HELM,
    desc     = L["This determines the visibility of an item when it's equipped for the first time"],
    order    = Order(),
    disabled = function(info) return not Addon:GetEnforceDefault() end,
    type     = "toggle",
    set      = function(info, val)        Addon:SetDefaultVisibility(Data.HEAD, val) end,
    get      = function(info)      return Addon:GetDefaultVisibility(Data.HEAD)      end,
  }
  CreateNewline()
  Options.args["CloakDefaultShown"] = {
    name     = SHOW_CLOAK,
    desc     = L["This determines the visibility of an item when it's equipped for the first time"],
    order    = Order(),
    disabled = function(info) return not Addon:GetEnforceDefault() end,
    type     = "toggle",
    set      = function(info, val)        Addon:SetDefaultVisibility(Data.BACK, val) end,
    get      = function(info)      return Addon:GetDefaultVisibility(Data.BACK)      end,
  }
  
  
  CreateDivider(10)
  CreateDescription(L["List items"])
  CreateDescription(("/%s list"):format(Data.CHAT_COMMAND), "small")
  CreateNewline()
  Options.args["ListHats"] = {
    name = L["List Hats"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() Addon:ListItems(Data.HEAD) end,
  }
  CreateNewline()
  Options.args["ListCloaks"] = {
    name = L["List Cloaks"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() Addon:ListItems(Data.BACK) end,
  }
  
  CreateDivider(10)
  CreateDescription(L["Forget items"])
  CreateDescription(("/%s forget [%s]"):format(Data.CHAT_COMMAND, L["ItemLink"]), "small")
  CreateNewline()
  Options.args["ForgetHats"] = {
    name = L["Forget Hats"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() StaticPopup_Show(("%s_CONFIRM_FORGET_ALL_HATS"):format(ADDON_NAME:upper()), nil, nil, Addon) end,
  }
  CreateNewline()
  Options.args["ForgetCloaks"] = {
    name = L["Forget Cloaks"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() StaticPopup_Show(("%s_CONFIRM_FORGET_ALL_CLOAKS"):format(ADDON_NAME:upper()), nil, nil, Addon) end,
  }
  
  return Options
end



function Data:MakeWeakAuraOptionsTable(Addon, L)
  local Options = {
    type = "group",
    args = {}
  }
  
  local Helpers           = GetOptionTableHelpers(Options)
  local Order             = Helpers.Order
  local CreateHeader      = Helpers.CreateHeader
  local CreateDivider     = Helpers.CreateDivider
  local CreateNewline     = Helpers.CreateNewline
  local CreateDescription = Helpers.CreateDescription
  
  
  CreateDescription(L["Only one version of %s should be used. You can disable or delete the conflicting WeakAura here."]:format(ADDON_NAME), "small")
  CreateDivider()
  Options.args["DisableWeakAura"] = {
    name = L["Disable WeakAura"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() StaticPopup_Show(("%s_CONFIRM_DISABLE_WEAKAURA"):format(ADDON_NAME:upper()), ADDON_NAME) end,
  }
  CreateNewline()
  Options.args["DeleteWeakAura"] = {
    name = L["Delete WeakAura"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() StaticPopup_Show(("%s_CONFIRM_DELETE_WEAKAURA"):format(ADDON_NAME:upper()), ADDON_NAME) end,
  }
  
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



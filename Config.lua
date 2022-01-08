
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



-- How spread out options are in interface options
local OPTIONS_DIVIDER_HEIGHT = 3


local OPTION_DEFAULTS = {
  profile = {
    ["*"] = {},
    
    DefaultVisibility = {
      [1]  = false,
      [15] = false,
    },
    
    DEBUG = {
      MENU = false,
    },
  },
}

function Data:GetDefaultOptions()
  return OPTION_DEFAULTS
end


Data.HIDABLE_SLOTS = {
  [1]  = true, -- HEAD
  [15] = true, -- BACK
}
Data.HAT   = 1
Data.CLOAK = 15



function Data:MakeOptionsTable(Addon, L)
  local db = Addon:GetDB()
  
  local order = 99
  local function Order(inc)
    order = order + (inc and inc or 0) + 1
    return order
  end
  
  local ADDON_OPTIONS = {
    type = "group",
    args = {}
  }
  
  local function CreateHeader(name)
    ADDON_OPTIONS.args["divider" .. Order()] = {name = name, order = Order(-1), type = "header"}
  end
  
  local function CreateDivider(count)
    for i = 1, count or OPTIONS_DIVIDER_HEIGHT do
      ADDON_OPTIONS.args["divider" .. Order()] = {name = "", order = Order(-1), type = "description"}
    end
  end
  local function CreateNewline()
    CreateDivider(1)
  end
  local function CreateDescription(desc, fontSize)
    ADDON_OPTIONS.args["description" .. Order()] = {name = desc, fontSize = fontSize or "large", order = Order(-1), type = "description"}
  end
  
  
  CreateDescription(DEFAULTS)
  ADDON_OPTIONS.args["HatDefaultShown"] = {
    name = SHOW_HELM,
    desc = L["This determines the state of an item the first time it's equipped"],
    order = Order(),
    type = "toggle",
    set = function(info, val)        Addon:SetDefaultVisibility(Data.HAT, val) end,
    get = function(info)      return Addon:GetDefaultVisibility(Data.HAT)      end,
  }
  CreateNewline()
  ADDON_OPTIONS.args["CloakDefaultShown"] = {
    name = SHOW_CLOAK,
    desc = L["This determines the state of an item the first time it's equipped"],
    order = Order(),
    type = "toggle",
    set = function(info, val)        Addon:SetDefaultVisibility(Data.CLOAK, val) end,
    get = function(info)      return Addon:GetDefaultVisibility(Data.CLOAK)      end,
  }
  
  
  CreateDivider(10)
  CreateDescription(L["List items"])
  ADDON_OPTIONS.args["ListHats"] = {
    name = L["List Hats"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() Addon:ListItems(Data.HAT) end,
  }
  CreateNewline()
  ADDON_OPTIONS.args["ListCloaks"] = {
    name = L["List Cloaks"],
    desc = nil,
    order = Order(),
    type = "execute",
    func = function() Addon:ListItems(Data.CLOAK) end,
  }
  
  
  CreateDivider(10)
  CreateDescription(L["Forget an item"])
  CreateDescription(("/hatter forget [%s]"):format(L["ItemLink"]), "small")
  
  
  return ADDON_OPTIONS
end




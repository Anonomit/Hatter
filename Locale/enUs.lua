
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, not Addon:IsDebugEnabled())
if not L then return end






L["Equip a hat to configure it."] = true
L["Equip a cloak to configure it."] = true



L["Remembering"] = true
L["Shown"]       = true
L["Hidden"]      = true

L["Ignore New Items"] = true
L["This determines whether item visibility should be remembered automatically for new equipment."] = true
L["Force Visibility for New Items"] = true
L["This applies to items when they are equipped for the first time.|n|nIf enabled, visibility will be determined by these default settings.|n|nIf disabled, visibility will be the same as the previously equipped item in that slot."] = true
L["Visibility for New Equipment"] = true
L["This determines the visibility of an item when it's equipped for the first time."] = true



L["Don't change visibility when this item is equipped."] = true



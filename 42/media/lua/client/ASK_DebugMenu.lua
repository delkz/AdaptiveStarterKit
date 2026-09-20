require "DebugUIs/DebugMenu/ISDebugMenu"

local function grantCurrentKit()
    local ASK = AdaptiveStarterKit
    local player = getPlayer()
    if not ASK or not player then return end

    local config = ASK.getSettings()
    if not config.debug then
        ASK.showPlayerMessage(player, getText("IGUI_ASK_EnableDebug"))
        return
    end
    if not config.enabled then
        ASK.showPlayerMessage(player, getText("IGUI_ASK_ModDisabled"))
        return
    end

    ASK.debugGrantCurrent(player)
end

-- Add before vanilla sorting so Close remains the last button.
local originalSetupButtons = ISDebugMenu.setupButtons
function ISDebugMenu:setupButtons()
    self:addButtonInfo(getText("IGUI_ASK_GrantCurrent"), grantCurrentKit, "MAIN")
    originalSetupButtons(self)
end

local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Main.lua")
end

local function onCreatePlayer(_playerIndex, player)
    if not player then return end

    if isClient and isClient() then
        sendClientCommand(player, ASK.MOD_ID, ASK.COMMAND_REQUEST_KIT, {})
        return
    end

    ASK.grantToPlayer(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)

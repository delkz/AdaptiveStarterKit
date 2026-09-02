local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Server.lua")
end

local function onClientCommand(module, command, player, _args)
    if module ~= ASK.MOD_ID or command ~= ASK.COMMAND_REQUEST_KIT then return end
    if not player then return end

    ASK.grantToPlayer(player)
end

Events.OnClientCommand.Add(onClientCommand)

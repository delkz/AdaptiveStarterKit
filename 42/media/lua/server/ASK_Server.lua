local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Server.lua")
end

local function onClientCommand(module, command, player, _args)
    if module ~= ASK.MOD_ID then return end
    if not player then return end

    if command == ASK.COMMAND_REQUEST_KIT then
        ASK.grantToPlayer(player)
        return
    end

    local config = ASK.getSettings()
    if not config.debug then return end

    if command == ASK.COMMAND_RESET_KIT then
        ASK.resetPlayerGrant(player)
        ASK.log(config, "Reset grant flag for player.")
        return
    end

    if command == ASK.COMMAND_FORCE_KIT then
        ASK.grantToPlayer(player, _args and _args.tier or 1)
    end
end

Events.OnClientCommand.Add(onClientCommand)

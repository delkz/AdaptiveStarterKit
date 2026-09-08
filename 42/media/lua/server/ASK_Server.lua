local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Server.lua")
end

local function onClientCommand(module, command, player, _args)
    if module ~= ASK.MOD_ID then return end
    ASK.log(nil, "OnClientCommand: command=" .. tostring(command) .. ", player=" .. tostring(player)
        .. ", requestedTier=" .. tostring(_args and _args.tier))
    if not player then ASK.log(nil, "Command ignored: no player."); return end

    if command == ASK.COMMAND_REQUEST_KIT then
        ASK.log(nil, "Server grant returned=" .. tostring(ASK.grantToPlayer(player)))
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
        ASK.log(config, "Forced server grant returned=" .. tostring(ASK.grantToPlayer(player, _args and _args.tier or 1)))
    else
        ASK.log(config, "Unknown command ignored: " .. tostring(command))
    end
end

Events.OnClientCommand.Add(onClientCommand)
ASK.log(nil, "Server handler registered: OnClientCommand.")

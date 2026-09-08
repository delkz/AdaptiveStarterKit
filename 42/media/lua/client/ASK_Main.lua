local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Main.lua")
end

local function onCreatePlayer(_playerIndex, player)
    ASK.log(nil, "OnCreatePlayer: index=" .. tostring(_playerIndex) .. ", player=" .. tostring(player))
    if not player then return end

    if isClient and isClient() then
        ASK.log(nil, "Sending RequestKit to server.")
        sendClientCommand(player, ASK.MOD_ID, ASK.COMMAND_REQUEST_KIT, {})
        ASK.log(nil, "RequestKit sent; awaiting server processing.")
        return
    end

    ASK.log(nil, "Local grant returned=" .. tostring(ASK.grantToPlayer(player)))
end

local function onServerCommand(module, command, args)
    if module ~= ASK.MOD_ID or command ~= ASK.COMMAND_SHOW_MESSAGE then return end
    ASK.log(nil, "OnServerCommand: command=" .. tostring(command) .. ", message=" .. tostring(args and args.message))

    ASK.showPlayerMessage(getPlayer(), args and args.message)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnServerCommand.Add(onServerCommand)
ASK.log(nil, "Client handlers registered: OnCreatePlayer, OnServerCommand.")

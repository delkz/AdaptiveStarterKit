local ASK = {
    MOD_ID = "AdaptiveStarterKit",
    COMMAND_REQUEST_KIT = "RequestKit",
    COMMAND_RESET_KIT = "ResetKit",
    COMMAND_FORCE_KIT = "ForceKit",
    COMMAND_SHOW_MESSAGE = "ShowMessage",
    GRANTED_KEY = "AdaptiveStarterKitGranted",
    KITS = {},
}

local DEFAULT_THRESHOLDS = { 4, 8, 15, 31, 61 }
local MINIMUM_THRESHOLDS = { 0, 1, 2, 3, 4 }
local DIFFICULTY = {
    HARSH = 1,
    BALANCED = 2,
    GENEROUS = 3,
}

local function numberOrDefault(value, fallback)
    return tonumber(value) or fallback
end

local function clamp(value, minimum, maximum)
    return math.min(maximum, math.max(minimum, value))
end

local function normalizedThresholds(root)
    local thresholds = {
        math.max(MINIMUM_THRESHOLDS[1], numberOrDefault(root.Tier2Day, DEFAULT_THRESHOLDS[1])),
        math.max(MINIMUM_THRESHOLDS[2], numberOrDefault(root.Tier3Day, DEFAULT_THRESHOLDS[2])),
        math.max(MINIMUM_THRESHOLDS[3], numberOrDefault(root.Tier4Day, DEFAULT_THRESHOLDS[3])),
        math.max(MINIMUM_THRESHOLDS[4], numberOrDefault(root.Tier5Day, DEFAULT_THRESHOLDS[4])),
        math.max(MINIMUM_THRESHOLDS[5], numberOrDefault(root.Tier6Day, DEFAULT_THRESHOLDS[5])),
    }

    for index = 2, #thresholds do
        if thresholds[index] <= thresholds[index - 1] then
            thresholds[index] = thresholds[index - 1] + 1
        end
    end

    return thresholds
end

local function applyDifficultyPreset(config)
    if config.difficultyPreset == DIFFICULTY.HARSH then
        config.multiplier = clamp(config.multiplier * 0.75, 0.5, 3.0)
        config.firearmChance = clamp(math.floor(config.firearmChance * 0.5), 0, 100)
        config.roughItemChance = 85
        return config
    end

    if config.difficultyPreset == DIFFICULTY.GENEROUS then
        config.multiplier = clamp(config.multiplier * 1.35, 0.5, 3.0)
        config.firearmChance = clamp(math.floor(config.firearmChance * 1.5), 0, 100)
        config.roughItemChance = 35
        return config
    end

    config.roughItemChance = 60
    return config
end

function ASK.getSettings()
    local root = SandboxVars and SandboxVars.AdaptiveStarterKit or {}
    return applyDifficultyPreset({
        enabled = root.Enabled ~= false,
        difficultyPreset = clamp(numberOrDefault(root.DifficultyPreset, DIFFICULTY.BALANCED), DIFFICULTY.HARSH, DIFFICULTY.GENEROUS),
        equipBackpack = root.EquipBackpack ~= false,
        professionTweaks = root.ProfessionTweaks ~= false,
        roughItems = root.RoughItems ~= false,
        showMessage = root.ShowMessage ~= false,
        thresholds = normalizedThresholds(root),
        multiplier = clamp(numberOrDefault(root.SupplyMultiplier, 1.0), 0.5, 3.0),
        firearmChance = clamp(numberOrDefault(root.FirearmChance, 10), 0, 100),
        debug = root.Debug == true,
    })
end

function ASK.log(config, message)
    config = config or (ASK._grantContext and ASK._grantContext.config) or ASK.getSettings()
    if config.debug then
        ASK._logSequence = (ASK._logSequence or 0) + 1
        local side = isServer and isServer() and "server" or (isClient and isClient() and "client" or "singleplayer")
        local context = ASK._grantContext
        print("[AdaptiveStarterKit] [" .. side .. "] [step=" .. ASK._logSequence
            .. (context and " grant=" .. context.id or "") .. "] " .. message)
    end
end

local function isMultiplayerServer()
    return isServer and isServer()
end

local function transmitAddedItem(inventory, item)
    if item and isMultiplayerServer() and sendAddItemToContainer then
        ASK.log(nil, "Sync item: sending container update.")
        sendAddItemToContainer(inventory, item)
        ASK.log(nil, "Sync item: container update sent (not a client acknowledgement).")
    else
        ASK.log(nil, "Sync item skipped: item=" .. tostring(item ~= nil)
            .. ", server=" .. tostring(isMultiplayerServer()) .. ", API=" .. tostring(sendAddItemToContainer ~= nil))
    end
end

local function recordGrantedItem(item, destination)
    if not ASK._grantContext or not item then return end

    local fullType = item.getFullType and item:getFullType() or tostring(item)
    table.insert(ASK._grantContext.items, {
        fullType = fullType,
        destination = destination or "inventory",
    })
end

function ASK.beginGrantContext(config, tier, worldDay, player)
    ASK._grantSequence = (ASK._grantSequence or 0) + 1
    ASK._grantContext = {
        id = ASK._grantSequence,
        attempted = 0,
        failed = 0,
        config = config,
        tier = tier,
        worldDay = worldDay,
        profession = ASK.getProfession(player) or "unknown",
        items = {},
    }
end

function ASK.clearGrantContext()
    ASK._grantContext = nil
end

local function summarizeGrantedItems()
    if not ASK._grantContext then return "none" end
    if #ASK._grantContext.items == 0 then return "none" end

    local parts = {}
    for _, entry in ipairs(ASK._grantContext.items) do
        table.insert(parts, entry.fullType .. "@" .. entry.destination)
    end

    return table.concat(parts, ", ")
end

local function hasGrantedItems()
    return ASK._grantContext and #ASK._grantContext.items > 0
end

function ASK.addItem(inventory, fullType, deferTransmit)
    local context = ASK._grantContext
    if context then context.attempted = context.attempted + 1 end
    ASK.log(nil, "AddItem begin: type=" .. tostring(fullType)
        .. ", destination=" .. (inventory == ASK._packedInventory and "backpack" or "inventory")
        .. ", containerAvailable=" .. tostring(inventory ~= nil) .. ", deferSync=" .. tostring(deferTransmit == true))
    local ok, item = pcall(function()
        return inventory:AddItem(fullType)
    end)

    if not ok or not item then
        if context then context.failed = context.failed + 1 end
        print("[AdaptiveStarterKit] Could not add item: " .. tostring(fullType)
            .. "; reason=" .. (ok and "AddItem returned nil" or tostring(item)))
        return nil
    end

    ASK.log(nil, "AddItem success: requested=" .. tostring(fullType))

    if not deferTransmit then
        transmitAddedItem(inventory, item)
    end

    recordGrantedItem(item, inventory == ASK._packedInventory and "backpack" or "inventory")
    return item
end

local function randomFloat(minimum, maximum)
    return minimum + (ZombRandFloat(0.0, 1.0) * (maximum - minimum))
end

function ASK.addUsed(inventory, fullType, minimumUses, maximumUses, config)
    config = config or {}

    local item = ASK.addItem(inventory, fullType, true)
    if not item then return nil end

    if config.roughItems == true and ASK.chance(config.roughItemChance) and item.setUsedDelta then
        local minimum = clamp(numberOrDefault(minimumUses, 0.25), 0, 1)
        local maximum = clamp(numberOrDefault(maximumUses, 0.85), minimum, 1)
        local delta = randomFloat(minimum, maximum)
        ASK.log(config, "Used supply: type=" .. fullType .. ", min=" .. minimum .. ", max=" .. maximum .. ", delta=" .. delta)
        item:setUsedDelta(delta)
    else
        ASK.log(config, "Used supply unchanged: type=" .. fullType .. ", roughItems=" .. tostring(config.roughItems)
            .. ", setterAvailable=" .. tostring(item.setUsedDelta ~= nil) .. "; disabled, roll rejected, or unsupported.")
    end

    transmitAddedItem(inventory, item)
    return item
end

local function getBackItem(player)
    if player and player.getClothingItem_Back then
        return player:getClothingItem_Back()
    end

    return nil
end

local function setBackItem(player, item)
    if player.setClothingItem_Back then
        player:setClothingItem_Back(item)
        return true
    end

    if player.setWornItem then
        player:setWornItem("Back", item)
        return true
    end

    return false
end

function ASK.addBackpack(player, inventory, fullType, config)
    config = config or {}

    local item = ASK.addItem(inventory, fullType, true)
    if not item then return nil end

    if item.getInventory then
        config.backpackInventory = item:getInventory()
        ASK._packedInventory = config.backpackInventory
    end
    ASK.log(config, "Backpack container available=" .. tostring(config.backpackInventory ~= nil))

    if not config.equipBackpack then
        ASK.log(config, "Backpack equip skipped: disabled in settings.")
        transmitAddedItem(inventory, item)
        return item
    end

    if getBackItem(player) then
        ASK.log(config, "Back slot already occupied; leaving " .. fullType .. " in inventory.")
        transmitAddedItem(inventory, item)
        return item
    end

    local ok, equipped = pcall(function()
        return setBackItem(player, item)
    end)

    if ok and equipped then
        ASK.log(config, "Equipped " .. fullType .. " on the player's back.")
    else
        ASK.log(config, "Could not equip " .. fullType .. "; leaving it in inventory. result=" .. tostring(equipped))
    end

    transmitAddedItem(inventory, item)
    return item
end

local function getPackedInventory(config, fallbackInventory)
    return config and config.backpackInventory or fallbackInventory
end

function ASK.addPackedItem(config, fallbackInventory, fullType)
    return ASK.addItem(getPackedInventory(config, fallbackInventory), fullType)
end

function ASK.addPackedUsed(config, fallbackInventory, fullType, minimumUses, maximumUses)
    return ASK.addUsed(getPackedInventory(config, fallbackInventory), fullType, minimumUses, maximumUses, config)
end

function ASK.addWorn(inventory, fullType, minimumCondition, maximumCondition)
    local item = ASK.addItem(inventory, fullType, true)
    if not item or not item.getConditionMax or not item.setCondition then
        ASK.log(nil, "Wear skipped: item absent or condition API unavailable; type=" .. tostring(fullType))
        transmitAddedItem(inventory, item)
        return item
    end

    local maxCondition = item:getConditionMax()
    if maxCondition and maxCondition > 0 then
        local minimumRatio = clamp(numberOrDefault(minimumCondition, 0.25), 0, 1)
        local maximumRatio = clamp(numberOrDefault(maximumCondition, 0.75), minimumRatio, 1)
        local low = math.max(1, math.floor(maxCondition * minimumRatio))
        local high = math.max(low, math.floor(maxCondition * maximumRatio))
        local condition = ZombRand(low, high + 1)
        ASK.log(nil, "Wear: type=" .. fullType .. ", maxCondition=" .. maxCondition .. ", low=" .. low .. ", high=" .. high .. ", selected=" .. condition)
        item:setCondition(condition)
    else
        ASK.log(nil, "Wear skipped: non-positive maximum condition for " .. fullType)
    end

    transmitAddedItem(inventory, item)
    return item
end

function ASK.addRepeated(inventory, fullType, baseAmount, multiplier)
    local amount = numberOrDefault(baseAmount, 1) * numberOrDefault(multiplier, 1)
    local count = math.max(1, math.floor(amount + 0.5))
    ASK.log(nil, "Repeated item: type=" .. fullType .. ", base=" .. tostring(baseAmount)
        .. ", multiplier=" .. tostring(multiplier) .. ", finalCount=" .. count)

    for _ = 1, count do
        ASK.addItem(inventory, fullType)
    end
end

function ASK.addPackedRepeated(config, fallbackInventory, fullType, baseAmount)
    config = config or {}
    ASK.addRepeated(getPackedInventory(config, fallbackInventory), fullType, baseAmount, config.multiplier or 1)
end

function ASK.chance(percent)
    local normalizedPercent = clamp(numberOrDefault(percent, 0), 0, 100)
    local roll = normalizedPercent > 0 and ZombRand(100) or nil
    local passed = roll ~= nil and roll < normalizedPercent
    ASK.log(nil, "Chance: requested=" .. tostring(percent) .. ", normalized=" .. normalizedPercent
        .. ", roll(0-99)=" .. tostring(roll) .. ", passed=" .. tostring(passed))
    return passed
end

function ASK.getProfession(player)
    if not player or not player.getDescriptor then return nil end

    local descriptor = player:getDescriptor()
    if not descriptor or not descriptor.getCharacterProfession then return nil end

    local profession = descriptor:getCharacterProfession()
    if not profession then return nil end

    if type(profession) == "string" then
        return profession
    end

    if profession.getName then
        return tostring(profession:getName())
    end

    if profession.getType then
        return tostring(profession:getType())
    end

    return tostring(profession)
end

function ASK.showPlayerMessage(player, message)
    ASK.log(nil, "Show message: playerAvailable=" .. tostring(player ~= nil) .. ", text=" .. tostring(message))
    if not player or not message then return end

    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, message)
        ASK.log(nil, "Message displayed through HaloTextHelper.")
        return
    end

    if player.Say then
        player:Say(message)
        ASK.log(nil, "Message displayed through Say fallback.")
    else
        ASK.log(nil, "Message skipped: no display API available.")
    end
end

local function notifyPlayer(player, config, message)
    if not config.showMessage then
        ASK.log(config, "Notification skipped: ShowMessage disabled.")
        return
    end

    if isMultiplayerServer() and sendServerCommand then
        sendServerCommand(player, ASK.MOD_ID, ASK.COMMAND_SHOW_MESSAGE, { message = message })
        ASK.log(config, "Notification command sent to client.")
        return
    end

    ASK.showPlayerMessage(player, message)
end

local function resolveTier(day, thresholds)
    local tier = 1
    for index, threshold in ipairs(thresholds) do
        if day >= threshold then
            tier = index + 1
        end
    end
    return tier
end

function ASK.resetPlayerGrant(player)
    ASK.log(nil, "Reset requested: playerAvailable=" .. tostring(player ~= nil))
    if not player then return false end

    local modData = player:getModData()
    ASK.log(nil, "Reset grant flag: previous=" .. tostring(modData[ASK.GRANTED_KEY]))
    modData[ASK.GRANTED_KEY] = nil
    if player.transmitModData then
        player:transmitModData()
    end

    return true
end

function ASK.debugReset(player)
    local config = ASK.getSettings()
    if not config.debug then
        print("[AdaptiveStarterKit] Enable Debug in Sandbox options before using test commands.")
        return false
    end

    if isClient and isClient() and sendClientCommand then
        sendClientCommand(player, ASK.MOD_ID, ASK.COMMAND_RESET_KIT, {})
        return true
    end

    return ASK.resetPlayerGrant(player)
end

function ASK.debugGrantTier(player, tier)
    local config = ASK.getSettings()
    if not config.debug then
        print("[AdaptiveStarterKit] Enable Debug in Sandbox options before using test commands.")
        return false
    end

    local normalizedTier = clamp(numberOrDefault(tier, 1), 1, #ASK.KITS)
    if isClient and isClient() and sendClientCommand then
        sendClientCommand(player, ASK.MOD_ID, ASK.COMMAND_FORCE_KIT, { tier = normalizedTier })
        return true
    end

    return ASK.grantToPlayer(player, normalizedTier)
end

local function describeDifficulty(config)
    if config.difficultyPreset == DIFFICULTY.HARSH then return "Harsh" end
    if config.difficultyPreset == DIFFICULTY.GENEROUS then return "Generous" end

    return "Balanced"
end

local function finishGrant(player, config, granted)
    if not ASK._grantContext then return end

    local context = ASK._grantContext
    ASK.log(config, "Kit summary: tier=" .. context.tier
        .. ", completed=" .. tostring(granted) .. ", attempted=" .. context.attempted
        .. ", failed=" .. context.failed .. ", added=" .. #context.items
        .. ", day=" .. context.worldDay
        .. ", preset=" .. describeDifficulty(config)
        .. ", profession=" .. context.profession
        .. ", items=" .. summarizeGrantedItems())

    if granted and hasGrantedItems() then
        notifyPlayer(player, config, "You start with a few scavenged supplies.")
    else
        ASK.log(config, "Notification skipped: kit failed or no items added.")
    end

    ASK.log(config, "Grant finished; clearing temporary context. Grant flag remains set, including empty/partial kits.")
    ASK.clearGrantContext()
    ASK._packedInventory = nil
end

function ASK.grantToPlayer(player, forcedTier)
    local config = ASK.getSettings()
    ASK.log(config, "Grant requested: player=" .. tostring(player) .. ", forcedTier=" .. tostring(forcedTier))
    if not player then ASK.log(config, "Grant skipped: no player."); return false end
    if not config.enabled then ASK.log(config, "Grant skipped: mod disabled."); return false end
    ASK.log(config, "Effective settings: preset=" .. config.difficultyPreset .. ", multiplier=" .. config.multiplier
        .. ", thresholds=" .. table.concat(config.thresholds, ",") .. ", firearmChance=" .. config.firearmChance
        .. ", roughItems=" .. tostring(config.roughItems) .. ", roughItemChance=" .. config.roughItemChance
        .. ", equipBackpack=" .. tostring(config.equipBackpack) .. ", professionTweaks=" .. tostring(config.professionTweaks)
        .. ", showMessage=" .. tostring(config.showMessage))

    local modData = player:getModData()
    ASK.log(config, "Existing grant flag=" .. tostring(modData[ASK.GRANTED_KEY]))
    if modData[ASK.GRANTED_KEY] and not forcedTier then
        ASK.log(config, "Player already received a kit; skipping.")
        return false
    end

    -- Mark first so a partial item error cannot be exploited by reconnecting.
    modData[ASK.GRANTED_KEY] = true
    ASK.log(config, "Grant flag set before item creation to prevent duplicate grants after partial failure.")
    if player.transmitModData then
        player:transmitModData()
        ASK.log(config, "Grant flag transmission requested.")
    end

    local worldHours = getGameTime():getWorldAgeHours()
    local worldDay = math.max(0, math.floor(worldHours / 24))
    local tier = forcedTier and clamp(numberOrDefault(forcedTier, 1), 1, #ASK.KITS) or resolveTier(worldDay, config.thresholds)
    local inventory = player:getInventory()
    local kit = ASK.KITS[tier] or ASK.KITS[1]

    ASK.log(config, "Granting tier " .. tier .. " on world day " .. worldDay .. ".")
    ASK.beginGrantContext(config, tier, worldDay, player)
    ASK.log(config, "Resolved kit: worldHours=" .. tostring(worldHours) .. ", day=" .. worldDay
        .. ", tier=" .. tier .. ", profession=" .. ASK._grantContext.profession
        .. ", inventoryAvailable=" .. tostring(inventory ~= nil) .. ", kitAvailable=" .. tostring(kit ~= nil))
    if tier == 1 then ASK.log(config, "Tier 1 intentionally grants no items (early-world empty kit).") end
    if kit then
        local ok, errorMessage = pcall(function()
            kit(player, inventory, config)
        end)

        if not ok then
            print("[AdaptiveStarterKit] Error while granting kit: " .. tostring(errorMessage))
            finishGrant(player, config, false)
            return false
        end
    else
        ASK.log(config, "No kit function available; no items can be added.")
    end
    finishGrant(player, config, true)
    return true
end

AdaptiveStarterKit = ASK

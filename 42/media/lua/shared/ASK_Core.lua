local ASK = {
    MOD_ID = "AdaptiveStarterKit",
    COMMAND_REQUEST_KIT = "RequestKit",
    GRANTED_KEY = "AdaptiveStarterKitGranted",
    KITS = {},
}

local DEFAULT_THRESHOLDS = { 4, 8, 15, 31, 61 }
local MINIMUM_THRESHOLDS = { 0, 1, 2, 3, 4 }

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

function ASK.getSettings()
    local root = SandboxVars and SandboxVars.AdaptiveStarterKit or {}
    return {
        enabled = root.Enabled ~= false,
        thresholds = normalizedThresholds(root),
        multiplier = clamp(numberOrDefault(root.SupplyMultiplier, 1.0), 0.5, 3.0),
        firearmChance = clamp(numberOrDefault(root.FirearmChance, 10), 0, 100),
        debug = root.Debug == true,
    }
end

function ASK.log(config, message)
    if config.debug then
        print("[AdaptiveStarterKit] " .. message)
    end
end

local function isMultiplayerServer()
    return isServer and isServer()
end

local function transmitAddedItem(inventory, item)
    if item and isMultiplayerServer() and sendAddItemToContainer then
        sendAddItemToContainer(inventory, item)
    end
end

function ASK.addItem(inventory, fullType, deferTransmit)
    local ok, item = pcall(function()
        return inventory:AddItem(fullType)
    end)

    if not ok or not item then
        print("[AdaptiveStarterKit] Could not add item: " .. tostring(fullType))
        return nil
    end

    if not deferTransmit then
        transmitAddedItem(inventory, item)
    end

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
    local item = ASK.addItem(inventory, fullType, true)
    if not item then return nil end

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
        ASK.log(config, "Could not equip " .. fullType .. "; leaving it in inventory.")
    end

    transmitAddedItem(inventory, item)
    return item
end

function ASK.addWorn(inventory, fullType, minimumCondition, maximumCondition)
    local item = ASK.addItem(inventory, fullType, true)
    if not item or not item.getConditionMax or not item.setCondition then
        transmitAddedItem(inventory, item)
        return item
    end

    local maxCondition = item:getConditionMax()
    if maxCondition and maxCondition > 0 then
        local minimumRatio = clamp(numberOrDefault(minimumCondition, 0.25), 0, 1)
        local maximumRatio = clamp(numberOrDefault(maximumCondition, 0.75), minimumRatio, 1)
        local low = math.max(1, math.floor(maxCondition * minimumRatio))
        local high = math.max(low, math.floor(maxCondition * maximumRatio))
        item:setCondition(ZombRand(low, high + 1))
    end

    transmitAddedItem(inventory, item)
    return item
end

function ASK.addRepeated(inventory, fullType, baseAmount, multiplier)
    local amount = numberOrDefault(baseAmount, 1) * numberOrDefault(multiplier, 1)
    local count = math.max(1, math.floor(amount + 0.5))

    for _ = 1, count do
        ASK.addItem(inventory, fullType)
    end
end

function ASK.chance(percent)
    local normalizedPercent = clamp(numberOrDefault(percent, 0), 0, 100)
    return normalizedPercent > 0 and ZombRand(100) < normalizedPercent
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

function ASK.grantToPlayer(player)
    if not player then return false end

    local config = ASK.getSettings()
    if not config.enabled then return false end

    local modData = player:getModData()
    if modData[ASK.GRANTED_KEY] then
        ASK.log(config, "Player already received a kit; skipping.")
        return false
    end

    -- Mark first so a partial item error cannot be exploited by reconnecting.
    modData[ASK.GRANTED_KEY] = true
    if player.transmitModData then
        player:transmitModData()
    end

    local worldHours = getGameTime():getWorldAgeHours()
    local worldDay = math.max(0, math.floor(worldHours / 24))
    local tier = resolveTier(worldDay, config.thresholds)
    local inventory = player:getInventory()
    local kit = ASK.KITS[tier] or ASK.KITS[1]

    ASK.log(config, "Granting tier " .. tier .. " on world day " .. worldDay .. ".")
    if kit then
        kit(player, inventory, config)
    end
    return true
end

AdaptiveStarterKit = ASK

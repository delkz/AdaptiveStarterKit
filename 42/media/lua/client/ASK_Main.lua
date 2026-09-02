local ASK = {}

local function settings()
    local root = SandboxVars and SandboxVars.AdaptiveStarterKit or {}
    return {
        enabled = root.Enabled ~= false,
        thresholds = {
            tonumber(root.Tier2Day) or 4,
            tonumber(root.Tier3Day) or 8,
            tonumber(root.Tier4Day) or 15,
            tonumber(root.Tier5Day) or 31,
            tonumber(root.Tier6Day) or 61,
        },
        multiplier = tonumber(root.SupplyMultiplier) or 1.0,
        firearmChance = tonumber(root.FirearmChance) or 10,
        debug = root.Debug == true,
    }
end

local function log(config, message)
    if config.debug then
        print("[AdaptiveStarterKit] " .. message)
    end
end

local function safeAdd(inventory, fullType)
    local ok, item = pcall(function()
        return inventory:AddItem(fullType)
    end)
    if not ok or not item then
        print("[AdaptiveStarterKit] Could not add item: " .. tostring(fullType))
        return nil
    end
    return item
end

local function addWorn(inventory, fullType, minimumCondition, maximumCondition)
    local item = safeAdd(inventory, fullType)
    if not item or not item.getConditionMax or not item.setCondition then
        return item
    end

    local maxCondition = item:getConditionMax()
    if maxCondition and maxCondition > 0 then
        local low = math.max(1, math.floor(maxCondition * minimumCondition))
        local high = math.max(low, math.floor(maxCondition * maximumCondition))
        item:setCondition(ZombRand(low, high + 1))
    end
    return item
end

local function addRepeated(inventory, fullType, baseAmount, multiplier)
    local count = math.max(1, math.floor((baseAmount * multiplier) + 0.5))
    for _ = 1, count do
        safeAdd(inventory, fullType)
    end
end

local function chance(percent)
    return percent > 0 and ZombRand(100) < percent
end

local kits = {
    [1] = function() end,

    [2] = function(inventory, config)
        safeAdd(inventory, "Base.WaterBottleFull")
        if chance(65) then safeAdd(inventory, "Base.Crisps") end
    end,

    [3] = function(inventory, config)
        safeAdd(inventory, "Base.Bag_Schoolbag")
        safeAdd(inventory, "Base.WaterBottleFull")
        safeAdd(inventory, "Base.CannedBeans")
        addWorn(inventory, chance(50) and "Base.Hammer" or "Base.RollingPin", 0.30, 0.65)
    end,

    [4] = function(inventory, config)
        safeAdd(inventory, "Base.Bag_Schoolbag")
        safeAdd(inventory, "Base.WaterBottleFull")
        addRepeated(inventory, "Base.CannedBeans", 1, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 2, config.multiplier)
        safeAdd(inventory, "Base.Lighter")
        addWorn(inventory, chance(50) and "Base.Hammer" or "Base.MetalBar", 0.30, 0.70)
    end,

    [5] = function(inventory, config)
        safeAdd(inventory, "Base.Bag_DuffelBagTINT")
        safeAdd(inventory, "Base.WaterBottleFull")
        addRepeated(inventory, "Base.CannedBeans", 2, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 2, config.multiplier)
        safeAdd(inventory, "Base.Lighter")
        safeAdd(inventory, chance(50) and "Base.Screwdriver" or "Base.Wrench")
        addWorn(inventory, chance(50) and "Base.HandAxe" or "Base.MetalPipe", 0.25, 0.65)
    end,

    [6] = function(inventory, config)
        safeAdd(inventory, "Base.Bag_DuffelBagTINT")
        safeAdd(inventory, "Base.WaterBottleFull")
        addRepeated(inventory, "Base.CannedBeans", 2, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 3, config.multiplier)
        safeAdd(inventory, "Base.Lighter")
        safeAdd(inventory, "Base.Screwdriver")
        safeAdd(inventory, chance(50) and "Base.Wrench" or "Base.CanOpener")
        addWorn(inventory, chance(50) and "Base.HandAxe" or "Base.Crowbar", 0.20, 0.60)

        if chance(config.firearmChance) then
            addWorn(inventory, "Base.Pistol", 0.25, 0.60)
        end
    end,
}

local function resolveTier(day, thresholds)
    local tier = 1
    for index, threshold in ipairs(thresholds) do
        if day >= threshold then
            tier = index + 1
        end
    end
    return tier
end

function ASK.onCreatePlayer(playerIndex, player)
    if not player then return end

    local config = settings()
    if not config.enabled then return end

    local modData = player:getModData()
    if modData.AdaptiveStarterKitGranted then
        log(config, "Player already received a kit; skipping.")
        return
    end

    -- Mark first so a partial item error cannot be exploited by reconnecting.
    modData.AdaptiveStarterKitGranted = true

    local worldHours = getGameTime():getWorldAgeHours()
    local worldDay = math.max(0, math.floor(worldHours / 24))
    local tier = resolveTier(worldDay, config.thresholds)
    local inventory = player:getInventory()

    log(config, "Granting tier " .. tier .. " on world day " .. worldDay .. ".")
    kits[tier](inventory, config)
end

Events.OnCreatePlayer.Add(ASK.onCreatePlayer)


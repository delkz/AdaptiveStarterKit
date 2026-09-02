local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Kits.lua")
end

local add = ASK.addItem
local addBackpack = ASK.addBackpack
local addWorn = ASK.addWorn
local addRepeated = ASK.addRepeated
local chance = ASK.chance

ASK.KITS = {
    [1] = function() end,

    [2] = function(_player, inventory)
        add(inventory, "Base.WaterBottle")
        if chance(65) then add(inventory, "Base.Crisps") end
    end,

    [3] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_Schoolbag", config)
        add(inventory, "Base.WaterBottle")
        add(inventory, "Base.TinnedBeans")
        addWorn(inventory, chance(50) and "Base.Hammer" or "Base.RollingPin", 0.30, 0.65)
    end,

    [4] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_Schoolbag", config)
        add(inventory, "Base.WaterBottle")
        addRepeated(inventory, "Base.TinnedBeans", 1, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 2, config.multiplier)
        add(inventory, "Base.Lighter")
        addWorn(inventory, chance(50) and "Base.Hammer" or "Base.MetalBar", 0.30, 0.70)
    end,

    [5] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_DuffelBagTINT", config)
        add(inventory, "Base.WaterBottle")
        addRepeated(inventory, "Base.TinnedBeans", 2, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 2, config.multiplier)
        add(inventory, "Base.Lighter")
        add(inventory, chance(50) and "Base.Screwdriver" or "Base.Wrench")
        addWorn(inventory, chance(50) and "Base.HandAxe" or "Base.MetalPipe", 0.25, 0.65)
    end,

    [6] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_DuffelBagTINT", config)
        add(inventory, "Base.WaterBottle")
        addRepeated(inventory, "Base.TinnedBeans", 2, config.multiplier)
        addRepeated(inventory, "Base.Bandage", 3, config.multiplier)
        add(inventory, "Base.Lighter")
        add(inventory, "Base.Screwdriver")
        add(inventory, chance(50) and "Base.Wrench" or "Base.TinOpener")
        addWorn(inventory, chance(50) and "Base.HandAxe" or "Base.Crowbar", 0.20, 0.60)

        if chance(config.firearmChance) then
            addWorn(inventory, "Base.Pistol", 0.25, 0.60)
        end
    end,
}

local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_Kits.lua")
end

if not ASK.KIT_POOLS or not ASK.KIT_UTILS or not ASK.addProfessionTouch then
    error("[AdaptiveStarterKit] ASK_KitData.lua and ASK_KitProfession.lua must be loaded before ASK_Kits.lua")
end

local addBackpack = ASK.addBackpack
local addPacked = ASK.addPackedItem
local addPackedUsed = ASK.addPackedUsed
local addWorn = ASK.addWorn
local chance = ASK.chance
local pools = ASK.KIT_POOLS
local utils = ASK.KIT_UTILS

ASK.KITS = {
    [1] = function() end,

    [2] = function(_player, inventory, config)
        addPackedUsed(config, inventory, "Base.WaterBottle", 0.35, 0.90)
        if chance(65) then utils.addPackedOneOf(config, inventory, pools.snacks) end
    end,

    [3] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_Schoolbag", config)
        addPackedUsed(config, inventory, "Base.WaterBottle", 0.35, 0.90)
        utils.addPackedFood(config, inventory, true)
        if chance(30) then utils.addPackedOneOf(config, inventory, pools.cannedFood) end
        addWorn(inventory, utils.pick(pools.basicWeapons), 0.30, 0.65)
        ASK.addProfessionTouch(player, inventory, config, 3)
    end,

    [4] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_Schoolbag", config)
        addPackedUsed(config, inventory, "Base.WaterBottle", 0.30, 0.85)
        utils.addPackedFood(config, inventory)
        ASK.addPackedRepeated(config, inventory, "Base.Bandage", 2)
        if chance(70) then addPackedUsed(config, inventory, "Base.Lighter", 0.20, 0.75) end
        if chance(35) then addPacked(config, inventory, "Base.TinOpener") end
        addWorn(inventory, utils.pick(pools.midWeapons), 0.30, 0.70)
        ASK.addProfessionTouch(player, inventory, config, 4)
    end,

    [5] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_DuffelBagTINT", config)
        addPackedUsed(config, inventory, "Base.WaterBottle", 0.25, 0.80)
        ASK.addPackedRepeated(config, inventory, "Base.TinnedBeans", 2)
        ASK.addPackedRepeated(config, inventory, "Base.Bandage", 2)
        if chance(85) then addPackedUsed(config, inventory, "Base.Lighter", 0.20, 0.75) end
        utils.addPackedOneOf(config, inventory, pools.tools)
        addWorn(inventory, chance(25) and "Base.HandAxe" or utils.pick(pools.midWeapons), 0.25, 0.65)
        ASK.addProfessionTouch(player, inventory, config, 5)
    end,

    [6] = function(player, inventory, config)
        addBackpack(player, inventory, "Base.Bag_DuffelBagTINT", config)
        addPackedUsed(config, inventory, "Base.WaterBottle", 0.25, 0.80)
        ASK.addPackedRepeated(config, inventory, "Base.TinnedBeans", 2)
        ASK.addPackedRepeated(config, inventory, "Base.Bandage", 3)
        addPackedUsed(config, inventory, "Base.Lighter", 0.20, 0.75)
        utils.addPackedOneOf(config, inventory, pools.tools)
        utils.addPackedOneOf(config, inventory, pools.tools)
        addWorn(inventory, utils.pick(pools.lateWeapons), 0.20, 0.60)
        ASK.addProfessionTouch(player, inventory, config, 6)

        if chance(ASK.getProfessionFirearmChance(player, config)) then
            addWorn(inventory, "Base.Pistol", 0.25, 0.60)
        end
    end,
}

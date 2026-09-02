local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_KitData.lua")
end

ASK.KIT_POOLS = {
    snacks = {
        "Base.BeefJerky",
        "Base.Chocolate",
        "Base.Crisps",
        "Base.Crisps2",
        "Base.Crisps3",
        "Base.Crisps4",
        "Base.GranolaBar",
        "Base.Peanuts",
    },

    cannedFood = {
        "Base.CannedChili",
        "Base.CannedCorn",
        "Base.CannedCornedBeef",
        "Base.CannedPeaches",
        "Base.CannedSardines",
        "Base.TinnedBeans",
        "Base.TinnedSoup",
        "Base.TunaTin",
    },

    basicWeapons = {
        "Base.Hammer",
        "Base.RollingPin",
    },

    midWeapons = {
        "Base.Hammer",
        "Base.MetalBar",
        "Base.MetalPipe",
    },

    lateWeapons = {
        "Base.MetalPipe",
        "Base.Crowbar",
        "Base.HandAxe",
    },

    tools = {
        "Base.Screwdriver",
        "Base.Wrench",
        "Base.TinOpener",
    },
}

ASK.KIT_UTILS = {}

function ASK.KIT_UTILS.pick(items)
    return items[ZombRand(#items) + 1]
end

function ASK.KIT_UTILS.addOneOf(inventory, items)
    return ASK.addItem(inventory, ASK.KIT_UTILS.pick(items))
end

function ASK.KIT_UTILS.addPackedOneOf(config, fallbackInventory, items)
    return ASK.addPackedItem(config, fallbackInventory, ASK.KIT_UTILS.pick(items))
end

function ASK.KIT_UTILS.addPackedFood(config, fallbackInventory, preferReadyToEat)
    if preferReadyToEat or ASK.chance(35) then
        return ASK.KIT_UTILS.addPackedOneOf(config, fallbackInventory, ASK.KIT_POOLS.snacks)
    end

    return ASK.KIT_UTILS.addPackedOneOf(config, fallbackInventory, ASK.KIT_POOLS.cannedFood)
end

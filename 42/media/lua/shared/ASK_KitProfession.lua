local ASK = AdaptiveStarterKit
if not ASK then
    error("[AdaptiveStarterKit] ASK_Core.lua must be loaded before ASK_KitProfession.lua")
end

if not ASK.KIT_POOLS or not ASK.KIT_UTILS then
    error("[AdaptiveStarterKit] ASK_KitData.lua must be loaded before ASK_KitProfession.lua")
end

local addWorn = ASK.addWorn
local chance = ASK.chance
local pools = ASK.KIT_POOLS
local utils = ASK.KIT_UTILS

local PROFESSION_TOUCHES = {
    burgerflipper = "cook",
    carpenter = "technical",
    chef = "cook",
    constructionworker = "technical",
    doctor = "medical",
    electrician = "technical",
    engineer = "technical",
    farmer = "outdoors",
    fireofficer = "responder",
    fisherman = "outdoors",
    lumberjack = "outdoors",
    mechanics = "technical",
    metalworker = "technical",
    nurse = "medical",
    parkranger = "outdoors",
    policeofficer = "responder",
    repairman = "technical",
    securityguard = "responder",
    veteran = "responder",
}

local function getProfessionTouch(player, config)
    if not config.professionTweaks then return nil end

    local profession = ASK.getProfession(player)
    if not profession then return nil end

    return PROFESSION_TOUCHES[string.lower(profession)]
end

local function professionTouchChance(tier)
    if tier <= 3 then return 100 end
    if tier == 4 then return 70 end
    if tier == 5 then return 30 end

    return 15
end

function ASK.addProfessionTouch(player, inventory, config, tier)
    local touch = getProfessionTouch(player, config)
    ASK.log(config, "Profession bonus: enabled=" .. tostring(config.professionTweaks)
        .. ", category=" .. tostring(touch) .. ", tier=" .. tier)
    if not touch or tier < 3 then ASK.log(config, "Profession bonus skipped: no category or tier below 3."); return end
    if not chance(professionTouchChance(tier)) then ASK.log(config, "Profession bonus skipped: chance rejected."); return end
    ASK.log(config, "Profession bonus accepted; evaluating category item rules.")

    if touch == "medical" then
        if chance(65) then ASK.addPackedItem(config, inventory, "Base.Bandage") end
        if tier >= 4 and chance(35) then ASK.addPackedUsed(config, inventory, "Base.AlcoholWipes", 0.20, 0.70) end
        return
    end

    if touch == "technical" then
        if tier >= 4 and chance(55) then utils.addPackedOneOf(config, inventory, pools.tools) end
        return
    end

    if touch == "cook" then
        if chance(55) then utils.addPackedFood(config, inventory, true) end
        if tier >= 4 and chance(25) then addWorn(inventory, "Base.KitchenKnife", 0.20, 0.55) end
        return
    end

    if touch == "outdoors" then
        if tier >= 4 and chance(45) then ASK.addPackedUsed(config, inventory, "Base.Matches", 0.20, 0.70) end
        if tier >= 5 and chance(25) then addWorn(inventory, chance(50) and "Base.FishingRod" or "Base.HandFork", 0.20, 0.55) end
        return
    end

    if touch == "responder" and tier >= 5 and chance(35) then
        addWorn(inventory, "Base.Nightstick", 0.20, 0.60)
    end
end

function ASK.getProfessionFirearmChance(player, config)
    if getProfessionTouch(player, config) == "responder" and chance(professionTouchChance(6)) then
        ASK.log(config, "Firearm chance: responder bonus applied; final=" .. math.min(100, config.firearmChance + 5))
        return math.min(100, config.firearmChance + 5)
    end

    ASK.log(config, "Firearm chance: no profession bonus; final=" .. config.firearmChance)
    return config.firearmChance
end

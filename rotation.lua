local izi = require("common/izi_sdk")
local enums = require("common/enums")
local SPELLS = require("spells")
local constants = require("constants")
local thane_rotation = require("thane")
local slayer_rotation = require("slayer")

local buffs = enums.buff_db

local rotation = {}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

---@param me game_object
---@return boolean
function rotation.is_aoe(me)
    local enemies_melee = me:get_enemies_in_melee_range(8)
    return #enemies_melee > 1
end

---@param me game_object
---@return table
function rotation.get_player_buffs(me)
    local avatar_id = SPELLS.AVATAR:id()
    local recklessness_id = SPELLS.RECKLESSNESS:id()

    return {
        enrage = me:has_buff(buffs.ENRAGE),
        enrage_remains = me:buff_remains_sec(buffs.ENRAGE),
        sudden_death = me:has_buff(buffs.SUDDEN_DEATH),
        sudden_death_stacks = me:get_buff_stacks(buffs.SUDDEN_DEATH),
        whirlwind = me:has_buff(buffs.WHIRLWIND),
        whirlwind_stacks = me:get_buff_stacks(buffs.WHIRLWIND),
        thunder_blast = me:has_buff(constants.THUNDER_BLAST),
        thunder_blast_stacks = me:get_buff_stacks(constants.THUNDER_BLAST),
        avatar = me:has_buff(avatar_id),
        avatar_remains = me:buff_remains_sec(avatar_id),
        scent_of_blood_stacks = me:get_buff_stacks(constants.SCENT_OF_BLOOD),
        recklessness = me:has_buff(recklessness_id),
        ragedrinker = me:has_buff(constants.RAGEDRINKER),
        surge_of_adrenaline = me:has_buff(constants.SURGE_OF_ADRENALINE),
    }
end

---@param target game_object
---@return table
function rotation.get_target_debuffs(target)
    return {
        rend = target:has_debuff(buffs.REND),
    }
end

---@param target game_object
---@return boolean
function rotation.is_valid_target(target)
    if not (target and target:is_valid()) then
        return false
    end
    if target:is_damage_immune(target.DMG.MAGICAL) then
        return false
    end
    if target:is_cc_weak() then
        return false
    end
    return true
end

-- ============================================
-- ROTATION LOGIC
-- ============================================

function rotation.execute_target_rotation(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat)
    local is_thane = core.spell_book.is_spell_learned(constants.LIGHTNING_STRIKES)
    
    if is_thane then
        return thane_rotation.execute(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat)
    else
        return slayer_rotation.execute(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat)
    end
end

return rotation

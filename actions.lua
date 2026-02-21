local SPELLS = require("spells")
local enums = require("common/enums")
local izi = require("common/izi_sdk")
local constants = require("constants")
local buffs = enums.buff_db

local actions = {}

-- ============================================
-- ACTION WRAPPERS
-- ============================================

---@param target game_object
---@param cooldown_toggle boolean
---@param in_combat boolean
function actions.execute_avatar(target, cooldown_toggle, in_combat)
    if not cooldown_toggle or not in_combat then
        return false
    end

    if SPELLS.AVATAR:cast_safe(target, "Single Target: Avatar") then
        return true
    end
end

---@param target game_object
---@param cooldown_toggle boolean
---@param in_combat boolean
function actions.execute_recklessness(target, cooldown_toggle, in_combat)
    if not cooldown_toggle or not in_combat then
        return false
    end

    if SPELLS.RECKLESSNESS:cast_safe(target, "Single Target: Recklessness") then
        return true
    end
end

---@param target game_object
---@param in_combat boolean
---@param target_in_melee boolean
function actions.execute_odyns_fury(target, in_combat, target_in_melee)
    if not in_combat or not target_in_melee then
        return false
    end

    if SPELLS.ODYNS_FURY:cast_safe(target, "Single Target: Odyn's Fury") then
        return true
    end
end

---@param target game_object
---@param rage_current number
---@return boolean
function actions.execute_rampage(target, rage_current)
    if rage_current >= 80 then
        if SPELLS.RAMPAGE:cast_safe(target, "Single Target: Rampage") then
            return true
        end
    end
    return false
end

---@param target game_object
---@param player_buffs table
---@param rage_current number
function actions.execute_execute(target, player_buffs, rage_current)
    if player_buffs.sudden_death and rage_current <= 100 then
        if SPELLS.EXECUTE_SUDDEN_DEATH:cast_safe(target, "Single Target: Execute - Sudden Death") then
            return true
        end
    end

    if target:get_health_percentage() < 35 and SPELLS.EXECUTE:cooldown_up() then
        if SPELLS.EXECUTE:since_last_cast() > 1 and SPELLS.EXECUTE:cast_safe(target, "Single Target: Execute") then
            return true
        end
    end

    return false
end

---@param target game_object
function actions.execute_bloodthirst(target)
    if SPELLS.BLOODTHIRST:cast_safe(target, "Single Target: Bloodthirst") then
        return true
    end
    return false
end

---@param target game_object
function actions.execute_raging_blow(target)
    if SPELLS.RAGING_BLOW:cast_safe(target, "Single Target: Raging Blow") then
        return true
    end
    return false
end

---@param target game_object
---@param in_combat boolean
---@param target_in_melee boolean
---@param aoe_active boolean
---@param player_buffs table
function actions.execute_whirlwind(target, in_combat, target_in_melee, aoe_active, player_buffs)
    if not in_combat or not target_in_melee then
        return false
    end

    local has_improved_whirlwind = core.spell_book.is_spell_learned(constants.IMPROVED_WHIRLWIND)

    if aoe_active and has_improved_whirlwind then
        local whirlwind_remaining = izi.me():buff_remains_sec(buffs.WHIRLWIND)
        if not player_buffs.whirlwind or whirlwind_remaining < 2.0 then
            if SPELLS.WHIRLWIND:cast_safe(target, "AOE: Whirlwind (Maintain Cleave)") then
                return true
            end
        end
    end

    if not aoe_active then
        if SPELLS.WHIRLWIND:cast_safe(target, "Single Target: Whirlwind") then
            return true
        end
    end
 
    return false
end

---@param target game_object
---@param in_combat boolean
---@param target_in_melee boolean
---@param target_debuffs table
function actions.execute_rend(target, in_combat, target_in_melee, target_debuffs)
    if not in_combat or not target_in_melee then
        return false
    end

    local rend_remaining = target:debuff_remains_sec(buffs.REND)
    if not target_debuffs.rend or rend_remaining <= 5.0 then
        if SPELLS.REND:cast_safe(target, "Single Target: Rend") then
            return true
        end
    end
    return false
end

---@param target game_object
function actions.execute_bloodbath(target)
    if SPELLS.BLOODBATH:cast_safe(target, "Single Target: Bloodbath") then
        return true
    end
    return false
end

---@param target game_object
---@param player_buffs table
function actions.execute_bladestorm(target, player_buffs)
    if player_buffs.enrage_remains > 1 then
        if SPELLS.BLADESTORM:cast_safe(target, "Single Target: Bladestorm") then
            return true
        end
    end
    return false
end

---@param target game_object
function actions.execute_crushing_blow(target)
    if SPELLS.CRUSHING_BLOW:cast_safe(target, "Single Target: Crushing Blow") then
        return true
    end
    return false
end

---@param target game_object
---@param player_buffs table
---@return boolean
function actions.execute_thunder_blast(target, player_buffs)
    if SPELLS.THUNDER_CLAP:cast_safe(target, "Thane: Thunder Blast") then
        return true
    end
    return false
end

---@param target game_object
---@return boolean
function actions.execute_thunder_clap(target)
    if SPELLS.THUNDER_CLAP:cast_safe(target, "Thane: Thunder Clap") then
        return true
    end
    return false
end

return actions

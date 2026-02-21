local SPELLS = require("spells")
local actions = require("actions")
local constants = require("constants")

local slayer = {}

---@param target game_object
---@param me game_object
---@param player_buffs table
---@param cooldown_toggle boolean
---@param aoe_active boolean
---@param rage_current number
---@param in_combat boolean
function slayer.execute(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat)
    local enraged_time_remaining = player_buffs.enrage_remains
    local target_in_melee = target:is_in_melee_range(10)
    local gcd = me:gcd()

    -- 1. actions.slayer=recklessness
    if actions.execute_recklessness(me, cooldown_toggle, in_combat) then
        return true
    end

    -- 2. actions.slayer+=/avatar
    if actions.execute_avatar(me, cooldown_toggle, in_combat) then
        return true
    end

    -- 3. actions.slayer+=/bloodbath
    if actions.execute_bloodbath(target) then
        return true
    end

    -- 4. actions.slayer+=/odyns_fury
    if actions.execute_odyns_fury(target, in_combat, target_in_melee) then
        return true
    end

    -- 5. actions.slayer+=/execute,if=buff.sudden_death.stack=2&buff.enrage.up
    if player_buffs.sudden_death_stacks == 2 and player_buffs.enrage then
        if SPELLS.EXECUTE_SUDDEN_DEATH:since_last_cast() > 1.0 and SPELLS.EXECUTE_SUDDEN_DEATH:cast_safe(target, "Single Target: Execute - Sudden Death (2 stacks)") then
            return true
        end
    end

    -- 6. actions.slayer+=/rampage,if=buff.enrage.remains<gcd
    if enraged_time_remaining < gcd then
        if SPELLS.RAMPAGE:cast_safe(target, "Single Target: Rampage (Maintain Enrage)") then
            return true
        end
    end

    -- 7. actions.slayer+=/whirlwind,if=active_enemies>=2&talent.improved_whirlwind&buff.whirlwind.stack=0
    if aoe_active and core.spell_book.is_spell_learned(constants.IMPROVED_WHIRLWIND) and not player_buffs.whirlwind then
        if SPELLS.WHIRLWIND:cast_safe(target, "AOE: Whirlwind (Cleave)") then
            return true
        end
    end

    -- 8. actions.slayer+=/bladestorm,if=buff.enrage.remains>1
    if actions.execute_bladestorm(target, player_buffs, in_combat) then
        return true
    end

    -- 9. actions.slayer+=/execute
    if actions.execute_execute(target, player_buffs, rage_current > 0) then
        return true
    end

    -- 10. actions.slayer+=/crushing_blow
    if actions.execute_crushing_blow(target) then
        return true
    end

    -- 11. actions.slayer+=/rampage,if=rage>115
    if rage_current > 115 then
        if SPELLS.RAMPAGE:cast_safe(target, "Single Target: Rampage (Rage Capping)") then
            return true
        end
    end

    -- 12. actions.slayer+=/bloodthirst
    if actions.execute_bloodthirst(target) then
        return true
    end

    -- 13. actions.slayer+=/rampage
    if actions.execute_rampage(target, rage_current) then
        return true
    end

    -- 14. actions.slayer+=/rend,if=dot.rend_dot.remains<6
    local rend_remaining = target:debuff_remains_sec(player_buffs.rend_id or 772) -- rend_id is usually 772, or we can get it from enums.buff_db.REND
    -- Actually, let's use the helper's pattern or enums
    -- In rotation.lua it was: local rend_remaining = target:debuff_remains_sec(buffs.REND)
    -- I should probably pass buffs or require enums here too.
    -- Wait, let's check enums in slayer.lua.
    
    -- I'll use require("common/enums").buff_db to be safe.
    local buffs = require("common/enums").buff_db
    local rend_rem = target:debuff_remains_sec(buffs.REND)

    if rend_rem < 6 and in_combat then
        if SPELLS.REND:cast_safe(target, "Single Target: Rend (Refresh)") then
            return true
        end
    end

    -- 15. actions.slayer+=/raging_blow
    if actions.execute_raging_blow(target) then
        return true
    end

    -- 16. actions.slayer+=/rend
    -- Target debuffs needed.
    local target_debuffs = { rend = target:has_debuff(buffs.REND) }
    if actions.execute_rend(target, target_debuffs, in_combat) then
        return true
    end

    -- 17. actions.slayer+=/whirlwind
    if actions.execute_whirlwind(target, in_combat, target_in_melee, aoe_active, player_buffs) then
        return true
    end

    return false
end

return slayer

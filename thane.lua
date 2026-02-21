local SPELLS = require("spells")
local actions = require("actions")
local constants = require("constants")

local thane = {}

---@param target game_object
---@param me game_object
---@param player_buffs table
---@param cooldown_toggle boolean
---@param aoe_active boolean
---@param rage_current number
---@param in_combat boolean
function thane.execute(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat)
    local enraged_time_remaining = player_buffs.enrage_remains
    local gcd = me:gcd()

    local has_improved_whirlwind = core.spell_book.is_spell_learned(constants.IMPROVED_WHIRLWIND)
    local has_vicious_contempt = core.spell_book.is_spell_learned(constants.VICIOUS_CONTEMPT)
    local has_meat_cleaver = core.spell_book.is_spell_learned(constants.MEAT_CLEAVER)
    local has_surge_of_adrenaline = core.spell_book.is_spell_learned(constants.SURGE_OF_ADRENALINE)
    local has_executioners_wrath = core.spell_book.is_spell_learned(constants.EXECUTIONERS_WRATH)
    local has_deep_wounds = core.spell_book.is_spell_learned(constants.DEEP_WOUNDS)

    -- 1. actions.thane=recklessness
    if actions.execute_recklessness(me, cooldown_toggle, in_combat) then
        return true
    end

    -- 2. actions.thane+=/thunder_clap,if=buff.whirlwind.stack=0&talent.improved_whirlwind&active_enemies>=2
    if aoe_active and player_buffs.whirlwind_stacks == 0 and has_improved_whirlwind then
        if actions.execute_thunder_clap(target) then
            return true
        end
    end

    -- 3. actions.thane+=/avatar,if=!buff.thunder_blast.up
    if not player_buffs.thunder_blast then
        if actions.execute_avatar(me, cooldown_toggle, in_combat) then
            return true
        end
    end

    -- 4. actions.thane+=/thunder_blast,if=buff.whirlwind.stack=0&buff.enrage.up&talent.improved_whirlwind&active_enemies>=2
    if aoe_active and player_buffs.whirlwind_stacks == 0 and player_buffs.enrage and has_improved_whirlwind then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 5. actions.thane+=/thunder_blast,if=buff.enrage.up&buff.avatar.remains<=2
    if player_buffs.enrage and player_buffs.avatar and player_buffs.avatar_remains <= 2 then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 6. actions.thane+=/thunder_blast,if=cooldown.avatar.remains<10
    if SPELLS.AVATAR:cooldown_remains() < 10 then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 7. actions.thane+=/odyns_fury
    local target_in_melee = target:is_in_melee_range(10)
    if actions.execute_odyns_fury(target, in_combat, target_in_melee) then
        return true
    end

    -- 8. actions.thane+=/bloodbath,if=buff.scent_of_blood.stack=2&talent.vicious_contempt&target.health.pct<35
    if player_buffs.scent_of_blood_stacks == 2 and has_vicious_contempt and target:get_health_percentage() < 35 then
        if actions.execute_bloodbath(target) then
            return true
        end
    end

    -- 9. actions.thane+=/rampage,if=buff.enrage.remains<gcd
    if player_buffs.enrage_remains < gcd then
        if SPELLS.RAMPAGE:cast_safe(target, "Thane: Rampage (Maintain Enrage)") then
            return true
        end
    end

    -- 10. actions.thane+=/rampage,if=buff.recklessness.up&rage>=130
    if player_buffs.recklessness and rage_current >= 130 then
        if SPELLS.RAMPAGE:cast_safe(target, "Thane: Rampage (Recklessness Rage Capping)") then
            return true
        end
    end

    -- 11. actions.thane+=/thunder_blast,if=buff.enrage.up&buff.thunder_blast.stack=2
    if player_buffs.enrage and player_buffs.thunder_blast_stacks == 2 then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 12. actions.thane+=/bloodbath
    if actions.execute_bloodbath(target) then
        return true
    end

    -- 13. actions.thane+=/thunder_blast,if=buff.enrage.up&buff.avatar.up
    if player_buffs.enrage and player_buffs.avatar then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 14. actions.thane+=/thunder_clap,if=talent.meat_cleaver&active_enemies>=3
    local nearby_enemies = me:get_enemies_in_melee_range(8)
    if has_meat_cleaver and #nearby_enemies >= 3 then
        if actions.execute_thunder_clap(target) then
            return true
        end
    end

    -- 15. actions.thane+=/crushing_blow,if=action.raging_blow.charges=2&(buff.ragedrinker.up|(talent.surge_of_adrenaline&!buff.surge_of_adrenaline.up))
    if SPELLS.RAGING_BLOW:charges() == 2 and (player_buffs.ragedrinker or (has_surge_of_adrenaline and not player_buffs.surge_of_adrenaline)) then
        if actions.execute_crushing_blow(target) then
            return true
        end
    end

    -- 16. actions.thane+=/rampage,if=buff.recklessness.up&rage>=90
    if player_buffs.recklessness and rage_current >= 90 then
        if SPELLS.RAMPAGE:cast_safe(target, "Thane: Rampage (Recklessness Rage)") then
            return true
        end
    end

    -- 17. actions.thane+=/crushing_blow,if=talent.surge_of_adrenaline&!buff.surge_of_adrenaline.up
    if has_surge_of_adrenaline and not player_buffs.surge_of_adrenaline then
        if actions.execute_crushing_blow(target) then
            return true
        end
    end

    -- 18. actions.thane+=/rampage,if=buff.recklessness.up
    if player_buffs.recklessness then
        if SPELLS.RAMPAGE:cast_safe(target, "Thane: Rampage (Recklessness Active)") then
            return true
        end
    end

    -- 19. actions.thane+=/crushing_blow
    if actions.execute_crushing_blow(target) then
        return true
    end

    -- 20. actions.thane+=/thunder_blast,if=buff.enrage.up&buff.avatar.up&buff.avatar.remains<4
    if player_buffs.enrage and player_buffs.avatar and player_buffs.avatar_remains < 4 then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 21. actions.thane+=/bloodthirst,if=talent.vicious_contempt&target.health.pct<35
    if has_vicious_contempt and target:get_health_percentage() < 35 then
        if actions.execute_bloodthirst(target) then
            return true
        end
    end

    -- 22. actions.thane+=/rampage,if=rage>=100
    if rage_current >= 100 then
        if SPELLS.RAMPAGE:cast_safe(target, "Thane: Rampage (High Rage)") then
            return true
        end
    end

    -- 23. actions.thane+=/execute,if=talent.executioners_wrath|talent.deep_wounds
    if has_executioners_wrath or has_deep_wounds then
        if actions.execute_execute(target, player_buffs, rage_current) then
            return true
        end
    end

    -- 24. actions.thane+=/bloodthirst
    if actions.execute_bloodthirst(target) then
        return true
    end

    -- 25. actions.thane+=/thunder_blast,if=buff.enrage.up
    if player_buffs.enrage then
        if actions.execute_thunder_blast(target, player_buffs) then
            return true
        end
    end

    -- 26. actions.thane+=/rampage
    if actions.execute_rampage(target, rage_current) then
        return true
    end

    -- 27. actions.thane+=/raging_blow
    if actions.execute_raging_blow(target) then
        return true
    end

    -- 28. actions.thane+=/execute
    if actions.execute_execute(target, player_buffs, rage_current) then
        return true
    end

    -- 29. actions.thane+=/thunder_clap
    if actions.execute_thunder_clap(target) then
        return true
    end

    -- 30. actions.thane+=/whirlwind
    -- Note: This requires aoe_active and target_in_melee which are parameters
    local target_in_melee = target:is_in_melee_range(10)
    if actions.execute_whirlwind(target, in_combat, target_in_melee, aoe_active, player_buffs) then
        return true
    end

    return false
end

return thane

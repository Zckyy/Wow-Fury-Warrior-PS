-- ============================================
-- DEPENDENCIES
-- ============================================
local izi = require("common/izi_sdk")
local enums = require("common/enums")
local key_helper = require("common/utility/key_helper")
local control_panel_helper = require("common/utility/control_panel_helper")

local buffs = enums.buff_db

-- ============================================
-- CONSTANTS
-- ============================================
local TAG = "blaze_fury_warrior_"

local CONSTANTS = {
    IMPROVED_WHIRLWIND = 12950,
    CRASHING_THUNDER = 436707,
    THUNDER_BLAST = 435607,
}

local SPELLS = {
    RAGING_BLOW = izi.spell(85288),
    CRUSHING_BLOW = izi.spell(335097),
    BLOODTHIRST = izi.spell(23881),
    BLOODBATH = izi.spell(335096),
    RAMPAGE = izi.spell(184367),
    EXECUTE = izi.spell(163201),
    EXECUTE_SUDDEN_DEATH = izi.spell(5308),
    RECKLESSNESS = izi.spell(1719),
    AVATAR = izi.spell(107574),
    ODYNS_FURY = izi.spell(385059),
    REND = izi.spell(772),
    WHIRLWIND = izi.spell(190411),
    THUNDER_CLAP = izi.spell(6343),
    THUNDER_BLAST = izi.spell(435607),
    BLADESTORM = izi.spell(227847),
}

local CUSTOMBUFFS = {
    -- TBD
}

-- ============================================
-- STATE TRACKING
-- ============================================
local state = {
    IN_COMBAT = false,
}

-- ============================================
-- MENU CONFIGURATION
-- ============================================
local menu = {
    root         = core.menu.tree_node(),
    enabled      = core.menu.checkbox(false, TAG .. "enabled"),
    toggle_key   = core.menu.keybind(7, false, TAG .. "toggle"),
    cooldown_key = core.menu.keybind(7, false, TAG .. "cooldown_key"),
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

---@return boolean
local function rotation_enabled()
    return menu.enabled:get_state() and menu.toggle_key:get_toggle_state()
end

---@param me game_object
---@return boolean
local function is_aoe(me)
    --Get enemies that are in combat within 30 yards
    --local enemies = me:get_enemies_in_range(30)

    --Get enemies within melee range
    local enemies_melee = me:get_enemies_in_melee_range(8)

    --Check if we are in an AoE scenario
    local is_aoe = #enemies_melee > 1

    return is_aoe
end

---@param me game_object
---@return table
local function get_player_buffs(me)
    return {
        enrage = me:has_buff(buffs.ENRAGE),
        enrage_remains = me:buff_remains_sec(buffs.ENRAGE),
        sudden_death = me:has_buff(buffs.SUDDEN_DEATH),
        sudden_death_stacks = me:get_buff_stacks(buffs.SUDDEN_DEATH),
        whirlwind = me:has_buff(buffs.WHIRLWIND),
    }
end

---@param target game_object
---@return table
local function get_target_debuffs(target)
    return {
        rend = target:has_debuff(buffs.REND),
    }
end

---@param target game_object
---@return boolean
local function is_valid_target(target)
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

---@param target game_object
---@param cooldown_toggle boolean
---@param in_combat boolean
local function execute_avatar(target, cooldown_toggle, in_combat)
    if not cooldown_toggle then
        return false
    end

    if not in_combat then
        return false
    end

    if SPELLS.AVATAR:cast_safe(target, "Single Target: Avatar") then
        return true
    end
end

---@param target game_object
---@param cooldown_toggle boolean
---@param in_combat boolean
local function execute_recklessness(target, cooldown_toggle, in_combat)
    if not cooldown_toggle then
        return false
    end

    if not in_combat then
        return false
    end

    if SPELLS.RECKLESSNESS:cast_safe(target, "Single Target: Recklessness") then
        return true
    end
end

---@param target game_object
---@param in_combat boolean
---@param target_in_melee boolean
local function execute_odyns_fury(target, in_combat, target_in_melee)
    if not in_combat then
        return false
    end

    if not target_in_melee then
        return false
    end

    if SPELLS.ODYNS_FURY:cast_safe(target, "Single Target: Odyn's Fury") then
        return true
    end
end

---@param target game_object
---@param rage_current number
---@param player_buffs table
---@param enraged_time_remaining number
---@return boolean
local function execute_rampage(target, rage_current, player_buffs, enraged_time_remaining)
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
---@return boolean
local function execute_execute(target, player_buffs, rage_current)
    -- Sudden Death buff allows Execute to be used
    if player_buffs.sudden_death and rage_current <= 100 then
        if SPELLS.EXECUTE_SUDDEN_DEATH:since_last_cast() > 0.5 and SPELLS.EXECUTE_SUDDEN_DEATH:cast_safe(target, "Single Target: Execute - Sudden Death") then
            return true
        end
    end

    -- Normal Execute when target is below 35% HP
    -- Adding a check for since_last_cast to prevent repeat casts before the SDK updates the cooldown state
    if target:get_health_percentage() < 35 and SPELLS.EXECUTE:cooldown_up() then
        if SPELLS.EXECUTE:since_last_cast() > 0.5 and SPELLS.EXECUTE:cast_safe(target, "Single Target: Execute") then
            return true
        end
    end

    return false
end

---@param target game_object
---@return boolean
local function execute_bloodthirst(target)
    if SPELLS.BLOODTHIRST:cast_safe(target, "Single Target: Bloodthirst") then
        return true
    end
    return false
end

---@param target game_object
---@return boolean
local function execute_raging_blow(target)
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
---@return boolean
local function execute_whirlwind(target, in_combat, target_in_melee, aoe_active, player_buffs)
    if not in_combat then
        return false
    end

    if not target_in_melee then
        return false
    end

    -- Check if Improved Whirlwind talent is learned
    local has_improved_whirlwind = core.spell_book.is_spell_learned(CONSTANTS.IMPROVED_WHIRLWIND)

    -- In AOE with Improved Whirlwind, maintain the Whirlwind buff for cleave
    if aoe_active and has_improved_whirlwind then
        local whirlwind_remaining = izi.me():buff_remains_sec(buffs.WHIRLWIND)
        -- Refresh if buff is missing or about to expire (< 2 seconds)
        if not player_buffs.whirlwind or whirlwind_remaining < 2.0 then
            if SPELLS.WHIRLWIND:cast_safe(target, "AOE: Whirlwind (Maintain Cleave)") then
                return true
            end
        end
    end

    -- Single target filler
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
---@return boolean
local function execute_rend(target, in_combat, target_in_melee, target_debuffs)
    if not in_combat then
        return false
    end

    if not target_in_melee then
        return false
    end

    -- Apply Rend if not present or refresh with pandemic (5 seconds remaining)
    local rend_remaining = target:debuff_remains_sec(buffs.REND)
    if not target_debuffs.rend or rend_remaining <= 5.0 then
        if SPELLS.REND:cast_safe(target, "Single Target: Rend") then
            return true
        end
    end
    return false
end


---@param target game_object
---@return boolean
local function execute_bloodbath(target)
    if SPELLS.BLOODBATH:cast_safe(target, "Single Target: Bloodbath") then
        return true
    end
    return false
end

---@param target game_object
---@param player_buffs table
---@return boolean
local function execute_bladestorm(target, player_buffs)
    if player_buffs.enrage_remains > 1 then
        if SPELLS.BLADESTORM:cast_safe(target, "Single Target: Bladestorm") then
            return true
        end
    end
    return false
end

---@param target game_object
---@return boolean
local function execute_crushing_blow(target)
    if SPELLS.CRUSHING_BLOW:cast_safe(target, "Single Target: Crushing Blow") then
        return true
    end
    return false
end


---@param target game_object
---@param me game_object
---@param player_buffs table
---@param cooldown_toggle boolean
---@param aoe_active boolean
---@param rage_current number
---@return boolean
local function execute_target_rotation(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current)
    local enraged_time_remaining = player_buffs.enrage_remains
    local target_debuffs = get_target_debuffs(target)
    local target_in_melee = target:is_in_melee_range(10)
    local gcd = me:gcd()

    -- 1. actions.slayer=recklessness
    if execute_recklessness(me, cooldown_toggle, state.IN_COMBAT) then
        return true
    end

    -- 2. actions.slayer+=/avatar
    if execute_avatar(me, cooldown_toggle, state.IN_COMBAT) then
        return true
    end

    -- 3. actions.slayer+=/bloodbath
    if execute_bloodbath(target) then
        return true
    end

    -- 4. actions.slayer+=/odyns_fury
    if execute_odyns_fury(target, state.IN_COMBAT, target_in_melee) then
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
    if aoe_active and core.spell_book.is_spell_learned(CONSTANTS.IMPROVED_WHIRLWIND) and not player_buffs.whirlwind then
        if SPELLS.WHIRLWIND:cast_safe(target, "AOE: Whirlwind (Cleave)") then
            return true
        end
    end

    -- 8. actions.slayer+=/bladestorm,if=buff.enrage.remains>1
    if execute_bladestorm(target, player_buffs) then
        return true
    end

    -- 9. actions.slayer+=/execute
    if execute_execute(target, player_buffs, rage_current) then
        return true
    end

    -- 10. actions.slayer+=/crushing_blow
    if execute_crushing_blow(target) then
        return true
    end

    -- 11. actions.slayer+=/rampage,if=rage>115
    if rage_current > 115 then
        if SPELLS.RAMPAGE:cast_safe(target, "Single Target: Rampage (Rage Capping)") then
            return true
        end
    end

    -- 12. actions.slayer+=/bloodthirst
    if execute_bloodthirst(target) then
        return true
    end

    -- 13. actions.slayer+=/rampage
    if execute_rampage(target, rage_current, player_buffs, enraged_time_remaining) then
        return true
    end

    -- 14. actions.slayer+=/rend,if=dot.rend_dot.remains<6
    local rend_remaining = target:debuff_remains_sec(buffs.REND)
    if rend_remaining < 6 then
        if SPELLS.REND:cast_safe(target, "Single Target: Rend (Refresh)") then
            return true
        end
    end

    -- 15. actions.slayer+=/raging_blow
    if execute_raging_blow(target) then
        return true
    end

    -- 16. actions.slayer+=/rend
    if execute_rend(target, state.IN_COMBAT, target_in_melee, target_debuffs) then
        return true
    end

    -- 17. actions.slayer+=/whirlwind
    if execute_whirlwind(target, state.IN_COMBAT, target_in_melee, aoe_active, player_buffs) then
        return true
    end

    return false
end

-- ============================================
-- MENU RENDERING
-- ============================================

core.register_on_render_menu_callback(function()
    menu.root:render("Blaze - Fury Warrior", function()
        menu.enabled:render("Enabled Plugin")

        if not menu.enabled:get_state() then
            return
        end

        menu.toggle_key:render("Toggle Rotation")
        menu.cooldown_key:render("Cooldown Keybind")
    end)
end)

-- ============================================
-- CONTROL PANEL
-- ============================================

core.register_on_render_control_panel_callback(function()
    local control_panel_elements = {}

    if not menu.enabled:get_state() then
        return control_panel_elements
    end

    control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = string.format("[Blaze - Fury Warrior] Enabled (%s)",
                key_helper:get_key_name(menu.toggle_key:get_key_code())
            ),
            keybind = menu.toggle_key,
        })

    control_panel_helper:insert_toggle(control_panel_elements,
        {
            name = string.format("[Blaze - Fury Warrior] Cooldown (%s)",
                key_helper:get_key_name(menu.cooldown_key:get_key_code())
            ),
            keybind = menu.cooldown_key,
        })

    return control_panel_elements
end)

-- ============================================
-- MAIN UPDATE LOOP
-- ============================================

core.register_on_update_callback(function()
    control_panel_helper:on_update(menu)

    if not rotation_enabled() then
        return
    end

    local me = izi.me()
    if not me then
        return
    end

    -- Update combat state
    state.IN_COMBAT = me:is_in_combat()

    -- Cache frequently-used values
    local player_buffs = get_player_buffs(me)
    local cooldown_toggle = menu.cooldown_key:get_toggle_state()
    local targets = izi.get_ts_targets()
    local rage_current = me:get_power(enums.power_type.RAGE)

    -- Process all valid targets
    for i = 1, #targets do
        local target = targets[i]

        if not is_valid_target(target) then
            goto continue
        end

        local aoe_active = is_aoe(me)

        -- Execute rotation for this target
        if execute_target_rotation(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current) then
            return
        end

        ::continue::
    end
end)

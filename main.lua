-- ============================================
-- DEPENDENCIES
-- ============================================
local rotation             = require("rotation")
local izi                  = require("common/izi_sdk")
local enums                = require("common/enums")
local key_helper           = require("common/utility/key_helper")
local control_panel_helper = require("common/utility/control_panel_helper")

local buffs = enums.buff_db

-- ============================================
-- CONFIGURATION
-- ============================================
local TAG = "blaze_fury_warrior_"

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
    if not (me and me:is_valid()) then
        return
    end

    -- Cache frequently-used values
    local in_combat      = me:is_in_combat()
    local player_buffs   = rotation.get_player_buffs(me)
    local cooldown_toggle = menu.cooldown_key:get_toggle_state()
    local targets         = izi.get_ts_targets()
    local rage_current    = me:get_power(enums.power_type.RAGE)

    -- Process all valid targets
    for i = 1, #targets do
        local target = targets[i]

        if not rotation.is_valid_target(target) then
            goto continue
        end

        local aoe_active = rotation.is_aoe(me)

        -- Execute rotation for this target
        if rotation.execute_target_rotation(target, me, player_buffs, cooldown_toggle, aoe_active, rage_current, in_combat) then
            break
        end

        ::continue::
    end
end)

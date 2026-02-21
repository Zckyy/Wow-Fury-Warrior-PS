local izi = require("common/izi_sdk")
local spell = izi.spell

---@class warrior_fury_spells
local SPELLS =
{
    -- Cooldowns
    RECKLESSNESS = spell(1719),
    AVATAR = spell(107574),
    BLADESTORM = spell(227847),

    -- Damage abilities
    RAGING_BLOW = spell(85288),
    CRUSHING_BLOW = spell(335097),
    BLOODTHIRST = spell(23881),
    BLOODBATH = spell(335096),
    RAMPAGE = spell(184367),
    EXECUTE = spell(163201),
    EXECUTE_SUDDEN_DEATH = spell(5308),
    ODYNS_FURY = spell(385059),
    REND = spell(772),
    WHIRLWIND = spell(190411),
    THUNDER_CLAP = spell(6343),
    THUNDER_BLAST = spell(435222),
}

return SPELLS
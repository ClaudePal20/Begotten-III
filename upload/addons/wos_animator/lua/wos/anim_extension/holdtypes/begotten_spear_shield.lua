--=====================================================================
/*		My Custom Holdtype
			Created by thats sweet( STEAM_0:1:4916602 )*/
local DATA = {}
DATA.Name = "begotten_spear_shield"
DATA.HoldType = "wos-begotten_spear_shield"
DATA.BaseHoldType = "melee"
DATA.Translations = {} 


-- 		["idle"] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
--		["idle_crouch"] = {ACT_COVER_LOW, ACT_COVER_LOW},
--		["walk"] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
--		["walk_crouch"] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
--		["run"] = {ACT_RUN, ACT_RUN},
--		["attack"] = ACT_MELEE_ATTACK_SWING

-- Crouching
DATA.Translations[ ACT_COVER_LOW ] = {
	{ Sequence = "a_spear_shield_crouch_idle", Weight = 1 },
}

DATA.Translations[ ACT_WALK_CROUCH ] = {
	{ Sequence = "a_spear_shield_crouch_walk", Weight = 1 },
}

-- Idle
DATA.Translations[ ACT_IDLE_ANGRY_MELEE ] = {
	{ Sequence = "a_spear_shield_unholstered_idle", Weight = 1 },
}

DATA.Translations[ ACT_IDLE ] = {
	{ Sequence = "a_spear_shield_holstered_idle", Weight = 1 },
}

-- Walking
DATA.Translations[ ACT_WALK ] = {
	{ Sequence = "a_spear_shield_holstered_walk", Weight = 1 },
}

DATA.Translations[ ACT_WALK_AIM_RIFLE ] = {
	{ Sequence = "a_spear_shield_unholstered_walk", Weight = 1 },
}

-- Running
DATA.Translations[ ACT_RUN ] = {
	{ Sequence = "a_spear_shield_holstered_run", Weight = 1 },
}

DATA.Translations[ ACT_RUN_AIM_RIFLE_STIMULATED ] = {
	{ Sequence = "a_spear_shield_unholstered_run", Weight = 1 },
}

-- Attack
DATA.Translations[ ACT_GESTURE_RANGE_ATTACK_SMG1 ] = {
	{ Sequence = "a_spear_shield_attack", Weight = 1 },
}

wOS.AnimExtension:RegisterHoldtype( DATA )
--=====================================================================

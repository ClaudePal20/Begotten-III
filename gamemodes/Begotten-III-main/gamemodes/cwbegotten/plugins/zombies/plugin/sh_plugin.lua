--[[
	created by cash wednesday.
--]]

PLUGIN:SetGlobalAlias("cwZombies");

Clockwork.kernel:IncludePrefixed("cl_hooks.lua");
Clockwork.kernel:IncludePrefixed("cl_plugin.lua");
Clockwork.kernel:IncludePrefixed("sv_hooks.lua");
Clockwork.kernel:IncludePrefixed("sv_plugin.lua");

-- Called when the Clockwork shared variables are added.
function cwZombies:ClockworkAddSharedVars(globalVars, playerVars)
	playerVars:Number("NextSound");
	playerVars:Bool("IsTarget", true);
end

cwZombies.zombieNPCS = {
	"npc_bgt_another",
	"npc_bgt_brute",
	"npc_bgt_chaser",
	"npc_bgt_coinsucker",
	"npc_bgt_eddie",
	"npc_bgt_giant",
	"npc_bgt_grunt",
	"npc_bgt_guardian",
	"npc_bgt_ironclad",
	"npc_bgt_otis",
	"npc_bgt_pursuer",
	"npc_bgt_shambler",
	"npc_bgt_suitor",
	"npc_bgt_chaplain",
	"npc_bgt_demonknight",
};

cwZombies.npcSpawnAmounts = {
	["npc_bgt_pursuer"] = function() return math.random(1,3) end,
	["npc_drg_animals_wolf"] = function() return math.random(3,5) end,
};

cwZombies.terrorNPCs = cwZombies.zombieNPCS;

local entityMeta = FindMetaTable("Entity");

-- A function to get if an entity is a zombie.
function entityMeta:IsZombie()
	return table.HasValue(cwZombies.zombieNPCS, self:GetClass());
end;
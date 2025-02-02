--[[
	Begotten III: Jesus Wept
--]]

local laughs = {"possession/laugh_03.wav", "possession/laugh_06.wav", "possession/laugh_09.wav"};

-- Called when attempts to use a command.
function cwPossession:PlayerCanUseCommand(player, commandTable, arguments)
	if (player.possessor) then
		local blacklisted = {
			"OrderShipment",
			"CharFallOver",
			"DropWeapon",
			"DropShield",
			"DropCoin",
			"CharPhysDesc",
			"CharGetUp",
			"CharCancelGetUp",
			"InvAction",
			"Unequip",
			"Sleep",
			"Drink",
			"Suicide",
			"Flagellate",
			"Electrocute",
			"Relay",
			"DarkWhisper",
			"DarkWhisperDirect",
			"DarkWhisperFaction",
			"DarkReply",
			"Relay",
			"Warcry",
			"Diagnose",
			"StorageGiveCash",
			"StorageGiveItem",
			"StorageTakeCash",
			"StorageTakeItem",
			"StorageClose",
			"Radio",
			"SetFreq",
			"HellJaunt",
			"HellTeleport",
		};
		
		if (table.HasValue(blacklisted, commandTable.name)) then
			Schema:EasyText(player, "firebrick", "You cannot use this command while you are possessed!");
			
			return false;
		end;
	end;
end;

-- Called when a player dies.
function cwPossession:PlayerDeath(player, inflictor, attacker, damageInfo)
	if player:IsPossessed() then
		if IsValid(player.possessor) then
			player.possessor:Spectate(0);
			player.possessor:UnSpectate();
			
			cwObserverMode:MakePlayerEnterObserverMode(player.possessor);
			
			player.possessor.victim = nil;
		end
		
		player:SetSharedVar("currentlyPossessed", false);
		player.possessor = nil;
	elseif attacker:IsPlayer() and attacker:IsPossessed() then
		attacker:EmitSound(laughs[math.random(1, #laughs)]);
	end
end;

function cwPossession:PlayerDisconnected(player)
	if player:IsPossessed() then
		if IsValid(player.possessor) then
			player.possessor:Spectate(0);
			player.possessor:UnSpectate();
			
			cwObserverMode:MakePlayerEnterObserverMode(player.possessor);
			
			player.possessor.victim = nil;
		end
		
		Schema:EasyText(GetAdmins(), "tomato", player:Name().." has disconnected while possessed!");
	elseif IsValid(player.victim) then
		player.victim:SetSharedVar("currentlyPossessed", false);
		player.victim.possessor = nil;

		Clockwork.datastream:Start(player.victim, "Stunned", 5); -- Replace with damnation or custom VFX later!
		Clockwork.player:SetRagdollState(player.victim, RAGDOLL_KNOCKEDOUT, 15);
		Clockwork.chatBox:AddInTargetRadius(player.victim, "me", "is suddenly thrown to the ground by some unseen force!", player.victim:GetPos(), Clockwork.config:Get("talk_radius"):Get() * 2);
		player.victim:EmitSound("possession/spiritsting.wav");
	end
end;

-- Possessed players take 1/4th the damage.
function cwPossession:EntityTakeDamageNew(entity, damageInfo)
	if entity:IsPlayer() then
		if entity:IsPossessed() then
			damageInfo:SetDamage(damageInfo:GetDamage() / 4);
		elseif IsValid(entity.victim) then
			damageInfo:SetDamage(0);
			damageInfo:ScaleDamage(0);
			
			return true;
		end;
	end;
end;

function cwPossession:Tick()
	if cwPossession.possessedPlayers then
		local curTime = CurTime();
		
		if !self.nextPossessionCheck or (curTime > self.nextPossessionCheck) then
			for i = 1, #self.possessedPlayers do
				local possessed_player = self.possessedPlayers[i];
				
				if IsValid(possessed_player) then
					
				else
					table.remove(self.possessedPlayers, i);
					break;
				end
			end
		end
	end
end
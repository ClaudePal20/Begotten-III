--[[
	Begotten III: Jesus Wept
--]]

local playerMeta = FindMetaTable("Player")

util.AddNetworkString("PossessionFreakoutAnim")

-- A function to get if the player can be possessed.
function playerMeta:CanBePossessed(bIgnoreTrait)
	if self:Alive() and self:HasInitialized() and !self.possessor and !self.victim and !self.opponent then
		if !bIgnoreTrait then
			if self:HasTrait("possessed") then
				return true;
			end
		else
			return true;
		end
	end
	
	return false;
end

-- A function to possess a player.
function playerMeta:Possess(possessor)
	if IsValid(possessor) then
		if !cwPossession.possessedPlayers then
			cwPossession.possessedPlayers = {};
		end
	
		possessor.attacking = false;
		possessor.jumping = false;
		possessor.crouching = false;
		possessor.reloading = false;
		possessor.forward = false;
		possessor.backward = false;
		possessor.left = false;
		possessor.right = false;
		possessor.movementForward = 0;
		possessor.sidewaysMovement = 0;
		possessor.upMove = 0;
		possessor.MouseX = 0;
		possessor.MouseY = 0;
		possessor.viewAngles = self:EyeAngles();
		possessor.victim = self;
		
		self.possessor = possessor;
		
		table.insert(cwPossession.possessedPlayers, self);
		
		possessor:Spectate(OBS_MODE_IN_EYE);
		possessor:SpectateEntity(self);
		
		self:SetSharedVar("currentlyPossessed", true);
		
		Clockwork.chatBox:Add(self, nil, "itnofake", "As much as you struggle, you cannot fight off the entity that is now taking control of your body!");
		
		self:Freeze(false);
		self:ResetInjuries();
		self:SetHealth(self:GetMaxHealth() or 100);
		self:SetNeed("thirst", 0);
		self:SetNeed("hunger", 0);
		self:SetBloodLevel(5000);
		self:StopAllBleeding();
		
		Clockwork.datastream:Start(possessor, "Possessing", self);
		Clockwork.datastream:Start(possessor, "Stunned", 5); -- Replace with damnation or custom VFX later!
		Clockwork.datastream:Start(self, "Possessed", possessor);
		Clockwork.datastream:Start(self, "Stunned", 5); -- Replace with damnation or custom VFX later!
		
		Schema:EasyText(GetAdmins(), "tomato", possessor:Name().." has possessed '"..self:Name().."'.");
	end
end

-- A function to make a player go fucking crazy!!!
function playerMeta:PossessionFreakout()
	local entitiesInSphere = ents.FindInSphere(self:GetPos(), 512);
	
	for k, v in pairs (entitiesInSphere) do	
		if (IsValid(v) and v:IsPlayer()) then
			if v:HasInitialized() then
				if !v.cwObserverMode then
					v:HandleSanity(-25);
				end
				
				Clockwork.datastream:Start(v, "PlaySound", "youbetterhide2.mp3");
			end
		end
	end
	
	self:SetSharedVar("possessionFreakout", true);
	self:Freeze(true);
	
	Clockwork.chatBox:Add(self, nil, "itnofake", "You feel something claw its way into your mind!");
	Clockwork.chatBox:AddInTargetRadius(self, "me", "begins involuntarily convulsing and trembling, almost as if they are losing control of their body!", self:GetPos(), Clockwork.config:Get("talk_radius"):Get() * 2);
	
	net.Start("PossessionFreakoutAnim")
	net.WriteEntity(self);
	net.Broadcast();
	
	timer.Simple(2, function()
		if IsValid(self) and self:Alive() then
			self:EmitSound("possession/maggot_guy_scream3_gasps.ogg", 60);
		end
	end);
	
	timer.Simple(7, function()
		if IsValid(self) and self:Alive() then
			self:EmitSound("possession/maggot_guy_scream3_scream.wav", 100);
		end
	end);
	
	timer.Simple(30, function()
		if IsValid(self) then
			self:SetSharedVar("possessionFreakout", false);
			self:Freeze(false);
			
			if !self.possessor then
				if self:Alive() then
					Clockwork.player:SetRagdollState(self, RAGDOLL_KNOCKEDOUT, 15);
					Clockwork.chatBox:AddInTargetRadius(self, "me", "suddenly falls limp and drops to the ground!", self:GetPos(), Clockwork.config:Get("talk_radius"):Get() * 2);
					
					self:EmitSound("possession/spiritsting.wav");
				end
			end
		end
	end);
end

-- A function to unpossess a player.
function playerMeta:Unpossess()
	if !cwPossession.possessedPlayers then
		cwPossession.possessedPlayers = {};
	end
	
	if IsValid(self.possessor) then
		self.possessor:Spectate(0);
		self.possessor:UnSpectate();
		
		cwObserverMode:MakePlayerEnterObserverMode(self.possessor);
		
		Schema:EasyText(GetAdmins(), "tomato", self.possessor:Name().." has stopped possessing '"..self.possessor.victim:Name().."'.");
		
		self.possessor.victim = nil;
	end
	
	self.possessor = nil;
	
	self:SetSharedVar("currentlyPossessed", false);
	self:SetSharedVar("possessionFreakout", false);
	Clockwork.datastream:Start(self, "Stunned", 5); -- Replace with damnation or custom VFX later!
	Clockwork.player:SetRagdollState(self, RAGDOLL_KNOCKEDOUT, 15);
	Clockwork.chatBox:AddInTargetRadius(self, "me", "suddenly falls limp and drops to the ground!", self:GetPos(), Clockwork.config:Get("talk_radius"):Get() * 2);
	self:EmitSound("possession/spiritsting.wav");
	
	for i = 1, #cwPossession.possessedPlayers do
		if !IsValid(cwPossession.possessedPlayers[i]) or cwPossession.possessedPlayers[i] == self then
			table.remove(cwPossession.possessedPlayers, i);
			break;
		end
	end
end

-- A function to get if the player is possessed.
function playerMeta:IsPossessed()
	return self:GetSharedVar("currentlyPossessed") or false;
end
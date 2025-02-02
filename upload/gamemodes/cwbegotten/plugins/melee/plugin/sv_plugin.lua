--[[
	Begotten 3: Jesus Wept
	written by: cash wednesday, DETrooper, gabs and alyousha35.
--]]

local playerMeta = FindMetaTable("Player");

-- A function to handle a player's stability value.
function cwMelee:HandleStability(player, amount, cooldown)
	if (!amount or !IsValid(player)) then
		return;
	end;

	--[[if (!cooldown or !isnumber(cooldown)) then
		cooldown = 10;
	end;

	player.stabilityCooldown = CurTime() + cooldown;]]--
	player:SetCharacterData("stability", math.Clamp(player:GetCharacterData("stability", player:GetMaxStability()) + amount, 0, player:GetMaxStability()));
end;

function playerMeta:TakePoise(amount)
	if (Clockwork.player:HasFlags(self, "E")) then
		return;
	end

	local newAmount = amount;
	local leftArm = Clockwork.limb:GetHealth(self, HITGROUP_LEFTARM, false)
	local rightArm = Clockwork.limb:GetHealth(self, HITGROUP_RIGHTARM, false)
	local armDamage = math.min(leftArm, rightArm)
	
	if (armDamage <= 90) then
		if armDamage <= 75 and armDamage > 50 then
			newAmount = math.floor(newAmount * 1.2);
		elseif armDamage <= 50 and armDamage > 25 then
			newAmount = math.floor(newAmount * 1.5);
		elseif armDamage <= 25 and armDamage > 10 then
			newAmount = math.floor(newAmount * 2);
		else
			newAmount = math.floor(newAmount * 3);
		end
	end
	
	if newAmount > 0 then
		newAmount = 0 - newAmount;
	end

	self:SetNWInt("meleeStamina", math.Clamp(self:GetNWInt("meleeStamina", 90) + newAmount, 0, self:GetMaxPoise() or 90));
	
	if self:GetNWInt("meleeStamina", 90) <= 0 and self:GetNWBool("Guardening", false) == true then
		self:CancelGuardening();
		self.nextStas = CurTime() + 3;
	end
end

-- A function to take from a player's stability.
function playerMeta:TakeStability(amount, cooldown)
	--printp("Taking stability - Initial Amount: "..amount);
	
	if (Clockwork.player:HasFlags(self, "E") or !self:Alive()) then
		return;
	end

	if not self:IsInGodMode() and (!cwPowerArmor or (cwPowerArmor and --[[!self:IsWearingPowerArmor()]] !self.wearingPowerArmor)) then
		if self:GetSharedVar("tied") ~= 0 then
			self.nextStability = CurTime() + 3;
			
			cwMelee:HandleStability(self, -100, cooldown);
			cwMelee:PlayerStabilityFallover(self, 30);
			
			return;
		end
		
		if self.bgCharmData and self.HasCharmEquipped then
			if self:GetFaith() == "Faith of the Family" and self:HasCharmEquipped("effigy_earthing") then
				amount = math.floor(amount * 0.75);
				--printp("Earthing Effigy Reduction: "..amount);
			end
		end
		
		if cwBeliefs and self:HasBelief("fortitude_finisher") then
			amount = math.floor(amount * 0.75);
		end
	
		local armorClass;
		local armorTable = self:GetClothesItem();
		
		if armorTable then
			armorClass = armorTable.weightclass;

			if armorTable.stabilityScale then
				amount = math.floor(amount * armorTable.stabilityScale);
				--printp("Armor Modifier: "..amount);
			elseif armorClass then
				if armorClass == "Heavy" then
					amount = math.floor(amount * 0.6);
					--printp("Armor Modifier: "..amount);
				elseif armorClass == "Medium" then
					amount = math.floor(amount * 0.7);
					--printp("Armor Modifier: "..amount);
				elseif armorClass == "Light" then
					amount = math.floor(amount * 0.85);
					--printp("Armor Modifier: "..amount);
				end
			end
		end
		
		local leftLeg = Clockwork.limb:GetHealth(self, HITGROUP_LEFTLEG, false)
		local rightLeg = Clockwork.limb:GetHealth(self, HITGROUP_RIGHTLEG, false)
		local legDamage = math.min(leftLeg, rightLeg)

		if (legDamage <= 90) then
			if legDamage > 75 then
				amount = math.floor(amount * 1.2);
				--printp("Leg Damage Modifier: "..amount);
			elseif legDamage <= 75 and legDamage > 50 then
				amount = math.floor(amount * 1.5);
				--printp("Leg Damage Modifier: "..amount);
			elseif legDamage <= 50 and legDamage > 25 then
				amount = math.floor(amount * 2);
				--printp("Leg Damage Modifier: "..amount);
			elseif legDamage <= 25 and legDamage > 10 then
				amount = math.floor(amount * 3);
				--printp("Leg Damage Modifier: "..amount);
			else
				amount = math.floor(amount * 4);
				--printp("Leg Damage Modifier: "..amount);
			end
		end
		
		if self.nobleStatureActive then
			if self:GetVelocity():Length() == 0 then
				amount = math.floor(amount / 2);
			end
		end
		
		cwMelee:HandleStability(self, -math.abs(amount), cooldown);
		self.nextStability = CurTime() + 3;
		
		if (self:GetCharacterData("stability", self:GetMaxStability()) <= 0 and !self:IsRagdolled() and !self:GetNWBool("bliz_frozen")) then
			local stabilityDelay = 0.5;
			local falloverTime = 5;

			if armorClass then
				if (armorClass == "Medium") then
					stabilityDelay = 1;
					falloverTime = 8;
				elseif (armorClass == "Heavy") then
					stabilityDelay = 1.5;
					falloverTime = 12;
				end;
			end;

			cwMelee:PlayerStabilityFallover(self, falloverTime);
		end;
	end
end;

-- A function to give player's stability.
function playerMeta:GiveStability(amount, cooldown)
	cwMelee:HandleStability(self, math.abs(amount), cooldown);
end;

function playerMeta:AddFreeze(amount, attacker)
	local model = self:GetModel();
	
	if IsValid(attacker) and (!cwPowerArmor or (cwPowerArmor and --[[!self:IsWearingPowerArmor()]] !self.wearingPowerArmor)) and !self.cloakBurningActive then
		local freeze = self:GetNWInt("freeze", 0);
		
		self:SetNWInt("freeze", math.Clamp(math.Round(freeze + amount), 0, 100));
		
		if self:GetNWInt("freeze") >= 100 then
			--if attacker:GetActiveWeapon().FreezeTime then
				--DoElementalEffect({Element = EML_ICE, Target = self, Duration = attacker:GetActiveWeapon().FreezeTime, Attacker = attacker})
			--end
			
			DoElementalEffect({Element = EML_ICE, Target = self, Duration = 20, Attacker = attacker})
		end
		
		hook.Run("RunModifyPlayerSpeed", self, self.cwInfoTable, true);
	end
end

function playerMeta:TakeFreeze(amount)
	local freeze = self:GetNWInt("freeze", 0);
	
	self:SetNWInt("freeze", math.Clamp(math.Round(freeze - amount), 0, 100));
	
	hook.Run("RunModifyPlayerSpeed", self, self.cwInfoTable, true);
end

-- A function to get a player's maximum poise.
function playerMeta:GetMaxPoise()
	local max_poise = 90;
	if self:GetCharacterData("isDemon", false) then
		max_poise = 1000
	end
	if cwBeliefs and self.HasBelief then
		if self:HasBelief("fighter") then
			max_poise = max_poise + 10;
			
			if self:HasBelief("warrior") then
				max_poise = max_poise + 10;
				
				if self:HasBelief("master_at_arms") then
					max_poise = max_poise + 15;
				end
			end
		end
		
		if self:HasBelief("man_become_beast") then
			max_poise = max_poise + 10;
		end
	end
	if self:GetSubfaction() == "Legionary" then
		max_poise = max_poise + 15;
	end
	
	return max_poise;
end;

-- A function to get a player's maximum stability.
function playerMeta:GetMaxStability()
	local max_stability = 100;
	if self:GetCharacterData("isDemon", false) then
		max_stability = 1000
	end
	local boost = self:GetNetVar("loyaltypoints", 0)
	if boost > 0 then
		max_stability = tonumber(max_stability + boost);
	end
	
	if self:GetSubfaction() == "Philimaxio" then
		max_stability = max_stability + 25;
	end
	
	if cwBeliefs and self.HasBelief then
		if self:HasBelief("litheness_finisher") then
			max_stability = max_stability + 25;
		end
		
		if self:HasBelief("enduring_bear") then
			max_stability = max_stability + 25;
		end
	end
	
	return max_stability;
end;

function playerMeta:GetArmorClass()
	local armorTable = self:GetClothesItem();
	
	if armorTable then
		if (armorTable.weightclass) then
			return armorTable.weightclass;
		end;
	end
end;

function playerMeta:Disorient(blurAmount)
	netstream.Start(self, "Disorient", blurAmount);
end;
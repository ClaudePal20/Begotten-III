--[[
	Begotten 3: Jesus Wept
	written by: cash wednesday, DETrooper, gabs and alyousha35.
--]]

PLUGIN:SetGlobalAlias("cwMelee");

Clockwork.kernel:IncludePrefixed("cl_plugin.lua");
Clockwork.kernel:IncludePrefixed("cl_hooks.lua");
Clockwork.kernel:IncludePrefixed("sv_plugin.lua");
Clockwork.kernel:IncludePrefixed("sv_hooks.lua");

function cwMelee:KeyPress(player, key)
	local bUse = (key == IN_USE)
	local bAttack2 = (key == IN_ATTACK2)

	if (bUse or bAttack2) then
		local requiredKey = false;
		
		if (bUse) then
			requiredKey = player:KeyDown(IN_ATTACK2)
		elseif (bAttack2) then
			requiredKey = player:KeyDown(IN_USE)
		end;
		
		if (requiredKey) then
			if (player:GetNWBool("MelAttacking") != false) then
				return;
			end;
			
			local activeWeapon = player:GetActiveWeapon();
			
			if (!IsValid(activeWeapon)) then
				return;
			end;
			
			if (activeWeapon.Base == "sword_swepbase") then
				local attackTable = GetTable(activeWeapon.AttackTable);
				
				if (attackTable and attackTable["canaltattack"] == true) then
					local curTime = CurTime();
					
					if (!player.StanceSwitchOn or curTime > player.StanceSwitchOn) then
						if (player.HasBelief and player:HasBelief("halfsword_sway")) then
							if (player:GetNWBool("ThrustStance") == false) then
								if (activeWeapon.CanSwipeAttack == true) then
									player:SetNWBool("ThrustStance", true)
									player:PrintMessage(HUD_PRINTTALK, "*** Switched to swiping stance.")
									player.StanceSwitchOn = curTime + 1;
								else
									player:SetNWBool("ThrustStance", true)
									player:PrintMessage(HUD_PRINTTALK, "*** Switched to thrusting stance.")
									player.StanceSwitchOn = curTime + 1;
								end;
							else
								if (activeWeapon.CanSwipeAttack == true) then
									player:SetNWBool("ThrustStance", false)
									player:PrintMessage(HUD_PRINTTALK, "*** Switched to thrusting stance.")
									player.StanceSwitchOn = curTime + 1;
								elseif (attackTable["dmgtype"] == 128) then
									player:SetNWBool("ThrustStance", false)
									player:PrintMessage(HUD_PRINTTALK, "*** Switched to bludgeoning stance.")
									player.StanceSwitchOn = curTime + 1;
								else
									player:SetNWBool("ThrustStance", false)
									player:PrintMessage(HUD_PRINTTALK, "*** Switched to slashing stance.")
									player.StanceSwitchOn = curTime + 1;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	
	if (bAttack2) then
		if (!player:KeyDown(IN_USE)) then
			if (player:GetNWBool("MelAttacking") != false) then
				player:CancelGuardening()
				return;
			end;
			
			local activeWeapon = player:GetActiveWeapon();
			
			if (!IsValid(activeWeapon)) then
				return;
			end;
			
			if (activeWeapon.Base == "sword_swepbase") then
				if (activeWeapon.IronSights == true) then
					local loweredParryDebug = activeWeapon:GetNextSecondaryFire();
					local curTime = CurTime();
					
					if (loweredParryDebug < curTime) then
						local blockTable = GetTable(activeWeapon.BlockTable);
						
						if (blockTable and player:GetNWInt("meleeStamina", 100) >= blockTable["guardblockamount"]) then
							player:SetNWBool("Guardening", true);
							player.beginBlockTransition = true;
							player.StaminaRegenDelay = 0;
							activeWeapon.Primary.Cone = activeWeapon.IronCone;
							activeWeapon.Primary.Recoil = activeWeapon.Primary.IronRecoil;
						else
							player:CancelGuardening()
						end;
					end;
				else
					player:CancelGuardening();
				end;
			end;
		elseif (player:GetNWBool("Guardening", false) == true) then
			player:CancelGuardening()
		end;
	end;
	
	if (key == IN_RELOAD) then
		local activeWeapon = player:GetActiveWeapon();
		
		if (IsValid(activeWeapon)) then
			if (activeWeapon.Base == "sword_swepbase") then
				local blockTable = GetTable(activeWeapon.BlockTable);

				if (blockTable and blockTable["canparry"] == true) then
					if (player.HasBelief and player:HasBelief("parrying")) then
						activeWeapon:SecondaryAttack();
					end;
				end;
			end;
		end;
	end;
end;

function cwMelee:KeyRelease(player, key)
	if key == IN_ATTACK2 then
		if (player:GetNWBool("Guardening", false) == true) then
			player:CancelGuardening();
		end;
	end
end

local playerMeta = FindMetaTable("Player");

function playerMeta:CancelGuardening()
	local activeWeapon = self:GetActiveWeapon();
	
	if (IsValid(activeWeapon)) then
		if (activeWeapon.Base == "sword_swepbase") then
			activeWeapon.Primary.Cone = activeWeapon.DefaultCone;
			activeWeapon.Primary.Recoil = activeWeapon.DefaultRecoil;
		end;
	end;
	
	self:SetNWBool("Guardening", false);
	self.beginBlockTransition = true;
end;
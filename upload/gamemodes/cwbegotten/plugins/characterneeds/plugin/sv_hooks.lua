--[[
	Begotten III: Jesus Wept
--]]

-- Called when a player's character data should be restored.
function cwCharacterNeeds:PlayerRestoreCharacterData(player, data)
	for i = 1, #self.Needs do
		local need = self.Needs[i];
		
		if (!data[need]) then
			data[need] = 0;
		end;
	end;
end;

-- Called when a player's shared variables should be set.
--[[function cwCharacterNeeds:OnePlayerSecond(player, curTime)
	for i = 1, #self.Needs do
		local need = self.Needs[i];
		
		player:SetSharedVar(need, player:GetCharacterData(need));
	end;
end;]]--

function cwCharacterNeeds:PostPlayerSpawn(player, lightSpawn, changeClass, firstSpawn)
	if (!lightSpawn) then
		for i = 1, #self.Needs do
			local need = self.Needs[i];
			
			player:SetCharacterData(need, player:GetCharacterData(need) or 0);
			player:SetSharedVar(need, player:GetCharacterData(need));
		end
	end
end;

-- Called at an interval while a player is connected.
function cwCharacterNeeds:PlayerThink(player, curTime, infoTable, alive, initialized)
	local curTime = CurTime();
	
	if !player.nextNeedCheck or curTime >= player.nextNeedCheck then
		--[[if (game.GetMap() != "rp_begotten3") then
			return;
		end;]]--
		
		if (alive and !player.cwObserverMode and !player.opponent) then
			local playerNeeds = {};
			
			for i = 1, #self.Needs do
				local need = self.Needs[i];
				
				playerNeeds[need] = player:GetNeed(need);
			end
		
			if (!player.nextHunger or curTime >= player.nextHunger) then
				if (playerNeeds["hunger"] > -1) then
					local next_hunger = 200;
					
					if player:HasTrait("gluttony") then
						next_hunger = next_hunger * 0.35;
					end
					
					if player:HasBelief("asceticism") then
						next_hunger = next_hunger * 1.35;
					end
					
					player:HandleNeed("hunger", 1);
					player.nextHunger = curTime + next_hunger;
				end;
			end;
			
			if (!player.nextThirst or curTime >= player.nextThirst) then
				if (playerNeeds["thirst"] > -1) then
					local next_thirst = 100;
					
					if player:HasTrait("gluttony") then
						next_thirst = next_thirst * 0.35;
					end
				
					if player:HasBelief("asceticism") then
						next_thirst = next_thirst * 1.35;
					end
				
					player:HandleNeed("thirst", 1);
					player.nextThirst = curTime + next_thirst;
				end;
			end;
			
			if (!player.nextSleep or curTime >= player.nextSleep) then
				if (playerNeeds["sleep"] > -1) then
					local next_sleep = 400;
					
					if cwBeliefs and player:HasBelief("yellow_and_black") then
						if player:HasTrait("gluttony") then
							next_sleep = next_sleep * 0.35;
						end
					
						if player:HasBelief("asceticism") then
							next_sleep = next_sleep * 1.35;
						end
					end

					player:HandleNeed("sleep", 1);
					player.nextSleep = curTime + next_sleep;
					
					if playerNeeds["sleep"] >= 60 then
						if player:HasBelief("yellow_and_black") then
							local d = DamageInfo()
							d:SetDamage(5 * math.Rand(0.5, 1));
							d:SetDamageType(DMG_SHOCK);
							d:SetDamagePosition(player:GetPos() + Vector(0, 0, 48));
							
							player:TakeDamageInfo(d);
							
							Clockwork.chatBox:Add(player, nil, "itnofake", "Some of my systems are beginning to power down, I need to recharge!");
						end
					end
				end;
			end;
			
			--[[if (!player.nextCorruption or curTime >= player.nextCorruption) then
				if (playerNeeds["corruption"] > -1) then
					-- Check for sacrifical weapons.
					local weaponData = player:GetCharacterData("weapons");
					
					if weaponData and #weaponData > 0 then
						for i = 1, #weaponData do
							if weaponData[i].uniqueID and weaponData[i].itemID then
								local weaponItem = Clockwork.inventory:FindItemByID(player:GetInventory(), weaponData[i].uniqueID, weaponData[i].itemID);
								
								if weaponItem and weaponItem.isSacrifical and weaponItem:HasPlayerEquipped(player) then
									player:HandleNeed("corruption", 1);
								end
							end
						end
					end
				
					player.nextCorruption = curTime + 15;
				end;
			end;]]--
		end;
		
		player.nextNeedCheck = curTime + 5;
	end;
end;

function cwCharacterNeeds:PlayerShouldStaminaRegenerate(player)
	if player:GetNeed("thirst") >= 75 or player:GetNeed("sleep") >= 75 then
		return false;
	end;
end;

-- Called when a player uses an item.
function cwCharacterNeeds:PlayerUseItem(player, itemTable, itemEntity)
	if itemTable.needs then
		local subfaction = player:GetSubfaction();
	
		for k, v in pairs(itemTable.needs) do
			if (k == "hunger" or k == "thirst") and subfaction == "Varazdat" then
				if itemTable.uniqueID == "humanmeat" or itemTable.uniqueID == "cooked_human_meat" or itemTable.uniqueID == "canned_fresh_meat" or itemTable.uniqueID == "varazdat_bloodwine" or itemTable.uniqueID == "varazdat_masterclass_bloodwine" then
					player:HandleNeed(k, -v);
				end
			elseif subfaction ~= "Varazdat" then
				player:HandleNeed(k, -v);
			end
		end
	end
end;

function cwCharacterNeeds:ActionStopped(player, action)
	if action == "unragdoll" and player.sleepData then
		player.sleepData = nil;
	end
end;

function cwCharacterNeeds:ActionCompletedPreCallback(player, action)
	if action == "unragdoll" and player.sleepData then
		local sleepData = player.sleepData;
		
		if cwSanity and sleepData.sanity then
			player:HandleSanity(sleepData.sanity);
		end
		
		if sleepData.hunger then
			player:HandleNeed("hunger", sleepData.hunger);
		end
		
		if sleepData.thirst then
			player:HandleNeed("thirst", sleepData.thirst);
		end
		
		if sleepData.rest then
			player:HandleNeed("sleep", sleepData.rest);
		end
		
		player.sleepData = nil;
	end
end;

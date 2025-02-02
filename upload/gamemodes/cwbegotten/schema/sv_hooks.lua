--[[
	Begotten 3: Jesus Wept
	written by: cash wednesday, DETrooper, gabs and alyousha35.
--]]

local map = game.GetMap() == "rp_begotten3";

function GetAdmins()
	local admins = {}
	local players = _player.GetAll();
	
	for i = 1, _player.GetCount() do
		local v = players[i];
		if (v:IsAdmin()) then
			admins[#admins + 1] = v;
		end;
	end;
	
	return admins;
end;

-- A function to get the number of characters a player has in each faction and return it as a table.
function Schema:GetCharacterCountByFaction(player)
	local stored = Clockwork.faction:GetStored();
	local characters = player:GetCharacters();
	local charTable = {};
	
	for k, v in pairs (stored) do
		if (!charTable[k]) then
			charTable[k] = 0;
		end;
	end;
	
	for k, v in pairs (characters) do
		if (v.data["permakilled"]) then
			continue;
		end;
		
		if (v.faction and charTable[v.faction]) then
			charTable[v.faction] = charTable[v.faction] + 1;
		end;
	end;
	
	return charTable;
end;

-- Called when a player attempts to create a character.
function Schema:PlayerCanCreateCharacter(player, character, characterID)
	local factionTable = Clockwork.faction:FindByID(character.faction);

	--[[local charLimitEnabled = Clockwork.config:Get("enable_charlimit"):Get();
	
	if (charLimitEnabled) then
		if (player:IsAdmin() or Clockwork.player:HasFlags(player, "j")) then
			return true;
		end;
		
		local bGore = character.faction == FACTION_GOREIC;
		local bSatanist = character.faction == FACTION_SATANIST;
		
		if (bGore or bSatanist) then
			local factionCount = self:GetCharacterCountByFaction(player);
			local goreCount = factionCount[FACTION_GOREIC] + ((bGore and 1) or 0);
			local satanistCount = factionCount[FACTION_SATANIST] + ((bSatanist and 1) or 0); -- add one for the character currently being created
			local goreLimit = Clockwork.config:Get("gore_charlimit"):Get()
			local satanistLimit = Clockwork.config:Get("satanist_charlimit"):Get()
			
			if ((goreLimit < goreCount) or (satanistLimit < satanistCount)) then
				Clockwork.player:SetCreateFault(player, "You cannot create another character belonging to the "..character.faction.." whitelist!");
				
				return false;
			end;
		end;
	end;]]--
	
	if factionTable.disabled then
		Clockwork.player:SetCreateFault(player, "This character's faction is disabled and thus cannot be created!");
	
		return false;
	end
end;

-- Called to get whether a player can interact with one of their characters.
function Schema:PlayerCanInteractCharacter(player, action, character)
	local factionTable = Clockwork.faction:FindByID(character.faction);

	--[[local charLimitEnabled = Clockwork.config:Get("enable_charlimit"):Get();
	
	if (charLimitEnabled) then
		local whitelisted = character.faction == FACTION_GOREIC or character.faction == FACTION_SATANIST;
		
		if (whitelisted and action == "use") then
			local data = character.data;

			if (player:IsAdmin() or (Clockwork.player:HasFlags(player, "j") and !data["permakilled"])) then
				return true;
			end;

			local factionCount = self:GetCharacterCountByFaction(player);
			local goreCount = factionCount[FACTION_GOREIC];
			local satanistCount = factionCount[FACTION_SATANIST];
			local goreLimit = Clockwork.config:Get("gore_charlimit"):Get();
			local satanistLimit = Clockwork.config:Get("satanist_charlimit"):Get();

			if ((goreLimit < goreCount) or (satanistLimit < satanistCount)) then
				Clockwork.player:SetCreateFault(player, "The number of characters you have in this faction exceeds the faction limit!");
				
				return false;
			end;
		end;
	end;]]--
	
	if action ~= "delete" and factionTable.disabled then
		Clockwork.player:SetCreateFault(player, "This character's faction is disabled and thus cannot be loaded!");
	
		return false;
	end
end;

-- Called when Clockwork has loaded all of the entities.
function Schema:ClockworkInitPostEntity()
	self:LoadRadios();
	self:LoadNPCs();
	self:SpawnBegottenEntities();
	
	if (!map) then
		return;
	end;
	
	self.towerTreasury = Clockwork.kernel:RestoreSchemaData("treasury")[1] or 0;
	self.archivesBookList = Clockwork.kernel:RestoreSchemaData("archivesBookList") or {};
end;

-- Called when data should be saved.
function Schema:SaveData() 
	if self.towerTreasury then
		Clockwork.kernel:SaveSchemaData("treasury", {self.towerTreasury});
	end
	
	if self.archivesBookList then
		Clockwork.kernel:SaveSchemaData("archivesBookList", self.archivesBookList);
	end
end;

-- Called just after data should be saved.
function Schema:PostSaveData()
	self:SaveRadios();
	self:SaveNPCs();
end;

-- Called when a player attempts to drop a weapon.
function GM:PlayerCanDropWeapon(player, itemTable, weapon, bNoMsg)
	if (itemTable.isUnique) then
		return false;
	else
		return true
	end
end

-- Called when a player wants to fallover.
function Schema:PlayerCanFallover(player)
	if player.cwWakingUp or self.falloverDisabled then
		return false;
	end
end

-- Called when a player attempts to get up.
function Schema:PlayerCanGetUp(player)
	if --[[(player:WaterLevel() == 3) or]] IsValid(player.CinderBlock) then
		return false
	end
end

-- Called when a player has been unragdolled.
function Schema:PlayerUnragdolled(player, state, ragdoll)
	local curTime = CurTime()
	
	if (!player.nextUnragdoll or player.nextUnragdoll < curTime) then
		player.nextUnragdoll = curTime + 1
		
		if (IsValid(player.CinderBlock)) then
			player.CinderBlock:Remove()
		end
	end
end

-- Called when an entity's menu option should be handled.
function Schema:EntityHandleMenuOption(player, entity, option, arguments)
	local class = entity:GetClass();

	if entity:IsPlayer() then
		if (arguments == "cw_sellSlave") and entity:GetNetVar("tied") != 0 then
			for k, v in pairs(ents.FindInSphere(player:GetPos(), 512)) do
				if v:GetClass() == "cw_salesman" and v:GetNetworkedString("Name") == "Reaver Despoiler" then
					Clockwork.player:GiveCash(player, entity:GetCharacterData("level", 1) * 15, "Sold Slave");
					player:EmitSound("generic_ui/coin_positive_02.wav");
					
					local playerName;
					
					if Clockwork.player:DoesRecognise(entity, player) then
						playerName = player:Name();
					else
						playerName = "an unknown Goreic Warrior";
					end
					
					if cwDeathCauses then
						cwDeathCauses:DeathCauseOverride(entity, "Sold into slavery by "..playerName..".");
					end
					
					Schema:EasyText(entity, "firebrick", "You have been sold into slavery by "..playerName.."!");
					entity:KillSilent();
					Schema:PermaKillPlayer(entity);
				end
			end
		end
	elseif (class == "prop_ragdoll" and arguments == "cw_corpseLoot") then
		if (!entity.cwInventory) then entity.cwInventory = {}; end;
		if (!entity.cash) then entity.cash = 0; end;
		
		local entityPlayer = Clockwork.entity:GetPlayer(entity);
		
		if (!entityPlayer or (entityPlayer and (!entityPlayer:Alive() or entityPlayer:GetMoveType() ~= MOVETYPE_OBSERVER))) then
			if player:GetMoveType() == MOVETYPE_WALK then
				player:EmitSound("physics/body/body_medium_impact_soft"..math.random(1, 7)..".wav");
			end
			
			Clockwork.storage:Open(player, {
				name = "Corpse",
				weight = 8,
				entity = entity,
				distance = 192,
				cash = entity.cash,
				inventory = entity.cwInventory,
				OnGiveCash = function(player, storageTable, cash)
					entity.cash = storageTable.cash;
				end,
				OnTakeCash = function(player, storageTable, cash)
					entity.cash = storageTable.cash;
				end
			});
		end;
		
		player.JustOpenedContainer = true;
		hook.Run("PreOpenedContainer", player, entity)
	elseif (class == "cw_belongings" and (arguments == "cw_belongingsOpen" or arguments == "cwBelongingsOpen")) then
		if player:GetMoveType() == MOVETYPE_WALK then
			player:EmitSound("physics/cardboard/cardboard_box_break3.wav");
		end
		
		Clockwork.storage:Open(player, {
			name = "Belongings",
			weight = 100,
			entity = entity,
			distance = 192,
			cash = entity.cash,
			inventory = entity.cwInventory,
			OnGiveCash = function(player, storageTable, cash)
				entity.cash = storageTable.cash;
			end,
			OnTakeCash = function(player, storageTable, cash)
				entity.cash = storageTable.cash;
			end,
			OnClose = function(player, storageTable, entity)
				if (IsValid(entity)) then
					local invEmpty = true;
					
					if entity.cwInventory then
						for k, v in pairs(entity.cwInventory) do
							if v and !table.IsEmpty(v) then
								invEmpty = false;
								break;
							end
						end
					end
					
					if ((!entity.cwInventory and !entity.cash) or (invEmpty and (entity.cash == 0 or !entity.cash)) or (!entity.cwInventory and entity.cash == 0)) then
						entity:Explode(entity:BoundingRadius() * 2);
						entity:Remove();
					end;
				end;
			end,
			CanGiveItem = function(player, storageTable, itemTable)
				return false;
			end
		});
		
		player.JustOpenedContainer = true;
		hook.Run("PreOpenedContainer", player, entity)
	elseif (class == "cw_radio") then
		if (option == "Set Frequency" and type(arguments) == "string") then
			if !entity:IsStatic() or (entity:IsStatic() and player:IsAdmin()) then
				if ( string.find(arguments, "^%d%d%d%.%d$") ) then
					local start, finish, decimal = string.match(arguments, "(%d)%d(%d)%.(%d)");
					
					start = tonumber(start);
					finish = tonumber(finish);
					decimal = tonumber(decimal);
					
					if (start == 1 and finish > 0 and finish < 10 and decimal > 0 and decimal < 10) then
						entity:SetFrequency(arguments);
						
						Schema:EasyText(player, "olivedrab", "You have set this stationary radio's arguments to "..arguments..".");
					else
						Schema:EasyText(player, "peru", "The radio arguments must be between 101.1 and 199.9!");
					end;
				else
					Schema:EasyText(player, "peru", "The radio arguments must look like xxx.x!");
				end;
			else
				Schema:EasyText(player, "peru", "This radio cannot be tampered with!");
			end;
		elseif (arguments == "cw_radioToggle") then
			entity:Toggle();
		elseif (arguments == "cw_radioTake") then
			if !entity:IsStatic() or (entity:IsStatic() and player:IsAdmin()) then
				local instance = Clockwork.item:CreateInstance("stationary_radio");
				local success, fault = player:GiveItem(instance);
				
				if (!success) then
					Schema:EasyText(entity, "chocolate", fault);
				else
					entity:Remove();
				end;
			else
				Schema:EasyText(player, "peru", "This radio cannot be tampered with!");
			end
		end
	elseif ((arguments == "cwUntieCinderBlock" and entity:GetNWBool("BIsCinderBlock") == true) or IsValid(entity:GetNWEntity("CinderBlock"))) then
		if (class == "prop_physics") then
			entity:Remove()
		else
			if (IsValid(entity.CinderBlock)) then
				entity.CinderBlock:Remove()
			end
		end
		
		player:GiveItem(Clockwork.item:CreateInstance("cinder_block"), true)
		--player:GiveItem(Clockwork.item:CreateInstance("length_of_rope"), true)
	elseif (class == "cw_gramophone" and arguments == "cwToggleGramophone") then
		entity:Toggle();
	elseif (class == "cw_siege_ladder" and arguments == "cwTearDownSiegeLadder") then
		if entity:GetNWEntity("owner") == player then
			local itemTable = Clockwork.item:CreateInstance("siege_ladder");
			
			if itemTable then
				if entity.strikesRequired < 15 then
					itemTable:SetCondition(math.Round(100 * (entity.strikesRequired / 15)));
				end
			
				player:GiveItem(itemTable);
				
				if !player.cwObserverMode then
					local pickupSound = "generic_ui/ui_llite_0"..tostring(math.random(1, 3))..".wav";
					
					player:EmitSound(pickupSound);
					player:FakePickup(entity);
				end
			end
		
			entity:Remove();
		end
	end;
	
	if (arguments == "cwContainerOpen") then
		player.JustOpenedContainer = true;
		hook.Run("PreOpenedContainer", player, entity)
	end;
	
	if (class == "prop_physics" and arguments == "cw_breakdown") then
		self:BreakObject(player, entity);
	end;
end;

-- Called when a chat box message has been added.
function Schema:ChatBoxMessageAdded(info)
	if (info.class == "ic") then
		local eavesdroppers = {};
		local talkRadius = Clockwork.config:Get("talk_radius"):Get();
		local listeners = {};
		local radiospies = {};
		local radios = ents.FindByClass("cw_radio");
		local data = {};
		local jammed = false;
		for k, v in ipairs(radios) do
			if (!v:IsOff() and !v:IsCrazy() and info.speaker:GetPos():Distance(v:GetPos()) <= 80) then
				if info.speaker:GetEyeTrace().Entity == v then
					local frequency = v:GetFrequency();
					
					if (frequency != "") then
						info.shouldSend = false;
						info.listeners = {};
						data.frequency = frequency;
						data.position = v:GetPos();
						data.entity = v;
						
						break;
					end;
				end
			end;
		end;
		
		local dataFreq = data.frequency;
		
		if (IsValid(data.entity) and dataFreq != "") then
			local speaker = info.speaker;
			local dataPos = data.position;
			
			for k, v in pairs( _player.GetAll()) do
				if (v:HasInitialized() and v:Alive() and !v:IsRagdolled(RAGDOLL_FALLENOVER)) then
					local plyPos = v:GetPos();
					if (v:GetCharacterData("radioState", false) and v:HasItemByID("ecw_radio")) then
						table.insert(radiospies, v);
						if ((v:GetCharacterData("radioJamming", false)) and (v:GetCharacterData("frequency") == dataFreq)) then
							info.text = "<STATIC>"
							jammed = true
						end
					elseif ((v:GetCharacterData("frequency") == dataFreq and v:GetSharedVar("tied") == 0 and v:HasItemByID("handheld_radio") and v:GetCharacterData("radioState", false)) or speaker == v) then
						local lastZone = v:GetCharacterData("LastZone");
						
						if lastZone == "tower" or lastZone == "wasteland" then
							table.insert(listeners, v);
						end
							
						if speaker ~= v then
							if not v:IsNoClipping() and not v.cwWakingUp then
								if lastZone == "tower" or lastZone == "wasteland" or lastZone == "caves" or lastZone == "scrapper" then
									v:EmitSound("radio/radio_out"..tostring(math.random(2, 3))..".wav", 75, math.random(95, 100), 0.75, CHAN_AUTO);
								end
							end
						end
					elseif (plyPos:DistToSqr(dataPos) <= (talkRadius * talkRadius)) then
						table.insert(eavesdroppers, v);
					end;
				end;
			end;
			
			for k, v in ipairs(radios) do
				local radioPosition = v:GetPos();
				local radioFrequency = v:GetFrequency();
				
				if (!v:IsOff() and !v:IsCrazy() and radioFrequency == data.frequency) then
					for k2, v2 in pairs( _player.GetAll()) do
						if (v2:HasInitialized() and !table.HasValue(listeners, v2) and !table.HasValue(eavesdroppers, v2)) then
							if (v2:GetPos():DistToSqr(radioPosition) <= (talkRadius * talkRadius)) then
								table.insert(listeners, v2);
							end;
						end;
					end;
					
					v:EmitSound("radio/radio_out"..tostring(math.random(2, 3))..".wav", 75, math.random(95, 100), 0.75, CHAN_AUTO);
				end;
			end;
			
			if (!table.IsEmpty(listeners)) then
				Clockwork.chatBox:Add(listeners, info.speaker, "radio", info.text);
			end;
			
			if (!table.IsEmpty(eavesdroppers)) then
				Clockwork.chatBox:Add(eavesdroppers, info.speaker, "radio_eavesdrop", info.text);
			end;
			
			if (!table.IsEmpty(radiospies)) then
				if jammed then
					Clockwork.chatBox:Add(radiospies, info.speaker, "radiospy",  info.text);
				else
					Clockwork.chatBox:Add(radiospies, info.speaker, "radiospy",  "["..info.speaker:GetCharacterData("frequency", "100.0").."]: \""..info.text.."\"");
				end
			end;
		end;
	end;
end;

-- Called when a player has used their radio.
function Schema:PlayerRadioUsed(player, text, listeners, eavesdroppers)
	local newEavesdroppers = {};
	local talkRadius = Clockwork.config:Get("talk_radius"):Get() * 2;
	local frequency = player:GetCharacterData("frequency");
	
	local playerCount = _player.GetCount();
	local players = _player.GetAll();

	for k, v in ipairs(ents.FindByClass("cw_radio")) do
		local radioPosition = v:GetPos();
		local radioFrequency = v:GetFrequency();
		
		if (!v:IsOff() and !v:IsCrazy() and radioFrequency == frequency) then
			for i = 1, playerCount do
				local v2, k2 = players[i], i;
				if ( v2:HasInitialized() and !listeners[v2] and !eavesdroppers[v2] ) then
					if (v2:GetPos():DistToSqr(radioPosition) <= (talkRadius * talkRadius)) then
						newEavesdroppers[v2] = v2;
					end;
				end;
				
				break;
			end;
		end;
	end;
	
	if (!table.IsEmpty(newEavesdroppers)) then
		Clockwork.chatBox:Add(newEavesdroppers, player, "radio_eavesdrop", text);
	end;
end;

-- Called when a player's radio info should be adjusted.
function Schema:PlayerAdjustRadioInfo(player, info)
	--[[for k, v in ipairs( _player.GetAll() ) do
		if ( v:HasInitialized() and v:HasItem("handheld_radio")) then
			if ( v:GetCharacterData("frequency") == player:GetCharacterData("frequency") ) then
				if (v:GetSharedVar("tied") == 0) then
					info.listeners[v] = v;
				end;
			end;
		end;
	end;]]--
end;

-- Called when a player's drop weapon info should be adjusted.
function Schema:PlayerAdjustDropWeaponInfo(player, info)
	if (Clockwork.player:GetWeaponClass(player) == info.itemTable.weaponClass) then
		info.position = player:GetShootPos();
		info.angles = player:GetAimVector():Angle();
	else
		local gearTable = {
			Clockwork.player:GetGear(player, "Primary"),
			Clockwork.player:GetGear(player, "Secondary"),
			Clockwork.player:GetGear(player, "Tertiary")
		};
		
		for k, v in pairs(gearTable) do
			if (IsValid(v)) then
				local gearItemTable = v:GetItemTable();
				
				if (gearItemTable and gearItemTable.weaponClass == info.itemTable.weaponClass) then
					local position, angles = v:GetRealPosition();
					
					if (position and angles) then
						info.position = position;
						info.angles = angles;
						
						break;
					end;
				end;
			end;
		end;
	end;
end;

-- Called when a player has an unknown inventory item.
function Schema:PlayerHasUnknownInventoryItem(player, inventory, item, amount)
	if (item == "radio") then
		inventory["handheld_radio"] = amount;
	end;
end;

-- Called when a player's default inventory is needed.
function Schema:GetPlayerDefaultInventory(player, character, inventory)
	if (character.faction == FACTION_WASTELANDER) then
		Clockwork.inventory:AddInstance(
			inventory, Clockwork.item:CreateInstance("handheld_radio")
		);
	end;
end;

-- Called when a player's inventory item has been updated.
function Schema:PlayerInventoryItemUpdated(player, itemTable, amount, force)
	local clothes = player:GetCharacterData("clothes");
	
	if (clothes == itemTable.index) then
		if (!player:HasItemByID(itemTable.uniqueID)) then
			itemTable:OnChangeClothes(player, false);
			
			player:SetCharacterData("clothes", nil);
		end;
	end;
end;

-- Called when a player switches their flashlight on or off.
function Schema:PlayerSwitchFlashlight(player, on)
	if (on and player:GetNetVar("tied") != 0) then
		return false;
	end;
end;

-- Called when a player's storage should close.
function Schema:PlayerStorageShouldClose(player, storage)
	local entity = player:GetStorageEntity();
	
	if (player.searching and entity:IsPlayer() and entity:GetNetVar("tied") == 0) then
		return true;
	end;
end;

-- Called when a player attempts to spray their tag.
function Schema:PlayerSpray(player)
	return true;
end;

-- Called when a player presses F3.
function Schema:ShowSpare1(player)
	local itemTable = player:FindItemByID("bindings");
	
	if (!itemTable) then
		Schema:EasyText(player, "chocolate", "You have nothing to tie with!");
		
		return;
	end;

	Clockwork.player:RunClockworkCommand(player, "InvAction", "use", itemTable("uniqueID"), tostring(itemTable("itemID")));
end;

-- Called when a player presses F4.
function Schema:ShowSpare2(player)
	Clockwork.player:RunClockworkCommand(player, "CharSearch");
end;

-- Called when a player's footstep sound should be played.
function Schema:PlayerFootstep(player, position, foot, soundString, volume, recipientFilter)
	-- Moving all of this shit to the client, but the code needs to remain for the wakeup sequence as footsteps can only be forced serverside.
	
	local running = nil;
	
	if (player:IsRunning()) then
		running = true;
	end;
	
	if !player.cwWakingUp then
		if cwPowerArmor and player.wearingPowerArmor then
			if running then
				util.ScreenShake(player:GetPos(), 2, 1, 0.5, 750)
			else
				util.ScreenShake(player:GetPos(), 1, 1, 0.5, 750)
			end
			
			return true;
		end
	else
		if cwPowerArmor and player.wearingPowerArmor then
			if running then
				local runSounds = {
					"npc/dog/dog_footstep1.wav",
					"npc/dog/dog_footstep2.wav",
					"npc/dog/dog_footstep3.wav",
					"npc/dog/dog_footstep4.wav",
				}; 
				
				player:EmitSound(runSounds[math.random(1, #runSounds)]);
				util.ScreenShake(player:GetPos(), 2, 1, 0.5, 750)
			else
				local walkSounds = {
					"npc/dog/dog_footstep_walk01.wav",
					"npc/dog/dog_footstep_walk02.wav",
					"npc/dog/dog_footstep_walk03.wav",
					"npc/dog/dog_footstep_walk04.wav",
					"npc/dog/dog_footstep_walk05.wav",
					"npc/dog/dog_footstep_walk06.wav",
					"npc/dog/dog_footstep_walk07.wav",
					"npc/dog/dog_footstep_walk08.wav",
					"npc/dog/dog_footstep_walk09.wav",
					"npc/dog/dog_footstep_walk10.wav"
				};
				
				player:EmitSound(walkSounds[math.random(1, #walkSounds)]);
				util.ScreenShake(player:GetPos(), 1, 1, 0.5, 750)
			end
			
			return true;
		end
		
		if (player:Crouching() and player:HasBelief("nimble")) or player.cloaked then
			return true;
		end;
		
		local clothesItem = player:GetClothesItem();
		
		if (clothesItem) then
			if (running) then
				if (clothesItem.runSound) then
					if (type(clothesItem.runSound) == "table") then
						player:EmitSound(clothesItem.runSound[math.random(1, #clothesItem.runSound)], 65, math.random(95, 100), 0.5);
					else
						player:EmitSound(clothesItem.runSound, 65, math.random(95, 100), 0.50);
					end;
				end;
			elseif (clothesItem.walkSound) then
				if (type(clothesItem.walkSound) == "table") then
					player:EmitSound(clothesItem.walkSound[math.random(1, #clothesItem.walkSound)], 65, math.random(95, 100), 0.5);
				else
					player:EmitSound(clothesItem.walkSound, 65, math.random(95, 100), 0.5);
				end;
			end;
		end;
		
		player:EmitSound(soundString);
		
		return true;
	end
end;

-- Called when a player spawns an object.
function Schema:PlayerSpawnObject(player)
	if (player:GetNetVar("tied") != 0) then
		Schema:EasyText(player, "firebrick", "You don't have permission to do this right now!");
		
		return false;
	end;
end;

-- Called when a player attempts to breach an entity.
function Schema:PlayerCanBreachEntity(player, entity)
	if (string.lower(entity:GetClass()) == "func_door_rotating") then
		return false;
	end;
	
	if (Clockwork.entity:IsDoor(entity)) then
		if (!Clockwork.entity:IsDoorFalse(entity)) then
			return true;
		end;
	end;
end;

-- Called when a player attempts to use the radio.
function Schema:PlayerCanRadio(player, text, listeners, eavesdroppers)
	if (player:HasItemByID("handheld_radio")) or (player:HasItemByID("ecw_radio")) then
		if player:GetCharacterData("radioState", false) ~= true then
			Schema:EasyText(player, "peru", "Your radio is turned off!");
			
			return false;
		end
	
		if (!player:GetCharacterData("frequency")) then
			Schema:EasyText(player, "peru", "You need to set the radio frequency first!");
			
			return false;
		end;
		
		local lastZone = player:GetCharacterData("LastZone");
		
		if (player:HasItemByID("ecw_radio")) then
			return true
		elseif lastZone ~= "wasteland" and lastZone ~= "tower" then
			Schema:EasyText(player, "peru", "Your radio cannot get a signal here!");
			
			return false;
		end
	else
		Schema:EasyText(player, "chocolate", "You do not own a radio!");
		
		return false;
	end;
	
	return true;
end;

-- Called when a player spawns for the first time.
function Schema:PlayerInitialSpawn(player)
	player:SetNetVar("customClass", "");
	player:SetNetVar("permaKilled", false);
	
	if !self.autoTieEnabled or player:IsAdmin() then
		player:SetNetVar("tied", 0);
	end
end;

-- Called when a player attempts to use an entity in a vehicle.
function Schema:PlayerCanUseEntityInVehicle(player, entity, vehicle)
	if (entity:IsPlayer() or Clockwork.entity:IsPlayerRagdoll(entity)) then
		return true;
	end;
end;

local voltistSounds = {"npc/scanner/combat_scan4.wav", "npc/scanner/combat_scan5.wav", "npc/scanner/combat_scan1.wav", "npc/scanner/combat_scan2.wav", "npc/scanner/combat_scan3.wav", "npc/scanner/cbot_servochatter.wav", "npc/scanner/scanner_talk1.wav", "npc/scanner/scanner_talk2.wav"};
local voltistYellSounds = {"npc/scanner/scanner_siren2.wav", "npc/scanner/scanner_pain2.wav", "npc/stalker/go_alert2.wav"};

function Schema:PlayerSayICEmitSound(player)
	if player:GetSubfaith() == "Voltism" then
		if cwBeliefs and (player:HasBelief("the_storm") or player:HasBelief("the_paradox_riddle_equation")) then
			if !Clockwork.player:HasFlags(player, "T") then
				player:EmitSound(voltistSounds[math.random(1, #voltistSounds)], 90, 150);
			end
		end
	end
end

function Schema:PlayerYellEmitSound(player)
	if player:GetSubfaith() == "Voltism" then
		if cwBeliefs and (player:HasBelief("the_storm") or player:HasBelief("the_paradox_riddle_equation")) then
			if !Clockwork.player:HasFlags(player, "T") then
				player:EmitSound(voltistYellSounds[math.random(1, #voltistYellSounds)], 90, 150);
			end
		end
	end
end

-- Called when a player presses a key.
function Schema:KeyPress(player, key)
	if (key == IN_USE) then
		local untieTime = 6;
		local target = player:GetEyeTraceNoCursor().Entity;
		local entity = target;
		
		if player.HasBelief and player:HasBelief("dexterity") then
			untieTime = 6;
		end
		
		if (IsValid(target)) then
			target = Clockwork.entity:GetPlayer(target);
			
			if (target and player:GetNetVar("tied") == 0) then
				if (target:GetShootPos():Distance(player:GetShootPos()) <= 192) then
					if (target:GetNetVar("tied") != 0) then
						Clockwork.player:SetAction(player, "untie", untieTime);
						
						Clockwork.player:EntityConditionTimer(player, target, entity, untieTime, 192, function()
							return player:Alive() and !player:IsRagdolled() and !player:HasGodMode() and player:GetNetVar("tied") == 0;
						end, function(success)
							if (success) then
								self:TiePlayer(target, false);
								
								--player:ProgressAttribute(ATB_DEXTERITY, 15, true);
							end;
							
							Clockwork.player:SetAction(player, "untie", false);
						end);
					end;
				end;
			end;
		end;
	elseif (key == IN_ATTACK) then
		local action = Clockwork.player:GetAction(player);
		
		if (action == "reloading") then
			if player.itemUsing and IsValid(player.itemUsing) then
				player.itemUsing.beingUsed = false;
				player.itemUsing = nil;
			end
			
			Clockwork.player:SetAction(player, nil);
		elseif (action == "mutilating") or (action == "skinning") then
			Clockwork.player:SetAction(player, nil);
		elseif (action == "bloodTest") then
			Clockwork.chatBox:AddInTargetRadius(player, "me", "stops the blood test.", player:GetPos(), config.Get("talk_radius"):Get() * 2);
			Clockwork.player:SetAction(player, nil);
		end
	end;
end;

-- Called each frame that a player is dead.
function Schema:PlayerDeathThink(player)
	if (player:GetCharacterData("permakilled")) then
		return true;
	end;
end;

-- Called when a player attempts to switch to a character.
function Schema:PlayerCanSwitchCharacter(player, character)
	if (player:GetCharacterData("permakilled")) then
		if !player.wineRepetitions then
			return true;
		end
	end;
	
	if (player:GetNetVar("tied") != 0) then
		return false, "You cannot switch to this character while tied!";
	end;
	
	if player.beingSacrificed then
		return false, "You cannot switch to this character while being sacrificed!";
	end
	
	if player.sacrificing then
		return false, "You cannot switch to this character while sacrificing someone!";
	end
	
	if player.teleporting then
		return false, "You cannot switch to this character while in the process of teleporting!";
	end
end;

-- Called when a player's death info should be adjusted.
function Schema:PlayerAdjustDeathInfo(player, info)
	if (player:GetCharacterData("permakilled")) then
		info.spawnTime = 0;
	end;
end;

-- Called when a player attempts to delete a character.
function Schema:PlayerCanDeleteCharacter(player, character)
	if (character.data["permakilled"]) then
		return true;
	end;
end;

-- Called when a player attempts to use a character.
function Schema:PlayerCanUseCharacter(player, character)
	if (character.data["permakilled"]) then
		return character.name.." is permanently killed and cannot be used!";
	end;
end;

-- Called when a player's character screen info should be adjusted.
function Schema:PlayerAdjustCharacterScreenInfo(player, character, info)
	if (character.data["permakilled"]) then
		info.details = "This character is permanently killed.";
	end;

	if (character.data["customclass"]) then
		info.customClass = character.data["customclass"];
	end;
	
	if (character.data["rank"]) then
		info.rank = character.data["rank"];
	end
end;

-- Called when a player attempts to use a tool.
function Schema:CanTool(player, trace, tool) end;

-- Called when a player's shared variables should be set.
function Schema:OnePlayerSecond(player, curTime, infoTable)
	--player:SetNetVar("customClass", player:GetCharacterData("customclass", ""));
	player:SetNetVar("clothes", player:GetCharacterData("clothes", 0));

	--[[if (player:Alive() and !player:IsRagdolled() and player:GetVelocity():Length() > 0) then
		local inventoryWeight = player:GetInventoryWeight();
		
		if (inventoryWeight >= player:GetMaxWeight() / 4) then
			player:ProgressAttribute(ATB_STRENGTH, inventoryWeight / 400, true);
		end;
	end;]]--
end;

-- Called when an entity is created.
function Schema:OnEntityCreated(entity)
	if (entity:GetClass() == "prop_physics") then
		timer.Simple(FrameTime(), function()
			if (IsValid(entity)) then
				if (string.find(entity:GetModel(), "wood_crate")) then
					if (entity:GetSkin() != 1) then
						entity:SetSkin(1);
					end;
				end;
			end;
		end);
	end;
end;

local bannedents = {
	["prop_door_rotating"] = true,
	["func_door"] = true,
	["prop_door"] = true,
	["cw_salesman"] = true,
	["func_brush"] = true,
}

function Schema:PhysgunPickup(player, entity)
	if (entity.PopeSpeaker or bannedents[entity:GetClass()]) then
		return false;
	end;
end;

local randomspeaks = {
	"kronos/pa/new/feedback2.mp3",
	"kronos/pa/new/feedback3.mp3",
	"kronos/pa/new/feedback4.mp3",
	"kronos/pa/feedback6.mp3",
	"kronos/pa/feedback3.mp3",
}

-- Called every tick.
function Schema:Think()
	local curTime = CurTime();
	
	--[[if (!self.nextPAran or self.nextPAran < curTime) then
		self.nextPAran = curTime + math.random(600, 1200);
		
		local ra = table.Random(PopeSpeas)
		if (IsValid(ra)) then
			ra:EmitSound(table.Random(randomspeaks), 60);
		end;
	end;]]--
	
	--[[if (!self.nextCookCheck or curTime > self.nextCookCheck) then
		self.nextCookCheck = curTime + 2;

		local cookItems = {};
		
		for k, v in pairs (ents.FindByClass("cw_item")) do
			local itemTable = v:GetItemTable();
			
			if (itemTable and itemTable("canBeCooked")) then
				cookItems[#cookItems + 1] = v;
			end;
		end;
		
		for k, v in pairs (cookItems) do
			if (IsValid(v)) then
				local position = v:GetPos();
				local found = false;
				
				for k2, v2 in pairs (ents.FindInSphere(position, 32)) do
					if (v2:IsOnFire() or v2.OnFire or v2:GetClass() == "env_fire") then
						found = true;
					end;
				end;
				
				if (found) then
					local itemTable = v:GetItemTable();

					if (!v.CookLevels) then
						v.CookLevels = 1;
					else
						v.CookLevels = v.CookLevels + 1;
					end;
					
					v:Ignite(1, 0);
					v:EmitSound("ambient/fire/mtov_flame2.wav");
					
					if (v.CookLevels >= (itemTable("cookRequirement") or 5)) then
						local uniqueID = itemTable("uniqueID");
						local cookedName = string.Replace(uniqueID, "uncooked", "cooked");
						local player = v.cwHoldingGrab:GetOwner();
						
						if (Clockwork.item:FindByID(cookedName) and IsValid(player)) then
							player:UpdateInventory(cookedName, 1);
							
							v:EmitSound("ambient/fire/ignite.wav", 65);
							v:Remove();
						end;
					end;
				end;
			end;
		end;
	end;]]--
	
	if (!self.nextCinderBlock or self.nextCinderBlock < curTime) then
		self.nextCinderBlock = curTime + 3
		
		if (!map) then
			return;
		end;
		
		local entities = ents.GetAll()
		local count = ents.GetCount()
		
		for i = 1, count do
			local entity = entities[i]
			
			if (entity:GetClass() != "prop_physics" or entity:WaterLevel() < 1) then
				continue
			end
			
			if (entity:GetNWBool("BIsCinderBlock")) then
				local physObj = entity:GetPhysicsObject()
				
				if (IsValid(physObj) and physObj:GetMass() < 100000) then
					physObj:SetMass(100000)
				end
			end
		end
	end
	
	if (!self.nextNpcSpawn or self.nextNpcSpawn < curTime) then
		if (!map) then
			return;
		end;
		
		if self.npcSpawnsEnabled ~= false then
			if self.spawnedNPCS and self.maxNPCS and #self.spawnedNPCS < self.maxNPCS then
				if math.random(1, 6) == 1 then
					local goreNPCs = {"npc_animal_bear", "npc_animal_deer", "npc_animal_goat"};
					local npcName = goreNPCs[math.random(1, #goreNPCs)];
					local spawnPos = self.npcSpawns["gore"][math.random(1, #self.npcSpawns["gore"])];
					
					if math.random(1, 20) == 1 then
						npcName = "npc_animal_cave_bear";
					end
					
					if npcName and spawnPos then
						local entity = ents.Create(npcName);
						
						if IsValid(entity) then
							entity:SetPos(spawnPos + Vector(0, 0, 32));
							entity:SetAngles(Angle(0, math.random(1, 359), 0));
							entity:Spawn();
							entity:Activate();
							
							table.insert(self.spawnedNPCS, entity:EntIndex());
						end
					end
				else
					local spawnPos = self.npcSpawns["wasteland"][math.random(1, #self.npcSpawns["wasteland"])];
					local thrallNPCs;
					
					if cwDayNight and cwDayNight.currentCycle == "night" then
						--thrallNPCs = {"cw_suitor", "cw_shambler"};
						thrallNPCs = {"npc_bgt_suitor", "npc_bgt_eddie"};
					else
						--thrallNPCs = {"cw_another", "cw_brute", "cw_grunt", "cw_ed"};
						thrallNPCs = {"npc_bgt_another", "npc_bgt_brute", "npc_bgt_grunt", "npc_bgt_eddie"};
					end
					
					local npcName = thrallNPCs[math.random(1, #thrallNPCs)];
					
					if math.random(1, 40) == 1 then
						--npcName = "cw_otis";
						npcName = "npc_bgt_otis";
					end
					
					ParticleEffect("teleport_fx", spawnPos, Angle(0,0,0), nil);
					sound.Play("misc/summon.wav", spawnPos, 100, 100);
					
					timer.Simple(0.75, function()
						local entity = cwZombies:SpawnThrall(npcName, spawnPos, Angle(0, math.random(1, 359), 0));
						
						if IsValid(entity) then
							table.insert(self.spawnedNPCS, entity:EntIndex())
						end
					end);
				end
			end
		end
		
		self.nextNpcSpawn = curTime + 60;
	end
end;

-- Called at an interval while a player is connected.
function Schema:PlayerThink(player, curTime, infoTable, alive, initialized)
	--[[if (player:Alive() and !player:IsRagdolled()) then
		if (!player:InVehicle() and player:GetMoveType() == MOVETYPE_WALK) then
			if (player:IsInWorld()) then
				if (!player:IsOnGround()) then
					player:ProgressAttribute(ATB_ACROBATICS, 0.25, true);
				elseif (infoTable.running) then
					player:ProgressAttribute(ATB_AGILITY, 0.125, true);
				elseif (infoTable.jogging) then
					player:ProgressAttribute(ATB_AGILITY, 0.0625, true);
				end;
			end;
		end;
	end;]]--
	
	--[[local acrobatics = Clockwork.attributes:Fraction(player, ATB_ACROBATICS, 100, 50);
	local strength = Clockwork.attributes:Fraction(player, ATB_STRENGTH, 8, 4);
	local agility = Clockwork.attributes:Fraction(player, ATB_AGILITY, 50, 25);]]--
	
	--infoTable.inventoryWeight = player:GetMaxWeight();
	
	--[[infoTable.inventoryWeight = infoTable.inventoryWeight + strength;
	infoTable.jumpPower = infoTable.jumpPower + acrobatics;
	infoTable.runSpeed = infoTable.runSpeed + agility;]]--
	if initialized and alive then
		local faction = player:GetFaction();
		local bOnGround = player:IsOnGround();
		local moveType = player:GetMoveType();
		local waterLevel = player:WaterLevel();
		
		if (moveType == MOVETYPE_NOCLIP) then
			if (player.bOnGround) then
				player.bOnGround = nil;
			end;
			
			if (player.bWasInAir) then
				player.bWasInAir = nil;
			end;
		end;	
		
		if (bOnGround) then
			if (!player.bOnGround) then
				player.bOnGround = true;
			end;
			
			if (player.bWasInAir) then
				if (waterLevel >= 1 and waterLevel < 3) then
					hook.Run("HitGroundWater", player, player.bWasInAir);
				end;
				
				player.bWasInAir = nil;
			end;
		else
			if (player.bWasInAir) then
				if (waterLevel >= 1 and waterLevel < 3) then
					hook.Run("HitGroundWater", player, player.bWasInAir);
					
					player.bWasInAir = nil;
				end;
			end;
		
			if (player.bOnGround) then
				player.bWasInAir = player:GetPos().z;
				player.bOnGround = nil;
			end;
		end;
		
		local wages = Clockwork.class:Query(player:Team(), "coinslotWages", 0);
		
		if Schema.RanksToCoin[faction] then
			wages = Schema.RanksToCoin[faction][math.Clamp(player:GetCharacterData("rank", 1), 1, #Schema.RanksToCoin[faction])];
		end
		
		infoTable.coinslotWages = wages;
		
		if infoTable.coinslotWages > 0 then
			if !infoTable.nextCoinslotWages or infoTable.nextCoinslotWages < curTime then
				if !self.towerTreasury then
					self.towerTreasury = Clockwork.kernel:RestoreSchemaData("treasury")[1] or 0;
				end
				
				local collectableWages = player:GetCharacterData("collectableWages", 0);
				
				if collectableWages < 3 and self.towerTreasury > 0 then
					player:SetCharacterData("collectableWages", collectableWages + 1);
				end
				
				infoTable.nextCoinslotWages = curTime + 1800;
			end
		end;
		
		if (!player.nextOneSecond or player.nextOneSecond < curTime) then
			player.nextOneSecond = curTime + 1;
			
			local nextTeleport = player:GetCharacterData("nextTeleport");
			
			if nextTeleport and nextTeleport > 0 then
				player:SetCharacterData("nextTeleport", math.max(nextTeleport - 1, 0));
			end
			
			if (waterLevel >= 1) then
				if player:GetSubfaith() == "Voltism" and !Clockwork.player:HasFlags(player, "T") then
					if cwBeliefs and (player:HasBelief("the_storm") or player:HasBelief("the_paradox_riddle_equation")) then
						if player:Alive() and !player.cwObserverMode then
							if waterLevel == 1 then
								Schema:DoTesla(player, true);
							else
								Schema:DoTesla(player, false);
								player:DeathCauseOverride("Short-circuited in a body of water.");
								player:Kill();
							end
						end
					end
				end
			end
			
			if (player:GetMoveType() != MOVETYPE_NOCLIP) then
				if (player:IsRunning()) then
					if (player:HasTrait("clumsy")) then
						if (!player.lastClumsyFallen or player.lastClumsyFallen < curTime) then
							if (math.random(1, 4) == 4) then
								Clockwork.player:SetRagdollState(player, RAGDOLL_FALLENOVER, math.random(4, 7));
								Clockwork.chatBox:AddInTargetRadius(player, "me", "trips and falls like a fucking idiot!", player:GetPos(), config.Get("talk_radius"):Get() * 2);
							
								if (cwContainerHiding) then
									local sound = table.Random(cwContainerHiding.startleSounds["female"]);
									
									if (player:GetGender() == GENDER_MALE) then
										sound = table.Random(cwContainerHiding.startleSounds["male"]);
									end;
									
									player:EmitSound(sound);
									player:EmitSound("physics/wood/wood_crate_break"..math.random(1, 5)..".wav", 60);
								end;
								
								player:TakeDamage(2);
								player.lastClumsyFallen = curTime + 60;
							else
								player.lastClumsyFallen = curTime + 5;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
end;

-- Called when a player hits water.
function Schema:HitGroundWater(player, airZ)
	local position = player:GetPos();
	local difference = math.abs(position.z - airZ);
	
	if (difference > 512) then
		local world = GetWorldEntity();
		local damageInfo = DamageInfo();
			damageInfo:SetDamageType(DMG_FALL);
			damageInfo:SetDamage(35 * (difference / 512))
			damageInfo:SetAttacker(world)
			damageInfo:SetInflictor(world);
			damageInfo:SetDamagePosition(Vector(position.x, position.y, airZ));
		player:TakeDamageInfo(damageInfo);
	end;
end;

-- Called when an entity is removed.
function Schema:EntityRemoved(entity)
	if (entity.FireSound) then
		entity.FireSound:Stop();
		entity.FireSound = nil;
	end;
	
	if (IsValid(entity) and entity:GetClass() == "prop_ragdoll") then
		if (entity.cwInventory and entity.cash) then
			if (!table.IsEmpty(entity.cwInventory) or entity.cash > 0) then
				local invEmpty = true;
				
				for k, v in pairs(entity.cwInventory) do
					if v and !table.IsEmpty(v) then
						invEmpty = false;
						break;
					end
				end
				
				if !invEmpty then
					local belongings = ents.Create("cw_belongings");
					
					belongings:SetAngles(Angle(0, 0, -90));
					belongings:SetData(entity.cwInventory, entity.cash);
					belongings:SetPos(entity:GetPos() + Vector(0, 0, 32));
					belongings:Spawn();
					
					entity.cwInventory = nil;
					entity.cash = nil;
				end;
			end;
		end;
	end;
	
	if IsValid(entity) and (entity:IsNPC() or entity:IsNextBot()) and self.spawnedNPCS then
		for i = 1, #self.spawnedNPCS do
			if self.spawnedNPCS[i] == entity:EntIndex() then
				table.remove(self.spawnedNPCS, i);
				break;
			end
		end
	end
end;

-- Called when a player closes a storage entity.
function Schema:ClosedStorage(player, entity)
	if player:GetMoveType() == MOVETYPE_WALK then
		self:CloseSound(entity, player);
	end
	
	if (entity.IsBackpack) then
		if (Clockwork.inventory:IsEmpty(entity.cwInventory)) then
			self:DestroyBackpack(entity);
		end;
	end;
end;

-- Called just before a player opens a container.
function Schema:PreOpenedContainer(player, entity)
	local model = string.lower(entity:GetModel());
	
	if (cwStorage.containerList[model]) then
		local containerWeight = cwStorage.containerList[model][1] or 2;
		
		if (entity.cwPassword) then
			return;
		end;
		
		if player:GetMoveType() == MOVETYPE_WALK then
			self:OpenSound(entity, player);
		end
		
		if (hook.Run("CanOpenContainer", player, entity, containerWeight, true) or player.JustOpenedContainer) then
			player.JustOpenedContainer = nil;
			
			-- maybe remake this so it saves which containers have been checked by the same player or in the last 10 minutes or something.
			--[[if (math.random(1, 10) == 1 and player:Health() >= 50) then
				self:ClearAllItems(entity);
				
				return;
			end;]]--
			
			--[[
			local wealthTable = self:CalculateWealth(player);
			
			if (entity.cwInventory and !entity.Locked) then
				for k, v in pairs (entity.cwInventory) do
					local itemTable = Clockwork.item:FindByID(k);
					local category = string.lower(itemTable("category"));
					
					if (string.find(category, "tools")) then
						if ((#wealthTable["tools"] > math.random(2, 3)) and (math.random(1, 5) != 1)) then
							entity.cwInventory[k] = nil;
						end;
					elseif (string.find(category, "medical")) then
						if ((#wealthTable["medical"] >= math.random(2, 3)) and (player:Health() >= 50)) then
							entity.cwInventory[k] = nil;
						end;
					end;
					
					for k2, v2 in pairs (self.NoDuplicates) do
						if (k == v2 and player:HasItemByID(v2)) then
							entity.cwInventory[k] = nil;
						end;
					end;
				end;
			end;
			--]]
		end;
	end;
end;

-- A function to get if a player can open a container.
function Schema:CanOpenContainer(player, entity, weight, noCall)
	if (noCall) then
		return false;
	end;
	
	-- needs to be revisited
	--[[
	if (entity.Locked) then
		local toolTable = self:GetRequiredTool(entity);
		local hasTool = nil;
		local delay = nil;
		
		for k, v in pairs (toolTable) do
			local requiredTool = v[1];
			local toolDelay = v[2];
			
			if (player:HasItemByID(requiredTool)) then
				hasTool = requiredTool;
				delay = toolDelay;
				
				break;
			end;
		end;
		
		if (hasTool and delay) then
			timer.Create(entity:EntIndex().."_OpenSounds", math.Rand(0.5, (delay / 2)), math.Round(delay / 1), function()
				if (IsValid(entity) and IsValid(player)) then
					self:OpenSound(entity, player);
				else
					timer.Destroy(entity:EntIndex().."_OpenSounds")
				end;
			end);
			
			local physObj = entity:GetPhysicsObject();
			local model = entity:GetModel();
			local motionEnabled = true;

			if (IsValid(physObj)) then
				motionEnabled = physObj:IsMotionEnabled();
				physObj:EnableMotion(false);
			end;
			
			self:Slow(player, 0);

			if (string.find(model, "wood_crate")) then
				timer.Create(entity:EntIndex().."_BreakCheck", delay / 2.5, delay, function()
					if (IsValid(entity) and IsValid(player)) then
						if (math.random(1, 25) == 1) then
							self:RespawnProp(entity)
							
							entity.cwInventory = {};
							entity:Fire("break");
							
							self:Slow(player)
							Clockwork.player:SetAction(player, nil);
						end;
					else
						timer.Destroy(entity:EntIndex().."_BreakCheck")
					end;
				end);
			end;

			local containerName = "container";
			
			if (string.find(model, "trashdumpster01a") or string.find(model, "trashbin01a")) then
				containerName = "dumpster";
			elseif (string.find(model, "wood_crate")) then
				containerName = "crate";
			elseif (string.find(model, "controlroom")) then
				containerName = "cabinet";
			elseif (string.find(model, "ammocrate_")) then
				containerName = "car trunk";
			elseif (string.find(model, "oildrum001")) then
				containerName = "barrel";
			elseif (string.find(model, "oildrum001")) then
				containerName = "barrel";
			elseif (string.find(model, "furnituredrawer")) then
				containerName = "drawer";
			elseif (string.find(model, "filecabinet")) then
				containerName = "filing cabinet";
			end;

			Clockwork.player:SetAction(player, "opencontainer", delay, nil, function()
				if (IsValid(entity) and IsValid(player)) then
					local containerWeight = cwStorage.containerList[model][1] or 2;
					
					if (timer.Exists(entity:EntIndex().."_OpenSounds")) then
						timer.Destroy(entity:EntIndex().."_OpenSounds")
					end;
					
					if (timer.Exists(entity:EntIndex().."_BreakCheck")) then
						timer.Destroy(entity:EntIndex().."_BreakCheck")
					end;
					
					if (IsValid(physObj)) then
						physObj:EnableMotion(motionEnabled);
					end;
					
					player.JustOpenedContainer = true;
					self:Slow(player)
					entity.Locked = false;
					
					timer.Simple(FrameTime(), function()
						hook.Run("PreOpenedContainer", player, entity)
						cwStorage:OpenContainer(player, entity, containerWeight);
					end);
				end;
			end);
		else
			self:Notify(player, "You do not have the right tools to open this container!");
			
		end;
		
		return false;
	else
		return true;
	end;
	--]]
end;

-- Called each tick.
function Schema:Tick() end;

-- Called when a player's health is set.
function Schema:PlayerHealthSet(player, newHealth, oldHealth) end;

-- Called when a player attempts to be given a weapon.
function Schema:PlayerCanBeGivenWeapon(player, class, uniqueID, forceReturn) end;

-- Called when the player attempts to be ragdolled.
function Schema:PlayerCanRagdoll(player, state, delay, decay, ragdoll) end;

-- Called when a player attempts to NoClip.
function Schema:PlayerNoClip(player) end;

-- Called when a player's data should be saved.
function Schema:PlayerSaveData(player, data) end;

-- Called when a player's data should be restored.
function Schema:PlayerRestoreData(player, data) end;

-- Called to check if a player does have an flag.
function Schema:PlayerDoesHaveFlag(player, flag) end;

-- Called when a player's attribute has been updated.
function Schema:PlayerAttributeUpdated(player, attributeTable, amount) end;

-- Called to check if a player does recognise another player.
function Schema:PlayerDoesRecognisePlayer(player, target, status, isAccurate, realValue)
	local playerFaction = player:GetFaction();
	local targetFaction = target:GetFaction();
	local kinisgerOverride = target:GetSharedVar("kinisgerOverride");
	
	if kinisgerOverride then
		targetFaction = kinisgerOverride;
	end

	if targetFaction == "Holy Hierarchy" then
		return true;
	elseif targetFaction == "Gatekeeper" then
		if playerFaction == "Gatekeeper" or playerFaction == "Holy Hierarchy" then
			return true;
		end
	elseif targetFaction == "Pope Adyssa's Gatekeepers" then
		if playerFaction == "Pope Adyssa's Gatekeepers" or playerFaction == "Holy Hierarchy" then
			return true;
		end
	elseif targetFaction == "Goreic Warrior" and playerFaction == "Goreic Warrior" then
		return true;
	elseif target:GetFaction() == "Children of Satan" and playerFaction == "Children of Satan" then
		return true;
	end
end;

-- Called when attempts to use a command.
function Schema:PlayerCanUseCommand(player, commandTable, arguments)
	if (string.lower(commandTable.name) == "storageclose") then
		if player.cwStorageTab then
			local entity = player.cwStorageTab.entity;

			if (IsValid(entity) and IsValid(player)) then
				hook.Run("ClosedStorage", player, entity);
			end;
		end
	end;

	if (player:GetNetVar("tied") != 0) then
		local blacklisted = {
			"OrderShipment",
			"Broadcast",
			"Dispatch",
			"Request",
			"Radio"
		};
		
		if (table.HasValue(blacklisted, commandTable.name)) then
			Schema:EasyText(player, "firebrick", "You cannot use this command when you are tied!");
			
			return false;
		end;
	end;
end;

-- Called when a player attempts to use a door.
function Schema:PlayerCanUseDoor(player, door)
	if map then
		local doorName = door:GetName();
		
		if doorName == "toothboyblastdoor" or doorName == "toothboyblastdoor2" then
			if player:GetSubfaith() ~= "Voltism" then
				if !player.cwObserverMode then
					Schema:DoTesla(player, true);
					player:TakeStability(player:GetMaxStability() * 3);
				end
				
				return false;
			end
		elseif doorName == "castle_bigdoor1" or doorName == "castle_bigdoor2" then
			return false;
		end
	end
end;

-- Called when a player attempts to lock an entity.
function Schema:PlayerCanLockEntity(player, entity) end;

-- Called when a player attempts to unlock an entity.
function Schema:PlayerCanUnlockEntity(player, entity) end;

-- Called when a player's character has unloaded.
function Schema:PlayerCharacterUnloaded(player) end;

-- Called when a player attempts to change class.
function Schema:PlayerCanChangeClass(player, class)
	if (player:GetNetVar("tied") != 0) then
		Schema:EasyText(player, "peru", "You cannot change classes when you are tied!");
		
		return false;
	end;
end;

-- Called when a player attempts to use an entity.
function Schema:PlayerUse(player, entity)
	local curTime = CurTime();

	if (entity.bustedDown) then
		return false;
	end;
	
	if (player:GetNetVar("tied") != 0) then
		if (entity:IsVehicle()) then
			if (Clockwork.entity:IsChairEntity(entity) or Clockwork.entity:IsPodEntity(entity)) then
				return;
			end;
		end;
		
		if (!player.nextTieNotify or player.nextTieNotify < curTime) then
			Schema:EasyText(player, "peru", "You cannot use that when you are tied!");
			
			player.nextTieNotify = curTime + 2;
		end;
		
		return false;
	end;
end;

-- Called when a player attempts to destroy an item.
function Schema:PlayerCanDestroyItem(player, itemTable, noMessage)
	if (player:GetNetVar("tied") != 0) then
		if (!noMessage) then
			Schema:EasyText(player, "peru", "You cannot destroy items when you are tied!");
		end;
		
		return false;
	end;
end;

-- Called when a player attempts to drop an item.
function Schema:PlayerCanDropItem(player, itemTable, noMessage)
	if (player:GetNetVar("tied") != 0) then
		if (!noMessage) then
			Schema:EasyText(player, "peru", "You cannot drop items when you are tied!");
		end;
		
		return false;
	end;
end;

-- Called when a player attempts to use an item.
function Schema:PlayerCanUseItem(player, itemTable, noMessage)
	if (player:GetNetVar("tied") != 0) then
		if (!noMessage) then
			Schema:EasyText(player, "peru", "You cannot use items when you are tied!");
		end;
		
		return false;
	end;
	
	--[[if (Clockwork.item:IsWeapon(itemTable)) then
		return true
	end;]]--
end;

-- Called when a player attempts to earn generator cash.
function Schema:PlayerCanEarnGeneratorCash(player, info, cash) end;

-- Called when a player's death sound should be played.
function Schema:PlayerPlayDeathSound(player, gender) end;

-- Called when a player's pain sound should be played.
function Schema:PlayerPlayPainSound(player, gender, damageInfo, hitGroup) end;

local imbecileClasses = {
	"ic",
	"yell",
	"radio",
	"whisper",
	"prayer",
	"proclaim",
	"relay",
	"darkwhisper",
	"darkwhisperglobal",
	"darkwhispernondark",
	"darkwhisperreply",
	"darkwhispernoprefix",
	"ravenspeak",
	"ravenspeakclan",
	"ravenspeakfaction",
	"ravenspeakreply",
	"speaker"
};

-- Called when chat box info should be adjusted.
function Schema:ChatBoxAdjustInfo(info)
	if (IsValid(info.speaker) and info.speaker:HasInitialized()) then
		if table.HasValue(imbecileClasses, info.class) then
			if info.speaker:HasTrait("imbecile") then
				local imbecileText = info.text;
				
				if #imbecileText > 2 then
					local fillers = {"uh", "uhh", "uhhh", "erm", "ehh", "like"};
					local suffixes = {".", ",", ";", "!", ":", "?"};
					local splitText = string.Split(imbecileText, " ");
					local tourettes = {"ASSHOLE", "FUCKING", "FUCK", "ASS", "BITCH", "CUNT", "PENIS"};
					local vowels = {["upper"] = {"A", "E", "I", "O", "U"}, ["lower"] = {"a", "e", "i", "o", "u"}};
					
					for i = 1, #splitText do
						local currentSplit = splitText[i];
						
						if math.random(1, 2) == 1 then
							for j = 1, #currentSplit do
								for k = 1, 5 do
									local vowelShuffle = math.random(1, 5);
									
									currentSplit = string.gsub(currentSplit, vowels["upper"][k], vowels["upper"][vowelShuffle]);
									currentSplit = string.gsub(currentSplit, vowels["lower"][k], vowels["lower"][vowelShuffle]);
								end
							end
						elseif #currentSplit >= 2 then
							local characterToRepeat = math.random(1, #currentSplit - 1);
							local str = string.sub(currentSplit, characterToRepeat, characterToRepeat);
							
							currentSplit = string.gsub(string.SetChar(currentSplit, characterToRepeat, "#"), "#", str.."-"..string.lower(str));
						end
						
						if #currentSplit >= 2 and math.random(1, 3) == 1 then
							local suffix_found = false;
							
							for j = 1, #suffixes do
								if string.EndsWith(currentSplit, suffixes[j]) then
									suffix_found = true;
									break;
								end
							end
							
							if not suffix_found then
								if math.random(1, 10) == 1 then
									currentSplit = currentSplit.."- "..tourettes[math.random(1, #tourettes)].."!";
								else
									currentSplit = fillers[math.random(1, #fillers)];
								end
							end
						end
						
						if math.random(1, 6) == 1 then
							currentSplit = string.upper(currentSplit);
						end
						
						splitText[i] = currentSplit;
					end
					
					info.text = table.concat(splitText, " ");
				end;
			end;
		end
				
		return true;
	end;
end;

-- Called when a player destroys generator.
function Schema:PlayerDestroyGenerator(player, entity, generator) end;

-- Called just before a player dies.
function Schema:DoPlayerDeath(player, attacker, damageInfo)
	if !player.opponent then
		local clothes = player:GetCharacterData("clothes");
		
		if (clothes) then
			player:GiveItem(Clockwork.item:CreateInstance(clothes));
			player:SetCharacterData("clothes", nil);
		end;
	end
	
	player.beingSearched = nil;
	player.searching = nil;
	
	self:TiePlayer(player, false, true);
end;

-- Called when a player dies.
function Schema:PlayerDeath(player, inflictor, attacker, damageInfo)
	if !player.opponent then
		local bounty = player:GetCharacterData("bounty", 0);
		
		if bounty > 0 then
			if IsValid(attacker) and attacker:IsPlayer() and attacker:Alive() then
				Clockwork.player:GiveCash(attacker, bounty);
				
				player:RemoveBounty();
			end
		end
	end
	
	if player.banners then
		player.banners = {};
	end
	
	-- Gore sacrifice shit.
	if IsValid(attacker) and attacker:IsPlayer() and attacker:Alive() and player:GetFaction() ~= "Goreic Warrior" and attacker:GetFaction() == "Goreic Warrior" then
		if player:GetPos():WithinAABox(Vector(11622, -6836, 12500), Vector(8744, -10586, 11180)) then
			local catalysts = {"down_catalyst", "elysian_catalyst", "up_catalyst", "trinity_catalyst", "light_catalyst", "purifying_stone", "belphegor_catalyst", "pantheistic_catalyst", "familial_catalyst", "ice_catalyst"};
			local killXP = (cwBeliefs.xpValues["kill"] * 3) or 15;
			local level = player:GetCharacterData("level", 1);
			local numCatalysts = 0;
			
			if level >= 10 and level < 20 then
				numCatalysts = 1;
			elseif level >= 20 and level < 30 then
				numCatalysts = 2;
			elseif level >= 30 then
				numCatalysts = 3;
			end
			
			if numCatalysts > 0 then
				for i = 1, numCatalysts do
					attacker:GiveItem(item.CreateInstance(catalysts[math.random(1, #catalysts)]));
				end
				
				Clockwork.hint:Send(attacker, "You have gained "..tostring(numCatalysts).." random catalysts.", 5, Color(100, 175, 100), true, true);
			end
			
			killXP = killXP * math.Clamp(level, 1, 40);
			
			if attacker:GetSubfaction() == "Clan Crast" then	
				killXP = killXP * 2;
			
				local valid_players = {};
				
				for k, v in pairs(ents.FindInSphere(attacker:GetPos(), 1024)) do
					if v:IsPlayer() and v:GetFaction() == "Goreic Warrior" and !v.cwObserverMode then
						table.insert(valid_players, v);
					end
				end
				
				if #valid_players < 2 then
					attacker:HandleXP(killXP);
				else
					local xpPerPlayer = math.Round(killXP / #valid_players);
					
					for i = 1, #valid_players do
						valid_players[i]:HandleXP(xpPerPlayer);
					end
				end
				
				Clockwork.chatBox:AddInTargetRadius(attacker, "me", "strikes down "..player:Name().." as a sacrifice. Their blood seeps into the ground beneath the Great Tree and roots envelop their corpse. The usage of Clan Crast ritual chanting increases the fertility of the offering, thus enhancing the outcome and spreading its power to all those nearby.", attacker:GetPos(), config.Get("talk_radius"):Get() * 4);
			else
				attacker:HandleXP(killXP);
				Clockwork.chatBox:AddInTargetRadius(attacker, "me", "strikes down "..player:Name().." as a sacrifice. Their blood seeps into the ground beneath the Great Tree and roots envelop their corpse.", attacker:GetPos(), config.Get("talk_radius"):Get() * 4);
			end
			
			timer.Simple(1, function()
				if IsValid(player) then
					local ragdoll = player:GetRagdollEntity();
					
					if IsValid(ragdoll) then
						ragdoll:SetMaterial("models/props_pipes/pipesystem01a_skin2");
					end
				end
			end);
		end		
	end
end;

-- Called when a player changes ranks.
function Schema:PlayerChangedRanks(player)
	local faction = player:GetFaction();
	
	if (self.Ranks[faction]) then
		if (!player:GetCharacterData("rank")) then
			player:SetCharacterData("rank", 1);
		end;
		
		player:OverrideName(nil)
		local name = player:Name();

		for k, v in pairs (self.Ranks[faction]) do
			if (string.find(name, v)) then
				local newName = self:StripRank(name, v)
				Clockwork.player:SetName(player, string.Trim(newName));
			end;
		end;
		
		local rank = math.Clamp(player:GetCharacterData("rank", 1), 1, #self.Ranks[faction]);

		if (rank and isnumber(rank) and self.Ranks[faction][rank]) then
			player:OverrideName(self.Ranks[faction][rank].." "..player:Name());
		end;
	end;
end;

-- Called just after a player spawns.
function Schema:PostPlayerSpawn(player, lightSpawn, changeClass, firstSpawn)
	local curTime = CurTime();
	
	if (!player.nextSpawnRun or player.nextSpawnRun < curTime) then
		local bounty = player:GetCharacterData("bounty");
		local clothes = player:GetCharacterData("clothes");
		
		if (!lightSpawn) then
			Clockwork.datastream:Start(player, "ClearEffects", true);
			player.beingSearched = nil;
			player.searching = nil;
		end;

		if (player:GetNetVar("tied") != 0) then
			self:TiePlayer(player, true);
		end;
		
		if (clothes) then
			local itemTable = Clockwork.item:FindByID(clothes);
			
			if (itemTable and player:HasItemByID(itemTable.uniqueID)) then
				self:PlayerWearClothes(player, itemTable);
			else
				player:SetCharacterData("clothes", nil);
			end;
		end;
		
		if (!lightSpawn and firstSpawn and !player.cwWakingUp and !player.cwWoke) then
			if not player:IsBot() then
				self:PlayerWakeup(player);
			end
			
			player.cwWoke = true;
		end
		
		if bounty then
			player:SetSharedVar("bounty", bounty);
		end

		Clockwork.datastream:Start(player, "GetZone");
		
		player.nextSpawnRun = curTime + 1;
	end;
end;

-- Called when a player switches zones.
function Schema:PlayerChangedZones(player, uniqueID)
	self:SyncFogDistance(player, uniqueID)
end;

-- Called when a player spawns lightly.
function Schema:PostPlayerLightSpawn(player, weapons, ammo, special)
	local clothes = player:GetCharacterData("clothes");
	
	if (clothes) then
		local itemTable = Clockwork.item:FindByID(clothes);
		
		if (itemTable) then
			itemTable:OnChangeClothes(player, true);
		end;
	end;
end;

function Schema:PlayerCharacterLoaded(player)
	netstream.Start(player, "GetZone");
	
	if self.autoTieEnabled and !player:IsAdmin() then
		player:SetNetVar("tied", 1);
	end
	
	if player.banners then
		player.banners = {};
	end
	
	local faction = player:GetFaction();
	
	player:OverrideName(nil)
	
	if (self.Ranks[faction]) then
		if (!player:GetCharacterData("rank") or player:GetCharacterData("rank") < 1 or player:GetCharacterData("rank") > #self.Ranks[faction]) then
			local factionTable = Clockwork.faction:FindByID(faction);
			local subfaction = player:GetSubfaction();
			local subfactionRankFound = false;
			
			if subfaction and subfaction ~= "" and subfaction ~= "N/A" then
				if factionTable and factionTable.subfactions then
					for i = 1, #factionTable.subfactions do
						local isubfaction = factionTable.subfactions[i];
						
						if isubfaction.name == subfaction then
							if isubfaction.startingRank then
								player:SetCharacterData("rank", isubfaction.startingRank);
								subfactionRankFound = true;
							end
						end
					end
				end
			end
			
			if !subfactionRankFound then
				player:SetCharacterData("rank", 1);
			end
		end;

		local name = player:Name();
		
		for k, v in pairs (self.Ranks[faction]) do
			if (string.find(name, v)) then
				player:SetCharacterData("rank", k);
				local newName = self:StripRank(name, v)
				Clockwork.player:SetName(player, string.Trim(newName));
			end;
		end;
		
		local rank = math.Clamp(player:GetCharacterData("rank", 1), 1, #self.Ranks[faction]);
		
		if (rank and isnumber(rank) and self.Ranks[faction][rank]) then
			player:OverrideName(self.Ranks[faction][rank].." "..player:Name());
		end;
	end;
	
	if faction == "Goreic Warrior" then
		if player:GetSubfaction() == "Clan Crast" then
			if !Clockwork.player:HasFlags(player, "U") then
				Clockwork.player:GiveFlags(player, "U");
			end
		end
	elseif faction == "Gatekeepers" then
		local subfaction = player:GetSubfaction();
		
		if !subfaction or subfaction == "N/A" or subfaction == "" then
			player:SetCharacterData("Subfaction", "Legionary", true);
			
			timer.Simple(0.5, function()
				if IsValid(player) then
					Clockwork.player:LoadCharacter(player, Clockwork.player:GetCharacterID(player));
				end
			end);
		end
	end
	
	player.bWasInAir = nil;
end;

-- Called when a player throws a punch.
function Schema:PlayerPunchThrown(player)
	--player:ProgressAttribute(ATB_STRENGTH, 0.25, true);
end;

-- Called when a player punches an entity.
function Schema:PlayerPunchEntity(player, entity)
	--[[if (entity:IsPlayer() or entity:IsNPC() or entity:IsNextBot()) then
		player:ProgressAttribute(ATB_STRENGTH, 1, true);
	else
		player:ProgressAttribute(ATB_STRENGTH, 0.5, true);
	end;]]--
end;

-- Called when an entity has been breached.
function Schema:EntityBreached(entity, activator) end;

-- A function to scale damage by hit group.
function Schema:PlayerScaleDamageByHitGroup(player, attacker, hitGroup, damageInfo, baseDamage) end;

-- Called when a player's default model is needed.
function Schema:GetPlayerDefaultModel(player) end;

-- Called when an NPC has been killed.
function Schema:OnNPCKilled(npc, attacker, inflictor)
	if IsValid(npc) and self.spawnedNPCS then
		for i = 1, #self.spawnedNPCS do
			if self.spawnedNPCS[i] == npc:EntIndex() then
				table.remove(self.spawnedNPCS, i);
				break;
			end
		end
	end
end;

-- Called when a player's visibility should be set up.
function Schema:SetupPlayerVisibility(player) end;

-- Called when a player's typing display has started.
function Schema:PlayerStartTypingDisplay(player, code) end;

-- Called when a player's typing display has finished.
function Schema:PlayerFinishTypingDisplay(player, textTyped) end;

-- Called when a player stuns an entity.
function Schema:PlayerStunEntity(player, entity) end;

-- Called when a player's weapons should be given.
function Schema:PlayerGiveWeapons(player) end;

-- Called when a player attempts to spawn a prop.
function Schema:PlayerSpawnProp(player, model) end;

-- Called when a player attempts to restore a recognised name.
function Schema:PlayerCanRestoreRecognisedName(player, target) end;

-- Called when a player attempts to save a recognised name.
function Schema:PlayerCanSaveRecognisedName(player, target) end;

-- Called when a player's character has initialized.
function Schema:PlayerCharacterInitialized(player)
	if self.archivesBookList then
		netstream.Start(player, "Archives", self.archivesBookList);
	end
end;

-- Called when a player's name has changed.
function Schema:PlayerNameChanged(player, previousName, newName) end;

-- Called when a player uses a door.
function Schema:PlayerUseDoor(player, door) end;

-- Called when a player's limb damage is healed.
function Schema:PlayerLimbDamageHealed(player, hitGroup, amount)
	--[[if (hitGroup == HITGROUP_HEAD) then
		player:BoostAttribute("Limb Damage", ATB_MEDICAL, false);
	elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_STOMACH) then
		player:BoostAttribute("Limb Damage", ATB_ENDURANCE, false);
	elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
		player:BoostAttribute("Limb Damage", ATB_ACROBATICS, false);
		player:BoostAttribute("Limb Damage", ATB_AGILITY, false);
	elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
		player:BoostAttribute("Limb Damage", ATB_DEXTERITY, false);
		player:BoostAttribute("Limb Damage", ATB_STRENGTH, false);
	end;]]--
end;

-- Called when a player's limb damage is reset.
function Schema:PlayerLimbDamageReset(player)
	player:BoostAttribute("Limb Damage", nil, false);
end;

-- Called when a player's limb takes damage.
function Schema:PlayerLimbTakeDamage(player, hitGroup, damage)
	--[[local limbDamage = Clockwork.limb:GetDamage(player, hitGroup);
	
	if (hitGroup == HITGROUP_HEAD) then
		player:BoostAttribute("Limb Damage", ATB_MEDICAL, -limbDamage);
	elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_STOMACH) then
		player:BoostAttribute("Limb Damage", ATB_ENDURANCE, -limbDamage);
	elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
		player:BoostAttribute("Limb Damage", ATB_ACROBATICS, -limbDamage);
		player:BoostAttribute("Limb Damage", ATB_AGILITY, -limbDamage);
	elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
		player:BoostAttribute("Limb Damage", ATB_DEXTERITY, -limbDamage);
		player:BoostAttribute("Limb Damage", ATB_STRENGTH, -limbDamage);
	end;]]--
end;

function Schema:PostPlayerGiveToStorage(player, storageTable, itemTable)
	if IsValid(player) and player:GetMoveType() == MOVETYPE_WALK then
		player:EmitSound("generic_ui/ui_llite_0"..tostring(math.random(1, 3))..".wav");
	end
end

function Schema:PostPlayerTakeFromStorage(player, storageTable, itemTable)
	if IsValid(player) and player:GetMoveType() == MOVETYPE_WALK then
		player:EmitSound("generic_ui/ui_llite_0"..tostring(math.random(1, 3))..".wav");
	end
end

-- Called when an entity takes damage.
function Schema:EntityTakeDamageNew(entity, damageInfo)
	if (entity.GodMode) then
		return true;
	end;
	
	if entity:IsPlayer() and entity:HasInitialized() and entity:Alive() then
		if (damageInfo:IsFallDamage() and (Clockwork.player:HasFlags(entity, "E"))) then
			return false;
		elseif damageInfo:IsDamageType(DMG_BULLET) or damageInfo:IsDamageType(DMG_BUCKSHOT) then
			if entity:GetSubfaction() == "Philimaxio" then
				damageInfo:ScaleDamage(0.3);
			end
		end;
	end
	
	local attacker = damageInfo:GetAttacker();
	
	-- rubber johnny flags
	if (entity:IsPlayer() and attacker:IsPlayer()) then
		local hasFlags = Clockwork.player:HasFlags(entity, "6");
		local attHasFlags = Clockwork.player:HasFlags(attacker, "6");

		if (hasFlags and !attHasFlags) then
			attacker:TakeDamage(damageInfo:GetDamage());
			damageInfo:SetDamage(0);
			damageInfo:ScaleDamage(0);
			return true;
		end;
	end;
	
	if (entity:GetNWBool("BIsCinderBlock")) then
		if (!entity.health) then
			entity.health = 40
		end
		
		entity.health = entity.health - damageInfo:GetDamage()
		
		if (entity.health <= 0) then
			for i = 1, 5 do
				local effectData = EffectData()
					effectData:SetOrigin(entity:GetPos())
					effectData:SetScale(16)
				util.Effect("GlassImpact", effectData)
			end
			
			entity:EmitSound("physics/concrete/concrete_break2.wav")
			entity:Remove()
		else
			entity:EmitSound("physics/concrete/concrete_block_impact_hard"..math.random(2, 3)..".wav")
		end
	end
	
	if (entity:GetClass() == "prop_ragdoll") then
		if (IsValid(entity.CinderBlock) and damageInfo:GetAttacker():IsWorld()) then
			return true
		end
	end
	
	if (entity.cwWakingUp) then
		damageInfo:SetDamage(0);
		damageInfo:ScaleDamage(0);
		return true;
	end;

	if (entity:GetClass() == "cw_item") then
		local itemTable = entity:GetItemTable();
		local decayOnDamage = itemTable.decayOnDamage;
		
		if (decayOnDamage) then
			itemTable:TakeCondition(damageInfo:GetDamage());
		end;
	end;
	
	local attacker = damageInfo:GetAttacker();
	local damage = damageInfo:GetDamage();
	local bIsPlayer = entity:IsPlayer();

	if IsValid(attacker) then
		local class = attacker:GetClass();
		
		if attacker:IsPlayer() then
			local attackerWeapon = attacker:GetActiveWeapon();
			
			if IsValid(attackerWeapon) then
				if attackerWeapon:GetClass() == "weapon_crowbar" then
					damageInfo:SetDamageType(4);
					damageInfo:SetDamage(math.max(damage, 300));
					return true;
				end
			end
		end
		
		if (damage > 40) then
			if (bIsPlayer or entity:IsNPC() or entity:IsNextBot() or class == "prop_ragdoll") then
				local damagePosition = damageInfo:GetDamagePosition();
				
				if (damageType == DMG_BULLET or damageType == DMG_BUCKSHOT or damageType == DMG_SLASH) then
					self:BloodEffect(entity, damagePosition);
				end;
			end;
		end;
		
		if bIsPlayer then
			if (class == "env_fire") then
				if (cwBeliefs and entity.HasBelief and entity:HasBelief("taste_of_iron")) or entity.cloakBurningActive then
					damageInfo:ScaleDamage(0);
					damageInfo:SetDamage(0);
					
					return true;
				end
				
				local position = entity:GetPos();
				local attackerPosition = attacker:GetPos();
				local curTime = CurTime();

				if (position:Distance(attackerPosition) < 128) then
					if (!entity.lastDamagedByFire) then
						entity.lastDamagedByFire = 0;
					end;
					
					if (!entity.fireDamages or entity.lastDamagedByFire < curTime) then
						entity.fireDamages = 1;
					else
						entity.fireDamages = entity.fireDamages + 1;
					end;

					damageInfo:SetDamage(math.random(2, 5) * entity.fireDamages);
					entity.lastDamagedByFire = curTime + 3;
				end;
			elseif (class == "entityflame") then
				if entity.cloakBurningActive then
					damageInfo:ScaleDamage(0);
					damageInfo:SetDamage(0);
					
					return true;
				end
			end;
		end;
	end
	
	if (self.cwExplodePropDamages[damageType]) then
		local model = string.lower(entity:GetModel());
		
		damageInfo:ScaleDamage(0);
		damageInfo:SetDamage(0);
		
		if (self.cwExplodeProps[model] and !entity.Fired) then
			local bCanExplode = self.cwExplodeProps[model];
			local explodeCallback = nil;
			
			if (type(bCanExplode) == "table") then
				explodeCallback = bCanExplode[2];
				bCanExplode = bCanExplode[1];
			end;
			
			if (bCanExplode) then
				entity.Fired = true;
				
				if (explodeCallback) then
					explodeCallback(entity, attacker);
				else
					self:FireyExplosion(entity, attacker);
				end;
			end;
		end;
		
		return true;
	end;
	
	if (self.towerSafeZoneEnabled) then
		if entity:IsPlayer() then
			if entity:InTower() then
				if IsValid(damageInfo:GetAttacker()) and damageInfo:GetAttacker():IsPlayer() then
					local faction = damageInfo:GetAttacker():GetFaction();
				
					if faction ~= "Gatekeeper" and faction ~= "Holy Hierarchy" and !damageInfo:GetAttacker():IsAdmin() then
						damageInfo:SetDamage(0);
						return true;
					end
				elseif damageInfo:IsDamageType(DMG_BURN) then
					damageInfo:SetDamage(0);
					return true;
				end
			end
		end
	end
	
	if bIsPlayer and IsValid(attacker) and attacker:IsPlayer() then
		local attackerWeapon = attacker:GetActiveWeapon();
		
		if IsValid(attackerWeapon) then
			local weaponClass = attackerWeapon:GetClass();
			
			if string.find(weaponClass, "begotten_dagger_") or string.find(weaponClass, "begotten_dualdagger_") then
				if attacker:GetSubfaction() == "Kinisger" then
					damageInfo:ScaleDamage(1.25);
				end

				if !entity:IsRagdolled() and math.abs(math.AngleDifference(entity:EyeAngles().y, (attacker:GetPos() - entity:GetPos()):Angle().y)) >= 100 then
					if cwBeliefs and attacker:HasBelief("assassin") then
						damageInfo:ScaleDamage(3);
					else
						damageInfo:ScaleDamage(2);
					end
					
					entity:EmitSound("meleesounds/kill1.wav.mp3");
				end
			end
		end
		
		if entity.banners then
			for k, v in pairs(entity.banners) do
				if v == "glazic" then
					local faction = entity:GetFaction();
					
					if faction == "Gatekeeper" or faction == "Holy Hierarchy" then
						damageInfo:ScaleDamage(0.75);

						break;
					end
				end
			end
		end
		
		if attacker.banners then
			for k, v in pairs(attacker.banners) do
				if v == "glazic" then
					local faction = attacker:GetFaction();
					
					if faction == "Gatekeeper" or faction == "Holy Hierarchy" then
						damageInfo:ScaleDamage(1.15);

						break;
					end
				end
			end
		end
	end
end;

function Schema:ModifyPlayerSpeed(player, infoTable, action)
	local subfaction = player:GetSubfaction();
	
	if subfaction == "Philimaxio" then
		infoTable.runSpeed = infoTable.runSpeed * 0.85;
	elseif subfaction == "Varazdat" then
		if player:Health() > player:GetMaxHealth() * 0.95 then
			infoTable.runSpeed = infoTable.runSpeed * 1.1;
		end
	elseif subfaction == "Praeventor" then
		infoTable.runSpeed = infoTable.runSpeed * 1.05;
	end

	if (Clockwork.player:HasFlags(player, "E")) then
		infoTable.runSpeed = infoTable.walkSpeed * 3;
		infoTable.jumpPower = infoTable.jumpPower * 3;
	elseif action == "reloading" or action == "building" or action == "skinning" or action == "mutilating" or action == "putting_on_armor" or action == "taking_off_armor" then
		infoTable.runSpeed = infoTable.walkSpeed * 0.1;
		infoTable.walkSpeed = infoTable.walkSpeed * 0.1;
	end
end

-- Called when a player needs to fall over from fall damage.
function Schema:PlayerCanFallOverFromFallDamage(player)
	if (Clockwork.player:HasFlags(player, "E")) then
		return false;
	end;
end;

-- Called when a player uses a cinderblock item.
function Schema:CinderBlockExecution(player, target, itemTable)
	if (player:HasItemByID("cinder_block")) then
		local trace = player:GetEyeTrace()
		local entity = trace.Entity
		
		if (target:IsPlayer()) then
			if target:GetSharedVar("tied") then
				Clockwork.player:SetRagdollState(target, RAGDOLL_FALLENOVER, nil);
				entity = target:GetRagdollEntity()
			else
				Schema:EasyText(player, "peru", "This person must be tied before you can tie the cinder block!")
			end
		end
		
		if (entity:GetClass() == "prop_ragdoll") then
			local leftFoot = entity:LookupBone("ValveBiped.Bip01_L_Foot")
			local rightFoot = entity:LookupBone("ValveBiped.Bip01_R_Foot")
			
			if leftFoot and rightFoot then
				local leftFootPosition = entity:GetBonePosition(leftFoot)
				local rightFootPosition = entity:GetBonePosition(rightFoot)
				local feetBones = {leftFoot, rightFoot}
				local requiredDistance = 64
				
				if (trace.HitPos:Distance(leftFootPosition) <= requiredDistance or trace.HitPos:Distance(rightFootPosition) <= requiredDistance) then
					local footBone = feetBones[math.random(1, #feetBones)]
					
					if (footBone) then
						local cinderBlock = ents.Create("prop_physics")
						cinderBlock:SetModel(itemTable("model"))
						cinderBlock:SetPos(entity:GetBonePosition(footBone) + Vector(0, 0, 32))
						cinderBlock:SetAngles(AngleRand())
						cinderBlock:Spawn()
						cinderBlock:SetCollisionGroup(COLLISION_GROUP_WORLD)
						cinderBlock:SetNWBool("BIsCinderBlock", true)
						cinderBlock:SetOwner(entity)
						
						local players = _player.GetAll();

						for k, v in pairs(players) do
							if (IsValid(v:GetRagdollEntity())) then
								if (v:GetRagdollEntity() == entity) then
									entity.RagdollOwner = v
									break
								end
							end
						end
						
						entity:SetNWEntity("CinderBlock", cinderBlock)
						entity.CinderBlock = cinderBlock
						if (IsValid(entity.RagdollOwner)) then
							entity.RagdollOwner.CinderBlock = cinderBlock
						end

						entity.CinderBlockRope = constraint.Rope(cinderBlock, entity, 0, 13, Vector(0, 0, -10), Vector(0, 0, 0), 50, 0, 0, 0.5, "cable/rope")
						return
					end
				else
					Schema:EasyText(player, "peru", "This person does not have valid foot bones for some reason! Try using /adminhelp and contacting an admin!");
				end
			else
				Schema:EasyText(player, "peru", "You must tie this to your victim's foot!")
				return false
			end
		else
			Schema:EasyText(player, "darkgrey", "You must look at a valid target!")
			return false
		end
	else
		return false
	end
end
--[[
	Begotten 3: Jesus Wept
	written by: cash wednesday, DETrooper, gabs and alyousha35.
--]]

-- Called when Clockwork has loaded all of the entities.
function cwItemSpawner:ClockworkInitPostEntity()
	self:LoadItemSpawns()
	--self:SetupContainers(); -- Potentially glitched.
end

-- Called just after data should be saved.
--[[function cwItemSpawner:PostSaveData()
	self:SaveItemSpawns()
end]]--

-- Called every tick.
function cwItemSpawner:Think()
	local curTime = CurTime();
	
	if (!self.nextContainerCheck or self.nextContainerCheck < curTime) then
		self.nextContainerCheck = curTime + 8;
		
		if !self.ContainerLocations then
			return;
		end;
		
		local containers = self.Containers;
		
		if not containers then
			self.Containers = {};
			
			containers = self.Containers;
		end
		
		for i = 1, #containers do
			local containerTable = containers[i];
			
			if containerTable.lifeTime then
				if containerTable.lifeTime < curTime then
					local container = containerTable.container;
					
					if IsValid(container) then
						if !self.occupier and self:IsAreaClear(container:GetPos(), true) then
							local posFound = false;
							
							for k, v in pairs(self.ContainerLocations) do
								if posFound then
									break;
								end
								
								for j = 1, #v do
									if v[j].occupier == container:EntIndex() then
										posFound = true;
										v[j].occupier = nil;
										
										break;
									end
								end
							end
							
							container.cwInventory = nil;
							container.cwCash = nil;
							container:Remove();
							table.remove(self.Containers, i);
							
							break;
						else
							-- Move this container to the back of the queue, we'll check it again after all the others.
							-- This has the added side effect of making sure camping doesn't pay off :)
							table.remove(self.Containers, i);
							table.insert(self.Containers, containerTable);
							
							break;
						end
					else
						table.remove(self.Containers, i);
						break;
					end
				end
			else
				local container = containerTable.container;
				
				if IsValid(container) then
					if !self.occupier and self:IsAreaClear(container:GetPos(), true) then
						local posFound = false;
						
						for k, v in pairs(self.ContainerLocations) do
							if posFound then
								break;
							end
							
							for j = 1, #v do
								if v[j].occupier == container:EntIndex() then
									posFound = true;
									v[j].occupier = nil;
									
									break;
								end
							end
						end
						
						container.cwInventory = nil;
						container.cwCash = nil;
						container:Remove();
						table.remove(self.Containers, i);
						
						break;
					else
						-- Move this container to the back of the queue, we'll check it again after all the others.
						-- This has the added side effect of making sure camping doesn't pay off :)
						table.remove(self.Containers, i);
						table.insert(self.Containers, containerTable);
						
						break;
					end
				else
					table.remove(self.Containers, i);
					break;
				end
			end
		end
		
		if self.Containers then
			local numContainers = #self.Containers;

			if numContainers < self.MaxContainers then
				local containerCategory = self.Categories[math.random(#self.Categories)];
				local unoccupiedLocations = {};
				
				if containerCategory == "supermarket" then
					if math.random(1, 3) < 3 then
						containerCategory = "city";
					end
				end
				
				if self.ContainerLocations[containerCategory] then
					for i = 1, #self.ContainerLocations[containerCategory] do
						local location = self.ContainerLocations[containerCategory][i];
						
						if not location.occupier then
							table.insert(unoccupiedLocations, location);
						end
					end
					
					if #unoccupiedLocations > 0 then
						local unoccupiedLocation = unoccupiedLocations[math.random(#unoccupiedLocations)]
						
						if self:IsAreaClear(unoccupiedLocation.pos, true) then
							local container = ents.Create("prop_physics")

							container:SetAngles(unoccupiedLocation.angles);
							container:SetModel(unoccupiedLocation.model);
							container:SetPos(unoccupiedLocation.pos);
							container:Spawn();
							
							unoccupiedLocation.occupier = container:EntIndex();
							
							local physicsObject = container:GetPhysicsObject();
							
							if (IsValid(physicsObject)) then
								physicsObject:EnableMotion(false);
							end;
							
							numContainers = numContainers + 1;
							
							local containerTable = {
								container = container,
								lifeTime = curTime + self.ContainerLifetime
							};
							
							table.insert(self.Containers, containerTable);
							
							local lockChance = math.random(1, 100);
							
							if lockChance <= 5 then
								container.cwLockType = "none";
								container.cwLockTier = 3;
								container:SetNWBool("unlocked", false);
							elseif lockChance <= 15 then
								container.cwLockType = "none";
								container.cwLockTier = 2;
								container:SetNWBool("unlocked", false);
							elseif lockChance <= 25 then
								container.cwLockType = "none";
								container.cwLockTier = 1;
								container:SetNWBool("unlocked", false);
							end
							
							if not container.cwInventory then
								container.cwInventory = {};
							end
							
							local itemIncrease = (container.cwLockTier or 0) * 2
							
							for i = 1, math.random(3 + itemIncrease, 6 + itemIncrease) do
								local randomItem = self:SelectItem(containerCategory, false, true);
								
								if randomItem then
									local itemInstance = item.CreateInstance(randomItem);
									
									if itemInstance then
										local category = itemInstance.category;
										
										if category == "Helms" or category == "Armor" or category == "Melee" or category == "Crafting Materials" then
											-- 86% chance for these items to spawn with less than 100% condition.
											if math.random(1, 6) ~= 1 then
												itemInstance:TakeCondition(math.random(math.random(10, 50), 75));
											end
										elseif itemInstance.category == "Shot" and itemInstance.ammoMagazineSize and itemInstance.SetAmmoMagazine then
											itemInstance:SetAmmoMagazine(math.random(1, itemInstance.ammoMagazineSize));
										end
										
										Clockwork.inventory:AddInstance(container.cwInventory, itemInstance, 1);
									end
								end
							end
							
							if (container.cwLockTier and container.cwLockTier >= 1) or math.random(1, 10) == 1 then
								container.cwCash = math.random(10, 50);
								
								if math.random(1, 5) == 1 then
									container.cwCash = math.random(50, 100);
								end
							end
						end
					end
				end
			end
		end
		
		if self.SuperCrate then
			local supercrate = self.SuperCrate.supercrate;
			
			if IsValid(supercrate) and self.SuperCrate.lifeTime < curTime then
				if self:IsAreaClear(supercrate:GetPos(), true) then
					if IsValid(supercrate) then
						supercrate.cwInventory = nil;
						supercrate.cwCash = nil;
						supercrate:Remove();
					end

					self.SuperCrate = nil;
					self.nextSuperCrate = curTime + self.SuperCrateCooldown;
				end
			elseif !IsValid(supercrate) then
				self.SuperCrate = nil;
				self.nextSuperCrate = curTime + self.SuperCrateCooldown;
			end
		end
		
		local playerCount = _player.GetCount();
		local players = _player.GetAll();

		for i = 1, playerCount do
			local v, k = players[i], i;
			if v:IsAdmin() then
				if v.itemContainerSpawnESP then
					if self.Containers then
						Clockwork.datastream:Start(v, "ItemContsESPInfo",  {self.Containers, self.SuperCrate});
					end
				end
			end
		end
	end
	
	if (!self.nextItemSpawn or self.nextItemSpawn < curTime) then
		self.nextItemSpawn = curTime + 5;
		
		if not self.ItemsSpawned then
			self.ItemsSpawned = {};
		end
		
		if not self.nextSuperCrate then
			-- 1 hour between supercrates.
			self.nextSuperCrate = curTime + self.SuperCrateCooldown;
		end
		
		if not self.SuperCrate and self.nextSuperCrate < curTime then
			self:SpawnSupercrate();
		end
		
		for i = 1, #self.ItemsSpawned do
			local itemEnt = self.ItemsSpawned[i];
			
			if IsValid(itemEnt) then
				if itemEnt.lifeTime < curTime then
					if self:IsAreaClear(itemEnt:GetPos(), true) then
						itemEnt:Remove();
						table.remove(self.ItemsSpawned, i);
						break;
					end
				end
			else
				table.remove(self.ItemsSpawned, i);
				break;
			end
		end
		
		if #self.ItemsSpawned < self.MaxGroundSpawns then
			local itemCategory = self.Categories[math.random(#self.Categories)];
			local randomItem = self:SelectItem(itemCategory);

			if (!randomItem) then
				return;
			end;

			local spawnPosition = self:GetSpawnPosition(itemCategory);

			if (spawnPosition and isvector(spawnPosition.position)) then
				local entity = Clockwork.entity:CreateItem(nil, randomItem, Vector(spawnPosition.position.x, spawnPosition.position.y, spawnPosition.position.z + 16));
				local itemTable = entity:GetItemTable();
				
				entity.lifeTime = CurTime() + self.ItemLifetime;
				
				if itemTable.category == "Helms" or itemTable.category == "Armor" or itemTable.category == "Melee" then
					-- 86% chance for these items to spawn with less than 100% condition.
					if math.random(1, 6) ~= 1 then
						itemTable:TakeCondition(math.random(math.random(20, 50), 75));
					end
				elseif itemTable.category == "Shot" and itemTable.ammoMagazineSize and itemTable.SetAmmoMagazine then
					itemTable:SetAmmoMagazine(math.random(1, itemTable.ammoMagazineSize));
				end
				
				table.insert(self.ItemsSpawned, entity);
			end;
		end
	end;
end;

-- Called just after a player spawns.
function cwItemSpawner:PostPlayerSpawn(player, lightSpawn, changeClass, firstSpawn)
	if (player:IsAdmin() or player:IsUserGroup("operator")) then
		Clockwork.datastream:Start(player, "ItemSpawnESPInfo", {self.SpawnLocations});
	end;
end;

-- Called when a player uses an unknown item function.
function cwItemSpawner:PlayerUseUnknownItemFunction(player, itemTable, itemFunction, toolUniqueID, toolItemID)
	if (itemTable.breakdownItems) then
		if (itemFunction == "breakdown" and toolUniqueID and toolItemID) then
			local toolItem = player:FindItemByID(toolUniqueID, toolItemID);
			
			if (toolItem) then
				self:Breakdown(player, itemTable, toolItem);
			end;
		elseif (itemFunction == "breakdown") then
			self:Breakdown(player, itemTable);
		end;
	end;
end;
	
-- A function to break an item and give it's parts to the player.
function cwItemSpawner:Breakdown(player, itemTable, toolItem)
	for k, v in pairs (itemTable.breakdownItems) do
		player:UpdateInventory(k, v);
	end;
	
	if (itemTable.OnBreakdown) then
		itemTable:OnBreakdown(player, toolItem);
	end;
	
	if (toolItem) then
		toolItem:TakeCondition(math.random(1, 2));
	end;
end;
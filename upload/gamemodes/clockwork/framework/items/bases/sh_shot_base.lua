--[[
	Begotten III: Jesus Wept
	By: DETrooper, cash wednesday, gabs, alyousha35

	Other credits: kurozael, Alex Grist, Mr. Meow, zigbomb
--]]

local ITEM = item.New(nil, true);
	ITEM.name = "Shot Base"
	ITEM.useText = "Load"
	ITEM.useSound = false
	ITEM.category = "Shot"
	ITEM.roundsText = "Bullets"
	ITEM:AddData("Rounds", 1, true) -- default to 1 round
	ITEM.equippable = false; -- this blocks equipping the item as a melee weapon.
	ITEM.ammoMagazineSize = nil;
	
	-- A function to get the item's weight.
	function ITEM:GetItemWeight()
		return (self.weight / self.ammoMagazineSize) * self:GetData("Rounds") or 1;
	end

	-- A function to get the item's space.
	function ITEM:GetItemSpace()
		return (self.space / self.ammoMagazineSize) * self:GetData("Rounds") or 1;
	end
	
	-- Called whent he item entity's menu options are needed.
	function ITEM:GetEntityMenuOptions(entity, options)
		if self.ammoMagazineSize then
			local ammo = self:GetAmmoMagazine();
			
			if ammo and ammo > 0 then
				options["Unload Shot"] = {
					isArgTable = true,
					arguments = "cwItemMagazineAmmo",
					toolTip = toolTip
				};
			end;
		end;
	end;

	-- Called when a player uses the item.
	function ITEM:OnUse(player, itemEntity)
		if self.ammoType then
			local valid_weapon;
			local weaponData = player.bgWeaponData or {};
			
			if itemEntity and itemEntity.beingUsed then
				Schema:EasyText(player, "peru", "This item is already being used!");
				return false;
			end
			
			if player.HasBelief and not player:HasBelief("powder_and_steel") then
				Schema:EasyText(player, "chocolate", "You do not have the required belief, 'Powder and Steel', to load this weapon!");
				
				return false;
			end

			for i = 1, #weaponData do
				if not valid_weapon and weaponData[i].uniqueID and weaponData[i].realID then
					local weaponItem = Clockwork.inventory:FindItemByID(player:GetInventory(), weaponData[i].uniqueID, weaponData[i].realID);

					if weaponItem and self:CanUseOnItem(player, weaponItem, false) then
						self:UseOnItem(player, weaponItem, true, itemEntity);
						return false; -- Gets taken by the UseOnItem function after a delay.
					end
				end
			end
		end
		
		Schema:EasyText(player, "chocolate", "No valid weapon could be found for this ammo type!");
		return false;
	end
	
	function ITEM:UseOnItem(player, weaponItem, canUse, itemEntity)
		if canUse or self:CanUseOnItem(player, weaponItem, true) then
			local consumeTime = weaponItem.reloadTime or 10;
		
			if player:HasBelief("dexterity") then
				consumeTime = math.Round(consumeTime * 0.67);
			end
			
			if player.holyPowderkegActive then
				consumeTime = 3;
			end
			
			if weaponItem.reloadSounds then
				player:EmitSound(weaponItem.reloadSounds[1]);
			
				for i = 2, #weaponItem.reloadSounds do
					timer.Simple(consumeTime * ((i - 1) / #weaponItem.reloadSounds), function()
						if IsValid(player) and Clockwork.player:GetAction(player) == "reloading" then
							player:EmitSound(weaponItem.reloadSounds[i]);
						end
					end);
				end
			end
			
			local weaponRaised = Clockwork.player:GetWeaponRaised(player);
			
			if weaponRaised then
				Clockwork.player:SetWeaponRaised(player, false);
			end
			
			if itemEntity then
				itemEntity.beingUsed = true;
				player.itemUsing = itemEntity;
			end
			
			Clockwork.player:SetAction(player, "reloading", consumeTime, nil, function()
				if IsValid(player) and weaponItem then
					if itemEntity and !IsValid(itemEntity) then
						Schema:EasyText(player, "peru", "The shot you were reloading no longer exists!");
						return;
					end
					
					local weaponItemAmmo = weaponItem:GetData("Ammo");
				
					if not weaponItem.usesMagazine then
						table.insert(weaponItemAmmo, self.ammoType);
						
						weaponItem:SetData("Ammo", weaponItemAmmo);
					elseif #weaponItemAmmo <= 0 then
						if self.ammoMagazineSize then
							local rounds = self:GetAmmoMagazine();
							
							if rounds and rounds > 0 then
								for j = 1, rounds do
									table.insert(weaponItemAmmo, self.ammoType);
								end

								weaponItem:SetData("Ammo", weaponItemAmmo);
							end
						else
							-- Chambered single round.
							 
							table.insert(weaponItemAmmo, self.ammoType);
							
							weaponItem:SetData("Ammo", weaponItemAmmo);
						end
					end
					
					if weaponRaised then
						Clockwork.player:SetWeaponRaised(player, true);
					end
					
					if IsValid(itemEntity) then
						itemEntity:Remove();
					else
						player:TakeItem(self);
					end
				end
			end);
		end
	end
	
	function ITEM:CanUseOnItem(player, weaponItem, bNotify)
		local action = Clockwork.player:GetAction(player);
		
		if (action == "reloading") then
			if bNotify then
				Schema:EasyText(player, "peru", "Your character is already reloading!");
			end
			
			return false;
		end
		
		if weaponItem and weaponItem.category == "Firearms" and weaponItem.ammoTypes then
			if table.HasValue(weaponItem.ammoTypes, self.ammoType) then
				local weaponItemAmmo = weaponItem:GetData("Ammo");
				
				if weaponItemAmmo and #weaponItemAmmo < weaponItem.ammoCapacity then
					if player.HasBelief and not player:HasBelief("powder_and_steel") then
						if bNotify then
							Schema:EasyText(player, "chocolate", "You do not have the required belief, 'Powder and Steel', to load this weapon!");
						end
						
						return false;
					end
					
					if not weaponItem.usesMagazine then
						return true;
					else
						if self.ammoMagazineSize and #weaponItemAmmo <= 0 then			
							local roundsLeft = self:GetAmmoMagazine();
							
							if roundsLeft and roundsLeft > 0 then
								return true;
							else
								if bNotify then
									Schema:EasyText(player, "peru", "This magazine is empty!");
								end
								
								return false;
							end
						elseif #weaponItemAmmo <= 0 then
							-- Chambered single round.
							return true;
						else
							if bNotify then
								Schema:EasyText(player, "peru", "This weapon is currently loaded with a magazine or a round in the chamber!");
							end
							
							return false;
						end
					end
				else
					if bNotify then
						Schema:EasyText(player, "peru", "This weapon is at its ammunition capacity!");
					end
					
					return false;
				end
			else
				if bNotify then
					Schema:EasyText(player, "peru", "This weapon cannot use this ammunition type!");
				end
				
				return false;
			end
		else
			if bNotify then
				Schema:EasyText(player, "peru", "This weapon cannot take ammunition!");
			end
			
			return false;
		end
	end
	
	function ITEM:UseOnMagazine(player, magazineItem)
		if magazineItem and magazineItem.category == "Shot" and magazineItem.ammoMagazineSize then
			if magazineItem.ammoName == self.ammoName then
				local magazineItemAmmo = magazineItem:GetAmmoMagazine();
				
				if magazineItemAmmo and magazineItemAmmo < magazineItem.ammoMagazineSize then
					if magazineItem.SetAmmoMagazine then
						magazineItem:SetAmmoMagazine(magazineItemAmmo + 1);
						return true;
					end
				else
					Schema:EasyText(player, "peru", "This magazine is currently full!");
					return false;
				end
			else
				Schema:EasyText(player, "peru", "This magazine is not the correct ammo type for this round!");
				return false;
			end
		else
			Schema:EasyText(player, "chocolate", "You must load this round into a suitable magazine or weapon!");
			return false;
		end
	end
	
	function ITEM:TakeFromMagazine(player)
		if IsValid(player) and self.ammoMagazineSize then
			local itemAmmo = self:GetAmmoMagazine();

			if itemAmmo and itemAmmo > 0 then
				local ammoItemID = string.gsub(string.lower(self.ammoName), " ", "_");
				local ammoItem = item.CreateInstance(ammoItemID);
				
				if ammoItem then
					self:SetAmmoMagazine(itemAmmo - 1);
					
					player:GiveItem(ammoItem);
				end
				
				return;
			end
			
			Schema:EasyText(player, "peru", "This magazine has no ammo to unload!");
			return;
		end
	end

	-- Called when a player drops the item.
	function ITEM:OnDrop(player, position) end

	if (SERVER) then
		function ITEM:OnGenerated()
			self:SetData("Rounds", self.ammoMagazineSize)
		end
	else
		function ITEM:GetClientSideInfo()
			return Clockwork.kernel:AddMarkupLine("", "Rounds: "..self.ammoMagazineSize)
		end
	end
	
	function ITEM:GetAmmoMagazine()
		if self.ammoMagazineSize then
			-- Item is magazine.
			local rounds = self:GetData("Rounds");
			
			if (rounds) then
				return rounds;
			else
				return self.ammoMagazineSize;
			end;
		end;
	end;
	
	function ITEM:SetAmmoMagazine(amount)
		if self.ammoMagazineSize then
			if amount and self.SetData then
				self:SetData("Rounds", amount);
			end
		end;
	end
	
	ITEM:AddQueryProxy("ammoMagazineSize", ITEM.GetAmmoMagazine)
ITEM:Register()
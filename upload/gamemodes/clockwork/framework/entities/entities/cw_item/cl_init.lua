--[[
	Begotten III: Jesus Wept
	By: DETrooper, cash wednesday, gabs, alyousha35

	Other credits: kurozael, Alex Grist, Mr. Meow, zigbomb
--]]

include("shared.lua")

-- Called when the target ID HUD should be painted.
function ENT:HUDPaintTargetID(x, y, alpha)
	if (Clockwork.entity:HasFetchedItemData(self)) then
		local itemTable = Clockwork.entity:FetchItemTable(self)

		if (hook.Run("PaintItemTargetID", x, y, alpha, itemTable)) then
			local colorTargetID = Clockwork.option:GetColor("target_id")
			local colorWhite = Clockwork.option:GetColor("white")
			local color = itemTable.color or colorTargetID
			local name = itemTable:GetName();
			
			if itemTable:IsBroken() or itemTable:GetCondition() <= 0 then
				y = Clockwork.kernel:DrawInfo("Broken "..name, x, y, color, alpha)
			else
				y = Clockwork.kernel:DrawInfo(name, x, y, color, alpha)
			end

			if (itemTable.OnHUDPaintTargetID) then
				local newY = itemTable:OnHUDPaintTargetID(self, x, y, alpha)

				if (newY == false) then
					return
				end

				if (isnumber(newY)) then
					y = newY
				end
			end

			y = Clockwork.kernel:DrawInfo((itemTable.weightText or itemTable.weight.."kg"), x, y, colorWhite, alpha)

			local spaceUsed = itemTable.space
			if (Clockwork.inventory:UseSpaceSystem() and spaceUsed > 0) then
				y = Clockwork.kernel:DrawInfo((itemTable.spaceText or spaceUsed.."l"), x, y, colorWhite, alpha)
			end
		end
	end
end

-- Called each frame.
function ENT:Think()
	if (!Clockwork.entity:HasFetchedItemData(self)) then
		Clockwork.entity:FetchItemData(self)
		return
	end

	--[[local itemTable = Clockwork.entity:FetchItemTable(self)

	if itemTable then
		if (itemTable.OnEntityThink) then
			local nextThink = itemTable:OnEntityThink(self)

			if (isnumber(nextThink)) then
				self:NextThink(CurTime() + nextThink)
			end
		end

		hook.Run("ItemEntityThink", itemTable, self)
	end]]--
end

-- Called when the entity should draw.
function ENT:Draw()
	if (!Clockwork.entity:HasFetchedItemData(self)) then
		return
	end

	local drawModel = true
	local itemTable = Clockwork.entity:FetchItemTable(self)
	
	if itemTable then
		local shouldDrawItemEntity = hook.Run("ItemEntityDraw", itemTable, self)

		if (shouldDrawItemEntity == false or (itemTable.OnDrawModel and itemTable:OnDrawModel(self) == false)) then
			drawModel = false
		end
		
		if (drawModel) then
			if itemTable.attachmentSkin then
				self:SetSkin(itemTable.attachmentSkin);
			end
			
			if itemTable.bodygroup0 then
				self:SetBodygroup(0, itemTable.bodygroup0 - 1);
			end
			
			if itemTable.bodygroup1 then
				self:SetBodygroup(0, itemTable.bodygroup1 - 1);
			end
			
			if itemTable.bodygroup2 then
				self:SetBodygroup(1, itemTable.bodygroup2 - 1);
			end
			
			if itemTable.bodygroup3 then
				self:SetBodygroup(2, itemTable.bodygroup3 - 1);
			end
				
			self:DrawModel()
		end
	end
end
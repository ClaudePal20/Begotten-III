--[[
	Begotten III: Jesus Wept
	By: DETrooper, cash wednesday, gabs, alyousha35

	Other credits: kurozael, Alex Grist, Mr. Meow, zigbomb
--]]

function cwStamina:PlayerCharacterInitialized(data)
	local stamina = Clockwork.Client:GetNWInt("Stamina", 100);
	
	self.stamina = stamina;
end

-- Called when the bars are needed.
function cwStamina:GetBars(bars)
	local max_stamina = Clockwork.Client:GetNetVar("Max_Stamina", 100);
	local stamina = Clockwork.Client:GetNWInt("Stamina", 100);
	
	if (!self.stamina) then
		self.stamina = stamina;
	else
		self.stamina = math.Approach(self.stamina, stamina, 1);
	end;
	
	if (self.stamina < max_stamina - 5) then
		bars:Add("STAMINA", Color(100, 175, 100, 255), "STAMINA", self.stamina, max_stamina, self.stamina < 10);
	end;
end;
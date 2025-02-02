--[[
	Begotten III: Jesus Wept
	By: DETrooper, cash wednesday, gabs, alyousha35

	Other credits: kurozael, Alex Grist, Mr. Meow, zigbomb
--]]

include("shared.lua");

-- Called when the target ID HUD should be painted.
function ENT:HUDPaintTargetID(x, y, alpha)
	local colorTargetID = Clockwork.option:GetColor("target_id")
	local colorWhite = Clockwork.option:GetColor("white")
	
	y = Clockwork.kernel:DrawInfo("Coinslot", x, y, colorTargetID, alpha)
	y = Clockwork.kernel:DrawInfo("A machine with several cranks and gears, and a prominent coinslot.", x, y, colorWhite, alpha);
end;

local function CreateMenu(state)
	if (IsValid(menu)) then
		menu:Remove();
	end;
	
	local scrW = ScrW();
	local scrH = ScrH();
	local menu = DermaMenu();
		
	menu:SetMinimumWidth(150);
	
	if state ~= "Gore" then
		menu:AddOption("Collect Ration", function() Clockwork.Client:ConCommand("cw_CoinslotRation") end);
		menu:AddOption("Donate", function() 
			Derma_StringRequest("Coinslot", "How much coin would you offer to the Coinslot?", nil, function(text)
				Clockwork.kernel:RunCommand("CoinslotDonate", text);
			end)
		end);
		
		if cwShacks.shacks and Clockwork.Client:GetFaction() ~= "Holy Hierarchy" then
			local playerShack = Clockwork.Client:GetSharedVar("shack");
			
			if !playerShack then
				local subMenu = menu:AddSubMenu("Purchase Property");
				local marketMenu = subMenu:AddSubMenu("Market Area");
				
				for k, v in SortedPairsByMemberValue(cwShacks.shackData["market"], "name") do
					if not cwShacks.shacks[k] then
						marketMenu:AddOption("("..tostring(v.price)..") "..v.name, function() Clockwork.kernel:RunCommand("CoinslotPurchase", k) end);
					else
						marketMenu:AddOption("(SOLD) "..v.name, function() end);
					end
				end
				
				local groundFloorMenu = subMenu:AddSubMenu("Ground Floor");
				
				for k, v in SortedPairsByMemberValue(cwShacks.shackData["floor1"], "name") do
					if not cwShacks.shacks[k] then
						groundFloorMenu:AddOption("("..tostring(v.price)..") "..v.name, function() Clockwork.kernel:RunCommand("CoinslotPurchase", k) end);
					else
						groundFloorMenu:AddOption("(SOLD) "..v.name, function() end);
					end
				end
				
				local secondFloorMenu = subMenu:AddSubMenu("Second Floor");
				
				for k, v in SortedPairsByMemberValue(cwShacks.shackData["floor2"], "name") do
					if not cwShacks.shacks[k] then
						secondFloorMenu:AddOption("("..tostring(v.price)..") "..v.name, function() Clockwork.kernel:RunCommand("CoinslotPurchase", k) end);
					else
						secondFloorMenu:AddOption("(SOLD) "..v.name, function() end);
					end
				end
				
				local thirdFloorMenu = subMenu:AddSubMenu("Third Floor");
				
				for k, v in SortedPairsByMemberValue(cwShacks.shackData["floor3"], "name") do
					if not cwShacks.shacks[k] then
						thirdFloorMenu:AddOption("("..tostring(v.price)..") "..v.name, function() Clockwork.kernel:RunCommand("CoinslotPurchase", k) end);
					else
						thirdFloorMenu:AddOption("(SOLD) "..v.name, function() end);
					end
				end
				
				local fourthFloorMenu = subMenu:AddSubMenu("Fourth Floor");
				
				for k, v in SortedPairsByMemberValue(cwShacks.shackData["floor4"], "name") do
					if not cwShacks.shacks[k] then
						fourthFloorMenu:AddOption("("..tostring(v.price)..") "..v.name, function() Clockwork.kernel:RunCommand("CoinslotPurchase", k) end);
					else
						fourthFloorMenu:AddOption("(SOLD) "..v.name, function() end);
					end
				end
			else
				subMenu = menu:AddSubMenu("Sell Property");
				
				for k, v in pairs(cwShacks.shackData) do
					for k2, v2 in pairs(v) do
						if k2 == playerShack then
							subMenu:AddOption("("..tostring(v2.price / 2)..") "..v2.name, function() Clockwork.kernel:RunCommand("CoinslotSell", k2) end);
							break;
						end
					end
				end
			end
		end
	end
	
	if state == "Gatekeeper" then
		local subMenu = menu:AddSubMenu("Salary");
		
		subMenu:AddOption("Check", function() Clockwork.Client:ConCommand("cw_CoinslotSalaryCheck") end);
		subMenu:AddOption("Collect", function() Clockwork.Client:ConCommand("cw_CoinslotSalary") end);
	end
	
	if state == "Hierarchy" then
		local subMenu = menu:AddSubMenu("Treasury");
		
		subMenu:AddOption("Check", function() Clockwork.Client:ConCommand("cw_CoinslotTreasury") end);
		--[[subMenu:AddOption("Collect", function() 
			Derma_StringRequest("Coinslot", "How much coin would you collect from the Coinslot?", nil, function(text)
				Clockwork.kernel:RunCommand("CoinslotCollect", text);
			end) 
		end);]]--
	elseif Clockwork.Client:IsAdmin() then
		local subMenu = menu:AddSubMenu("(ADMIN) Treasury");
		
		subMenu:AddOption("Check", function() Clockwork.Client:ConCommand("cw_CoinslotTreasury") end);
		subMenu:AddOption("Collect", function() 
			Derma_StringRequest("Coinslot", "How much coin would you collect from the Coinslot?", nil, function(text)
				Clockwork.kernel:RunCommand("CoinslotCollect", text);
			end) 
		end);
	end
	
	menu:Open();
	menu:SetPos(scrW / 2 - (menu:GetWide() / 2), scrH / 2 - (menu:GetTall() / 2));
end

Clockwork.datastream:Hook("OpenCoinslotMenu", function(state)
	CreateMenu(state);
end);
--[[
	Begotten 3: Jesus Wept
	written by: cash wednesday, DETrooper, gabs and alyousha35.
--]]

-- Called when the bars are needed.
function cwMelee:GetBars(bars)
	local max_stability = Clockwork.Client:GetNWInt("maxStability", 100);
	local stability = Clockwork.Client:GetNetVar("Stability");
	local max_poise = Clockwork.Client:GetNWInt("maxMeleeStamina", 90);
	local poise = Clockwork.Client:GetNWInt("meleeStamina");
	local freeze = Clockwork.Client:GetNWInt("freeze");
	local frameTime = FrameTime();
	
	if (stability) then
		if (!self.stability) then
			self.stability = stability;
		elseif (stability != self.stability) then
			self.stability = math.Approach(self.stability, stability, frameTime * (16 * math.Clamp(math.abs(self.stability - stability) * 2, 1, 10)));
		end;
		
		if (self.stability < max_stability) then
			bars:Add("stability", Color(135, 80, 60), "STABILITY", self.stability, max_stability, self.stability < 25);
		end;
	end;
	
	if (poise) then
		if (!self.poise) then
			self.poise = poise;
		elseif (poise != self.poise) then
			self.poise = math.Approach(self.poise, poise, frameTime * (16 * math.Clamp(math.abs(self.poise - poise) * 2, 1, 10)));
		end;
		
		if (self.poise < max_poise) then
			bars:Add("POISE", Color(50, 175, 100), "POISE", self.poise, max_poise, self.poise < 10);
		end;
	end;
	
	if (freeze) then
		if (!self.freeze) then
			self.freeze = freeze;
		elseif (freeze != self.freeze) then
			self.freeze = math.Approach(self.freeze, freeze, frameTime * (16 * math.Clamp(math.abs(self.freeze - freeze) * 2, 1, 10)));
		end
		
		if (self.freeze > 0) then
			bars:Add("ICE", Color(96, 192, 214), "ICE", self.freeze, 100, self.freeze > 90);
		end;
	end
end;

-- Called when the foreground HUD should be painted.
function cwMelee:HUDPaintForeground()
	local curTime = CurTime();
	
	if (Clockwork.Client:Alive()) then
		if (self.parryEffects and #self.parryEffects > 0) then
			for k, v in pairs(self.parryEffects) do
				local alpha = math.Clamp((15 / v[2]) * (v[1] - curTime), 0, 155);
				local scrW, scrH = ScrW(), ScrH();
				
				if (alpha != 0) then
					draw.RoundedBox(0, 0, 0, scrW, scrH, Color(90, 90, 90, alpha));
				else
					table.remove(self.parryEffects, k);
				end;
			end;
		end;
	end;
end;

-- Called when the screenspace effects are rendered.
function cwMelee:RenderScreenspaceEffects()
	if (self.blurAmount and self.blurAmount != 0) then
		self.blurAmount = math.Approach(self.blurAmount, 0, FrameTime());
		DrawMotionBlur(0.05, self.blurAmount, 0.01)
	elseif (self.blurAmount) then
		self.blurAmount = nil;
	end;
end;

--[[function cwMelee:Think()
	if (!self.nextBreathingCheck or self.nextBreathingCheck < curTime) then
		self.nextBreathingCheck = curTime + 0.6;
	
		for k, v in pairs(_player.GetAll()) do
			local max_poise = v:GetMaxPoise();
			local poise = v:GetSharedVar("meleeStamina", max_poise);
			local playedBreathing = false;
			
			if (poise < max_poise * 0.8) then
				if (!v.breathingSound) then
					v.breathingSound = CreateSound(v, "breathing1.wav");
				end
				
				if (!v.nextBreathing or curTime >= v.nextBreathing) then
					local gender = v:GetGender();
					local pitch = 90;
					
					if (gender == GENDER_FEMALE) then
						pitch = 125;
					end;
					
					v.nextBreathing = curTime + (0.50 + ((1.25 / max_poise) * poise));
					v.breathingSound:PlayEx(0.15 - ((0.15 / max_poise) * poise), pitch);
				end;
				
				playedBreathing = true;
			else
				if v.breathingSound then
					v.breathingSound:Stop();
					v.breathingSound = nil;
				end
			end;
			
			if (!playedBreathing and v.breathingSound) then
				v.breathingSound:FadeOut(2);
				v.breathingSound = nil;
			end;
		end;
	end;
end]]--
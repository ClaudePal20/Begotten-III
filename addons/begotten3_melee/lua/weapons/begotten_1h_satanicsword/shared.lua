SWEP.Base = "sword_swepbase"
-- WEAPON TYPE: One Handed

SWEP.PrintName = "Satanic Sword"
SWEP.Category = "(Begotten) One Handed"

SWEP.AdminSpawnable = true
SWEP.Spawnable = true
SWEP.AutoSwitchTo = false
SWEP.Slot = 0
SWEP.Weight = 2
SWEP.UseHands = true

SWEP.HoldType = "wos-begotten_1h"
SWEP.HoldTypeShield = "wos-begotten_1h_shield"

SWEP.ViewModel = "models/v_onehandedbegotten.mdl"
SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false

--Anims
SWEP.BlockAnim = "a_sword_block"
SWEP.CriticalAnim = "a_sword_attack_slash_slow_01"
SWEP.CriticalAnimShield = "a_sword_shield_attack_slash_slow_01"
SWEP.ParryAnim = "a_sword_parry"

SWEP.IronSightsPos = Vector(-7.64, -6.433, -0.96)
SWEP.IronSightsAng = Vector(-2.814, 8.442, -48.543)

SWEP.hasSwordplay = true;
SWEP.isArmingSword = true;

--Sounds
SWEP.AttackSoundTable = "SmallMetalAttackSoundTable"
SWEP.BlockSoundTable = "MetalBlockSoundTable"
SWEP.SoundMaterial = "Metal" -- Metal, Wooden, MetalPierce, Punch, Default

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
SWEP.AttackTable = "SatanicSwordAttackTable"
SWEP.BlockTable = "SatanicSwordBlockTable"

function SWEP:CriticalAnimation()

	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	local attacktable = GetTable(self.AttackTable)
	local rate = 0.45
	
	if self:GetNW2Bool("swordplayActive") == true then
		rate = 0.55
	end

	-- Viewmodel attack animation!
	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "misscenter1" ) )
	self.Owner:GetViewModel():SetPlaybackRate(rate)
	
	if (SERVER) then
	timer.Simple( 0.05, function() if self:IsValid() then
	self.Weapon:EmitSound(attacksoundtable["criticalswing"][math.random(1, #attacksoundtable["criticalswing"])])
	end end)	
	self.Owner:ViewPunch(Angle(1,4,1))
	end
	
end

function SWEP:ParryAnimation()
	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "misscenter1" ))
end

function SWEP:HandlePrimaryAttack()

	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	local attacktable = GetTable(self.AttackTable)
	
	local isShieldActive = self:GetNW2String("activeShield"):len() > 0
	local isSwordplayActive = self:GetNW2Bool("swordplayActive")
	local rate = 0.45

	if isSwordplayActive then
		anim = isShieldActive and "a_sword_shield_attack_slash_fast_01" or "a_sword_attack_slash_fast_0" .. math.random(1, 2)
		rate = 0.55
	else
		anim = isShieldActive and "a_sword_shield_attack_slash_slow_01" or "a_sword_attack_slash_slow_0" .. math.random(1, 2)
	end
	
	--Attack animation
	self:TriggerAnim(self.Owner, anim);

	-- Viewmodel attack animation!
	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "misscenter1" ) )
	self.Owner:GetViewModel():SetPlaybackRate(rate)
	
	self.Weapon:EmitSound(attacksoundtable["primarysound"][math.random(1, #attacksoundtable["primarysound"])])
	self.Owner:ViewPunch(attacktable["punchstrength"])

end

function SWEP:HandleThrustAttack()

	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	local attacktable = GetTable(self.AttackTable)
	local rate = 0.45;
	
	local isShieldActive = self:GetNW2String("activeShield"):len() > 0
	local isSwordplayActive = self:GetNW2Bool("swordplayActive")

	if isSwordplayActive then
		anim = isShieldActive and "a_sword_shield_attack_stab_fast_01" or "a_sword_attack_stab_fast_01"
		rate = 0.6
	else
		anim = isShieldActive and "a_sword_shield_attack_stab_medium_01" or "a_sword_attack_stab_medium_01"
	end
	
	--Attack animation
	self:TriggerAnim(self.Owner, anim);

	-- Viewmodel attack animation!
	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "thrust1" ) )
	self.Owner:GetViewModel():SetPlaybackRate(rate)
	
	self.Weapon:EmitSound(attacksoundtable["altsound"][math.random(1, #attacksoundtable["altsound"])])
	self.Owner:ViewPunch(attacktable["punchstrength"])

end

function SWEP:OnDeploy()
	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	self.Owner:ViewPunch(Angle(0,1,0))
	if !self.Owner.cwObserverMode then self.Weapon:EmitSound(attacksoundtable["drawsound"][math.random(1, #attacksoundtable["drawsound"])]) end;
end

/*---------------------------------------------------------
	Bone Mods
---------------------------------------------------------*/

SWEP.VElements = {
	["v_satanicsword"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.714, 1.59, -1.558), angle = Angle(12.857, -167.144, -169.482), size = Vector(1, 1, 1), material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["w_satanicsword"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.59, 2.25, -1.558), angle = Angle(171.817, -22.209, -10.52), size = Vector(0.899, 0.899, 0.899), material = "", skin = 0, bodygroup = {} }
}

SWEP.VElementsDual = {
	["v_left"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "Dummy16", rel = "", pos = Vector(2, -8.396, -1), angle = Angle(12.222, -180, 90), size = Vector(1, 1, 1), material = "", skin = 0, bodygroup = {} },
	["v_right"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "Dummy01", rel = "", pos = Vector(2.469, -12.346, 0.493), angle = Angle(-180, 18.888, -94.445), size = Vector(1, 1, 1), material = "", skin = 0, bodygroup = {} }
}

SWEP.WElementsDual = {
	["w_left"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "ValveBiped.Bip01_L_Hand", rel = "", pos = Vector(4.59, 0.7, 2.558), angle = Angle(180, 0, 180), size = Vector(0.899, 0.899, 0.899), material = "", skin = 0, bodygroup = {} },
	["w_right"] = { type = "Model", model = "models/skyrim/daedric/sword/w_daedricsword.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.59, 2.25, -1.558), angle = Angle(141.817, -22.209, -10.52), size = Vector(0.899, 0.899, 0.899), material = "", skin = 0, bodygroup = {} }
}
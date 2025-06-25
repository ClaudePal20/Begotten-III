SWEP.Base = "sword_swepbase"
-- WEAPON TYPE: Polearm Totem

SWEP.PrintName = "Crackling Interference Totem"
SWEP.Category = "(Begotten) Polearm"

SWEP.AdminSpawnable = true
SWEP.Spawnable = true
SWEP.AutoSwitchTo = false
SWEP.Slot = 0
SWEP.Weight = 3
SWEP.UseHands = true

SWEP.HoldType = "wos-begotten_2h"

SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.ViewModelFOV = 80
SWEP.ViewModelFlip = false

--Anims
SWEP.BlockAnim = "a_heavy_2h_block"
SWEP.CriticalAnim = "a_heavy_2h_attack_slash_02"
SWEP.ParryAnim = "a_heavy_2h_parry"
SWEP.PrimarySwingAnim = "a_heavy_2h_attack_slash_01"

SWEP.IronSightsPos = Vector(3.64, -8.04, -6.56)
SWEP.IronSightsAng = Vector(10, 0.703, 50)

SWEP.LoweredAngles = Angle(-20, 0, 0)

--Sounds
SWEP.AttackSoundTable = "MetalBluntPolearmAttackSoundTable"
SWEP.BlockSoundTable = "WoodenBlockSoundTable"
SWEP.SoundMaterial = "MetalPierce"
SWEP.WindUpSound = "draw/skyrim_axe_draw1.mp3"

SWEP.bannerType = "voltist"

SWEP.AttackTable = "InterferenceTotemAttackTable"
SWEP.BlockTable = "InterferenceTotemBlockTable"

function SWEP:CriticalAnimation()
	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:GetViewModel():SetPlaybackRate(0.25)

	if (SERVER) then
		timer.Simple(0.05, function()
			if self:IsValid() then
				self.Weapon:EmitSound(attacksoundtable["criticalswing"][math.random(1, #attacksoundtable["criticalswing"])])
			end
		end)
		self.Owner:ViewPunch(Angle(1, 4, 1))
	end
end

function SWEP:ParryAnimation()
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:HandlePrimaryAttack()
	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	local attacktable = GetTable(self.AttackTable)

	self:TriggerAnim(self.Owner, self.PrimarySwingAnim)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:GetViewModel():SetPlaybackRate(0.25)
	self.Weapon:EmitSound(self.WindUpSound)

	timer.Simple(attacktable["striketime"] - 0.05, function()
		if self:IsValid() and self.isAttacking then
			self.Weapon:EmitSound(attacksoundtable["altsound"][math.random(1, #attacksoundtable["altsound"])])
		end
	end)

	self.Owner:ViewPunch(attacktable["punchstrength"])
end

function SWEP:HandleThrustAttack()
	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	local attacktable = GetTable(self.AttackTable)

	self:TriggerAnim(self.Owner, "a_heavy_2h_attack_stab_01")
	self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	self.Owner:GetViewModel():SetPlaybackRate(0.4)
	self.Weapon:EmitSound(self.WindUpSound)

	timer.Simple(attacktable["striketime"] - 0.05, function()
		if self:IsValid() and self.isAttacking then
			self.Weapon:EmitSound(attacksoundtable["altsound"][math.random(1, #attacksoundtable["altsound"])])
		end
	end)

	self.Owner:ViewPunch(attacktable["punchstrength"])
end

function SWEP:OnDeploy()
	local attacksoundtable = GetSoundTable(self.AttackSoundTable)
	self.Owner:ViewPunch(Angle(0, 5, 0))

	if not self.Owner.cwObserverMode then
		self.Weapon:EmitSound(attacksoundtable["drawsound"][math.random(1, #attacksoundtable["drawsound"])])
	end

	if SERVER and IsValid(self.Owner) then
		self.Owner:SetNetVar("ravenInterferenceActive", true)
	end
end

function SWEP:Holster()
	local player = self.OwnerOverride or self.Owner

	if IsValid(player) then
		player:SetNetVar("ravenInterferenceActive", false)

		timer.Remove(player:EntIndex().."IdleAnimation")
		self:StopAllAnims(player)
		player:SetNetVar("ThrustStance", false)
		player:SetLocalVar("ParrySuccess", false)
		player:SetLocalVar("Riposting", false)

		if CLIENT and player:IsPlayer() then
			local vm = player:GetViewModel()
			if IsValid(vm) then
				player:SetLocalVar("Parry", false)
				self:ResetBonePositions(vm)
				vm:SetSubMaterial(0, "")
				vm:SetSubMaterial(1, "")
				vm:SetSubMaterial(2, "")
			end
		end
	end

	return true
end

SWEP.ViewModelBoneMods = {
	["v_weapon.Knife_Handle"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Forearm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(14.444, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, -12.789), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(-0.556, 0, 2.407), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(-2.3, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0.925), angle = Angle(-56.667, 0, 0) }
}

SWEP.VElements = {
	["v_interference_totem"] = {
		type = "Model",
		model = "models/props_forest/utilitypole01b.mdl",
		bone = "v_weapon.Knife_Handle",
		rel = "",
		pos = Vector(3.9, 0.2, -17.143),
		angle = Angle(1.169, -61.949, 10.519),
		size = Vector(0.899, 0.899, 0.899),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

SWEP.WElements = {
	["w_interference_totem"] = {
		type = "Model",
		model = "models/props_forest/utilitypole01b.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(2.7, 1.3, 35.11),
		angle = Angle(180, -130, -2),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

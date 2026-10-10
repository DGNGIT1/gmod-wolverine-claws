if CLIENT then
    SWEP.PrintName = "Wolverine Claws"
    SWEP.Slot = 0
    SWEP.SlotPos = 1
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
    SWEP.ViewModelFOV = 55
end

SWEP.Base = "weapon_base"
SWEP.Category = "Fortnite"
SWEP.Author = "DGNGIT1"
SWEP.Contact = ""
SWEP.Purpose = "Replica 1:1 Fortnite Chapter 2 S4"
SWEP.Instructions = "Left click to slash. Right click to dash forward."
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_models/v_fortnite_wolverine_claws.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_fortnite_wolverine_claws.mdl"
SWEP.HoldType = "fist"

SWEP.Primary.Damage = 45
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.4

SWEP.Secondary.Damage = 90
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 1.2

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    self:SetHoldType(self.HoldType)
    return true
end

function SWEP:PrimaryAttack()
    if not IsValid(self:GetOwner()) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    self:EmitSound("weapons/knife/knife_slash1.wav")

    if CLIENT then return end

    local owner = self:GetOwner()
    owner:LagCompensation(true)

    local trace = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 75,
        filter = owner,
        mask = MASK_SHOT_HULL
    })

    if trace.Hit then
        self:EmitSound("weapons/knife/knife_hitwall1.wav")

        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamage(self.Primary.Damage)
        dmg:SetDamageType(DMG_SLASH)

        if IsValid(trace.Entity) then
            trace.Entity:TakeDamageInfo(dmg)
        end
    end

    owner:LagCompensation(false)
end

function SWEP:SecondaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    local aim = owner:GetAimVector()
    owner:SetVelocity(aim * 520 + Vector(0, 0, 150))
    owner:ViewPunch(Angle(-8, 0, 0))
    self:EmitSound("physics/flesh/flesh_squish1.wav")
end

if CLIENT then
    SWEP.PrintName = "Wolverine's Claws"
    SWEP.Slot = 0
    SWEP.SlotPos = 1
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
    SWEP.ViewModelFOV = 60
end

SWEP.Base = "weapon_base"
SWEP.Category = "Fortnite - Chapter 2 S4"
SWEP.Author = "DGNGIT1"
SWEP.Contact = ""
SWEP.Purpose = "Wolverine Claws from Fortnite Chapter 2 Season 4"
SWEP.Instructions = "LMB: 6-hit combo | RMB: Spin Slash | Jump + LMB: Air Dash | Shift: Flip Dodge"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_models/v_fortnite_wolverine_claws.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_fortnite_wolverine_claws.mdl"
SWEP.HoldType = "fist"
SWEP.UseHands = true

SWEP.Primary.Damage = 35
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.12
SWEP.Primary.StructureDamage = 50

SWEP.Secondary.Damage = 60
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 0.5

SWEP.AirDashDamage = 25
SWEP.AirDashStructureDamage = 40
SWEP.SpinSlashCooldown = 5
SWEP.AirDashCooldown = 5
SWEP.DodgeRollCooldown = 5
SWEP.PassiveHealPerSecond = 6
SWEP.SpeedBoostMultiplier = 1.25

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    self.ComboStep = 0
    self.ComboResetTime = 0
    self.LastSpinSlash = 0
    self.LastAirDash = 0
    self.LastDodge = 0
    self.LastPassiveHeal = CurTime()
    self:SetNextThink(CurTime() + 0.01)
end

function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            self.OriginalWalkSpeed = owner:GetWalkSpeed()
            self.OriginalRunSpeed = owner:GetRunSpeed()
            owner:SetWalkSpeed(self.OriginalWalkSpeed * self.SpeedBoostMultiplier)
            owner:SetRunSpeed(self.OriginalRunSpeed * self.SpeedBoostMultiplier)
        end
    end

    self:SetHoldType(self.HoldType)
    return true
end

function SWEP:Holster()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            if self.OriginalWalkSpeed then
                owner:SetWalkSpeed(self.OriginalWalkSpeed)
            end
            if self.OriginalRunSpeed then
                owner:SetRunSpeed(self.OriginalRunSpeed)
            end
        end
    end

    self.ComboStep = 0
    return true
end

function SWEP:Think()
    if not IsValid(self:GetOwner()) then return end

    local owner = self:GetOwner()
    local curTime = CurTime()

    if SERVER then
        if owner:KeyPressed(IN_SPEED) and owner:IsOnGround() and curTime - self.LastDodge >= self.DodgeRollCooldown then
            self:PerformDodgeRoll()
            self.LastDodge = curTime
        end

        if curTime - self.LastPassiveHeal >= 1 then
            owner:SetHealth(math.min(owner:GetHealth() + self.PassiveHealPerSecond, owner:GetMaxHealth()))
            self.LastPassiveHeal = curTime
        end
    end

    self:SetNextThink(curTime + 0.01)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local curTime = CurTime()

    if not owner:IsOnGround() and curTime - self.LastAirDash >= self.AirDashCooldown then
        self:PerformAirDash()
        self.LastAirDash = curTime
        return
    end

    if curTime > self.ComboResetTime then
        self.ComboStep = 0
    end

    self.ComboStep = self.ComboStep + 1
    if self.ComboStep > 6 then
        self.ComboStep = 1
    end

    local delay = 0.12
    if self.ComboStep == 5 then
        delay = 0.18
    elseif self.ComboStep == 6 then
        delay = 0.28
    end

    self.SetNextPrimaryFire = self.SetNextPrimaryFire or function() end
    self:SetNextPrimaryFire(curTime + delay)
    self:SetNextSecondaryFire(curTime + delay)

    self.ComboResetTime = curTime + 0.9

    owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:EmitSound("weapons/knife/knife_slash" .. math.random(1, 2) .. ".wav")

    if CLIENT then return end

    owner:LagCompensation(true)

    local trace = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 90,
        filter = owner,
        mask = MASK_SHOT_HULL
    })

    if trace.Hit and IsValid(trace.Entity) then
        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageType(DMG_SLASH)

        if trace.Entity:IsPlayer() or trace.Entity:IsNPC() then
            dmg:SetDamage(self.Primary.Damage)
            if self.ComboStep == 6 then
                dmg:SetDamage(45)
            end
        else
            dmg:SetDamage(self.Primary.StructureDamage)
            if self.ComboStep == 6 then
                dmg:SetDamage(80)
            end
        end

        trace.Entity:TakeDamageInfo(dmg)
        self:EmitSound("weapons/knife/knife_hitwall1.wav")
    end

    owner:LagCompensation(false)
end

function SWEP:SecondaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local curTime = CurTime()
    if curTime - self.LastSpinSlash < self.SpinSlashCooldown then return end

    self:SetNextSecondaryFire(curTime + 0.5)
    self.LastSpinSlash = curTime

    owner:SetAnimation(PLAYER_ATTACK2)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    self:EmitSound("physics/flesh/flesh_squish_violent2.wav")

    if CLIENT then return end

    owner:LagCompensation(true)

    local radius = 145
    local entities = ents.FindInSphere(owner:GetPos(), radius)

    for _, entity in ipairs(entities) do
        if entity ~= owner and IsValid(entity) then
            local canHit = entity:IsNPC() or entity:IsPlayer() or entity:GetClass() ~= "prop_physics"
            if canHit then
                local dmg = DamageInfo()
                dmg:SetAttacker(owner)
                dmg:SetInflictor(self)
                dmg:SetDamageType(DMG_SLASH)

                if entity:IsPlayer() or entity:IsNPC() then
                    dmg:SetDamage(self.Secondary.Damage)
                else
                    dmg:SetDamage(90)
                end

                entity:TakeDamageInfo(dmg)
            end
        end
    end

    self:EmitSound("weapons/knife/knife_hitwall1.wav")
    owner:LagCompensation(false)
end

function SWEP:PerformAirDash()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local aim = owner:GetAimVector()
    owner:SetVelocity(aim * 620 + Vector(0, 0, 150))
    owner:ViewPunch(Angle(-10, 0, 0))
    self:EmitSound("physics/flesh/flesh_impact_bullet1.wav")

    if CLIENT then return end

    owner:LagCompensation(true)
    local trace = util.TraceLine({
        start = owner:GetPos(),
        endpos = owner:GetPos() + aim * 120,
        filter = owner,
        mask = MASK_SHOT_HULL
    })

    if trace.Hit and IsValid(trace.Entity) then
        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageType(DMG_SLASH)

        if trace.Entity:IsPlayer() or trace.Entity:IsNPC() then
            dmg:SetDamage(self.AirDashDamage)
        else
            dmg:SetDamage(self.AirDashStructureDamage)
        end

        trace.Entity:TakeDamageInfo(dmg)
        self:EmitSound("weapons/knife/knife_hitwall1.wav")
    end

    owner:LagCompensation(false)
end

function SWEP:PerformDodgeRoll()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local direction = owner:GetForward()
    owner:SetVelocity(direction * 420 + Vector(0, 0, 60))
    owner:ViewPunch(Angle(-8, 0, 0))
    self:EmitSound("physics/body/body_medium_impact_hard1.wav")
end

function SWEP:OnRemove()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            if self.OriginalWalkSpeed then
                owner:SetWalkSpeed(self.OriginalWalkSpeed)
            end
            if self.OriginalRunSpeed then
                owner:SetRunSpeed(self.OriginalRunSpeed)
            end
        end
    end
end

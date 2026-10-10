if CLIENT then
    SWEP.PrintName = "Wolverine's Claws"
    SWEP.Slot = 0
    SWEP.SlotPos = 1
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
    SWEP.ViewModelFOV = 55
end

SWEP.Base = "weapon_base"
SWEP.Category = "Fortnite - Chapter 2 S4"
SWEP.Author = "DGNGIT1"
SWEP.Contact = ""
SWEP.Purpose = "Wolverine's Mythic weapon from Fortnite Chapter 2 Season 4"
SWEP.Instructions = "Left Click: Slash | Right Click: Spin Slash | Jump + Attack: Air Dash"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_models/v_fortnite_wolverine_claws.mdl"
SWEP.WorldModel = "models/weapons/w_models/w_fortnite_wolverine_claws.mdl"
SWEP.HoldType = "fist"
SWEP.UseHands = true

-- Primary Attack (Swipe)
SWEP.Primary.Damage = 35
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.15

-- Secondary Attack (Spin Slash)
SWEP.Secondary.Damage = 60
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 0.5

-- Air Dash Damage
SWEP.AirDashDamage = 25
SWEP.AirDashStructureDamage = 40

-- Passive Abilities
SWEP.PassiveHealingPerSec = 2
SWEP.SpeedBoostMultiplier = 1.25

-- Cooldowns
SWEP.SpinSlashCooldown = 5
SWEP.AirDashCooldown = 5

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    
    -- Initialize tracking variables
    if SERVER then
        self.LastSpinSlashTime = 0
        self.LastAirDashTime = 0
        self.LastHealTime = CurTime()
    end
end

function SWEP:Deploy()
    self:SetHoldType(self.HoldType)
    
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Apply speed boost when deployed
            owner:SetRunSpeed(owner:GetRunSpeed() * self.SpeedBoostMultiplier)
            owner:SetWalkSpeed(owner:GetWalkSpeed() * self.SpeedBoostMultiplier)
        end
    end
    
    return true
end

function SWEP:Holster()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Reset speed when holstered
            owner:SetRunSpeed(owner:GetRunSpeed() / self.SpeedBoostMultiplier)
            owner:SetWalkSpeed(owner:GetWalkSpeed() / self.SpeedBoostMultiplier)
        end
    end
    
    return true
end

-- PRIMARY ATTACK: Swipe Combo
function SWEP:PrimaryAttack()
    if not IsValid(self:GetOwner()) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:EmitSound("weapons/knife/knife_slash1.wav")

    if CLIENT then return end

    owner:LagCompensation(true)

    -- Melee trace for swipe
    local trace = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 85,
        filter = owner,
        mask = MASK_SHOT_HULL
    })

    if trace.Hit and IsValid(trace.Entity) then
        self:EmitSound("weapons/knife/knife_hitwall1.wav")

        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageType(DMG_SLASH)
        
        -- Damage varies: 35 for players, 50 for structures
        if trace.Entity:IsNPC() or trace.Entity:IsPlayer() then
            dmg:SetDamage(self.Primary.Damage)
        else
            dmg:SetDamage(50) -- Structure damage
        end

        trace.Entity:TakeDamageInfo(dmg)
    end

    owner:LagCompensation(false)
end

-- SECONDARY ATTACK: Spin Slash (Whirlwind Attack)
function SWEP:SecondaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local currentTime = CurTime()
    
    -- Check cooldown
    if currentTime - self.LastSpinSlashTime < self.SpinSlashCooldown then
        return
    end

    self:SetNextSecondaryFire(CurTime() + 0.5)
    self.LastSpinSlashTime = currentTime

    owner:SetAnimation(PLAYER_ATTACK2)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    self:EmitSound("physics/flesh/flesh_squish_violent2.wav")

    if CLIENT then return end

    owner:LagCompensation(true)

    -- Spin Slash hits all entities in radius
    local spinRadius = 120
    local ents = ents.FindInSphere(owner:GetPos(), spinRadius)

    for _, entity in ipairs(ents) do
        if entity ~= owner and IsValid(entity) and (entity:IsNPC() or entity:IsPlayer() or not entity:IsMoving()) then
            if (entity:IsNPC() or entity:IsPlayer()) or not entity:GetClass():find("weapon") then
                local dmg = DamageInfo()
                dmg:SetAttacker(owner)
                dmg:SetInflictor(self)
                dmg:SetDamageType(DMG_SLASH)
                
                if entity:IsNPC() or entity:IsPlayer() then
                    dmg:SetDamage(self.Secondary.Damage)
                else
                    dmg:SetDamage(80) -- Higher structure damage for spin
                end

                entity:TakeDamageInfo(dmg)
                self:EmitSound("weapons/knife/knife_hitwall1.wav")
            end
        end
    end

    owner:LagCompensation(false)
end

-- SPECIAL: Air Dash (triggered while in air)
function SWEP:Think()
    if not IsValid(self:GetOwner()) then return end

    local owner = self:GetOwner()
    local currentTime = CurTime()

    -- Passive Healing
    if SERVER then
        if currentTime - self.LastHealTime >= 1 then
            owner:SetHealth(math.min(owner:GetHealth() + self.PassiveHealingPerSec, owner:GetMaxHealth()))
            self.LastHealTime = currentTime
        end
    end

    -- Check for Air Dash input
    if SERVER then
        if owner:KeyPressed(IN_ATTACK) and not owner:IsOnGround() then
            if currentTime - self.LastAirDashTime >= self.AirDashCooldown then
                self:PerformAirDash()
                self.LastAirDashTime = currentTime
            end
        end
    end

    self:SetNextThink(CurTime() + 0.01)
end

function SWEP:PerformAirDash()
    local owner = self:GetOwner()
    if not IsValid(owner) or CLIENT then return end

    local aimVector = owner:GetAimVector()
    owner:SetVelocity(aimVector * 600 + Vector(0, 0, 150))
    owner:ViewPunch(Angle(-12, math.Rand(-5, 5), 0))

    self:EmitSound("physics/flesh/flesh_impact_bullet1.wav")

    -- Air Dash damage on contact
    owner:LagCompensation(true)

    local trace = util.TraceLine({
        start = owner:GetPos(),
        endpos = owner:GetPos() + aimVector * 100,
        filter = owner,
        mask = MASK_SHOT_HULL
    })

    if trace.Hit and IsValid(trace.Entity) then
        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageType(DMG_SLASH)
        
        if trace.Entity:IsNPC() or trace.Entity:IsPlayer() then
            dmg:SetDamage(self.AirDashDamage)
        else
            dmg:SetDamage(self.AirDashStructureDamage)
        end

        trace.Entity:TakeDamageInfo(dmg)
        self:EmitSound("weapons/knife/knife_hitwall1.wav")
    end

    owner:LagCompensation(false)
end

-- Holster handling
function SWEP:OnDrop()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:SetRunSpeed(owner:GetRunSpeed() / self.SpeedBoostMultiplier)
            owner:SetWalkSpeed(owner:GetWalkSpeed() / self.SpeedBoostMultiplier)
        end
    end
end

AddCSLuaFile() -- Permite descărcarea fișierului de către clienți

SWEP.PrintName          = "Ghearele lui Wolverine (Fortnite)"
SWEP.Author             = "Numele Tău"
SWEP.Purpose            = "Replica 1:1 Fortnite Chapter 2 S4"
SWEP.Spawnable          = true -- Apare în meniul de spawn
SWEP.AdminSpawnable     = true

SWEP.ViewModel          = "models/weapons/v_models/v_fortnite_wolverine_claws.mdl"
SWEP.WorldModel         = "models/weapons/w_models/w_fortnite_wolverine_claws.mdl"
SWEP.HoldType           = "fist" -- Poziția în care le ține playerul la persoana a 3-a

SWEP.Primary.Damage         = 45 -- Damage per lovitură normală
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay          = 0.4

SWEP.Secondary.Damage       = 90 -- Atac greu / Lunge în Fortnite

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    owner:SetAnimation( PLAYER_ATTACK1 )
    self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

    -- Emiterea unui sunet de tăiere (Slashed sound) specific
    self:EmitSound("weapons/knife/knife_slash1.wav")

    if CLIENT then return end

    -- Determinarea razei de acțiune melee (Tracer)
    local trace = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (owner:GetAimVector() * 75), -- 75 unități distanță
        filter = owner
    })

    if trace.Hit then
        self:EmitSound("weapons/knife/knife_hitwall1.wav")
        
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( self )
        dmginfo:SetDamage( self.Primary.Damage )
        dmginfo:SetDamageType( DMG_SLASH )
        
        if IsValid(trace.Entity) then
            trace.Entity:TakeDamageInfo( dmginfo )
        end
    end
end

function SWEP:SecondaryAttack()
    -- Poți adăuga un atac special de tip „Lunge Dash" cu salt în față,
    -- specific abilității mitice a lui Wolverine din acel sezon.
    self:SetNextSecondaryFire( CurTime() + 1.5 )
    local owner = self:GetOwner()
    if not IsValid(owner) or CLIENT then return end
    
    owner:SetVelocity( owner:GetAimVector() * 600 + Vector(0, 0, 150) )
    self:EmitSound("physics/flesh/flesh_squish1.wav")
end

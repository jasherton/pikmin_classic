if (SERVER) then
	AddCSLuaFile("shared.lua");
	
	SWEP.Weight				= 5;
	SWEP.AutoSwitchTo		= false;
	SWEP.AutoSwitchFrom		= false;
end


if (CLIENT) then
	SWEP.PrintName			= ("Olimar Gun");	
	SWEP.Slot				= 1;
	SWEP.SlotPos			= 1;
	SWEP.DrawAmmo			= false;
	SWEP.DrawCrosshair		= true;
	SWEP.WepSelectIcon = surface.GetTextureID("weapons/pikmincommand");
end

function SWEP:Initialize()
	self.Owner.HasPikmin = false;
	self.WhistleSound = CreateSound(self, Sound("pikmin/whistle.wav"));
	if (SERVER) then
		self:SetWeaponHoldType(self.HoldType);
	end
end

function SWEP:Deploy()
	if (SERVER) then
		self.Owner.HasPikmin = false;
		self:SendWeaponAnim(ACT_VM_DRAW);
		timer.Destroy("PikDeployIdleAnim" .. self.Owner:UniqueID());
		timer.Create("PikDeployIdleAnim" .. self.Owner:UniqueID(), 1.2, 1, self.SendWeaponAnim, self, ACT_VM_IDLE);
	end
	return true;
end

function SWEP:Holster()
	if (SERVER) then
		timer.Destroy("PikDeployIdleAnim" .. self.Owner:UniqueID());
		timer.Destroy("PikPrimaryIdleAnim" .. self.Owner:UniqueID());
		timer.Destroy("Pik2ndryIdleAnim" .. self.Owner:UniqueID());
		timer.Destroy("PikReloadIdleAnim" .. self.Owner:UniqueID());
		self.Whistling = false;
		self.WhistleSound:Stop();
		if (ValidEntity(throwpikmin)) then
			throwpikmin = nil;
		end
		self:SendWeaponAnim(ACT_VM_HOLSTER);
	end
	return true;
end

function SWEP:PrimaryAttack()
end

SWEP.SelRadius = 0;

function SWEP:Think()
	if (self.Whistling) then
		self.SelRadius = (self.SelRadius + 2); //Grow larger as long as we whistle
		local tr = util.QuickTrace(self.Owner:GetShootPos(), (self.Owner:GetAimVector() * 750), {self.Owner, self});
		if (tr.Hit) then
			local pos = tr.HitPos;
			for k, v in pairs(ents.FindByClass("pikmin")) do
				if (v:GetPos():Distance(pos) <= (10 + self.SelRadius)) then
					if (v.Dismissed) then
						v:Join(self.Owner);
					end
					if (v.Olimar == self.Owner) then
						if (v:IsOnFire()) then
							v:Extinguish();
						end
						v.AtkTarget = nil;
						if (v.Attacking) then
							local quickpos = v:GetPos();
							v.Attacking = false;
							v:SetParent();
							v:SetPos((quickpos + Vector(0, 0, 8)));
							v.Victim = nil;
						end
					end
				end
			end
		end
	end
end

local throwpikmin = nil;

local function PikSWepKeyPress(ply, key)
	if (SERVER) then
		if (ply:Alive()) then
			if (ValidEntity(ply:GetActiveWeapon()) && ply:GetActiveWeapon():GetClass() == "olimar_gun") then
				if (key == IN_ATTACK) then
					local piks = {};
					local check = false;
					for k, v in pairs(ents.FindByClass("pikmin")) do
						if (v.Olimar == ply && !v.Attacking) then
							local pos = ply:GetPos();
							local ppos = v:GetPos();
							if (ppos:Distance(pos) <= 200 && !v.JustThrown) then
								check = true;
								table.insert(piks, v);
							end
						end
					end
					if (check) then
						timer.Destroy("PikPrimaryGrabSound" .. ply:UniqueID());
						local rnd = math.random(1, #piks);
						throwpikmin = piks[rnd];
						ply.HasPikmin = true;
						timer.Create("PikPrimaryGrabSound" .. ply:UniqueID(), .8, 1,
							function(ply)
								if (ply.HasPikmin) then
									ply:EmitSound(Sound("pikmin/grab.wav"));
								end
							end, ply);
					end
				end
				if (key == IN_RELOAD) then
					if (!ply:KeyDown(IN_USE)) then
						local tr = util.QuickTrace(ply:GetShootPos(), (ply:GetAimVector() * 1000), {ply, ply:GetActiveWeapon()});
						if (tr.Hit) then
							timer.Destroy("PikWhistlefor" .. ply:UniqueID());
							timer.Destroy("PikPrimaryIdleAnim" .. ply:UniqueID());
							timer.Destroy("Pik2ndryIdleAnim" .. ply:UniqueID());
							timer.Destroy("Pik2ndWhistle" .. ply:UniqueID());
							timer.Destroy("PikDeployIdleAnim" .. ply:UniqueID());
							timer.Destroy("PikReloadIdleAnim" .. ply:UniqueID());
							ply:GetActiveWeapon().Whistling = true;
							ply:GetActiveWeapon().WhistleSound:Stop();
							ply:GetActiveWeapon().WhistleSound:Play();
							ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_RELOAD);
							timer.Create("PikReloadIdleAnim" .. ply:UniqueID(), 1.45, 1,
								function()
									ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE);
								end);
							timer.Create("PikWhistlefor" .. ply:UniqueID(), 1.4, 1,
								function()
									if (ply:GetActiveWeapon().Whistling) then
										ply:GetActiveWeapon().Whistling = false;
										ply:GetActiveWeapon().WhistleSound:Stop();
									end
								end);
						end
					else
						local doanim = false;
						if (ply.Whistling) then
							ply.Whistling = false;
							ply.WhistleSound:Stop();
						end
						for k, v in pairs(ents.FindByClass("pikmin")) do
							if (v.Olimar == ply) then
								doanim = true;
								v:Disband();
							end
						end
						if (doanim) then
							timer.Destroy("PikReloadIdleAnim" .. ply:UniqueID());
							timer.Destroy("PikDeployIdleAnim" .. ply:UniqueID());
							timer.Destroy("Pik2ndryIdleAnim" .. ply:UniqueID());
							timer.Destroy("Pik2ndWhistle" .. ply:UniqueID());
							ply:GetActiveWeapon().WhistleSound:Stop()
							ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_DRYFIRE);
							timer.Create("PikReloadIdleAnim" .. ply:UniqueID(), .75, 1,
										function()
											ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE);
										end);
							ply:EmitSound("pikmin/disband.wav");
						end
					end
				end
			end
		end
	end
end
hook.Add("KeyPress", "GrabPikmin", PikSWepKeyPress);

local function PikSWepKeyRelease(ply, key) //release primary, throw pikmin
	if (SERVER) then
		if (ply:Alive()) then
			if (ValidEntity(ply:GetActiveWeapon()) && ply:GetActiveWeapon():GetClass() == "olimar_gun") then
				if (key == IN_ATTACK) then
					if (ValidEntity(throwpikmin) && ply.HasPikmin) then
						timer.Destroy("PikPrimaryIdleAnim" .. ply:UniqueID());
						timer.Destroy("PikDeployIdleAnim" .. ply:UniqueID());
						local pik = throwpikmin;
						local ppos = pik:GetPos();
						local vec = ply:GetAimVector();
						local phys = pik:GetPhysicsObject();
						pik:SetPos((ply:GetShootPos() + (vec * 25)));
						local force = 50;
						if (pik:GetPikType() == "yellow") then
							force = 75;
						elseif (pik:GetPikType() == "purple") then
							force = 45;
						end
						vec = (vec * force);
						if (phys:IsValid()) then
							phys:ApplyForceCenter(((vec + Vector(0, 0, 5)) * 125));
						end
						ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_PRIMARYATTACK);
						ply:SetAnimation(ACT_MELEE_ATTACK_SWING); //this doesnt work  :(
						pik:SetAnim("thrown");
						ply:EmitSound("pikmin/pikmin_throw.wav");
						timer.Create("PikPrimaryIdleAnim" .. ply:UniqueID(), .75, 1,
							function()
								ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE);
							end);
						pik.JustThrown = true; //Going to check if they should follow us while in the air...
						pik.ShouldSpin = true;
						pik.CanMove = false;
						timer.Simple(2.5,
							function()
								if (ValidEntity(pik)) then
									pik.CanMove = true;
									pik.JustThrown = false;
								end
							end);
						ply.HasPikmin = false;
					end
				end
				if (key == IN_RELOAD) then
					if (ply:GetActiveWeapon().Whistling) then
						timer.Destroy("PikReloadIdleAnim" .. ply:UniqueID());
						timer.Destroy("PikDeployIdleAnim" .. ply:UniqueID());
						ply:GetActiveWeapon():SendWeaponAnim(ACT_VM_IDLE);
						ply:GetActiveWeapon().Whistling = false;
						ply:GetActiveWeapon().WhistleSound:FadeOut(.2);
						ply:GetActiveWeapon().SelRadius = 0;
					end
				end
			end
		end
	end
end
hook.Add("KeyRelease", "ThrowPikmin", PikSWepKeyRelease);

function SWEP:SecondaryAttack()
	local tr = util.QuickTrace(self.Owner:GetShootPos(), (self.Owner:GetAimVector() * 10000), self.Owner);
	if (ValidEntity(tr.Entity)) then
		for k, v in pairs(ents.FindByClass("pikmin")) do
			if (v.Olimar == self.Owner && (tr.Entity:IsNPC() || tr.Entity:IsPlayer())) then
				timer.Destroy("Pik2ndryIdleAnim" .. self.Owner:UniqueID());
				timer.Destroy("Pik2ndWhistle" .. self.Owner:UniqueID());
				self.WhistleSound:Stop();
				v.AtkTarget = tr.Entity;
				self:SendWeaponAnim(ACT_VM_SECONDARYATTACK);
				timer.Create("Pik2ndryIdleAnim" .. self.Owner:UniqueID(), 1.3, 1, self.SendWeaponAnim, self, ACT_VM_IDLE);
				self.WhistleSound:Play();
				timer.Create("Pik2ndWhistle" .. self.Owner:UniqueID(), 1.45, 1,
					function()
						if (ValidEntity(self)) then
							self.WhistleSound:Stop();
						end
					end);
			end
		end
	end
end

------------General Swep Info---------------
SWEP.Author = ("Aska");
SWEP.Purpose = ("Control Pikmin");
SWEP.Instructions = ("Primary Fire - Throw Pikmin\nSecondary Fire - Order Pikmin to attack\nReload - Whistle (hold to call Pikmin)\nUse+Reload - Dismiss Pikmin");
SWEP.Spawnable = true;
SWEP.AdminSpawnable = true;
SWEP.HoldType = ("melee");
SWEP.Category = ("Aska's SWeps");
-----------------------------------------------

------------Models---------------------------
SWEP.ViewModel = ("models/weapons/v_olimar.mdl");
SWEP.WorldModel = ("models/weapons/w_olimar.mdl");
-----------------------------------------------
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include('shared.lua');


/*****************************************
Initialize and spawn functions
Gotta have these, or we have no SEnt!
******************************************/

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:DrawShadow(false);
	self:SetColor(255, 255, 255, 255);
	self:StartMotionController();
	self.DrownSound = CreateSound(self, "pikmin/drowning.wav");
	for k, v in pairs(ents.FindByClass("pikmin")) do
		if (ValidEntity(v) && v != self) then
			constraint.NoCollide(self, v, 0, 0); 
		end
	end
	local phys = self:GetPhysicsObject();
	if (phys:IsValid()) then
		phys:SetBuoyancyRatio(.375);
		phys:Wake();
	end
end

function ENT:SpawnFunction(ply, tr)
	ply:ConCommand("pikmin_menu");
end


/*****************************************
Easy access functions
Things like returning variables or setting them
******************************************/

function ENT:Mdl()
	if (ValidEntity(self.PikMdl)) then
		return self.PikMdl;
	end
	return nil;
end

function ENT:SetAnim(anim)
	local mdl = self:Mdl();
	mdl.Anim = anim;
end

function ENT:GetAnim()
	local mdl = self:Mdl();
	if (mdl.Anim) then
		return tostring(mdl.Anim);
	end
	return nil;
end

function ENT:SetPikLevel(lvl)
	self.PikLevel = tonumber(lvl);
	self:Mdl():SetModel("models/pikmin/pikmin_" .. self:GetPikType() .. self:GetPikLevel() .. ".mdl");
	self:Mdl():SetNetworkedInt("Level", lvl);
end

function ENT:GetPikLevel()
	if (self.PikLevel) then
		return tonumber(self.PikLevel);
	end
	return nil;
end

function ENT:GetPikType()
	if (self.PikClr) then
		return tostring(self.PikClr);
	end
	return nil;
end

/*****************************************
Juicy, meaty, core code
Here is where the Pikmin come alive!
******************************************/

function ENT:CreatePikRagdoll(dis)
	local mdl = self:Mdl();
	//w00t at TetaBonita for the ragdoll code!
	local rag = ents.Create("prop_ragdoll");
	rag:SetModel(mdl:GetModel());
	rag:SetPos(mdl:GetPos());
	rag:SetAngles(mdl:GetAngles());
	rag:Spawn();
	if (!rag:IsValid()) then
		return
	end
	rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
	local entvel;
	local entphys = self:GetPhysicsObject();
	if (entphys:IsValid()) then
		entvel = entphys:GetVelocity();
	else
		entvel = self:GetVelocity();
	end
	for i = 1, rag:GetPhysicsObjectCount() do
		local bone = rag:GetPhysicsObjectNum(i);
		if (ValidEntity(bone)) then
			local bonepos, boneang = mdl:GetBonePosition(rag:TranslatePhysBoneToBone(i));
			bone:SetPos(bonepos);
			bone:SetAngle(boneang);
			if (dis) then //is this for the dissolve effect?
				bone:ApplyForceOffset((self:GetVelocity() * .04), self:GetPos());
				bone:AddVelocity((entvel * .05));
				bone:AddVelocity(Vector(0, 0, 10));
				bone:EnableGravity(false);
			else
				bone:ApplyForceOffset(self:GetVelocity(), self:GetPos());
				bone:AddVelocity(entvel);
			end
		end
	end
	rag:SetSkin(mdl:GetSkin());
	rag:SetColor(mdl:GetColor());
	rag:SetMaterial(mdl:GetMaterial());
	local phys = rag:GetPhysicsObject();
	if (phys:IsValid()) then
		phys:EnableGravity(false);
		phys:ApplyForceCenter(Vector(0, 0, 5));
	end
	self:Remove();
	return rag;
end

local function PikminCreate(ply, cmd, args)
	if (!args[1]) then
		return;
	end
	if (args[1] == "red" || args[1] == "yellow" || args[1] == "blue" || args[1] == "purple" || args[1] == "white" || args[1] == "random") then
		local mdlstr = "models/pikmin/pikmin_red1.mdl";
		local pikhp = 24;
		local pikdmg = 3;
		local clr = string.lower(args[1]);
		if (clr == "yellow") then
			mdlstr = "models/pikmin/pikmin_yellow1.mdl";
		elseif (clr == "blue") then
			mdlstr = "models/pikmin/pikmin_blue1.mdl";
		elseif (clr == "purple") then
			mdlstr = "models/pikmin/pikmin_purple1.mdl";
		elseif (clr == "white") then
			mdlstr = "models/pikmin/pikmin_white1.mdl";
		elseif (clr == "random") then
			local rnd = math.random(1, 5);
			if (rnd == 1) then
				clr = "red";
			elseif (rnd == 2) then
				clr = "yellow";
			elseif (rnd == 3) then
				clr = "blue";
			elseif (rnd == 4) then
				clr = "purple";
			elseif (rnd == 5) then
				clr = "white";
			end
			mdlstr = "models/pikmin/pikmin_" .. clr .. "1.mdl";
		end
		if (clr == "yellow") then
			pikhp = 18;
			pikdmg = 2;
		elseif (clr == "blue") then
			pikhp = 28;
			pikdmg = 2;
		elseif (clr == "purple") then
			pikhp = 40;
			pikdmg = 6;
		elseif (clr == "white") then
			pikhp = 12.5;
			pikdmg = 1;
		end
		local pos = ply:GetShootPos();
		pos = (pos + ((ply:GetForward() * -1) * 32));
		pos = (pos + (ply:GetRight() * math.Rand(-50, 50)));
		local ent = ents.Create("pikmin");
		ent.Olimar = ply;
		ent.PikClr = clr;
		ent.PikHP = pikhp;
		ent.PikDmg = pikdmg;
		if (clr != "purple" && clr != "white") then
			ent:SetModel("models/pikmin/pikmin_collision.mdl");
		else
			local str = string.Left(clr, 1);
			ent:SetModel("models/pikmin/pikmin_collision" .. str .. ".mdl");
		end
		ent:SetPos(pos);
		ent:SetMoveCollide(MOVECOLLIDE_FLY_SLIDE);
		ent:EmitSound(Sound("pikmin/pikmin_pluck.wav"));
		ent:Spawn();
		ent:Activate();
		local mdl = ents.Create("pikmin_model");
		mdl:SetModel(mdlstr);
		mdl:SetPos(ent:GetPos());
		mdl:SetParent(ent);
		mdl:Spawn();
		mdl:Activate();
		ent.PikMdl = mdl;
		ent.PikMdl:SetNetworkedString("Color", clr);
		ent:SetPikLevel(1);
		undo.Create(clr .. " Pikmin");
			undo.AddEntity(ent);
			undo.SetPlayer(ply);
		undo.Finish();
	else
		ply:ChatPrint("Not a valid color: red, yellow, blue, purple, white");
	end
end
concommand.Add("pikmin_create", PikminCreate);

function ENT:Disband()
	if (!self.Attacking && !ValidEntity(self.AtkTarget)) then //Don't disband if we're attacking or charging after an enemy, our leader still wants the kill!
		self.DismissShadowAng = self:GetAngles();
		self.Olimar = nil;
		self.Dismissed = true;
		self.AtkTarget = nil;
		self.Attacking = false;
		self.Victim = nil;
		self:Mdl():SetNetworkedBool("Dismissed", true);
		self:SetAnim("dismissed");
	end
end

function ENT:Join(ent)
	self.Olimar = ent;
	self.Dismissed = false;
	self.RejoinAnim = true;
	self:EmitSound("pikmin/coming.wav");
	timer.Simple(.325, 
		function()
			if (ValidEntity(self)) then
				self.RejoinAnim = false;
			end
		end);
	self:Mdl():SetNetworkedBool("Dismissed", false);
	self:SetAnim("join");
end

function ENT:LatchOn(ent)
	if (ValidEntity(ent) && (ent:IsNPC() || ent:IsPlayer()) && (self.JustThrown || ValidEntity(self.AtkTarget))) then
		if (self:GetPikType() == "purple" && self.JustThrown) then
			ent:TakeDamage(10);
			self:EmitSound("physics/body/body_medium_impact_hard" .. math.random(4, 6) .. ".wav");
		end
		local pos = self:GetPos();
		local epos = ent:GetPos();
		local dir = (epos - pos):Angle();
		self.Attacking = true;
		self.Victim = ent;
		self:SetAnim("attack");
		self:SetAngles(dir);
		self:SetParent(ent);
	end
end

function ENT:Die()
	local rag = self:CreatePikRagdoll(false);
	if (self:IsOnFire()) then
		rag:Ignite(math.Rand(8, 10), 0);
	end
	local clr = self.PikClr;
	if (clr == "red") then
		rag.cr = 255;
		rag.cg = 10;
		rag.cb = 10;
	elseif (clr == "yellow") then
		rag.cr = 255;
		rag.cg = 255;
		rag.cb = 10;
	elseif (clr == "blue") then
		rag.cr = 10;
		rag.cg = 10;
		rag.cb = 255;
	elseif (clr == "purple") then
		rag.cr = 200;
		rag.cg = 10;
		rag.cb = 200;
	elseif (clr == "white") then
		rag.cr = 250;
		rag.cg = 250;
		rag.cb = 250;
	end
	self.DrownSound:Stop();
	self:EmitSound("pikmin/pikmin_die.wav", 100, math.random(95, 110));
	self:Remove();
	timer.Simple(math.Rand(1.6, 2.5), //Give it some random-ness, so they don't die in order so much
		function(rag)
			if (ValidEntity(rag)) then
				local pos = rag:GetPos();
				local r = rag.cr;
				local g = rag.cg;
				local b = rag.cb;
				local effectdata = EffectData();
				effectdata:SetOrigin(rag:GetPos());
				effectdata:SetStart(Vector(r, g, b));
				util.Effect("pikmin_pop", effectdata);
				local effectdata = EffectData();
				effectdata:SetOrigin((rag:GetPos() + Vector(0, 0, 15)));
				effectdata:SetStart(Vector((r * .5), (g * .5), (b * .5)));
				util.Effect("pikmin_deathsoul", effectdata);
				rag:EmitSound(Sound("pikmin/pikmin_pop.wav"), 100, math.random(95, 110));
				rag:Remove();
			end
		end, rag);
end

function ENT:OnRemove()
	self.DrownSound:Stop();
	self:SetParent();
	if (self.Carrying && ValidEntity(self.CarryEnt)) then
		local ent = self.CarryEnt;
		local num = 1;
		if (self:GetPikType() == "purple") then
			num = 10;
		end
		ent.NumCarry = (ent.NumCarry - num);
		local typ = self:GetPikType();
		if (typ == "red") then
			ent.Reds = (ent.Reds - 1);
		elseif (typ == "yellow") then
			ent.Yellows = (ent.Blues - 1);
		elseif (typ == "blue") then
			ent.Blues = (ent.Blues - 1);
		end
	end
end

function ENT:OnTakeDamage(dmg)
	dmg:SetDamageForce((dmg:GetDamageForce() * .25));
	self:TakePhysicsDamage(dmg);
	self.PikHP = (self.PikHP - dmg:GetDamage());
	if (self.PikHP <= 0) then
		if (self:GetPikType() == "white") then //Poison the bastards that killed us
			local ef = EffectData();
				ef:SetOrigin(self:GetPos());
			util.Effect("pikmin_poison", ef);
			local poisonpos = self:GetPos();
			local pikolimar = self.Olimar;
			timer.Create("PikPoisonfor " .. self:EntIndex(), .9, math.random(10, 12),
				function(pos, o) //Todo: Clean this function
					for k, v in pairs(ents.FindInSphere(pos, 125)) do
						if (v:IsPlayer() && v != o) then
							local coughrand = math.random(1, 2);
							if (coughrand == 1) then
								v:EmitSound("ambient/voices/cough" .. tostring(math.random(1, 4)) .. ".wav");
							end
							v:TakeDamage(math.random(1, 2), (o || self), self);
						end
					if (v:IsNPC()) then
						v:TakeDamage(math.random(1, 2), (o || self), self);
					end
					if (v:GetClass() == "pikmin") then
						if (v:GetPikType() == "white") then
							timer.Destroy("PikPoisonfor" .. v:EntIndex());
						end
					end
				end
			end, poisonpos, pikolimar);
		end
		self:Die(); // 3:
	else
		if (self:GetPikLevel() != 1) then
			local lvl = self:GetPikLevel();
			local effectdata = EffectData();
			local pos, ang;
			if (lvl == 2) then
				pos, ang = self:Mdl():GetBonePosition(self:Mdl():LookupBone("piki_bud"));
			else
				pos, ang = self:Mdl():GetBonePosition(self:Mdl():LookupBone("piki_flower"));
			end
			effectdata:SetOrigin(pos);
			local r = 255;
			local g = 255;
			local b = 255;
			if (self:GetPikType() == "white" || self:GetPikType() == "purple") then
				r = 220;
				g = 100;
				b = 150;
			end
			effectdata:SetStart(Vector(r, g, b));
			util.Effect("pikmin_leveldown", effectdata);
			self:SetPikLevel((self:GetPikLevel() - 1));
		end
	end
end

function ENT:PhysicsSimulate(phys, delta)
	local pos = self:GetPos();
	phys:Wake();
	self.ShadowParams={};
	self.ShadowParams.secondstoarrive = .2;
	
	if (ValidEntity(self.Olimar)) then
		pos = self.Olimar:GetPos();
	end
	if (ValidEntity(self.AtkTarget)) then
		pos = self.AtkTarget:GetPos();
	end
	
	self.ShadowParams.pos = Vector(0, 0, 0);
	self.ShadowParams.angle = (pos - self:GetPos()):Angle();
	self.ShadowParams.angle.p = 0; //Don't be turning your whole body up and down...
	if (self.Dismissed) then
		self.ShadowParams.angle = self.DismissShadowAng;
		self.ShadowParams.angle.p = 0;
	end
	self.ShadowParams.maxangular = 5000;
	self.ShadowParams.maxangulardamp = 10000;
	self.ShadowParams.maxspeed = 0;
	self.ShadowParams.maxspeeddamp = 0;
	self.ShadowParams.dampfactor = 0.8;
	self.ShadowParams.teleportdistance = 0;
	self.ShadowParams.deltatime = delta;
	phys:ComputeShadowControl(self.ShadowParams);
end

ENT.LastHop = 0;
ENT.LastObHop = 0;
ENT.NextAttack = 0;
ENT.PlayDrownSound = true;
ENT.DrownTime = 0;
ENT.DrowningTimeBool = false;
ENT.CanMove = true;
ENT.ShouldSpin = false;
ENT.LastPullApart = 0;
ENT.Held = false;

function ENT:Think()
	local pos = self:GetPos();
	local vel = self:GetVelocity();
	if (self.Dismissed) then
		self:SetAnim("dismissed");
	end
	if (vel:Length() <= 5 && !self.Dismissed && !self.Victim && (!self.ShouldSpin || !self.JustThrown) && !self.RejoinAnim && !self.Sucking) then
		self:SetAnim("idle");
	end
	if (vel:Length() >= 6 && !self.Dismissed && !self.Victim && (!self.ShouldSpin || !self.JustThrown) && !self.RejoinAnim && !self.Sucking) then
		self:SetAnim("running");
	end
	//Fail-safe
	if ((!ValidEntity(self.Olimar) || !self.Olimar:Alive()) && !self.Dismissed) then
		self:Disband();
	end
	if (self.Sucking) then
		self:SetAnim("nectar");
	end
	if (!self.Attacking && CurTime() >= self.LastPullApart) then
		self.LastPullApart = (CurTime() + .75);
		for k, v in pairs(ents.FindByClass("pikmin")) do
			if (v != self && v.Olimar == self.Olimar && pos:Distance(v:GetPos()) <= 10) then
				local phys = self:GetPhysicsObject();
				if (phys:IsValid()) then
					local dir = (pos - v:GetPos());
					dir = (dir + Vector(0, 0, 10));
					phys:ApplyForceCenter((dir * 35));
				end
			end
		end
	end
	//Moving
	if (ValidEntity(self.Olimar)) then
		if (self.CanMove) then
			local opos = pos;
			local dist;
			if (ValidEntity(self.Olimar)) then
				opos = self.Olimar:GetPos();
				dist = pos:Distance(opos);
			end
			if (dist >= 1000) then
				if (!self.Victim) then
					self:Disband();
				end
			end
			if (CurTime() >= self.LastObHop) then
				self.LastObHop = (CurTime() + 1.5);
				local tbl = {};
				for k, v in pairs(ents.FindByClass("pikmin")) do
					tbl[(#tbl + 1)] = v;
				end
				for k, v in pairs(ents.FindByClass("pikmin_model")) do
					tbl[(#tbl + 1)] = v;
				end
				//See if we should hop over an obstacle
				local tr = util.QuickTrace((self:GetPos() + Vector(0, 0, 4)), (self:GetForward() * 20), tbl);
				if (tr.HitWorld) then
					local phys = self:GetPhysicsObject();
					if (phys:IsValid()) then
						local force = 1750;
						if (self:GetPikType() == "purple") then
							force = 2000;
						end
						phys:ApplyForceCenter((self:GetUp() * force));
					end
				end
			end
			if (CurTime() >= self.LastHop) then
				if (ValidEntity(self.AtkTarget)) then
					opos = self.AtkTarget:GetPos();
					dist = 200;
				end
				if (self:IsOnFire() && self:GetPikType() != "red") then
					opos = (self:GetPos() + Vector(math.Rand(-1000, 1000), math.Rand(-1000, 1000), 0));
					dist = 200;
				end
				if (dist >= 200) then
					if (vel:Length() <= 250) then
						self.LastHop = (CurTime() + .1);
						local force = 700;
						local zforce = 325;
						local lvl = self:GetPikLevel();
						local dir = (opos - pos);
						if (self.PikClr == "purple") then
							force = 475;
							zforce = 425;
						end
						if (self.PikClr == "white") then
							force = 1250;
						end
						dir = (dir * 1.5);
						local vec = Vector(dir.x, dir.y, 0);
						if (self:WaterLevel() >= 1) then
							vec = dir;
						end
						self:GetPhysicsObject():ApplyForceCenter(((vec:GetNormal() * (force + (lvl * 50))) + Vector(0, 0, zforce)));
					end
				end
			end
		end
	end
	//On fire
	if (self:IsOnFire()) then
		if (self:GetPikType() == "red") then
			self:Extinguish();
		else
			self:SetAnim("onfire");
		end
	end
	//Water
	if (self:WaterLevel() >= 1) then //We are in water
		local phys = self:GetPhysicsObject();
		if (self:IsOnFire()) then
			self:Extinguish();
		end
		if (self:GetPikType() == "blue") then //We're ok
			if (!self.Attacking) then
				self:SetAnim("swimming");
			end
		else //We're screwed
			if (self.Attacking) then
				local quickpos = (self:GetPos() + Vector(0, 0, 7.5));
				self.Attacking = false;
				self.AtkTarget = nil;
				self:SetParent();
				self:SetPos(quickpos);
				self.Victim = nil;
			end
			self:SetAnim("drowning");
			self.CanMove = false;
			if (phys:IsValid()) then
				local push = 12;
				if (self:GetPikType() == "purple") then
					push = 8;
				elseif (self:GetPikType() == "white") then
					push = 22;
				end
				phys:ApplyForceCenter(Vector(0, 0, push));
			end
			if (!self.DrowningTimeBool) then
				self.DrowningTimeBool = true;
				self.DrownTime = (CurTime() + 5);
			end
			if (CurTime() >= self.DrownTime) then
				self:Die();
			end
			if (self.PlayDrownSound) then
				 self.PlayDrownSound = false;
				 self.DrownSound:Play();
			end
		end
	else
		if (self.DrowningTimeBool) then
			self.DrowningTimeBool = false;
		end
		if (!self.PlayDrownSound) then
			self.PlayDrownSound = true;
			self.DrownSound:Stop();
			self.CanMove = true;
		end
	end
	//Attacking
	if (self.Attacking) then
		if (ValidEntity(self.Victim)) then
			if (CurTime() >= self.NextAttack) then
				self.NextAttack = (CurTime() + .76);
				local dmg = (self.PikDmg + self:GetPikLevel());
				if ((self.Victim:Health() - dmg) <= 0) then
					for k, v in pairs(ents.FindByClass("pikmin")) do
						if (v.Victim == self.Victim && v != self) then
							local quickpos = (v:GetPos() + Vector(0, 0, 7.5));
							v.Attacking = false;
							v.AtkTarget = nil;
							v:SetParent();
							v:SetPos(quickpos);
							v.Victim = nil;
							if (v.Dismissed) then
								v:SetAnim("dismissed");
							end
						end
					end
					local rnd = math.random(1, 3);
					if (rnd == 1) then
						local nec = ents.Create("pikmin_nectar");
						nec:SetPos((self.Victim:GetPos() + Vector(0, 0, 50)));
						nec:Spawn();
						local phys = nec:GetPhysicsObject();
						if (phys:IsValid()) then
							phys:ApplyForceCenter(Vector(0, 0, 5000));
							phys:AddAngleVelocity(Angle(math.random(10, 100), math.random(10, 100), math.random(10, 100)));
						end
					end
					self.Victim:TakeDamage(dmg, self.Olimar, self);
					local quickpos = (self:GetPos() + Vector(0, 0, 7.5));
					self.Attacking = false;
					self.AtkTarget = nil;
					self:SetParent();
					self:SetPos(quickpos);
					self.Victim = nil;
					if (self.Dismissed) then
						self:SetAnim("dismissed");
					end
				else
					self.Victim:TakeDamage(dmg, self.Olimar, self);
				end
				self:EmitSound("pikmin/hit.wav", 100, math.random(98, 105));
			end
		end
	end
	self:NextThink(CurTime());
	return true;
end

function ENT:PhysicsCollide(data, phys)
	if (self.JustThrown && data.HitEntity:IsWorld()) then
		self.ShouldSpin = false;
	end
end

function ENT:StartTouch(thing)
	if (!self.Attacking) then
		if (thing:IsPlayer()) then
			if (self.Dismissed) then
				self:Join(thing);
			elseif (thing != self.Olimar) then
				self:LatchOn(thing);
			end
		elseif (thing:IsNPC() && thing:GetClass() != "npc_rollermine") then
			self:LatchOn(thing);
		end
		if (thing:GetClass() == "prop_combine_ball") then
			if (ValidEntity(self) && !self.Dissolving) then
				self:EmitSound("pikmin/pikmin_die.wav", 100, math.random(95, 110));
				local mdl = self:CreatePikRagdoll(true);
				local dissolve = ents.Create("env_entity_dissolver");
				dissolve:SetPos(mdl:GetPos());
				mdl:SetName(tostring(mdl));
				dissolve:SetKeyValue("target", mdl:GetName());
				dissolve:SetKeyValue("dissolvetype", "0");
				dissolve:Spawn();
				dissolve:Fire("Dissolve", "", 0);
				dissolve:Fire("kill", "", 1);
				dissolve:EmitSound(Sound("NPC_CombineBall.KillImpact"));
				mdl:Fire("sethealth", "0", 0);
				mdl.Dissolving = true;
			end
		end
	end
end

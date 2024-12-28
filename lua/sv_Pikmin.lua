AddCSLuaFile("cl_Pikmin.lua");
AddCSLuaFile("autorun/client/cl_Pikmin-autorun.lua");

for k, v in pairs(file.Find("../sound/pikmin/*")) do
	resource.AddFile("sound/pikmin/" .. v);
	Sound(v); //Precache all sounds
end

for k, v in pairs(file.Find("../models/pikmin/*")) do
	resource.AddFile("models/pikmin/" .. v);
	util.PrecacheModel("pikmin/" .. v); //Precache all sounds
end

for k, v in pairs(file.Find("../models/weapons/v_olimar.*")) do
	resource.AddFile("models/weapons/" .. v);
	util.PrecacheModel("weapons/" .. v); //Precache all sounds
end
for k, v in pairs(file.Find("../models/weapons/w_olimar.*")) do
	resource.AddFile("models/weapons/" .. v);
	util.PrecacheModel("weapons/" .. v); //Precache all sounds
end

for k, v in pairs(file.Find("../materials/models/pikmin/*")) do
	resource.AddFile("materials/models/pikmin/" .. v);
end

for k, v in pairs(file.Find("../materials/pikmin/*")) do
	resource.AddFile("materials/pikmin/" .. v);
end

resource.AddFile("materials/VGUI/entities/pikmin.vtf");
resource.AddFile("materials/VGUI/entities/pikmin.vmt");

resource.AddFile("materials/weapons/pikmincommand.vtf");
resource.AddFile("materials/weapons/pikmincommand.vmt");

local function DontToolMe(ply, tr, tool)
	if (ValidEntity(tr.Entity) && tr.Entity:GetClass() == "pikmin_onion" || tr.Entity:GetClass() == "pikmin" || tr.Entity:GetClass() == "pikmin_model") then
		if (tool == "duplicator") then
			return false;
		end
	end
	return true;
end
hook.Add("CanTool", "DontDupeOnions", DontToolMe);

local function DontPickMeUp(ply, ent)
	if (ValidEntity(ent) && ent:GetClass() == "pikmin_onion") then
		return false;
	end
	return true;
end
hook.Add("GravGunPickupAllowed", "DontPickupOnions", DontPickMeUp);

local function PikGravPunt(ply, ent)
	if (ent:GetClass() == "pikmin") then
		ent:SetAnim("thrown");
		ply:EmitSound("pikmin/throw.wav");
		ent.JustThrown = true; //Going to check if they should follow us while in the air...
		ent.ShouldSpin = true;
		ent.CanMove = false;
		timer.Simple(2.5,
			function()
				if (ValidEntity(ent)) then
					ent.CanMove = true;
					ent.JustThrown = false;
				end
			end);
	end
end
hook.Add("GravGunPunt", "ThrowAnimOnPunt", PikGravPunt);

local function PikDontHitPlayer(ply, thing) //Pikmin are chargin' me!
	if (thing:GetClass() == "pikmin") then
		return false;
	end
	return true;
end
hook.Add("PlayerShouldTakeDamage", "OMGPIKMINDONTHURTMEH", PikDontHitPlayer);

local function PikEntityRemoved(ent)
	if (ent:IsNPC()) then
		for k, v in pairs(ents.FindByClass("pikmin")) do
			if (v.Attacking && v.Victim == ent) then
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
	end
end
hook.Add("EntityRemoved", "PikEntityRemoved", PikEntityRemoved);

//Template for code block comments
/*****************************************

******************************************/


AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include('shared.lua');


/*****************************************
Initialize and spawn functions
Gotta have these, or we have no SEnt!
******************************************/

function ENT:Initialize()
	self:SetModel("models/props_vehicles/carparts_wheel01a.mdl");
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:SetMaterial("models/shiny");
	self:SetColor(255, 200, 0, 255)
	local phys = self:GetPhysicsObject();
	if (phys:IsValid()) then
		phys:Wake();
	end
end

function ENT:SpawnFunction(ply, tr)
	if (!tr.Hit) then
		return;
	end
	local SpawnPos = (tr.HitPos + (tr.HitNormal * 16));
	local ent = ents.Create("pikmin_nectar");
	ent:SetPos(SpawnPos);
	ent:Spawn();
	ent:Activate();
	undo.Create("Nectar");
		undo.AddEntity(ent);
		undo.SetPlayer(ply);
	undo.Finish();
end

function ENT:StartTouch(thing)
	if (thing:GetClass() == "pikmin" && thing:GetPikLevel() < 3) then
		if (!thing.Attacking) then
			timer.Simple(4.5,
				function()
					if (ValidEntity(self)) then
						for k, v in pairs(ents.FindByClass("pikmin")) do
							if (v:GetParent() == self) then
								v:SetParent();
								v:SetPos((self:GetPos() + Vector(math.Rand(-20, 20), math.Rand(-20, 20), 10)));
								v:SetPikLevel(3);
								v:EmitSound("pikmin/level.wav");
								v.Sucking = false;
								if (v.Dismissed) then
									v:SetAnim("dismissed");
								end
							end
						end
						self:Remove();
					end
				end);
			thing:EmitSound("pikmin/suck.wav");
			thing:SetParent(self);
			thing.Sucking = true;
			timer.Simple(2,
				function()
					if (ValidEntity(thing) && ValidEntity(self)) then
						thing:SetParent();
						thing:SetPos((self:GetPos() + Vector(math.Rand(-20, 20), math.Rand(-20, 20), 10)));
						thing:SetPikLevel(3);
						thing:EmitSound("pikmin/level.wav");
						thing.Sucking = false;
						if (thing.Dismissed) then
							thing:SetAnim("dismissed");
						end
					end
				end);
		end
	end
end

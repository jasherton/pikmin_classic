include('shared.lua')

local dismisssprite = Material("pikmin/disband_light");

function ENT:Initialize()
end

function ENT:Draw()
	self:DrawModel();
	if (self:GetNetworkedBool("Dismissed", false)) then
		local lvl = self:GetNetworkedInt("Level", 2);
		local pos, ang;
		if (lvl == 1) then
			pos, ang = self:GetBonePosition(self:LookupBone("piki_leaf"));
		end
		if (lvl == 2) then
			pos, ang = self:GetBonePosition(self:LookupBone("piki_bud"));
		end
		if (lvl == 3) then
			pos, ang = self:GetBonePosition(self:LookupBone("piki_flower"));
		end
		render.SetMaterial(dismisssprite);
		local clr = self:GetNetworkedString("Color");
		if (clr == "red") then
			clr = Color(255, 150, 150, 200);
		elseif (clr == "yellow") then
			clr = Color(255, 255, 150, 200);
		elseif (clr == "blue") then
			clr = Color(150, 150, 255, 200);
		elseif (clr == "purple") then
			clr = Color(225, 150, 225, 200);
		elseif (clr == "white") then
			clr = Color(255, 255, 255, 200);
		end
		render.DrawSprite(pos, 28, 28, clr);
	end
end

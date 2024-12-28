local function SpawnPikminMenu(ply, cmd, args)
	local w, h = surface.ScreenWidth(), surface.ScreenHeight();
	local frame = vgui.Create("DFrame");
	frame:SetSize((w * .7), (h * .275));
	
	local W = frame:GetWide();
	local H = frame:GetTall();
	
	frame:SetPos(((w * .5) - (W * .5)), (h * .125));
	frame:SetVisible(true);
	frame:MakePopup();
	frame:SetTitle("Pikmin Spawn Menu");
	//function frame:Paint()
	//	draw.RoundedBox(3, 0, 0, W, H, Color(25, 100, 25, 250));
	//	return true;
	//end
	
	local piktbl = {
		"red",
		"yellow",
		"blue",
		"purple",
		"white"
	};
	
	local inc = 0;
	
	for i = 1, #piktbl do //lets do this neatly...
		local btn = vgui.Create("DModelPanel", frame);
		btn:SetPos(((W * .05) + inc), (H * .2));
		btn:SetWide((W * .175));
		btn:SetTall((H * .55));
		btn:SetModel("models/pikmin/pikmin_" ..  piktbl[i] .. "1.mdl");
		btn:SetLookAt(Vector(0, 0, 25));
		btn:SetFOV(56);
		btn:SetAmbientLight(Color(80, 80, 80));
		btn:SetCamPos(Vector(60, 15, 40));
		btn:SetAnimSpeed(math.Rand(.9, 1.2));
		btn:SetAnimated(true);
		function btn:LayoutEntity(ent)
			self:RunAnimation();
		end
		function btn:Think()
			local anim = btn.Entity:LookupSequence("dismissed");
			btn.Entity:ResetSequence(anim);
		end 
		function btn:DoClick()
			RunConsoleCommand("pikmin_create", piktbl[i])
		end
		inc = (inc + (28 + (w * .1)));
	end
	
	local rand = vgui.Create("DButton", frame);
	rand:SetPos((W * .1), (H * .8));
	rand:SetWide((W * .8));
	rand:SetTall((H * .1));
	rand:SetText("Random!");
	rand.DoClick = function()
						RunConsoleCommand("pikmin_create", "random");
					end
					
	frame:SizeToContents();
end
concommand.Add("pikmin_menu", SpawnPikminMenu);

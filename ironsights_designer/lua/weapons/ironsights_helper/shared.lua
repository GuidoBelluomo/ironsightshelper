SWEP.Author = "Kurochi"
SWEP.Category = "Kurochi's Ironsights Helper"
SWEP.PrintName = "Kurochi's Ironsights Helper"
SWEP.Instructions = "Check the workshop page."
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = false
SWEP.Primary.Automatic = true;

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

SWEP.OffsetAngle = Angle(0, 0, 0)
SWEP.OffsetVector = Vector(0, 0, 0)

SWEP.EditMode = false;
SWEP.SelectedPos = 0;
SWEP.Aiming = false;
SWEP.Steps = {0.001, 0.01, 0.1, 1, 5, 10}
SWEP.StepIndex = 4;
SWEP.IronsightsFOV = nil;
SWEP.DefaultIronsightsFOV = nil;

function SWEP:Ammo1()
	return 999;
end

SWEP.LastReload = CurTime();
function SWEP:Reload()
	if (SERVER) then
		if (CurTime() < self.LastReload + 0.5) then
			return;
		end
		self.LastReload = CurTime();

		if (game.SinglePlayer()) then
			self:CallOnClient("Reload");
		end
	else

	end
	self.EditMode = !self.EditMode;
	if (self.EditMode) then
		self.Aiming = false;
		self.BobScale = 0;
		self.SwayScale = 0;
	else
		self.BobScale = 1;
		self.SwayScale = 1;
	end
end

SWEP.LastShot = CurTime();
function SWEP:PrimaryAttack()
	if (SERVER) then
		if (!self.EditMode) then
			if (CurTime() >= self.LastShot + 0.25) then
				self:ShootBullet(0, 1, 0);
				self.LastShot = CurTime();
				self.Weapon:EmitSound( "Weapon_pistol.Single" )
				self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			end
		end
	end
end

function SWEP:SecondaryAttack()
	if (SERVER) then
		if (game.SinglePlayer()) then
			self:CallOnClient("SecondaryAttack");
		end
	else
		self.Aiming = !self.Aiming;
	end
end

local GM = gmod.GetGamemode();
if (CLIENT) then
	local KeyPresses = {}
	local KeyDelay = 0.1
	function KeyDown(key, delay)
		delay = delay or KeyDelay;
		if (!KeyPresses[key]) then
			KeyPresses[key] = -delay;
		end

		if (CurTime() >= KeyPresses[key] + delay and input.IsKeyDown(key)) then
			KeyPresses[key] = CurTime()
			return true;
		end
		return false;
	end

	function SWEP:DrawHUD()
		if (!self.IronsightsFOV) then
			return;
		end

		local hudText = "[Toggle with Reload] Edit Mode " .. (self.EditMode and "ON" or "OFF") .. "\n[Insert] Use model from last spawned entity\n[Keypad Space] Copy to clipboard\n-\n"
		if (!self.EditMode) then
			hudText = hudText .. "Primary Fire: Shoot\nSecondary Fire: Aim (" .. (self.Aiming and "ON" or "OFF") .. ")"
		else
			hudText = hudText .. "[Toggle with Flashlight] Flip Model " .. (self.ViewModelFlip and "ON" or "OFF") .. "\n\nCurrent Step: " .. self.Steps[self.StepIndex] .. "\n[Up] Increment Value\n[Down] Decrement Value\n\n[Left] Previous value\n[Right] Next Value\n[Page Up] Top Value\n[Page Down] Bottom Value\n\n[Numpad -] Decrease Step\n[Numpad +] Increase Step\n\n[Delete] Reset"
		end
		surface.SetFont("CloseCaption_Normal")
		local w, h = surface.GetTextSize(hudText)
		draw.RoundedBox(8, 10, 10, w + 20, h + 20, Color(0, 0, 0, 200))
		draw.DrawText(hudText, "CloseCaption_Normal", 20, 20)

		if (self.EditMode) then
			local x, y = 30 + w + 10, 10;

			local SelectedPos = self.SelectedPos;
			local offsetX = (self.SelectedPos == 0 and "<colour=green>" or "") .. math.Round(self.OffsetVector.x, 3) .. (self.SelectedPos == 0 and "</colour>" or "");
			local offsetY = (self.SelectedPos == 1 and "<colour=green>" or "") .. math.Round(self.OffsetVector.y, 3) .. (self.SelectedPos == 1 and "</colour>" or "");
			local offsetZ = (self.SelectedPos == 2 and "<colour=green>" or "") .. math.Round(self.OffsetVector.z, 3) .. (self.SelectedPos == 2 and "</colour>" or "");
			local angleP = (self.SelectedPos == 3 and "<colour=green>" or "") .. math.Round(self.OffsetAngle.p, 3) .. (self.SelectedPos == 3 and "</colour>" or "");
			local angleY = (self.SelectedPos == 4 and "<colour=green>" or "") .. math.Round(self.OffsetAngle.y, 3) .. (self.SelectedPos == 4 and "</colour>" or "");
			local angleR = (self.SelectedPos == 5 and "<colour=green>" or "") .. math.Round(self.OffsetAngle.r, 3) .. (self.SelectedPos == 5 and "</colour>" or "");
			local fov = (self.SelectedPos == 6 and "<colour=green>" or "") .. math.Round(self.IronsightsFOV) .. (self.SelectedPos == 6 and "</colour>" or "");

			hudText = "<font=CloseCaption_Normal>Offset Vector:\t(" .. offsetX .. ",\t" .. offsetY .. ",\t" .. offsetZ .. ")" .. "\n"
			hudText = hudText .. "Offset Angle:\t(" .. angleP .. ",\t" .. angleY .. ",\t" .. angleR .. ")\n"
			hudText = hudText .. "Ironsights FOV:\t" .. fov .. "</font>"
			hudText = markup.Parse(hudText)
			w, h = hudText:Size()
			draw.RoundedBox(8, x, y, w + 20, h + 20, Color(0, 0, 0, 200))
			hudText:Draw(x + 10, y + 10, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	function SWEP:OwnerChanged()
		self.IronsightsFOV = LocalPlayer():GetFOV()
		self.DefaultIronsightsFOV = self.IronsightsFOV;
	end

	function SWEP:Think()
		if (!self.IronsightsFOV) then
			return;
		end

		if (KeyDown(KEY_SPACE, 0.2)) then
			SetClipboardText("Vector(" .. self.OffsetVector.x .. ", " .. self.OffsetVector.y .. ", " .. self.OffsetVector.z .. ") Angle(" .. self.OffsetAngle.p .. ", " .. self.OffsetAngle.y .. ", " .. self.OffsetAngle.r .. ")")
			LocalPlayer():ChatPrint("Copied values to clipboard! You can now paste it anywhere you want. Value may look weird, don't worry about it, it works.")
			return;
		elseif (KeyDown(KEY_INSERT, 0.2)) then
			local ent = ents.GetAll()[#ents.GetAll()];
			if (IsValid(ent)) then
				local model = ent:GetModel()
				if (util.IsValidModel(model)) then
					self.ViewModel = model
				else
					LocalPlayer():ChatPrint("Invalid model!");
				end
			else
				LocalPlayer():ChatPrint("Invalid entity!");
			end
		end

		if (self.EditMode) then
			local modifier = 0;
			local step = self.Steps[self.StepIndex]

			if (KeyDown(KEY_DELETE, 0.2)) then
				self.OffsetVector = Vector(0, 0, 0)
				self.OffsetAngle = Angle(0, 0, 0)
				self.IronsightsFOV = self.DefaultIronsightsFOV
				return;
			end

			if (KeyDown(KEY_UP)) then
				modifier = step;
			elseif (KeyDown(KEY_DOWN)) then
				modifier = -step;
			end

			if (KeyDown(KEY_LEFT, 0.2)) then
				self.SelectedPos = math.Clamp(self.SelectedPos - 1, 0, 6)
				modifier = 0;
			elseif (KeyDown(KEY_RIGHT, 0.2)) then
				self.SelectedPos = math.Clamp(self.SelectedPos + 1, 0, 6)
				modifier = 0;
			elseif (KeyDown(KEY_PAGEDOWN, 0.2)) then
				self.SelectedPos = (math.Clamp(self.SelectedPos + 3, 0, 6));
				modifier = 0;
			elseif (KeyDown(KEY_PAGEUP, 0.2)) then
				self.SelectedPos = (math.Clamp(self.SelectedPos - 3, 0, 6));
				modifier = 0;
			end

			if (KeyDown(KEY_PAD_MINUS, 0.2)) then
				self.StepIndex = math.Clamp(self.StepIndex - 1, 1, #self.Steps)
				modifier = 0;
			elseif (KeyDown(KEY_PAD_PLUS, 0.2)) then
				self.StepIndex = math.Clamp(self.StepIndex + 1, 1, #self.Steps)
				modifier = 0;
			end

			local selectedPos = self.SelectedPos
			if (selectedPos == 0) then
				self.OffsetVector.x = self.OffsetVector.x + modifier;
			elseif (selectedPos == 1) then
				self.OffsetVector.y = self.OffsetVector.y + modifier;
			elseif (selectedPos == 2) then
				self.OffsetVector.z = self.OffsetVector.z + modifier;
			elseif (selectedPos == 3) then
				self.OffsetAngle.p = self.OffsetAngle.p + modifier;
			elseif (selectedPos == 4) then
				self.OffsetAngle.y = self.OffsetAngle.y + modifier;
			elseif (selectedPos == 5) then
				self.OffsetAngle.r = self.OffsetAngle.r + modifier;
			elseif (selectedPos == 6) then
				self.IronsightsFOV = math.max(0, self.IronsightsFOV + modifier);
			end
		end
	end

	function SWEP:GetViewModelPosition(pos, ang)
		if (self.EditMode or self.Aiming) then
			local OffsetVector = self.OffsetVector
			local OffsetAngle = self.OffsetAngle
			
			ang:RotateAroundAxis( ang:Right(), OffsetAngle.x )
			ang:RotateAroundAxis( ang:Up(), OffsetAngle.y )
			ang:RotateAroundAxis( ang:Forward(), OffsetAngle.z )

			pos = pos + OffsetVector.x * ang:Right()
			pos = pos + OffsetVector.y * ang:Forward()
			pos = pos + OffsetVector.z * ang:Up()
			
			return pos, ang
		end
	end

	function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
		vm:SetModel(self.ViewModel)
	end

	function SWEP:TranslateFOV(fov)
		if (self.IronsightsFOV and (self.Aiming or self.EditMode)) then
			fov = self.IronsightsFOV
		end
		return fov;
	end

	function draw.Circle( x, y, radius, seg )
		local cir = {}

		table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( i / seg ) * -360 )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end

		local a = math.rad( 0 ) -- This is needed for non absolute segment counts
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		surface.DrawPoly( cir )
	end

	function SWEP:DoDrawCrosshair(x, y)
		draw.NoTexture()
		surface.SetDrawColor( 0, 0, 0, 255 )
		draw.Circle(x, y, 2, 8);
		surface.SetDrawColor( 255, 255, 255, 255 )
		draw.Circle(x, y, 1, 8);
		return true;
	end
else
	function GM:PlayerPostThink(player)
		local SWEP = player:GetActiveWeapon();
		if (SWEP:GetClass() == "ironsights_helper" and player:GetMoveType() != MOVETYPE_NOCLIP) then
			if (SWEP.EditMode) then
				if (player:GetMoveType() != MOVETYPE_NONE) then
					player:SetMoveType(MOVETYPE_NONE)
				end
			else
				if (player:GetMoveType() != MOVETYPE_WALK) then
					player:SetMoveType(MOVETYPE_WALK)
				end
			end
		end
	end

	function  GM:PlayerSwitchFlashlight(player, enabled)
		local SWEP = player:GetActiveWeapon();
		if (SWEP:GetClass() == "ironsights_helper") then
			player:SendLua('SWEP = LocalPlayer():GetActiveWeapon() if (SWEP:GetClass() == "ironsights_helper" and SWEP.EditMode) then SWEP.ViewModelFlip = !SWEP.ViewModelFlip end')
		end

		return !SWEP.EditMode;
	end
end
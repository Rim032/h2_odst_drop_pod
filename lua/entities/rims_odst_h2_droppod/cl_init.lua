include("shared.lua")

game.AddParticles("particles/h2_odst_droppod_effects.pcf")
PrecacheParticleSystem("h2_odst_droppod_thrust_main")
PrecacheParticleSystem("h2_odst_droppod_air_main")

surface.CreateFont("DP_Font", {
	font = "Arial",
	extended = false,
	size = ScrW()/96,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

function ENT:Draw()
	self:DrawModel()

	if self:GetNWBool("droppod_thrust_is_on") then
		local thrust_emitter = ParticleEmitter(self:GetPos())
		if thrust_emitter == nil then return end

		local v_offset = self:GetAttachment(1).Pos
		local v_normal = self:GetUp()
		v_offset = v_offset + v_normal * 5

		local thrust_particle = thrust_emitter:Add("effects/softglow.vmt", v_offset)
		if thrust_particle == nil then return end

		thrust_particle:SetVelocity( v_normal * math.Rand(1500,2000) + self:GetVelocity())
		thrust_particle:SetLifeTime(0)
		thrust_particle:SetDieTime(0.1)
		thrust_particle:SetStartAlpha(255)
		thrust_particle:SetEndAlpha(0)
		thrust_particle:SetStartSize(math.Rand(45,55))
		thrust_particle:SetEndSize(math.Rand(0,10))
		thrust_particle:SetRoll(math.Rand(-1,1) * 100)
		thrust_particle:SetColor(0, 76, 255)

		render.SetMaterial(Material("sprites/light_glow02_add"))
		render.DrawSprite(self:GetAttachment(1).Pos, 384, 180, Color(0, 76, 255))
	end
end

local pod_fuel = 3
local pod_stage = 0
local pod_health = 100
local pod_ent = nil

--[[net.Receive("rh2_odst_pod_THRUST_ON", function(len, ply)
	local thruster_particle = pod_ent:CreateParticleEffect("h2_odst_droppod_thrust_main", 1)
	timer.Simple(0.5, function() thruster_particle:StopEmissionAndDestroyImmediately() end)
end)]]

net.Receive("rh2_odst_pod_SEND_INFO", function(len, ply)
	pod_health = net.ReadInt(8)
	pod_stage = net.ReadInt(4)
	pod_fuel = net.ReadInt(8)
	pod_ent = net.ReadEntity()

	return pod_health, pod_stage, pod_fuel, pod_ent
end)

net.Receive("rh2_odst_pod_LANDED", function(len, ply)
	util.ScreenShake(Vector(0, 0, 0), 8, 8, 1, 250)
end)

net.Receive("rh2_odst_pod_AIRBREAK_ON", function(len, ply)
	util.ScreenShake(Vector(0, 0, 0), 6, 6, 3, 100)

	--[[local heat_particle = pod_ent:CreateParticleEffect("h2_odst_droppod_air_main", 1)
	timer.Simple(1, function() heat_particle:StopEmissionAndDestroyImmediately() end)]]
end)


hook.Add("HUDPaint", "rh2_droppod_hud_hook", function()
	if LocalPlayer():GetVehicle() == NULL or LocalPlayer():GetVehicle():GetParent() == NULL then return end
	if LocalPlayer():GetVehicle():GetParent():GetClass() ~= "rims_odst_h2_droppod" then return end

	draw.RoundedBox(0, ScrW()/2.31, ScrH()-ScrH()/8.44, ScrW()/7.5, ScrH()/24, Color(25, 25, 25, 200))
	draw.RoundedBox(0, ScrW()/2-ScrW()/15.48, ScrH()-ScrH()/8.71, pod_fuel * ScrW()/23.23, 37, Color(252, 160, 98, 200))

	draw.RoundedBox(0, ScrW()/2.31, ScrH()-ScrH()/6.07, ScrW()/7.5, ScrH()/24, Color(25, 25, 25, 200))
	draw.RoundedBox(0, ScrW()/2-ScrW()/15.48, ScrH()-ScrH()/6.27, pod_health * ScrW()/774.2, 37, Color(152, 242, 114, 200))

	draw.DrawText(("Thruster Fuel: "..pod_fuel.."L"), "DP_Font", ScrW()/2,  ScrH()/1.12, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --965
	draw.DrawText(("Drop Pod Strength: "..pod_health), "DP_Font", ScrW()/2,  ScrH()/1.18, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --915
	draw.DrawText(("Drop Pod Stage: "..pod_stage), "DP_Font", ScrW()/2,  ScrH()/1.08, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --1000
end)

hook.Add( "CalcView", "MyCalcView", function(ply, pos, angles, fov)
	if LocalPlayer():GetVehicle() == NULL or LocalPlayer():GetVehicle():GetParent() == NULL then return end
	if LocalPlayer():GetVehicle():GetParent():GetClass() ~= "rims_odst_h2_droppod" then return end

	local view = {
		origin = pos - (angles:Forward() * 200),
		angles = angles,
		fov = fov,
		drawviewer = true
	}

	return view
end)

include("shared.lua")
include("autorun/server/h2_droppod_manage.lua")

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
end

local thruster_dlightA = DynamicLight(LocalPlayer():EntIndex())
local thruster_dlightB = DynamicLight(LocalPlayer():EntIndex())

local pod_fuel = 0
local pod_stage = 0
local pod_health = 100

local pod_ply = LocalPlayer()
local pod_ent = nil

net.Receive("rh2_odst_pod_THRUST_ON", function(len, ply)
	pod_ent = net.ReadEntity()

	if (thruster_dlightA) then
		thruster_dlightA.pos = pod_ent:GetAttachment(1).Pos
		thruster_dlightA.r = 25
		thruster_dlightA.g = 25
		thruster_dlightA.b = 255
		thruster_dlightA.brightness = 8
		thruster_dlightA.Decay = 200
		thruster_dlightA.Size = 256
		thruster_dlightA.DieTime = CurTime() + 8
	end

	if (thruster_dlightB) then
		thruster_dlightB.pos = pod_ent:GetAttachment(1).Pos
		thruster_dlightB.r = 25
		thruster_dlightB.g = 25
		thruster_dlightB.b = 255
		thruster_dlightB.brightness = 8
		thruster_dlightB.Decay = 200
		thruster_dlightB.Size = 256
		thruster_dlightB.DieTime = CurTime() + 8
	end

	--render.DrawSprite(pod_vector + Vector(0, 0, 300), 512, 512, Color(0, 0, 100))
	return pod_vector
end)

net.Receive("rh2_odst_pod_SEND_FUEL", function(len, ply)
	pod_fuel = net.ReadInt(8)
	return pod_fuel
end)

net.Receive("rh2_odst_pod_SEND_PLY", function(len, ply)
	pod_ply = net.ReadEntity()
	pod_health = net.ReadInt(8)
	pod_stage = net.ReadInt(4)

	return pod_ply, pod_health, pod_stage
end)

net.Receive("rh2_odst_pod_LANDED", function(len, ply)
	util.ScreenShake(Vector(0, 0, 0), 8, 8, 1, 250)
end)

net.Receive("rh2_odst_pod_AIRBREAK_ON", function(len, ply)
	util.ScreenShake(Vector(0, 0, 0), 2, 2, 2, 100)
end)


hook.Add("HUDPaint", "rh2_droppod_hud_hook", function()
	if pod_fuel == nil then pod_fuel = 3 return end
	if LocalPlayer():GetNWBool("droppod_is_occupied") == false then pod_fuel = 3 return end
	if pod_ply ~= LocalPlayer() then pod_fuel = 3 return end

	draw.RoundedBox(0, ScrW()/2.31, ScrH()-ScrH()/8.44, ScrW()/7.5, ScrH()/24, Color(25, 25, 25, 200))
	draw.RoundedBox(0, ScrW()/2-ScrW()/15.48, ScrH()-ScrH()/8.71, pod_fuel * ScrW()/23.23, 37, Color(252, 160, 98, 200))

	draw.RoundedBox(0, ScrW()/2.31, ScrH()-ScrH()/6.07, ScrW()/7.5, ScrH()/24, Color(25, 25, 25, 200))
	draw.RoundedBox(0, ScrW()/2-ScrW()/15.48, ScrH()-ScrH()/6.27, pod_health * ScrW()/774.2, 37, Color(152, 242, 114, 200))

	draw.DrawText(("Thruster Fuel: "..pod_fuel.."L"), "DP_Font", ScrW()/2,  ScrH()/1.12, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --965
	draw.DrawText(("Drop Pod Strength: "..pod_health), "DP_Font", ScrW()/2,  ScrH()/1.18, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --915
	draw.DrawText(("Drop Pod Stage: "..pod_stage), "DP_Font", ScrW()/2,  ScrH()/1.08, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER) --1000
end)

hook.Add( "CalcView", "MyCalcView", function(ply, pos, angles, fov)
	if LocalPlayer():GetNWBool("droppod_is_occupied") == false then return end
	if pod_ply ~= LocalPlayer() then return end
	--if !pod_ply:GetVehicle():GetThirdPersonMode() then return end

	local view = {
		origin = pos - (angles:Forward() * 200),
		angles = angles,
		fov = fov,
		drawviewer = true
	}

	return view
end)
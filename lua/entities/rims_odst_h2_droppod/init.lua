AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("rh2_odst_pod_LAUNCH")
--util.AddNetworkString("rh2_odst_pod_THRUST_ON")
util.AddNetworkString("rh2_odst_pod_AIRBREAK_ON")
util.AddNetworkString("rh2_odst_pod_LANDED")
util.AddNetworkString("rh2_odst_pod_SEND_INFO")

local mENT = FindMetaTable("Entity")

game.AddParticles("particles/h2_odst_droppod_effects.pcf")
PrecacheParticleSystem("h2_odst_droppod_thrust_main")
PrecacheParticleSystem("h2_odst_droppod_air_main")

function ENT:Initialize()
	self:SetModel("models/rim/h2_odst_pod_01.mdl")
	self:PhysicsInit(MOVETYPE_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:GetPhysicsObject():EnableGravity(false)
	self:GetPhysicsObject():EnableMotion(false)
	
	if self:GetPhysicsObject():IsValid() then
		self:GetPhysicsObject():Wake()
	else
		print("[H2DP] Drop Pod physics failed.")
	end

	self.pod_seat = ents.Create("prop_vehicle_prisoner_pod")
	self.pod_seat:SetModel("models/Nova/airboat_seat.mdl") 
	self.pod_seat:SetPos(self:GetPos() + Vector(-5, 0, 50)) --x=-15
	self.pod_seat:SetAngles(self:GetAngles() + Angle(0, 90, 0))
	self.pod_seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	self.pod_seat:SetKeyValue("limitview", 0)
	self.pod_seat:SetCameraDistance(5) 
	self.pod_seat:SetThirdPersonMode(true)
	self.pod_seat:SetParent(self)
	self.pod_seat:Spawn()
	self.pod_seat:Activate()
	self.pod_seat:SetRenderMode(RENDERMODE_NONE)

	self.pod_fuel = 3
	self.airbreak_on = false
	self.pod_landed = false
	self.pod_plp_given = false
	self.pod_health = 100
	self.exploded = false
	self.door_opened = false
	self.pod_stage = 0
	self.launch_speed_degraded = false
	self.thruster_being_used = false
	self.max_velocity_turn = 25

	self:GetPhysicsObject():SetMass(200)
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if (!tr.Hit) then return end
	local ent_pos = tr.HitPos + tr.HitNormal

	local dp_ent = ents.Create("rims_odst_h2_droppod")
	dp_ent:SetPos(ent_pos)
	dp_ent:Spawn()
	dp_ent:Activate()
	dp_ent.owner = ply

	return dp_ent
end

function ENT:Use(active_ply, caller, useType, value)
	if self.pod_seat:GetDriver() == NULL and active_ply:IsValid() then
		active_ply:EnterVehicle(self.pod_seat)
		self.pod_seat:SetThirdPersonMode(true)
		self.active_player = self.pod_seat:GetDriver() 

		return self.active_player
	end
end

function ENT:OnTakeDamage(dmg)
	if dmg == nil then return end
	if !self:IsValid() then return end

	dmg:ScaleDamage(0.5)
	self.pod_health = self.pod_health - dmg:GetDamage()
	self:EmitSound("pod_hurt_sound")

	if self.pod_health <= 0 then
		self:pod_explode()
	end
end

local fuel_delay = 0.25
local fuel_last_occurance = -fuel_delay

function ENT:Think()
	if self.active_player ~= nil then
		net.Start("rh2_odst_pod_SEND_INFO")
			net.WriteInt(self.pod_health, 8)
			net.WriteInt(self.pod_stage, 4)
			net.WriteInt(self.pod_fuel, 8)
			net.WriteEntity(self)
		net.Send(self.active_player)

		if self.pod_seat:GetDriver() == NULL then
			self.active_player = nil
		end
	end

	if self.pod_stage == 0 then
		self:pod_launch()
	elseif self.pod_stage == 1 then
		self:pod_control()
		self:pod_airbreak()

		self:apply_prime_velocity()

		self:bad_pod_land()
	elseif self.pod_stage == 2 then
		self:pod_land()
	end
end

function mENT:apply_prime_velocity()
	if !self:IsValid() then return end
	if self.max_velocity_turn == nil then return end

	if !self.airbreak_on and !self.pod_plp_given and !self.launch_speed_degraded and !self.pod_landed and !self.thruster_being_used then
		local pod_ang_velocity = self:GetPhysicsObject():GetAngleVelocity()
		if pod_ang_velocity.x >= -self.max_velocity_turn and pod_ang_velocity.x <= self.max_velocity_turn and pod_ang_velocity.y <= self.max_velocity_turn and pod_ang_velocity.y >= -self.max_velocity_turn then
			local pod_constant_velocity = self:GetPhysicsObject():LocalToWorldVector(Vector(0, 0, -1800))
			self:GetPhysicsObject():SetVelocity(pod_constant_velocity)
		else
			self.launch_speed_degraded = true
		end
	end
end

function mENT:is_touching_ground()
	if !self:IsValid() then return end

	local ent_trace = {start = self:GetPos(), endpos = self:GetPos() - Vector(0, 0, 50), filter = {self, self.pod_seat}}
	local ent_tr = util.TraceEntity(ent_trace, self)

	local trace_result_ent = ent_tr.Entity
	if trace_result_ent == NULL or trace_result_ent == nil then return false end

	if trace_result_ent:GetClass() == "worldspawn" then
		return true
	end

	return false
end

function mENT:pod_blast_dmg()
	if self.active_player == nil then return end
	if !self:IsValid() then return end

	local dmg_info = DamageInfo()
	dmg_info:SetAttacker(self.active_player)
	dmg_info:SetDamage(200)
	dmg_info:SetDamageType(DMG_FALL)

	local ent_test = ents.FindInSphere(self:GetPos(), 250)
	for _i, ent in pairs(ent_test) do
		if ent ~= nil and ent:IsNPC() or ent:IsPlayer() and ent ~= self.active_player then
			ent:TakeDamageInfo(dmg_info)
		end
	end
end

function mENT:bad_pod_land()
	if self.active_player == nil then return end
	if !self:IsValid() then return end

	if !self.pod_landed and self:is_touching_ground() and self.pod_stage > 0 and !self.pod_plp_given then
		self:StopSound("pod_thruster_sound")
		self.active_player:EmitSound("pod_player_hurt_sound")
		self.active_player:Kill()

		self.pod_health = 0
		self:pod_explode()

		self.pod_plp_given = true
	end
end

function mENT:pod_land()
	if self.pod_stage ~= 2 then return end	
	if self.active_player == nil then return end
	if !self:IsValid() then return end

	self:StopSound("pod_thruster_sound")
	
	if !self.pod_landed and self:is_touching_ground() then
		self:SetBodygroup(1, 0)
		self:SetPos(self:GetPos() - Vector(0, 0, 25))
		self.active_player:EmitSound("pod_impact_sound")

		net.Start("rh2_odst_pod_LANDED")
		net.Send(self.active_player)

		self:GetPhysicsObject():EnableMotion(false)
		self:GetPhysicsObject():SetVelocity(Vector(0, 0, 0))
		self:GetPhysicsObject():Sleep()

		self.pod_landed = true
		self:pod_blast_dmg()
	end

	if self.pod_landed and !self.door_opened and self.active_player:KeyDown(IN_ATTACK) then
		self.pod_stage = self.pod_stage + 1
		self:SetBodygroup(2, 1)

		local pod_door_vectorA = self:GetPhysicsObject():LocalToWorldVector(Vector(-50, 0, 35))
		self.pod_door_ent = ents.Create("rims_odst_h2_droppod_door")
		self.pod_door_ent:SetPos(self:GetPos() + pod_door_vectorA)
		self.pod_door_ent:SetAngles(self:GetAngles())
		self.pod_door_ent:Spawn()
		self.pod_door_ent:Activate()

		local pod_door_vectorB = self.pod_door_ent:GetPhysicsObject():LocalToWorldVector(Vector(2000, 0, 160))
		self.pod_door_ent:GetPhysicsObject():SetVelocity(pod_door_vectorB)
		self.door_opened = true

		self.active_player:EmitSound("pod_door_pop_sound")
		timer.Simple(2, function()
			if self.active_player ~= nil then
				self.active_player:StopSound("pod_door_pop_sound")
			end
		end)
	end
end

function mENT:pod_airbreak()
	if self.pod_stage ~= 1 then return end	
	if self.active_player == nil then return end
	if !self:IsValid() then return end

	if self.active_player:KeyDown(IN_ATTACK) and !self:is_touching_ground() then
		self:StopSound("pod_thruster_sound")
		self:SetBodygroup(1, 1)

		self.airbreak_on = true
		self.launch_speed_degraded = true
		self.pod_stage = self.pod_stage + 1
		self.active_player:EmitSound("pod_airbreak_sound")

		net.Start("rh2_odst_pod_AIRBREAK_ON")
		net.Send(self.active_player)
		self:SetNWBool("droppod_thrust_is_on", false)

		local pod_airbreak_velocity = self:GetPhysicsObject():LocalToWorldVector(Vector(0, 0, -1400))
		self:GetPhysicsObject():SetVelocity(pod_airbreak_velocity)

		if self.airbreak_on then
			self.airbreak_on = false
			timer.Simple(3, function()
				if self:IsValid() then
					self:SetBodygroup(1, 0)
				end
			end)
		end
	end
end

function mENT:pod_control()
	if self.pod_stage ~= 1 then return end	
	if self.active_player == nil or !self.active_player:Alive() then return end
	if !self:IsValid() then return end

	local fuel_time_elapsed = CurTime() - fuel_last_occurance

	if self.active_player:KeyDown(IN_ATTACK2) and self.pod_fuel > 0 then
		if fuel_time_elapsed > fuel_delay then
			self.pod_fuel = self.pod_fuel - 1

			local pod_thruster_velocity = self:GetPhysicsObject():LocalToWorldVector(Vector(0, 0, -800))
			self:GetPhysicsObject():AddVelocity(pod_thruster_velocity)
			self:EmitSound("pod_thruster_sound")
			fuel_last_occurance = CurTime()
		end

		--[[net.Start("rh2_odst_pod_THRUST_ON")
		net.Send(self.active_player)]]
		self:SetNWBool("droppod_thrust_is_on", true)
		self.thruster_being_used = true
	else
		self.thruster_being_used = false

		self:SetNWBool("droppod_thrust_is_on", false)
		self:StopSound("pod_thruster_sound")
	end

	if self.active_player:KeyDown(IN_MOVELEFT) and self.pod_fuel > 0 then
		self:GetPhysicsObject():AddAngleVelocity(Vector(-5, 0, 0))
	elseif self.active_player:KeyDown(IN_MOVERIGHT) and self.pod_fuel > 0 then
		self:GetPhysicsObject():AddAngleVelocity(Vector(5, 0, 0))
	elseif self.active_player:KeyDown(IN_FORWARD) and self.pod_fuel > 0 then
		self:GetPhysicsObject():AddAngleVelocity(Vector(0, 5, 0))
	elseif self.active_player:KeyDown(IN_BACK) and self.pod_fuel > 0 then
		self:GetPhysicsObject():AddAngleVelocity(Vector(0, -5, 0))
	end
end

function mENT:pod_launch()
	if self.active_player == nil then return end
	if self.pod_stage ~= 0 then return end	
	if !self:IsValid() then return end

	if self.active_player:KeyDown(IN_ATTACK) then
		self.pod_stage = self.pod_stage + 1
		self:GetPhysicsObject():EnableGravity(true)
		self:GetPhysicsObject():EnableMotion(true)

		local pod_launch_velocity = self:GetPhysicsObject():LocalToWorldVector(Vector(0, 0, -4000))
		self:GetPhysicsObject():SetVelocity(pod_launch_velocity)

		self.active_player:EmitSound("pod_launch_sound")
	end
end

function mENT:pod_explode()
	if !self.exploded then
		self.explode_entA = ents.Create("env_explosion") 
		self.explode_entB = ents.Create("env_physexplosion")
		self.explode_entA:Spawn()
		self.explode_entB:Spawn()
			
		self.explode_entA:SetPos(self:GetPos())
		self.explode_entB:SetPos(self:GetPos())
		
		self.explode_entB:SetKeyValue("magnitude", 175)
		self.explode_entA:SetKeyValue("spawnflags", 178)
		self.explode_entA:Fire("explode", "", 0)
		self.explode_entB:Fire("explode", "", 0)
		
		self.explode_entA:Remove()
		self.explode_entB:Remove()

		self.exploded = true
	end

	self:Remove()
end

function ENT:OnRemove()
	if self.active_player ~= nil then
		self.active_player:StopSound("pod_impact_sound")
		self.active_player:StopSound("pod_start_sound")
		self.active_player:StopSound("pod_launch_sound")
		self.active_player:StopSound("pod_airbreak_sound")
		self.active_player:StopSound("pod_player_hurt_sound")
	end

	self:StopSound("pod_hurt_sound")
	self:StopSound("pod_thruster_sound")
	self.pod_seat:Remove()
end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "ODST Drop Pod"
ENT.Category = "Halo 2 Drop Pod"
ENT.Spawnable = true
ENT.Author = "Rim"


sound.Add( {
	name = "pod_start_sound",
	channel = CHAN_STATIC,
	volume = 0.8,
	level = 80,
	pitch = 100,
	sound = "vehicles/tank_readyfire1.wav"
} )

sound.Add( {
	name = "pod_launch_sound",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = 60,
	sound = "physics/metal/metal_sheet_impact_hard8.wav"
} )

sound.Add( {
	name = "pod_impact_sound",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = 60,
	sound = "ambient/materials/cartrap_explode_impact1.wav"
} )

sound.Add( {
	name = "pod_thruster_sound",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = 40,
	sound = "ambient/gas/steam2.wav"
} )

sound.Add( {
	name = "pod_airbreak_sound",
	channel = CHAN_STATIC,
	volume = 0.8,
	level = 80,
	pitch = 60,
	sound = "physics/plastic/plastic_barrel_break1.wav"
} )

sound.Add( {
	name = "pod_player_hurt_sound",
	channel = CHAN_STATIC,
	volume = 0.8,
	level = 80,
	pitch = 100,
	sound = "vo/npc/male01/pain02.wav"
} )

sound.Add( {
	name = "pod_hurt_sound",
	channel = CHAN_STATIC,
	volume = 0.8,
	level = 80,
	pitch = 60,
	sound = "physics/metal/metal_sheet_impact_bullet1.wav"
} )

sound.Add( {
	name = "pod_door_steam_sound",
	channel = CHAN_STATIC,
	volume = 0.4,
	level = 80,
	pitch = 75,
	sound = "ambient/gas/steam2.wav"
} )

sound.Add( {
	name = "pod_door_pop_sound",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = 50,
	sound = "ambient/materials/clang1.wav"
} )

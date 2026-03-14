if SERVER then
	AddCSLuaFile("vrmod_climbing/client/core.lua")
	AddCSLuaFile("vrmod_climbing/client/wallrun.lua")
	AddCSLuaFile("vrmod_climbing/client/slide.lua")
	AddCSLuaFile("vrmod_climbing/client/ui.lua")
	AddCSLuaFile("vrmod_climbing/client/presets.lua")
	include("vrmod_climbing/server.lua")
	return
end

include("vrmod_climbing/client/core.lua")
include("vrmod_climbing/client/ui.lua")
if SERVER then
	AddCSLuaFile("vrmod_brush_climbing/client/core.lua")
	AddCSLuaFile("vrmod_brush_climbing/client/wallrun.lua")
	AddCSLuaFile("vrmod_brush_climbing/client/slide.lua")
	AddCSLuaFile("vrmod_brush_climbing/client/presets.lua")
	include("vrmod_brush_climbing/server.lua")
	return
end

include("vrmod_brush_climbing/client/core.lua")

g_VR = g_VR or {}
vrmod = vrmod or {}
vrmod.climbing = vrmod.climbing or {}
local cvBindMode = CreateClientConVar("vrmod_brushclimb_bind_mode", "0", true, false, "0=Grip+Trigger, 1=Grip, 2=Trigger", 0, 2)
local cvEnable = CreateClientConVar("vrmod_brushclimb_enable", "1", true, false, "Enable VRMod brush climbing", 0, 1)
local cvGrabDistance = CreateClientConVar("vrmod_brushclimb_grab_distance", "22", true, false, "Brush grab trace range", 4, 48)
local cvLaunchMult = CreateClientConVar("vrmod_brushclimb_launch_mult", "1.35", true, false, "Release launch multiplier", 0, 4)
local cvLaunchMin = CreateClientConVar("vrmod_brushclimb_launch_min", "120", true, false, "Minimum hand speed for launch", 0, 500)
local cvLaunchMax = CreateClientConVar("vrmod_brushclimb_launch_max", "650", true, false, "Maximum added launch speed", 0, 1500)
local cvUseSounds = CreateClientConVar("vrmod_brushclimb_sounds", "1", true, false, "Play climbing sounds", 0, 1)
local cvClimbSoundVolume = CreateClientConVar("vrmod_brushclimb_sound_volume", "0.8", true, false, "Climbing sound volume", 0, 1)
local cvDebug = CreateClientConVar("vrmod_brushclimb_debug", "0", true, false, "Debug draw for brush climbing", 0, 1)
local cvDebugText = CreateClientConVar("vrmod_brushclimb_debug_text", "1", true, false, "Debug text above hands", 0, 1)
local cvHandInset = CreateClientConVar("vrmod_brushclimb_hand_inset", "1.1", true, false, "Push held hand slightly into surface", 0, 4)
local cvWallPushDist = CreateClientConVar("vrmod_brushclimb_wall_push_dist", "2.0", true, false, "Push player body away from wall while holding", 0, 12)
local cvCameraCollision = CreateClientConVar("vrmod_brushclimb_camera_collision", "1", true, false, "Prevent camera clipping into brushes while climbing", 0, 1)
local cvPalmOffsetForward = CreateClientConVar("vrmod_brushclimb_palm_offset_forward", "3.30", true, false, "Temporary palm center forward offset", -8, 8)
local cvPalmOffsetRight = CreateClientConVar("vrmod_brushclimb_palm_offset_right", "-2.32", true, false, "Temporary palm center right offset", -8, 8)
local cvPalmOffsetUp = CreateClientConVar("vrmod_brushclimb_palm_offset_up", "-0.05", true, false, "Temporary palm center up offset", -8, 8)
local cvPalmOffsetForwardRight = CreateClientConVar("vrmod_brushclimb_palm_offset_forward_right", "3.30", true, false, "Right hand palm center forward offset", -8, 8)
local cvPalmOffsetRightRight = CreateClientConVar("vrmod_brushclimb_palm_offset_right_right", "2.32", true, false, "Right hand palm center right offset", -8, 8)
local cvPalmOffsetUpRight = CreateClientConVar("vrmod_brushclimb_palm_offset_up_right", "0.05", true, false, "Right hand palm center up offset", -8, 8)
local cvWallrunHandRange = CreateClientConVar("vrmod_wallrun_hand_range", "20", true, false, "How close hand must be to wall for wall run", 4, 48)
local cvWallrunBindMode = CreateClientConVar("vrmod_wallrun_bind_mode", "1", true, false, "0=Grip, 1=Trigger", 0, 1)
local cvWallrunCooldown = CreateClientConVar("vrmod_wallrun_cooldown", "0.5", true, false, "Seconds before wall run can trigger again", 0, 5)
local cvWallrunAirRegen = CreateClientConVar("vrmod_wallrun_air_regen", "2.0", true, false, "Cooldown seconds recovered per second while airborne (0 = no air regen)", 0, 10)
local cvWallrunLookMaxDot = CreateClientConVar("vrmod_wallrun_look_max_dot", "0.45", true, false, "Max abs(dot(view, wall normal)) allowed for wallrun (lower = stricter along-wall look)", 0, 1)
local cvWallrunSoundEnable = CreateClientConVar("vrmod_wallrun_sounds", "1", true, false, "Play wallrun step sounds", 0, 1)
local cvWallrunSoundVolume = CreateClientConVar("vrmod_wallrun_sound_volume", "0.75", true, false, "Wallrun sound volume", 0, 1)
local cvWallrunSoundInterval = CreateClientConVar("vrmod_wallrun_sound_interval", "0.18", true, false, "Seconds between wallrun step sounds", 0.05, 1)
local cvAllowWalls = CreateClientConVar("vrmod_brushclimb_allow_walls", "1", true, false, "Allow grabbing wall surfaces (server must also permit)", 0, 1)
local cvAllowCeilings = CreateClientConVar("vrmod_brushclimb_allow_ceilings", "1", true, false, "Allow grabbing ceiling surfaces (server must also permit)", 0, 1)
local cvAllowLedges = CreateClientConVar("vrmod_brushclimb_allow_ledges", "1", true, false, "Allow grabbing ledge surfaces (server must also permit)", 0, 1)
local cvAllowFloor = CreateClientConVar("vrmod_brushclimb_allow_floors", "1", true, false, "Allow grabbing floor surfaces (server must also permit)", 0, 1)
local cvAllowDoors = CreateClientConVar("vrmod_brushclimb_allow_doors", "0", true, false, "Allow grabbing door entities (server must also permit)", 0, 1)
local cvAllowPushable = CreateClientConVar("vrmod_brushclimb_allow_pushable", "0", true, false, "Allow grabbing func_pushable entities (server must also permit)", 0, 1)
local cvAllowToggleable = CreateClientConVar("vrmod_brushclimb_allow_toggleable", "0", true, false, "Allow grabbing toggleable brush entities (server must also permit)", 0, 1)
local cvAllowLadders = CreateClientConVar("vrmod_brushclimb_allow_ladders", "1", true, false, "Allow grabbing ladder surfaces (always bypasses surface type filters)", 0, 1)
local cvSlideEnable = CreateClientConVar("vrmod_slide_enable", "1", true, false, "Enable VRMod sliding", 0, 1)
local cvSlideHeadHeight = CreateClientConVar("vrmod_slide_head_height", "40", true, false, "HMD height above origin (units) at which you count as low enough to slide", 4, 120)
local cvSlideSoundEnable = CreateClientConVar("vrmod_slide_sounds", "1", true, false, "Play slide sounds", 0, 1)
local cvSlideSoundVolume = CreateClientConVar("vrmod_slide_sound_volume", "0.75", true, false, "Slide sound volume", 0, 1)
local cvClimbAssistEnable = CreateClientConVar("vrmod_brushclimb_assist_enable", "1", true, false, "Enable subtle climb assist on release", 0, 1)
local cvClimbAssistStrength = CreateClientConVar("vrmod_brushclimb_assist_strength", "65", true, false, "Extra boost strength from climb assist", 0, 260)
local cvDoorBashEnable = CreateClientConVar("vrmod_brushclimb_doorbash_enable", "1", true, false, "Enable door bash with hand impacts", 0, 1)
local cvDoorBashSpeed = CreateClientConVar("vrmod_brushclimb_doorbash_speed", "310", true, false, "Minimum hand speed for door bash", 0, 1200)
local cvDoorBashRange = CreateClientConVar("vrmod_brushclimb_doorbash_range", "22", true, false, "Trace range for door bash detection", 6, 64)
local cvDoorBashCooldown = CreateClientConVar("vrmod_brushclimb_doorbash_cooldown", "0.14", true, false, "Cooldown between door bashes", 0.03, 1)
local cvArmSwingJumpEnable = CreateClientConVar("vrmod_brushclimb_armswing_jump_enable", "1", true, false, "Enable jump from arm swing", 0, 1)
local cvArmSwingJumpSpeed = CreateClientConVar("vrmod_brushclimb_armswing_jump_speed", "265", true, false, "Required upward hand speed per hand for two-hand arm-swing jump", 50, 1200)
local cvArmSwingJumpCooldown = CreateClientConVar("vrmod_brushclimb_armswing_jump_cooldown", "0.18", true, false, "Cooldown between arm-swing jumps", 0.05, 1)
local MIRRORED_PERMISSION_CVARS = {
	vrmod_brushclimb_allow_walls = "sv_vrmod_brushclimb_allow_walls",
	vrmod_brushclimb_allow_ceilings = "sv_vrmod_brushclimb_allow_ceilings",
	vrmod_brushclimb_allow_ledges = "sv_vrmod_brushclimb_allow_ledges",
	vrmod_brushclimb_allow_floors = "sv_vrmod_brushclimb_allow_floors",
	vrmod_brushclimb_allow_doors = "sv_vrmod_brushclimb_allow_doors",
	vrmod_brushclimb_allow_pushable = "sv_vrmod_brushclimb_allow_pushable",
	vrmod_brushclimb_allow_toggleable = "sv_vrmod_brushclimb_allow_toggleable",
}

local MIRRORED_PERMISSION_SERVER_CVARS = {}
local mirroredClientSyncMute = {}
for clientCvarName, serverCvarName in pairs(MIRRORED_PERMISSION_CVARS) do
	MIRRORED_PERMISSION_SERVER_CVARS[serverCvarName] = clientCvarName
end

local function IsTruthyConVarValue(value)
	value = tostring(value or "0")
	return value == "1" or value == "true"
end

local function MirrorClientPermissionToServer(clientCvarName, enabled)
	local serverCvarName = MIRRORED_PERMISSION_CVARS[clientCvarName]
	if not serverCvarName then return end
	if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
	RunConsoleCommand("vrmod_brushclimb_admin_set", serverCvarName, enabled and "1" or "0")
end

for clientCvarName in pairs(MIRRORED_PERMISSION_CVARS) do
	local callbackId = "vrmod_brushclimb_mirror_" .. clientCvarName
	cvars.RemoveChangeCallback(clientCvarName, callbackId)
	cvars.AddChangeCallback(clientCvarName, function(_, _, newValue)
		if mirroredClientSyncMute[clientCvarName] then return end
		MirrorClientPermissionToServer(clientCvarName, IsTruthyConVarValue(newValue))
	end, callbackId)
end

local zeroVec = Vector(0, 0, 0)
local zeroAng = Angle(0, 0, 0)
local HAND_LEFT = 1
local HAND_RIGHT = 2
local hands = {
	[HAND_LEFT] = {
		handId = HAND_LEFT,
		poseName = "pose_lefthand",
		pickupAction = "boolean_left_pickup",
		setPoseName = "SetLeftHandPose",
		triggerBooleans = {"boolean_reload", "boolean_left_primaryfire", "boolean_left_secondaryfire"},
		triggerAnalogs = {"vector1_left_primaryfire"},
		grabAngle = Angle(0, 0, 90),
	},
	[HAND_RIGHT] = {
		handId = HAND_RIGHT,
		poseName = "pose_righthand",
		pickupAction = "boolean_right_pickup",
		setPoseName = "SetRightHandPose",
		triggerBooleans = {"boolean_primaryfire", "boolean_secondaryfire"},
		triggerAnalogs = {"vector1_primaryfire"},
		grabAngle = Angle(0, 0, -90),
	},
}

local state = {
	running = false,
	locomotionStopped = false,
	lastSyncTime = 0,
	lastSyncPos = nil,
	lastUpdateFrame = -1,
	attachLerpTime = 0.09,
	hands = {
		[HAND_LEFT] = {
			want = false,
			holding = false,
			anchorPos = nil,
			anchorNormal = nil,
			gripDown = false,
			triggerDown = false,
			debugTraces = nil,
			debugBest = nil,
			nearWall = false,
			secondaryGrabBlend = false
		},
		[HAND_RIGHT] = {
			want = false,
			holding = false,
			anchorPos = nil,
			anchorNormal = nil,
			gripDown = false,
			triggerDown = false,
			debugTraces = nil,
			debugBest = nil,
			nearWall = false,
			secondaryGrabBlend = false
		},
	},
	wallRunActive = false,
	wallRunCooldownUntil = 0,
	wallRunHand = nil,
	wallRunWasOnGround = true, -- tracks ground state for landing detection
	nextWallRunSoundAt = 0,
	slideActive = false,
	nextDoorBashAt = 0,
	nextArmSwingJumpAt = 0,
}

local liveInput = {}
-- Global API
function vrmod.climbing.GetState()
	return {
		holding = state.hands[HAND_LEFT].holding or state.hands[HAND_RIGHT].holding,
		wallrunning = state.wallRunActive == true,
		sliding = state.slideActive == true,
		running = state.running == true
	}
end

function vrmod.climbing.IsHoldingLeft()
	return state.hands[HAND_LEFT].holding == true
end

function vrmod.climbing.IsHoldingRight()
	return state.hands[HAND_RIGHT].holding == true
end

local climbSounds = {"vrclimb/handstep1.wav", "vrclimb/handstep2.wav", "vrclimb/handstep3.wav", "vrclimb/handstep4.wav",}
local releaseSounds = {"vrclimb/release1.wav", "vrclimb/release2.wav", "vrclimb/release3.wav", "vrclimb/release4.wav", "vrclimb/release5.wav",}
local wallrunSounds = {"vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast1.wav", "vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast2.wav", "vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast3.wav", "vrclimb/footsteps/concrete/me_footsteps_concrete_grit_wallrun_fast5.wav",}
local slideStartSounds = {"vrclimb/slide/concrete/me_concrete_slide1.wav", "vrclimb/slide/concrete/me_concrete_slide2.wav", "vrclimb/slide/concrete/me_concrete_slide3.wav", "vrclimb/slide/concrete/me_concrete_slide4.wav",}
local slideLoopSoundPath = "vrclimb/slide/me_footstep_concreteslideloop.wav"
local traceDirsLocal = {Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1), Vector(0, 0, -1), Vector(1, 1, 0), Vector(1, -1, 0), Vector(-1, 1, 0), Vector(-1, -1, 0), Vector(1, 0, 1), Vector(1, 0, -1), Vector(-1, 0, 1), Vector(-1, 0, -1), Vector(0, 1, 1), Vector(0, 1, -1), Vector(0, -1, 1), Vector(0, -1, -1), Vector(1, 1, 1), Vector(1, 1, -1), Vector(1, -1, 1), Vector(1, -1, -1), Vector(-1, 1, 1), Vector(-1, 1, -1), Vector(-1, -1, 1), Vector(-1, -1, -1),}
local traceDirsWorld = {Vector(0, 0, -1), Vector(0, 0, 1), Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(1, 1, 0):GetNormalized(), Vector(1, -1, 0):GetNormalized(), Vector(-1, 1, 0):GetNormalized(), Vector(-1, -1, 0):GetNormalized(), Vector(1, 0, -1):GetNormalized(), Vector(-1, 0, -1):GetNormalized(), Vector(0, 1, -1):GetNormalized(), Vector(0, -1, -1):GetNormalized(),}
local clientNudgeDirs = {Vector(0, 0, 1), Vector(0, 0, -1), Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(1, 1, 0):GetNormalized(), Vector(1, -1, 0):GetNormalized(), Vector(-1, 1, 0):GetNormalized(), Vector(-1, -1, 0):GetNormalized(),}
local function CanClientFitAt(ply, pos, useDuck)
	if not IsValid(ply) then return false end
	local mins, maxs
	if useDuck then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end

	local tr = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = mins,
		maxs = maxs,
		mask = MASK_PLAYERSOLID,
		filter = ply,
	})
	return not (tr.StartSolid or tr.AllSolid)
end

local function ResolveClientFeetPos(desiredPos, fallbackPos)
	local ply = LocalPlayer()
	if not IsValid(ply) then return desiredPos end
	if CanClientFitAt(ply, desiredPos, true) or CanClientFitAt(ply, desiredPos, false) then return desiredPos end
	for radius = 2, 12, 2 do
		for i = 1, #clientNudgeDirs do
			local testPos = desiredPos + clientNudgeDirs[i] * radius
			if CanClientFitAt(ply, testPos, true) or CanClientFitAt(ply, testPos, false) then return testPos end
		end
	end

	if fallbackPos and (CanClientFitAt(ply, fallbackPos, true) or CanClientFitAt(ply, fallbackPos, false)) then return fallbackPos end
	return desiredPos
end

local function ResolveCameraOriginCollision(targetOrigin)
	if not cvCameraCollision:GetBool() then return targetOrigin end
	if not g_VR or not g_VR.tracking then return targetOrigin end
	local hmd = g_VR.tracking.hmd
	local ply = LocalPlayer()
	if not hmd or not IsValid(ply) then return targetOrigin end
	local localHmd = hmd.pos - g_VR.origin
	local currentHmd = hmd.pos
	local targetHmd = targetOrigin + localHmd
	local radius = 4
	local padding = 1.5
	local tr = util.TraceHull({
		start = currentHmd,
		endpos = targetHmd,
		mins = Vector(-radius, -radius, -radius),
		maxs = Vector(radius, radius, radius),
		mask = MASK_SOLID,
		filter = ply,
	})

	if tr.StartSolid or tr.AllSolid then return g_VR.origin end
	if tr.Hit then
		local safeHmd = tr.HitPos + tr.HitNormal * (radius + padding)
		return safeHmd - localHmd
	end
	return targetOrigin
end

local function GetServerConVarBool(name, fallback)
	local cv = GetConVar(name)
	if not cv then return fallback end
	return cv:GetBool()
end

local function GetServerConVarFloat(name, fallback)
	local cv = GetConVar(name)
	if not cv then return fallback end
	return cv:GetFloat()
end

local function IsClimbableHit(trace)
	if not trace or not trace.Hit then return false end
	if trace.HitWorld then return true end
	local ent = trace.Entity
	if not IsValid(ent) then
		-- Some BSP/detail brush hits can come through without a valid entity clientside.
		-- If it's a solid hit at all, allow it as climbable geometry.
		return true
	end

	if ent:GetSolid() == SOLID_NONE then return false end
	local cls = ent:GetClass() or ""
	-- Doors: server must permit AND client must permit
	local isDoor = cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating"
	if isDoor then return GetServerConVarBool("sv_vrmod_brushclimb_allow_doors", false) and cvAllowDoors:GetBool() end
	-- func_pushable: server must permit AND client must permit
	if cls == "func_pushable" then return GetServerConVarBool("sv_vrmod_brushclimb_allow_pushable", false) and cvAllowPushable:GetBool() end
	-- Toggleable brushes: server must permit AND client must permit
	local isToggleable = cls == "func_button" or cls == "func_rot_button" or cls == "momentary_rot_button" or cls == "momentary_door"
	if isToggleable then return GetServerConVarBool("sv_vrmod_brushclimb_allow_toggleable", false) and cvAllowToggleable:GetBool() end
	-- Static props are safe for grabbing.
	if cls == "prop_static" then return true end
	-- Dynamic props are allowed only when effectively static.
	if cls == "prop_dynamic" then return ent:GetMoveType() == MOVETYPE_NONE end
	-- Physics props stay blocked (moving networked bodies desync badly).
	if cls == "prop_physics" then return false end
	if string.StartWith(cls, "func_") then return true end
	local model = ent:GetModel()
	if isstring(model) and string.sub(model, 1, 1) == "*" then return true end
	if ent:GetMoveType() == MOVETYPE_NONE then return true end
	return false
end

local function IsLadderSurface(trace)
	if not trace or not trace.Hit then return false end
	if IsValid(trace.Entity) then
		local cls = string.lower(trace.Entity:GetClass() or "")
		if cls == "func_useableladder" or cls == "func_ladder" or cls == "func_climbable" then return true end
	end

	local tex = trace.HitTexture and string.lower(trace.HitTexture) or ""
	if tex ~= "" and string.find(tex, "ladder", 1, true) then return true end
	local samplePos = trace.HitPos + trace.HitNormal * 2
	return bit.band(util.PointContents(samplePos), CONTENTS_LADDER) ~= 0
end

-- Returns "floor", "ledge", "wall", or "ceiling" based on the surface normal.
-- Thresholds read from replicated server convars so clients stay in sync.
local function GetSurfaceType(normal)
	if not normal then return "wall" end
	local z = normal.z
	local floorMin = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_floor_normal_min", 0.85), 0, 1)
	local ledgeMin = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_ledge_normal_min", 0.55), 0, 1)
	local ceilMax = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_ceil_normal_max", -0.55), -1, 0)
	if z >= floorMin then return "floor" end
	if z >= ledgeMin then return "ledge" end
	if z <= ceilMax then return "ceiling" end
	return "wall"
end

local function GetGrabSurfacePriority(surfaceType)
	if surfaceType == "floor" then return 4 end
	if surfaceType == "ledge" then return 3 end
	if surfaceType == "wall" then return 2 end
	if surfaceType == "ceiling" then return 1 end
	return 0
end

local function GetTraceSurfaceType(trace)
	if not trace or not trace.Hit then return "wall" end
	local surfaceType = GetSurfaceType(trace.HitNormal)
	if surfaceType ~= "wall" then return surfaceType end
	local floorMin = math.Clamp(GetServerConVarFloat("sv_vrmod_brushclimb_floor_normal_min", 0.85), 0, 1)
	local wallFlat = Vector(trace.HitNormal.x, trace.HitNormal.y, 0)
	if wallFlat:LengthSqr() < 0.0001 then return surfaceType end
	wallFlat:Normalize()
	-- If we hit a vertical face, probe just above and slightly inside it.
	-- A walkable top face here means the wall hit is really a ledge/lip.
	local probeStart = trace.HitPos + Vector(0, 0, 12) - wallFlat * 3
	local topTrace = util.TraceHull({
		start = probeStart,
		endpos = probeStart + Vector(0, 0, -20),
		mins = Vector(-1.5, -1.5, -1.5),
		maxs = Vector(1.5, 1.5, 1.5),
		mask = MASK_SOLID,
		filter = LocalPlayer(),
	})

	if not topTrace.Hit then return surfaceType end
	if topTrace.HitNormal.z < floorMin then return surfaceType end
	if topTrace.HitPos.z <= trace.HitPos.z + 2 then return surfaceType end
	if topTrace.HitPos.z > trace.HitPos.z + 24 then return surfaceType end
	return "ledge"
end

local function GetPalmOffsetForHand(handId)
	if handId == HAND_RIGHT then return Vector(cvPalmOffsetForwardRight:GetFloat(), cvPalmOffsetRightRight:GetFloat(), cvPalmOffsetUpRight:GetFloat()) end
	return Vector(cvPalmOffsetForward:GetFloat(), cvPalmOffsetRight:GetFloat(), cvPalmOffsetUp:GetFloat())
end

local function GetHandCenterPos(handPose, handId)
	local offset = GetPalmOffsetForHand(handId)
	return LocalToWorld(offset, zeroAng, handPose.pos, handPose.ang)
end

local function IsDoorEntity(ent)
	if not IsValid(ent) then return false end
	local cls = ent:GetClass() or ""
	return cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating"
end

local function PickSound(list, volume)
	if not cvUseSounds:GetBool() then return end
	if #list == 0 then return end
	local snd = list[math.random(1, #list)]
	local vol = math.Clamp(volume or cvClimbSoundVolume:GetFloat(), 0, 1)
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply:EmitSound(snd, 75, math.random(96, 104), vol, CHAN_AUTO)
	else
		surface.PlaySound(snd)
	end
end

local function TryDoorBash(handPose, handId)
	if not cvDoorBashEnable:GetBool() then return end
	if CurTime() < (state.nextDoorBashAt or 0) then return end
	if not handPose or not handPose.vel then return end
	local speed = handPose.vel:Length()
	if speed < cvDoorBashSpeed:GetFloat() then return end
	local startPos = GetHandCenterPos(handPose, handId)
	local dir = handPose.vel:GetNormalized()
	if dir:LengthSqr() < 0.001 then dir = handPose.ang:Forward() end
	local trace = util.TraceLine({
		start = startPos,
		endpos = startPos + dir * cvDoorBashRange:GetFloat(),
		mask = MASK_SOLID,
		filter = LocalPlayer(),
	})

	if not trace.Hit or not IsDoorEntity(trace.Entity) then return end
	state.nextDoorBashAt = CurTime() + cvDoorBashCooldown:GetFloat()
	net.Start("vrmod_brush_doorbash")
	net.WriteEntity(trace.Entity)
	net.SendToServer()
end

local StopSlideLoopSound
local EnsureSlideLoopSound
local StopWallRunSignal
local UpdateWallRun
local UpdateSlide
local GetTriggerDown
local GetGripDown
local AnyHandHolding
local wallrunModule = include("vrmod_climbing/client/wallrun.lua")
if isfunction(wallrunModule) then
	wallrunModule({
		state = state,
		hands = hands,
		HAND_LEFT = HAND_LEFT,
		HAND_RIGHT = HAND_RIGHT,
		traceDirsLocal = traceDirsLocal,
		zeroVec = zeroVec,
		zeroAng = zeroAng,
		wallrunSounds = wallrunSounds,
		releaseSounds = releaseSounds,
		cvUseSounds = cvUseSounds,
		cvWallrunBindMode = cvWallrunBindMode,
		cvWallrunCooldown = cvWallrunCooldown,
		cvWallrunAirRegen = cvWallrunAirRegen,
		cvWallrunLookMaxDot = cvWallrunLookMaxDot,
		cvWallrunSoundEnable = cvWallrunSoundEnable,
		cvWallrunSoundVolume = cvWallrunSoundVolume,
		cvWallrunSoundInterval = cvWallrunSoundInterval,
		cvWallrunHandRange = cvWallrunHandRange,
		cvLaunchMult = cvLaunchMult,
		cvLaunchMin = cvLaunchMin,
		cvLaunchMax = cvLaunchMax,
		-- Defer function resolution so module init order cannot capture nil upvalues.
		GetGripDown = function(...)
			if isfunction(GetGripDown) then return GetGripDown(...) end
			return false
		end,
		GetTriggerDown = function(...)
			if isfunction(GetTriggerDown) then return GetTriggerDown(...) end
			return false
		end,
		GetHandCenterPos = function(...)
			if isfunction(GetHandCenterPos) then return GetHandCenterPos(...) end
			return zeroVec
		end,
		AnyHandHolding = function(...)
			if isfunction(AnyHandHolding) then return AnyHandHolding(...) end
			return false
		end,
		PickSound = PickSound,
		setStopWallRunSignal = function(fn) StopWallRunSignal = fn end,
		setUpdateWallRun = function(fn) UpdateWallRun = fn end,
	})
end

local slideModule = include("vrmod_climbing/client/slide.lua")
if isfunction(slideModule) then
	slideModule({
		state = state,
		zeroVec = zeroVec,
		cvUseSounds = cvUseSounds,
		cvSlideEnable = cvSlideEnable,
		cvSlideHeadHeight = cvSlideHeadHeight,
		cvSlideSoundEnable = cvSlideSoundEnable,
		cvSlideSoundVolume = cvSlideSoundVolume,
		slideStartSounds = slideStartSounds,
		slideLoopSoundPath = slideLoopSoundPath,
		GetServerConVarFloat = GetServerConVarFloat,
		AnyHandHolding = function(...)
			if isfunction(AnyHandHolding) then return AnyHandHolding(...) end
			return false
		end,
		PickSound = PickSound,
		setStopSlideLoopSound = function(fn) StopSlideLoopSound = fn end,
		setEnsureSlideLoopSound = function(fn) EnsureSlideLoopSound = fn end,
		setUpdateSlide = function(fn) UpdateSlide = fn end,
	})
end

StopSlideLoopSound = StopSlideLoopSound or function() end
EnsureSlideLoopSound = EnsureSlideLoopSound or function() end
StopWallRunSignal = StopWallRunSignal or function() end
UpdateWallRun = UpdateWallRun or function() end
UpdateSlide = UpdateSlide or function() end
GetTriggerDown = function(handCfg)
	local input = g_VR.input or {}
	local boolKeys = handCfg.triggerBooleans or {}
	local hasBool = false
	for i = 1, #boolKeys do
		local val = liveInput[boolKeys[i]]
		if val == nil then val = input[boolKeys[i]] end
		if val ~= nil then
			hasBool = true
			if val then return true end
		end
	end

	if hasBool then return false end
	local analogKeys = handCfg.triggerAnalogs or {}
	local maxAnalog = nil
	for i = 1, #analogKeys do
		local val = input[analogKeys[i]]
		if val ~= nil then maxAnalog = math.max(maxAnalog or 0, val) end
	end

	if maxAnalog ~= nil then return maxAnalog > 0.6 end
	return input[handCfg.pickupAction] or false
end

GetGripDown = function(handCfg)
	local input = g_VR.input or {}
	local val = liveInput[handCfg.pickupAction]
	if val ~= nil then return val end
	return input[handCfg.pickupAction] or false
end

local function WantsGrab(handId)
	local handCfg = hands[handId]
	local gripDown = GetGripDown(handCfg)
	local triggerDown = GetTriggerDown(handCfg)
	local mode = cvBindMode:GetInt()
	if mode == 1 then
		return gripDown
	elseif mode == 2 then
		return triggerDown
	end
	return gripDown and triggerDown
end

local function FindGrabSurface(handPose, handId)
	local bestTrace = nil
	local bestDist = math.huge
	local bestPriority = -1
	local range = cvGrabDistance:GetFloat()
	local startPos = GetHandCenterPos(handPose, handId)
	local traceRadius = 1.6
	-- Surface type permissions: both server AND client must allow
	local svWalls = GetServerConVarBool("sv_vrmod_brushclimb_allow_walls", true)
	local svCeilings = GetServerConVarBool("sv_vrmod_brushclimb_allow_ceilings", true)
	local svLedges = GetServerConVarBool("sv_vrmod_brushclimb_allow_ledges", true)
	local svFloors = GetServerConVarBool("sv_vrmod_brushclimb_allow_floors", true)
	local debugTraces = cvDebug:GetBool() and {} or nil
	local function EvaluateTrace(dir)
		local endPos = startPos + dir * range
		local trace = util.TraceLine({
			start = startPos,
			endpos = endPos,
			mask = MASK_SOLID,
			filter = LocalPlayer(),
		})

		if not trace.Hit then
			trace = util.TraceHull({
				start = startPos,
				endpos = endPos,
				mins = Vector(-traceRadius, -traceRadius, -traceRadius),
				maxs = Vector(traceRadius, traceRadius, traceRadius),
				mask = MASK_SOLID,
				filter = LocalPlayer(),
			})
		end

		-- Ladders (func_ladder, func_useableladder, func_climbable, CONTENTS_LADDER) always
		-- bypass surface-type filters and entity filters; they are always climbable unless
		-- the client explicitly opts out with allow_ladders = 0.
		local valid = false
		local surfType = "wall"
		if trace and trace.Hit then
			local isLadder = IsLadderSurface(trace)
			if isLadder then
				valid = cvAllowLadders:GetBool()
				surfType = "ledge"
			else
				-- Surface type filter (server ceiling AND client preference)
				surfType = GetTraceSurfaceType(trace)
				local surfaceAllowed
				if surfType == "floor" then
					surfaceAllowed = svFloors and cvAllowFloor:GetBool()
				elseif surfType == "ledge" then
					surfaceAllowed = svLedges and cvAllowLedges:GetBool()
				elseif surfType == "ceiling" then
					surfaceAllowed = svCeilings and cvAllowCeilings:GetBool()
				else -- wall
					surfaceAllowed = svWalls and cvAllowWalls:GetBool()
				end

				valid = IsClimbableHit(trace) and surfaceAllowed
			end
		end

		if debugTraces then
			debugTraces[#debugTraces + 1] = {
				start = startPos,
				stop = endPos,
				hit = trace and trace.Hit or false,
				hitPos = trace and trace.HitPos or endPos,
				valid = valid,
				surfaceType = surfType,
			}
		end

		if valid then
			local priority = GetGrabSurfacePriority(surfType)
			local dist = startPos:DistToSqr(trace.HitPos)
			if priority > bestPriority or priority == bestPriority and dist < bestDist then
				bestPriority = priority
				bestDist = dist
				bestTrace = trace
			end
		end
	end

	for i = 1, #traceDirsLocal do
		local dir = LocalToWorld(traceDirsLocal[i]:GetNormalized(), zeroAng, zeroVec, handPose.ang)
		EvaluateTrace(dir)
	end

	for i = 1, #traceDirsWorld do
		EvaluateTrace(traceDirsWorld[i])
	end
	return bestTrace, debugTraces
end

AnyHandHolding = function() return state.hands[HAND_LEFT].holding or state.hands[HAND_RIGHT].holding end
local function TryArmSwingJump()
	if not cvArmSwingJumpEnable:GetBool() then return end
	if CurTime() < (state.nextArmSwingJumpAt or 0) then return end
	if AnyHandHolding() or state.wallRunActive or state.slideActive then return end
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:IsOnGround() then return end
	if not g_VR or not g_VR.tracking then return end
	local leftPose = g_VR.tracking[hands[HAND_LEFT].poseName]
	local rightPose = g_VR.tracking[hands[HAND_RIGHT].poseName]
	if not leftPose or not rightPose or not leftPose.vel or not rightPose.vel then return end
	local leftUp = math.max(0, leftPose.vel.z)
	local rightUp = math.max(0, rightPose.vel.z)
	local minSpeed = cvArmSwingJumpSpeed:GetFloat()
	if leftUp < minSpeed or rightUp < minSpeed then return end
	local avgUpSpeed = (leftUp + rightUp) * 0.5
	local intensity = math.Clamp(avgUpSpeed / math.max(minSpeed, 1), 1, 1.8)
	state.nextArmSwingJumpAt = CurTime() + cvArmSwingJumpCooldown:GetFloat()
	net.Start("vrmod_brush_armswing_jump")
	net.WriteFloat(intensity)
	net.SendToServer()
end

local function SyncServerPos(pos, holding, force)
	if not IsValid(LocalPlayer()) then return end
	local now = CurTime()
	if not force then
		local minInterval = 0.05
		if now - state.lastSyncTime < minInterval then return end
		if state.lastSyncPos and state.lastSyncPos:DistToSqr(pos) < 4 then return end
	end

	state.lastSyncTime = now
	state.lastSyncPos = Vector(pos.x, pos.y, pos.z)
	net.Start("vrmod_brush_climb_sync")
	net.WriteVector(pos)
	net.WriteBool(holding)
	net.SendToServer()
end

local function UpdateLocomotionState()
	if AnyHandHolding() then
		if not state.locomotionStopped and vrmod.StopLocomotion then
			state.locomotionStopped = true
			vrmod.StopLocomotion()
		end
	elseif state.locomotionStopped then
		state.locomotionStopped = false
		if vrmod.StartLocomotion then vrmod.StartLocomotion() end
		if g_VR and g_VR.tracking and g_VR.tracking.hmd then
			local hmd = g_VR.tracking.hmd
			local releasePos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
			releasePos.z = g_VR.origin.z
			releasePos = ResolveClientFeetPos(releasePos, LocalPlayer():GetPos())
			SyncServerPos(releasePos, false, true)
		end
	end
end

local function ReleaseHand(handId, doLaunch)
	local handState = state.hands[handId]
	if not handState.holding then return end
	local releaseNormal = handState.anchorNormal and Vector(handState.anchorNormal.x, handState.anchorNormal.y, handState.anchorNormal.z) or nil
	handState.holding = false
	handState.anchorPos = nil
	handState.anchorNormal = nil
	handState.anchorStartPos = nil
	handState.originAtGrab = nil
	handState.localHandAtGrab = nil
	handState.grabStartTime = nil
	handState.frozenHandAng = nil
	local handCfg = hands[handId]
	local pose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
	local handVel = pose and pose.vel or Vector()
	local launch = -handVel * cvLaunchMult:GetFloat()
	local minSpeed = cvLaunchMin:GetFloat()
	local maxSpeed = cvLaunchMax:GetFloat()
	local fullyReleased = not AnyHandHolding()
	local usedAssist = false
	local speed = launch:Length()
	local didLaunch = false
	if doLaunch and fullyReleased then
		if cvClimbAssistEnable:GetBool() and releaseNormal then
			local surfType = GetSurfaceType(releaseNormal)
			if surfType == "wall" or surfType == "ledge" then
				local downSpeed = math.max(0, -handVel.z)
				local assistThreshold = math.max(60, minSpeed * 0.45)
				if downSpeed >= assistThreshold then
					local assistScale = math.Clamp(downSpeed / math.max(cvLaunchMax:GetFloat(), 1), 0, 1)
					local assistPower = cvClimbAssistStrength:GetFloat() * (0.45 + assistScale * 0.55)
					local away = Vector(releaseNormal.x, releaseNormal.y, 0)
					if away:LengthSqr() > 0.001 then
						away:Normalize()
					else
						away = zeroVec
					end

					launch = launch + Vector(0, 0, assistPower) + away * assistPower * 0.2
					usedAssist = true
				end
			end
		end

		speed = launch:Length()
		local maxResult = maxSpeed + (usedAssist and cvClimbAssistStrength:GetFloat() or 0)
		if speed > maxResult and speed > 0 then
			launch = launch:GetNormalized() * maxResult
			speed = maxResult
		end

		if speed > minSpeed or usedAssist then
			net.Start("vrmod_brush_climb_launch")
			net.WriteVector(launch)
			net.SendToServer()
			didLaunch = true
		end
	end

	if fullyReleased and didLaunch then PickSound(releaseSounds) end
end

local function GrabHand(handId)
	local handCfg = hands[handId]
	local pose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
	if not pose then return end
	local trace, debugTraces = FindGrabSurface(pose, handId)
	local handState = state.hands[handId]
	handState.debugTraces = debugTraces
	handState.debugBest = trace and trace.HitPos or nil
	if not trace then return end
	local inset = math.max(0, cvHandInset:GetFloat())
	local anchorPos = trace.HitPos - trace.HitNormal * inset
	local hadOtherHandHolding = false
	for otherHandId, otherState in pairs(state.hands) do
		if otherHandId ~= handId and otherState.holding then
			hadOtherHandHolding = true
			break
		end
	end

	handState.holding = true
	handState.anchorPos = anchorPos
	handState.anchorNormal = trace.HitNormal
	handState.anchorStartPos = GetHandCenterPos(pose, handId)
	handState.grabStartTime = CurTime()
	handState.frozenHandAng = Angle(pose.ang.pitch, pose.ang.yaw, pose.ang.roll)
	handState.secondaryGrabBlend = hadOtherHandHolding
	-- Smoothly pull from the grabbed hand pose to the wall anchor to avoid sudden snaps.
	handState.originAtGrab = Vector(g_VR.origin.x, g_VR.origin.y, g_VR.origin.z)
	handState.localHandAtGrab = handState.anchorStartPos - g_VR.origin
	PickSound(climbSounds)
end

local function UpdateHeldMovement()
	local desiredOrigin = Vector(0, 0, 0)
	local weightSum = 0
	local pushNormal = Vector(0, 0, 0)
	local pushCount = 0
	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		if handState.holding and handState.anchorPos then
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then
				local handCenterNow = GetHandCenterPos(pose, handId)
				local localHandNow = handCenterNow - g_VR.origin
				local anchorPos = handState.anchorPos
				local blendT = 1
				if handState.grabStartTime and handState.anchorStartPos then
					blendT = math.Clamp((CurTime() - handState.grabStartTime) / state.attachLerpTime, 0, 1)
					anchorPos = LerpVector(blendT, handState.anchorStartPos, handState.anchorPos)
				end

				local handWeight = 1
				if handState.secondaryGrabBlend then
					handWeight = math.max(0.001, blendT)
					if blendT >= 1 then handState.secondaryGrabBlend = false end
				end

				desiredOrigin = desiredOrigin + (anchorPos - localHandNow) * handWeight
				weightSum = weightSum + handWeight
				if handState.anchorNormal then
					pushNormal = pushNormal + handState.anchorNormal
					pushCount = pushCount + 1
				end
			end
		end
	end

	if weightSum <= 0 then return end
	local targetOrigin = desiredOrigin / weightSum
	if pushCount > 0 then
		local avgNormal = pushNormal / pushCount
		local lateral = Vector(avgNormal.x, avgNormal.y, 0)
		local lateralLenSqr = lateral:LengthSqr()
		local pushDist = math.max(0, cvWallPushDist:GetFloat())
		if lateralLenSqr > 0.0001 and pushDist > 0 then targetOrigin = targetOrigin + lateral:GetNormalized() * pushDist end
	end

	targetOrigin = ResolveCameraOriginCollision(targetOrigin)
	g_VR.origin = targetOrigin
	local hmd = g_VR.tracking.hmd
	if hmd and IsValid(LocalPlayer()) then
		local feetPos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
		feetPos.z = g_VR.origin.z
		local safeFeetPos = ResolveClientFeetPos(feetPos, LocalPlayer():GetPos())
		LocalPlayer():SetPos(safeFeetPos)
		SyncServerPos(safeFeetPos, true, false)
	end
end

local function UpdateHandPoses()
	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		if handState.holding and handState.anchorPos then
			local setPose = vrmod and vrmod[handCfg.setPoseName]
			if setPose then
				local targetPos = handState.anchorPos
				if handState.grabStartTime and handState.anchorStartPos then
					local t = math.Clamp((CurTime() - handState.grabStartTime) / state.attachLerpTime, 0, 1)
					targetPos = LerpVector(t, handState.anchorStartPos, handState.anchorPos)
				end

				local trackingPose = g_VR.tracking and g_VR.tracking[handCfg.poseName]
				local frozenAng = handState.frozenHandAng or trackingPose and trackingPose.ang or zeroAng
				local palmOffset = GetPalmOffsetForHand(handId)
				local handRootPos = LocalToWorld(-palmOffset, zeroAng, targetPos, frozenAng)
				setPose(handRootPos, frozenAng)
			end
		end
	end
end

local function ResetState()
	for handId, handState in pairs(state.hands) do
		handState.want = false
		handState.gripDown = false
		handState.triggerDown = false
		handState.debugTraces = nil
		handState.debugBest = nil
		handState.anchorStartPos = nil
		handState.originAtGrab = nil
		handState.localHandAtGrab = nil
		handState.grabStartTime = nil
		handState.frozenHandAng = nil
		handState.nearWall = false
		handState.secondaryGrabBlend = false
		if handState.holding then ReleaseHand(handId, false) end
	end

	if state.wallRunActive then
		state.wallRunActive = false
		state.wallRunHand = nil
		state.wallRunCooldownUntil = CurTime() + cvWallrunCooldown:GetFloat()
		state.nextWallRunSoundAt = 0
		net.Start("vrmod_wallrun_sync")
		net.WriteBool(false)
		net.WriteVector(zeroVec)
		net.SendToServer()
	end

	if state.slideActive then
		state.slideActive = false
		net.Start("vrmod_slide_sync")
		net.WriteBool(false)
		net.WriteVector(zeroVec)
		net.SendToServer()
	end

	StopSlideLoopSound()
	UpdateLocomotionState()
end

local function UpdateClimbing(renderPass)
	if not state.running then return end
	if not g_VR or not g_VR.active or not g_VR.tracking then return end
	if renderPass == "right" then return end
	local frameNum = FrameNumber()
	if state.lastUpdateFrame == frameNum then return end
	state.lastUpdateFrame = frameNum
	for handId, handState in pairs(state.hands) do
		local handCfg = hands[handId]
		handState.gripDown = GetGripDown(handCfg)
		handState.triggerDown = GetTriggerDown(handCfg)
		if cvDebug:GetBool() and not handState.holding then
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then
				local trace, debugTraces = FindGrabSurface(pose, handId)
				handState.debugTraces = debugTraces
				handState.debugBest = trace and trace.HitPos or nil
			end
		end

		local wantsGrab = WantsGrab(handId)
		if wantsGrab and not handState.want then
			GrabHand(handId)
		elseif not wantsGrab and handState.want then
			ReleaseHand(handId, true)
		end

		handState.want = wantsGrab
		if not handState.holding and not wantsGrab then
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then TryDoorBash(pose, handId) end
		end
	end

	TryArmSwingJump()
	UpdateLocomotionState()
	UpdateHeldMovement()
	UpdateHandPoses()
	UpdateWallRun()
	UpdateSlide()
end

local function DrawDebug()
	if not state.running then return end
	if not cvDebug:GetBool() then return end
	if not g_VR or not g_VR.active or not g_VR.tracking then return end
	render.SetColorMaterial()
	local range = cvGrabDistance:GetFloat()
	local half = Vector(range, range, range)
	for handId, handCfg in pairs(hands) do
		local handState = state.hands[handId]
		local pose = g_VR.tracking[handCfg.poseName]
		if pose then
			local color = Color(255, 255, 255, 160)
			if handState.gripDown then color = Color(255, 220, 80, 180) end
			if handState.triggerDown then color = Color(255, 150, 40, 180) end
			if handState.want then color = Color(80, 255, 120, 200) end
			if handState.holding then color = Color(80, 180, 255, 220) end
			render.DrawWireframeBox(pose.pos, Angle(), -half, half, color, true)
			render.DrawWireframeSphere(pose.pos, range, 10, 10, color, true)
			if handState.debugTraces then
				for i = 1, #handState.debugTraces do
					local tr = handState.debugTraces[i]
					local lineColor = tr.valid and Color(0, 255, 0, 180) or Color(255, 0, 0, 90)
					render.DrawLine(tr.start, tr.stop, lineColor, true)
					if tr.hit then render.DrawWireframeSphere(tr.hitPos, 0.8, 4, 4, lineColor, true) end
				end
			end

			if handState.holding and handState.anchorPos then
				render.DrawWireframeSphere(handState.anchorPos, 1.4, 6, 6, Color(100, 220, 255, 220), true)
			elseif handState.debugBest then
				render.DrawWireframeSphere(handState.debugBest, 1.2, 6, 6, Color(120, 255, 120, 210), true)
			end

			if cvDebugText:GetBool() then
				local viewPos = g_VR.tracking.hmd and g_VR.tracking.hmd.pos or EyePos()
				local txtPos = pose.pos + Vector(0, 0, 4)
				local txtAng = (viewPos - txtPos):Angle()
				txtAng = Angle(0, txtAng.yaw + 90, 90)
				local wrTag = state.wallRunActive and "WR:ON" or handState.nearWall and "WR:NEAR" or "WR:--"
				local slideTag = state.slideActive and "SLD:ON" or "SLD:--"
				cam.Start3D2D(txtPos, txtAng, 0.03)
				draw.SimpleTextOutlined(string.format("%s G:%d T:%d W:%d H:%d %s %s", handId == HAND_LEFT and "L" or "R", handState.gripDown and 1 or 0, handState.triggerDown and 1 or 0, handState.want and 1 or 0, handState.holding and 1 or 0, wrTag, slideTag), "DermaLarge", 0, 0, state.slideActive and Color(80, 200, 255, 235) or state.wallRunActive and Color(255, 200, 50, 235) or Color(255, 255, 255, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
				cam.End3D2D()
			end
		end
	end
end

local function StopClimbing()
	if not state.running then return end
	state.running = false
	ResetState()
	StopSlideLoopSound()
	state.lastSyncPos = nil
	state.lastSyncTime = 0
	state.lastUpdateFrame = -1
	if g_VR and g_VR.tracking and g_VR.tracking.hmd then
		local hmd = g_VR.tracking.hmd
		local stopPos = hmd.pos + Angle(0, hmd.ang.yaw, 0):Forward() * -10
		stopPos.z = g_VR.origin.z
		stopPos = ResolveClientFeetPos(stopPos, LocalPlayer():GetPos())
		SyncServerPos(stopPos, false, true)
	end

	hook.Remove("VRMod_PreRender", "vrmod_brush_climbing")
	hook.Remove("VRMod_Input", "vrmod_brush_climbing_inputcache")
	hook.Remove("PostDrawTranslucentRenderables", "vrmod_brush_climbing_debug")
end

local function StartClimbing()
	if state.running then return end
	if not cvEnable:GetBool() then return end
	state.running = true
	state.lastSyncPos = nil
	state.lastSyncTime = 0
	state.lastUpdateFrame = -1
	liveInput = {}
	for k, v in pairs(g_VR.input or {}) do
		liveInput[k] = v
	end

	hook.Add("VRMod_PreRender", "vrmod_brush_climbing", UpdateClimbing)
	hook.Add("VRMod_Input", "vrmod_brush_climbing_inputcache", function(action, pressed) liveInput[action] = pressed end)
	hook.Add("PostDrawTranslucentRenderables", "vrmod_brush_climbing_debug", function(depth, sky)
		if depth or sky then return end
		DrawDebug()
	end)
end

hook.Add("VRMod_Start", "vrmod_brush_climbing_start", function(ply)
	if ply ~= LocalPlayer() then return end
	StartClimbing()
end)

hook.Add("VRMod_Exit", "vrmod_brush_climbing_exit", function(ply)
	if ply ~= LocalPlayer() then return end
	StopClimbing()
end)

cvars.AddChangeCallback("vrmod_brushclimb_enable", function(_, _, newValue)
	if tobool(newValue) then
		if g_VR and g_VR.active then StartClimbing() end
		return
	end

	StopClimbing()
end, "vrmod_brush_climbing_enable")

if g_VR and g_VR.active then timer.Simple(0, StartClimbing) end
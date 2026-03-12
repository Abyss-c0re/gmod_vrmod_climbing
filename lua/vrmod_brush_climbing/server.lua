if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("vrmod_brush_climb_launch")
	util.AddNetworkString("vrmod_brush_climb_sync")
	util.AddNetworkString("vrmod_wallrun_sync")
	util.AddNetworkString("vrmod_slide_sync")
	util.AddNetworkString("vrmod_brush_doorbash")
	util.AddNetworkString("vrmod_brush_armswing_jump")
	vrmod = vrmod or {}
	vrmod.climbing = vrmod.climbing or {}
	local svLedgeNormalMin = CreateConVar("sv_vrmod_brushclimb_ledge_normal_min", "0.55", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum surface normal Z to classify as a ledge (below this = wall)", 0, 1)
	local svFloorNormalMin = CreateConVar("sv_vrmod_brushclimb_floor_normal_min", "0.85", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum surface normal Z to classify as a floor (above = floor, below = ledge)", 0, 1)
	local svCeilNormalMax = CreateConVar("sv_vrmod_brushclimb_ceil_normal_max", "-0.55", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Maximum surface normal Z to classify as a ceiling", -1, 0)
	local svReduceCollider = CreateConVar("sv_vrmod_brushclimb_reduce_collider", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Force duck hull while climbing and after release until ground touch", 0, 1)
	-- Surface type permissions (admin sets the ceiling; clients can only further restrict)
	local svAllowWalls = CreateConVar("sv_vrmod_brushclimb_allow_walls", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing wall surfaces", 0, 1)
	local svAllowCeilings = CreateConVar("sv_vrmod_brushclimb_allow_ceilings", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing ceiling surfaces", 0, 1)
	local svAllowLedges = CreateConVar("sv_vrmod_brushclimb_allow_ledges", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing ledge surfaces", 0, 1)
	local svAllowFloors = CreateConVar("sv_vrmod_brushclimb_allow_floors", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing floor surfaces", 0, 1)
	-- Entity type permissions
	local svAllowDoors = CreateConVar("sv_vrmod_brushclimb_allow_doors", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing door entities", 0, 1)
	local svAllowPushable = CreateConVar("sv_vrmod_brushclimb_allow_pushable", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing func_pushable entities", 0, 1)
	local svAllowToggleable = CreateConVar("sv_vrmod_brushclimb_allow_toggleable", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow grabbing toggleable brush entities (func_button, etc.)", 0, 1)
	local svWallrunJumpForce = CreateConVar("sv_vrmod_wallrun_jump_force", "350", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Wall jump launch force", 50, 800)
	local svWallrunWallForce = CreateConVar("sv_vrmod_wallrun_wall_force", "120", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Force pushing player into wall while running", 10, 400)
	local svWallrunFreeTime = CreateConVar("sv_vrmod_wallrun_free_time", "0.6", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds of free running before gravity builds", 0, 10)
	local svWallrunFallRate = CreateConVar("sv_vrmod_wallrun_fall_rate", "90", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Downward acceleration after free time", 0, 600)
	local svWallrunMaxFall = CreateConVar("sv_vrmod_wallrun_max_fall_speed", "260", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max downward speed while wall running", 0, 1000)
	local svWallrunSpeed = CreateConVar("sv_vrmod_wallrun_speed", "300", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Target horizontal speed while wall running", 80, 1000)
	local svWallrunBounceForce = CreateConVar("sv_vrmod_wallrun_bounce_force", "170", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Push away from wall on wallrun jump", 0, 900)
	local svWallrunSpeedGrace = CreateConVar("sv_vrmod_wallrun_speed_grace", "0.15", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to blend direction when attaching to wall at speed", 0, 1)
	local svWallrunMinJumpTime = CreateConVar("sv_vrmod_wallrun_min_jump_time", "0.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Min seconds on wall before wallrun jump fires (prevents sprint-jump hijack)", 0, 1)
	local svDoorBashEnable = CreateConVar("sv_vrmod_doorbash_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow opening doors with high-speed hand impacts", 0, 1)
	local svDoorBashCooldown = CreateConVar("sv_vrmod_doorbash_open_cooldown", "0.08", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Cooldown between door bashes", 0.03, 1)
	local svDoorBashVolume = CreateConVar("sv_vrmod_doorbash_sound_volume", "0.75", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Impact sound volume for door bash", 0, 1)
	local svArmSwingJumpEnable = CreateConVar("sv_vrmod_armswing_jump_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow jumping from hand swings", 0, 1)
	local svArmSwingJumpPower = CreateConVar("sv_vrmod_armswing_jump_power", "185", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Vertical force from arm swing jump", 80, 500)
	local svArmSwingForwardBoost = CreateConVar("sv_vrmod_armswing_forward_boost", "35", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Forward boost from arm swing jump", 0, 300)
	local svArmSwingJumpCooldown = CreateConVar("sv_vrmod_armswing_jump_cooldown", "0.14", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Cooldown between arm swing jumps", 0.05, 1)
	local svSlideEnable = CreateConVar("sv_vrmod_slide_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Enable VRMod sliding", 0, 1)
	local svSlideMinSpeed = CreateConVar("sv_vrmod_slide_min_speed", "150", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Minimum horizontal speed to enter a slide", 0, 800)
	local svSlideFriction = CreateConVar("sv_vrmod_slide_friction", "100", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Horizontal deceleration while sliding (units/s^2)", 0, 600)
	local svSlideAirBoost = CreateConVar("sv_vrmod_slide_air_boost", "80", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed boost added when landing into a slide from the air", 0, 600)
	local svSlideStopSpeed = CreateConVar("sv_vrmod_slide_stop_speed", "60", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed below which a slide automatically ends", 0, 400)
	local svSlideEntryBoost = CreateConVar("sv_vrmod_slide_entry_boost", "60", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Flat speed bonus added the moment a slide begins", 0, 600)
	local editableServerCvars = {
		sv_vrmod_brushclimb_ledge_normal_min = svLedgeNormalMin,
		sv_vrmod_brushclimb_floor_normal_min = svFloorNormalMin,
		sv_vrmod_brushclimb_ceil_normal_max = svCeilNormalMax,
		sv_vrmod_brushclimb_reduce_collider = svReduceCollider,
		sv_vrmod_brushclimb_allow_walls = svAllowWalls,
		sv_vrmod_brushclimb_allow_ceilings = svAllowCeilings,
		sv_vrmod_brushclimb_allow_ledges = svAllowLedges,
		sv_vrmod_brushclimb_allow_floors = svAllowFloors,
		sv_vrmod_brushclimb_allow_doors = svAllowDoors,
		sv_vrmod_brushclimb_allow_pushable = svAllowPushable,
		sv_vrmod_brushclimb_allow_toggleable = svAllowToggleable,
		sv_vrmod_wallrun_jump_force = svWallrunJumpForce,
		sv_vrmod_wallrun_wall_force = svWallrunWallForce,
		sv_vrmod_wallrun_free_time = svWallrunFreeTime,
		sv_vrmod_wallrun_fall_rate = svWallrunFallRate,
		sv_vrmod_wallrun_max_fall_speed = svWallrunMaxFall,
		sv_vrmod_wallrun_speed = svWallrunSpeed,
		sv_vrmod_wallrun_bounce_force = svWallrunBounceForce,
		sv_vrmod_wallrun_speed_grace = svWallrunSpeedGrace,
		sv_vrmod_wallrun_min_jump_time = svWallrunMinJumpTime,
		sv_vrmod_doorbash_enable = svDoorBashEnable,
		sv_vrmod_doorbash_open_cooldown = svDoorBashCooldown,
		sv_vrmod_doorbash_sound_volume = svDoorBashVolume,
		sv_vrmod_armswing_jump_enable = svArmSwingJumpEnable,
		sv_vrmod_armswing_jump_power = svArmSwingJumpPower,
		sv_vrmod_armswing_forward_boost = svArmSwingForwardBoost,
		sv_vrmod_armswing_jump_cooldown = svArmSwingJumpCooldown,
		sv_vrmod_slide_enable = svSlideEnable,
		sv_vrmod_slide_min_speed = svSlideMinSpeed,
		sv_vrmod_slide_friction = svSlideFriction,
		sv_vrmod_slide_air_boost = svSlideAirBoost,
		sv_vrmod_slide_stop_speed = svSlideStopSpeed,
		sv_vrmod_slide_entry_boost = svSlideEntryBoost,
	}

	concommand.Add("vrmod_brushclimb_admin_set", function(ply, _, args)
		if IsValid(ply) and not ply:IsAdmin() then return end
		local cvarName = args[1]
		local rawValue = args[2]
		local cv = cvarName and editableServerCvars[cvarName] or nil
		if not cv or rawValue == nil then return end
		cv:SetString(tostring(rawValue))
	end)

	local fallProtectUntil = {}
	local nextLaunchTime = {}
	local nextDoorBashAt = {}
	local nextArmSwingJumpAt = {}
	local isBrushHolding = {}
	local holdExpireAt = {}
	local duckHoldUntil = {}
	local duckUntilGround = {}
	local zeroVel = Vector(0, 0, 0)
	-- Slide state
	local isSliding = {}
	local slideDir = {}
	local slideSpeed = {}
	local wantsSlide = {}
	local slideDirWanted = {}
	local wasAirLow = {}
	local slideJumpMomentum = {} -- {dir, speed, storedAt}
	-- Wall run entry state
	local wallRunEntrySpeed = {} -- horizontal speed captured at first wall contact
	local holdSyncGrace = 0.25
	local duckGrace = 0.35
	local maxSyncDistSqr = 300 * 300
	local nudgeDirs = {Vector(0, 0, 1), Vector(0, 0, -1), Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(1, 1, 0):GetNormalized(), Vector(1, -1, 0):GetNormalized(), Vector(-1, 1, 0):GetNormalized(), Vector(-1, -1, 0):GetNormalized(),}
	--API
	function vrmod.climbing.GetState(ply)
		return {
			holding = isBrushHolding[ply] == true,
			wallrunning = vrWallRunWants[ply] ~= nil,
			sliding = isSliding[ply] == true,
			slideSpeed = slideSpeed[ply] or 0,
			fallProtected = (fallProtectUntil[ply] or 0) > CurTime()
		}
	end

	local function CanFitAt(ply, pos, mins, maxs)
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

	local function CanFitAnyHull(ply, pos)
		local minsStand, maxsStand = ply:GetHull()
		local minsDuck, maxsDuck = ply:GetHullDuck()
		return CanFitAt(ply, pos, minsStand, maxsStand) or CanFitAt(ply, pos, minsDuck, maxsDuck)
	end

	local function ResolveToNearbyFit(ply, desiredPos, fallbackPos, maxRadius, stepSize)
		if CanFitAnyHull(ply, desiredPos) then return desiredPos end
		maxRadius = maxRadius or 18
		stepSize = stepSize or 3
		for radius = stepSize, maxRadius, stepSize do
			for i = 1, #nudgeDirs do
				local testPos = desiredPos + nudgeDirs[i] * radius
				if CanFitAnyHull(ply, testPos) then return testPos end
			end

			local upTest = desiredPos + Vector(0, 0, radius * 0.8)
			if CanFitAnyHull(ply, upTest) then return upTest end
		end

		if fallbackPos and CanFitAnyHull(ply, fallbackPos) then return fallbackPos end
		return nil
	end

	local function applyLaunch(_, ply)
		if not IsValid(ply) then return end
		local now = CurTime()
		if (nextLaunchTime[ply] or 0) > now then return end
		nextLaunchTime[ply] = now + 0.08
		local launch = net.ReadVector()
		local maxSpeed = 900
		if launch:LengthSqr() > maxSpeed * maxSpeed then launch = launch:GetNormalized() * maxSpeed end
		local currentVel = ply:GetVelocity()
		local desiredVel = currentVel + launch
		local maxResultSpeed = 950
		if desiredVel:LengthSqr() > maxResultSpeed * maxResultSpeed then desiredVel = desiredVel:GetNormalized() * maxResultSpeed end
		ply:SetVelocity(desiredVel - currentVel)
	end

	if vrmod and vrmod.NetReceiveLimited then
		vrmod.NetReceiveLimited("vrmod_brush_climb_launch", 24, 96, applyLaunch)
	else
		net.Receive("vrmod_brush_climb_launch", applyLaunch)
	end

	local function IsDoorEntity(ent)
		if not IsValid(ent) then return false end
		local cls = ent:GetClass() or ""
		return cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating"
	end

	net.Receive("vrmod_brush_doorbash", function(_, ply)
		if not IsValid(ply) then return end
		if not svDoorBashEnable:GetBool() then return end
		local now = CurTime()
		if (nextDoorBashAt[ply] or 0) > now then return end
		local door = net.ReadEntity()
		if not IsDoorEntity(door) then return end
		if ply:GetPos():DistToSqr(door:GetPos()) > 190 * 190 then return end
		nextDoorBashAt[ply] = now + svDoorBashCooldown:GetFloat()
		door:Fire("Unlock", "", 0)
		door:Fire("SetSpeed", "900", 0)
		door:Fire("Open", "", 0)
		door:Fire("Use", "", 0)
		door:EmitSound("physics/wood/wood_crate_impact_hard3.wav", 85, math.random(95, 108), math.Clamp(svDoorBashVolume:GetFloat(), 0, 1))
	end)

	net.Receive("vrmod_brush_armswing_jump", function(_, ply)
		if not IsValid(ply) then return end
		if not svArmSwingJumpEnable:GetBool() then return end
		if not ply:Alive() or not ply:IsOnGround() then return end
		local moveType = ply:GetMoveType()
		if moveType == MOVETYPE_NOCLIP or moveType == MOVETYPE_OBSERVER then return end
		local now = CurTime()
		if (nextArmSwingJumpAt[ply] or 0) > now then return end
		nextArmSwingJumpAt[ply] = now + svArmSwingJumpCooldown:GetFloat()
		local intensity = math.Clamp(net.ReadFloat() or 1, 0.75, 1.8)
		local vel = ply:GetVelocity()
		local jumpVel = Vector(0, 0, svArmSwingJumpPower:GetFloat() * intensity)
		local forward = ply:EyeAngles():Forward()
		forward.z = 0
		if forward:LengthSqr() > 0.0001 then
			forward:Normalize()
			jumpVel = jumpVel + forward * svArmSwingForwardBoost:GetFloat() * intensity
		end

		local target = vel + jumpVel
		local maxSpeed = 1000
		if target:LengthSqr() > maxSpeed * maxSpeed then target = target:GetNormalized() * maxSpeed end
		ply:SetVelocity(target - vel)
		fallProtectUntil[ply] = now + 0.4
	end)

	local function applySync(_, ply)
		if not IsValid(ply) then return end
		local pos = net.ReadVector()
		local holding = net.ReadBool()
		if not pos then return end
		local currentPos = ply:GetPos()
		local now = CurTime()
		if currentPos:DistToSqr(pos) > maxSyncDistSqr then
			if not holding then
				isBrushHolding[ply] = false
				holdExpireAt[ply] = nil
			end
			return
		end

		if holding then
			local resolved = ResolveToNearbyFit(ply, pos, currentPos, 20, 4)
			if resolved then
				ply:SetPos(resolved)
				isBrushHolding[ply] = true
				holdExpireAt[ply] = now + holdSyncGrace
				duckHoldUntil[ply] = now + duckGrace
				fallProtectUntil[ply] = now + 0.35
			else
				isBrushHolding[ply] = false
				holdExpireAt[ply] = nil
				fallProtectUntil[ply] = now + 0.45
			end
			return
		end

		isBrushHolding[ply] = false
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = now + 0.2
		duckUntilGround[ply] = svReduceCollider:GetBool()
		local resolved = ResolveToNearbyFit(ply, pos, currentPos, 14, 2)
		if resolved then ply:SetPos(resolved) end
		fallProtectUntil[ply] = now + 0.9
	end

	if vrmod and vrmod.NetReceiveLimited then
		vrmod.NetReceiveLimited("vrmod_brush_climb_sync", 60, 128, applySync)
	else
		net.Receive("vrmod_brush_climb_sync", applySync)
	end

	-- Wall run server state
	local vrWallRunWants = {}
	local wallRunStartTime = {}
	net.Receive("vrmod_wallrun_sync", function(_, ply)
		if not IsValid(ply) then return end
		local active = net.ReadBool()
		local normal = net.ReadVector()
		if active then
			vrWallRunWants[ply] = normal
		else
			vrWallRunWants[ply] = nil
		end
	end)

	net.Receive("vrmod_slide_sync", function(_, ply)
		if not IsValid(ply) then return end
		local active = net.ReadBool()
		local dir = net.ReadVector()
		wantsSlide[ply] = active
		slideDirWanted[ply] = dir
	end)

	local function GetWallFlatNormal(normal)
		local flat = Vector(normal.x, normal.y, 0)
		if flat:LengthSqr() > 0.0001 then
			flat:Normalize()
			return flat
		end
		return Vector(normal.x, normal.y, normal.z):GetNormalized()
	end

	local function ClampFlatSpeed(vec, maxSpeed)
		local flat = Vector(vec.x, vec.y, 0)
		local flatLen = flat:Length()
		if flatLen > maxSpeed and flatLen > 0 then flat = flat * maxSpeed / flatLen end
		return Vector(flat.x, flat.y, vec.z)
	end

	hook.Add("GetFallDamage", "vrmod_brush_climb_nofall", function(ply)
		if fallProtectUntil[ply] and fallProtectUntil[ply] > CurTime() then return 0 end
		if vrWallRunWants[ply] or wallRunStartTime[ply] then return 0 end
		if isSliding[ply] or slideJumpMomentum[ply] or wasAirLow[ply] or wantsSlide[ply] then return 0 end
	end)

	hook.Add("SetupMove", "vrmod_brush_climb_hold_velocity_lock", function(ply, mv)
		local now = CurTime()
		local holding = isBrushHolding[ply] and (holdExpireAt[ply] or 0) > now
		if holding then
			mv:SetVelocity(zeroVel)
			mv:SetForwardSpeed(0)
			mv:SetSideSpeed(0)
			mv:SetUpSpeed(0)
		elseif isBrushHolding[ply] then
			isBrushHolding[ply] = false
		end

		-- Wall run physics
		local wallNormal = vrWallRunWants[ply]
		if wallNormal and not holding and not ply:IsOnGround() then
			local currentVel = mv:GetVelocity()
			local currentHorizSpeed = Vector(currentVel.x, currentVel.y, 0):Length()
			if not wallRunStartTime[ply] then
				wallRunStartTime[ply] = now
				wallRunEntrySpeed[ply] = currentHorizSpeed
				fallProtectUntil[ply] = now + 10
			end

			local elapsed = now - wallRunStartTime[ply]
			-- FIX: only fire wallrun jump if the player has actually been on the wall
			-- long enough. This prevents a sprint-jump grazing the wall for one tick
			-- from hijacking the jump direction.
			if ply:KeyPressed(IN_JUMP) then
				if elapsed >= svWallrunMinJumpTime:GetFloat() then
					local wallFlatNormal = GetWallFlatNormal(wallNormal)
					local eyeFwd = ply:EyeAngles():Forward()
					local flatFwd = Vector(eyeFwd.x, eyeFwd.y, 0)
					local alongWallDir = flatFwd - wallFlatNormal * flatFwd:Dot(wallFlatNormal)
					if alongWallDir:LengthSqr() < 0.001 then alongWallDir = wallFlatNormal:Cross(Vector(0, 0, 1)) end
					if alongWallDir:LengthSqr() > 0.001 then alongWallDir:Normalize() end
					local currentFlat = Vector(currentVel.x, currentVel.y, 0)
					local intoWallSpeed = math.max(0, currentFlat:Dot(wallFlatNormal * -1))
					if intoWallSpeed > 0 then currentFlat = currentFlat + wallFlatNormal * intoWallSpeed end
					local tangentFlat = currentFlat - wallFlatNormal * currentFlat:Dot(wallFlatNormal)
					local awaySpeed = math.max(currentFlat:Dot(wallFlatNormal), svWallrunBounceForce:GetFloat())
					local upStrength = svWallrunJumpForce:GetFloat()
					local jumpFlat = tangentFlat + alongWallDir * upStrength * 0.45 + wallFlatNormal * awaySpeed
					local resultVel = ClampFlatSpeed(Vector(jumpFlat.x, jumpFlat.y, math.max(currentVel.z, 0) + upStrength), math.max(1100, svWallrunSpeed:GetFloat() + awaySpeed + upStrength * 0.45))
					mv:SetVelocity(resultVel)
					fallProtectUntil[ply] = now + 1.0
				end

				-- Either way, exit wallrun on jump press
				vrWallRunWants[ply] = nil
				wallRunEntrySpeed[ply] = nil
			else
				-- Wall-run movement direction
				local wallFlatNormal = GetWallFlatNormal(wallNormal)
				local viewDir = ply:EyeAngles():Forward()
				local moveDir = viewDir - wallFlatNormal * viewDir:Dot(wallFlatNormal)
				moveDir.z = 0
				if moveDir:LengthSqr() < 0.001 then moveDir = wallFlatNormal:Cross(Vector(0, 0, 1)) end
				moveDir:Normalize()
				local freeTime = svWallrunFreeTime:GetFloat()
				local entrySpeed = wallRunEntrySpeed[ply] or 0
				-- FIX: never reduce horizontal speed. Always carry at least entrySpeed
				-- (or whatever is faster right now). The drop phase only adds downward
				-- velocity — it does not touch horizontal.
				local targetHorizSpeed = math.max(entrySpeed, currentHorizSpeed, svWallrunSpeed:GetFloat())
				-- FIX: gravity adds to current Z instead of replacing it.
				-- During free time: hold Z near zero (counteract gravity).
				-- After free time: accumulate downward acceleration on top of currentVel.z.
				local zVel
				if elapsed < freeTime then
					zVel = math.max(currentVel.z, -4.0)
				else
					local fallRate = svWallrunFallRate:GetFloat()
					local maxFall = svWallrunMaxFall:GetFloat()
					zVel = math.max(currentVel.z - fallRate * FrameTime(), -maxFall)
				end

				-- Direction grace: blend entry heading → wall-run direction
				local spGrace = svWallrunSpeedGrace:GetFloat()
				local wallPushFlat = wallFlatNormal * -svWallrunWallForce:GetFloat()
				local targetFlat = moveDir * targetHorizSpeed
				local finalFlat
				if spGrace > 0 and elapsed < spGrace then
					local t = elapsed / spGrace
					local entryFlat = Vector(currentVel.x, currentVel.y, 0)
					if entryFlat:LengthSqr() < 0.001 then entryFlat = targetFlat end
					local blendedDir = LerpVector(t, entryFlat:GetNormalized(), moveDir)
					if blendedDir:LengthSqr() < 0.001 then blendedDir = moveDir end
					blendedDir:Normalize()
					finalFlat = blendedDir * targetHorizSpeed
				else
					finalFlat = targetFlat
				end

				mv:SetVelocity(finalFlat + wallPushFlat + Vector(0, 0, zVel))
				mv:SetSideSpeed(0)
				if mv:GetForwardSpeed() < 0 then mv:SetForwardSpeed(0) end
			end
		elseif ply:IsOnGround() then
			wallRunStartTime[ply] = nil
			wallRunEntrySpeed[ply] = nil
		end

		if duckHoldUntil[ply] and bit.band(ply:GetFlags(), FL_ONGROUND) ~= 0 then duckHoldUntil[ply] = nil end
		if duckUntilGround[ply] and bit.band(ply:GetFlags(), FL_ONGROUND) ~= 0 then duckUntilGround[ply] = nil end
		-- ── Sliding ───────────────────────────────────────────────────────────
		if svSlideEnable:GetBool() and not holding and not vrWallRunWants[ply] then
			local vel = mv:GetVelocity()
			local onGround = ply:IsOnGround()
			local frameTime = FrameTime()
			-- Only use the client HMD-height signal. Do NOT use IN_DUCK as a fallback:
			-- VRmod sets IN_DUCK on every crouch-jump, which would silently trigger a
			-- fake slide on any fast sprint-jump and corrupt the jump direction.
			local low = wantsSlide[ply] == true
			-- Re-apply slide-jump horizontal momentum (first airborne tick).
			-- storedAt prevents the discard branch from firing on the same tick as the jump.
			-- Also discard if the player is no longer low - they stood up, so the slide
			-- momentum should not apply (and was likely a false trigger to begin with).
			if slideJumpMomentum[ply] then
				local mom = slideJumpMomentum[ply]
				local age = now - mom.storedAt
				if not onGround and not low then
					-- Player stood up mid-air: discard, do not apply locked direction.
					slideJumpMomentum[ply] = nil
				elseif not onGround and low then
					mv:SetVelocity(Vector(mom.dir.x * mom.speed, mom.dir.y * mom.speed, vel.z))
					slideJumpMomentum[ply] = nil
				elseif age > 0.3 then
					slideJumpMomentum[ply] = nil
				end
			end

			if isSliding[ply] then
				local dir = slideDir[ply]
				local speed = slideSpeed[ply] or 0
				speed = math.max(speed - svSlideFriction:GetFloat() * frameTime, 0)
				slideSpeed[ply] = speed
				if not low or not onGround or speed < svSlideStopSpeed:GetFloat() then
					isSliding[ply] = false
					slideDir[ply] = nil
					slideSpeed[ply] = nil
				elseif ply:KeyPressed(IN_JUMP) then
					slideJumpMomentum[ply] = {
						dir = dir,
						speed = speed,
						storedAt = now
					}

					isSliding[ply] = false
					slideDir[ply] = nil
					slideSpeed[ply] = nil
				else
					mv:SetVelocity(dir * speed + Vector(0, 0, vel.z))
					mv:SetForwardSpeed(0)
					mv:SetSideSpeed(0)
					mv:SetUpSpeed(0)
					mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
				end
			elseif onGround and low then
				local hVel = Vector(vel.x, vel.y, 0)
				local speed = hVel:Length()
				local boost = 0
				if wasAirLow[ply] then
					boost = svSlideAirBoost:GetFloat()
					wasAirLow[ply] = nil
				end

				if speed + boost >= svSlideMinSpeed:GetFloat() then
					local dir = slideDirWanted[ply]
					if not dir or dir:LengthSqr() < 0.01 then dir = hVel end
					dir = Vector(dir.x, dir.y, 0)
					if dir:LengthSqr() > 0.001 then
						dir:Normalize()
						local entrySpeed = speed + boost + svSlideEntryBoost:GetFloat()
						isSliding[ply] = true
						slideDir[ply] = dir
						slideSpeed[ply] = entrySpeed
						mv:SetVelocity(dir * entrySpeed + Vector(0, 0, vel.z))
						mv:SetForwardSpeed(0)
						mv:SetSideSpeed(0)
						mv:SetUpSpeed(0)
						mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK))
						ply:EmitSound("physics/concrete/concrete_scrape_smooth1.wav", 75, math.random(90, 110), 0.6)
					end
				end
			elseif not onGround and low then
				wasAirLow[ply] = true
			elseif onGround then
				wasAirLow[ply] = nil
			end
		end

		-- ── End Sliding ───────────────────────────────────────────────────────
		local forceDuck = (duckHoldUntil[ply] or 0) > now
		if svReduceCollider:GetBool() then forceDuck = forceDuck or holding or duckUntilGround[ply] == true end
		if forceDuck then mv:SetButtons(bit.bor(mv:GetButtons(), IN_DUCK)) end
	end)

	hook.Add("PlayerDisconnected", "vrmod_brush_climb_cleanup", function(ply)
		fallProtectUntil[ply] = nil
		nextLaunchTime[ply] = nil
		nextDoorBashAt[ply] = nil
		nextArmSwingJumpAt[ply] = nil
		isBrushHolding[ply] = nil
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = nil
		duckUntilGround[ply] = nil
		vrWallRunWants[ply] = nil
		wallRunStartTime[ply] = nil
		wallRunEntrySpeed[ply] = nil
		isSliding[ply] = nil
		slideDir[ply] = nil
		slideSpeed[ply] = nil
		wantsSlide[ply] = nil
		slideDirWanted[ply] = nil
		wasAirLow[ply] = nil
		slideJumpMomentum[ply] = nil
	end)

	hook.Add("PlayerDeath", "vrmod_brush_climb_cleanup_death", function(ply)
		isBrushHolding[ply] = nil
		nextDoorBashAt[ply] = nil
		nextArmSwingJumpAt[ply] = nil
		holdExpireAt[ply] = nil
		duckHoldUntil[ply] = nil
		duckUntilGround[ply] = nil
		vrWallRunWants[ply] = nil
		wallRunStartTime[ply] = nil
		wallRunEntrySpeed[ply] = nil
		isSliding[ply] = nil
		slideDir[ply] = nil
		slideSpeed[ply] = nil
		wantsSlide[ply] = nil
		slideDirWanted[ply] = nil
		wasAirLow[ply] = nil
		slideJumpMomentum[ply] = nil
	end)

	hook.Add("PlayerFootstep", "vrmod_wallrun_no_footstep", function(ply) if vrWallRunWants[ply] then return true end end)
	return
end
return function(ctx)
	if not istable(ctx) then return end

	local state = ctx.state
	local hands = ctx.hands
	local HAND_LEFT = ctx.HAND_LEFT
	local HAND_RIGHT = ctx.HAND_RIGHT
	local traceDirsLocal = ctx.traceDirsLocal
	local zeroVec = ctx.zeroVec
	local zeroAng = ctx.zeroAng
	local wallrunSounds = ctx.wallrunSounds or {}
	local releaseSounds = ctx.releaseSounds or {}

	local cvUseSounds = ctx.cvUseSounds
	local cvWallrunBindMode = ctx.cvWallrunBindMode
	local cvWallrunCooldown = ctx.cvWallrunCooldown
	local cvWallrunAirRegen = ctx.cvWallrunAirRegen
	local cvWallrunLookMaxDot = ctx.cvWallrunLookMaxDot
	local cvWallrunSoundEnable = ctx.cvWallrunSoundEnable
	local cvWallrunSoundVolume = ctx.cvWallrunSoundVolume
	local cvWallrunSoundInterval = ctx.cvWallrunSoundInterval
	local cvWallrunHandRange = ctx.cvWallrunHandRange
	local cvLaunchMult = ctx.cvLaunchMult
	local cvLaunchMin = ctx.cvLaunchMin
	local cvLaunchMax = ctx.cvLaunchMax

	local GetGripDown = ctx.GetGripDown
	local GetTriggerDown = ctx.GetTriggerDown
	local GetHandCenterPos = ctx.GetHandCenterPos
	local AnyHandHolding = ctx.AnyHandHolding
	local PickSound = ctx.PickSound

	local function IsLookingAlongWall(normal)
		local ply = LocalPlayer()
		if not IsValid(ply) or not normal then return false end
		local view = ply:EyeAngles():Forward()
		local viewFlat = Vector(view.x, view.y, 0)
		local wallFlat = Vector(normal.x, normal.y, 0)
		if viewFlat:LengthSqr() < 0.0001 or wallFlat:LengthSqr() < 0.0001 then return false end
		viewFlat:Normalize()
		wallFlat:Normalize()
		local maxDot = math.Clamp(cvWallrunLookMaxDot:GetFloat(), 0, 1)
		return math.abs(viewFlat:Dot(wallFlat)) <= maxDot
	end

	local function MaybePlayWallRunStep(forceNow)
		if not (cvUseSounds:GetBool() and cvWallrunSoundEnable:GetBool()) then return end
		local now = CurTime()
		if not forceNow and now < (state.nextWallRunSoundAt or 0) then return end
		PickSound(wallrunSounds, cvWallrunSoundVolume:GetFloat())
		state.nextWallRunSoundAt = now + cvWallrunSoundInterval:GetFloat()
	end

	local function IsHandNearWall(handPose, handId)
		local range = cvWallrunHandRange:GetFloat()
		local startPos = GetHandCenterPos(handPose, handId)
		for i = 1, #traceDirsLocal do
			local dir = LocalToWorld(traceDirsLocal[i]:GetNormalized(), zeroAng, zeroVec, handPose.ang)
			local trace = util.TraceLine({
				start = startPos,
				endpos = startPos + dir * range,
				mask = MASK_SOLID,
				filter = LocalPlayer(),
			})
			if trace.Hit and math.abs(trace.HitNormal.z) < 0.3 then
				if trace.HitWorld or (IsValid(trace.Entity) and trace.Entity:GetSolid() ~= SOLID_NONE) then
					return true, trace.HitNormal
				end
			end
		end
		return false, nil
	end

	local function WallRunInputHeld()
		local mode = cvWallrunBindMode:GetInt()
		for _, handCfg in pairs(hands) do
			if mode == 0 then
				if GetGripDown(handCfg) then return true end
			else
				if GetTriggerDown(handCfg) then return true end
			end
		end
		return false
	end

	local function StopWallRunSignal()
		if not state.wallRunActive then return end
		state.wallRunActive = false
		state.wallRunCooldownUntil = CurTime() + cvWallrunCooldown:GetFloat()
		state.nextWallRunSoundAt = 0

		local wallHand = state.wallRunHand
		state.wallRunHand = nil
		if wallHand and g_VR and g_VR.tracking then
			local otherHandId = wallHand == HAND_LEFT and HAND_RIGHT or HAND_LEFT
			local otherCfg = hands[otherHandId]
			local otherPose = g_VR.tracking[otherCfg.poseName]
			if otherPose and otherPose.vel then
				local launch = -otherPose.vel * cvLaunchMult:GetFloat()
				local speed = launch:Length()
				local minSpeed = cvLaunchMin:GetFloat()
				local maxSpeed = cvLaunchMax:GetFloat()
				if speed > minSpeed then
					if speed > maxSpeed then
						launch = launch:GetNormalized() * maxSpeed
					end
					net.Start("vrmod_brush_climb_launch")
					net.WriteVector(launch)
					net.SendToServer()
					PickSound(releaseSounds)
				end
			end
		end

		net.Start("vrmod_wallrun_sync")
		net.WriteBool(false)
		net.WriteVector(zeroVec)
		net.SendToServer()
	end

	local function UpdateWallRun()
		if not g_VR or not g_VR.tracking then return end
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local onGround = ply:IsOnGround()
		if onGround and not state.wallRunWasOnGround then
			state.wallRunCooldownUntil = 0
		end

		if not onGround and not state.wallRunActive then
			local regen = cvWallrunAirRegen:GetFloat()
			if regen > 0 and state.wallRunCooldownUntil > CurTime() then
				state.wallRunCooldownUntil = state.wallRunCooldownUntil - regen * FrameTime()
			end
		end

		state.wallRunWasOnGround = onGround

		if AnyHandHolding() then
			StopWallRunSignal()
			for _, hs in pairs(state.hands) do hs.nearWall = false end
			return
		end

		if not WallRunInputHeld() then
			StopWallRunSignal()
			for _, hs in pairs(state.hands) do hs.nearWall = false end
			return
		end

		local found = false
		local hitNormal = nil
		local foundHand = nil
		for handId, handCfg in pairs(hands) do
			local pose = g_VR.tracking[handCfg.poseName]
			if pose then
				local near, normal = IsHandNearWall(pose, handId)
				state.hands[handId].nearWall = near
				if near and IsLookingAlongWall(normal) and not found then
					found = true
					hitNormal = normal
					foundHand = handId
				end
			else
				state.hands[handId].nearWall = false
			end
		end

		if found and not state.wallRunActive then
			if CurTime() < state.wallRunCooldownUntil then return end
			state.wallRunActive = true
			state.wallRunHand = foundHand
			state.nextWallRunSoundAt = 0
			net.Start("vrmod_wallrun_sync")
			net.WriteBool(true)
			net.WriteVector(hitNormal)
			net.SendToServer()
			MaybePlayWallRunStep(true)
		elseif found and state.wallRunActive then
			state.wallRunHand = foundHand
			MaybePlayWallRunStep(false)
		elseif not found and state.wallRunActive then
			StopWallRunSignal()
		end
	end

	if isfunction(ctx.setStopWallRunSignal) then
		ctx.setStopWallRunSignal(StopWallRunSignal)
	end
	if isfunction(ctx.setUpdateWallRun) then
		ctx.setUpdateWallRun(UpdateWallRun)
	end
end

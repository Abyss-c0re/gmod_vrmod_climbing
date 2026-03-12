return function(ctx)
	if not istable(ctx) then return end
	local state = ctx.state
	local zeroVec = ctx.zeroVec
	local cvUseSounds = ctx.cvUseSounds
	local cvSlideEnable = ctx.cvSlideEnable
	local cvSlideHeadHeight = ctx.cvSlideHeadHeight
	local cvSlideSoundEnable = ctx.cvSlideSoundEnable
	local cvSlideSoundVolume = ctx.cvSlideSoundVolume
	local slideStartSounds = ctx.slideStartSounds or {}
	local slideLoopSoundPath = ctx.slideLoopSoundPath
	local GetServerConVarFloat = ctx.GetServerConVarFloat
	local AnyHandHolding = ctx.AnyHandHolding
	local PickSound = ctx.PickSound
	local slideLoopPatch = nil
	-- Stop slide loop sound
	local function StopSlideLoopSound()
		if slideLoopPatch then
			slideLoopPatch:Stop()
			slideLoopPatch = nil
		end
	end

	-- Ensure slide loop sound is playing
	local function EnsureSlideLoopSound()
		if not (cvUseSounds:GetBool() and cvSlideSoundEnable:GetBool()) then
			StopSlideLoopSound()
			return
		end

		local ply = LocalPlayer()
		if not IsValid(ply) then
			StopSlideLoopSound()
			return
		end

		if not slideLoopPatch then slideLoopPatch = CreateSound(ply, slideLoopSoundPath) end
		if not slideLoopPatch then return end
		if not slideLoopPatch:IsPlaying() then
			slideLoopPatch:PlayEx(cvSlideSoundVolume:GetFloat(), 100)
		else
			slideLoopPatch:ChangeVolume(cvSlideSoundVolume:GetFloat(), 0)
		end
	end

	-- Main slide update function
	local function UpdateSlide()
		if not cvSlideEnable:GetBool() then
			if state.slideActive then
				state.slideActive = false
				net.Start("vrmod_slide_sync")
				net.WriteBool(false)
				net.WriteVector(zeroVec)
				net.SendToServer()
			end

			StopSlideLoopSound()
			return
		end

		if not g_VR or not g_VR.active or not g_VR.tracking then return end
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		if AnyHandHolding() or state.wallRunActive then
			if state.slideActive then
				state.slideActive = false
				net.Start("vrmod_slide_sync")
				net.WriteBool(false)
				net.WriteVector(zeroVec)
				net.SendToServer()
			end

			StopSlideLoopSound()
			return
		end

		local hmd = g_VR.tracking.hmd
		if not hmd then return end
		local plyVel = ply:GetVelocity()
		local flatVel = Vector(plyVel.x, plyVel.y, 0)
		local flatSpeed = flatVel:Length()
		local minSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_min_speed", 90)
		local maxSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_max_speed", 400) -- new max speed
		-- Check if player is crouched below slide height
		local isLow = hmd.pos.z - g_VR.origin.z <= cvSlideHeadHeight:GetFloat()
		local shouldSlide = isLow and flatSpeed >= minSlideSpeed
		-- Update slide state and sounds
		if shouldSlide ~= state.slideActive then
			state.slideActive = shouldSlide
			if shouldSlide then
				PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
				EnsureSlideLoopSound()
			else
				StopSlideLoopSound()
			end
		end

		-- Apply sliding movement and friction
		if state.slideActive then
			-- Clamp velocity to maxSlideSpeed
			if flatSpeed > maxSlideSpeed then
				flatVel:Normalize()
				flatVel = flatVel * maxSlideSpeed
			end

			-- Apply friction scaled by FrameTime
			local frictionPerSecond = GetServerConVarFloat("sv_vrmod_slide_friction") -- units/sec per second, adjust for your scale
			local frictionThisFrame = frictionPerSecond * FrameTime()
			local newSpeed = math.max(flatVel:Length() - frictionThisFrame, 0)
			if newSpeed < minSlideSpeed then
				newSpeed = 0
				state.slideActive = false
				StopSlideLoopSound()
			end

			if flatVel:LengthSqr() > 0.001 then
				flatVel:Normalize()
				flatVel = flatVel * newSpeed
			end

			-- Set new velocity
			ply:SetLocalVelocity(flatVel + Vector(0, 0, plyVel.z))
		end

		-- Send normalized direction to server
		local flatDir = flatVel
		if flatDir:LengthSqr() > 0.001 then flatDir:Normalize() end
		net.Start("vrmod_slide_sync")
		net.WriteBool(state.slideActive)
		net.WriteVector(flatDir)
		net.SendToServer()
	end

	-- Expose functions to ctx
	if isfunction(ctx.setStopSlideLoopSound) then ctx.setStopSlideLoopSound(StopSlideLoopSound) end
	if isfunction(ctx.setEnsureSlideLoopSound) then ctx.setEnsureSlideLoopSound(EnsureSlideLoopSound) end
	if isfunction(ctx.setUpdateSlide) then ctx.setUpdateSlide(UpdateSlide) end
end
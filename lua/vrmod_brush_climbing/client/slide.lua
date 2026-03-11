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

	local function StopSlideLoopSound()
		if slideLoopPatch then
			slideLoopPatch:Stop()
			slideLoopPatch = nil
		end
	end

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
		if not slideLoopPatch then
			slideLoopPatch = CreateSound(ply, slideLoopSoundPath)
		end
		if not slideLoopPatch then return end
		if not slideLoopPatch:IsPlaying() then
			slideLoopPatch:PlayEx(cvSlideSoundVolume:GetFloat(), 100)
		else
			slideLoopPatch:ChangeVolume(cvSlideSoundVolume:GetFloat(), 0)
		end
	end

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
		local vel = ply:GetVelocity()
		local flatSpeed = Vector(vel.x, vel.y, 0):Length()
		local minSlideSpeed = GetServerConVarFloat("sv_vrmod_slide_min_speed", 150)
		local canPlaySlideSound = ply:IsOnGround() and flatSpeed >= minSlideSpeed
		local isLow = (hmd.pos.z - g_VR.origin.z) <= cvSlideHeadHeight:GetFloat()
		if isLow == state.slideActive then
			if isLow and canPlaySlideSound then
				if not (slideLoopPatch and slideLoopPatch:IsPlaying()) then
					PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
				end
				EnsureSlideLoopSound()
			else
				StopSlideLoopSound()
			end
			return
		end
		state.slideActive = isLow
		if isLow and canPlaySlideSound then
			PickSound(slideStartSounds, cvSlideSoundVolume:GetFloat())
			EnsureSlideLoopSound()
		else
			StopSlideLoopSound()
		end
		local flatDir = Vector(vel.x, vel.y, 0)
		if flatDir:LengthSqr() > 0.001 then flatDir:Normalize() end
		net.Start("vrmod_slide_sync")
		net.WriteBool(isLow)
		net.WriteVector(flatDir)
		net.SendToServer()
	end

	if isfunction(ctx.setStopSlideLoopSound) then
		ctx.setStopSlideLoopSound(StopSlideLoopSound)
	end
	if isfunction(ctx.setEnsureSlideLoopSound) then
		ctx.setEnsureSlideLoopSound(EnsureSlideLoopSound)
	end
	if isfunction(ctx.setUpdateSlide) then
		ctx.setUpdateSlide(UpdateSlide)
	end
end

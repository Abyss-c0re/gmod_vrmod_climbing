if SERVER then return end
local presetModule = include("vrmod_climbing/client/presets.lua") or {}
local defaultPresetName = isstring(presetModule.defaultPresetName) and string.Trim(presetModule.defaultPresetName) ~= "" and presetModule.defaultPresetName or "Default"
local cvSelectedPreset = CreateClientConVar("vrmod_brushclimb_selected_preset", defaultPresetName, true, false, "Last selected local VRModClimbing preset")
local PRESET_DATA_DIR = "vrmod_climbing"
local LEGACY_PRESET_DATA_PATH = "vrmod_brushclimb/presets.json"
local PRESET_CVARS = {"vrmod_brushclimb_bind_mode", "vrmod_brushclimb_enable", "vrmod_brushclimb_grab_distance", "vrmod_brushclimb_launch_mult", "vrmod_brushclimb_launch_min", "vrmod_brushclimb_launch_max", "vrmod_brushclimb_sounds", "vrmod_brushclimb_sound_volume", "vrmod_brushclimb_debug", "vrmod_brushclimb_debug_text", "vrmod_brushclimb_hand_inset", "vrmod_brushclimb_wall_push_dist", "vrmod_brushclimb_camera_collision", "vrmod_brushclimb_palm_offset_forward", "vrmod_brushclimb_palm_offset_right", "vrmod_brushclimb_palm_offset_up", "vrmod_brushclimb_palm_offset_forward_right", "vrmod_brushclimb_palm_offset_right_right", "vrmod_brushclimb_palm_offset_up_right", "vrmod_wallrun_enable", "vrmod_wallrun_hand_range", "vrmod_wallrun_bind_mode", "vrmod_wallrun_cooldown", "vrmod_wallrun_air_regen", "vrmod_wallrun_look_max_dot", "vrmod_wallrun_sounds", "vrmod_wallrun_sound_volume", "vrmod_wallrun_sound_interval", "vrmod_brushclimb_allow_walls", "vrmod_brushclimb_allow_ceilings", "vrmod_brushclimb_allow_ledges", "vrmod_brushclimb_allow_floors", "vrmod_brushclimb_allow_doors", "vrmod_brushclimb_allow_pushable", "vrmod_brushclimb_allow_toggleable", "vrmod_brushclimb_allow_ladders", "vrmod_slide_enable", "vrmod_slide_head_height", "vrmod_slide_sounds", "vrmod_slide_sound_volume", "vrmod_brushclimb_assist_enable", "vrmod_brushclimb_assist_strength", "vrmod_brushclimb_doorbash_enable", "vrmod_brushclimb_doorbash_speed", "vrmod_brushclimb_doorbash_range", "vrmod_brushclimb_doorbash_cooldown", "vrmod_brushclimb_armswing_jump_enable", "vrmod_brushclimb_armswing_jump_speed", "vrmod_brushclimb_armswing_jump_cooldown",}
local presetStore = {
    custom = {},
}

local builtinPresets = {}
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

local function SetMirroredClientPermission(cvarName, enabled)
    local cv = GetConVar(cvarName)
    if not cv then return end
    local targetValue = enabled and "1" or "0"
    if cv:GetString() == targetValue then return end
    mirroredClientSyncMute[cvarName] = true
    RunConsoleCommand(cvarName, targetValue)
    timer.Simple(0, function() mirroredClientSyncMute[cvarName] = nil end)
end

local function NotifyPreset(messageText, notifyType)
    if notification and notification.AddLegacy then notification.AddLegacy(messageText, notifyType or NOTIFY_GENERIC, 3) end
    if surface and surface.PlaySound then surface.PlaySound("buttons/button15.wav") end
end

local function CaptureCurrentPresetValues()
    local values = {}
    for i = 1, #PRESET_CVARS do
        local cvarName = PRESET_CVARS[i]
        local cv = GetConVar(cvarName)
        if cv then values[cvarName] = cv:GetString() end
    end
    return values
end

local function SanitizePresetName(name)
    name = string.Trim(tostring(name or ""))
    name = string.gsub(name, "[/\\:*?\"<>|]", "_")
    name = string.gsub(name, "%s+", " ")
    if #name > 48 then name = string.sub(name, 1, 48) end
    return name
end

local function NormalizePresetValues(values)
    if not istable(values) then return nil end
    local out = {}
    for i = 1, #PRESET_CVARS do
        local cvarName = PRESET_CVARS[i]
        if values[cvarName] ~= nil then out[cvarName] = tostring(values[cvarName]) end
    end
    return out
end

local function GetPresetFilePath(name)
    local safeName = SanitizePresetName(name)
    if safeName == "" then return nil, "" end
    return PRESET_DATA_DIR .. "/" .. safeName .. ".txt", safeName
end

local function SavePresetFile(name, values)
    local path, safeName = GetPresetFilePath(name)
    if not path then return false end
    file.CreateDir(PRESET_DATA_DIR)
    local payload = {
        name = safeName,
        values = NormalizePresetValues(values) or {},
    }

    file.Write(path, util.TableToJSON(payload, true))
    return true
end

local function BuildBuiltinPresets()
    local defaults = {}
    for i = 1, #PRESET_CVARS do
        local cvarName = PRESET_CVARS[i]
        local cv = GetConVar(cvarName)
        if cv then defaults[cvarName] = cv:GetDefault() end
    end

    builtinPresets[defaultPresetName] = defaults
    local extra = istable(presetModule.presets) and presetModule.presets or {}
    for presetName, presetValues in pairs(extra) do
        local safeName = SanitizePresetName(presetName)
        if safeName ~= "" then builtinPresets[safeName] = NormalizePresetValues(presetValues) or {} end
    end
end

local function LoadPresetStore()
    presetStore.custom = {}
    local files = file.Find(PRESET_DATA_DIR .. "/*.txt", "DATA")
    for i = 1, #files do
        local fileName = files[i]
        local path = PRESET_DATA_DIR .. "/" .. fileName
        local raw = file.Read(path, "DATA")
        if isstring(raw) and raw ~= "" then
            local parsed = util.JSONToTable(raw)
            if istable(parsed) then
                local inferredName = string.match(fileName, "^(.*)%.txt$") or fileName
                local safeName = SanitizePresetName(parsed.name or inferredName)
                local values = parsed.values
                if not istable(values) then values = parsed end
                if safeName ~= "" and builtinPresets[safeName] == nil then presetStore.custom[safeName] = NormalizePresetValues(values) or {} end
            end
        end
    end

    if file.Exists(LEGACY_PRESET_DATA_PATH, "DATA") then
        local raw = file.Read(LEGACY_PRESET_DATA_PATH, "DATA")
        if isstring(raw) and raw ~= "" then
            local parsed = util.JSONToTable(raw)
            if istable(parsed) and istable(parsed.custom) then
                for name, values in pairs(parsed.custom) do
                    local safeName = SanitizePresetName(name)
                    if safeName ~= "" and builtinPresets[safeName] == nil and not presetStore.custom[safeName] then
                        local normalized = NormalizePresetValues(values) or {}
                        presetStore.custom[safeName] = normalized
                        SavePresetFile(safeName, normalized)
                    end
                end
            end
        end
    end
end

local function IsBuiltinPreset(name)
    return builtinPresets[name] ~= nil
end

local function GetPresetValues(name)
    if builtinPresets[name] then return builtinPresets[name] end
    return presetStore.custom[name]
end

local function GetPresetNames()
    local builtinNames = {}
    local customNames = {}
    for name in pairs(builtinPresets) do
        builtinNames[#builtinNames + 1] = name
    end

    for name in pairs(presetStore.custom) do
        customNames[#customNames + 1] = name
    end

    table.sort(builtinNames, function(a, b) return string.lower(a) < string.lower(b) end)
    table.sort(customNames, function(a, b) return string.lower(a) < string.lower(b) end)
    local names = {}
    for i = 1, #builtinNames do
        names[#names + 1] = builtinNames[i]
    end

    for i = 1, #customNames do
        names[#names + 1] = customNames[i]
    end
    return names
end

local function ApplyPresetValues(values)
    if not istable(values) then return end
    for cvarName, cvarValue in pairs(values) do
        if GetConVar(cvarName) then RunConsoleCommand(cvarName, tostring(cvarValue)) end
    end
end

local function ApplyPresetByName(name)
    local preset = GetPresetValues(name)
    if not preset then return false end
    ApplyPresetValues(preset)
    cvSelectedPreset:SetString(name)
    return true
end

local function SaveCustomPreset(name, values)
    local safeName = SanitizePresetName(name)
    if safeName == "" then return false, "Invalid preset name." end
    if IsBuiltinPreset(safeName) then return false, "This preset name is reserved by addon defaults." end
    local normalized = NormalizePresetValues(values) or {}
    presetStore.custom[safeName] = normalized
    if not SavePresetFile(safeName, normalized) then return false, "Failed to save preset file." end
    return true, safeName
end

local function DeleteCustomPreset(name)
    if IsBuiltinPreset(name) then return false, "Built-in presets cannot be deleted." end
    if not presetStore.custom[name] then return false, "Preset not found." end
    presetStore.custom[name] = nil
    local path = GetPresetFilePath(name)
    if path and file.Exists(path, "DATA") then file.Delete(path) end
    return true
end

BuildBuiltinPresets()
LoadPresetStore()
if not GetPresetValues(SanitizePresetName(cvSelectedPreset:GetString())) and GetPresetValues(defaultPresetName) then cvSelectedPreset:SetString(defaultPresetName) end
local function BuildPresetControls(form)
    if not IsValid(form) then return end
    local row = vgui.Create("DPanel")
    row:SetTall(74)
    row.Paint = function() end
    local label = vgui.Create("DLabel", row)
    label:SetPos(2, 2)
    label:SetSize(120, 20)
    label:SetText("Preset:")
    label:SetColor(Color(0, 0, 0))
    local combo = vgui.Create("DComboBox", row)
    combo:SetPos(56, 0)
    combo:SetSize(330, 22)
    local btnApply = vgui.Create("DButton", row)
    btnApply:SetText("Apply")
    btnApply:SetPos(2, 30)
    btnApply:SetSize(58, 20)
    local btnSave = vgui.Create("DButton", row)
    btnSave:SetText("Save")
    btnSave:SetPos(64, 30)
    btnSave:SetSize(58, 20)
    local btnSaveAs = vgui.Create("DButton", row)
    btnSaveAs:SetText("Save As...")
    btnSaveAs:SetPos(126, 30)
    btnSaveAs:SetSize(84, 20)
    local btnDelete = vgui.Create("DButton", row)
    btnDelete:SetText("Delete")
    btnDelete:SetPos(214, 30)
    btnDelete:SetSize(58, 20)
    local btnReset = vgui.Create("DButton", row)
    btnReset:SetText("Reset")
    btnReset:SetPos(276, 30)
    btnReset:SetSize(58, 20)
    btnReset:SetTooltip("Apply addon default preset.")
    local function getSelectedPresetName()
        local selectedId = combo:GetSelectedID()
        if selectedId then
            local optionData = combo:GetOptionData(selectedId)
            if isstring(optionData) and optionData ~= "" then return optionData end
        end
        return SanitizePresetName(combo:GetText())
    end

    local function fillPresets()
        local old = getSelectedPresetName()
        combo:Clear()
        local names = GetPresetNames()
        local selectedId = nil
        for i = 1, #names do
            local presetName = names[i]
            local suffix = IsBuiltinPreset(presetName) and " [built-in]" or ""
            local newId = combo:AddChoice(presetName .. suffix, presetName)
            if presetName == old then selectedId = newId end
        end

        local selected = SanitizePresetName(cvSelectedPreset:GetString())
        if selected == "" or not GetPresetValues(selected) then selected = defaultPresetName end
        if selected == "" or not GetPresetValues(selected) then selected = old end
        if selected == "" or not GetPresetValues(selected) then selected = GetPresetNames()[1] or "" end
        if selected ~= "" then
            if selectedId == nil then
                for i = 1, #names do
                    if names[i] == selected then
                        selectedId = i
                        break
                    end
                end
            end

            if selectedId ~= nil then
                combo._syncing = true
                combo:ChooseOptionID(selectedId)
                combo._syncing = false
                cvSelectedPreset:SetString(selected)
            end
        end
    end

    combo.OnSelect = function(_, _, _, selectedName)
        if combo._syncing then return end
        if not selectedName or selectedName == "" then return end
        cvSelectedPreset:SetString(selectedName)
    end

    btnApply.DoClick = function()
        local selectedName = getSelectedPresetName()
        if not selectedName or selectedName == "" then
            NotifyPreset("Pick a preset first.", NOTIFY_ERROR)
            return
        end

        if not ApplyPresetByName(selectedName) then
            NotifyPreset("Preset not found.", NOTIFY_ERROR)
            fillPresets()
            return
        end

        NotifyPreset("Applied preset: " .. selectedName, NOTIFY_GENERIC)
    end

    btnSave.DoClick = function()
        local selectedName = getSelectedPresetName()
        if not selectedName or selectedName == "" then
            NotifyPreset("Pick a preset first.", NOTIFY_ERROR)
            return
        end

        if IsBuiltinPreset(selectedName) then
            NotifyPreset("Built-in preset is read-only. Use Save As...", NOTIFY_HINT)
            return
        end

        local ok, result = SaveCustomPreset(selectedName, CaptureCurrentPresetValues())
        if not ok then
            NotifyPreset(result, NOTIFY_ERROR)
            return
        end

        cvSelectedPreset:SetString(result)
        fillPresets()
        NotifyPreset("Saved preset: " .. result, NOTIFY_GENERIC)
    end

    btnSaveAs.DoClick = function()
        Derma_StringRequest("Save preset", "Preset name:", SanitizePresetName(combo:GetText()), function(text)
            local ok, result = SaveCustomPreset(text, CaptureCurrentPresetValues())
            if not ok then
                NotifyPreset(result, NOTIFY_ERROR)
                return
            end

            cvSelectedPreset:SetString(result)
            fillPresets()
            NotifyPreset("Saved preset: " .. result, NOTIFY_GENERIC)
        end)
    end

    btnDelete.DoClick = function()
        local selectedName = getSelectedPresetName()
        if not selectedName or selectedName == "" then
            NotifyPreset("Pick a preset first.", NOTIFY_ERROR)
            return
        end

        Derma_Query("Delete preset '" .. selectedName .. "'?", "Delete preset", "Delete", function()
            local ok, err = DeleteCustomPreset(selectedName)
            if not ok then
                NotifyPreset(err, NOTIFY_ERROR)
                return
            end

            fillPresets()
            NotifyPreset("Deleted preset: " .. selectedName, NOTIFY_GENERIC)
        end, "Cancel")
    end

    btnReset.DoClick = function()
        if ApplyPresetByName(defaultPresetName) then
            fillPresets()
            NotifyPreset("Applied default preset: " .. defaultPresetName, NOTIFY_GENERIC)
        else
            NotifyPreset("Default preset not found.", NOTIFY_ERROR)
        end
    end

    fillPresets()
    form:AddItem(row)
    form:ControlHelp("Presets: choose/apply/save/delete local client presets. Built-in presets come from client/presets.lua.")
end

local function BuildTabMain(form)
    if not IsValid(form) then return end
    BuildPresetControls(form)
    form:ControlHelp("")
    form:Help("[Client] Core toggles")
    form:CheckBox("[Client] Enable VRModClimbing", "vrmod_brushclimb_enable")
    form:CheckBox("[Client] Enable sliding", "vrmod_slide_enable")
    form:CheckBox("[Client] Enable Climb Assist", "vrmod_brushclimb_assist_enable")
    form:CheckBox("[Client] Enable arm-swing jump", "vrmod_brushclimb_armswing_jump_enable")
    form:CheckBox("[Client] Enable door bash", "vrmod_brushclimb_doorbash_enable")
    form:CheckBox("[Client] Play climbing sounds", "vrmod_brushclimb_sounds")
    form:CheckBox("[Client] Play wallrun sounds", "vrmod_wallrun_sounds")
    form:CheckBox("[Client] Play slide sounds", "vrmod_slide_sounds")
    local s = form:NumSlider("[Client] Arm-swing jump speed", "vrmod_brushclimb_armswing_jump_speed", 50, 1200, 0)
    s:SetTooltip("Required upward hand speed for each hand. Jump triggers only on two-hand upward swing.")
    s = form:NumSlider("[Client] Door bash speed", "vrmod_brushclimb_doorbash_speed", 0, 1200, 0)
    s:SetTooltip("Minimum hand speed required to punch-open a door.")
    s = form:NumSlider("[Client] Climb Assist strength", "vrmod_brushclimb_assist_strength", 0, 260, 0)
    s:SetTooltip("Subtle extra release boost when climbing from wall/ledge.")
    form:ControlHelp("")
    form:Help("[Server] Main runtime parameters (admin can edit)")
    local function AddMainServerCheckbox(labelText, cvarName, tooltipText)
        local row = vgui.Create("DCheckBoxLabel")
        row:SetText("[Server] " .. labelText)
        row:SetValue(GetServerConVarBool(cvarName, false) and 1 or 0)
        row:SizeToContents()
        if tooltipText and tooltipText ~= "" then row:SetTooltip(tooltipText) end
        row.OnChange = function(_, val)
            if row._syncing then return end
            if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
            RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, val and "1" or "0")
        end

        row.Think = function(self)
            local desired = GetServerConVarBool(cvarName, false) and 1 or 0
            if self:GetChecked() ~= desired == 1 then
                self._syncing = true
                self:SetValue(desired)
                self._syncing = false
            end
        end

        form:AddItem(row)
    end

    AddMainServerCheckbox("Enable arm-swing jump", "sv_vrmod_armswing_jump_enable", "Server-side permission for hand-swing jumping.")
    AddMainServerCheckbox("Enable door bash", "sv_vrmod_doorbash_enable", "Server-side permission for opening doors via hand impacts.")
    AddMainServerCheckbox("Enable sliding", "sv_vrmod_slide_enable", "Server-side sliding enable.")
    form:ControlHelp("[Server] Wallrun speed and wall-bounce force are in the Wall Run tab.")
end

local function BuildTabClimbing(form)
    if not IsValid(form) then return end
    form:CheckBox("Enable VRModClimbing", "vrmod_brushclimb_enable")
    local bindPanel = vgui.Create("DPanel")
    bindPanel:SetSize(300, 30)
    bindPanel.Paint = function() end
    local label = vgui.Create("DLabel", bindPanel)
    label:SetSize(120, 30)
    label:SetPos(0, -3)
    label:SetText("Grab input mode:")
    label:SetColor(Color(0, 0, 0))
    local combo = vgui.Create("DComboBox", bindPanel)
    combo:Dock(TOP)
    combo:DockMargin(115, 0, 0, 5)
    combo:AddChoice("Grip + Trigger")
    combo:AddChoice("Grip only")
    combo:AddChoice("Trigger only")
    combo.OnSelect = function(_, index) GetConVar("vrmod_brushclimb_bind_mode"):SetInt(index - 1) end
    combo.Think = function(self)
        local mode = GetConVar("vrmod_brushclimb_bind_mode"):GetInt()
        if self._mode ~= mode then
            self._mode = mode
            self:ChooseOptionID(mode + 1)
        end
    end

    form:AddItem(bindPanel)
    form:ControlHelp("Physics")
    local tmp = form:NumSlider("Grab distance", "vrmod_brushclimb_grab_distance", 4, 48, 0)
    tmp:SetTooltip("How far from your hand a brush can be grabbed.")
    tmp = form:NumSlider("Launch multiplier", "vrmod_brushclimb_launch_mult", 0, 4, 2)
    tmp:SetTooltip("Scales launch force from opposite hand velocity.")
    tmp = form:NumSlider("Launch minimum speed", "vrmod_brushclimb_launch_min", 0, 500, 0)
    tmp:SetTooltip("No launch below this hand speed.")
    tmp = form:NumSlider("Launch max speed", "vrmod_brushclimb_launch_max", 0, 1500, 0)
    tmp:SetTooltip("Clamp for launch speed.")
    tmp = form:NumSlider("Hand surface inset", "vrmod_brushclimb_hand_inset", 0, 4, 1)
    tmp:SetTooltip("Push held hand slightly into surfaces for tighter contact.")
    tmp = form:NumSlider("Wall body push distance", "vrmod_brushclimb_wall_push_dist", 0, 12, 1)
    tmp:SetTooltip("Keeps your body slightly away from walls while holding.")
    tmp = form:CheckBox("Camera anti-clip while climbing", "vrmod_brushclimb_camera_collision")
    tmp:SetTooltip("Pushes camera away from brushes while you are holding a climb point.")
    form:ControlHelp("")
    form:ControlHelp("Palm Offsets")
    form:NumSlider("Left palm offset forward", "vrmod_brushclimb_palm_offset_forward", -8, 8, 2)
    form:NumSlider("Left palm offset right", "vrmod_brushclimb_palm_offset_right", -8, 8, 2)
    form:NumSlider("Left palm offset up", "vrmod_brushclimb_palm_offset_up", -8, 8, 2)
    form:NumSlider("Right palm offset forward", "vrmod_brushclimb_palm_offset_forward_right", -8, 8, 2)
    form:NumSlider("Right palm offset right", "vrmod_brushclimb_palm_offset_right_right", -8, 8, 2)
    form:NumSlider("Right palm offset up", "vrmod_brushclimb_palm_offset_up_right", -8, 8, 2)
    form:ControlHelp("")
    form:ControlHelp("Surface Filters  (server may restrict further)")
    form:CheckBox("Allow grabbing walls", "vrmod_brushclimb_allow_walls"):SetTooltip("Allow grabbing near-vertical surfaces.")
    form:CheckBox("Allow grabbing ceilings", "vrmod_brushclimb_allow_ceilings"):SetTooltip("Allow grabbing downward-facing surfaces.")
    form:CheckBox("Allow grabbing ledges", "vrmod_brushclimb_allow_ledges"):SetTooltip("Allow grabbing slanted upward surfaces between wall and floor.")
    form:CheckBox("Allow grabbing floors", "vrmod_brushclimb_allow_floors"):SetTooltip("Allow grabbing nearly-flat upward surfaces (floors).")
    form:ControlHelp("")
    form:ControlHelp("Entity Filters  (server may restrict further)")
    form:CheckBox("Allow grabbing doors", "vrmod_brushclimb_allow_doors"):SetTooltip("Allow func_door, func_door_rotating and prop_door_rotating to be grabbed.")
    form:CheckBox("Allow grabbing pushables", "vrmod_brushclimb_allow_pushable"):SetTooltip("Allow func_pushable entities to be grabbed.")
    form:CheckBox("Allow grabbing toggleable brushes", "vrmod_brushclimb_allow_toggleable"):SetTooltip("Allow func_button, func_rot_button, momentary_rot_button and momentary_door to be grabbed.")
    form:CheckBox("Allow grabbing ladders", "vrmod_brushclimb_allow_ladders"):SetTooltip("Allow grabbing ladder surfaces (func_ladder, func_climbable, CONTENTS_LADDER). Ladders always bypass surface-type filters when enabled.")
    form:ControlHelp("")
    form:ControlHelp("Debug")
    form:CheckBox("Play climbing sounds", "vrmod_brushclimb_sounds")
    form:NumSlider("Climb sound volume", "vrmod_brushclimb_sound_volume", 0, 1, 2)
    form:CheckBox("Debug draw (grab cube + traces)", "vrmod_brushclimb_debug")
    form:CheckBox("Debug text above hands", "vrmod_brushclimb_debug_text")
end

local function BuildTabWallRun(form)
    if not IsValid(form) then return end
    form:CheckBox("Enable wall running", "vrmod_wallrun_enable")
    local function AddServerLiveSlider(labelText, cvarName, minValue, maxValue, decimals, tooltipText)
        local row = vgui.Create("DNumSlider")
        row:SetText("[Server] " .. labelText)
        row:SetMin(minValue)
        row:SetMax(maxValue)
        row:SetDecimals(decimals or 0)
        row:SetValue(GetServerConVarFloat(cvarName, minValue))
        if tooltipText and tooltipText ~= "" then row:SetTooltip(tooltipText) end
        row.OnValueChanged = function(_, val)
            if row._syncing then return end
            if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
            RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, tostring(val))
        end

        row.Think = function(self)
            local current = GetServerConVarFloat(cvarName, minValue)
            if math.abs((self:GetValue() or 0) - current) > 0.001 then
                self._syncing = true
                self:SetValue(current)
                self._syncing = false
            end
        end

        form:AddItem(row)
    end

    local wrBindPanel = vgui.Create("DPanel")
    wrBindPanel:SetSize(300, 30)
    wrBindPanel.Paint = function() end
    local wrLabel = vgui.Create("DLabel", wrBindPanel)
    wrLabel:SetSize(120, 30)
    wrLabel:SetPos(0, -3)
    wrLabel:SetText("Wall run bind:")
    wrLabel:SetColor(Color(0, 0, 0))
    local wrCombo = vgui.Create("DComboBox", wrBindPanel)
    wrCombo:Dock(TOP)
    wrCombo:DockMargin(115, 0, 0, 5)
    wrCombo:AddChoice("Grip")
    wrCombo:AddChoice("Trigger")
    wrCombo.OnSelect = function(_, index) GetConVar("vrmod_wallrun_bind_mode"):SetInt(index - 1) end
    wrCombo.Think = function(self)
        local mode = GetConVar("vrmod_wallrun_bind_mode"):GetInt()
        if self._mode ~= mode then
            self._mode = mode
            self:ChooseOptionID(mode + 1)
        end
    end

    form:AddItem(wrBindPanel)
    local wr = form:NumSlider("Hand range", "vrmod_wallrun_hand_range", 4, 48, 0)
    wr:SetTooltip("How close your hand must be to a wall to trigger wall running.")
    wr = form:NumSlider("Cooldown", "vrmod_wallrun_cooldown", 0, 5, 1)
    wr:SetTooltip("Seconds before wall run can activate again after ending.")
    wr = form:NumSlider("Airborne cooldown regen", "vrmod_wallrun_air_regen", 0, 10, 1)
    wr:SetTooltip("How fast the cooldown recovers while airborne (seconds/second). Landing always resets it instantly.")
    wr = form:NumSlider("Look-along strictness", "vrmod_wallrun_look_max_dot", 0, 1, 2)
    wr:SetTooltip("Lower value = must look more along the wall. Higher value = easier activation.")
    AddServerLiveSlider("Wallrun speed", "sv_vrmod_wallrun_speed", 80, 1000, 0, "Target movement speed while wallrunning.")
    AddServerLiveSlider("Wall bounce force", "sv_vrmod_wallrun_bounce_force", 0, 900, 0, "Force pushing away from wall when jumping off it.")
    form:CheckBox("Play wallrun sounds", "vrmod_wallrun_sounds")
    wr = form:NumSlider("Wallrun sound volume", "vrmod_wallrun_sound_volume", 0, 1, 2)
    wr:SetTooltip("Wallrun sound loudness.")
    wr = form:NumSlider("Wallrun step interval", "vrmod_wallrun_sound_interval", 0.05, 1, 2)
    wr:SetTooltip("Delay between wallrun step sounds.")
end

local function BuildTabSlide(form)
    if not IsValid(form) then return end
    form:CheckBox("Enable sliding", "vrmod_slide_enable")
    local sh = form:NumSlider("Slide head height threshold", "vrmod_slide_head_height", 4, 120, 0)
    sh:SetTooltip("HMD height above feet (units) at which you count as low enough to slide. Sliding only activates while in VR.")
    form:CheckBox("Play slide sounds", "vrmod_slide_sounds")
    sh = form:NumSlider("Slide sound volume", "vrmod_slide_sound_volume", 0, 1, 2)
    sh:SetTooltip("Slide sound loudness.")
    -- New friction slider
    sh = form:NumSlider("Slide friction", "sv_vrmod_slide_friction", 0, 600, 0)
    sh:SetTooltip("Friction applied while sliding. Higher values slow down the slide.")
end

local function BuildTabbedSettings(parent)
    local sheet = vgui.Create("DPropertySheet", parent)
    sheet:Dock(FILL)
    sheet:DockMargin(2, 2, 2, 2)
    local function MakeTab(name, buildFn)
        local panel = vgui.Create("DPanel", sheet)
        panel:Dock(FILL)
        panel.Paint = function() end
        local scroll = vgui.Create("DScrollPanel", panel)
        scroll:Dock(FILL)
        local form = vgui.Create("DForm", scroll)
        form:SetName(name)
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function() end
        buildFn(form)
        sheet:AddSheet(name, panel)
    end

    MakeTab("Main", BuildTabMain)
    MakeTab("Climbing", BuildTabClimbing)
    MakeTab("Wall Run", BuildTabWallRun)
    MakeTab("Slide", BuildTabSlide)
end

local climbSettingsFrame = nil
local function OpenClimbSettingsWindow()
    if IsValid(climbSettingsFrame) then
        climbSettingsFrame:MakePopup()
        climbSettingsFrame:Center()
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(450, 580)
    frame:SetTitle("VRModClimbing")
    frame:MakePopup()
    frame:Center()
    climbSettingsFrame = frame
    function frame:OnRemove()
        climbSettingsFrame = nil
    end

    BuildTabbedSettings(frame)
end

concommand.Add("vrmod_brushclimb_menu", function() OpenClimbSettingsWindow() end)
hook.Add("VRMod_Menu", "vrmod_brush_climbing_menu", function(frame)
    if IsValid(frame.DPropertySheet) then
        local panel = vgui.Create("DPanel", frame.DPropertySheet)
        panel:Dock(FILL)
        BuildTabbedSettings(panel)
        frame.DPropertySheet:AddSheet("VRClimb", panel)
        return
    end

    local form = frame.SettingsForm
    if not IsValid(form) then return end
    form:ControlHelp("VRClimb - Main")
    BuildTabMain(form)
    form:ControlHelp("VRClimb - Climbing")
    BuildTabClimbing(form)
    form:ControlHelp("VRClimb - Wall Run")
    BuildTabWallRun(form)
    form:ControlHelp("VRClimb - Slide")
    BuildTabSlide(form)
end)

local function EnsureQuickMenuItem()
    if not vrmod or not vrmod.AddInGameMenuItem then return end
    vrmod.AddInGameMenuItem("VRClimb", 5, 3, function() RunConsoleCommand("vrmod_brushclimb_menu") end)
end

hook.Add("VRMod_Start", "vrmod_brush_climbing_menu_button", function(ply)
    if ply ~= LocalPlayer() then return end
    EnsureQuickMenuItem()
end)

timer.Simple(0, EnsureQuickMenuItem)
local function AddAdminCheckbox(form, labelText, cvarName, tooltipText)
    local mirroredClientCvarName = MIRRORED_PERMISSION_SERVER_CVARS[cvarName]
    local row = vgui.Create("DCheckBoxLabel")
    row:SetText(labelText)
    row:SetValue(GetServerConVarBool(cvarName, false) and 1 or 0)
    row:SizeToContents()
    if tooltipText and tooltipText ~= "" then row:SetTooltip(tooltipText) end
    row.OnChange = function(_, val)
        if row._syncing then return end
        if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
        if mirroredClientCvarName then SetMirroredClientPermission(mirroredClientCvarName, val) end
        RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, val and "1" or "0")
    end

    row.Think = function(self)
        local desired = GetServerConVarBool(cvarName, false) and 1 or 0
        if self:GetChecked() ~= desired == 1 then
            self._syncing = true
            self:SetValue(desired)
            self._syncing = false
        end

        if mirroredClientCvarName and IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then SetMirroredClientPermission(mirroredClientCvarName, desired == 1) end
    end

    form:AddItem(row)
end

local function AddAdminSlider(form, labelText, cvarName, minValue, maxValue, decimals, tooltipText)
    local row = vgui.Create("DNumSlider")
    row:SetText(labelText)
    row:SetMin(minValue)
    row:SetMax(maxValue)
    row:SetDecimals(decimals or 0)
    row:SetValue(GetServerConVarFloat(cvarName, minValue))
    if tooltipText and tooltipText ~= "" then row:SetTooltip(tooltipText) end
    row.OnValueChanged = function(_, val)
        if row._syncing then return end
        if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
        RunConsoleCommand("vrmod_brushclimb_admin_set", cvarName, tostring(val))
    end

    row.Think = function(self)
        local current = GetServerConVarFloat(cvarName, minValue)
        if math.abs((self:GetValue() or 0) - current) > 0.001 then
            self._syncing = true
            self:SetValue(current)
            self._syncing = false
        end
    end

    form:AddItem(row)
end

hook.Add("PopulateToolMenu", "vrmod_brush_climbing_admin_utilities", function()
    spawnmenu.AddToolCategory("Utilities", "VRModClimbing", "VRModClimbing")
    -- Climbing tab
    spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_Climbing", "Climbing", "", "", function(panel)
        panel:ClearControls()
        local form = vgui.Create("DForm", panel)
        form:SetName("Climbing")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function() end
        BuildTabClimbing(form)
        form:ControlHelp("")
        if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
            form:Help("Server parameters can be changed only by admins.")
        else
            form:Help("Admin: Surface Permissions (set the ceiling for all clients)")
        end

        AddAdminCheckbox(form, "Allow walls", "sv_vrmod_brushclimb_allow_walls", "Permit clients to grab wall surfaces.")
        AddAdminCheckbox(form, "Allow ceilings", "sv_vrmod_brushclimb_allow_ceilings", "Permit clients to grab ceiling surfaces.")
        AddAdminCheckbox(form, "Allow ledges", "sv_vrmod_brushclimb_allow_ledges", "Permit clients to grab ledge surfaces.")
        AddAdminCheckbox(form, "Allow floors", "sv_vrmod_brushclimb_allow_floors", "Permit clients to grab floor surfaces.")
        AddAdminCheckbox(form, "Allow doors", "sv_vrmod_brushclimb_allow_doors", "Permit clients to grab door entities.")
        AddAdminCheckbox(form, "Allow pushables", "sv_vrmod_brushclimb_allow_pushable", "Permit clients to grab func_pushable entities.")
        AddAdminCheckbox(form, "Allow toggleable brushes", "sv_vrmod_brushclimb_allow_toggleable", "Permit clients to grab func_button, etc.")
        form:ControlHelp("")
        form:Help("Admin: Behaviour")
        AddAdminCheckbox(form, "Reduce collider while climbing", "sv_vrmod_brushclimb_reduce_collider", "Keep duck hull while climbing and after release.")
        AddAdminCheckbox(form, "Enable door bash", "sv_vrmod_doorbash_enable", "Allow opening doors with high-speed hand impacts.")
        AddAdminSlider(form, "Door bash cooldown", "sv_vrmod_doorbash_open_cooldown", 0.03, 1.0, 2, "Minimum time between door bash activations.")
        AddAdminSlider(form, "Door bash impact volume", "sv_vrmod_doorbash_sound_volume", 0.0, 1.0, 2, "Volume of the extra impact sound on door bash.")
        AddAdminCheckbox(form, "Enable arm-swing jump", "sv_vrmod_armswing_jump_enable", "Allow jumping from upward two-hand swings.")
        AddAdminSlider(form, "Arm-swing jump power", "sv_vrmod_armswing_jump_power", 80, 500, 0, "Vertical jump force applied by arm swing.")
        AddAdminSlider(form, "Arm-swing forward boost", "sv_vrmod_armswing_forward_boost", 0, 300, 0, "Extra forward speed added by arm swing jump.")
        AddAdminSlider(form, "Arm-swing jump cooldown", "sv_vrmod_armswing_jump_cooldown", 0.05, 1.0, 2, "Minimum delay between arm-swing jumps.")
        form:ControlHelp("")
        form:Help("Admin: Surface Thresholds")
        AddAdminSlider(form, "Ledge normal min Z", "sv_vrmod_brushclimb_ledge_normal_min", 0, 1, 2, "Minimum normal Z for a surface to be a ledge (vs wall).")
        AddAdminSlider(form, "Floor normal min Z", "sv_vrmod_brushclimb_floor_normal_min", 0, 1, 2, "Minimum normal Z for a surface to be a floor (vs ledge).")
        AddAdminSlider(form, "Ceiling normal max Z", "sv_vrmod_brushclimb_ceil_normal_max", -1, 0, 2, "Maximum normal Z for a surface to be a ceiling (vs wall).")
        panel:AddItem(form)
    end)

    -- Wall Run tab
    spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_WallRun", "Wall Run", "", "", function(panel)
        panel:ClearControls()
        local form = vgui.Create("DForm", panel)
        form:SetName("Wall Run")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function() end
        BuildTabWallRun(form)
        form:ControlHelp("")
        if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
            form:Help("Server parameters can be changed only by admins.")
        else
            form:Help("Admin server parameters (replicated to clients).")
        end

        AddAdminSlider(form, "Jump force", "sv_vrmod_wallrun_jump_force", 50, 800, 0, "Launch force when jumping off wall.")
        AddAdminSlider(form, "Wall push force", "sv_vrmod_wallrun_wall_force", 10, 400, 0, "Force keeping player pressed into wall.")
        AddAdminSlider(form, "Free time (seconds)", "sv_vrmod_wallrun_free_time", 0, 5, 1, "Seconds before gravity starts building.")
        AddAdminSlider(form, "Fall rate", "sv_vrmod_wallrun_fall_rate", 0, 500, 0, "Downward acceleration after free time.")
        AddAdminSlider(form, "Max fall speed", "sv_vrmod_wallrun_max_fall_speed", 0, 800, 0, "Maximum downward speed on wall.")
        AddAdminSlider(form, "Wallrun speed", "sv_vrmod_wallrun_speed", 80, 1000, 0, "Target horizontal speed while wallrunning.")
        AddAdminSlider(form, "Wall bounce force", "sv_vrmod_wallrun_bounce_force", 0, 900, 0, "Extra push away from wall on wallrun jump.")
        AddAdminSlider(form, "Speed transfer grace", "sv_vrmod_wallrun_speed_grace", 0, 1, 2, "Seconds to blend direction on wall contact.")
        AddAdminSlider(form, "Min jump contact time", "sv_vrmod_wallrun_min_jump_time", 0, 1, 2, "Min seconds on wall before wallrun jump fires.")
        panel:AddItem(form)
    end)

    -- Slide tab
    spawnmenu.AddToolMenuOption("Utilities", "VRModClimbing", "VRModClimbing_Slide", "Slide", "", "", function(panel)
        panel:ClearControls()
        local form = vgui.Create("DForm", panel)
        form:SetName("Slide")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function() end
        BuildTabSlide(form)
        form:ControlHelp("")
        if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then
            form:Help("Server parameters can be changed only by admins.")
        else
            form:Help("Admin server parameters (replicated to clients).")
        end

        AddAdminCheckbox(form, "Enable sliding", "sv_vrmod_slide_enable", "Allow players to slide when crouching at speed. VR only.")
        AddAdminSlider(form, "Min entry speed", "sv_vrmod_slide_min_speed", 0, 800, 0, "Minimum horizontal speed to start a slide.")
        AddAdminSlider(form, "Entry boost", "sv_vrmod_slide_entry_boost", 0, 600, 0, "Flat speed bonus at slide start.")
        AddAdminSlider(form, "Slide friction", "sv_vrmod_slide_friction", 0, 600, 0, "Horizontal deceleration (units/s^2).")
        AddAdminSlider(form, "Stop speed", "sv_vrmod_slide_stop_speed", 0, 400, 0, "Speed below which slide ends.")
        AddAdminSlider(form, "Air-landing boost", "sv_vrmod_slide_air_boost", 0, 600, 0, "Extra speed when landing into a slide from air.")
        panel:AddItem(form)
    end)
end)
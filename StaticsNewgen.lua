--[[
    STATICS NEWGEN - CLIENT
    Place in StarterPlayer > StarterPlayerScripts as a LocalScript.

    This is an in-game system for your own experience. It uses PlayerGui and
    ordinary Roblox services; it does not use executor APIs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera
local originalCameraFOV = camera and camera.FieldOfView or 70
local isLocalVR = VRService.VREnabled
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not isLocalVR
local deviceClass = isLocalVR and "VR" or (isMobile and "Mobile" or "PC")
local mainBaseSize = isMobile and Vector2.new(640, 760) or Vector2.new(820, 520)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		camera = Workspace.CurrentCamera
		originalCameraFOV = camera.FieldOfView
	end
end)

-- Never block the UI on networking. If the server starts late, connect in the
-- background while the complete menu remains usable.
local remotes = ReplicatedStorage:FindFirstChild("StaticsNewgenRemotes")
local ClientStatus = remotes and remotes:FindFirstChild("ClientStatus")
local RoleSync = remotes and remotes:FindFirstChild("RoleSync")
local HopRequest = remotes and remotes:FindFirstChild("HopRequest")
local ResetRequest = remotes and remotes:FindFirstChild("ResetRequest")
local ActionFeedback = remotes and remotes:FindFirstChild("ActionFeedback")

if ClientStatus then
	ClientStatus:FireServer({ vr = isLocalVR, mobile = isMobile, device = deviceClass })
end

local COLORS = {
	bg = Color3.fromRGB(14, 14, 20),
	panel = Color3.fromRGB(21, 22, 30),
	panel2 = Color3.fromRGB(28, 29, 39),
	line = Color3.fromRGB(53, 55, 70),
	text = Color3.fromRGB(239, 240, 247),
	muted = Color3.fromRGB(139, 142, 160),
	purple = Color3.fromRGB(139, 92, 246),
	cyan = Color3.fromRGB(34, 211, 238),
	green = Color3.fromRGB(52, 211, 153),
	red = Color3.fromRGB(248, 75, 90),
	yellow = Color3.fromRGB(250, 204, 70),
}

-- Three complete visual systems based on the supplied references. They only
-- change presentation; every control keeps the same behavior and state.
local THEMES = {
	DarkDock = {
		DisplayName = "Dark Dock",
		Description = "Rounded two-column layout",
		bg = Color3.fromRGB(10, 10, 12),
		panel = Color3.fromRGB(25, 25, 27),
		panel2 = Color3.fromRGB(43, 43, 46),
		top = Color3.fromRGB(13, 13, 15),
		sidebar = Color3.fromRGB(14, 14, 16),
		line = Color3.fromRGB(67, 68, 72),
		text = Color3.fromRGB(244, 244, 246),
		muted = Color3.fromRGB(163, 164, 169),
		accent = Color3.fromRGB(42, 201, 104),
		secondary = Color3.fromRGB(41, 157, 225),
		success = Color3.fromRGB(42, 201, 104),
		danger = Color3.fromRGB(238, 79, 91),
		warning = Color3.fromRGB(244, 194, 63),
		Radius = 1.15,
		BodyFont = Enum.Font.Gotham,
		HeaderFont = Enum.Font.GothamBold,
	},
	Skeet = {
		DisplayName = "Skeet Compact",
		Description = "Dense, sharp, lime-accented",
		bg = Color3.fromRGB(17, 15, 18),
		panel = Color3.fromRGB(24, 22, 25),
		panel2 = Color3.fromRGB(31, 29, 32),
		top = Color3.fromRGB(24, 21, 25),
		sidebar = Color3.fromRGB(19, 17, 20),
		line = Color3.fromRGB(48, 45, 50),
		text = Color3.fromRGB(231, 229, 232),
		muted = Color3.fromRGB(137, 132, 140),
		accent = Color3.fromRGB(107, 164, 51),
		secondary = Color3.fromRGB(142, 194, 71),
		success = Color3.fromRGB(116, 186, 58),
		danger = Color3.fromRGB(203, 69, 78),
		warning = Color3.fromRGB(209, 169, 57),
		Radius = 0.38,
		BodyFont = Enum.Font.Code,
		HeaderFont = Enum.Font.GothamBold,
	},
	Emerald = {
		DisplayName = "Emerald Stack",
		Description = "Layered stats with glass glow",
		bg = Color3.fromRGB(16, 18, 18),
		panel = Color3.fromRGB(31, 33, 32),
		panel2 = Color3.fromRGB(47, 48, 46),
		top = Color3.fromRGB(30, 31, 30),
		sidebar = Color3.fromRGB(24, 26, 25),
		line = Color3.fromRGB(71, 75, 72),
		text = Color3.fromRGB(242, 243, 241),
		muted = Color3.fromRGB(143, 147, 143),
		accent = Color3.fromRGB(52, 211, 153),
		secondary = Color3.fromRGB(93, 224, 179),
		success = Color3.fromRGB(52, 211, 153),
		danger = Color3.fromRGB(201, 86, 91),
		warning = Color3.fromRGB(224, 184, 74),
		Radius = 0.72,
		BodyFont = Enum.Font.Gotham,
		HeaderFont = Enum.Font.GothamBold,
	},
}

local activeThemeName = "DarkDock"
local activeTheme = THEMES[activeThemeName]
local ORIGINAL_PALETTE = table.clone(COLORS)

local function paletteRole(color)
	if color == COLORS.bg then return "bg" end
	if color == COLORS.panel then return "panel" end
	if color == COLORS.panel2 then return "panel2" end
	if color == COLORS.line then return "line" end
	if color == COLORS.text then return "text" end
	if color == COLORS.muted then return "muted" end
	if color == COLORS.purple then return "accent" end
	if color == COLORS.cyan then return "secondary" end
	if color == COLORS.green then return "success" end
	if color == COLORS.red then return "danger" end
	if color == COLORS.yellow then return "warning" end
	if color == ORIGINAL_PALETTE.bg then return "bg" end
	if color == ORIGINAL_PALETTE.panel then return "panel" end
	if color == ORIGINAL_PALETTE.panel2 then return "panel2" end
	if color == ORIGINAL_PALETTE.line then return "line" end
	if color == ORIGINAL_PALETTE.text then return "text" end
	if color == ORIGINAL_PALETTE.muted then return "muted" end
	if color == ORIGINAL_PALETTE.purple then return "accent" end
	if color == ORIGINAL_PALETTE.cyan then return "secondary" end
	if color == ORIGINAL_PALETTE.green then return "success" end
	if color == ORIGINAL_PALETTE.red then return "danger" end
	if color == ORIGINAL_PALETTE.yellow then return "warning" end
	return nil
end

local ROLE_COLORS = {
	Innocent = Color3.fromRGB(72, 186, 255),
	Detective = Color3.fromRGB(52, 211, 153),
	Traitor = Color3.fromRGB(248, 75, 90),
}

local config = {
	AimEnabled = true,
	StickyAim = true,
	VisibleCheck = true,
	TeamCheck = true,
	AimStrength = 0.38,
	LockRadius = 210,
	LockBreakMultiplier = 2.25,
	StickyGrace = 0.65,
	PredictionEnabled = true,
	PredictionTime = 0.085,
	AutoRetarget = true,
	AimDeadzone = 1.5,
	MaxAimDistance = 650,
	WeaponConeDegrees = 16,
	WeaponStickyConeDegrees = 30,
	VRAimEnabled = true,
	VRAimStrength = 0.46,
	VRConeDegrees = 20,
	VRStickyConeDegrees = 34,
	VRStickyGrace = 0.8,
	CameraFOV = 78,
	FOVOverride = true,
	TargetPart = "Head",
	ShowLockRadius = true,
	ESPEnabled = true,
	Highlights = true,
	Nameplates = true,
	ShowDistance = true,
	ShowRoles = true,
	ShowVR = true,
	HealthBars = true,
	Tracers = false,
	ESPTeamCheck = true,
	ThroughWalls = true,
	MaxESPDistance = 850,
	ESPTextSize = isLocalVR and 18 or 14,
	ESPFillTransparency = 0.72,
	ESPColorMode = "Role",
	PerformanceMode = "Off",
}

local knownRoles = {}
local roundMeta = { state = "Waiting", timeLeft = 0 }
local currentTarget = nil
local weaponTarget = nil
local vrWeaponTarget = nil
local lastWeaponValidAt = 0
local lastVRWeaponValidAt = 0
local lastStandardAdapterCall = 0
local lastVRAdapterCall = 0
local selectedPlayer = nil
local aimEngaged = false
local targetAcquiredForEngagement = false
local lastTargetValidAt = 0
local visuals = {}
local pages = {}
local navButtons = {}
local UI = {}
local currentPage = "Home"
local themeCards = {}
local applyTheme
local actionStatusLabel = nil
local actionMessage = "Session actions are ready."
local actionMessageOkay = true

local function setAimEngaged(value)
	aimEngaged = value
	if value then
		targetAcquiredForEngagement = currentTarget ~= nil
		lastTargetValidAt = os.clock()
	else
		currentTarget = nil
		if not isLocalVR then weaponTarget = nil end
		targetAcquiredForEngagement = false
	end
end

local roleConnection
local feedbackConnection
local function connectRoleSync(remote)
	if roleConnection then roleConnection:Disconnect() end
	RoleSync = remote
	roleConnection = remote.OnClientEvent:Connect(function(view, meta)
		knownRoles = typeof(view) == "table" and view or {}
		roundMeta = typeof(meta) == "table" and meta or roundMeta
	end)
end

local function showActionMessage(message, okay)
	actionMessage = tostring(message)
	actionMessageOkay = okay ~= false
	if actionStatusLabel then
		actionStatusLabel.Text = actionMessage
		actionStatusLabel.TextColor3 = actionMessageOkay and COLORS.green or COLORS.red
	end
end

local function connectFeedback(remote)
	if feedbackConnection then feedbackConnection:Disconnect() end
	ActionFeedback = remote
	feedbackConnection = remote.OnClientEvent:Connect(showActionMessage)
end

if RoleSync then connectRoleSync(RoleSync) end
if ActionFeedback then connectFeedback(ActionFeedback) end

task.spawn(function()
	if RoleSync and ClientStatus and HopRequest and ResetRequest and ActionFeedback then return end
	local lateFolder = ReplicatedStorage:WaitForChild("StaticsNewgenRemotes", 10)
	if not lateFolder then
		warn("[Statics Newgen] StaticsServer was not found. UI is running without role/VR sync.")
		return
	end
	local lateStatus = lateFolder:WaitForChild("ClientStatus", 3)
	local lateRoleSync = lateFolder:WaitForChild("RoleSync", 3)
	local lateHop = lateFolder:WaitForChild("HopRequest", 3)
	local lateReset = lateFolder:WaitForChild("ResetRequest", 3)
	local lateFeedback = lateFolder:WaitForChild("ActionFeedback", 3)
	if lateStatus then
		ClientStatus = lateStatus
		ClientStatus:FireServer({ vr = isLocalVR, mobile = isMobile, device = deviceClass })
	end
	if lateRoleSync and lateRoleSync ~= RoleSync then connectRoleSync(lateRoleSync) end
	if lateHop then HopRequest = lateHop end
	if lateReset then ResetRequest = lateReset end
	if lateFeedback and lateFeedback ~= ActionFeedback then connectFeedback(lateFeedback) end
end)

--============================================================ UI HELPERS
local function corner(instance, radius)
	local value = Instance.new("UICorner")
	local baseRadius = radius or 8
	value:SetAttribute("BaseRadius", baseRadius)
	value.CornerRadius = UDim.new(0, math.max(1, math.floor(baseRadius * activeTheme.Radius + 0.5)))
	value.Parent = instance
	return value
end

local function stroke(instance, color, transparency, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color or COLORS.line
	value:SetAttribute("ThemeColorRole", paletteRole(value.Color) or "line")
	value.Transparency = transparency or 0
	value.Thickness = thickness or 1
	value.Parent = instance
	return value
end

local function text(parent, value, size, position, font, color, textSize)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position or UDim2.new()
	label.Font = font or Enum.Font.Gotham
	label.Text = value or ""
	label.TextColor3 = color or COLORS.text
	label:SetAttribute("ThemeTextRole", paletteRole(label.TextColor3) or "text")
	label:SetAttribute("ThemeHeader", (font == Enum.Font.GothamBlack or font == Enum.Font.GothamBold) and true or false)
	label.TextSize = textSize or 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function panel(parent, size, position)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = COLORS.panel
	frame:SetAttribute("ThemeBackgroundRole", "panel")
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, 12)
	stroke(frame, COLORS.line, 0.35, 1)
	return frame
end

local function scrollPanel(parent, size, position, canvasHeight)
	local frame = Instance.new("ScrollingFrame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = COLORS.panel
	frame:SetAttribute("ThemeBackgroundRole", "panel")
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 3
	frame.ScrollBarImageColor3 = COLORS.purple
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.CanvasSize = UDim2.fromOffset(0, canvasHeight)
	frame.Parent = parent
	corner(frame, 12)
	stroke(frame, COLORS.line, 0.35, 1)
	return frame
end

local function button(parent, title, size, position, color)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = color or COLORS.panel2
	btn:SetAttribute("ThemeBackgroundRole", paletteRole(btn.BackgroundColor3) or "panel2")
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamBold
	btn.Text = title
	btn.TextColor3 = COLORS.text
	btn:SetAttribute("ThemeTextRole", "text")
	btn:SetAttribute("ThemeHeader", true)
	btn.TextSize = 13
	btn.Parent = parent
	corner(btn, 8)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.12 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
	end)
	return btn
end

local function makeToggle(parent, title, y, getter, setter)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, 42)
	row.Position = UDim2.fromOffset(12, y)
	row.BackgroundColor3 = COLORS.panel2
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 8)

	text(row, title, UDim2.new(1, -76, 1, 0), UDim2.fromOffset(12, 0), Enum.Font.GothamMedium, COLORS.text, 13)

	local track = button(row, "", UDim2.fromOffset(44, 24), UDim2.new(1, -56, 0.5, -12), COLORS.line)
	corner(track, 12)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18, 18)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Parent = track
	corner(knob, 9)

	local function refresh(instant)
		local enabled = getter()
		local knobPosition = enabled and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
		local trackColor = enabled and COLORS.purple or COLORS.line
		track:SetAttribute("ThemeBackgroundRole", enabled and "accent" or "line")
		if instant then
			knob.Position = knobPosition
			track.BackgroundColor3 = trackColor
		else
			TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quart), { Position = knobPosition }):Play()
			TweenService:Create(track, TweenInfo.new(0.16), { BackgroundColor3 = trackColor }):Play()
		end
	end

	track.Activated:Connect(function()
		setter(not getter())
		refresh(false)
	end)
	refresh(true)
	return row, refresh
end

local function makeSlider(parent, title, y, minimum, maximum, getter, setter, formatter)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -24, 0, 58)
	holder.Position = UDim2.fromOffset(12, y)
	holder.BackgroundColor3 = COLORS.panel2
	holder.BorderSizePixel = 0
	holder.Parent = parent
	corner(holder, 8)

	text(holder, title, UDim2.new(1, -90, 0, 25), UDim2.fromOffset(12, 4), Enum.Font.GothamMedium, COLORS.text, 13)
	local valueLabel = text(holder, "", UDim2.fromOffset(70, 25), UDim2.new(1, -82, 0, 4), Enum.Font.GothamBold, COLORS.cyan, 12)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, -24, 0, 8)
	bar.Position = UDim2.fromOffset(12, 39)
	bar.BackgroundColor3 = COLORS.line
	bar.BorderSizePixel = 0
	bar.AutoButtonColor = false
	bar.Text = ""
	bar.Parent = holder
	corner(bar, 4)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = COLORS.purple
	fill.BorderSizePixel = 0
	fill.Parent = bar
	corner(fill, 4)

	local dragging = false
	local function updateFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local value = minimum + (maximum - minimum) * alpha
		setter(value)
		fill.Size = UDim2.fromScale(alpha, 1)
		valueLabel.Text = formatter and formatter(value) or tostring(math.floor(value + 0.5))
	end

	local function refresh()
		local value = getter()
		local alpha = math.clamp((value - minimum) / (maximum - minimum), 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		valueLabel.Text = formatter and formatter(value) or tostring(math.floor(value + 0.5))
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	refresh()
	return holder, refresh
end

local thumbnailCache = {}
local thumbnailWaiters = {}
local function setThumbnail(imageLabel, userId)
	if thumbnailCache[userId] then
		imageLabel.Image = thumbnailCache[userId]
		return
	end
	if thumbnailWaiters[userId] then
		table.insert(thumbnailWaiters[userId], imageLabel)
		return
	end
	thumbnailWaiters[userId] = { imageLabel }
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		local waiters = thumbnailWaiters[userId] or {}
		thumbnailWaiters[userId] = nil
		if ok then
			thumbnailCache[userId] = content
			for _, waitingImage in ipairs(waiters) do
				if waitingImage.Parent then waitingImage.Image = content end
			end
		end
	end)
end

--============================================================ ROOT GUI
local screen = Instance.new("ScreenGui")
screen.Name = "StaticsNewgenUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 150
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- The loader uses its own DisplayOrder so the rest of the interface can finish
-- constructing behind it without flashing half-built controls onto the screen.
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "StaticsLoading"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.DisplayOrder = 500
loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingGui.Parent = playerGui

local loadingRoot = Instance.new("CanvasGroup")
loadingRoot.Size = UDim2.fromScale(1, 1)
loadingRoot.BackgroundColor3 = Color3.fromRGB(7, 7, 12)
loadingRoot.BorderSizePixel = 0
loadingRoot.GroupTransparency = 1
loadingRoot.Parent = loadingGui

local loadingBackground = Instance.new("UIGradient")
loadingBackground.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 10, 35)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(8, 9, 16)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 20, 27)),
})
loadingBackground.Rotation = 28
loadingBackground.Parent = loadingRoot

local loadingLogo = Instance.new("Frame")
loadingLogo.AnchorPoint = Vector2.new(0.5, 0.5)
loadingLogo.Position = UDim2.fromScale(0.5, 0.35)
loadingLogo.Size = UDim2.fromOffset(92, 92)
loadingLogo.BackgroundColor3 = COLORS.purple
loadingLogo.BorderSizePixel = 0
loadingLogo.Parent = loadingRoot
corner(loadingLogo, 26)
stroke(loadingLogo, Color3.fromRGB(205, 190, 255), 0.45, 2)

local loadingLogoGradient = Instance.new("UIGradient")
loadingLogoGradient.Color = ColorSequence.new(COLORS.purple, COLORS.cyan)
loadingLogoGradient.Rotation = 30
loadingLogoGradient.Parent = loadingLogo

local loadingLogoScale = Instance.new("UIScale")
loadingLogoScale.Scale = 0.55
loadingLogoScale.Parent = loadingLogo

local loadingS = text(loadingLogo, "S", UDim2.fromScale(1, 1), UDim2.new(), Enum.Font.GothamBlack, Color3.fromRGB(8, 8, 13), 46)
loadingS.TextXAlignment = Enum.TextXAlignment.Center

local loadingTitle = text(loadingRoot, "STATICS NEWGEN", UDim2.new(1, -40, 0, 42), UDim2.new(0, 20, 0.35, 66), Enum.Font.GothamBlack, COLORS.text, 28)
loadingTitle.TextXAlignment = Enum.TextXAlignment.Center

local loadingStage = text(loadingRoot, "Preparing your session...", UDim2.new(1, -40, 0, 28), UDim2.new(0, 20, 0.35, 108), Enum.Font.GothamMedium, COLORS.muted, 13)
loadingStage.TextXAlignment = Enum.TextXAlignment.Center

local loadingDiscord = text(loadingRoot, "", UDim2.new(1, -40, 0, 28), UDim2.new(0, 20, 0.35, 138), Enum.Font.GothamBold, COLORS.cyan, 12)
loadingDiscord.TextXAlignment = Enum.TextXAlignment.Center

local loadingBar = Instance.new("Frame")
loadingBar.AnchorPoint = Vector2.new(0.5, 0)
loadingBar.Position = UDim2.new(0.5, 0, 0.35, 181)
loadingBar.Size = UDim2.fromOffset(330, 6)
loadingBar.BackgroundColor3 = Color3.fromRGB(42, 43, 58)
loadingBar.BorderSizePixel = 0
loadingBar.Parent = loadingRoot
corner(loadingBar, 3)

local loadingFill = Instance.new("Frame")
loadingFill.Size = UDim2.fromScale(0, 1)
loadingFill.BackgroundColor3 = COLORS.purple
loadingFill.BorderSizePixel = 0
loadingFill.Parent = loadingBar
corner(loadingFill, 3)
local loadingFillGradient = Instance.new("UIGradient")
loadingFillGradient.Color = ColorSequence.new(COLORS.purple, COLORS.cyan)
loadingFillGradient.Parent = loadingFill

local loadingTagline = text(loadingRoot, "A new generation of controls for your experience.", UDim2.new(1, -50, 0, 34), UDim2.new(0, 25, 1, -64), Enum.Font.GothamMedium, Color3.fromRGB(168, 171, 190), 12)
loadingTagline.TextXAlignment = Enum.TextXAlignment.Center

local loadingBlur = Instance.new("BlurEffect")
loadingBlur.Name = "StaticsLoadingBlur"
loadingBlur.Size = 18
loadingBlur.Parent = Lighting

local loadingSpinConnection = RunService.RenderStepped:Connect(function(dt)
	loadingLogoGradient.Rotation = (loadingLogoGradient.Rotation + dt * 42) % 360
end)
local loadingFinished = false

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.42
dim.BorderSizePixel = 0
dim.Visible = false
dim.Parent = screen

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(mainBaseSize.X, mainBaseSize.Y)
main.BackgroundColor3 = COLORS.bg
main:SetAttribute("ThemeBackgroundRole", "bg")
main.BorderSizePixel = 0
main.Active = true
main.Visible = false
main.Parent = screen
corner(main, 14)
stroke(main, Color3.fromRGB(72, 74, 92), 0.15, 1)

-- Registered before the large page build: if a later runtime error interrupts
-- startup, the player still gets a useful shell instead of a permanent loader.
local bootFallback = text(main, "STARTUP INTERRUPTED\nOpen View > Output and copy the first red Statics error.", UDim2.new(1, -40, 1, -40), UDim2.fromOffset(20, 20), Enum.Font.GothamBold, COLORS.red, 16)
bootFallback.TextWrapped = true
bootFallback.TextXAlignment = Enum.TextXAlignment.Center
bootFallback.Visible = false
bootFallback.ZIndex = 500
task.delay(12, function()
	if loadingFinished then return end
	if loadingSpinConnection then loadingSpinConnection:Disconnect() end
	if loadingGui.Parent then loadingGui:Destroy() end
	if loadingBlur.Parent then loadingBlur:Destroy() end
	main.Visible = true
	dim.Visible = true
	bootFallback.Visible = true
end)

local scale = Instance.new("UIScale")
scale.Parent = main

local function updateScale()
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local widthPadding = isMobile and 18 or 80
	local heightPadding = isMobile and 18 or 70
	local fit = math.min(viewport.X / (mainBaseSize.X + widthPadding), viewport.Y / (mainBaseSize.Y + heightPadding))
	scale.Scale = math.clamp(fit, isMobile and 0.42 or 0.58, 1)
end
updateScale()
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

local top = Instance.new("Frame")
top.Name = "Topbar"
top.Size = UDim2.new(1, 0, 0, 56)
top.BackgroundColor3 = Color3.fromRGB(24, 24, 33)
top:SetAttribute("ThemeBackgroundRole", "top")
top.BorderSizePixel = 0
top.Active = true
top.Parent = main
corner(top, 14)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 14)
topFix.Position = UDim2.new(0, 0, 1, -14)
topFix.BackgroundColor3 = top.BackgroundColor3
topFix:SetAttribute("ThemeBackgroundRole", "top")
topFix.BorderSizePixel = 0
topFix.Parent = top

local logo = Instance.new("Frame")
logo.Size = UDim2.fromOffset(34, 34)
logo.Position = UDim2.fromOffset(15, 11)
logo.BackgroundColor3 = COLORS.purple
logo.BorderSizePixel = 0
logo.Parent = top
corner(logo, 9)
local logoGradient = Instance.new("UIGradient")
logoGradient.Color = ColorSequence.new(COLORS.purple, COLORS.cyan)
logoGradient.Rotation = 35
logoGradient.Parent = logo
local logoText = text(logo, "S", UDim2.fromScale(1, 1), UDim2.new(), Enum.Font.GothamBlack, Color3.fromRGB(10, 10, 14), 18)
logoText.TextXAlignment = Enum.TextXAlignment.Center

text(top, "Statics Newgen", UDim2.fromOffset(180, 24), UDim2.fromOffset(61, 7), Enum.Font.GothamBold, COLORS.text, 16)
text(top, "https://discord.gg/uDCbY6upt", UDim2.fromOffset(240, 18), UDim2.fromOffset(61, 30), Enum.Font.Gotham, COLORS.muted, 11)

local minimize = button(top, "-", UDim2.fromOffset(34, 30), UDim2.new(1, -82, 0, 13), COLORS.panel2)
local close = button(top, "X", UDim2.fromOffset(34, 30), UDim2.new(1, -42, 0, 13), COLORS.panel2)

local sidebar = Instance.new("Frame")
sidebar.Size = isMobile and UDim2.new(1, 0, 0, 62) or UDim2.new(0, 72, 1, -56)
sidebar.Position = isMobile and UDim2.new(0, 0, 1, -62) or UDim2.fromOffset(0, 56)
sidebar.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
sidebar:SetAttribute("ThemeBackgroundRole", "sidebar")
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local content = Instance.new("Frame")
content.Size = isMobile and UDim2.new(1, 0, 1, -118) or UDim2.new(1, -72, 1, -56)
content.Position = isMobile and UDim2.fromOffset(0, 56) or UDim2.fromOffset(72, 56)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = main

local openButton = button(screen, "STATICS", UDim2.fromOffset(110, 40), UDim2.new(0, 18, 0.5, -20), COLORS.purple)
-- Keep the launcher permanently brand-purple even when the menu theme changes.
openButton:SetAttribute("ThemeLocked", true)
openButton:SetAttribute("ThemeBackgroundRole", nil)
openButton.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
local openButtonGradient = Instance.new("UIGradient")
openButtonGradient.Color = ColorSequence.new(
	Color3.fromRGB(168, 85, 247),
	Color3.fromRGB(109, 40, 217)
)
openButtonGradient.Rotation = 20
openButtonGradient.Parent = openButton
local openButtonStroke = stroke(openButton, Color3.fromRGB(196, 181, 253), 0.35, 1.5)
openButtonStroke:SetAttribute("ThemeColorRole", nil)
if isMobile then
	openButton.Size = UDim2.fromOffset(132, 50)
	openButton.Position = UDim2.new(0, 14, 1, -66)
	openButton.TextSize = 15
end
openButton.Visible = false

local menuVisible = true
local mobileAssistButton = nil
local function setMenuVisible(visible)
	menuVisible = visible
	main.Visible = visible
	dim.Visible = visible
	openButton.Visible = not visible
	if mobileAssistButton then mobileAssistButton.Visible = isMobile and not visible end
end
close.Activated:Connect(function() setMenuVisible(false) end)
minimize.Activated:Connect(function() setMenuVisible(false) end)
openButton.Activated:Connect(function() setMenuVisible(true) end)

-- custom drag works with mouse and touch
do
	local dragging = false
	local dragStart
	local startPosition
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X / scale.Scale, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y / scale.Scale)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

--============================================================ NAVIGATION
do
local navData = {
	"Home",
	"Aim",
	"VRAim",
	"Visuals",
	"Performance",
	"UI",
	"Session",
	"Players",
}
local navIconParts = {}

local function iconLine(parent, size, position, rotation)
	local line = Instance.new("Frame")
	line.Size = size
	line.Position = position
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Rotation = rotation or 0
	line.BackgroundColor3 = COLORS.muted
	line.BorderSizePixel = 0
	line.Parent = parent
	corner(line, 3)
	table.insert(navIconParts[parent.Parent.Name], line)
	return line
end

local function makeNavIcon(btn, pageName)
	btn.Text = ""
	btn.Name = pageName
	navIconParts[pageName] = {}
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(24, 24)
	icon.BackgroundTransparency = 1
	icon.Parent = btn

	if pageName == "Home" then
		iconLine(icon, UDim2.fromOffset(15, 3), UDim2.fromOffset(7, 9), -42)
		iconLine(icon, UDim2.fromOffset(15, 3), UDim2.fromOffset(17, 9), 42)
		iconLine(icon, UDim2.fromOffset(16, 12), UDim2.fromOffset(12, 16), 0)
	elseif pageName == "Aim" then
		local ring = iconLine(icon, UDim2.fromOffset(16, 16), UDim2.fromOffset(12, 12), 0)
		ring.BackgroundTransparency = 1
		stroke(ring, COLORS.muted, 0, 2)
		iconLine(icon, UDim2.fromOffset(22, 2), UDim2.fromOffset(12, 12), 0)
		iconLine(icon, UDim2.fromOffset(2, 22), UDim2.fromOffset(12, 12), 0)
	elseif pageName == "VRAim" then
		local headset = iconLine(icon, UDim2.fromOffset(22, 13), UDim2.fromOffset(12, 11), 0)
		headset.BackgroundTransparency = 1
		stroke(headset, COLORS.muted, 0, 2)
		iconLine(icon, UDim2.fromOffset(7, 5), UDim2.fromOffset(7, 12), 0)
		iconLine(icon, UDim2.fromOffset(7, 5), UDim2.fromOffset(17, 12), 0)
		iconLine(icon, UDim2.fromOffset(8, 2), UDim2.fromOffset(12, 20), 0)
	elseif pageName == "Visuals" then
		local eye = iconLine(icon, UDim2.fromOffset(23, 14), UDim2.fromOffset(12, 12), 0)
		eye.BackgroundTransparency = 1
		stroke(eye, COLORS.muted, 0, 2)
		iconLine(icon, UDim2.fromOffset(7, 7), UDim2.fromOffset(12, 12), 0)
	elseif pageName == "Performance" then
		iconLine(icon, UDim2.fromOffset(4, 9), UDim2.fromOffset(5, 16), 0)
		iconLine(icon, UDim2.fromOffset(4, 15), UDim2.fromOffset(12, 13), 0)
		iconLine(icon, UDim2.fromOffset(4, 21), UDim2.fromOffset(19, 10), 0)
	elseif pageName == "UI" then
		local back = iconLine(icon, UDim2.fromOffset(15, 14), UDim2.fromOffset(9, 9), 0)
		back.BackgroundTransparency = 1
		stroke(back, COLORS.muted, 0, 2)
		local front = iconLine(icon, UDim2.fromOffset(15, 14), UDim2.fromOffset(15, 15), 0)
		front.BackgroundTransparency = 1
		stroke(front, COLORS.muted, 0, 2)
	elseif pageName == "Session" then
		iconLine(icon, UDim2.fromOffset(18, 3), UDim2.fromOffset(10, 8), 0)
		iconLine(icon, UDim2.fromOffset(8, 3), UDim2.fromOffset(19, 5), 45)
		iconLine(icon, UDim2.fromOffset(18, 3), UDim2.fromOffset(14, 16), 0)
		iconLine(icon, UDim2.fromOffset(8, 3), UDim2.fromOffset(5, 19), 45)
	else
		iconLine(icon, UDim2.fromOffset(8, 8), UDim2.fromOffset(8, 8), 0)
		iconLine(icon, UDim2.fromOffset(7, 7), UDim2.fromOffset(17, 9), 0)
		iconLine(icon, UDim2.fromOffset(16, 8), UDim2.fromOffset(9, 18), 0)
		iconLine(icon, UDim2.fromOffset(10, 7), UDim2.fromOffset(18, 18), 0)
	end
end

function UI.showPage(name)
	currentPage = name
	for pageName, page in pairs(pages) do page.Visible = pageName == name end
	for pageName, btn in pairs(navButtons) do
		btn:SetAttribute("ThemeBackgroundRole", pageName == name and "accent" or "panel2")
		btn.BackgroundColor3 = pageName == name and COLORS.purple or COLORS.panel2
		for _, part in ipairs(navIconParts[pageName] or {}) do
			if part:IsA("UIStroke") then
				part.Color = pageName == name and COLORS.text or COLORS.muted
			else
				part.BackgroundColor3 = pageName == name and COLORS.text or COLORS.muted
				local childStroke = part:FindFirstChildOfClass("UIStroke")
				if childStroke then childStroke.Color = pageName == name and COLORS.text or COLORS.muted end
			end
		end
	end
end

for i, pageName in ipairs(navData) do
	local btn
	if isMobile then
		btn = button(sidebar, "", UDim2.new(1 / #navData, -6, 0, 50), UDim2.new((i - 1) / #navData, 3, 0, 6), COLORS.panel2)
	else
		btn = button(sidebar, "", UDim2.fromOffset(40, 40), UDim2.fromOffset(16, 10 + (i - 1) * 45), COLORS.panel2)
	end
	makeNavIcon(btn, pageName)
	btn.Activated:Connect(function() UI.showPage(pageName) end)
	navButtons[pageName] = btn
end

local sideAvatar = Instance.new("ImageLabel")
sideAvatar.Size = UDim2.fromOffset(42, 42)
sideAvatar.Position = UDim2.new(0, 15, 1, -57)
sideAvatar.BackgroundColor3 = COLORS.panel2
sideAvatar.BorderSizePixel = 0
sideAvatar.Parent = sidebar
corner(sideAvatar, 10)
setThumbnail(sideAvatar, localPlayer.UserId)
sideAvatar.Visible = not isMobile
end

local function newPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

--============================================================ HOME PAGE
do
local home = newPage("Home")
local welcome = panel(home, UDim2.new(1, -32, 0, 104), UDim2.fromOffset(16, 16))
local ownAvatar = Instance.new("ImageLabel")
ownAvatar.Size = UDim2.fromOffset(74, 74)
ownAvatar.Position = UDim2.fromOffset(16, 15)
ownAvatar.BackgroundColor3 = COLORS.panel2
ownAvatar.BorderSizePixel = 0
ownAvatar.Parent = welcome
corner(ownAvatar, 12)
setThumbnail(ownAvatar, localPlayer.UserId)
text(welcome, "Hello, " .. localPlayer.DisplayName, UDim2.new(1, -250, 0, 28), UDim2.fromOffset(108, 18), Enum.Font.GothamBold, COLORS.text, 19)
text(welcome, "Statics Newgen  /  " .. string.upper(deviceClass) .. " MODE", UDim2.new(1, -250, 0, 22), UDim2.fromOffset(108, 48), Enum.Font.Gotham, COLORS.muted, 12)
UI.roleBadge = text(welcome, "WAITING", UDim2.fromOffset(130, 38), UDim2.new(1, -148, 0.5, -19), Enum.Font.GothamBold, COLORS.muted, 12)
UI.roleBadge.TextXAlignment = Enum.TextXAlignment.Center
UI.roleBadge.BackgroundTransparency = 0
UI.roleBadge.BackgroundColor3 = COLORS.panel2
corner(UI.roleBadge, 8)

local serverCard = panel(home, UDim2.new(0.54, -22, 1, -152), UDim2.fromOffset(16, 136))
text(serverCard, "SERVER", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 12), Enum.Font.GothamBold, COLORS.muted, 11)
local serverGrid = Instance.new("Frame")
serverGrid.Size = UDim2.new(1, -24, 1, -52)
serverGrid.Position = UDim2.fromOffset(12, 40)
serverGrid.BackgroundTransparency = 1
serverGrid.Parent = serverCard
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.CellSize = UDim2.new(0.5, -4, 0.5, -4)
gridLayout.Parent = serverGrid
UI.statLabels = {}
for _, item in ipairs({ {"Players", "0"}, {"Latency", "0 ms"}, {"Round", "Waiting"}, {"FPS", "0"} }) do
	local stat = Instance.new("Frame")
	stat.BackgroundColor3 = COLORS.panel2
	stat.BorderSizePixel = 0
	stat.Parent = serverGrid
	corner(stat, 8)
	text(stat, item[1], UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 8), Enum.Font.Gotham, COLORS.muted, 10)
	local value = text(stat, item[2], UDim2.new(1, -20, 0, 27), UDim2.fromOffset(10, 27), Enum.Font.GothamBold, COLORS.text, 16)
	UI.statLabels[item[1]] = value
end

local homeRight = Instance.new("Frame")
homeRight.Size = UDim2.new(0.46, -10, 1, -152)
homeRight.Position = UDim2.new(0.54, 6, 0, 136)
homeRight.BackgroundTransparency = 1
homeRight.Parent = home

local lockCard = panel(homeRight, UDim2.new(1, 0, 0.48, -5), UDim2.new())
text(lockCard, "ASSIST STATUS", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 12), Enum.Font.GothamBold, COLORS.purple, 11)
UI.lockHome = text(lockCard, "Disabled", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(14, 38), Enum.Font.GothamBold, COLORS.text, 20)
text(lockCard, "Hold right-click; your gun applies soft correction", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 72), Enum.Font.Gotham, COLORS.muted, 10)

local discordCard = panel(homeRight, UDim2.new(1, 0, 0.52, -5), UDim2.new(0, 0, 0.48, 5))
local discordGradient = Instance.new("UIGradient")
discordGradient.Color = ColorSequence.new(Color3.fromRGB(73, 62, 180), Color3.fromRGB(23, 93, 137))
discordGradient.Rotation = 25
discordGradient.Parent = discordCard
text(discordCard, "DISCORD", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 13), Enum.Font.GothamBold, Color3.fromRGB(210, 220, 255), 11)
text(discordCard, "https://discord.gg/uDCbY6upt", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(14, 38), Enum.Font.GothamBold, Color3.new(1, 1, 1), 13)
text(discordCard, "Use your Experience social links", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(14, 70), Enum.Font.Gotham, Color3.fromRGB(202, 206, 230), 10)
end

--============================================================ AIM PAGE
do
local aim = newPage("Aim")
text(aim, "Standard Aim Assist", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(aim, "Considers any eligible player in the experience where you install the weapon adapter.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)

local aimLeft = scrollPanel(aim, UDim2.new(0.55, -24, 1, -91), UDim2.fromOffset(16, 75), 770)
local aimRight = panel(aim, UDim2.new(0.45, -8, 1, -91), UDim2.new(0.55, 0, 0, 75))
local _, refreshAimToggle = makeToggle(aimLeft, "Aim assist", 12, function()
	return config.AimEnabled
end, function(value)
	config.AimEnabled = value
	if not value then
		setAimEngaged(false)
		weaponTarget = nil
	end
end)
UI.refreshAimToggle = refreshAimToggle
makeToggle(aimLeft, "Sticky aim", 60, function() return config.StickyAim end, function(v) config.StickyAim = v end)
makeToggle(aimLeft, "Visible check", 108, function() return config.VisibleCheck end, function(v) config.VisibleCheck = v end)
makeToggle(aimLeft, "Team check", 156, function() return config.TeamCheck end, function(v) config.TeamCheck = v end)
makeToggle(aimLeft, "Movement prediction", 204, function() return config.PredictionEnabled end, function(v) config.PredictionEnabled = v end)
makeToggle(aimLeft, "Auto retarget", 252, function() return config.AutoRetarget end, function(v) config.AutoRetarget = v end)
makeToggle(aimLeft, "Camera FOV override", 300, function() return config.FOVOverride end, function(v)
	config.FOVOverride = v
	if not v and camera then camera.FieldOfView = originalCameraFOV end
end)
makeSlider(aimLeft, "Strength", 352, 0.02, 0.72, function() return config.AimStrength end, function(v) config.AimStrength = v end, function(v) return math.floor(v / 0.72 * 100) .. "%" end)
makeSlider(aimLeft, "Lock radius", 416, 60, 460, function() return config.LockRadius end, function(v) config.LockRadius = v end, function(v) return math.floor(v) .. " px" end)
makeSlider(aimLeft, "Camera FOV", 480, 50, 120, function() return config.CameraFOV end, function(v) config.CameraFOV = v end, function(v) return math.floor(v) .. " deg" end)
makeSlider(aimLeft, "Prediction", 544, 0, 0.2, function() return config.PredictionTime end, function(v) config.PredictionTime = v end, function(v) return string.format("%.3fs", v) end)
makeSlider(aimLeft, "Maximum distance", 608, 100, 1500, function() return config.MaxAimDistance end, function(v) config.MaxAimDistance = v end, function(v) return math.floor(v) .. " st" end)
makeSlider(aimLeft, "Sticky grace", 672, 0, 1.2, function() return config.StickyGrace end, function(v) config.StickyGrace = v end, function(v) return string.format("%.2fs", v) end)

text(aimRight, "LIVE AIM ASSIST", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 14), Enum.Font.GothamBold, COLORS.muted, 11)
UI.targetAvatar = Instance.new("ImageLabel")
UI.targetAvatar.Size = UDim2.fromOffset(122, 122)
UI.targetAvatar.AnchorPoint = Vector2.new(0.5, 0)
UI.targetAvatar.Position = UDim2.new(0.5, 0, 0, 54)
UI.targetAvatar.BackgroundColor3 = COLORS.panel2
UI.targetAvatar.BorderSizePixel = 0
UI.targetAvatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
UI.targetAvatar.Parent = aimRight
corner(UI.targetAvatar, 18)
stroke(UI.targetAvatar, COLORS.purple, 0.25, 2)
UI.targetName = text(aimRight, "Hold right-click", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 188), Enum.Font.GothamBold, COLORS.text, 17)
UI.targetName.TextXAlignment = Enum.TextXAlignment.Center
UI.targetInfo = text(aimRight, "Your weapon direction is blended, never hard-snapped", UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 219), Enum.Font.Gotham, COLORS.muted, 10)
UI.targetInfo.TextXAlignment = Enum.TextXAlignment.Center
UI.aimHint = text(aimRight, "WAITING FOR WEAPON ADAPTER", UDim2.new(1, -28, 0, 44), UDim2.new(0, 14, 1, -58), Enum.Font.GothamBold, COLORS.yellow, 11)
UI.aimHint.BackgroundTransparency = 0
UI.aimHint.BackgroundColor3 = COLORS.panel2
UI.aimHint.TextXAlignment = Enum.TextXAlignment.Center
corner(UI.aimHint, 9)

--============================================================ VR ASSIST PAGE
local vrAimPage = newPage("VRAim")
text(vrAimPage, "VR Assist", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(vrAimPage, "A separate muzzle-ray profile that only considers players marked as using VR.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)

local vrAimLeft = panel(vrAimPage, UDim2.new(0.55, -24, 1, -91), UDim2.fromOffset(16, 75))
local vrAimRight = panel(vrAimPage, UDim2.new(0.45, -8, 1, -91), UDim2.new(0.55, 0, 0, 75))
local _, refreshVRAimToggle = makeToggle(vrAimLeft, "VR-player-only assist", 12, function()
	return config.VRAimEnabled
end, function(value)
	config.VRAimEnabled = value
	if not value then vrWeaponTarget = nil end
end)
makeToggle(vrAimLeft, "Sticky VR retention", 60, function() return config.StickyAim end, function(v) config.StickyAim = v end)
makeToggle(vrAimLeft, "Visible check", 108, function() return config.VisibleCheck end, function(v) config.VisibleCheck = v end)
makeToggle(vrAimLeft, "Team check", 156, function() return config.TeamCheck end, function(v) config.TeamCheck = v end)
makeSlider(vrAimLeft, "VR assist strength", 208, 0.02, 0.8, function() return config.VRAimStrength end, function(v) config.VRAimStrength = v end, function(v) return math.floor(v / 0.8 * 100) .. "%" end)
makeSlider(vrAimLeft, "VR acquire cone", 272, 4, 35, function() return config.VRConeDegrees end, function(v)
	config.VRConeDegrees = v
	config.VRStickyConeDegrees = math.max(v + 10, v * 1.7)
end, function(v) return math.floor(v) .. " deg" end)
makeSlider(vrAimLeft, "VR sticky grace", 336, 0, 1.5, function() return config.VRStickyGrace end, function(v) config.VRStickyGrace = v end, function(v) return string.format("%.2fs", v) end)
makeSlider(vrAimLeft, "Maximum distance", 400, 100, 1500, function() return config.MaxAimDistance end, function(v) config.MaxAimDistance = v end, function(v) return math.floor(v) .. " st" end)

text(vrAimRight, "VR TARGET FILTER", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 14), Enum.Font.GothamBold, COLORS.cyan, 11)
local vrFilterIcon = Instance.new("Frame")
vrFilterIcon.Size = UDim2.fromOffset(150, 92)
vrFilterIcon.AnchorPoint = Vector2.new(0.5, 0)
vrFilterIcon.Position = UDim2.new(0.5, 0, 0, 55)
vrFilterIcon.BackgroundColor3 = COLORS.panel2
vrFilterIcon.BorderSizePixel = 0
vrFilterIcon.Parent = vrAimRight
corner(vrFilterIcon, 24)
stroke(vrFilterIcon, COLORS.cyan, 0.15, 2)
local vrLensLeft = panel(vrFilterIcon, UDim2.fromOffset(52, 38), UDim2.fromOffset(17, 24))
local vrLensRight = panel(vrFilterIcon, UDim2.fromOffset(52, 38), UDim2.fromOffset(81, 24))
vrLensLeft.BackgroundColor3 = Color3.fromRGB(20, 83, 96)
vrLensRight.BackgroundColor3 = Color3.fromRGB(20, 83, 96)
UI.vrFilterTitle = text(vrAimRight, "VR PLAYERS ONLY", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 173), Enum.Font.GothamBlack, COLORS.text, 18)
UI.vrFilterTitle.TextXAlignment = Enum.TextXAlignment.Center
UI.vrFilterInfo = text(vrAimRight, "Requires the server-replicated UsingVR attribute. Standard players are ignored by this profile.", UDim2.new(1, -34, 0, 64), UDim2.fromOffset(17, 211), Enum.Font.Gotham, COLORS.muted, 11)
UI.vrFilterInfo.TextWrapped = true
UI.vrFilterInfo.TextXAlignment = Enum.TextXAlignment.Center
UI.vrAdapterLabel = text(vrAimRight, "WAITING FOR VR GUN ADAPTER", UDim2.new(1, -28, 0, 44), UDim2.new(0, 14, 1, -58), Enum.Font.GothamBold, COLORS.yellow, 11)
UI.vrAdapterLabel.BackgroundTransparency = 0
UI.vrAdapterLabel.BackgroundColor3 = COLORS.panel2
UI.vrAdapterLabel.TextXAlignment = Enum.TextXAlignment.Center
corner(UI.vrAdapterLabel, 9)
end

--============================================================ VISUALS PAGE
do
local visualPage = newPage("Visuals")
text(visualPage, "Visuals", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(visualPage, "ESP remains local. VR users receive a replicated VR badge.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)
local visualLeft = scrollPanel(visualPage, UDim2.new(0.5, -24, 1, -91), UDim2.fromOffset(16, 75), 838)
local visualRight = panel(visualPage, UDim2.new(0.5, -8, 1, -91), UDim2.new(0.5, 0, 0, 75))
makeToggle(visualLeft, "Master ESP", 12, function() return config.ESPEnabled end, function(v) config.ESPEnabled = v end)
makeToggle(visualLeft, "Character highlight", 60, function() return config.Highlights end, function(v) config.Highlights = v end)
makeToggle(visualLeft, "Nameplates", 108, function() return config.Nameplates end, function(v) config.Nameplates = v end)
makeToggle(visualLeft, "Distance", 156, function() return config.ShowDistance end, function(v) config.ShowDistance = v end)
makeToggle(visualLeft, "Known roles", 204, function() return config.ShowRoles end, function(v) config.ShowRoles = v end)
makeToggle(visualLeft, "Device badge", 252, function() return config.ShowVR end, function(v) config.ShowVR = v end)
makeToggle(visualLeft, "Through walls", 300, function() return config.ThroughWalls end, function(v) config.ThroughWalls = v end)
makeToggle(visualLeft, "ESP team filter", 348, function() return config.ESPTeamCheck end, function(v) config.ESPTeamCheck = v end)
makeToggle(visualLeft, "Lock-radius ring", 396, function() return config.ShowLockRadius end, function(v) config.ShowLockRadius = v end)
makeToggle(visualLeft, "Health bars", 444, function() return config.HealthBars end, function(v) config.HealthBars = v end)
makeToggle(visualLeft, "Screen tracers", 492, function() return config.Tracers end, function(v) config.Tracers = v end)
makeSlider(visualLeft, "ESP distance", 544, 100, 2000, function() return config.MaxESPDistance end, function(v) config.MaxESPDistance = v end, function(v) return math.floor(v) .. " st" end)
makeSlider(visualLeft, "Text size", 608, 10, 24, function() return config.ESPTextSize end, function(v) config.ESPTextSize = v end, function(v) return math.floor(v) .. " px" end)
makeSlider(visualLeft, "Fill visibility", 672, 0.05, 0.8, function() return 1 - config.ESPFillTransparency end, function(v) config.ESPFillTransparency = 1 - v end, function(v) return math.floor(v * 100) .. "%" end)

local colorModeButton = button(visualLeft, "COLOR MODE: ROLE", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 742), COLORS.panel2)
local colorModes = { "Role", "Team", "VR", "Accent" }
colorModeButton.Activated:Connect(function()
	local current = table.find(colorModes, config.ESPColorMode) or 1
	config.ESPColorMode = colorModes[current % #colorModes + 1]
	colorModeButton.Text = "COLOR MODE: " .. string.upper(config.ESPColorMode)
end)

text(visualRight, "ESP PREVIEW", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 14), Enum.Font.GothamBold, COLORS.muted, 11)
UI.previewBody = Instance.new("Frame")
UI.previewBody.Size = UDim2.fromOffset(118, 210)
UI.previewBody.AnchorPoint = Vector2.new(0.5, 0.5)
UI.previewBody.Position = UDim2.new(0.5, 0, 0.5, 12)
UI.previewBody.BackgroundColor3 = Color3.fromRGB(24, 42, 52)
UI.previewBody.BackgroundTransparency = 0.15
UI.previewBody.BorderSizePixel = 0
UI.previewBody.Parent = visualRight
corner(UI.previewBody, 45)
UI.previewBodyStroke = stroke(UI.previewBody, COLORS.cyan, 0, 2)
UI.previewHead = Instance.new("Frame")
UI.previewHead.Size = UDim2.fromOffset(74, 74)
UI.previewHead.AnchorPoint = Vector2.new(0.5, 0.5)
UI.previewHead.Position = UDim2.new(0.5, 0, 0, -24)
UI.previewHead.BackgroundColor3 = Color3.fromRGB(26, 46, 56)
UI.previewHead.BorderSizePixel = 0
UI.previewHead.Parent = UI.previewBody
corner(UI.previewHead, 37)
UI.previewHeadStroke = stroke(UI.previewHead, COLORS.cyan, 0, 2)
UI.previewTag = text(visualRight, "PlayerName  [VR]\nUNKNOWN  |  42m", UDim2.fromOffset(210, 48), UDim2.new(0.5, -105, 0, 48), Enum.Font.GothamBold, COLORS.cyan, 13)
UI.previewTag.TextXAlignment = Enum.TextXAlignment.Center
UI.previewTag.TextYAlignment = Enum.TextYAlignment.Center
end

--============================================================ PERFORMANCE PAGE
do
local performance = newPage("Performance")
text(performance, "Performance", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(performance, "Local-only rendering profiles. Nothing in the map is deleted.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)
local perfTop = panel(performance, UDim2.new(1, -32, 0, 104), UDim2.fromOffset(16, 75))
UI.bigFPS = text(perfTop, "0 FPS", UDim2.fromOffset(180, 55), UDim2.fromOffset(18, 12), Enum.Font.GothamBlack, COLORS.green, 31)
text(perfTop, "LIVE PERFORMANCE", UDim2.fromOffset(180, 20), UDim2.fromOffset(20, 67), Enum.Font.GothamBold, COLORS.muted, 10)
local perfModeLabel = text(perfTop, "MODE: OFF", UDim2.fromOffset(220, 35), UDim2.new(1, -240, 0.5, -18), Enum.Font.GothamBold, COLORS.text, 15)
perfModeLabel.TextXAlignment = Enum.TextXAlignment.Right

local perfModes = panel(performance, UDim2.new(1, -32, 0, 92), UDim2.fromOffset(16, 195))
local modeNames = { "Off", "Low", "Balanced", "Aggressive" }
UI.modeButtons = {}
for i, mode in ipairs(modeNames) do
	local width = 0.25
	local btn = button(perfModes, string.upper(mode), UDim2.new(width, -10, 0, 48), UDim2.new((i - 1) * width, 8, 0, 22), COLORS.panel2)
	UI.modeButtons[mode] = btn
end

local perfInfo = panel(performance, UDim2.new(1, -32, 1, -319), UDim2.fromOffset(16, 303))
text(perfInfo, "WHAT THE MODES CHANGE", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 13), Enum.Font.GothamBold, COLORS.muted, 11)
text(perfInfo, "LOW", UDim2.fromOffset(100, 22), UDim2.fromOffset(14, 48), Enum.Font.GothamBold, COLORS.cyan, 12)
text(perfInfo, "Post-processing only", UDim2.new(1, -130, 0, 22), UDim2.fromOffset(118, 48), Enum.Font.Gotham, COLORS.text, 12)
text(perfInfo, "BALANCED", UDim2.fromOffset(100, 22), UDim2.fromOffset(14, 82), Enum.Font.GothamBold, COLORS.yellow, 12)
text(perfInfo, "Post effects, shadows and beams", UDim2.new(1, -130, 0, 22), UDim2.fromOffset(118, 82), Enum.Font.Gotham, COLORS.text, 12)
text(perfInfo, "AGGRESSIVE", UDim2.fromOffset(100, 22), UDim2.fromOffset(14, 116), Enum.Font.GothamBold, COLORS.red, 12)
text(perfInfo, "Also disables local particles and trails", UDim2.new(1, -130, 0, 22), UDim2.fromOffset(118, 116), Enum.Font.Gotham, COLORS.text, 12)

local originalLighting = {
	GlobalShadows = Lighting.GlobalShadows,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local originalQuality
pcall(function()
	originalQuality = settings().Rendering.QualityLevel
end)
local changedEffects = {}

local function setEffectEnabled(instance, enabled)
	if changedEffects[instance] == nil then changedEffects[instance] = instance.Enabled end
	instance.Enabled = enabled
end

local function applyPerformanceMode(mode)
	config.PerformanceMode = mode

	for instance, wasEnabled in pairs(changedEffects) do
		if instance.Parent then instance.Enabled = wasEnabled end
	end
	changedEffects = {}
	Lighting.GlobalShadows = originalLighting.GlobalShadows
	Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale

	if mode ~= "Off" then
		for _, instance in ipairs(game:GetDescendants()) do
			if instance:IsA("PostEffect") then
				setEffectEnabled(instance, false)
			elseif mode == "Balanced" or mode == "Aggressive" then
				if instance:IsA("Beam") then setEffectEnabled(instance, false) end
				if mode == "Aggressive" and (instance:IsA("ParticleEmitter") or instance:IsA("Trail")) then
					setEffectEnabled(instance, false)
				end
			end
		end
	end

	if mode == "Balanced" or mode == "Aggressive" then
		Lighting.GlobalShadows = false
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
	end

	pcall(function()
		settings().Rendering.QualityLevel = mode == "Off"
			and (originalQuality or Enum.QualityLevel.Automatic)
			or Enum.QualityLevel.Level01
	end)

	for name, btn in pairs(UI.modeButtons) do
		btn:SetAttribute("ThemeBackgroundRole", name == mode and "accent" or "panel2")
		btn.BackgroundColor3 = name == mode and COLORS.purple or COLORS.panel2
	end
	perfModeLabel.Text = "MODE: " .. string.upper(mode)
end

for mode, btn in pairs(UI.modeButtons) do
	btn.Activated:Connect(function() applyPerformanceMode(mode) end)
end
applyPerformanceMode(isMobile and "Balanced" or "Off")

game.DescendantAdded:Connect(function(instance)
	if config.PerformanceMode == "Off" then return end
	task.defer(function()
		if not instance.Parent then return end
		if instance:IsA("PostEffect") then
			setEffectEnabled(instance, false)
		elseif (config.PerformanceMode == "Balanced" or config.PerformanceMode == "Aggressive")
			and instance:IsA("Beam") then
			setEffectEnabled(instance, false)
		elseif config.PerformanceMode == "Aggressive"
			and (instance:IsA("ParticleEmitter") or instance:IsA("Trail")) then
			setEffectEnabled(instance, false)
		end
	end)
end)
end

--============================================================ UI THEME GALLERY
do
local themePage = newPage("UI")
text(themePage, "Interface", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(themePage, "Choose a complete visual system. Features and settings stay exactly where you left them.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)

local themeDiscord = text(themePage, "STATICS NEWGEN  /  https://discord.gg/uDCbY6upt", UDim2.new(1, -32, 0, 28), UDim2.fromOffset(18, 76), Enum.Font.GothamBold, COLORS.cyan, 11)
themeDiscord.TextXAlignment = Enum.TextXAlignment.Center

local function miniFrame(parent, size, position, color, radius)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, radius or 4)
	return frame
end

local function makeThemeCard(themeName, index)
	local theme = THEMES[themeName]
	local card = Instance.new("TextButton")
	card.Name = themeName
	card:SetAttribute("ThemeLocked", true)
	card.Size = UDim2.new(1 / 3, -14, 1, -124)
	card.Position = UDim2.new((index - 1) / 3, 9, 0, 112)
	card.BackgroundColor3 = theme.bg
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.Parent = themePage
	corner(card, 14)
	local selection = stroke(card, theme.line, 0.1, 1.5)

	local preview = miniFrame(card, UDim2.new(1, -16, 0, 196), UDim2.fromOffset(8, 8), theme.panel, 10)
	local previewTop = miniFrame(preview, UDim2.new(1, 0, 0, 28), UDim2.new(), theme.top, 8)
	miniFrame(previewTop, UDim2.fromOffset(14, 14), UDim2.fromOffset(8, 7), theme.accent, 4)
	local brand = text(previewTop, "STATICS NEWGEN", UDim2.new(1, -32, 1, 0), UDim2.fromOffset(28, 0), Enum.Font.GothamBold, theme.text, 8)
	brand:SetAttribute("ThemeTextRole", nil)

	if themeName == "DarkDock" then
		local miniSide = miniFrame(preview, UDim2.new(0, 48, 1, -34), UDim2.fromOffset(6, 32), theme.sidebar, 7)
		for row = 0, 2 do
			miniFrame(miniSide, UDim2.new(1, -10, 0, 22), UDim2.fromOffset(5, 6 + row * 29), row == 0 and theme.panel2 or theme.sidebar, 7)
		end
		local body = miniFrame(preview, UDim2.new(1, -62, 1, -42), UDim2.fromOffset(58, 36), theme.panel2, 8)
		miniFrame(body, UDim2.new(1, -12, 0, 34), UDim2.fromOffset(6, 7), theme.panel, 14)
		miniFrame(body, UDim2.new(1, -12, 0, 7), UDim2.fromOffset(6, 51), theme.secondary, 4)
		miniFrame(body, UDim2.new(0.7, -6, 0, 7), UDim2.fromOffset(6, 68), theme.accent, 4)
		miniFrame(body, UDim2.new(1, -12, 0, 26), UDim2.fromOffset(6, 88), theme.panel, 12)
	elseif themeName == "Skeet" then
		for row = 0, 4 do
			local strip = miniFrame(preview, UDim2.new(1, -18, 0, 23), UDim2.fromOffset(9, 39 + row * 29), theme.panel2, 2)
			miniFrame(strip, UDim2.new(row == 2 and 0.38 or 0.72, 0, 0, 3), UDim2.new(0, 7, 1, -6), row == 2 and theme.accent or theme.line, 1)
		end
	else
		local stat = miniFrame(preview, UDim2.new(1, -18, 0, 54), UDim2.fromOffset(9, 38), theme.panel2, 9)
		miniFrame(stat, UDim2.new(0.58, 0, 1, 0), UDim2.new(), Color3.fromRGB(35, 66, 54), 9)
		for row = 0, 2 do
			local strip = miniFrame(preview, UDim2.new(1, -18, 0, 27), UDim2.fromOffset(9, 101 + row * 34), theme.panel2, 7)
			if row == 1 then miniFrame(strip, UDim2.new(0.6, 0, 0, 5), UDim2.new(0.36, 0, 0.5, -2), theme.danger, 3) end
		end
	end

	local name = text(card, theme.DisplayName, UDim2.new(1, -20, 0, 25), UDim2.new(0, 10, 0, 214), Enum.Font.GothamBold, theme.text, 14)
	name.TextXAlignment = Enum.TextXAlignment.Center
	local description = text(card, theme.Description, UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0, 240), Enum.Font.Gotham, theme.muted, 10)
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Center
	local choose = text(card, "CLICK TO APPLY", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 1, -38), Enum.Font.GothamBold, theme.accent, 10)
	choose.TextXAlignment = Enum.TextXAlignment.Center

	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.08 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	end)
	card.Activated:Connect(function()
		if applyTheme then applyTheme(themeName, true) end
	end)
	themeCards[themeName] = { card = card, stroke = selection, choose = choose }
end

makeThemeCard("DarkDock", 1)
makeThemeCard("Skeet", 2)
makeThemeCard("Emerald", 3)
end

--============================================================ SESSION PAGE
do
local sessionPage = newPage("Session")
text(sessionPage, "Session", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(sessionPage, "Move to another server or eliminate only your current character.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)

local sessionStatus = panel(sessionPage, UDim2.new(1, -32, 0, 92), UDim2.fromOffset(16, 75))
text(sessionStatus, "SESSION STATUS", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 12), Enum.Font.GothamBold, COLORS.muted, 11)
actionStatusLabel = text(sessionStatus, actionMessage, UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 38), Enum.Font.GothamBold, actionMessageOkay and COLORS.green or COLORS.red, 15)

local hopCard = panel(sessionPage, UDim2.new(0.5, -24, 1, -199), UDim2.fromOffset(16, 183))
text(hopCard, "HOP SERVER", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 18), Enum.Font.GothamBlack, COLORS.cyan, 18)
text(hopCard, "Finds a different live public server using the experience's private MemoryStore directory.", UDim2.new(1, -28, 0, 66), UDim2.fromOffset(14, 55), Enum.Font.Gotham, COLORS.muted, 11).TextWrapped = true
local hopButton = button(hopCard, "HOP TO ANOTHER SERVER", UDim2.new(1, -28, 0, 48), UDim2.new(0, 14, 1, -62), Color3.fromRGB(16, 130, 155))
hopButton:SetAttribute("ThemeBackgroundRole", "secondary")
hopButton.Activated:Connect(function()
	if not HopRequest then
		showActionMessage("Server script is not connected yet.", false)
		return
	end
	showActionMessage("Sending server-hop request...", true)
	HopRequest:FireServer()
end)

local killCard = panel(sessionPage, UDim2.new(0.5, -8, 1, -199), UDim2.new(0.5, 0, 0, 183))
text(killCard, "KILL", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 18), Enum.Font.GothamBlack, COLORS.red, 18)
text(killCard, "Eliminates only your current in-game character so Roblox can respawn it. This does not close Roblox or the client.", UDim2.new(1, -28, 0, 76), UDim2.fromOffset(14, 55), Enum.Font.Gotham, COLORS.muted, 11).TextWrapped = true
local killButton = button(killCard, "KILL", UDim2.new(1, -28, 0, 48), UDim2.new(0, 14, 1, -62), Color3.fromRGB(180, 42, 58))
killButton:SetAttribute("ThemeBackgroundRole", "danger")
killButton.Activated:Connect(function()
	if not ResetRequest then
		showActionMessage("Server script is not connected yet.", false)
		return
	end
	showActionMessage("Eliminating your current character...", true)
	ResetRequest:FireServer()
end)
end

--============================================================ PLAYERS PAGE
do
local playerPage = newPage("Players")
text(playerPage, "Players", UDim2.new(1, -32, 0, 32), UDim2.fromOffset(18, 15), Enum.Font.GothamBold, COLORS.text, 23)
text(playerPage, "Select a player to inspect their avatar, known role and device.", UDim2.new(1, -32, 0, 20), UDim2.fromOffset(18, 47), Enum.Font.Gotham, COLORS.muted, 11)

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(0, 260, 1, -91)
playerList.Position = UDim2.fromOffset(16, 75)
playerList.BackgroundColor3 = COLORS.panel
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 3
playerList.ScrollBarImageColor3 = COLORS.purple
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new()
playerList.Parent = playerPage
corner(playerList, 12)
stroke(playerList, COLORS.line, 0.35, 1)
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 7)
playerListLayout.Parent = playerList
local playerListPadding = Instance.new("UIPadding")
playerListPadding.PaddingTop = UDim.new(0, 10)
playerListPadding.PaddingLeft = UDim.new(0, 10)
playerListPadding.PaddingRight = UDim.new(0, 10)
playerListPadding.PaddingBottom = UDim.new(0, 10)
playerListPadding.Parent = playerList

local playerSpotlight = panel(playerPage, UDim2.new(1, -308, 1, -91), UDim2.fromOffset(292, 75))
text(playerSpotlight, "SELECTED PLAYER", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 14), Enum.Font.GothamBold, COLORS.muted, 11)
local selectedAvatar = Instance.new("ImageLabel")
selectedAvatar.Size = UDim2.fromOffset(150, 150)
selectedAvatar.AnchorPoint = Vector2.new(0.5, 0)
selectedAvatar.Position = UDim2.new(0.5, 0, 0, 52)
selectedAvatar.BackgroundColor3 = COLORS.panel2
selectedAvatar.BorderSizePixel = 0
selectedAvatar.Parent = playerSpotlight
corner(selectedAvatar, 22)
stroke(selectedAvatar, COLORS.purple, 0.25, 2)
local selectedName = text(playerSpotlight, "Nobody selected", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 217), Enum.Font.GothamBold, COLORS.text, 19)
selectedName.TextXAlignment = Enum.TextXAlignment.Center
UI.selectedMeta = text(playerSpotlight, "Choose someone from the list", UDim2.new(1, -28, 0, 42), UDim2.fromOffset(14, 250), Enum.Font.Gotham, COLORS.muted, 12)
UI.selectedMeta.TextXAlignment = Enum.TextXAlignment.Center
UI.selectedMeta.TextYAlignment = Enum.TextYAlignment.Top
local inspectorNote = text(playerSpotlight, "AVATAR INSPECTOR", UDim2.new(1, -28, 0, 44), UDim2.new(0, 14, 1, -58), Enum.Font.GothamBold, COLORS.purple, 12)
inspectorNote.BackgroundTransparency = 0
inspectorNote.BackgroundColor3 = COLORS.panel2
inspectorNote.TextXAlignment = Enum.TextXAlignment.Center
corner(inspectorNote, 9)

UI.playerRows = {}
local function selectPlayer(target)
	selectedPlayer = target
	selectedName.Text = target.DisplayName
	local role = knownRoles[target.Name] or "Unknown"
	local device = string.upper(target:GetAttribute("DeviceClass") or (target:GetAttribute("UsingVR") and "VR" or "PC")) .. " PLAYER"
	UI.selectedMeta.Text = string.upper(role) .. "\n" .. device .. "  |  @" .. target.Name
	setThumbnail(selectedAvatar, target.UserId)
	for player, row in pairs(UI.playerRows) do
		row.BackgroundColor3 = player == target and activeTheme.panel2:Lerp(activeTheme.accent, 0.28) or COLORS.panel2
	end
end

function UI.makePlayerRow(target)
	local row = button(playerList, "", UDim2.new(1, 0, 0, 58), UDim2.new(), COLORS.panel2)
	row.Name = target.Name
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromOffset(42, 42)
	avatar.Position = UDim2.fromOffset(8, 8)
	avatar.BackgroundColor3 = COLORS.bg
	avatar:SetAttribute("ThemeBackgroundRole", "bg")
	avatar.BorderSizePixel = 0
	avatar.Parent = row
	corner(avatar, 9)
	setThumbnail(avatar, target.UserId)
	text(row, target.DisplayName, UDim2.new(1, -66, 0, 22), UDim2.fromOffset(58, 8), Enum.Font.GothamBold, COLORS.text, 12)
	local info = text(row, "UNKNOWN", UDim2.new(1, -66, 0, 20), UDim2.fromOffset(58, 30), Enum.Font.Gotham, COLORS.muted, 10)
	info.Name = "Info"
	row.Activated:Connect(function() selectPlayer(target) end)
	UI.playerRows[target] = row
	return row
end
end

--============================================================ AIM ENGINE
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function modelForPlayer(target)
	if not target then return nil end

	-- Some VR systems render a separate tracked rig instead of moving the normal
	-- Player.Character. Prefer that rig whenever the server marked the user as VR.
	local fallbackRig = nil
	for _, folderName in ipairs({ "VRCharacters", "VRPlayers", "VRRigs" }) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			local named = folder:FindFirstChild(target.Name)
				or folder:FindFirstChild(tostring(target.UserId))
				or folder:FindFirstChild(target.DisplayName)
			if named and named:IsA("Model") then
				if target:GetAttribute("UsingVR") then return named end
				fallbackRig = fallbackRig or named
			end

			-- Owned VR systems can also identify rigs with attributes/ObjectValues.
			for _, candidate in ipairs(folder:GetChildren()) do
				if candidate:IsA("Model") then
					local ownerValue = candidate:FindFirstChild("Player") or candidate:FindFirstChild("Owner")
					local matchesAttribute = candidate:GetAttribute("UserId") == target.UserId
						or candidate:GetAttribute("OwnerUserId") == target.UserId
					local matchesValue = ownerValue and ownerValue:IsA("ObjectValue") and ownerValue.Value == target
					if matchesAttribute or matchesValue then
						if target:GetAttribute("UsingVR") then return candidate end
						fallbackRig = fallbackRig or candidate
					end
				end
			end
		end
	end

	return target.Character or fallbackRig
end

local function rigAnchor(character)
	if not character then return nil end
	for _, name in ipairs({ "HumanoidRootPart", "VRRoot", "UpperTorso", "Torso" }) do
		local candidate = character:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then return candidate end
		if candidate and candidate:IsA("Attachment") and candidate.Parent and candidate.Parent:IsA("BasePart") then
			return candidate.Parent
		end
	end
	return character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart", true)
end

local function rigTagAnchor(character)
	if not character then return nil end
	for _, name in ipairs({ "Head", "VRHead", "Headset", "CameraHead" }) do
		local candidate = character:FindFirstChild(name, true)
		if candidate and (candidate:IsA("BasePart") or candidate:IsA("Attachment")) then
			return candidate
		end
	end
	return rigAnchor(character)
end

local function aliveCharacter(target)
	local character = modelForPlayer(target)
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid", true)
	if not humanoid and target and target.Character and target.Character ~= character then
		humanoid = target.Character:FindFirstChildWhichIsA("Humanoid", true)
	end
	local root = rigAnchor(character)
	if character and root and (not humanoid or humanoid.Health > 0) then
		return character, humanoid, root
	end
	return nil
end

local function targetPart(target)
	local character = aliveCharacter(target)
	if not character then return nil end
	for _, name in ipairs({ config.TargetPart, "VRHead", "UpperTorso", "Head", "Torso" }) do
		local candidate = character:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then return candidate end
		if candidate and candidate:IsA("Attachment") and candidate.Parent and candidate.Parent:IsA("BasePart") then
			return candidate.Parent
		end
	end
	return rigAnchor(character)
end

local function isEnemy(target, vrOnly)
	if target == localPlayer then return false end
	if vrOnly and target:GetAttribute("UsingVR") ~= true then return false end
	if roundMeta.eliminated and roundMeta.eliminated[target.Name] then return false end
	if config.TeamCheck and localPlayer.Team and target.Team and localPlayer.Team == target.Team then return false end
	return aliveCharacter(target) ~= nil
end

local function distanceTo(part)
	local _, _, localRoot = aliveCharacter(localPlayer)
	if not localRoot or not part then return math.huge end
	return (part.Position - localRoot.Position).Magnitude
end

local function aimPosition(part)
	local position = part.Position
	if config.PredictionEnabled and config.PredictionTime > 0 then
		local velocity = part.AssemblyLinearVelocity
		if velocity.Magnitude > 160 then velocity = velocity.Unit * 160 end
		position += velocity * config.PredictionTime
	end
	return position
end

local function hasLineOfSight(part)
	if not config.VisibleCheck then return true end
	local localCharacter = localPlayer.Character
	local filter = { camera }
	if localCharacter then table.insert(filter, localCharacter) end
	rayParams.FilterDescendantsInstances = filter
	local origin = camera.CFrame.Position
	local result = Workspace:Raycast(origin, part.Position - origin, rayParams)
	return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function screenScore(part)
	local point, onScreen = camera:WorldToViewportPoint(aimPosition(part))
	if not onScreen or point.Z <= 0 then return nil end
	local center = camera.ViewportSize / 2
	return (Vector2.new(point.X, point.Y) - center).Magnitude
end

local function targetStillValid(target)
	if not isEnemy(target) then return false end
	local part = targetPart(target)
	if not part or distanceTo(part) > config.MaxAimDistance then return false end
	local score = screenScore(part)
	local visible = hasLineOfSight(part)
	local breakRadius = config.LockRadius * (config.StickyAim and config.LockBreakMultiplier or 1)
	if score and score <= breakRadius and visible then
		lastTargetValidAt = os.clock()
		return true
	end

	-- Sticky grace prevents a target from dropping because of one frame of
	-- occlusion, a jump past the ring edge, or a fast camera correction.
	return config.StickyAim and (os.clock() - lastTargetValidAt) <= config.StickyGrace
end

local function findBestTarget()
	local best, bestScore = nil, math.huge
	for _, target in ipairs(Players:GetPlayers()) do
		if isEnemy(target) then
			local part = targetPart(target)
			local score = part and screenScore(part)
			local distance = part and distanceTo(part) or math.huge
			-- Crosshair distance is dominant; the small world-distance term only
			-- resolves ties so close targets feel easier to select.
			local weightedScore = score and (score + distance * 0.008) or math.huge
			if score and score <= config.LockRadius and distance <= config.MaxAimDistance
				and weightedScore < bestScore and hasLineOfSight(part) then
				best = target
				bestScore = weightedScore
			end
		end
	end
	return best
end

-- VR weapons do not shoot from the desktop camera. They shoot from a muzzle
-- attachment controlled by the hand, so select by angle from that muzzle ray.
local weaponRayParams = RaycastParams.new()
weaponRayParams.FilterType = Enum.RaycastFilterType.Exclude
weaponRayParams.IgnoreWater = true

local function weaponCanSee(origin, position, target)
	local filter = { camera }
	if localPlayer.Character then table.insert(filter, localPlayer.Character) end
	local localVRModel = modelForPlayer(localPlayer)
	if localVRModel and localVRModel ~= localPlayer.Character then table.insert(filter, localVRModel) end
	weaponRayParams.FilterDescendantsInstances = filter
	local result = Workspace:Raycast(origin, position - origin, weaponRayParams)
	local targetModel = modelForPlayer(target)
	return not result or (targetModel and result.Instance:IsDescendantOf(targetModel))
		or (target.Character and result.Instance:IsDescendantOf(target.Character))
end

local function weaponCandidate(target, origin, forward, coneDegrees, vrOnly)
	if not isEnemy(target, vrOnly) then return nil end
	local part = targetPart(target)
	if not part then return nil end
	local position = aimPosition(part)
	local offset = position - origin
	local distance = offset.Magnitude
	if distance <= 0.01 or distance > config.MaxAimDistance then return nil end
	local direction = offset / distance
	local dot = math.clamp(forward:Dot(direction), -1, 1)
	local minimumDot = math.cos(math.rad(coneDegrees))
	if dot < minimumDot or not weaponCanSee(origin, position, target) then return nil end
	return {
		player = target,
		position = position,
		direction = direction,
		dot = dot,
		alignment = math.clamp((dot - minimumDot) / math.max(1 - minimumDot, 0.0001), 0, 1),
		distance = distance,
	}
end

local function findWeaponTarget(origin, forward, vrOnly)
	if typeof(origin) ~= "Vector3" or typeof(forward) ~= "Vector3" or forward.Magnitude < 0.001 then
		return nil
	end
	forward = forward.Unit
	local activeTarget = vrOnly and vrWeaponTarget or weaponTarget
	local stickyCone = vrOnly and config.VRStickyConeDegrees or config.WeaponStickyConeDegrees
	local acquireCone = vrOnly and config.VRConeDegrees or config.WeaponConeDegrees
	local grace = vrOnly and config.VRStickyGrace or config.StickyGrace
	local validAt = vrOnly and lastVRWeaponValidAt or lastWeaponValidAt

	if config.StickyAim and activeTarget then
		local sticky = weaponCandidate(activeTarget, origin, forward, stickyCone, vrOnly)
		if sticky then
			if vrOnly then lastVRWeaponValidAt = os.clock() else lastWeaponValidAt = os.clock() end
			return sticky
		end
		if os.clock() - validAt <= grace then
			local part = targetPart(activeTarget)
			if part then
				local position = aimPosition(part)
				local offset = position - origin
				if offset.Magnitude > 0.01 then
					return { player = activeTarget, position = position, direction = offset.Unit, alignment = 0.35, sticky = true }
				end
			end
		end
	end

	local best, bestScore = nil, math.huge
	for _, target in ipairs(Players:GetPlayers()) do
		local candidate = weaponCandidate(target, origin, forward, acquireCone, vrOnly)
		if candidate then
			local angularError = 1 - candidate.dot
			local score = angularError * 1000 + candidate.distance * 0.002
			if score < bestScore then
				best = candidate
				bestScore = score
			end
		end
	end

	if vrOnly then
		vrWeaponTarget = best and best.player or nil
		if best then lastVRWeaponValidAt = os.clock() end
	else
		weaponTarget = best and best.player or nil
		if best then lastWeaponValidAt = os.clock() end
	end
	return best
end

local lockRing = Instance.new("Frame")
lockRing.AnchorPoint = Vector2.new(0.5, 0.5)
lockRing.BackgroundTransparency = 1
lockRing.Parent = screen
corner(lockRing, 1000)
stroke(lockRing, COLORS.purple, 0.28, 1.5)

local aimMarker = Instance.new("Frame")
aimMarker.AnchorPoint = Vector2.new(0.5, 0.5)
aimMarker.Size = UDim2.fromOffset(24, 24)
aimMarker.BackgroundTransparency = 1
aimMarker.Visible = false
aimMarker.Parent = screen
corner(aimMarker, 12)
stroke(aimMarker, COLORS.cyan, 0, 2)

if isMobile then
	mobileAssistButton = button(screen, "HOLD ASSIST", UDim2.fromOffset(154, 62), UDim2.new(1, -172, 1, -84), COLORS.purple)
	mobileAssistButton.AnchorPoint = Vector2.new(0, 0)
	mobileAssistButton.TextSize = 16
	mobileAssistButton.Visible = false
	stroke(mobileAssistButton, COLORS.cyan, 0.35, 2)
	mobileAssistButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			config.AimEnabled = true
			UI.refreshAimToggle(true)
			setAimEngaged(true)
			TweenService:Create(mobileAssistButton, TweenInfo.new(0.1), { BackgroundColor3 = COLORS.cyan }):Play()
		end
	end)
	mobileAssistButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			setAimEngaged(false)
			TweenService:Create(mobileAssistButton, TweenInfo.new(0.1), { BackgroundColor3 = COLORS.purple }):Play()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.RightShift then
		if processed then return end
		setMenuVisible(not menuVisible)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
		-- Roblox's camera may mark right mouse as processed while rotating/zooming.
		-- Aim-down-sights still needs the same input, so intentionally handle it.
		if menuVisible then setMenuVisible(false) end
		config.AimEnabled = true
		UI.refreshAimToggle(true)
		setAimEngaged(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
		setAimEngaged(false)
	end
end)

RunService:BindToRenderStep("StaticsAimAssistPreview", Enum.RenderPriority.Camera.Value + 1, function()
	if not camera then return end
	if config.FOVOverride and not isLocalVR then camera.FieldOfView = config.CameraFOV end

	lockRing.Size = UDim2.fromOffset(config.LockRadius * 2, config.LockRadius * 2)
	lockRing.Position = UDim2.fromScale(0.5, 0.5)
	lockRing.Visible = config.AimEnabled and config.ShowLockRadius and not menuVisible

	if not config.AimEnabled or not aimEngaged then
		if currentTarget then setAimEngaged(false) end
		aimMarker.Visible = false
		return
	end

	if currentTarget and not targetStillValid(currentTarget) then
		currentTarget = nil
	end

	if not currentTarget and (config.AutoRetarget or not targetAcquiredForEngagement) then
		currentTarget = findBestTarget()
		if currentTarget then
			targetAcquiredForEngagement = true
			lastTargetValidAt = os.clock()
		end
	end

	local part = targetPart(currentTarget)
	if not part then aimMarker.Visible = false; return end

	local desiredPosition = aimPosition(part)
	local point, onScreen = camera:WorldToViewportPoint(desiredPosition)
	aimMarker.Visible = onScreen
	aimMarker.Position = UDim2.fromOffset(point.X, point.Y)

	-- No camera rotation here. The gun adapter softly blends its muzzle direction,
	-- which works with desktop weapons and does not fight a VR player's head.
end)

-- Local weapon scripts invoke this adapter. It returns a softly corrected
-- direction rather than an exact target point, so it cannot hard-snap the shot.
local function normalizeMuzzleInput(origin, fallbackDirection)
	if typeof(origin) == "Instance" then
		if origin:IsA("Attachment") then
			fallbackDirection = fallbackDirection or origin.WorldCFrame.LookVector
			origin = origin.WorldPosition
		elseif origin:IsA("BasePart") then
			fallbackDirection = fallbackDirection or origin.CFrame.LookVector
			origin = origin.Position
		end
	elseif typeof(origin) == "CFrame" then
		fallbackDirection = fallbackDirection or origin.LookVector
		origin = origin.Position
	end
	if typeof(fallbackDirection) == "CFrame" then fallbackDirection = fallbackDirection.LookVector end
	return origin, fallbackDirection
end

local aimDirectionFunction = Instance.new("BindableFunction")
aimDirectionFunction.Name = "StaticsAimDirection"
aimDirectionFunction.OnInvoke = function(origin, fallbackDirection)
	lastStandardAdapterCall = os.clock()
	origin, fallbackDirection = normalizeMuzzleInput(origin, fallbackDirection)
	if typeof(origin) ~= "Vector3" then return fallbackDirection end
	if typeof(fallbackDirection) ~= "Vector3" or fallbackDirection.Magnitude < 0.001 then
		return fallbackDirection
	end
	if not config.AimEnabled then return fallbackDirection.Unit end

	-- Desktop follows hold-right-click. VR has no mouse, so invoking this from
	-- the gun's fire/ADS code is itself the engagement signal.
	if not isLocalVR and not aimEngaged then return fallbackDirection.Unit end
	local rawDirection = fallbackDirection.Unit
	local candidate = findWeaponTarget(origin, rawDirection)
	if not candidate then return rawDirection end

	-- This is assistance, not a hard lock: center-of-cone targets receive more
	-- correction, edge targets receive less, and Strength caps the correction.
	local alignment = candidate.alignment or 0.35
	local edgeWeight = 0.22 + alignment * 0.78
	local assistAlpha = math.clamp(config.AimStrength * edgeWeight, 0, 0.82)
	if candidate.sticky then assistAlpha *= 0.72 end
	return rawDirection:Lerp(candidate.direction, assistAlpha).Unit
end
local playerScriptsFolder = localPlayer:WaitForChild("PlayerScripts")
local oldAimDirection = playerScriptsFolder:FindFirstChild("StaticsAimDirection")
if oldAimDirection then oldAimDirection:Destroy() end
aimDirectionFunction.Parent = playerScriptsFolder

local vrAimDirectionFunction = Instance.new("BindableFunction")
vrAimDirectionFunction.Name = "StaticsVRAimDirection"
vrAimDirectionFunction.OnInvoke = function(origin, fallbackDirection)
	lastVRAdapterCall = os.clock()
	origin, fallbackDirection = normalizeMuzzleInput(origin, fallbackDirection)
	if typeof(origin) ~= "Vector3" then return fallbackDirection end
	if typeof(fallbackDirection) ~= "Vector3" or fallbackDirection.Magnitude < 0.001 then return fallbackDirection end
	local rawDirection = fallbackDirection.Unit
	if not config.VRAimEnabled then return rawDirection end

	local candidate = findWeaponTarget(origin, rawDirection, true)
	if not candidate then return rawDirection end
	local alignment = candidate.alignment or 0.35
	local edgeWeight = 0.2 + alignment * 0.8
	local assistAlpha = math.clamp(config.VRAimStrength * edgeWeight, 0, 0.86)
	if candidate.sticky then assistAlpha *= 0.75 end
	return rawDirection:Lerp(candidate.direction, assistAlpha).Unit
end
local oldVRAimDirection = playerScriptsFolder:FindFirstChild("StaticsVRAimDirection")
if oldVRAimDirection then oldVRAimDirection:Destroy() end
vrAimDirectionFunction.Parent = playerScriptsFolder

--============================================================ ESP ENGINE
local function espModelFor(target)
	return modelForPlayer(target)
end

local function visualColor(target)
	local role = knownRoles[target.Name]
	if config.ESPColorMode == "Team" and target.Team then
		return target.TeamColor.Color
	elseif config.ESPColorMode == "VR" then
		return target:GetAttribute("UsingVR") and COLORS.cyan or COLORS.purple
	elseif config.ESPColorMode == "Accent" then
		return COLORS.purple
	end
	return ROLE_COLORS[role] or (target:GetAttribute("UsingVR") and COLORS.cyan or COLORS.purple)
end

local function getVisual(target)
	if visuals[target] then return visuals[target] end

	local highlight = Instance.new("Highlight")
	highlight.Name = "Statics_" .. target.Name
	highlight.FillTransparency = 0.72
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = Workspace

	local plate = Instance.new("BillboardGui")
	plate.Name = "StaticsPlate_" .. target.Name
	plate.Size = UDim2.fromOffset(isLocalVR and 280 or 220, isLocalVR and 66 or 54)
	plate.StudsOffset = Vector3.new(0, isLocalVR and 3.5 or 3, 0)
	plate.AlwaysOnTop = true
	plate.LightInfluence = 0
	plate.MaxDistance = config.MaxESPDistance
	plate.Enabled = false
	plate.Parent = playerGui

	local label = text(plate, "", UDim2.new(1, 0, 1, -9), UDim2.new(), Enum.Font.GothamBold, COLORS.text, config.ESPTextSize)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)

	local healthBack = Instance.new("Frame")
	healthBack.Name = "HealthBack"
	healthBack.AnchorPoint = Vector2.new(0.5, 1)
	healthBack.Size = UDim2.new(0.72, 0, 0, 5)
	healthBack.Position = UDim2.new(0.5, 0, 1, -2)
	healthBack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = plate
	corner(healthBack, 3)

	local healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = COLORS.green
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack
	corner(healthFill, 3)

	local tracer = Instance.new("Frame")
	tracer.Name = "Tracer_" .. target.Name
	tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	tracer.BackgroundColor3 = COLORS.purple
	tracer.BackgroundTransparency = 0.15
	tracer.BorderSizePixel = 0
	tracer.Visible = false
	tracer.Parent = screen
	corner(tracer, 2)

	visuals[target] = {
		highlight = highlight,
		plate = plate,
		label = label,
		healthBack = healthBack,
		healthFill = healthFill,
		tracer = tracer,
		active = false,
		model = nil,
		root = nil,
		color = COLORS.purple,
	}
	return visuals[target]
end

local espConnections = {}
local function removeVisual(target)
	local data = visuals[target]
	if not data then return end
	data.highlight:Destroy()
	data.plate:Destroy()
	data.tracer:Destroy()
	visuals[target] = nil
end

local function setupESPPlayer(target)
	if target == localPlayer or espConnections[target] then return end
	local added = target.CharacterAdded:Connect(function()
		removeVisual(target)
		task.delay(0.15, function()
			if target.Parent then getVisual(target) end
		end)
	end)
	local removing = target.CharacterRemoving:Connect(function()
		removeVisual(target)
	end)
	espConnections[target] = { added, removing }
	if target.Character then getVisual(target) end
end

for _, target in ipairs(Players:GetPlayers()) do setupESPPlayer(target) end
Players.PlayerAdded:Connect(setupESPPlayer)

Players.PlayerRemoving:Connect(function(target)
	removeVisual(target)
	local connections = espConnections[target]
	if connections then
		for _, connection in ipairs(connections) do connection:Disconnect() end
		espConnections[target] = nil
	end
	if currentTarget == target then setAimEngaged(false) end
	if weaponTarget == target then weaponTarget = nil end
	if vrWeaponTarget == target then vrWeaponTarget = nil end
	local row = UI.playerRows[target]
	if row then row:Destroy(); UI.playerRows[target] = nil end
end)

local function updateESP()
	local localRoot = rigAnchor(espModelFor(localPlayer))
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= localPlayer then
			local data = getVisual(target)
			local character = espModelFor(target)
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid", true)
			if not humanoid and target.Character then
				humanoid = target.Character:FindFirstChildWhichIsA("Humanoid", true)
			end
			local root = rigAnchor(character)
			local tagAnchor = rigTagAnchor(character)
			local alive = character and root and (not humanoid or humanoid.Health > 0)
			local distance = localRoot and root and (root.Position - localRoot.Position).Magnitude or math.huge
			local eliminatedTarget = roundMeta.eliminated and roundMeta.eliminated[target.Name]
			local sameTeam = localPlayer.Team and target.Team and localPlayer.Team == target.Team
			local show = config.ESPEnabled and alive and not eliminatedTarget and distance <= config.MaxESPDistance
				and (not config.ESPTeamCheck or not sameTeam)
			local color = visualColor(target)
			data.active = show
			data.model = character
			data.root = root
			data.color = color

			data.highlight.Enabled = show and config.Highlights
			data.highlight.Adornee = character
			data.highlight.FillColor = color
			data.highlight.FillTransparency = config.ESPFillTransparency
			data.highlight.OutlineColor = color
			data.highlight.DepthMode = config.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded

			data.plate.Enabled = show and config.Nameplates and tagAnchor ~= nil
			data.plate.Adornee = tagAnchor
			data.plate.MaxDistance = config.MaxESPDistance
			data.label.TextColor3 = color
			data.label.TextSize = config.ESPTextSize
			data.healthBack.Visible = show and config.Nameplates and config.HealthBars and humanoid ~= nil
			if humanoid then
				local healthAlpha = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
				data.healthFill.Size = UDim2.fromScale(healthAlpha, 1)
				data.healthFill.BackgroundColor3 = COLORS.red:Lerp(COLORS.green, healthAlpha)
			end

			if show and tagAnchor then
				local pieces = { target.DisplayName }
				if config.ShowVR then
					if target:GetAttribute("UsingVR") then
						table.insert(pieces, "[VR]")
					elseif target:GetAttribute("UsingMobile") then
						table.insert(pieces, "[MOBILE]")
					end
				end
				local second = {}
				if config.ShowRoles then table.insert(second, string.upper(knownRoles[target.Name] or "Unknown")) end
				if config.ShowDistance and localRoot and root then table.insert(second, math.floor(distance) .. " st") end
				data.label.Text = table.concat(pieces, "  ") .. "\n" .. table.concat(second, "  |  ")
			end

			if humanoid then
				humanoid.DisplayDistanceType = show and config.Nameplates and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
			end
		end
	end
end

local function updateScreenESP()
	if not camera then return end
	local startPoint = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y - 18)
	for _, data in pairs(visuals) do
		local root = data.root
		if config.Tracers and data.active and root and not menuVisible then
			local point, onScreen = camera:WorldToViewportPoint(root.Position)
			if onScreen and point.Z > 0 then
				local endPoint = Vector2.new(point.X, point.Y)
				local delta = endPoint - startPoint
				data.tracer.Visible = true
				data.tracer.BackgroundColor3 = data.color
				data.tracer.Size = UDim2.fromOffset(delta.Magnitude, 2)
				data.tracer.Position = UDim2.fromOffset((startPoint.X + endPoint.X) * 0.5, (startPoint.Y + endPoint.Y) * 0.5)
				data.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			else
				data.tracer.Visible = false
			end
		else
			data.tracer.Visible = false
		end
	end
end

--============================================================ LIVE UI DATA
local frameCount = 0
local fps = 0
local elapsed = 0
local uiElapsed = 0

RunService.RenderStepped:Connect(function(dt)
	frameCount += 1
	elapsed += dt
	uiElapsed += dt
	updateScreenESP()
	if elapsed >= 0.5 then
		fps = math.floor(frameCount / elapsed + 0.5)
		frameCount = 0
		elapsed = 0
	end
	if uiElapsed < 0.2 then return end
	uiElapsed = 0

	updateESP()

	local ownRole = knownRoles[localPlayer.Name]
	local roleColor = ROLE_COLORS[ownRole] or COLORS.muted
	UI.roleBadge.Text = string.upper(ownRole or "Waiting")
	UI.roleBadge.TextColor3 = roleColor

	local previewColor = visualColor(localPlayer)
	UI.previewBodyStroke.Color = previewColor
	UI.previewHeadStroke.Color = previewColor
	UI.previewBody.BackgroundTransparency = math.clamp(config.ESPFillTransparency, 0.1, 0.9)
	UI.previewHead.BackgroundTransparency = math.clamp(config.ESPFillTransparency, 0.1, 0.9)
	UI.previewTag.TextColor3 = previewColor
	UI.previewTag.TextSize = config.ESPTextSize
	UI.previewTag.Text = "PlayerName" .. (config.ShowVR and "  [VR]" or "")
		.. "\n" .. (config.ShowRoles and "UNKNOWN" or "ESP ACTIVE")
		.. (config.ShowDistance and "  |  42 st" or "")

	UI.statLabels.Players.Text = tostring(#Players:GetPlayers())
	UI.statLabels.Latency.Text = math.floor(localPlayer:GetNetworkPing() * 1000) .. " ms"
	local roundText = roundMeta.state or "Waiting"
	if roundMeta.winner then
		roundText = roundMeta.winner .. " win"
	elseif (roundMeta.timeLeft or 0) > 0 then
		roundText ..= "  " .. tostring(roundMeta.timeLeft) .. "s"
	end
	UI.statLabels.Round.Text = roundText
	UI.statLabels.FPS.Text = tostring(fps)
	UI.bigFPS.Text = fps .. " FPS"

	local assistedTarget = weaponTarget or currentTarget
	if config.AimEnabled and (aimEngaged or (isLocalVR and weaponTarget ~= nil)) then
		UI.lockHome.Text = assistedTarget and ("Assisting: " .. assistedTarget.DisplayName) or "Searching..."
		UI.lockHome.TextColor3 = assistedTarget and COLORS.cyan or COLORS.yellow
	else
		UI.lockHome.Text = config.AimEnabled and "Assist ready" or "Disabled"
		UI.lockHome.TextColor3 = config.AimEnabled and COLORS.green or COLORS.text
	end

	if assistedTarget then
		UI.targetName.Text = assistedTarget.DisplayName
		local targetDevice = string.upper(assistedTarget:GetAttribute("DeviceClass") or (assistedTarget:GetAttribute("UsingVR") and "VR" or "PC")) .. " PLAYER"
		UI.targetInfo.Text = targetDevice .. "  |  " .. string.upper(knownRoles[assistedTarget.Name] or "Unknown")
		setThumbnail(UI.targetAvatar, assistedTarget.UserId)
	else
		UI.targetName.Text = aimEngaged and "Searching crosshair..." or "Hold right-click"
		UI.targetInfo.Text = isLocalVR and "VR gun requests a soft muzzle correction" or "Look at a player, then hold right mouse"
	end
	if os.clock() - lastStandardAdapterCall < 2 then
		UI.aimHint.Text = "WEAPON ADAPTER CONNECTED"
		UI.aimHint.TextColor3 = COLORS.green
	else
		UI.aimHint.Text = "WAITING: GUN MUST INVOKE StaticsAimDirection"
		UI.aimHint.TextColor3 = COLORS.yellow
	end

	if vrWeaponTarget then
		UI.vrFilterTitle.Text = "ASSISTING " .. string.upper(vrWeaponTarget.DisplayName)
		UI.vrFilterTitle.TextColor3 = COLORS.cyan
	else
		UI.vrFilterTitle.Text = config.VRAimEnabled and "VR PLAYERS ONLY" or "VR ASSIST DISABLED"
		UI.vrFilterTitle.TextColor3 = config.VRAimEnabled and COLORS.text or COLORS.muted
	end
	local vrPlayerCount = 0
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= localPlayer and target:GetAttribute("UsingVR") then vrPlayerCount += 1 end
	end
	UI.vrFilterInfo.Text = string.format("Detected %d VR player%s. Separate VR rigs and Player.Character use the same resolver.",
		vrPlayerCount, vrPlayerCount == 1 and "" or "s")
	if os.clock() - lastVRAdapterCall < 2 then
		UI.vrAdapterLabel.Text = "VR GUN ADAPTER CONNECTED"
		UI.vrAdapterLabel.TextColor3 = COLORS.green
	else
		UI.vrAdapterLabel.Text = "WAITING: GUN MUST INVOKE StaticsVRAimDirection"
		UI.vrAdapterLabel.TextColor3 = COLORS.yellow
	end

	if selectedPlayer and selectedPlayer.Parent then
		local selectedRole = knownRoles[selectedPlayer.Name] or "Unknown"
		local selectedDevice = string.upper(selectedPlayer:GetAttribute("DeviceClass") or (selectedPlayer:GetAttribute("UsingVR") and "VR" or "PC")) .. " PLAYER"
		local selectedState = roundMeta.eliminated and roundMeta.eliminated[selectedPlayer.Name] and "ELIMINATED" or string.upper(selectedRole)
		UI.selectedMeta.Text = selectedState .. "\n" .. selectedDevice .. "  |  @" .. selectedPlayer.Name
	end

	for _, target in ipairs(Players:GetPlayers()) do
		local row = UI.playerRows[target] or UI.makePlayerRow(target)
		local role = knownRoles[target.Name] or "Unknown"
		local suffix = target:GetAttribute("UsingVR") and "  [VR]" or (target:GetAttribute("UsingMobile") and "  [MOBILE]" or "")
		if roundMeta.eliminated and roundMeta.eliminated[target.Name] then
			row.Info.Text = "ELIMINATED" .. suffix
			row.Info.TextColor3 = COLORS.red
		else
			row.Info.Text = string.upper(role) .. suffix
			row.Info.TextColor3 = ROLE_COLORS[role] or COLORS.muted
		end
	end
end)

local function isThemeLocked(instance)
	local cursor = instance
	while cursor and cursor ~= screen do
		if cursor:GetAttribute("ThemeLocked") then return true end
		cursor = cursor.Parent
	end
	return false
end

local function prepareThemeTargets()
	for _, instance in ipairs(screen:GetDescendants()) do
		if not isThemeLocked(instance) then
			if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1
				and not instance:GetAttribute("ThemeBackgroundRole") then
				local role = paletteRole(instance.BackgroundColor3)
				if role then instance:SetAttribute("ThemeBackgroundRole", role) end
			end

			if (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"))
				and not instance:GetAttribute("ThemeTextRole") then
				local role = paletteRole(instance.TextColor3)
				if role then instance:SetAttribute("ThemeTextRole", role) end
				instance:SetAttribute("ThemeHeader", instance.Font == Enum.Font.GothamBlack or instance.Font == Enum.Font.GothamBold)
			end

			if instance:IsA("UIStroke") and not instance:GetAttribute("ThemeColorRole") then
				instance:SetAttribute("ThemeColorRole", paletteRole(instance.Color) or "line")
			elseif instance:IsA("UIGradient") then
				instance:SetAttribute("ThemeGradient", true)
			elseif instance:IsA("ScrollingFrame") then
				instance:SetAttribute("ThemeScrollBar", true)
			end
		end
	end
end

applyTheme = function(themeName, animate)
	local theme = THEMES[themeName]
	if not theme then return end
	activeThemeName = themeName
	activeTheme = theme

	COLORS.bg = theme.bg
	COLORS.panel = theme.panel
	COLORS.panel2 = theme.panel2
	COLORS.line = theme.line
	COLORS.text = theme.text
	COLORS.muted = theme.muted
	COLORS.purple = theme.accent
	COLORS.cyan = theme.secondary
	COLORS.green = theme.success
	COLORS.red = theme.danger
	COLORS.yellow = theme.warning

	local duration = animate and 0.24 or 0
	local function colorProperty(instance, property, value)
		if duration > 0 and instance:IsA("GuiObject") then
			TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quart), { [property] = value }):Play()
		else
			instance[property] = value
		end
	end

	for _, instance in ipairs(screen:GetDescendants()) do
		if not isThemeLocked(instance) then
			local backgroundRole = instance:GetAttribute("ThemeBackgroundRole")
			if backgroundRole and instance:IsA("GuiObject") and theme[backgroundRole] then
				colorProperty(instance, "BackgroundColor3", theme[backgroundRole])
			end

			local textRole = instance:GetAttribute("ThemeTextRole")
			if textRole and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
				colorProperty(instance, "TextColor3", theme[textRole] or theme.text)
				instance.Font = instance:GetAttribute("ThemeHeader") and theme.HeaderFont or theme.BodyFont
			end

			if instance:IsA("UIStroke") then
				local strokeRole = instance:GetAttribute("ThemeColorRole")
				if strokeRole then instance.Color = theme[strokeRole] or theme.line end
			elseif instance:IsA("UICorner") then
				local baseRadius = instance:GetAttribute("BaseRadius")
				if baseRadius then instance.CornerRadius = UDim.new(0, math.max(1, math.floor(baseRadius * theme.Radius + 0.5))) end
			elseif instance:IsA("UIGradient") and instance:GetAttribute("ThemeGradient") then
				instance.Color = ColorSequence.new(theme.accent, theme.secondary)
			elseif instance:IsA("ScrollingFrame") and instance:GetAttribute("ThemeScrollBar") then
				instance.ScrollBarImageColor3 = theme.accent
			end
		end
	end

	for cardThemeName, data in pairs(themeCards) do
		local selected = cardThemeName == themeName
		data.stroke.Color = selected and THEMES[cardThemeName].accent or THEMES[cardThemeName].line
		data.stroke.Thickness = selected and 3 or 1.5
		data.choose.Text = selected and "ACTIVE THEME" or "CLICK TO APPLY"
	end
	if selectedPlayer and UI.playerRows[selectedPlayer] then
		UI.playerRows[selectedPlayer].BackgroundColor3 = theme.panel2:Lerp(theme.accent, 0.28)
	end
	for modeName, modeButton in pairs(UI.modeButtons) do
		local selected = modeName == config.PerformanceMode
		modeButton:SetAttribute("ThemeBackgroundRole", selected and "accent" or "panel2")
		modeButton.BackgroundColor3 = selected and theme.accent or theme.panel2
	end
	UI.showPage(currentPage)

	if animate then
		local sweep = Instance.new("Frame")
		sweep.Name = "ThemeSweep"
		sweep.Size = UDim2.new(0, 0, 0, 2)
		sweep.Position = UDim2.fromOffset(isMobile and 0 or 72, 56)
		sweep.BackgroundColor3 = theme.accent
		sweep.BorderSizePixel = 0
		sweep.ZIndex = 200
		sweep.Parent = main
		TweenService:Create(sweep, TweenInfo.new(0.34, Enum.EasingStyle.Quart), { Size = UDim2.new(1, isMobile and 0 or -72, 0, 2) }):Play()
		task.delay(0.36, function()
			if not sweep.Parent then return end
			local fade = TweenService:Create(sweep, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Connect(function() sweep:Destroy() end)
		end)
		showActionMessage(theme.DisplayName .. " interface applied.", true)
	end
end

prepareThemeTargets()
applyTheme("DarkDock", false)
UI.showPage("Home")

local loaderStages = {
	"Building the Statics interface...",
	"Connecting secure game services...",
	"Preparing smooth aim assistance...",
	"Calibrating customizable ESP...",
	"Detecting desktop, controller, and VR...",
	"Finalizing your session...",
}

local loaderTaglines = {
	"Statics makes complex controls feel clean and immediate.",
	"Universal by design across your own shooter maps and round modes.",
	"R6, R15, desktop, controller, and VR-ready presentation.",
	"An overpowered-feeling control suite without trusting client damage.",
	"Powerful client presentation with server-authoritative game actions.",
	"Build your experience around Statics and make every session feel newgen.",
}

task.spawn(function()
	TweenService:Create(loadingRoot, TweenInfo.new(0.3), { GroupTransparency = 0 }):Play()
	TweenService:Create(loadingLogoScale, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.wait(0.35)

	for index, stage in ipairs(loaderStages) do
		loadingStage.TextTransparency = 1
		loadingTagline.TextTransparency = 1
		loadingStage.Text = stage
		loadingTagline.Text = loaderTaglines[index]
		TweenService:Create(loadingStage, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		TweenService:Create(loadingTagline, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
		TweenService:Create(loadingFill, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(index / #loaderStages, 1),
		}):Play()
		task.wait(0.56)
	end

	loadingTitle.Text = "STATICS IS LOADED"
	loadingStage.Text = "Welcome, " .. localPlayer.DisplayName
	loadingDiscord.Text = "https://discord.gg/uDCbY6upt"
	loadingTagline.Text = "Hold right-click for soft assist, then let your own weapon and server handle the shot."
	TweenService:Create(loadingLogoScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
	task.wait(1.15)

	loadingFinished = true
	main.Size = UDim2.fromOffset(mainBaseSize.X * 0.94, mainBaseSize.Y * 0.94)
	dim.BackgroundTransparency = 1
	setMenuVisible(true)
	TweenService:Create(main, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(mainBaseSize.X, mainBaseSize.Y) }):Play()
	TweenService:Create(dim, TweenInfo.new(0.35), { BackgroundTransparency = 0.42 }):Play()
	TweenService:Create(loadingRoot, TweenInfo.new(0.38), { GroupTransparency = 1 }):Play()
	TweenService:Create(loadingBlur, TweenInfo.new(0.38), { Size = 0 }):Play()
	task.wait(0.42)
	if loadingSpinConnection then loadingSpinConnection:Disconnect() end
	loadingGui:Destroy()
	loadingBlur:Destroy()
end)

-- If a cosmetic loading tween ever fails, never trap the player behind it.
task.delay(10, function()
	if loadingFinished then return end
	loadingFinished = true
	if loadingSpinConnection then loadingSpinConnection:Disconnect() end
	if loadingGui.Parent then loadingGui:Destroy() end
	if loadingBlur.Parent then loadingBlur:Destroy() end
	setMenuVisible(true)
end)

print("[Statics Newgen] loaded | Device:", deviceClass)
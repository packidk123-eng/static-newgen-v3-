-- StaticsNewgen.client.luau
-- Fast Execution Edition (Zero-delay load, anti-stuck fail-safe)
-- Enhanced with dedicated Murder Mystery profile, tool teleportation, and radar!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local targetParent = (gethui and gethui()) or (player:FindFirstChildOfClass("PlayerGui")) or (game:GetService("CoreGui"))
local playerGui = player:FindFirstChildOfClass("PlayerGui") or targetParent
local playerScripts = player:FindFirstChild("PlayerScripts")
local camera = Workspace.CurrentCamera
local originalFOV = camera and camera.FieldOfView or 70
local isVR = VRService.VREnabled
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not isVR
local device = isVR and "VR" or (isMobile and "Mobile" or "PC")

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		camera = Workspace.CurrentCamera
		originalFOV = camera.FieldOfView
	end
end)

-- Non-blocking remote checking (Never yields or hangs script)
local remoteFolder = ReplicatedStorage:FindFirstChild("StaticsNewgenRemotes")
local Remotes = {
	Hello = remoteFolder and remoteFolder:FindFirstChild("Hello"),
	RoleSync = remoteFolder and remoteFolder:FindFirstChild("RoleSync"),
	Reset = remoteFolder and remoteFolder:FindFirstChild("ResetCharacter"),
	Hop = remoteFolder and remoteFolder:FindFirstChild("ServerHop"),
	Status = remoteFolder and remoteFolder:FindFirstChild("ActionStatus"),
	VerifyVR = remoteFolder and remoteFolder:FindFirstChild("VerifyVRAimCode"),
	Preferences = remoteFolder and remoteFolder:FindFirstChild("Preferences"),
	MMEvent = remoteFolder and remoteFolder:FindFirstChild("MMEvent"),
}
if Remotes.Hello then
	pcall(function()
		Remotes.Hello:FireServer({ vr = isVR, mobile = isMobile, device = device })
	end)
end

local DEFAULTS = {
	ActiveProfile = "Universal",
	Theme = "DarkDock",
	LayoutStyle = "Newgen",
	AimEnabled = false,
	StickyAim = true,
	WallCheck = true,
	TeamCheck = true,
	AimStrength = 0.35,
	AimRadius = 210,
	Prediction = true,
	PredictionTime = 0.08,
	MaxAimDistance = 650,
	CameraAssist = true,
	CameraFOVEnabled = false,
	CameraFOV = 78,
	ShowFOVCircle = true,
	FOVCircleOpacity = 0.75,
	FOVCircleThickness = 1.5,
	FOVCircleHue = 0.75,
	ESPEnabled = true,
	HighlightESP = true,
	NameESP = true,
	DistanceESP = true,
	RoleESP = true,
	VRESP = true,
	SkeletonESP = false,
	BoxESP = false,
	TracerESP = false,
	HealthESP = true,
	ESPTeamCheck = false,
	ThroughWalls = true,
	ESPMaxDistance = 850,
	ESPTextSize = isVR and 18 or 14,
	ESPFill = 0.28,
	EnemyColorHue = 0.98,
	TeammateColorHue = 0.48,
	PerformanceMode = isMobile and "Balanced" or "Off",
	CustomBackground = false,
	BackgroundHue = 0.75,
	BackgroundSaturation = 0.82,
	BackgroundValue = 0.85,
	BackgroundIntensity = 0.65,
	HitPart = "Body",
	
	-- Dedicated Murder Mystery Module Defaults
	MMEspEnabled = true,
	MMMurdererESP = true,
	MMSheriffESP = true,
	MMInnocentESP = true,
	MMGunDropESP = true,
	MMAutoGrabGun = true,
	MMAutoGrabDistance = 35,
	MMMurdererAlert = true,
	MMSheriffAlert = true,
	MMTrapESP = true,
	MMCoinESP = true,
	MMRadar = true,
	MMSilentAimMurderer = true,
	MMKnifePrediction = true,
	MMTeleportOffset = "Behind",
}
local Config = table.clone(DEFAULTS)

-- Load saved preferences in background without freezing main thread
if Remotes.Preferences and Remotes.Preferences:IsA("RemoteFunction") then
	task.spawn(function()
		local ok, saved = pcall(function()
			return Remotes.Preferences:InvokeServer("load")
		end)
		if ok and typeof(saved) == "table" then
			for key in pairs(DEFAULTS) do
				if saved[key] ~= nil then Config[key] = saved[key] end
			end
		end
	end)
end

Config.WallCheck = true

local VRConfig = {
	Enabled = false,
	Sticky = false,
	WallCheck = false,
	TeamCheck = false,
	Strength = 0.18,
	Cone = 15,
	MaxDistance = 500,
}

local State = {
	menuOpen = false,
	aimHeld = false,
	target = nil,
	weaponTarget = nil,
	lockedParts = {},
	lastTargetSeen = 0,
	roles = {},
	visuals = {},
	connections = {},
	profileChosen = false,
	dirty = false,
	vrUnlocked = player:GetAttribute("VRAimAuthorized") == true,
	sessionStarted = os.clock(),
	
	mmMurderer = nil,
	mmSheriff = nil,
	mmHero = nil,
	mmDroppedGun = nil,
	mmTraps = {},
	mmAlertDebounce = 0,
}
local UI = { pages = {}, nav = {}, refreshers = {}, bindings = {} }

local Themes = {
	DarkDock = { bg = Color3.fromRGB(10,10,13), panel = Color3.fromRGB(24,24,29), row = Color3.fromRGB(40,40,49), accent = Color3.fromRGB(139,92,246), accent2 = Color3.fromRGB(34,211,238), text = Color3.fromRGB(244,244,247), muted = Color3.fromRGB(148,150,166) },
	Skeet = { bg = Color3.fromRGB(17,15,18), panel = Color3.fromRGB(25,23,27), row = Color3.fromRGB(34,31,35), accent = Color3.fromRGB(112,170,54), accent2 = Color3.fromRGB(157,206,76), text = Color3.fromRGB(235,233,237), muted = Color3.fromRGB(136,132,141) },
	Emerald = { bg = Color3.fromRGB(15,18,18), panel = Color3.fromRGB(29,33,32), row = Color3.fromRGB(43,48,46), accent = Color3.fromRGB(52,211,153), accent2 = Color3.fromRGB(92,224,180), text = Color3.fromRGB(242,244,242), muted = Color3.fromRGB(142,150,146) },
}
local Theme = Themes[Config.Theme] or Themes.DarkDock

local function corner(parent, radius)
	local object = Instance.new("UICorner")
	object.CornerRadius = UDim.new(0, radius)
	object.Parent = parent
	return object
end
local function outline(parent, color, transparency, thickness)
	local object = Instance.new("UIStroke")
	object.Color = color
	object.Transparency = transparency or 0
	object.Thickness = thickness or 1
	object.Parent = parent
	return object
end
local function bindTheme(object, property, role)
	table.insert(UI.bindings, { object = object, property = property, role = role })
end
local function panel(parent, size, position, role)
	local object = Instance.new("Frame")
	object.Size = size
	object.Position = position or UDim2.new()
	object.BackgroundColor3 = Theme[role or "panel"]
	object.BorderSizePixel = 0
	object.Parent = parent
	corner(object, 12)
	local border = outline(object, Theme[role == "accent" and "accent2" or "row"], .68, 1)
	bindTheme(border, "Color", role == "accent" and "accent2" or "row")
	bindTheme(object, "BackgroundColor3", role or "panel")
	return object
end
local function label(parent, value, size, position, font, role, textSize)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Size = size
	object.Position = position or UDim2.new()
	object.Font = font or Enum.Font.Gotham
	object.Text = value
	object.TextColor3 = Theme[role or "text"]
	object.TextSize = textSize or 13
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Parent = parent
	bindTheme(object, "TextColor3", role or "text")
	return object
end
local function button(parent, value, size, position, role)
	local object = Instance.new("TextButton")
	object.Size = size
	object.Position = position or UDim2.new()
	object.BackgroundColor3 = Theme[role or "row"]
	object.BorderSizePixel = 0
	object.AutoButtonColor = false
	object.Font = Enum.Font.GothamBold
	object.Text = value
	object.TextColor3 = Theme.text
	object.TextSize = 11
	object.Parent = parent
	corner(object, 9)
	bindTheme(object, "BackgroundColor3", role or "row")
	bindTheme(object, "TextColor3", "text")
	object.MouseEnter:Connect(function()
		TweenService:Create(object, TweenInfo.new(.12), { BackgroundTransparency = .12 }):Play()
	end)
	object.MouseLeave:Connect(function()
		TweenService:Create(object, TweenInfo.new(.12), { BackgroundTransparency = 0 }):Play()
	end)
	return object
end

local function setAvatar(imageLabel, userId)
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and imageLabel.Parent then imageLabel.Image = image end
	end)
end

local function formatDuration(seconds)
	seconds = math.max(math.floor(seconds), 0)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function shadow(parent, transparency)
	local image = Instance.new("ImageLabel")
	image.Name = "Shadow"
	image.BackgroundTransparency = 1
	image.Image = "rbxassetid://1316045217"
	image.ImageColor3 = Color3.new()
	image.ImageTransparency = transparency or .45
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = Rect.new(10, 10, 118, 118)
	image.Size = UDim2.new(1, 34, 1, 34)
	image.Position = UDim2.fromOffset(-17, -17)
	image.ZIndex = math.max(parent.ZIndex - 1, 0)
	image.Parent = parent
	return image
end

local function pageHeader(page, titleText, subtitleText, accentRole)
	local accent = Theme[accentRole or "accent"]
	local line = Instance.new("Frame")
	line.Size = UDim2.fromOffset(4, 44)
	line.Position = UDim2.fromOffset(14, 15)
	line.BackgroundColor3 = accent
	line.BorderSizePixel = 0
	line.Parent = page
	corner(line, 2)
	local titleLabel = label(page, titleText, UDim2.new(1, -44, 0, 28), UDim2.fromOffset(28, 12), Enum.Font.GothamBlack, "text", 22)
	local subtitleLabel = label(page, subtitleText, UDim2.new(1, -44, 0, 21), UDim2.fromOffset(28, 40), Enum.Font.Gotham, "muted", 10)
	subtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	return titleLabel, subtitleLabel
end

-- Cleanup any previous UI
pcall(function()
	local old1 = targetParent:FindFirstChild("StaticsNewgenUI")
	if old1 then old1:Destroy() end
	if playerGui and playerGui ~= targetParent then
		local old2 = playerGui:FindFirstChild("StaticsNewgenUI")
		if old2 then old2:Destroy() end
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "StaticsNewgenUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = targetParent end)
if not gui.Parent and playerGui then gui.Parent = playerGui end

local dim = panel(gui, UDim2.fromScale(1,1), nil, "bg")
dim.BackgroundColor3 = Color3.new()
dim.BackgroundTransparency = .45
dim.Visible = false
local defaultBaseSize = isMobile and Vector2.new(640,760) or Vector2.new(860,550)
UI.layoutBaseSize = defaultBaseSize
UI.layoutFitWidth = defaultBaseSize.X + 24
local main = panel(gui, UDim2.fromOffset(defaultBaseSize.X,defaultBaseSize.Y), UDim2.fromScale(.5,.5), "bg")
main.AnchorPoint = Vector2.new(.5,.5)
main.Visible = false
local mainStroke=outline(main, Theme.accent, .28, 1.5)
shadow(main, .28)
local scale = Instance.new("UIScale")
scale.Parent = main
local function fitWindow()
	local viewport = camera and camera.ViewportSize or Vector2.new(1280,720)
	local size = UI.layoutBaseSize or defaultBaseSize
	scale.Scale = math.clamp(math.min(viewport.X/(UI.layoutFitWidth or(size.X+24)), viewport.Y/(size.Y+24)), isMobile and .42 or .55, 1)
end
fitWindow()

local top = panel(main, UDim2.new(1,0,0,58), nil, "panel")
local topSquare=Instance.new("Frame")
topSquare.Size=UDim2.new(1,0,0,14)
topSquare.Position=UDim2.new(0,0,1,-14)
topSquare.BackgroundColor3=Theme.panel
topSquare.BorderSizePixel=0
topSquare.Parent=top
bindTheme(topSquare,"BackgroundColor3","panel")
local topGradient = Instance.new("UIGradient")
topGradient.Color = ColorSequence.new(Theme.panel:Lerp(Theme.accent, .12), Theme.panel)
topGradient.Rotation = 12
topGradient.Parent = top
local logo = panel(top, UDim2.fromOffset(36,36), UDim2.fromOffset(14,11), "accent")
local logoText = label(logo, "S", UDim2.fromScale(1,1), nil, Enum.Font.GothamBlack, "bg", 18)
logoText.TextXAlignment = Enum.TextXAlignment.Center
label(top, "Statics Newgen", UDim2.fromOffset(190,24), UDim2.fromOffset(61,7), Enum.Font.GothamBold, "text", 16)
label(top, "discord.gg/rXxwRtaCQ", UDim2.fromOffset(210,18), UDim2.fromOffset(61,31), Enum.Font.Gotham, "muted", 10)
UI.saveStatus = label(top, "Ready", UDim2.fromOffset(150,20), UDim2.new(1,-240,0,19), Enum.Font.GothamBold, "muted", 10)
UI.saveStatus.TextXAlignment = Enum.TextXAlignment.Right
UI.saveStatus.Visible = not isMobile
local close = button(top, "X", UDim2.fromOffset(34,30), UDim2.new(1,-42,0,14), "row")
local minimize = button(top, "-", UDim2.fromOffset(34,30), UDim2.new(1,-82,0,14), "row")

do
	local dragging=false
	local dragStart=nil
	local startPosition=nil
	top.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true;dragStart=input.Position;startPosition=main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local delta=input.Position-dragStart
			main.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X/scale.Scale,startPosition.Y.Scale,startPosition.Y.Offset+delta.Y/scale.Scale)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
end

local sidebar = panel(main, isMobile and UDim2.new(1,0,0,62) or UDim2.new(0,116,1,-58), isMobile and UDim2.new(0,0,1,-62) or UDim2.fromOffset(0,58), "panel")
local content = Instance.new("Frame")
content.Size = isMobile and UDim2.new(1,0,1,-120) or UDim2.new(1,-116,1,-58)
content.Position = isMobile and UDim2.fromOffset(0,58) or UDim2.fromOffset(116,58)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = main

UI.rightRail = panel(main, UDim2.fromOffset(150,330), UDim2.new(1,14,0,78), "panel")
UI.rightRail.Visible = false
shadow(UI.rightRail,.55)
label(UI.rightRail,"STATICS NEWGEN",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,13),Enum.Font.GothamBlack,"text",12).TextXAlignment=Enum.TextXAlignment.Center
label(UI.rightRail,"SESSION",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,54),Enum.Font.GothamBold,"accent2",9)
UI.layoutStatus = label(UI.rightRail,"READY",UDim2.new(1,-20,0,28),UDim2.fromOffset(10,76),Enum.Font.GothamBlack,"text",14)
UI.layoutStatus.TextXAlignment=Enum.TextXAlignment.Center
label(UI.rightRail,"DEVICE",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,124),Enum.Font.GothamBold,"accent",9)
local railDevice=label(UI.rightRail,string.upper(device),UDim2.new(1,-20,0,28),UDim2.fromOffset(10,146),Enum.Font.GothamBlack,"text",14);railDevice.TextXAlignment=Enum.TextXAlignment.Center
label(UI.rightRail,"COMMUNITY",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,197),Enum.Font.GothamBold,"accent2",9)
local railDiscord=label(UI.rightRail,"discord.gg/\nrXxwRtaCQ",UDim2.new(1,-20,0,44),UDim2.fromOffset(10,222),Enum.Font.GothamBold,"text",10);railDiscord.TextWrapped=true;railDiscord.TextXAlignment=Enum.TextXAlignment.Center

local launcher = button(gui, "STATICS", UDim2.fromOffset(122,46), UDim2.new(0,16,1,-64), "accent")
launcher.Visible = false
launcher.TextColor3 = Color3.new(1,1,1)
launcher.TextSize = 13
local launcherGradient = Instance.new("UIGradient")
launcherGradient.Color = ColorSequence.new(Color3.fromRGB(165, 88, 247), Color3.fromRGB(104, 45, 214))
launcherGradient.Rotation = 18
launcherGradient.Parent = launcher
outline(launcher, Color3.fromRGB(218, 199, 255), .35, 1.5)
shadow(launcher, .45)

local showPage
local applyLayout

local toast=Instance.new("CanvasGroup")
toast.AnchorPoint=Vector2.new(1,0)
toast.Position=UDim2.new(1,-18,0,18)
toast.Size=UDim2.fromOffset(310,66)
toast.BackgroundColor3=Theme.panel
toast.BorderSizePixel=0
toast.GroupTransparency=1
toast.Visible=false
toast.ZIndex=500
toast.Parent=gui
corner(toast,12)
outline(toast,Theme.accent2,.3,1.5)
local toastTitle=label(toast,"STATICS",UDim2.new(1,-24,0,20),UDim2.fromOffset(12,8),Enum.Font.GothamBlack,"accent2",10);toastTitle.ZIndex=501
local toastMessage=label(toast,"",UDim2.new(1,-24,0,28),UDim2.fromOffset(12,29),Enum.Font.GothamMedium,"text",11);toastMessage.TextWrapped=true;toastMessage.ZIndex=501
local toastToken=0
local function notify(message,good)
	toastToken+=1
	local token=toastToken
	toast.Visible=true;toast.GroupTransparency=1;toast.Position=UDim2.new(1,20,0,18)
	toastTitle.Text=good==false and"ATTENTION"or"STATICS NEWGEN"
	toastTitle.TextColor3=good==false and Color3.fromRGB(248,75,90)or Theme.accent2
	toastMessage.Text=tostring(message)
	TweenService:Create(toast,TweenInfo.new(.22,Enum.EasingStyle.Quart),{GroupTransparency=0,Position=UDim2.new(1,-18,0,18)}):Play()
	task.delay(2.6,function()if token~=toastToken then return end;TweenService:Create(toast,TweenInfo.new(.2),{GroupTransparency=1,Position=UDim2.new(1,20,0,18)}):Play();task.wait(.22);if token==toastToken then toast.Visible=false end end)
end
UI.notify=notify

local setMenu = function(open)
	State.menuOpen = open
	local currentSize = UI.layoutBaseSize or defaultBaseSize
	if open then
		main.Visible = true
		dim.Visible = true
		launcher.Visible = false
		main.Size = UDim2.fromOffset(currentSize.X, currentSize.Y)
		dim.BackgroundTransparency = 0.45
	else
		main.Visible = false
		dim.Visible = false
		launcher.Visible = true
	end
end

close.Activated:Connect(function() setMenu(false) end)
minimize.Activated:Connect(function() setMenu(false) end)
launcher.Activated:Connect(function() setMenu(true) end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightShift then setMenu(not State.menuOpen) end
end)

local function newPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.fromScale(1,1)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	UI.pages[name] = page
	return page
end
local function scrollingPanel(parent,size,position,canvasHeight)
	local object=Instance.new("ScrollingFrame")
	object.Size=size;object.Position=position;object.BackgroundColor3=Theme.panel;object.BorderSizePixel=0;object.ScrollBarThickness=3;object.ScrollBarImageColor3=Theme.accent;object.CanvasSize=UDim2.fromOffset(0,canvasHeight);object.Parent=parent;corner(object,10);bindTheme(object,"BackgroundColor3","panel");return object
end

local navigation = {
	{ "Hub", "Game Hub" },
	{ "Home", "Overview" },
	{ "Aim", "Aim Assist" },
	{ "VRAim", "VR Assist" },
	{ "Words", "Final Letter", "The Final Letter" },
	{ "MurderMystery", "Murder Mystery", "Murder Mystery" },
	{ "Visuals", "Visuals" },
	{ "Performance", "Performance" },
	{ "Themes", "Themes" },
	{ "Colors", "Colors" },
	{ "Session", "Session" },
	{ "Players", "Players" },
}
UI.navVisuals = {}

local function navLine(parent, size, position, rotation)
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(.5,.5)
	line.Size = size
	line.Position = position
	line.Rotation = rotation or 0
	line.BackgroundColor3 = Theme.muted
	line.BorderSizePixel = 0
	line.Parent = parent
	corner(line, 3)
	return line
end

local function createNavIcon(parent, pageName)
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(24,24)
	icon.Position = UDim2.fromOffset(8,5)
	icon.BackgroundTransparency = 1
	icon.Parent = parent
	local pieces = {}
	local function add(size, position, rotation)
		local piece = navLine(icon, size, position, rotation)
		table.insert(pieces, piece)
		return piece
	end
	if pageName == "Hub" then
		for x=0,1 do for y=0,1 do add(UDim2.fromOffset(8,8),UDim2.fromOffset(7+x*10,7+y*10)) end end
	elseif pageName == "Home" then
		add(UDim2.fromOffset(15,3),UDim2.fromOffset(7,9),-42);add(UDim2.fromOffset(15,3),UDim2.fromOffset(17,9),42);add(UDim2.fromOffset(16,11),UDim2.fromOffset(12,16))
	elseif pageName == "Aim" then
		local ring=add(UDim2.fromOffset(17,17),UDim2.fromOffset(12,12));ring.BackgroundTransparency=1;local s=outline(ring,Theme.muted,0,2);table.insert(pieces,s);add(UDim2.fromOffset(23,2),UDim2.fromOffset(12,12));add(UDim2.fromOffset(2,23),UDim2.fromOffset(12,12))
	elseif pageName == "VRAim" then
		local headset=add(UDim2.fromOffset(22,13),UDim2.fromOffset(12,11));headset.BackgroundTransparency=1;local s=outline(headset,Theme.muted,0,2);table.insert(pieces,s);add(UDim2.fromOffset(7,5),UDim2.fromOffset(7,12));add(UDim2.fromOffset(7,5),UDim2.fromOffset(17,12));add(UDim2.fromOffset(8,2),UDim2.fromOffset(12,20))
	elseif pageName == "Words" then
		local left=add(UDim2.fromOffset(9,17),UDim2.fromOffset(7,12));left.BackgroundTransparency=1;table.insert(pieces,outline(left,Theme.muted,0,2));local right=add(UDim2.fromOffset(9,17),UDim2.fromOffset(17,12));right.BackgroundTransparency=1;table.insert(pieces,outline(right,Theme.muted,0,2))
	elseif pageName == "MurderMystery" then
		add(UDim2.fromOffset(16,3), UDim2.fromOffset(12,8), 45)
		add(UDim2.fromOffset(8,3), UDim2.fromOffset(7,17), -45)
		add(UDim2.fromOffset(3,7), UDim2.fromOffset(16,14), 45)
		add(UDim2.fromOffset(4,4), UDim2.fromOffset(18,6))
	elseif pageName == "Visuals" then
		local eye=add(UDim2.fromOffset(23,14),UDim2.fromOffset(12,12));eye.BackgroundTransparency=1;table.insert(pieces,outline(eye,Theme.muted,0,2));add(UDim2.fromOffset(7,7),UDim2.fromOffset(12,12))
	elseif pageName == "Performance" then
		add(UDim2.fromOffset(4,9),UDim2.fromOffset(5,16));add(UDim2.fromOffset(4,15),UDim2.fromOffset(12,13));add(UDim2.fromOffset(4,21),UDim2.fromOffset(19,10))
	elseif pageName == "Themes" then
		local a=add(UDim2.fromOffset(14,13),UDim2.fromOffset(9,9));a.BackgroundTransparency=1;table.insert(pieces,outline(a,Theme.muted,0,2));local b=add(UDim2.fromOffset(14,13),UDim2.fromOffset(15,15));b.BackgroundTransparency=1;table.insert(pieces,outline(b,Theme.muted,0,2))
	elseif pageName == "Colors" then
		local ring=add(UDim2.fromOffset(20,20),UDim2.fromOffset(12,12));ring.BackgroundTransparency=1;table.insert(pieces,outline(ring,Theme.muted,0,2));add(UDim2.fromOffset(5,5),UDim2.fromOffset(8,8));add(UDim2.fromOffset(5,5),UDim2.fromOffset(16,8));add(UDim2.fromOffset(5,5),UDim2.fromOffset(12,16))
	elseif pageName == "Session" then
		add(UDim2.fromOffset(18,3),UDim2.fromOffset(10,8));add(UDim2.fromOffset(8,3),UDim2.fromOffset(19,5),45);add(UDim2.fromOffset(18,3),UDim2.fromOffset(14,16));add(UDim2.fromOffset(8,3),UDim2.fromOffset(5,19),45)
	else
		add(UDim2.fromOffset(8,8),UDim2.fromOffset(8,8));add(UDim2.fromOffset(7,7),UDim2.fromOffset(17,9));add(UDim2.fromOffset(16,8),UDim2.fromOffset(9,18));add(UDim2.fromOffset(10,7),UDim2.fromOffset(18,18))
	end
	return icon,pieces
end

local function refreshNavigation()
	local visible = {}
	for _, spec in ipairs(navigation) do
		local show = not spec[3] or (State.profileChosen and Config.ActiveProfile == spec[3])
		UI.nav[spec[1]].Visible = show
		if show then table.insert(visible, spec) end
	end
	for index, spec in ipairs(visible) do
		local navButton = UI.nav[spec[1]]
		if isMobile or Config.LayoutStyle == "Horizon" then
			navButton.Size = UDim2.new(1/#visible,-4,0,48)
			navButton.Position = UDim2.new((index-1)/#visible,2,0,7)
			UI.navVisuals[spec[1]].title.Visible = false
			UI.navVisuals[spec[1]].icon.Position = UDim2.new(.5,-12,0,11)
		elseif Config.LayoutStyle == "Lynen" then
			local step=math.min(43,math.floor(406/#visible))
			local height=math.clamp(step-5,30,38)
			navButton.Size = UDim2.new(1,-14,0,height)
			navButton.Position = UDim2.fromOffset(7,7+(index-1)*step)
			UI.navVisuals[spec[1]].title.Visible = true
			UI.navVisuals[spec[1]].icon.Position = UDim2.fromOffset(8,7)
		else
			navButton.Size = UDim2.new(1,-16,0,34)
			navButton.Position = UDim2.fromOffset(8,7+(index-1)*38)
			UI.navVisuals[spec[1]].title.Visible = true
			UI.navVisuals[spec[1]].icon.Position = UDim2.fromOffset(8,5)
		end
	end
end

showPage=function(name)
	if name == "VRAim" and not State.vrUnlocked then UI.openVRGate(); return end
	State.currentPage=name
	for pageName, page in pairs(UI.pages) do
		local active = pageName == name
		page.Visible = active
		if active then
			page.Position = UDim2.new()
		end
	end
	for pageName, navButton in pairs(UI.nav) do
		local active = pageName == name
		navButton.BackgroundColor3 = active and Theme.accent or Theme.row
		local visual = UI.navVisuals[pageName]
		visual.title.TextColor3 = active and Theme.text or Theme.muted
		for _,piece in ipairs(visual.pieces) do
			if piece:IsA("UIStroke") then piece.Color=active and Theme.text or Theme.muted else piece.BackgroundColor3=active and Theme.text or Theme.muted end
		end
	end
end

for _, spec in ipairs(navigation) do
	local name = spec[1]
	local navButton = button(sidebar, "", UDim2.new(1,-16,0,34), nil, "row")
	local icon,pieces=createNavIcon(navButton,name)
	local title=label(navButton,spec[2],UDim2.new(1,-43,1,0),UDim2.fromOffset(38,0),Enum.Font.GothamBold,"muted",10)
	UI.nav[name] = navButton
	UI.navVisuals[name]={icon=icon,pieces=pieces,title=title}
	navButton.Activated:Connect(function() showPage(name) end)
end

applyLayout=function(layoutName,animate)
	if layoutName~="Newgen"and layoutName~="Lynen"and layoutName~="Horizon"then layoutName="Newgen"end
	Config.LayoutStyle=layoutName
	main.Position=UDim2.fromScale(.5,.5)
	local size = Vector2.new(860,550)
	if isMobile then
		size=Vector2.new(640,760)
	elseif layoutName=="Lynen" then
		size=Vector2.new(760,560)
	elseif layoutName=="Horizon" then
		size=Vector2.new(1080,640)
	end
	UI.layoutBaseSize=size
	main.Size=UDim2.fromOffset(size.X,size.Y)
	fitWindow()
	refreshNavigation()
end
UI.applyLayout=applyLayout

local function makeToggle(parent, title, y, getter, setter)
	local row = panel(parent, UDim2.new(1,-20,0,40), UDim2.fromOffset(10,y), "row")
	label(row, title, UDim2.new(1,-72,1,0), UDim2.fromOffset(10,0), Enum.Font.GothamMedium, "text", 12)
	local switch = button(row, "", UDim2.fromOffset(42,22), UDim2.new(1,-52,.5,-11), "row")
	local dot = panel(switch, UDim2.fromOffset(16,16), UDim2.fromOffset(3,3), "text")
	corner(switch,11); corner(dot,8)
	local function refresh()
		local enabled = getter()
		switch.BackgroundColor3 = enabled and Theme.accent or Color3.fromRGB(65,66,79)
		dot.Position = enabled and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)
	end
	switch.Activated:Connect(function() setter(not getter()); State.dirty = true; refresh() end)
	refresh(); table.insert(UI.refreshers,refresh); return refresh
end

local function makeSlider(parent,title,y,minimum,maximum,getter,setter)
	local row = panel(parent, UDim2.new(1,-20,0,58), UDim2.fromOffset(10,y), "row")
	label(row,title,UDim2.new(1,-80,0,24),UDim2.fromOffset(10,3),Enum.Font.GothamMedium,"text",12)
	local valueLabel = label(row,"",UDim2.fromOffset(70,24),UDim2.new(1,-80,0,3),Enum.Font.GothamBold,"accent2",11)
	valueLabel.TextXAlignment=Enum.TextXAlignment.Right
	local bar=button(row,"",UDim2.new(1,-20,0,8),UDim2.fromOffset(10,39),"row")
	local fill=panel(bar,UDim2.fromScale(0,1),nil,"accent")
	local dragging=false
	local function refresh() local n=getter();fill.Size=UDim2.fromScale(math.clamp((n-minimum)/(maximum-minimum),0,1),1);valueLabel.Text=tostring(math.floor(n*100+.5)/100) end
	local function setX(x) local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1);setter(minimum+(maximum-minimum)*a);State.dirty=true;refresh() end
	bar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;setX(input.Position.X) end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then setX(input.Position.X) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
	refresh()
end

local function buildHub()
	local page=newPage("Hub")
	pageHeader(page,"Game Hub","Choose a profile. Only its dedicated tools are added to navigation.","accent")
	local profiles={
		{"Universal","Core tools, device detection, aim, visuals, and performance.","accent"},
		{"The Final Letter","Keyboard capture, real-time recommendations, and one-tap filling.","accent2"},
		{"Murder Mystery","Dedicated Murderer & Sheriff Teleportation, Gun Drop ESP & Radar.","accent"},
	}
	for index,spec in ipairs(profiles) do
		local profileName=spec[1]
		local chosenProfile=profileName
		local card=panel(page,UDim2.new(1/3,-16,1,-104),UDim2.new((index-1)/3,10,0,78),"panel")
		shadow(card,.62)
		local accentLine=Instance.new("Frame");accentLine.Size=UDim2.new(1,0,0,5);accentLine.BackgroundColor3=Theme[spec[3]];accentLine.BorderSizePixel=0;accentLine.Parent=card;corner(accentLine,3)
		label(card,string.format("0%d",index),UDim2.new(1,-24,0,24),UDim2.fromOffset(12,17),Enum.Font.GothamBlack,spec[3],12).TextXAlignment=Enum.TextXAlignment.Right
		label(card,profileName,UDim2.new(1,-24,0,42),UDim2.fromOffset(12,47),Enum.Font.GothamBlack,"text",17).TextWrapped=true
		local description=label(card,spec[2],UDim2.new(1,-24,0,95),UDim2.fromOffset(12,98),Enum.Font.Gotham,"muted",10);description.TextWrapped=true;description.TextYAlignment=Enum.TextYAlignment.Top
		local btnLabel = chosenProfile=="Murder Mystery" and "POP UP MM2 SUITE" or "LOAD PROFILE"
		local load=button(card,btnLabel,UDim2.new(1,-24,0,42),UDim2.new(0,12,1,-54),spec[3])
		load.Activated:Connect(function()
			Config.ActiveProfile=chosenProfile;State.profileChosen=true;refreshNavigation();State.dirty=true
			if UI.notify then 
				if chosenProfile=="Murder Mystery" then
					UI.notify("Murder Mystery category popped up & unlocked!", true)
				else
					UI.notify(chosenProfile.." profile loaded", true)
				end
			end
			if chosenProfile=="The Final Letter" then
				Config.AimEnabled=false;Config.ESPEnabled=false;for _,refresh in ipairs(UI.refreshers)do refresh()end;showPage("Words")
			elseif chosenProfile=="Murder Mystery" then
				showPage("MurderMystery")
			else
				showPage("Home")
			end
		end)
	end
end

-- Robust MM2 Tool & Character Scanner (Searches both Hand & Backpack)
local function getPlayerWithTool(toolNames)
	if typeof(toolNames) == "string" then toolNames = { toolNames } end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if p.Character then
				for _, targetName in ipairs(toolNames) do
					if p.Character:FindFirstChild(targetName) then return p end
					for _, item in ipairs(p.Character:GetChildren()) do
						if item:IsA("Tool") and string.find(string.lower(item.Name), string.lower(targetName), 1, true) then
							return p
						end
					end
				end
			end
			local backpack = p:FindFirstChild("Backpack")
			if backpack then
				for _, targetName in ipairs(toolNames) do
					if backpack:FindFirstChild(targetName) then return p end
					for _, item in ipairs(backpack:GetChildren()) do
						if item:IsA("Tool") and string.find(string.lower(item.Name), string.lower(targetName), 1, true) then
							return p
						end
					end
				end
			end
		end
	end
	return nil
end

local function teleportToPlayer(targetPlayer, offsetMode)
	if not targetPlayer then
		if UI.notify then UI.notify("Player not found in match", false) end
		return false
	end
	local targetChar = targetPlayer.Character
	local myChar = player.Character
	if not targetChar or not myChar then
		if UI.notify then UI.notify("Character not spawned yet", false) end
		return false
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
	local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart
	if not targetRoot or not myRoot then return false end
	
	offsetMode = offsetMode or Config.MMTeleportOffset or "Behind"
	local offsetCFrame = CFrame.new(0, 0, 3.5)
	if offsetMode == "Above" then offsetCFrame = CFrame.new(0, 7, 0) end
	if offsetMode == "Direct" then offsetCFrame = CFrame.new(0, 0, -1.5) end
	
	myRoot.CFrame = targetRoot.CFrame * offsetCFrame
	if UI.notify then UI.notify("Teleported to " .. targetPlayer.DisplayName, true) end
	return true
end

local function buildMurderMystery()
	local page=newPage("MurderMystery")
	pageHeader(page,"Murder Mystery","Dedicated role scanner, teleportation suite, gun drop ESP, auto-grab, and killer radar.","accent")
	
	local left=scrollingPanel(page,UDim2.new(.58,-20,1,-82),UDim2.fromOffset(14,70),1100)
	local right=panel(page,UDim2.new(.42,-8,1,-82),UDim2.new(.58,0,0,70),"panel")
	
	label(left,"⚡ MM2 TELEPORTATION SUITE",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,10),Enum.Font.GothamBlack,"accent2",11)
	
	local tpMurdererBtn=button(left,"🔪 TELEPORT TO MURDERER",UDim2.new(1,-20,0,42),UDim2.fromOffset(10,38),"accent")
	tpMurdererBtn.BackgroundColor3=Color3.fromRGB(220,38,38)
	tpMurdererBtn.Activated:Connect(function()
		local murderer = getPlayerWithTool({"Knife", "KnifeTool", "Blade", "Dagger"})
		if murderer then
			teleportToPlayer(murderer, Config.MMTeleportOffset)
		else
			if UI.notify then UI.notify("Murderer not found or eliminated", false) end
		end
	end)
	
	local tpSheriffBtn=button(left,"🔫 TELEPORT TO SHERIFF",UDim2.new(1,-20,0,42),UDim2.fromOffset(10,86),"row")
	tpSheriffBtn.BackgroundColor3=Color3.fromRGB(8,145,178)
	tpSheriffBtn.Activated:Connect(function()
		local sheriff = getPlayerWithTool({"Gun", "Revolver", "GunTool", "Luger"})
		if sheriff then
			teleportToPlayer(sheriff, Config.MMTeleportOffset)
		else
			if UI.notify then UI.notify("Sheriff not found or dead", false) end
		end
	end)
	
	local tpGunBtn=button(left,"⭐ TELEPORT TO DROPPED GUN",UDim2.new(1,-20,0,42),UDim2.fromOffset(10,134),"row")
	tpGunBtn.BackgroundColor3=Color3.fromRGB(202,138,4)
	tpGunBtn.Activated:Connect(function()
		local gun=Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Revolver")
		if gun and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = gun.CFrame + Vector3.new(0, 1.5, 0)
			if UI.notify then UI.notify("Teleported to Gun Drop!", true) end
		else
			if UI.notify then UI.notify("No dropped gun found on map", false) end
		end
	end)
	
	local tpOffsetBtn=button(left,"TELEPORT OFFSET: " .. string.upper(Config.MMTeleportOffset or "Behind"),UDim2.new(1,-20,0,36),UDim2.fromOffset(10,182),"row")
	tpOffsetBtn.Activated:Connect(function()
		local modes={"Behind","Above","Direct"}
		local idx=table.find(modes, Config.MMTeleportOffset) or 1
		Config.MMTeleportOffset=modes[idx%#modes+1]
		tpOffsetBtn.Text="TELEPORT OFFSET: " .. string.upper(Config.MMTeleportOffset)
		if UI.notify then UI.notify("Teleport Offset set to " .. Config.MMTeleportOffset, true) end
	end)
	
	label(left,"👁️ ROLE ESP & AUTOMATION",UDim2.new(1,-20,0,24),UDim2.fromOffset(10,230),Enum.Font.GothamBlack,"accent",11)
	makeToggle(left,"Master MM ESP",260,function()return Config.MMEspEnabled end,function(v)Config.MMEspEnabled=v end)
	makeToggle(left,"Murderer ESP & Red Beacon",308,function()return Config.MMMurdererESP end,function(v)Config.MMMurdererESP=v end)
	makeToggle(left,"Sheriff & Hero ESP (Blue/Gold)",356,function()return Config.MMSheriffESP end,function(v)Config.MMSheriffESP=v end)
	makeToggle(left,"Innocent ESP (Green)",404,function()return Config.MMInnocentESP end,function(v)Config.MMInnocentESP=v end)
	makeToggle(left,"Dropped Gun ESP & Tracer",452,function()return Config.MMGunDropESP end,function(v)Config.MMGunDropESP=v end)
	makeToggle(left,"Auto Grab Dropped Gun",500,function()return Config.MMAutoGrabGun end,function(v)Config.MMAutoGrabGun=v end)
	makeSlider(left,"Auto Grab Distance",552,10,80,function()return Config.MMAutoGrabDistance end,function(v)Config.MMAutoGrabDistance=v end)
	makeToggle(left,"Murderer Knife Alert",616,function()return Config.MMMurdererAlert end,function(v)Config.MMMurdererAlert=v end)
	makeToggle(left,"Sheriff Dead / Gun Dropped Alert",664,function()return Config.MMSheriffAlert end,function(v)Config.MMSheriffAlert=v end)
	makeToggle(left,"Bear Trap ESP",712,function()return Config.MMTrapESP end,function(v)Config.MMTrapESP=v end)
	makeToggle(left,"Coin Spawn ESP",760,function()return Config.MMCoinESP end,function(v)Config.MMCoinESP=v end)
	makeToggle(left,"Murderer Proximity Radar",808,function()return Config.MMRadar end,function(v)Config.MMRadar=v end)
	makeToggle(left,"Silent Aim vs Murderer (Gun)",856,function()return Config.MMSilentAimMurderer end,function(v)Config.MMSilentAimMurderer=v end)
	makeToggle(left,"Knife Throw Prediction",904,function()return Config.MMKnifePrediction end,function(v)Config.MMKnifePrediction=v end)
	
	local closeCategoryBtn=button(left,"❌ HIDE / CLOSE MM2 CATEGORY",UDim2.new(1,-20,0,38),UDim2.fromOffset(10,954),"row")
	closeCategoryBtn.Activated:Connect(function()
		Config.ActiveProfile="Universal"
		refreshNavigation()
		showPage("Hub")
		if UI.notify then UI.notify("Murder Mystery category closed & hidden", true) end
	end)
	
	label(right,"LIVE MATCH ROLES",UDim2.new(1,-24,0,20),UDim2.fromOffset(12,12),Enum.Font.GothamBold,"accent",10)
	local rolesCard=panel(right,UDim2.new(1,-24,0,130),UDim2.fromOffset(12,36),"row")
	UI.mmMurdLabel=label(rolesCard,"MURDERER: SCANNING...",UDim2.new(1,-16,0,24),UDim2.fromOffset(10,8),Enum.Font.GothamBold,"muted",11)
	UI.mmSherLabel=label(rolesCard,"SHERIFF: SCANNING...",UDim2.new(1,-16,0,24),UDim2.fromOffset(10,34),Enum.Font.GothamBold,"accent2",11)
	UI.mmGunLabel=label(rolesCard,"GUN STATUS: WITH SHERIFF",UDim2.new(1,-16,0,24),UDim2.fromOffset(10,60),Enum.Font.GothamMedium,"text",10)
	UI.mmDistanceLabel=label(rolesCard,"MURDERER DISTANCE: --",UDim2.new(1,-16,0,24),UDim2.fromOffset(10,86),Enum.Font.GothamBlack,"accent",12)
end

-- Command Executor Engine (Supports Infinite Yield + Built-in Admin Commands)
local flying = false
local flyConn = nil
local noclip = false
local noclipConn = nil

local function launchInfiniteYield()
	if UI.notify then UI.notify("Launching Infinite Yield Admin Hub...", true) end
	task.spawn(function()
		local ok, err = pcall(function()
			loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
		end)
		if ok then
			if UI.notify then UI.notify("Infinite Yield loaded successfully!", true) end
		else
			warn("[Statics IY Error]: " .. tostring(err))
			if UI.notify then UI.notify("IY loadstring executed. Check console.", true) end
		end
	end)
end

local function executeAdminCommand(cmdText)
	if not cmdText or cmdText == "" then return end
	cmdText = string.gsub(cmdText, "^%s+", ""):gsub("%s+$", "")
	if string.sub(cmdText, 1, 1) == ";" or string.sub(cmdText, 1, 1) == ":" or string.sub(cmdText, 1, 1) == "/" then
		cmdText = string.sub(cmdText, 2)
	end
	
	local args = {}
	for word in string.gmatch(cmdText, "%S+") do table.insert(args, word) end
	local command = string.lower(args[1] or "")
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	
	if command == "iy" or command == "infiniteyield" or command == "admin" or string.find(cmdText, "githubusercontent", 1, true) then
		launchInfiniteYield()
		return
	elseif command == "fly" then
		flying = not flying
		if flying and root and hum then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "IYFlyVelocity"
			bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.Parent = root
			local bg = Instance.new("BodyGyro")
			bg.Name = "IYFlyGyro"
			bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			bg.P = 1e4
			bg.CFrame = root.CFrame
			bg.Parent = root
			
			if flyConn then flyConn:Disconnect() end
			flyConn = RunService.RenderStepped:Connect(function()
				if not flying or not root.Parent then
					if bv.Parent then bv:Destroy() end
					if bg.Parent then bg:Destroy() end
					if flyConn then flyConn:Disconnect() end
					return
				end
				local moveDir = hum.MoveDirection
				local cam = Workspace.CurrentCamera
				if moveDir.Magnitude > 0 and cam then
					bv.Velocity = (cam.CFrame.LookVector * moveDir.Z * -60) + (cam.CFrame.RightVector * moveDir.X * 60)
					bg.CFrame = cam.CFrame
				else
					bv.Velocity = Vector3.new(0, 0, 0)
					if cam then bg.CFrame = cam.CFrame end
				end
			end)
			if UI.notify then UI.notify("Fly enabled! Use WASD to fly.", true) end
		else
			flying = false
			if root then
				if root:FindFirstChild("IYFlyVelocity") then root.IYFlyVelocity:Destroy() end
				if root:FindFirstChild("IYFlyGyro") then root.IYFlyGyro:Destroy() end
			end
			if flyConn then flyConn:Disconnect() end
			if UI.notify then UI.notify("Fly disabled.", true) end
		end
	elseif command == "unfly" then
		flying = false
		if root then
			if root:FindFirstChild("IYFlyVelocity") then root.IYFlyVelocity:Destroy() end
			if root:FindFirstChild("IYFlyGyro") then root.IYFlyGyro:Destroy() end
		end
		if flyConn then flyConn:Disconnect() end
		if UI.notify then UI.notify("Fly disabled.", true) end
	elseif command == "speed" or command == "ws" or command == "walkspeed" then
		local num = tonumber(args[2]) or 100
		if hum then
			hum.WalkSpeed = num
			if UI.notify then UI.notify("WalkSpeed set to " .. num, true) end
		end
	elseif command == "jump" or command == "jp" or command == "jumppower" then
		local num = tonumber(args[2]) or 120
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = num
			if UI.notify then UI.notify("JumpPower set to " .. num, true) end
		end
	elseif command == "noclip" or command == "nc" then
		noclip = not noclip
		if noclip then
			if noclipConn then noclipConn:Disconnect() end
			noclipConn = RunService.Stepped:Connect(function()
				if not noclip then
					if noclipConn then noclipConn:Disconnect() end
					return
				end
				if player.Character then
					for _, part in ipairs(player.Character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end)
			if UI.notify then UI.notify("Noclip enabled!", true) end
		else
			if noclipConn then noclipConn:Disconnect() end
			if UI.notify then UI.notify("Noclip disabled.", true) end
		end
	elseif command == "clip" or command == "unnoclip" then
		noclip = false
		if noclipConn then noclipConn:Disconnect() end
		if UI.notify then UI.notify("Noclip disabled.", true) end
	elseif command == "btools" or command == "f3x" then
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			for _, binType in ipairs({Enum.BinType.Clone, Enum.BinType.Hammer, Enum.BinType.Grab}) do
				local b = Instance.new("HopperBin")
				b.BinType = binType
				b.Parent = backpack
			end
			if UI.notify then UI.notify("BTools (HopperBins) added to Backpack!", true) end
		end
	elseif command == "fullbright" or command == "fb" then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		if UI.notify then UI.notify("Fullbright enabled!", true) end
	elseif command == "god" or command == "godmode" then
		if hum then
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			if UI.notify then UI.notify("God mode health applied!", true) end
		end
	elseif command == "rejoin" or command == "rj" then
		if UI.notify then UI.notify("Rejoining current place...", true) end
		game:GetService("TeleportService"):Teleport(game.PlaceId, player)
	else
		-- Forward directly to Infinite Yield or run fallback
		if UI.notify then UI.notify("Executed command: " .. cmdText, true) end
		launchInfiniteYield()
	end
end

local function buildHome()
	local page=newPage("Home")
	pageHeader(page,"Overview","Live client session, Statics status, and Infinite Yield command suite.","accent")
	
	local leftScroll=scrollingPanel(page,UDim2.new(1,-28,1,-82),UDim2.fromOffset(14,70),820)
	
	-- 1. Identity Banner
	local identity=panel(leftScroll,UDim2.new(1,-20,0,88),UDim2.fromOffset(10,10),"panel")
	shadow(identity,.65)
	local avatar=Instance.new("ImageLabel");avatar.Size=UDim2.fromOffset(60,60);avatar.Position=UDim2.fromOffset(14,14);avatar.BackgroundColor3=Theme.row;avatar.BorderSizePixel=0;avatar.Parent=identity;corner(avatar,14);outline(avatar,Theme.accent2,.35,1.5);setAvatar(avatar,player.UserId)
	label(identity,player.DisplayName,UDim2.new(1,-320,0,26),UDim2.fromOffset(88,14),Enum.Font.GothamBlack,"text",18)
	label(identity,"@"..player.Name.."  /  "..string.upper(device),UDim2.new(1,-320,0,18),UDim2.fromOffset(88,42),Enum.Font.Gotham,"muted",10)
	UI.overviewRole=label(identity,"CLIENT: READY",UDim2.fromOffset(140,32),UDim2.new(1,-154,.5,-16),Enum.Font.GothamBold,"accent2",10);UI.overviewRole.TextXAlignment=Enum.TextXAlignment.Center;UI.overviewRole.BackgroundTransparency=0;UI.overviewRole.BackgroundColor3=Theme.row;corner(UI.overviewRole,9)
	
	-- 2. INFINITE YIELD COMMAND BAR & RUNNER (New Dedicated Space)
	local iyCard=panel(leftScroll,UDim2.new(1,-20,0,210),UDim2.fromOffset(10,110),"panel")
	shadow(iyCard,.4)
	outline(iyCard,Theme.accent2,.4,1.5)
	
	local iyHeader=label(iyCard,"⚡ INFINITE YIELD COMMAND BAR",UDim2.new(1,-180,0,22),UDim2.fromOffset(14,12),Enum.Font.GothamBlack,"accent2",12)
	local iyLaunchBtn=button(iyCard,"🚀 LAUNCH IY HUB",UDim2.fromOffset(150,30),UDim2.new(1,-164,0,8),"accent")
	iyLaunchBtn.Activated:Connect(function()
		launchInfiniteYield()
	end)
	
	-- Command Input Row
	local cmdInputBox=Instance.new("TextBox")
	cmdInputBox.Size=UDim2.new(1,-130,0,40)
	cmdInputBox.Position=UDim2.fromOffset(14,44)
	cmdInputBox.BackgroundColor3=Theme.row
	cmdInputBox.BorderSizePixel=0
	cmdInputBox.Font=Enum.Font.GothamBold
	cmdInputBox.PlaceholderText="Type admin command (e.g. fly, speed 100, noclip, btools, iy)..."
	cmdInputBox.PlaceholderColor3=Theme.muted
	cmdInputBox.Text=""
	cmdInputBox.TextColor3=Color3.fromRGB(255,255,255)
	cmdInputBox.TextSize=12
	cmdInputBox.TextXAlignment=Enum.TextXAlignment.Left
	cmdInputBox.ClearTextOnFocus=false
	cmdInputBox.Parent=iyCard
	corner(cmdInputBox,10)
	outline(cmdInputBox,Theme.accent,.5,1)
	
	local pad=Instance.new("UIPadding")
	pad.PaddingLeft=UDim.new(0,12)
	pad.PaddingRight=UDim.new(0,12)
	pad.Parent=cmdInputBox
	
	local execBtn=button(iyCard,"EXECUTE",UDim2.fromOffset(100,40),UDim2.new(1,-114,0,44),"accent2")
	execBtn.TextColor3=Color3.fromRGB(10,10,15)
	
	local function doRun()
		local text = cmdInputBox.Text
		if text and text ~= "" then
			executeAdminCommand(text)
			cmdInputBox.Text = ""
		end
	end
	
	execBtn.Activated:Connect(doRun)
	cmdInputBox.FocusLost:Connect(function(enter)
		if enter then doRun() end
	end)
	
	-- Quick Command Chips (Fly, Speed, Noclip, Btools, Fullbright, God)
	label(iyCard,"QUICK ADMIN COMMANDS:",UDim2.new(1,-28,0,18),UDim2.fromOffset(14,94),Enum.Font.GothamBold,"muted",9)
	local chips = {
		{ name = ";fly", cmd = "fly", color = "accent" },
		{ name = ";speed 100", cmd = "speed 100", color = "row" },
		{ name = ";noclip", cmd = "noclip", color = "row" },
		{ name = ";btools", cmd = "btools", color = "row" },
		{ name = ";fullbright", cmd = "fullbright", color = "row" },
		{ name = ";god", cmd = "god", color = "accent2" },
	}
	for idx, chip in ipairs(chips) do
		local chipBtn=button(iyCard, chip.name, UDim2.fromOffset(80, 26), UDim2.fromOffset(14 + (idx-1)*88, 116), chip.color)
		chipBtn.TextSize=10
		chipBtn.Activated:Connect(function()
			executeAdminCommand(chip.cmd)
		end)
	end
	
	local iyInfo=label(iyCard,"Runs Infinite Yield Hub or standalone native admin commands instantly.",UDim2.new(1,-28,0,24),UDim2.fromOffset(14,152),Enum.Font.Gotham,"muted",9)
	iyInfo.TextWrapped=true
	
	-- 3. Server & Systems 2-Card Grid
	local serverCard=panel(leftScroll,UDim2.new(.5,-15,0,180),UDim2.fromOffset(10,332),"panel")
	local systemsCard=panel(leftScroll,UDim2.new(.5,-15,0,180),UDim2.new(.5,5,0,332),"panel")
	
	label(serverCard,"SERVER METRICS",UDim2.new(1,-20,0,20),UDim2.fromOffset(10,10),Enum.Font.GothamBlack,"accent2",10)
	label(serverCard,"Network Ping: 32ms | Place ID: " .. tostring(game.PlaceId),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,34),Enum.Font.GothamBold,"text",10)
	label(serverCard,"Players Online: " .. tostring(#Players:GetPlayers()),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,58),Enum.Font.GothamBold,"text",10)
	label(serverCard,"Session Time: " .. formatDuration(os.clock() - State.sessionStarted),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,82),Enum.Font.Gotham,"muted",10)
	
	label(systemsCard,"STATICS CORE SYSTEMS",UDim2.new(1,-20,0,20),UDim2.fromOffset(10,10),Enum.Font.GothamBlack,"accent",10)
	label(systemsCard,"Aim Assist: " .. (Config.AimEnabled and "ACTIVE" or "OFF"),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,34),Enum.Font.GothamBold,"text",10)
	label(systemsCard,"Visuals (ESP): " .. (Config.ESPEnabled and "ACTIVE" or "OFF"),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,58),Enum.Font.GothamBold,"text",10)
	label(systemsCard,"Wall Check: ALWAYS ENFORCED",UDim2.new(1,-20,0,20),UDim2.fromOffset(10,82),Enum.Font.GothamBold,"accent2",10)
	
	-- 4. Community Box
	local comm=panel(leftScroll,UDim2.new(1,-20,0,60),UDim2.fromOffset(10,524),"panel")
	label(comm,"STATICS COMMUNITY: discord.gg/rXxwRtaCQ",UDim2.new(1,-24,0,24),UDim2.fromOffset(12,18),Enum.Font.GothamBlack,"text",12)
end

local function buildAim()
	local page=newPage("Aim")
	pageHeader(page,"Aim Assist","Smooth right-click assistance with optional weapon-direction correction.","accent")
	local left=scrollingPanel(page,UDim2.new(.58,-20,1,-82),UDim2.fromOffset(14,70),980)
	makeToggle(left,"Master aim assist",10,function()return Config.AimEnabled end,function(v)Config.AimEnabled=v;if not v then State.target=nil end end)
	makeToggle(left,"Sticky target",58,function()return Config.StickyAim end,function(v)Config.StickyAim=v end)
	makeToggle(left,"Wall check",106,function()return true end,function()Config.WallCheck=true end)
	makeToggle(left,"Team check",154,function()return Config.TeamCheck end,function(v)Config.TeamCheck=v end)
	makeToggle(left,"Camera assist",202,function()return Config.CameraAssist end,function(v)Config.CameraAssist=v end)
	makeToggle(left,"Show FOV circle",250,function()return Config.ShowFOVCircle end,function(v)Config.ShowFOVCircle=v end)
	makeSlider(left,"Strength",302,.02,.85,function()return Config.AimStrength end,function(v)Config.AimStrength=v end)
	makeSlider(left,"FOV radius",366,40,500,function()return Config.AimRadius end,function(v)Config.AimRadius=v end)
end

local function buildVRAim()
	local page=newPage("VRAim")
	pageHeader(page,"VR Aim Assist","Code-protected muzzle assistance. Every VR toggle starts off each execution.","accent2")
	local left=scrollingPanel(page,UDim2.new(.58,-20,1,-82),UDim2.fromOffset(14,70),500)
	makeToggle(left,"VR player assist",10,function()return VRConfig.Enabled end,function(v)VRConfig.Enabled=v end)
	makeToggle(left,"Sticky VR",58,function()return VRConfig.Sticky end,function(v)VRConfig.Sticky=v end)
	makeSlider(left,"Strength",110,.02,.8,function()return VRConfig.Strength end,function(v)VRConfig.Strength=v end)
end

local function buildVisuals()
	local page=newPage("Visuals")
	pageHeader(page,"Visuals","Rig-safe highlights, labels, roles, distance, VR badges, and skeletons.","accent2")
	local left=scrollingPanel(page,UDim2.new(.58,-20,1,-82),UDim2.fromOffset(14,70),930)
	makeToggle(left,"Master ESP",10,function()return Config.ESPEnabled end,function(v)Config.ESPEnabled=v end)
	makeToggle(left,"Highlight",58,function()return Config.HighlightESP end,function(v)Config.HighlightESP=v end)
	makeToggle(left,"Nameplates",106,function()return Config.NameESP end,function(v)Config.NameESP=v end)
	makeToggle(left,"Distance",154,function()return Config.DistanceESP end,function(v)Config.DistanceESP=v end)
	makeToggle(left,"Known roles",202,function()return Config.RoleESP end,function(v)Config.RoleESP=v end)
	makeToggle(left,"VR badge",250,function()return Config.VRESP end,function(v)Config.VRESP=v end)
	makeToggle(left,"Skeleton",298,function()return Config.SkeletonESP end,function(v)Config.SkeletonESP=v end)
	makeToggle(left,"2D boxes",346,function()return Config.BoxESP end,function(v)Config.BoxESP=v end)
	makeToggle(left,"Screen tracers",394,function()return Config.TracerESP end,function(v)Config.TracerESP=v end)
	makeToggle(left,"Health bars",442,function()return Config.HealthESP end,function(v)Config.HealthESP=v end)
end

local function buildWords()
	local page=newPage("Words")
	pageHeader(page,"The Final Letter","Global keyboard capture with chat exclusion and instant recommendations.","accent2")
	UI.wordLabel=label(page,"TYPE LETTERS ANYWHERE",UDim2.new(1,-28,0,42),UDim2.fromOffset(14,62),Enum.Font.GothamBlack,"accent2",18);UI.wordLabel.TextXAlignment=Enum.TextXAlignment.Center
end

local function buildUtilities()
	local performance=newPage("Performance")
	pageHeader(performance,"Performance","Local render profiles. No map objects are deleted.","accent2")
	local themes=newPage("Themes")
	pageHeader(themes,"Interface Studio","Choose a color system and a structural layout.","accent")
	local colors=newPage("Colors")
	pageHeader(colors,"Color Studio","Blend a custom hue into the active theme background.","accent2")
	local session=newPage("Session")
	pageHeader(session,"Session","Server-authoritative session actions with cooldown feedback.","accent2")
	local playersPage=newPage("Players")
	pageHeader(playersPage,"Players","Inspect connected players, known roles, and device status.","accent")
end

buildHub()
buildHome()
buildAim()
buildVRAim()
buildVisuals()
buildWords()
buildMurderMystery()
buildUtilities()

-- Fast Instant Opener (Guaranteed zero stuck loading)
refreshNavigation()
setMenu(true)
showPage("Hub")

task.spawn(function()
	if Config.ActiveProfile == "Murder Mystery" then
		showPage("MurderMystery")
	end
	if UI.notify then
		UI.notify("Statics Newgen loaded instantly! Press RightShift to toggle.", true)
	end
end)

print("[StaticsNewgen] Loaded successfully and opened menu.")

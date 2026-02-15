Players = cloneref(game:GetService("Players"))
RunService = cloneref(game:GetService("RunService"))
ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
LocalPlayer = Players.LocalPlayer
Character = LocalPlayer.Character
Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
	Humanoid = char:WaitForChild("Humanoid")
end)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/454244513/WindUIFix/refs/heads/main/main.lua"))()
local Window = WindUI:CreateWindow({
	Title = "BEN",
	Author = "BEN",
    OpenButton = {
		Title = "BEN",
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 3,
		Color = ColorSequence.new( -- gradient
			Color3.fromHex("f9a8d4"),
			Color3.fromHex("f9a8d4")
		),
		OnlyMobile = false,
		Enabled = true,
		Draggable = true,
		Scale = 0.5,
	},
})

local Tab = Window:Tab({
	Title = "Blade",
})
Tab:Select()

Tab:Paragraph({
	Title = "NONE",
	Desc = "NONE",
})

Tab:Paragraph({
	Title = "Free",
	Desc = "Prohibited from reselling",
})

Tab:Toggle({
	Title = "Blade Aura",
	Callback = function(state)
		bladeaura = state
	end,
})

-- New feature variables
local raygunEnabled = false
local killoppEnabled = false
local ignoreFriendsEnabled = false

-- Raygun aimbot initialization
local Camera = workspace.CurrentCamera
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = 200
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-- Get first gun GUID
local wepguid
local devv = require(ReplicatedStorage.devv)
local item = devv.load("v3item")
for i, v in next, (item.inventory and item.inventory.items or {}) do
	if v.type == "Gun" then
		wepguid = v.guid
		print("Found gun GUID:", wepguid)
		break
	end
end

-- Find remote event (fallback)
local function findRemoteEvent(eventName)
	for _, v in next, getgc(false) do
		if typeof(v) == "function" then
			local source = debug.info(v, "s")
			local name = debug.info(v, "n")
			if source and source:find("Signal") and name == "FireServer" then
				local success, upvalue = pcall(getupvalue, v, 1)
				if success and upvalue and typeof(upvalue) == "table" then
					for k, remote in pairs(upvalue) do
						if k == eventName then
							return typeof(remote) == "string" and ReplicatedStorage.devv.remoteStorage[remote] or remote
						end
					end
				end
				break
			end
		end
	end
	return nil
end

local replicateProjectiles = ReplicatedStorage.devv.remoteStorage:FindFirstChild("replicateProjectiles") or findRemoteEvent("replicateProjectiles")
local projectileHit = ReplicatedStorage.devv.remoteStorage:FindFirstChild("projectileHit") or findRemoteEvent("projectileHit")

local guid = require(ReplicatedStorage.devv.shared.Helpers.string.GUID)

-- Check if player is friend
local function isFriend(player)
	return LocalPlayer:IsFriendsWith(player.UserId)
end

-- Get closest player in FOV
local function getClosestPlayer()
	local closestCharacter
	local closestDistance = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if ignoreFriendsEnabled and isFriend(player) then
				continue
			end
			local character = player.Character
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local head = character:FindFirstChild("Head")
			if humanoid and humanoid.Health > 0 and rootPart and head then
				local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - FOVCircle.Position).Magnitude
					if distanceFromCenter <= FOVCircle.Radius then
						local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
						if distance < closestDistance then
							closestCharacter = character
							closestDistance = distance
						end
					end
				end
			end
		end
	end
	return closestCharacter
end

-- Raygun shot logic (called every frame)
local function doRaygunShot()
	if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0) then
		return
	end
	local targetChar = getClosestPlayer()
	if targetChar then
		local newGuid = guid()
		local spawnArgs = {
			[1] = wepguid,
			[2] = {
				[1] = {
					[1] = newGuid,
					[2] = targetChar.Head.CFrame
				}
			},
			[3] = "semi"
		}
		local hitArgs = {
			[1] = newGuid,
			[2] = "player",
			[3] = {
				hitPart = targetChar.Hitbox.Head_Hitbox,
				hitPlayerId = Players:GetPlayerFromCharacter(targetChar).UserId,
				hitSize = targetChar.Head.Size,
				pos = targetChar.Head.CFrame
			}
		}
		replicateProjectiles:FireServer(unpack(spawnArgs))
		projectileHit:FireServer(unpack(hitArgs))
	end
end

-- Raygun loop control
local raygunLoopRunning = false
local raygunLoopThread = nil

-- New UI toggles
Tab:Toggle({
	Title = "Raygun Aim",
	Callback = function(state)
		raygunEnabled = state
		FOVCircle.Visible = state
		if state then
			if not raygunLoopRunning then
				raygunLoopRunning = true
				raygunLoopThread = task.spawn(function()
					while raygunLoopRunning do
						doRaygunShot()
						task.wait(0.03)
					end
				end)
			end
		else
			raygunLoopRunning = false
			raygunLoopThread = nil
		end
	end,
})

Tab:Toggle({
	Title = "Killopp Toggle",
	Callback = function(state)
		killoppEnabled = state
		-- Add killopp logic here if needed
	end,
})

Tab:Toggle({
	Title = "Ignore Friends",
	Callback = function(state)
		ignoreFriendsEnabled = state
	end,
})

-- Original blade aura logic
load = require(ReplicatedStorage.devv).load
Signal = load("Signal")
FireServer = Signal.FireServer
InvokeServer = Signal.InvokeServer
GUID = load("GUID")
v3item = load("v3item")
Raycast = load("Raycast")
local inventory = v3item.inventory

hackthrow = function(plr, itemname, itemguid, velocity, epos)
	if plr ~= LocalPlayer then
		return
	end
	task.spawn(function()
		local throwGuid = GUID()
		local success, stickyId =
			InvokeServer("throwSticky", throwGuid, itemname, itemguid, velocity, epos)
		if not success then
			return
		end
		local dummyPart = Instance.new("Part")
		dummyPart.Size = Vector3.new(2, 2, 2)
		dummyPart.Position = epos
		dummyPart.Anchored = true
		dummyPart.Transparency = 1
		dummyPart.CanCollide = true
		dummyPart.Parent = workspace
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.FilterDescendantsInstances = { plr.Character, workspace.Game.Local, workspace.Game.Drones }
		local dist = (epos - plr.Character.Head.Position).Magnitude
		local rayResult = workspace:Raycast(
			plr.Character.Head.Position,
			(epos - plr.Character.Head.Position).Unit * (dist + 5),
			rayParams
		)
		if rayResult and rayResult.Instance then
			local hitPart = rayResult.Instance
			local relativeHitCFrame =
				hitPart.CFrame:ToObjectSpace(CFrame.new(rayResult.Position, rayResult.Position + rayResult.Normal))
			local stickyCFrame = CFrame.new(rayResult.Position)
			if dummyPart.Parent then
				dummyPart:Destroy()
			end
			getgenv().throwargs = {
				"hitSticky",
				stickyId or throwGuid,
				hitPart,
				relativeHitCFrame,
				stickyCFrame,
			}
			InvokeServer("hitSticky", stickyId or throwGuid, hitPart, relativeHitCFrame, stickyCFrame)
		else
			if dummyPart.Parent then
				dummyPart:Destroy()
			end
		end
	end)
end

getinventory = function()
	return inventory.items
end

finditem = function(string)
	for guid, data in next, getinventory() do
		if data.name == string or data.type == string or data.subtype == string then
			return data
		end
	end
end

executebladekill = function(plr, head)
	local item = finditem("Ninja Star")
	if item then
		FireServer("equip", item.guid)

		if not getgenv().throwargs then
			local spos = LocalPlayer.Character.RightHand.Position
			local epos = head.Position
			local velocity = (epos - spos).Unit * ((spos - epos).Magnitude * 15)
			task.spawn(InvokeServer, "attemptPurchaseAmmo", "Ninja Star")
			hackthrow(LocalPlayer, "Ninja Star", item.guid, velocity, epos)
		end

		if getgenv().throwargs then
			getgenv().throwargs[3] = head
			task.spawn(InvokeServer, unpack(getgenv().throwargs))
		end
	else
		task.spawn(InvokeServer, "attemptPurchase", "Ninja Star")
	end
end

RunService.Heartbeat:Connect(function()
	if bladeaura and HumanoidRootPart then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then
				continue
			end
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local head = char and char:FindFirstChild("Head")
			local dist = (HumanoidRootPart.Position - head.Position).Magnitude
			if hum and hum.Health > 0 and head and dist < 190 then
				executebladekill(plr, head)
				break
			end
		end
	end
end)

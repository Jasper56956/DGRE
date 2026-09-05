-- Dungeon 3D Barrier & Melee Push-Out (Standalone Module for GitHub)
if _G.DgnBarrier and type(_G.DgnBarrier.Stop) == "function" then
	_G.DgnBarrier.Stop()
end

local P = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")
local W = workspace

local Barrier = {
	Config = {
		Push = true,       -- เปิด/ปิด การดัน Melee
		Barrier = true,    -- เปิด/ปิด การแสดงผลบาเรีย 3D
		Buffer = 7.0       -- ระยะปลอดภัยเพิ่มเติม (studs)
	},
	Connections = {},
	Bars = {},
	IsRunning = false
}

-- Scan Dungeon Mobs
local function getMobs()
	local m = {}
	local D = W:FindFirstChild("dungeon")
	if not D then return m end

	for _, r in ipairs(D:GetChildren()) do
		local ef = r:FindFirstChild("enemyFolder")
		if ef then
			for _, mob in ipairs(ef:GetChildren()) do
				local hum = mob:FindFirstChild("Humanoid")
				local hrp = mob:FindFirstChild("HumanoidRootPart")
				if hum and hrp and hum.Health > 0 then
					local st = mob:FindFirstChild("enemyStyle") and mob.enemyStyle.Value or "melee"
					local atk = (st == "melee" and mob:FindFirstChild("meleeDistance") and mob.meleeDistance.Value) 
						or (mob:FindFirstChild("attackDistance") and mob.attackDistance.Value) or 4
					table.insert(m, { mob = mob, hrp = hrp, st = st, atk = atk })
				end
			end
		end
	end
	return m
end

-- Update 3D Barrier Part
local function upBar(d)
	local mob, hrp, st, atk = d.mob, d.hrp, d.st, d.atk
	local b = Barrier.Bars[mob]

	if not Barrier.Config.Barrier then
		if b then 
			b:Destroy()
			Barrier.Bars[mob] = nil 
		end
		return
	end

	if not b then
		b = Instance.new("Part")
		b.Shape = Enum.PartType.Ball
		b.Material = Enum.Material.ForceField
		b.Transparency = 0.6
		b.Anchored = true
		b.CanCollide = false
		b.CastShadow = false
		b.Color = (st == "melee") and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(65, 170, 255)
		b.Parent = W.CurrentCamera
		Barrier.Bars[mob] = b
	end

	local dia = (atk + Barrier.Config.Buffer) * 2
	b.Size = Vector3.new(dia, dia, dia)
	b.CFrame = hrp.CFrame
end

-- เริ่มการทำงาน
function Barrier.Start()
	if Barrier.IsRunning then return end
	Barrier.IsRunning = true

	local conn = RS.Heartbeat:Connect(function()
		local char = P.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (root and hum and hum.Health > 0) then return end

		local pPos = root.Position
		local mobs = getMobs()
		local active = {}

		for _, d in ipairs(mobs) do
			active[d.mob] = true
			upBar(d)

			-- ดันผู้เล่นออกเฉพาะมอนสเตอร์ Melee
			if Barrier.Config.Push and d.st == "melee" then
				local mPos = d.hrp.Position
				local flatDist = Vector3.new(pPos.X - mPos.X, 0, pPos.Z - mPos.Z).Magnitude
				local safeR = d.atk + Barrier.Config.Buffer

				if flatDist < safeR then
					local pen = safeR - flatDist
					local pushDir = Vector3.new(pPos.X - mPos.X, 0, pPos.Z - mPos.Z).Unit
					char:TranslateBy(pushDir * math.min(pen, 1.2))

					local vel = root.AssemblyLinearVelocity
					local inwardSpd = vel:Dot(-pushDir)
					if inwardSpd > 0 then
						root.AssemblyLinearVelocity = vel + (pushDir * inwardSpd)
					end
				end
			end
		end

		-- ลบบาเรียของมอนสเตอร์ที่ตายหรือหายไปแล้ว
		for m, b in pairs(Barrier.Bars) do
			if not active[m] or not m.Parent then
				b:Destroy()
				Barrier.Bars[m] = nil
			end
		end
	end)

	table.insert(Barrier.Connections, conn)
end

-- หยุดการทำงาน และลบ Part ทั้งหมด
function Barrier.Stop()
	Barrier.IsRunning = false
	for _, c in ipairs(Barrier.Connections) do
		c:Disconnect()
	end
	table.clear(Barrier.Connections)

	for m, b in pairs(Barrier.Bars) do
		b:Destroy()
	end
	table.clear(Barrier.Bars)
end

-- ฟังก์ชันช่วยตั้งค่า (Helper Functions)
function Barrier.SetPush(state)
	Barrier.Config.Push = state
end

function Barrier.SetBarrier(state)
	Barrier.Config.Barrier = state
	if not state then
		for m, b in pairs(Barrier.Bars) do
			b:Destroy()
		end
		table.clear(Barrier.Bars)
	end
end

function Barrier.SetDistance(val)
	Barrier.Config.Buffer = tonumber(val) or Barrier.Config.Buffer
end

-- เริ่มทำงานทันที และเก็บไว้ใน Global
Barrier.Start()
_G.DgnBarrier = Barrier
_G.DgnKite = Barrier.Stop -- คง _G.DgnKite เดิมไว้เพื่อความ compatible

return Barrier
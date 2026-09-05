-- ==========================================
-- Speed Boost Module (Core / Backend for Loader)
-- ==========================================
if _G.SpeedBoost and type(_G.SpeedBoost.Stop) == "function" then
	_G.SpeedBoost.Stop()
elseif type(_G.SpeedBoost) == "function" then
	_G.SpeedBoost()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SpeedBoost = {}
SpeedBoost.__index = SpeedBoost

local cfg = {
	enabled = false,
	speed = 20
}

local connections = {}

-- Main Speed Loop
local heartbeatConn = RunService.Heartbeat:Connect(function()
	if not cfg.enabled then return end

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum and hum.Health > 0) then return end

	if hum.MoveDirection.Magnitude > 0.01 then
		local dir = hum.MoveDirection
		local vel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(dir.X * cfg.speed, vel.Y, dir.Z * cfg.speed)
	end
end)
table.insert(connections, heartbeatConn)

--- เปิด/ปิด การทำงาน (true / false)
function SpeedBoost.SetEnabled(val: boolean)
	cfg.enabled = (val == true)
	return cfg.enabled
end

--- ปรับความเร็วเป้าหมาย
function SpeedBoost.SetSpeed(val: number)
	if type(val) == "number" then
		cfg.speed = val
	end
	return cfg.speed
end

--- สลับสถานะเปิด/ปิด
function SpeedBoost.Toggle()
	cfg.enabled = not cfg.enabled
	return cfg.enabled
end

--- อ่านค่าคอนฟิกปัจจุบัน
function SpeedBoost.GetConfig()
	return {
		enabled = cfg.enabled,
		speed = cfg.speed
	}
end

--- หยุดการทำงานและตัดการเชื่อมต่อทั้งหมด
function SpeedBoost.Stop()
	cfg.enabled = false
	for _, conn in ipairs(connections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(connections)
	if _G.SpeedBoost == SpeedBoost then
		_G.SpeedBoost = nil
	end
end

-- Export ไปยัง _G และ Return Table ให้ Loader
_G.SpeedBoost = SpeedBoost
return SpeedBoost
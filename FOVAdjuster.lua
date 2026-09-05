local R = game:GetService("RunService")
local cam = workspace.CurrentCamera

if _G.FOVAdjuster and type(_G.FOVAdjuster.Stop) == "function" then
	_G.FOVAdjuster.Stop()
end

local FOV = {}
FOV.__index = FOV

local cfg = { on = false, val = 70, def = 70, min = 30, max = 120 }
local conns = {}

local function apply()
	if not cfg.on then return end
	cam = workspace.CurrentCamera
	if cam and cam.FieldOfView ~= cfg.val then cam.FieldOfView = cfg.val end
end

table.insert(conns, R.RenderStepped:Connect(apply))
table.insert(conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(apply))

function FOV.SetEnabled(v: boolean)
	cfg.on = (v == true)
	cam = workspace.CurrentCamera
	if not cfg.on and cam then cam.FieldOfView = cfg.def else apply() end
	return cfg.on
end

function FOV.SetFOV(v: number)
	if type(v) == "number" then
		cfg.val = math.clamp(math.round(v), cfg.min, cfg.max)
		apply()
	end
	return cfg.val
end

function FOV.Reset()
	cfg.val = cfg.def
	cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = cfg.def end
	return cfg.val
end

function FOV.Toggle()
	return FOV.SetEnabled(not cfg.on)
end

function FOV.GetConfig()
	return { enabled = cfg.on, fov = cfg.val }
end

function FOV.Stop()
	cfg.on = false
	for _, c in ipairs(conns) do if c and c.Disconnect then c:Disconnect() end end
	table.clear(conns)
	cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = cfg.def end
	if _G.FOVAdjuster == FOV then _G.FOVAdjuster = nil end
end

_G.FOVAdjuster = FOV
return FOV

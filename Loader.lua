local H = game:GetService("HttpService")
local cFile = "dgre_cfg.json"
local cfg = {}
if readfile and isfile and isfile(cFile) then
	pcall(function() cfg = H:JSONDecode(readfile(cFile)) end)
end

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Swiftz/UI-Library/refs/heads/main/Libraries/uwuware%20(wally)%20-%20Library.lua"))()
local Bar = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/barrier_push.lua"))()
local Swp = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/WeaponSwap.lua"))()
local Spd = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/SpeedBoost.lua"))()
local Fov = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/FOVAdjuster.lua"))()
local Gfx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/GraphicsEnhancer.lua"))()
local Str = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/DGRE/refs/heads/main/store.lua"))()

local aSave = cfg.auto_save ~= nil and cfg.auto_save or false
local function save()
	if not (aSave and writefile) then return end
	local d = {}
	for k, v in pairs(Lib.flags) do
		d[k] = typeof(v) == "EnumItem" and v.Name or v
	end
	pcall(writefile, cFile, H:JSONEncode(d))
end

local wList = (Swp and Swp.GetWeapons) and Swp.GetWeapons() or {"None"}
if Swp then
	local w1, w2 = cfg.w_1 or wList[1], cfg.w_2 or wList[2] or wList[1]
	if w1 then Swp.SetWeapon1(w1) end
	if w2 then Swp.SetWeapon2(w2) end
	Swp.SetKeybind(cfg.w_key and Enum.KeyCode[cfg.w_key] or Enum.KeyCode.Z)
	Swp.ToggleKeybind(cfg.w_kb or false)
end

if Bar then
	if cfg.b_push ~= nil then Bar.SetPush(cfg.b_push) end
	if cfg.b_show ~= nil then Bar.SetBarrier(cfg.b_show) end
	if cfg.b_dist ~= nil then Bar.SetDistance(cfg.b_dist) end
end

if Spd then
	if cfg.s_on ~= nil then Spd.SetEnabled(cfg.s_on) end
	if cfg.s_val ~= nil then Spd.SetSpeed(cfg.s_val) end
end

if Fov then
	if cfg.fov_on ~= nil then Fov.SetEnabled(cfg.fov_on) end
	if cfg.fov_val ~= nil then Fov.SetFOV(cfg.fov_val) end
end

if Gfx then
	if cfg.gfx_blm ~= nil then Gfx.SetBloom(cfg.gfx_blm) end
	if cfg.gfx_pre ~= nil then Gfx.SetPreset(cfg.gfx_pre) end
	if cfg.gfx_on ~= nil then Gfx.SetEnabled(cfg.gfx_on) end
end

local Win = Lib:CreateWindow("DGRE Hub")

-- Barrier
local fBar = Win:AddFolder("Barrier")
fBar:AddToggle({text = "Push Melee", flag = "b_push", state = (cfg.b_push ~= nil and cfg.b_push or true), callback = function(v) Bar.SetPush(v) save() end})
fBar:AddToggle({text = "Show Barrier", flag = "b_show", state = (cfg.b_show or false), callback = function(v) Bar.SetBarrier(v) end})
fBar:AddSlider({text = "Distance", flag = "b_dist", min = 4, max = 30, value = (cfg.b_dist or 10), float = 1, callback = function(v) Bar.SetDistance(v) save() end})
fBar:AddButton({text = "Stop Barrier", callback = function() Bar.Stop() end})

-- Weapon Swap
local fSwp = Win:AddFolder("Weapon Swap")
local lW1 = fSwp:AddList({text = "Weapon 1", flag = "w_1", values = wList, value = (cfg.w_1 or wList[1] or ""), callback = function(v) Swp.SetWeapon1(v) save() end})
local lW2 = fSwp:AddList({text = "Weapon 2", flag = "w_2", values = wList, value = (cfg.w_2 or wList[2] or wList[1] or ""), callback = function(v) Swp.SetWeapon2(v) save() end})
fSwp:AddButton({text = "Refresh Weapons", callback = function()
	local u = Swp.RefreshInventory()
	if #u > 0 then
		if lW1 and lW1.values then lW1.values = u end
		if lW2 and lW2.values then lW2.values = u end
	end
end})
fSwp:AddToggle({text = "Auto-Swap Keybind", flag = "w_kb", state = (cfg.w_kb or false), callback = function(v) Swp.ToggleKeybind(v) save() end})
fSwp:AddBind({text = "Swap Key", flag = "w_key", key = (cfg.w_key and Enum.KeyCode[cfg.w_key] or Enum.KeyCode.Z), callback = function() Swp.Swap() save() end})
fSwp:AddButton({text = "⚡ Swap Weapon", callback = function() Swp.Swap() end})

-- Speed Boost
local fSpd = Win:AddFolder("Speed Boost")
fSpd:AddToggle({text = "Enable Speed", flag = "s_on", state = (cfg.s_on or false), callback = function(v) Spd.SetEnabled(v) save() end})
fSpd:AddSlider({text = "Speed Value", flag = "s_val", min = 16, max = 150, value = (cfg.s_val or 20), float = 1, callback = function(v) Spd.SetSpeed(v) save() end})
fSpd:AddButton({text = "Toggle Speed", callback = function() Spd.Toggle() save() end})

-- FOV Adjuster
local fFov = Win:AddFolder("FOV")
fFov:AddToggle({text = "Enable Custom FOV", flag = "fov_on", state = (cfg.fov_on or false), callback = function(v) Fov.SetEnabled(v) save() end})
fFov:AddSlider({text = "FOV Value", flag = "fov_val", min = 30, max = 120, value = (cfg.fov_val or 70), float = 1, callback = function(v) Fov.SetFOV(v) save() end})
fFov:AddButton({text = "Reset FOV", callback = function() Fov.Reset() save() end})

-- Graphics Enhancer
local fGfx = Win:AddFolder("Visuals")
local preList = {"Vibrant", "Cinematic", "RTX Glow"}
fGfx:AddToggle({text = "Enable Graphics", flag = "gfx_on", state = (cfg.gfx_on or false), callback = function(v) Gfx.SetEnabled(v) save() end})
fGfx:AddList({text = "Preset", flag = "gfx_pre", values = preList, value = (cfg.gfx_pre or "Vibrant"), callback = function(v) Gfx.SetPreset(v) save() end})
fGfx:AddToggle({text = "Bloom Effect", flag = "gfx_blm", state = (cfg.gfx_blm ~= nil and cfg.gfx_blm or true), callback = function(v) Gfx.SetBloom(v) save() end})
fGfx:AddButton({text = "Reset Graphics", callback = function() Gfx.Reset() save() end})

-- Shop
local fStr = Win:AddFolder("Shop")
fStr:AddButton({text = "Toggle Sell Shop", callback = function() if Str and Str.toggleSell then Str.toggleSell() end end})
fStr:AddButton({text = "Toggle Upgrade Shop", callback = function() if Str and Str.toggleUpgrade then Str.toggleUpgrade() end end})
fStr:AddButton({text = "Close Shops", callback = function() if Str then if Str.closeSell then Str.closeSell() end if Str.closeUpgrade then Str.closeUpgrade() end end end})

-- Settings (Auto-Save)
local fSet = Win:AddFolder("Settings")
fSet:AddToggle({text = "Auto-Save Config", flag = "auto_save", state = aSave, callback = function(v) aSave = v save() end})
fSet:AddButton({text = "💾 Save Config Now", callback = function()
	local old = aSave
	aSave = true
	save()
	aSave = old
end})

Lib:Init()
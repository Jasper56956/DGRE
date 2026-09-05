local L = game:GetService("Lighting")

if _G.GFX_Stop then pcall(_G.GFX_Stop) end

local GFX = {}
GFX.__index = GFX

local orig = {
	amb = L.Ambient,
	oamb = L.OutdoorAmbient,
	brt = L.Brightness,
	exp = L.ExposureCompensation,
	fe = L.FogEnd,
	fs = L.FogStart
}

local bl = L:FindFirstChild("EnhanceBloom") or Instance.new("BloomEffect")
bl.Name = "EnhanceBloom"
local cc = L:FindFirstChild("EnhanceCC") or Instance.new("ColorCorrectionEffect")
cc.Name = "EnhanceCC"
local sr = L:FindFirstChild("EnhanceSunRays") or Instance.new("SunRaysEffect")
sr.Name = "EnhanceSunRays"

local cfg = { on = false, preset = "Vibrant", blm = true }

function GFX.SetEnabled(v: boolean)
	cfg.on = (v == true)
	if cfg.on then GFX.SetPreset(cfg.preset or "Vibrant") else GFX.Reset() end
	return cfg.on
end

function GFX.SetBloom(v: boolean)
	cfg.blm = (v == true)
	bl.Enabled = cfg.blm
	return cfg.blm
end

function GFX.SetPreset(name: string)
	cfg.preset = name
	cfg.on = true
	bl.Parent, cc.Parent, sr.Parent = L, L, L
	bl.Enabled = cfg.blm

	if name == "Vibrant" then
		L.Ambient = Color3.fromRGB(60, 65, 80)
		L.OutdoorAmbient = Color3.fromRGB(120, 130, 150)
		L.Brightness = 1.8
		L.ExposureCompensation = 0.2
		L.FogEnd, L.FogStart = 10000, 500
		bl.Intensity, bl.Size, bl.Threshold = 0.65, 24, 0.85
		cc.Saturation, cc.Contrast, cc.Brightness = 0.3, 0.2, 0.05
		sr.Intensity, sr.Spread = 0.2, 0.8
	elseif name == "Cinematic" then
		L.Ambient = Color3.fromRGB(45, 48, 60)
		L.OutdoorAmbient = Color3.fromRGB(100, 110, 130)
		L.Brightness = 1.5
		L.ExposureCompensation = 0.1
		L.FogEnd, L.FogStart = 5000, 200
		bl.Intensity, bl.Size, bl.Threshold = 0.5, 20, 0.9
		cc.Saturation, cc.Contrast, cc.Brightness = 0.15, 0.25, 0.02
		sr.Intensity, sr.Spread = 0.25, 0.85
	elseif name == "RTX Glow" then
		L.Ambient = Color3.fromRGB(70, 75, 90)
		L.OutdoorAmbient = Color3.fromRGB(130, 140, 160)
		L.Brightness = 2.2
		L.ExposureCompensation = 0.25
		L.FogEnd, L.FogStart = 10000, 500
		bl.Intensity, bl.Size, bl.Threshold = 1.2, 30, 0.75
		cc.Saturation, cc.Contrast, cc.Brightness = 0.35, 0.22, 0.06
		sr.Intensity, sr.Spread = 0.35, 0.9
	elseif name == "Clear Vision" or name == "Clear" then
		L.Ambient = Color3.fromRGB(60, 65, 75)
		L.OutdoorAmbient = Color3.fromRGB(110, 120, 135)
		L.Brightness = 1.6
		L.ExposureCompensation = 0.15
		L.FogEnd, L.FogStart = 100000, 10000
		bl.Intensity, bl.Size, bl.Threshold = 0.4, 18, 0.9
		cc.Saturation, cc.Contrast, cc.Brightness = 0.1, 0.1, 0.02
		sr.Intensity, sr.Spread = 0.15, 0.8
	elseif name == "Default" then
		GFX.Reset()
	end
end

function GFX.Reset()
	cfg.on = false
	cfg.preset = "Default"
	L.Ambient, L.OutdoorAmbient = orig.amb, orig.oamb
	L.Brightness, L.ExposureCompensation = orig.brt, orig.exp
	L.FogEnd, L.FogStart = orig.fe, orig.fs
	if bl.Parent then bl.Parent = nil end
	if cc.Parent then cc.Parent = nil end
	if sr.Parent then sr.Parent = nil end
end

function GFX.Toggle()
	return GFX.SetEnabled(not cfg.on)
end

function GFX.Stop()
	GFX.Reset()
	if _G.GFX == GFX then _G.GFX = nil end
end

_G.GFX = GFX
_G.GFX_Stop = GFX.Stop
return GFX

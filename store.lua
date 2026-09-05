local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local rm = rs:WaitForChild("remotes")
local ss = require(p:WaitForChild("PlayerScripts"):WaitForChild("Ui"):WaitForChild("sellShop"))

local function oS() ss.Open() end
local function cS()
	ss.Close()
	pcall(function() rm.blacksmithValueFalse:FireServer() end)
end
local function tS()
	local g = p.PlayerGui:FindFirstChild("sellShop")
	if g and g.Frame.Visible then cS() else oS() end
end

local function oU()
	if not p.PlayerGui:FindFirstChild("blacksmith") then
		local t = rs.ui:FindFirstChild("blacksmith")
		if t then
			t:Clone().Parent = p.PlayerGui
			if p:FindFirstChild("inBlacksmith") then p.inBlacksmith.Value = true end
		end
	end
end
local function cU()
	local b = p.PlayerGui:FindFirstChild("blacksmith")
	if b then
		b:Destroy()
		pcall(function() rm.blacksmithValueFalse:FireServer() end)
		if p:FindFirstChild("inBlacksmith") then p.inBlacksmith.Value = false end
	end
end
local function tU()
	if p.PlayerGui:FindFirstChild("blacksmith") then cU() else oU() end
end

_G.Shop = {
	openSell = oS,
	closeSell = cS,
	toggleSell = tS,
	openUpgrade = oU,
	closeUpgrade = cU,
	toggleUpgrade = tU
}

return _G.Shop
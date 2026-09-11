--!strict
-- ItemUpgradeDisplay.lua
-- Dungeon Quest: Clean Non-Overlapping Native UI Stats Injection
-- Compact vars, clean fonts, no collisions

if _G.DQUpgradeCleanup then pcall(_G.DQUpgradeCleanup) end

local P = game:GetService("Players")
local R = game:GetService("ReplicatedStorage")
local lp = P.LocalPlayer
local pGui = lp:WaitForChild("PlayerGui")
local rem = R:WaitForChild("remotes")
local rInvy = rem:WaitForChild("reloadInvy")

local M = {}
M.__index = M

local TAG = "DQSlotTag"
local on = true
local conns = {}
local cInv = nil
local lastF = 0
local busy = false

local function cNum(n: number): string
	local s = tostring(math.floor(n))
	local k: number
	while true do
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return s
end

local function getInv(force: boolean?)
	local now = os.clock()
	if force or not cInv or (now - lastF > 1.5) then
		local ok, res = pcall(function() return rInvy:InvokeServer() end)
		if ok and type(res) == "table" then
			cInv = res
			lastF = now
		end
	end
	return cInv
end

local function fItem(cat: string, uNum: any)
	local inv = getInv()
	if not inv or not inv[cat] then return nil end
	local num = tonumber(uNum)
	if not num then return nil end
	for k, v in pairs(inv[cat]) do
		if tonumber(string.match(k, "%d+")) == num then return v end
	end
	return nil
end

local function cleanSlot(slot: Instance)
	for _, c in ipairs(slot:GetChildren()) do
		if c.Name == TAG or string.find(c.Name, "Tag") or string.find(c.Name, "MaxUpgrade") then
			c:Destroy()
		end
	end
end

local function setSlotTag(slot: Instance)
	if not slot or not slot:IsA("ImageLabel") then return end
	if not on then cleanSlot(slot) return end

	local tObj = slot:FindFirstChild("itemType")
	if not tObj or not tObj:IsA("StringValue") then return end

	local cat = tObj.Value
	local uVal = tObj:FindFirstChild("uniqueItemNum")
	local num = uVal and uVal.Value
	if not (cat == "weapon" or cat == "chest" or cat == "helmet") then
		cleanSlot(slot)
		return
	end

	local it = fItem(cat .. "s", num)
	if not it then return end

	local mUp = it.maxUpgrades or 0
	local cUp = it.currentUpgrade or 0
	if mUp <= 0 then cleanSlot(slot) return end

	cleanSlot(slot)

	local lbl = Instance.new("TextLabel")
	lbl.Name = TAG
	lbl.Size = UDim2.new(1, 0, 0.26, 0)
	lbl.Position = UDim2.new(0, 0, 0.74, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	lbl.BackgroundTransparency = 0.35
	lbl.BorderSizePixel = 0
	lbl.ZIndex = 14
	lbl.Active = false

	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, 3)
	uc.Parent = lbl

	local us = Instance.new("UIStroke")
	us.Color = Color3.fromRGB(255, 215, 0)
	us.Thickness = 1
	us.Transparency = 0.6
	us.Parent = lbl

	lbl.Font = Enum.Font.Highway
	lbl.TextColor3 = Color3.fromRGB(255, 230, 100)
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.TextScaled = true

	if cUp > 0 and cUp < mUp then
		lbl.Text = tostring(cUp) .. "/" .. tostring(mUp)
	else
		lbl.Text = "Max: " .. tostring(mUp)
	end
	lbl.Parent = slot
end

local function getBaseNum(txt: string): number
	local firstPart = string.match(txt, "^[^%-]+") or txt
	local digits = string.gsub(firstPart, "%D", "")
	return tonumber(digits) or 0
end

local function styleRow(title: GuiObject?, val: GuiObject?, yPos: number, height: number)
	if title and title:IsA("TextLabel") then
		title.AnchorPoint = Vector2.new(0, 0)
		title.Font = Enum.Font.Highway
		title.TextScaled = true
		title.TextWrapped = false
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Position = UDim2.new(0.04, 0, yPos, 0)
		title.Size = UDim2.new(0.40, 0, height, 0)
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Visible = true
	end
	if val and val:IsA("TextLabel") then
		val.AnchorPoint = Vector2.new(0, 0)
		val.Font = Enum.Font.Highway
		val.TextScaled = true
		val.TextWrapped = false
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.Position = UDim2.new(0.45, 0, yPos, 0)
		val.Size = UDim2.new(0.51, 0, height, 0)
		val.Visible = true
	end
end

local function updateNativeFrame(f: Instance, isArm: boolean)
	if not on or busy then return end
	busy = true

	local ok, err = pcall(function()
		local up = f:FindFirstChild("upgrades") :: TextLabel?
		if not up then return end

		local cUpS, mUpS = string.match(up.Text, "(%d+)/(%d+)")
		local cUp = tonumber(cUpS) or 0
		local mUp = tonumber(mUpS) or 0
		local rem = math.max(0, mUp - cUp)

		if not isArm then
			local pT = f:FindFirstChild("physicalDamageTitle") :: TextLabel?
			local pObj = f:FindFirstChild("physicalDamage") :: TextLabel?
			local sT = f:FindFirstChild("spellPowerTitle") :: TextLabel?
			local sObj = f:FindFirstChild("spellPower") :: TextLabel?
			local reqT = f:FindFirstChild("damageTitle") :: TextLabel?
			local reqObj = f:FindFirstChild("levelReq") :: TextLabel?
			local upT = f:FindFirstChild("upgradeTitle") :: TextLabel?
			local slT = f:FindFirstChild("sellTitle") :: TextLabel?
			local slObj = f:FindFirstChild("sellPrice") :: TextLabel?

			styleRow(pT, pObj, 0.20, 0.13)
			styleRow(sT, sObj, 0.35, 0.13)
			styleRow(reqT, reqObj, 0.50, 0.13)
			styleRow(upT, up, 0.65, 0.13)
			styleRow(slT, slObj, 0.80, 0.13)

			if pObj and sObj then
				local cP = getBaseNum(pObj.Text)
				local cS = getBaseNum(sObj.Text)
				if rem > 0 then
					pObj.Text = cNum(cP) .. " -> " .. cNum(cP + rem * 10)
					sObj.Text = cNum(cS) .. " -> " .. cNum(cS + rem * 10)
					up.Text = cUp .. "/" .. mUp .. " (+" .. cNum(rem * 10) .. ")"
				else
					pObj.Text = cNum(cP) .. " (Max)"
					sObj.Text = cNum(cS) .. " (Max)"
					up.Text = cUp .. "/" .. mUp .. " (Max)"
				end
			end

			if up then up.TextColor3 = Color3.fromRGB(255, 220, 100) end
			if slObj then
				slObj.TextColor3 = Color3.fromRGB(255, 215, 0)
				local sp = tonumber(string.gsub(slObj.Text, "%D", ""))
				if sp then slObj.Text = cNum(sp) end
			end
		else
			local pT = f:FindFirstChild("physicalDamageTitle") :: TextLabel?
			local pObj = f:FindFirstChild("physicalDamage") :: TextLabel?
			local sT = f:FindFirstChild("spellPowerTitle") :: TextLabel?
			local sObj = f:FindFirstChild("spellPower") :: TextLabel?
			local hT = f:FindFirstChild("healthTitle") :: TextLabel?
			local hObj = f:FindFirstChild("health") :: TextLabel?
			local reqT = f:FindFirstChild("damageTitle") :: TextLabel?
			local reqObj = f:FindFirstChild("levelReq") :: TextLabel?
			local upT = f:FindFirstChild("upgradeTitle") :: TextLabel?
			local slT = f:FindFirstChild("sellTitle") :: TextLabel?
			local slObj = f:FindFirstChild("sellPrice") :: TextLabel?

			styleRow(pT, pObj, 0.16, 0.11)
			styleRow(sT, sObj, 0.29, 0.11)
			styleRow(hT, hObj, 0.42, 0.11)
			styleRow(reqT, reqObj, 0.55, 0.11)
			styleRow(upT, up, 0.68, 0.11)
			styleRow(slT, slObj, 0.81, 0.11)

			if hObj and pObj and sObj then
				local cH = getBaseNum(hObj.Text)
				local cP = getBaseNum(pObj.Text)
				local cS = getBaseNum(sObj.Text)
				if rem > 0 then
					hObj.Text = cNum(cH) .. " -> " .. cNum(cH + rem * 10)
					pObj.Text = cNum(cP) .. " -> " .. cNum(cP + rem * 10)
					sObj.Text = cNum(cS) .. " -> " .. cNum(cS + rem * 10)
					up.Text = cUp .. "/" .. mUp .. " (+" .. cNum(rem * 10) .. ")"
				else
					hObj.Text = cNum(cH) .. " (Max)"
					pObj.Text = cNum(cP) .. " (Max)"
					sObj.Text = cNum(cS) .. " (Max)"
					up.Text = cUp .. "/" .. mUp .. " (Max)"
				end
			end

			if up then up.TextColor3 = Color3.fromRGB(255, 220, 100) end
			if slObj then
				slObj.TextColor3 = Color3.fromRGB(255, 215, 0)
				local sp = tonumber(string.gsub(slObj.Text, "%D", ""))
				if sp then slObj.Text = cNum(sp) end
			end
		end
	end)

	busy = false
end

local PANEL_NAME = "DQSortPanel"
local curSort = "default"

local SORT_MODES = {
	{"Max Phys Dmg", "maxPhys"},
	{"Max Spell Pwr", "maxSpell"},
	{"Max Health", "maxHp"},
	{"Cur Phys Dmg", "curPhys"},
	{"Cur Spell Pwr", "curSpell"},
	{"Max Upgrades", "maxUp"},
	{"REQ Level", "reqLvl"},
	{"Rarity", "rarity"},
	{"Default Order", "default"},
}

local R_MAP = {
	ultimate = 6,
	legendary = 5,
	epic = 4,
	rare = 3,
	uncommon = 2,
	common = 1
}

local function getCatPlural(c: string): string
	if c == "ability" then return "abilities" end
	return c .. "s"
end

local function getSortVal(it: any, mode: string): number
	if not it then return 0 end
	local mUp = it.maxUpgrades or 0
	local cUp = it.currentUpgrade or 0
	local rem = math.max(0, mUp - cUp)
	local pD = it.physicalDamage or (it.physicalPower or 0)
	local sD = it.spellPower or 0
	local hp = it.health or 0
	if mode == "maxPhys" then
		return pD + rem * 10
	elseif mode == "maxSpell" then
		return sD + rem * 10
	elseif mode == "maxHp" then
		return hp + rem * 10
	elseif mode == "curPhys" then
		return pD
	elseif mode == "curSpell" then
		return sD
	elseif mode == "maxUp" then
		return mUp
	elseif mode == "reqLvl" then
		return it.levelReq or 0
	elseif mode == "rarity" then
		return R_MAP[string.lower(it.rarity or "")] or 0
	end
	return 0
end

local function applySort(mode: string)
	curSort = mode
	local inv = pGui:FindFirstChild("inventory")
	if not inv then return end
	local inBg = inv:FindFirstChild("mainBackground") and inv.mainBackground:FindFirstChild("innerBackground")
	if not inBg then return end
	local rSF = inBg:FindFirstChild("rightSideFrame") and inBg.rightSideFrame:FindFirstChild("ScrollingFrame")
	if not rSF then return end

	local slots = {}
	for _, c in ipairs(rSF:GetChildren()) do
		if c:IsA("ImageLabel") then
			local tObj = c:FindFirstChild("itemType")
			local cat = tObj and tObj.Value
			local uVal = tObj and tObj:FindFirstChild("uniqueItemNum")
			local num = uVal and uVal.Value
			local it = cat and fItem(getCatPlural(cat), num)
			local origOrder = tonumber(c.Name) or 999
			local val = (mode == "default") and 0 or getSortVal(it, mode)
			table.insert(slots, {slot = c, val = val, orig = origOrder})
		end
	end

	if mode == "default" then
		table.sort(slots, function(a, b) return a.orig < b.orig end)
	else
		table.sort(slots, function(a, b)
			if a.val ~= b.val then return a.val > b.val end
			return a.orig < b.orig
		end)
	end

	for i, item in ipairs(slots) do
		item.slot.LayoutOrder = i
	end

	local pnl = inBg:FindFirstChild(PANEL_NAME)
	local bFrame = pnl and pnl:FindFirstChild("BtnFrame")
	if bFrame then
		for _, btn in ipairs(bFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				local isSel = (btn.Name == curSort)
				btn.BackgroundColor3 = isSel and Color3.fromRGB(110, 85, 20) or Color3.fromRGB(45, 45, 55)
				btn.TextColor3 = isSel and Color3.fromRGB(255, 230, 100) or Color3.fromRGB(240, 240, 255)
				local strk = btn:FindFirstChildOfClass("UIStroke")
				if strk then
					strk.Color = isSel and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(70, 70, 85)
				end
			end
		end
	end
end

local function createSortPanel()
	local inv = pGui:FindFirstChild("inventory")
	if not inv then return end
	local inBg = inv:FindFirstChild("mainBackground") and inv.mainBackground:FindFirstChild("innerBackground")
	if not inBg then return end

	local pnl = inBg:FindFirstChild(PANEL_NAME)
	if not pnl then
		pnl = Instance.new("ImageLabel")
		pnl.Name = PANEL_NAME
		pnl.Size = UDim2.new(0.25, 0, 0.70, 0)
		pnl.Position = UDim2.new(1.03, 0, 0.33, 0)
		pnl.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		pnl.BackgroundTransparency = 0.1
		pnl.BorderSizePixel = 0
		pnl.ZIndex = 15

		local uc = Instance.new("UICorner")
		uc.CornerRadius = UDim.new(0, 8)
		uc.Parent = pnl

		local us = Instance.new("UIStroke")
		us.Color = Color3.fromRGB(255, 215, 0)
		us.Thickness = 1.5
		us.Transparency = 0.3
		us.Parent = pnl

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0.11, 0)
		title.Position = UDim2.new(0, 0, 0.02, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.Highway
		title.Text = "SORT INVENTORY"
		title.TextColor3 = Color3.fromRGB(255, 220, 100)
		title.TextScaled = true
		title.ZIndex = 16
		title.Parent = pnl

		local sep = Instance.new("Frame")
		sep.Name = "Sep"
		sep.Size = UDim2.new(0.9, 0, 0, 1)
		sep.Position = UDim2.new(0.05, 0, 0.14, 0)
		sep.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel = 0
		sep.ZIndex = 16
		sep.Parent = pnl

		local bFrame = Instance.new("Frame")
		bFrame.Name = "BtnFrame"
		bFrame.Size = UDim2.new(0.92, 0, 0.83, 0)
		bFrame.Position = UDim2.new(0.04, 0, 0.16, 0)
		bFrame.BackgroundTransparency = 1
		bFrame.ZIndex = 16
		bFrame.Parent = pnl

		local ll = Instance.new("UIListLayout")
		ll.FillDirection = Enum.FillDirection.Vertical
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ll.VerticalAlignment = Enum.VerticalAlignment.Top
		ll.Padding = UDim.new(0, 2)
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Parent = bFrame

		for i, m in ipairs(SORT_MODES) do
			local btn = Instance.new("TextButton")
			btn.Name = m[2]
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.BackgroundColor3 = (m[2] == curSort) and Color3.fromRGB(110, 85, 20) or Color3.fromRGB(45, 45, 55)
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.Highway
			btn.Text = m[1]
			btn.TextColor3 = (m[2] == curSort) and Color3.fromRGB(255, 230, 100) or Color3.fromRGB(240, 240, 255)
			btn.TextSize = 12
			btn.ZIndex = 17
			btn.LayoutOrder = i

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 4)
			bc.Parent = btn

			local bs = Instance.new("UIStroke")
			bs.Color = (m[2] == curSort) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(70, 70, 85)
			bs.Thickness = 1
			bs.Parent = btn

			btn.MouseButton1Click:Connect(function()
				applySort(m[2])
			end)

			btn.Parent = bFrame
		end

		pnl.Parent = inBg
	end
end

local function cleanAll()
	local inv = pGui:FindFirstChild("inventory")
	if not inv then return end
	for _, desc in ipairs(inv:GetDescendants()) do
		if desc.Name == TAG or desc.Name == PANEL_NAME or string.find(desc.Name, "MaxUpgrade") or string.find(desc.Name, "MaxSlot") then
			if desc:IsA("GuiObject") and desc.Parent and desc.Parent.Name ~= "itemStatFrame" then
				desc:Destroy()
			end
		end
	end
end

function M.Refresh()
	if not on then cleanAll() return end
	local inv = pGui:FindFirstChild("inventory")
	if not inv then return end
	local inBg = inv:FindFirstChild("mainBackground") and inv.mainBackground:FindFirstChild("innerBackground")
	if not inBg then return end

	local rSF = inBg:FindFirstChild("rightSideFrame") and inBg.rightSideFrame:FindFirstChild("ScrollingFrame")
	local lF = inBg:FindFirstChild("leftSideFrame")

	getInv(true)

	if rSF then
		for _, s in ipairs(rSF:GetChildren()) do
			if s:IsA("ImageLabel") then setSlotTag(s) end
		end
	end
	if lF then
		for _, sN in ipairs({"weaponSlot", "chestSlot", "helmetSlot"}) do
			local s = lF:FindFirstChild(sN)
			if s then setSlotTag(s) end
		end
	end

	createSortPanel()
	if curSort ~= "default" then applySort(curSort) end
end

function M.Enable() on = true M.Refresh() end
function M.Disable() on = false cleanAll() end
function M.Toggle() if on then M.Disable() else M.Enable() end return on end

local function init()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)

	local inv = pGui:WaitForChild("inventory")
	local mBg = inv:WaitForChild("mainBackground")
	local inBg = mBg:WaitForChild("innerBackground")
	local rSF = inBg:WaitForChild("rightSideFrame"):WaitForChild("ScrollingFrame")
	local lF = inBg:WaitForChild("leftSideFrame")
	local isf = inv:WaitForChild("itemStatFrame")
	local wm = isf:WaitForChild("weaponMain")
	local am = isf:WaitForChild("armorMain")

	table.insert(conns, rSF.ChildAdded:Connect(function(c)
		if on and c:IsA("ImageLabel") then
			task.defer(function()
				setSlotTag(c)
				if curSort ~= "default" then applySort(curSort) end
			end)
		end
	end))

	table.insert(conns, mBg:GetPropertyChangedSignal("Visible"):Connect(function()
		if mBg.Visible and on then task.defer(M.Refresh) end
	end))

	for _, sN in ipairs({"weaponSlot", "chestSlot", "helmetSlot"}) do
		local s = lF:FindFirstChild(sN)
		if s then
			local it = s:FindFirstChild("itemType")
			local uV = it and it:FindFirstChild("uniqueItemNum")
			if uV then
				table.insert(conns, uV:GetPropertyChangedSignal("Value"):Connect(function()
					if on then task.defer(function() setSlotTag(s) end) end
				end))
			end
		end
	end

	local wmUp = wm:WaitForChild("upgrades")
	table.insert(conns, wmUp:GetPropertyChangedSignal("Text"):Connect(function()
		if on then task.defer(function() updateNativeFrame(wm, false) end) end
	end))
	table.insert(conns, wm:GetPropertyChangedSignal("Visible"):Connect(function()
		if wm.Visible and on then task.defer(function() updateNativeFrame(wm, false) end) end
	end))

	local amUp = am:WaitForChild("upgrades")
	table.insert(conns, amUp:GetPropertyChangedSignal("Text"):Connect(function()
		if on then task.defer(function() updateNativeFrame(am, true) end) end
	end))
	table.insert(conns, am:GetPropertyChangedSignal("Visible"):Connect(function()
		if am.Visible and on then task.defer(function() updateNativeFrame(am, true) end) end
	end))
end

_G.DQUpgradeCleanup = function()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	cleanAll()
end

task.spawn(function()
	cleanAll()
	init()
	M.Refresh()
end)

return M

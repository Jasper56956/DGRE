--!strict
-- Quick Weapon Swap Module (Core / Backend for Loader)
-- Can be hosted on GitHub and loaded via loadstring

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")
local equipRemote = remotes:WaitForChild("equipItem")

-- Module Table
local WeaponSwap = {}
WeaponSwap.__index = WeaponSwap

-- State variables
local itemMap = {} -- Lookup by displayName, clean name, or slot
local rawWeapons = {}
local weaponList = {}
local weaponA = nil
local weaponB = nil
local keybindConnection = nil
local currentKeybind = Enum.KeyCode.Z
local keybindEnabled = false

--- Refresh and return current weapon inventory
function WeaponSwap.RefreshInventory()
	table.clear(itemMap)
	table.clear(rawWeapons)
	table.clear(weaponList)

	local reloadInvy = remotes:FindFirstChild("reloadInvy")
	if not reloadInvy then
		warn("[WeaponSwap] Remote 'reloadInvy' not found.")
		return weaponList, itemMap
	end

	local success, inv = pcall(function()
		return reloadInvy:InvokeServer()
	end)

	if success and type(inv) == "table" and type(inv.weapons) == "table" then
		local temp = {}
		for id, item in pairs(inv.weapons) do
			if type(item) == "table" and item.name then
				local slot = tostring(string.sub(id, 8))
				local tag = item.equipped and "[Equipped] " or ""
				local rarityTag = item.rarity and (" (" .. tostring(item.rarity) .. ")") or ""
				local displayName = tag .. tostring(item.name) .. rarityTag

				local itemData = {
					slot = slot,
					name = tostring(item.name),
					displayName = displayName,
					rarity = item.rarity,
					equipped = item.equipped,
					rawId = id,
				}

				table.insert(temp, displayName)
				table.insert(rawWeapons, itemData)

				-- Support lookup by display name, clean weapon name, and slot
				itemMap[displayName] = itemData
				if not itemMap[tostring(item.name)] then
					itemMap[tostring(item.name)] = itemData
				end
				itemMap[slot] = itemData
			end
		end

		table.sort(temp)
		for _, name in ipairs(temp) do
			table.insert(weaponList, name)
		end
	else
		warn("[WeaponSwap] Failed to load weapons from reloadInvy.")
	end

	return weaponList, itemMap, rawWeapons
end

--- Resolve weapon input (accepts itemData table, display name, clean name, or slot)
local function resolveWeapon(weapon)
	if type(weapon) == "table" and weapon.slot then
		return weapon
	end
	if type(weapon) == "string" or type(weapon) == "number" then
		return itemMap[tostring(weapon)]
	end
	return nil
end

--- Set Primary Weapon (Weapon 1)
function WeaponSwap.SetWeapon1(weapon)
	weaponA = resolveWeapon(weapon)
	return weaponA
end

--- Set Secondary Weapon (Weapon 2)
function WeaponSwap.SetWeapon2(weapon)
	weaponB = resolveWeapon(weapon)
	return weaponB
end

--- Get currently selected weapons
function WeaponSwap.GetSelected()
	return weaponA, weaponB
end

--- Get weapon list and lookup map (refreshes if empty)
function WeaponSwap.GetWeapons()
	if #weaponList == 0 then
		WeaponSwap.RefreshInventory()
	end
	return weaponList, itemMap, rawWeapons
end

--- Perform Weapon Swap / Equip
function WeaponSwap.Swap()
	if not weaponA then
		warn("[WeaponSwap] กรุณาเลือก Weapon 1 ก่อน!")
		return false, "Weapon 1 not selected"
	end

	local curWepVal = player:FindFirstChild("weaponEquipped")
	local curWep = curWepVal and curWepVal.Value

	local target = weaponA
	if weaponB then
		-- Toggle between Weapon A and Weapon B
		if curWep == weaponA.name then
			target = weaponB
		else
			target = weaponA
		end
	end

	local ok = equipRemote:InvokeServer("weapon", tostring(target.slot))
	if ok then
		print("[WeaponSwap] สลับไปใช้: " .. tostring(target.name) .. " (Slot: " .. tostring(target.slot) .. ")")
		return true, target
	else
		warn("[WeaponSwap] สวมใส่อาวุธล้มเหลว: " .. tostring(target.name))
		return false, "Equip failed"
	end
end

--- Equip a specific weapon directly
function WeaponSwap.Equip(weapon)
	local target = resolveWeapon(weapon)
	if not target then
		warn("[WeaponSwap] ไม่พบอาวุธที่ระบุ")
		return false, "Weapon not found"
	end
	local ok = equipRemote:InvokeServer("weapon", tostring(target.slot))
	return ok, target
end

--- Set custom keybind (e.g. Enum.KeyCode.Z)
function WeaponSwap.SetKeybind(keyCode: Enum.KeyCode)
	currentKeybind = keyCode
end

--- Enable / Disable Keybind listener
function WeaponSwap.ToggleKeybind(enabled: boolean)
	keybindEnabled = enabled
	if keybindConnection then
		keybindConnection:Disconnect()
		keybindConnection = nil
	end

	if keybindEnabled then
		keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == currentKeybind then
				WeaponSwap.Swap()
			end
		end)
	end
end

--- Clean up any connections and global references
function WeaponSwap.Destroy()
	if keybindConnection then
		keybindConnection:Disconnect()
		keybindConnection = nil
	end
	if _G.WeaponSwap == WeaponSwap then
		_G.WeaponSwap = nil
	end
	if typeof(getgenv) == "function" and getgenv().WeaponSwap == WeaponSwap then
		getgenv().WeaponSwap = nil
	end
end

-- Initial Inventory Fetch
pcall(WeaponSwap.RefreshInventory)

-- Global Export for Loader & Executor compatibility
if typeof(getgenv) == "function" then
	getgenv().WeaponSwap = WeaponSwap
end
_G.WeaponSwap = WeaponSwap

return WeaponSwap
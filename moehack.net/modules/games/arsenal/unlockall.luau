
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = Players.LocalPlayer

local PlayerData = require(ReplicatedFirst:WaitForChild("Client"):WaitForChild("Utility"):WaitForChild("PlayerData"))
local Bridge = require(ReplicatedFirst:WaitForChild("Client"):WaitForChild("Utility"):WaitForChild("Bridge"))
local ItemUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemUtil"))
local GetIcon = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GetIcon"))
local State = require(ReplicatedFirst:WaitForChild("Client"):WaitForChild("Utility"):WaitForChild("State"))

local UnlockAll = {}
UnlockAll.__index = UnlockAll

function UnlockAll.new()
	local self = setmetatable({
		Player = LocalPlayer,
		PlayerData = PlayerData,
		Bridge = Bridge,
		ItemUtil = ItemUtil,
		GetIcon = GetIcon,
		State = State,
		Disabled = true,
		RealState = nil,
		RebuildPending = false,
		WrappedFunctions = {},
		Skin = nil,
		Announcer = nil,
		KillEffect = nil,
		WeaponSkin = nil,
		MeleeSkin = nil,
		Categories = {
			"Skins",
			"Melees",
			"Emotes",
			"KillEffects",
			"Cards",
			"Announcers",
			"WeaponSkins",
			"Themes",
			"Kits"
		}
	}, UnlockAll)

	PlayerData.Wait()

	self:BackfillMeleeAnimations()
	self:HookViewmodel()
	self:HookCharacterUpdates()
	self:HookInventoryUpdates()
	self:HookInventoryIcon()
	self:HookEquipped()
	self:HookDataValues()
	self:HookRagdoll()
	self:HookCharacterAdded()

	if not self.Disabled then
		self:UnlockAll()
		self:AdoptLoadout()
		self:PushAll()
		self:PaintMeleeIcon()
	end

	return self
end

function UnlockAll:GetImages()
	local ItemData = ReplicatedStorage:FindFirstChild("ItemData")
	return ItemData and ItemData:FindFirstChild("Images")
end

function UnlockAll:IsValidImage(Category, Name)
	if type(Name) ~= "string" or Name == "" then
		return false
	end

	if Name == "None" or Name == "Default" or Name == "Shuffle" then
		return true
	end

	local Images = self:GetImages()
	local CategoryFolder = Images and Images:FindFirstChild(Category)

	return CategoryFolder and CategoryFolder:FindFirstChild(Name) ~= nil
end

function UnlockAll:IsValidSkin(Name)
	if Name == "curr" or Name == "none" or Name == "del" then
		return false
	end

	return self:IsValidImage("Skins", Name)
end

function UnlockAll:IsValidMelee(Name)
	if type(Name) ~= "string" or Name == "" then
		return false
	end

	if Name == "None" or Name == "Default" or Name == "Shuffle" then
		return false
	end

	local Viewmodels = ReplicatedStorage:FindFirstChild("Viewmodels")

	if not Viewmodels or not Viewmodels:FindFirstChild("v_" .. Name) then
		return false
	end

	return self:IsValidImage("Melees", Name)
end

function UnlockAll:UnlockAll()
	if self.Disabled then
		return 0
	end

	local Images = self:GetImages()
	local Items = self.PlayerData.Data.Items

	if not Images or type(Items) ~= "table" then
		return 0
	end

	local UnlockedCount = 0

	for _, Category in self.Categories do
		local SourceFolder = Images:FindFirstChild(Category)
		local DestinationItems = Items[Category]

		if SourceFolder and type(DestinationItems) == "table" then
			for _, Item in SourceFolder:GetChildren() do
				if DestinationItems[Item.Name] == nil then
					DestinationItems[Item.Name] = 1
					UnlockedCount += 1
				end
			end
		end
	end

	return UnlockedCount
end

function UnlockAll:DeepCopy(Value, Depth)
	if Depth > 6 or type(Value) ~= "table" then
		return Value
	end

	local Result = {}

	for Key, Item in Value do
		Result[Key] = self:DeepCopy(Item, Depth + 1)
	end

	return Result
end

function UnlockAll:Disable()
	self.Disabled = true

	local Success, FreshData = pcall(function()
		return ReplicatedStorage:WaitForChild("Events"):WaitForChild("GetInventory"):InvokeServer({"GetData"})
	end)

	if not Success or type(FreshData) ~= "table" then
		return false
	end

	self.RealState = self:DeepCopy(FreshData, 0)
	self.PlayerData.Data = FreshData

	self.Skin = nil
	self.Announcer = nil
	self.KillEffect = nil
	self.WeaponSkin = nil
	self.MeleeSkin = nil

	return true
end

function UnlockAll:Enable()
	self.Disabled = false
	self:UnlockAll()
	self:AdoptLoadout()
	self:PushAll()
	self:PaintMeleeIcon()
end

function UnlockAll:BackfillMeleeAnimations()
	local Melees = ReplicatedStorage:FindFirstChild("Melees")
	local Dagger = Melees and Melees:FindFirstChild("Dagger")
	local WalkAnimation = Dagger and Dagger:FindFirstChild("Walk")
	local BackwardsWalkAnimation = Dagger and Dagger:FindFirstChild("BWalk")

	if not WalkAnimation or not BackwardsWalkAnimation then
		return
	end

	for _, Melee in Melees:GetChildren() do
		if not Melee:FindFirstChild("Walk") then
			WalkAnimation:Clone().Parent = Melee
		end

		if not Melee:FindFirstChild("BWalk") then
			BackwardsWalkAnimation:Clone().Parent = Melee
		end
	end
end

function UnlockAll:PushAll()
	if self.Disabled then
		return
	end

	local PlayerDataFolder = self.Player:FindFirstChild("Data")

	if not PlayerDataFolder then
		return
	end

	if self.Skin and self:IsValidSkin(self.Skin) then
		local SkinValue = PlayerDataFolder:FindFirstChild("Skin")

		if SkinValue then
			SkinValue.Value = self.Skin

			local SleeveValue = SkinValue:FindFirstChild("Sleeve")

			if SleeveValue then
				SleeveValue.Value = self.Skin
			end
		end

		self.Player:SetAttribute("ForceSleeves", self.Skin)
	end

	if self.Announcer and self:IsValidImage("Announcers", self.Announcer) then
		local AnnouncerValue = PlayerDataFolder:FindFirstChild("Announcer")

		if AnnouncerValue then
			AnnouncerValue.Value = self.Announcer
		end
	end

	if self.KillEffect and self:IsValidImage("KillEffects", self.KillEffect) then
		local KillEffectValue = PlayerDataFolder:FindFirstChild("KillEffect")

		if KillEffectValue then
			KillEffectValue.Value = self.KillEffect
		end
	end

	if self.WeaponSkin then
		local EquippedValue = self.Player:FindFirstChild("Equipped")

		if EquippedValue and EquippedValue.Value ~= self.WeaponSkin then
			EquippedValue.Value = self.WeaponSkin
		end
	end
end

function UnlockAll:ScheduleWeaponSkinRebuild()
	if self.RebuildPending then
		return
	end

	self.RebuildPending = true

	task.delay(0.35, function()
		self.RebuildPending = false
		self:PushAll()

		pcall(function()
			self.Bridge.GiveTools:Fire()
		end)
	end)
end

function UnlockAll:AdoptLoadout(Loadout)
	if self.Disabled then
		return
	end

	Loadout = Loadout or self.PlayerData.Data.Loadout

	if type(Loadout) ~= "table" then
		return
	end

	if self:IsValidSkin(Loadout.Skin) and Loadout.Skin ~= self.Skin then
		self.Skin = Loadout.Skin
	end

	if self:IsValidImage("Announcers", Loadout.Announcer) and Loadout.Announcer ~= self.Announcer then
		self.Announcer = Loadout.Announcer
	end

	if self:IsValidImage("KillEffects", Loadout.KillEffect) and Loadout.KillEffect ~= self.KillEffect then
		self.KillEffect = Loadout.KillEffect
	end

	if type(Loadout.WeaponSkins) == "string"
		and Loadout.WeaponSkins ~= ""
		and Loadout.WeaponSkins ~= self.WeaponSkin
		and self:IsValidImage("WeaponSkins", Loadout.WeaponSkins) then
		self.WeaponSkin = Loadout.WeaponSkins
		self:ScheduleWeaponSkinRebuild()
	end

	if type(Loadout.Melee) == "string"
		and Loadout.Melee ~= self.MeleeSkin
		and self:IsValidMelee(Loadout.Melee) then
		self.MeleeSkin = Loadout.Melee

		task.defer(function()
			self:PaintMeleeIcon()
		end)
	end

	self:PushAll()
end

function UnlockAll:PaintMeleeIcon()
	if self.Disabled then
		return
	end

	if not self:IsValidMelee(self.MeleeSkin) then
		return
	end

	local Image

	pcall(function()
		Image = self.GetIcon.getWeaponOfKiller(self.MeleeSkin)
	end)

	if type(Image) ~= "string" or Image == "" then
		pcall(function()
			Image = self.ItemUtil.GetInfo(self.MeleeSkin, "Melees"):unwrapOr(self.ItemUtil.FALLBACK_ITEM).Image
		end)
	end

	if type(Image) ~= "string" or Image == "" then
		return
	end

	local PlayerGui = self.Player:FindFirstChild("PlayerGui")
	local MainGui = PlayerGui and PlayerGui:FindFirstChild("GUI")
	local Inventory = MainGui and MainGui:FindFirstChild("Inventory")
	local InventoryItem = Inventory and Inventory:FindFirstChild("Item3")

	if not InventoryItem then
		return
	end

	local WeaponImage = InventoryItem:FindFirstChild("Weapon")

	if WeaponImage then
		WeaponImage.Image = Image
	end

	local ToolName = InventoryItem:FindFirstChild("ToolName")

	if ToolName then
		ToolName.Text = self.MeleeSkin
	end
end

function UnlockAll:Equip(Type, Name)
	if self.Disabled then
		return
	end

	if Type == "Skin" and self:IsValidSkin(Name) then
		self.Skin = Name
		self.PlayerData.Data.Loadout.Skin = Name
		self:PushAll()
	elseif Type == "Announcer" and self:IsValidImage("Announcers", Name) then
		self.Announcer = Name
		self.PlayerData.Data.Loadout.Announcer = Name
		self:PushAll()
	elseif Type == "KillEffect" and self:IsValidImage("KillEffects", Name) then
		self.KillEffect = Name
		self.PlayerData.Data.Loadout.KillEffect = Name
		self:PushAll()
	elseif Type == "WeaponSkin" and self:IsValidImage("WeaponSkins", Name) then
		self.WeaponSkin = Name
		self.PlayerData.Data.Loadout.WeaponSkins = Name
		self:PushAll()
		self:ScheduleWeaponSkinRebuild()
	elseif Type == "MeleeSkin" and self:IsValidMelee(Name) then
		self.MeleeSkin = Name
		self.PlayerData.Data.Loadout.Melee = Name

		task.defer(function()
			self:PaintMeleeIcon()
		end)
	end
end

function UnlockAll:HookViewmodel()
	local ViewmodelFunction = filtergc("function", {
		IgnoreExecutor = true,
		Name = "getmyvmodel"
	}, true)

	assert(type(ViewmodelFunction) == "function", "getmyvmodel not found")

	hookfunction(ViewmodelFunction, function()
		local CurrentViewmodel = self.State.gun and self.State.gun.Name

		if self.State.gun and self.State.gun:FindFirstChild("Viewmodel") then
			CurrentViewmodel = self.State.gun.Viewmodel.Value
		end

		local PlayerDataFolder = self.Player:FindFirstChild("Data")
		local MeleeValue = PlayerDataFolder and PlayerDataFolder:FindFirstChild("Melee")
		local MeleeName = string.split(MeleeValue and MeleeValue.Value or "", "_")[1]

		if (self.State.meleeslot == "Knife" or self.State.meleeslot == "Golden Knife")
			and self.State.equipped == "melee"
			and PlayerDataFolder
			and (ReplicatedStorage.Melees:FindFirstChild(MeleeName) or MeleeName == "Shuffle") then

			if MeleeName ~= "Shuffle" then
				local SelectedMelee = self.MeleeSkin

				if type(SelectedMelee) == "string" and SelectedMelee ~= "" and self.State.equipped == "melee" then
					local Viewmodels = ReplicatedStorage:FindFirstChild("Viewmodels")

					if Viewmodels and Viewmodels:FindFirstChild("v_" .. SelectedMelee) then
						return SelectedMelee
					end
				end

				return MeleeName
			end
		end

		return CurrentViewmodel
	end)
end

function UnlockAll:HookCharacterUpdates()
	self.Bridge.ChangeVisibleCharacter:Connect(function(Skin)
		if self:IsValidSkin(Skin) and Skin ~= self.Skin then
			self.Skin = Skin
			self:PushAll()
		end
	end)

	self.Bridge.LockerPreviewVoiceline:Connect(function(Announcer)
		if self:IsValidImage("Announcers", Announcer) and Announcer ~= self.Announcer then
			self.Announcer = Announcer
			self:PushAll()
		end
	end)

	self.Bridge.UpdateTracker:Connect(function()
		task.defer(function()
			pcall(function()
				self:AdoptLoadout()
			end)

			pcall(function()
				self:PaintMeleeIcon()
			end)
		end)
	end)

	self.PlayerData.Updated:Connect(function(Key)
		if Key == "Items" then
			task.defer(function()
				self:UnlockAll()
			end)
		end
	end)
end

function UnlockAll:HookInventoryIcon()
	self.Bridge.UpdateInventory:Connect(function()
		task.defer(function()
			if not self.Disabled then
				pcall(function()
					self:PaintMeleeIcon()
				end)
			end
		end)
	end)
end

function UnlockAll:HookInventoryUpdates()
	local Events = ReplicatedStorage:WaitForChild("Events")
	local PartialDataUpdate = Events:WaitForChild("PartialDataUpdate")

	PartialDataUpdate.OnClientEvent:Connect(function()
		task.defer(function()
			if self.Disabled then
				if self.RealState then
					self.PlayerData.Data = self:DeepCopy(self.RealState, 0)
				end

				self.Skin = nil
				self.Announcer = nil
				self.KillEffect = nil
				self.WeaponSkin = nil
				self.MeleeSkin = nil

				return
			end

			self:UnlockAll()

			pcall(function()
				self:AdoptLoadout()
			end)

			pcall(function()
				self:PushAll()
			end)
		end)
	end)
end

function UnlockAll:HookEquipped()
	local EquippedValue = self.Player:FindFirstChild("Equipped") or self.Player:WaitForChild("Equipped", 5)

	if not EquippedValue then
		return
	end

	EquippedValue:GetPropertyChangedSignal("Value"):Connect(function()
		if self.WeaponSkin
			and self:IsValidImage("WeaponSkins", self.WeaponSkin)
			and EquippedValue.Value ~= self.WeaponSkin then
			EquippedValue.Value = self.WeaponSkin
			self:ScheduleWeaponSkinRebuild()
		end
	end)
end

function UnlockAll:HookDataValues()
	for _, ValueName in {"Skin", "Announcer"} do
		local PlayerDataFolder = self.Player:FindFirstChild("Data")
		local DataValue = PlayerDataFolder and PlayerDataFolder:FindFirstChild(ValueName)

		if DataValue then
			DataValue:GetPropertyChangedSignal("Value"):Connect(function()
				task.defer(function()
					self:PushAll()
				end)
			end)
		end
	end
end

function UnlockAll:HookRagdoll()
	local RagdollEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CreateRagdoll")

	for _, Connection in getconnections(RagdollEvent.OnClientEvent) do
		local ConnectedFunction = Connection.Function

		if type(ConnectedFunction) ~= "function" or self.WrappedFunctions[ConnectedFunction] then
			continue
		end

		self.WrappedFunctions[ConnectedFunction] = true

		pcall(function()
			Connection:Disable()
		end)

		RagdollEvent.OnClientEvent:Connect(function(...)
			local ArgumentCount = select("#", ...)
			local Arguments = {...}

			if self.KillEffect and self.KillEffect ~= "None" then
				local Target = Arguments[2]
                local KillerName = Arguments[11]
				if Target ~= self.Player and KillerName == self.Player.Name then
					Arguments[12] = self.KillEffect
				end
			end

			return ConnectedFunction(table.unpack(Arguments, 1, ArgumentCount))
		end)
	end
end

function UnlockAll:HookCharacterAdded()
	self.Player.CharacterAdded:Connect(function()
		for _, Delay in {0.5, 1.5, 3} do
			task.delay(Delay, function()
				self:UnlockAll()
				self:PushAll()
			end)
		end
	end)
end

return UnlockAll.new()
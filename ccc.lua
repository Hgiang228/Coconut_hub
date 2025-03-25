repeat task.wait(1) until game.PlaceId ~= nil
repeat task.wait(1) until game:GetService("Players") and game:GetService("Players").LocalPlayer
repeat task.wait(1) until not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO")

local HttpService = game.HttpService
local RepStor = game.ReplicatedStorage
local Library = require(RepStor.Library)
local Player = game.Players.LocalPlayer
local HRP = Player.Character.HumanoidRootPart
local Instances = workspace.__THINGS.Instances
local saveMod = require(RepStor.Library.Client.Save)
local mapMod = require(RepStor.Library.Client.MapCmds)
local mapUtil = require(RepStor.Library.Util.MapUtil)
local zoneMod = require(RepStor.Library.Client.ZoneCmds)
local zoneDir = require(RepStor.Library.Directory.Zones)
local zoneUtil = require(RepStor.Library.Util.ZonesUtil)
local rankMod = require(RepStor.Library.Client.RankCmds)
local rbMod = require(RepStor.Library.Client.RebirthCmds)
local tabsMod = require(RepStor.Library.Client.TabController)
local currencyMod = require(RepStor.Library.Client.CurrencyCmds)
local eggMod = require(game.ReplicatedStorage.Library.Client.EggCmds)
local mapFolder = game.PlaceId == 8737899170 and workspace.Map or game.PlaceId == 16498369169 and workspace.Map2
local worldName = mapFolder.Name == "Map" and "World 1" or mapFolder.Name == "Map2" and "World 2"
local worldCurrency if worldName == "World 1" then worldCurrency = "Coins" elseif worldName == "World 2" then worldCurrency = "TechCoins" end
local eggLocal = getsenv(Player.PlayerScripts.Scripts.Game["Egg Opening Frontend"])
hookfunction(eggLocal.PlayEggAnimation, function() return end)
hookfunction(require(game.ReplicatedStorage.Library.Client.PlayerPet).CalculateSpeedMultiplier, function() return 250 end)
--
game:GetService("Players").LocalPlayer.Idled:connect(function()
	game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	wait(1)
	game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
Player.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
Player.PlayerScripts.Scripts.Core["Server Closing"].Enabled = false
--table.foreach(tabsMod, print)
function getActive() return workspace.__THINGS.__INSTANCE_CONTAINER.Active:GetChildren()[1] end
function Info(name) return saveMod.Get()[name] end 
function Open(tabName) return tabsMod.OpenTab(tabName) end
function Close() return tabsMod.CloseTab() end
function teleportToZone(ZoneFolder) -- If needing to Teleport to specific zone can do teleportToZone(mapUtil.GetZone("Zone Name"))
	if ZoneFolder and ZoneFolder:FindFirstChild("INTERACT") then
		if ZoneFolder.INTERACT:FindFirstChild("BREAKABLE_SPAWNS") then
			if ZoneFolder.INTERACT.BREAKABLE_SPAWNS:FindFirstChild("Main") then
				Player.Character.HumanoidRootPart.CFrame = ZoneFolder.INTERACT.BREAKABLE_SPAWNS.Main.CFrame * CFrame.new(0, 10, 0)
			end
		end
	elseif ZoneFolder.PERSISTENT.Teleport then
		Player.Character.HumanoidRootPart.CFrame = ZoneFolder.PERSISTENT.Teleport.CFrame * CFrame.new(0, 10, 0)
	end
end
function sendNotif(msg)
	local message = {content = msg}
	local jsonMessage = HttpService:JSONEncode(message)
	local success, webMessage = pcall(function() 
		HttpService:PostAsync(getgenv().config.webURL, jsonMessage) 
	end)
	if not success then 
		local response = request({Url = getgenv().config.webURL,Method = "POST",Headers = {["Content-Type"] = "application/json"},Body = jsonMessage})
	end
end

function getBestEgg(mod, name)
	local EggNumber = eggMod.GetHighestEggNumberAvailable()
	for _,egg in pairs (game.ReplicatedStorage.__DIRECTORY.Eggs["Zone Eggs"][worldName]:GetDescendants()) do
		local eggName = egg.Name:split(" | ")
		local eggNum = tonumber(eggName[1])
		if eggNum == EggNumber then
			if mod  then
				return egg
			elseif name then
				return egg.Name
			end
		end
	end
end

function goToBestEggPos()
	local eggName = getBestEgg(nil, true)
	local eggTpPlatform
	local eggPath = workspace.__THINGS.Eggs:FindFirstChild("Main") or workspace.__THINGS.Eggs:FindFirstChild("World2")
	for i,v in pairs(eggPath:GetChildren()) do
		local NameSplit = string.split(eggName, " | ")
		local NumSplit = string.split(v.Name, " - ")
		if NumSplit[1] == NameSplit[1] then
			eggTpPlatform = v.PriceFrame.Back
		end
	end
	if eggTpPlatform then
		HRP.CFrame = eggTpPlatform.CFrame * CFrame.new(0, -2, -10) 
	end
end

function checkQuest(id)
	for i,v in pairs(Info("Goals")) do
		if v.Type == id then
			return true
		end
	end
	return false
end

function completeQuest(goal)
	if goal.Type == 22 or goal.Type == 27 or goal.Type == 28 or goal.Type == 29 then
		local obbyName = nil
		if goal.Type == 22 and Info("UnlockedZones")["Autumn"] then
			obbyName = "SpawnObby" 
		elseif goal.Type == 27 and Info("UnlockedZones")["Icy Peaks"] then
			obbyName = "IceObby" 
		elseif goal.Type == 28 and Info("UnlockedZones")["Desert Pyramids"] then
			obbyName = "PyramidObby" 
		elseif goal.Type == 29 and Info("UnlockedZones")["Jungle Temple"] then
			obbyName = "JungleObby"
		end
		if obbyName then
			if not getActive() then 
				firetouchinterest(HRP, Instances[obbyName].Teleports.Enter, 1)
				firetouchinterest(HRP, Instances[obbyName].Teleports.Enter, 0)	
				task.wait(1.5) 
			end
			
			local Start = nil
			local Goal = nil 
			
			if getActive() then
				for i,v in pairs(getActive():GetDescendants()) do
					if v.Name == "StartLine" then
						if v:FindFirstChild("Part") then
							Start = v.Part
						else
							Start = v
						end
					elseif v.Name == "Goal" or v.Name == "Finish" then
						Goal = v
					end
				end
			end

			if Start and Goal then
				repeat HRP.CFrame = CFrame.new(Start.Position + Vector3.new(0,15,0)) task.wait(1.5) until Player.PlayerGui._INSTANCES.ObbyTimer.Enabled
				repeat HRP.CFrame = CFrame.new(Goal.Pad.Position + Vector3.new(0,15,0)) task.wait(1.5) until tostring(getActive()) ~= obbyName
			end
		end
	
	elseif goal.Type == 3 or goal.Type == 20 or goal.Type == 42 then
		local BestEggMod = require(getBestEgg(true, nil)) 
		if BestEggMod and Library.Balancing.CalcEggPrice(BestEggMod) * goal.Amount <= currencyMod.Get(worldCurrency) then
			goToBestEggPos()
			local eggSplit = string.split(getBestEgg(nil, true), " | ")
			local hatchCount = 1 + Info("EggSlotsPurchased")
			while checkQuest(goal.Type) do
				Library.Network.Invoke("Eggs_RequestPurchase", eggSplit[2], hatchCount)
			end
		end
	end
	
end

local autoOrbConnection = nil
local autoLootBagConnection = nil
for i, v in workspace.__THINGS.Orbs:GetChildren() do
	Library.Network.Fire("Orbs: Collect",{tonumber(v.Name)})
	Library.Network.Fire("Orbs_ClaimMultiple",{[1]={[1]=v.Name}})
	task.wait()
	v:Destroy()
end
for i, v in workspace.__THINGS.Lootbags:GetChildren() do
	Library.Network.Fire("Lootbags_Claim",{v.Name})
	task.wait()
	v:Destroy()
end
autoOrbConnection = workspace.__THINGS.Orbs.ChildAdded:Connect(function(v)
	Library.Network.Fire("Orbs: Collect",{tonumber(v.Name)})
	Library.Network.Fire("Orbs_ClaimMultiple",{[1]={[1]=v.Name}})
	task.wait()
	v:Destroy()
end)
autoLootBagConnection = workspace.__THINGS.Lootbags.ChildAdded:Connect(function(v)
	Library.Network.Fire("Lootbags_Claim",{v.Name})
	task.wait()
	v:Destroy()
end)

if not Info("PickedStarterPet") then
	Library.Network.Invoke("Pick Starter Pets", "Cat", "Dog") task.wait(1)
	Close() task.wait(1) -- waits to support emulator :Sob:
end

if Info("FirstLogin") then
	Close() task.wait(1) -- mhm fuck this game :pepelaugh:
	Library.Network.Fire("Changelog: Read") task.wait(1)
end

if getgenv().config.needPetNotifs then
	local found = false
	for i,v in pairs(Info("Inventory")["Pet"]) do
		if v.id == getgenv().config.desiredPetName then found = true break end
	end
	if not found then sendNotif("```diff\n- "..Player.Name.." needs "..tostring(Info("MaxPetsEquipped")).." "..getgenv().config.desiredPetName.."! \n```") end
end

if getgenv().config.autoClaimMail then
	spawn(function()
		while getgenv().config.autoWorld do task.wait(60)
			local success = Library.Network.Invoke("Mailbox: Claim All")
			if success and getgenv().config.needPetNotifs then
				for i,v in pairs(Info("Inventory")["Pet"]) do
					if v.id == getgenv().config.desiredPetName then
						sendNotif("```diff\n+ "..Player.Name.." has claimed "..getgenv().config.desiredPetName.." from mail | "..tostring(os.date("%H:%M")).." \n```")
						break
					end
				end
			end
		end
	end)
end

spawn(function()
	while getgenv().config.autoWorld do task.wait(30)
		if rankMod.AllRewardsReady() then 
			local claimCount = 1
			while not rankMod.AllRewardsRedeemed() do
				Library.Network.Fire("Ranks_ClaimReward", claimCount)
				task.wait(1) claimCount = claimCount + 1
			end
		end
		
		if getgenv().config.stopAtRank then
			if rankMod.GetMaxRank() and rankMod.GetMaxRank() >= getgenv().config.stopAtRankNum then 
				getgenv().config.autoRanks = false
			end
		end
		
		if getgenv().config.stopAtRebirth then
			if rbMod.Get() and rbMod.Get() >= getgenv().config.stopAtRebirthNum then
				getgenv().config.autoRebirth = false
			end
		end
	end
end)

while getgenv().config.autoWorld do task.wait()
	Close()
	if getActive() and tostring(getActive()) == "StairwayToHeaven" then
		firetouchinterest(HRP, Instances["StairwayToHeaven"].Teleports.Leave, 1)
		firetouchinterest(HRP, Instances["StairwayToHeaven"].Teleports.Leave, 0)
	end
	
	if getgenv().config.autoPetSlots then
		if currencyMod.Get("Diamonds") > Library.Balancing.CalcPetSlotPrice(Info("PetSlotsPurchased") + 1) and Info("PetSlotsPurchased") < rankMod.GetMaxPurchasableEquipSlots() and Info("UnlockedZones")["Green Forest"] then
			teleportToZone(mapUtil.GetZone("Green Forest"))
			Library.Network.Invoke("EquipSlotsMachine_RequestPurchase", (Info("PetSlotsPurchased") + 1))
		end
	end
	
	local maxName, maxTable = zoneMod.GetMaxOwnedZone()
	if maxTable.ZoneNumber > 99 and game.PlaceId == 8737899170 then 
		game.ReplicatedStorage.Network.World2Teleport:InvokeServer()
	end
	
	local nextName, nextTable = zoneMod.GetNextZone()
	local rebirth = rbMod.GetNextRebirth()
	if not mapMod.IsInDottedBox() or mapMod.GetCurrentZone() ~= maxTable._id then
		teleportToZone(maxTable.ZoneFolder)
	end
	
	local purchaseSuccess = Library.Network.Invoke("Zones_RequestPurchase", nextTable.ZoneName)
	if purchaseSuccess and getgenv().config.progressNotifs then
		sendNotif("```diff\n+ "..Player.Name.." has unlocked "..nextTable.ZoneName.." | "..tostring(os.date("%H:%M")).." \n```")	
	end
	
	if getgenv().config.autoRebirth then
		if rebirth and rebirth.ZoneNumberRequired then
			if maxTable.ZoneNumber >= rebirth.ZoneNumberRequired then
				local rebirthSuccess = Library.Network.Invoke("Rebirth_Request", tostring(rebirth.RebirthNumber))
				if rebirthSuccess and getgenv().config.rebirthNotifs then
					sendNotif("```diff\n+ "..Player.Name.." has made it to rebirth "..tostring(rebirth.RebirthNumber).." | "..tostring(os.date("%H:%M")).." \n```")
				end
			end
		end
	end
	
	if getgenv().config.autoRanks then
		for _,goal in pairs(Info("Goals")) do
			completeQuest(goal)
		end
	end
end

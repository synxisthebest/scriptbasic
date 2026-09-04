-- ================= CONFIG =================
getgenv().Config = {
    Race = { RaceV3 = true, Mirror = true, PullLever = true },
    Weapon = { GOD = true, CDK = true, SGT = true, POLE = true, SABER = true, KABUTO = true, TTK = true, GB = true, DT = true },
    Hop = { Playernear = true, Ripdindra = true, DoughKing = true, Mirage = true, Darkbeard = false, Ridecastle = false, Cakequeen = false, Soulreaper = false },
    AutoFarm = { 
        ThirdStat = "Sword",
        Masterygun = true, 
        Masterysword = true, 
        Masterymelee = true, 
        Methodfarm = "Level" 
    },
    Settings = {
        Lockfps = true,
        fpslock = 30,
        Whitescreen = false,
        fixlag = true
    },
    Webhook = ""
}

_G.FastAttack = true
_G.Stats = "Melee"
_G.SelectWP = "Melee"
_G.DistroyHit = true
_G.BringMob = true
_G.LevelFarm = true

_G.AutoFactory = true
_G.AutoElite = true
_G.Auto_Def_DarkCoat = false

_G.Active_Fruit = false
_G.Active_Factory = false
_G.Active_Elite = false
_G.Active_Sea2 = false
_G.Active_Pole = false
_G.Active_Saber = false
_G.Active_Superhuman = false
_G.Active_FarmLevel = true

-- ================= CẤU HÌNH RAID =================
_G.AutoRaidEnabled = true
_G.RaidCompleted = false
_G.RaidUsingBeli = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local VU = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local function GetCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

local sethidprop = sethiddenproperty or (function(...) return ... end)
local BringMob = false
local PosMon = CFrame.new(0, 0, 0)
local CurrentSelectWP = "Melee"

local taodangosea1 = (game.PlaceId == 2753915549)
local taodangosea2 = (game.PlaceId == 4442272183 or game.PlaceId == 79091703265657)
local taodangosea3 = (game.PlaceId == 7449423635)

if workspace:FindFirstChild("Map") then
    if workspace.Map:FindFirstChild("Dressrosa") or workspace.Map:FindFirstChild("Colosseum") or workspace.Map:FindFirstChild("Factory") or workspace.Map:FindFirstChild("Ice") then
        taodangosea2 = true
        taodangosea1 = false
        taodangosea3 = false
    elseif workspace.Map:FindFirstChild("Turtle") or workspace.Map:FindFirstChild("HauntedCastle") then
        taodangosea3 = true
        taodangosea1 = false
        taodangosea2 = false
    end
end

local MeleeCache = {}

-- ================= HELPER FUNCTIONS =================
local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function RequestWarp(targetVec3)
    local comm = GetCommF()
    if comm then
        pcall(function()
            comm:InvokeServer("requestEntrance", targetVec3)
        end)
    end
end

local CurrentTween = nil
local CurrentTargetPos = nil

function Tween(Pos)
    local root = GetRoot()
    if not root then return end
    
    local distance = (Pos.Position - root.Position).Magnitude
    if distance <= 25 then
        if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
        root.CFrame = Pos
        return
    end

    if CurrentTween then
        CurrentTween:Cancel()
    end

    CurrentTargetPos = Pos.Position
    -- Tăng tốc độ bay lên (chia cho 450 thay vì 350) để lướt cực nhanh qua đảo
    CurrentTween = TweenService:Create(
        root,
        TweenInfo.new(distance / 450, Enum.EasingStyle.Linear),
        {CFrame = Pos}
    )
    CurrentTween:Play()
end

local function EquipTool(ToolName)
    local selectName = ToolName or _G.CurrentEquippedTool or CurrentSelectWP
    if not selectName then return end
    local tool = LocalPlayer.Backpack:FindFirstChild(selectName) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(selectName))
    if tool and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:EquipTool(tool)
    end
end

function EnableBuso()
    if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HasBuso") then
        local comm = GetCommF()
        if comm then comm:InvokeServer("Buso") end
    end
end

local function HasItem(name)
    return (LocalPlayer.Backpack:FindFirstChild(name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))) ~= nil
end

local function GetSpawnedFruit()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and string.find(obj.Name:lower(), "fruit") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:FindFirstChildOfClass("TouchTransmitter") then
                return obj, handle
            end
        end
    end
    return nil, nil
end

local function HasUnstorableFruit()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    local function checkContainer(cont)
        if not cont then return false end
        for _, item in ipairs(cont:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name:lower(), "fruit") then
                return true
            end
        end
        return false
    end
    return checkContainer(char) or checkContainer(backpack)
end

local function GetCurrentToolMastery(name)
    local charTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name)
    if charTool and charTool:FindFirstChild("Level") then
        return tonumber(charTool.Level.Value) or 0
    end
    
    local bpTool = LocalPlayer.Backpack:FindFirstChild(name)
    if bpTool and bpTool:FindFirstChild("Level") then
        return tonumber(bpTool.Level.Value) or 0
    end
    
    return 0
end

local V1Melees = {
    { Name = "Water Kung Fu", BuyArgs = {"BuyWaterKungFu"}, Price = 750000, Frag = 0, NPCPos1 = CFrame.new(61122, 18, 1569), NPCPos2 = CFrame.new(-4959.12, 35.10, -4669.29, -0.94, 0.00, -0.34, 0.00, 1.00, 0.00, 0.34, 0.00, -0.94) },
    { Name = "Fishman Karate", BuyArgs = {"BuyFishmanKarate"}, Price = 750000, Frag = 0, NPCPos1 = CFrame.new(61122, 18, 1569), NPCPos2 = CFrame.new(-3054.44, 235.54, -10142.81) },
    { Name = "Black Leg", BuyArgs = {"BuyBlackLeg"}, Price = 150000, Frag = 0, NPCPos1 = CFrame.new(-1246, 12, 3995), NPCPos2 = CFrame.new(-445, 199, -825) },
    { Name = "Electro", BuyArgs = {"BuyElectro"}, Price = 500000, Frag = 0, NPCPos1 = CFrame.new(-4842, 718, -2623), NPCPos2 = CFrame.new(-5963.8, 15.3, -5003.5) },
    { Name = "Dragon Breath", BuyArgs = {"BlackbeardReward", "DragonClaw", "2"}, Price = 0, Frag = 1500, ReqLevel = 1100, NPCPos1 = nil, NPCPos2 = CFrame.new(-445, 199, -825) }
}
local SuperhumanNPCPos = CFrame.new(1185, 477, -6499)

-- XOAY VÒNG CÀY MASTERY ĐẾN 450 VÀ CHECK LEVEL CHO DRAGON BREATH
local function GetCurrentMeleeToFarm()
    local myLevel = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level")) and LocalPlayer.Data.Level.Value or 1
    local myBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli")) and LocalPlayer.Data.Beli.Value or 0
    local myFrag = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments")) and LocalPlayer.Data.Fragments.Value or 0

    for _, m in ipairs(V1Melees) do
        if HasItem(m.Name) then
            local mas = GetCurrentToolMastery(m.Name)
            if mas < 450 then
                return m, false
            else
                MeleeCache[m.Name] = true
            end
        end
    end

    for _, m in ipairs(V1Melees) do
        local levelValid = true
        if m.ReqLevel and myLevel < m.ReqLevel then
            levelValid = false
        end

        if not HasItem(m.Name) and not MeleeCache[m.Name] and myBeli >= m.Price and myFrag >= m.Frag and levelValid then
            local npcPos = taodangosea1 and m.NPCPos1 or m.NPCPos2
            if npcPos then
                return m, true
            end
        end
    end
    return nil, false
end

-- ================= HÀM HỖ TRỢ RAID (MIN LEVEL 1100) =================
local MIN_LEVEL_RAID = 1100
local MAX_FRUIT_PRICE = 1000000
local CHIP_NAME = "Special Microchip"
local RAID_COST_BELI = 100000

local function HasRaidChip()
    return HasItem(CHIP_NAME)
end

local function GetFruitList()
    local comm = GetCommF()
    if not comm then return {} end
    local success, fruits = pcall(function()
        return comm:InvokeServer("GetFruits")
    end)
    if success and type(fruits) == "table" then
        return fruits
    end
    return {}
end

local function HasFruitForChip()
    local fruits = GetFruitList()
    for _, fruit in ipairs(fruits) do
        if fruit.Price and fruit.Price <= MAX_FRUIT_PRICE then
            return true
        end
    end
    return false
end

local function BuyChipWithFruit()
    local comm = GetCommF()
    if not comm then return false end
    
    local fruits = GetFruitList()
    for _, fruit in ipairs(fruits) do
        if fruit.Price and fruit.Price <= MAX_FRUIT_PRICE then
            pcall(function()
                comm:InvokeServer("LoadFruit", tostring(fruit.Name))
                task.wait(0.5)
                comm:InvokeServer("RaidsNpc", "Select", CHIP_NAME)
                task.wait(1)
            end)
            if HasRaidChip() then
                return true
            end
        end
    end
    return false
end

local function BuyChipWithBeli()
    local comm = GetCommF()
    if not comm then return false end
    
    pcall(function()
        comm:InvokeServer("RaidsNpc", "Select", CHIP_NAME)
        task.wait(1)
    end)
    return HasRaidChip()
end

local function IsRaidActive()
    local raidTimer = LocalPlayer.PlayerGui:FindFirstChild("Main") and 
                      LocalPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and 
                      LocalPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer")
    return raidTimer and raidTimer.Visible == true
end

local function IsRaidFinished()
    return not IsRaidActive()
end

local function StartRaid()
    if taodangosea2 then
        Tween(CFrame.new(-6438.73535, 250.645355, -4501.50684))
        task.wait(2)
        local raidSummon = workspace.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector
        if raidSummon then
            fireclickdetector(raidSummon)
        end
    elseif taodangosea3 then
        RequestWarp(Vector3.new(-5097.93164, 316.447021, -3142.66602))
        task.wait(2)
        local raidSummon = workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector
        if raidSummon then
            fireclickdetector(raidSummon)
        end
    end
    task.wait(3)
end

local function GatherEnemiesAround(position, radius)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies or not position then return end
    
    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 then
            local distance = (enemy.HumanoidRootPart.Position - position).Magnitude
            if distance <= radius then
                enemy.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(math.random(-5,5), 10, math.random(-5,5)))
                enemy.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                enemy.HumanoidRootPart.CanCollide = false
                enemy.Humanoid.WalkSpeed = 0
                if enemy:FindFirstChild("Head") then
                    enemy.Head.CanCollide = false
                end
                if enemy.Humanoid:FindFirstChild("Animator") then
                    enemy.Humanoid.Animator:Destroy()
                end
            end
        end
    end
end

local function KillEnemiesInRadius(center, radius, maxTime)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end
    
    local startTime = tick()
    while tick() - startTime < (maxTime or 30) do
        local anyAlive = false
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 then
                local distance = (enemy.HumanoidRootPart.Position - center).Magnitude
                if distance <= radius then
                    anyAlive = true
                    EnableBuso()
                    EquipTool(_G.CurrentEquippedTool or CurrentSelectWP)
                    Tween(enemy.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0))
                    VU:CaptureController()
                    VU:Button1Down(Vector2.new(1280, 672))
                    task.wait(0.05)
                    break
                end
            end
        end
        if not anyAlive then
            break
        end
        task.wait(0.1)
    end
end

local function DoRaid()
    local islands = {"Island5", "Island 4", "Island 3", "Island 2", "Island 1"}
    local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if not locations then return end
    
    for _, islandName in ipairs(islands) do
        if not _G.Active_AutoRaid then return end
        local island = locations:FindFirstChild(islandName)
        if island then
            Tween(island.CFrame * CFrame.new(0, 50, 100))
            task.wait(2)
            GatherEnemiesAround(island.Position, 350)
            task.wait(0.5)
            KillEnemiesInRadius(island.Position, 350, 45)
        end
    end
end

-- ================= PRIORITY CONTROLLER =================
local TaskPriority = {
    {
        Name = "Factory",
        Flag = "Active_Factory",
        Check = function()
            if not _G.AutoFactory or not taodangosea2 then return false end
            local enemies = workspace:FindFirstChild("Enemies")
            local core = enemies and enemies:FindFirstChild("Core")
            return core and core:FindFirstChild("Humanoid") and core.Humanoid.Health > 0
        end
    },
    {
        Name = "Fruit",
        Flag = "Active_Fruit",
        Check = function()
            local fruitObj, _ = GetSpawnedFruit()
            return fruitObj ~= nil
        end
    },
    {
        Name = "Elite",
        Flag = "Active_Elite",
        Check = function()
            if not _G.AutoElite or not taodangosea3 then return false end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, name in ipairs({"Diablo", "Deandre", "Urban"}) do
                    local boss = enemies:FindFirstChild(name)
                    if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                        return true
                    end
                end
            end
            local questTitle = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest") and LocalPlayer.PlayerGui.Main.Quest:FindFirstChild("Container") and LocalPlayer.PlayerGui.Main.Quest.Container:FindFirstChild("QuestTitle") and LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle:FindFirstChild("Title")
            if questTitle and questTitle.Text ~= "" then
                for _, name in ipairs({"Diablo", "Deandre", "Urban"}) do
                    if string.find(questTitle.Text, name) then return true end
                end
            end
            return false
        end
    },
    {
        Name = "Sea2",
        Flag = "Active_Sea2",
        Check = function()
            local level = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or 0
            return level >= 700 and taodangosea1
        end
    },
    {
        Name = "Raid",
        Flag = "Active_AutoRaid",
        Check = function()
            local level = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or 0
            if level >= MIN_LEVEL_RAID and not taodangosea1 then
                if HasUnstorableFruit() then
                    return true
                end
                return (_G.AutoRaidEnabled and not _G.RaidCompleted)
            end
            return false
        end
    },
    {
        Name = "Pole",
        Flag = "Active_Pole",
        Check = function()
            if not taodangosea1 or not getgenv().Config.Weapon.POLE then return false end
            if HasItem("Pole (1st Form)") or HasItem("Pole") then return false end
            local enemies = workspace:FindFirstChild("Enemies")
            local boss = enemies and enemies:FindFirstChild("Thunder God")
            return boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0
        end
    },
    {
        Name = "Saber",
        Flag = "Active_Saber",
        Check = function()
            if not taodangosea1 or not getgenv().Config.Weapon.SABER then return false end
            local level = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or 0
            if level < 200 or HasItem("Saber") then return false end

            local enemies = workspace:FindFirstChild("Enemies")
            local saberBoss = enemies and enemies:FindFirstChild("Saber Expert")
            if saberBoss and saberBoss:FindFirstChild("Humanoid") and saberBoss.Humanoid.Health > 0 then
                return true
            end
            local map = workspace:FindFirstChild("Map")
            local finalDoor = map and map:FindFirstChild("Jungle") and map.Jungle:FindFirstChild("Final") and map.Jungle.Final:FindFirstChild("Part")
            if finalDoor and finalDoor.Transparency == 0 then
                return true
            end
            return false
        end
    },
    {
        Name = "Superhuman",
        Flag = "Active_Superhuman",
        Check = function()
            if HasItem("Superhuman") then return false end
            local currentBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli")) and LocalPlayer.Data.Beli.Value or 0
            local currentFrag = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments")) and LocalPlayer.Data.Fragments.Value or 0
            
            local targetMelee, needBuy = GetCurrentMeleeToFarm()
            if needBuy and targetMelee then
                if currentBeli >= targetMelee.Price and currentFrag >= targetMelee.Frag then
                    return true
                end
                return false
            end

            if not targetMelee and taodangosea2 and currentBeli >= 3000000 then
                return true
            end
            return false
        end
    },
    {
        Name = "FarmLevel",
        Flag = "Active_FarmLevel",
        Check = function()
            return true
        end
    }
}

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local selectedTask = nil
            for _, taskItem in ipairs(TaskPriority) do
                if taskItem.Check() then
                    selectedTask = taskItem.Flag
                    break
                end
            end
            for _, taskItem in ipairs(TaskPriority) do
                _G[taskItem.Flag] = (taskItem.Flag == selectedTask)
            end
        end)
    end
end)

-- ================= AUTO FACTORY =================
task.spawn(function()
    while task.wait(0.2) do
        if _G.Active_Factory then
            pcall(function()
                local enemies = workspace:FindFirstChild("Enemies")
                local core = enemies and enemies:FindFirstChild("Core")
                if core and core:FindFirstChild("Humanoid") and core:FindFirstChild("HumanoidRootPart") and core.Humanoid.Health > 0 then
                    repeat
                        task.wait(0.05)
                        if not _G.Active_Factory then break end
                        EnableBuso()
                        EquipTool(_G.CurrentEquippedTool or CurrentSelectWP)
                        core.HumanoidRootPart.CanCollide = false
                        core.Humanoid.WalkSpeed = 0
                        if core:FindFirstChild("Head") then core.Head.CanCollide = false end
                        core.HumanoidRootPart.Size = Vector3.new(80, 80, 80)
                        Tween(CFrame.new(424.1, 211.2, -427.5))
                        VU:CaptureController()
                        VU:Button1Down(Vector2.new(1280, 672))
                    until not _G.Active_Factory or not core.Parent or core.Humanoid.Health <= 0
                else
                    Tween(CFrame.new(424.1, 211.2, -427.5))
                end
            end)
        end
    end
end)

-- ================= AUTO ELITE HUNTER =================
task.spawn(function()
    while task.wait(0.3) do
        if _G.Active_Elite then
            pcall(function()
                local comm = GetCommF()
                local questUI = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                local questTitle = questUI and questUI:FindFirstChild("Container") and questUI.Container:FindFirstChild("QuestTitle") and questUI.Container.QuestTitle:FindFirstChild("Title")
                local hasEliteQuest = questTitle and (string.find(questTitle.Text, "Diablo") or string.find(questTitle.Text, "Deandre") or string.find(questTitle.Text, "Urban"))

                if not hasEliteQuest and comm then
                    comm:InvokeServer("EliteHunter")
                    task.wait(0.5)
                else
                    local enemies = workspace:FindFirstChild("Enemies")
                    local eliteBoss = nil
                    if enemies then
                        for _, name in ipairs({"Diablo", "Deandre", "Urban"}) do
                            local boss = enemies:FindFirstChild(name)
                            if boss and boss:FindFirstChild("Humanoid") and boss:FindFirstChild("HumanoidRootPart") and boss.Humanoid.Health > 0 then
                                eliteBoss = boss
                                break
                            end
                        end
                    end

                    if eliteBoss then
                        repeat
                            task.wait(0.05)
                            if not _G.Active_Elite then break end
                            EnableBuso()
                            EquipTool(_G.CurrentEquippedTool or CurrentSelectWP)
                            eliteBoss.HumanoidRootPart.CanCollide = false
                            eliteBoss.Humanoid.WalkSpeed = 0
                            if eliteBoss:FindFirstChild("Head") then eliteBoss.Head.CanCollide = false end
                            eliteBoss.HumanoidRootPart.Size = Vector3.new(80, 80, 80)
                            Tween(eliteBoss.HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))
                            VU:CaptureController()
                            VU:Button1Down(Vector2.new(1280, 672))
                        until not _G.Active_Elite or not eliteBoss.Parent or eliteBoss.Humanoid.Health <= 0 or not eliteBoss:FindFirstChild("HumanoidRootPart")
                    else
                        for _, name in ipairs({"Diablo", "Deandre", "Urban"}) do
                            local repBoss = ReplicatedStorage:FindFirstChild(name)
                            if repBoss and repBoss:FindFirstChild("HumanoidRootPart") then
                                Tween(repBoss.HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ================= AUTO DEFEND / FARM DARK COAT =================
task.spawn(function()
    while task.wait(0.5) do
        if _G.Auto_Def_DarkCoat then
            pcall(function()
                local function GetBP(item)
                    return LocalPlayer.Backpack:FindFirstChild(item) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(item))
                end

                local function GetDarkbeard()
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, v in ipairs(enemies:GetChildren()) do
                            if v.Name == "Darkbeard" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                return v
                            end
                        end
                    end
                    return nil
                end

                local darkbeardBoss = GetDarkbeard()

                if GetBP("Fist of Darkness") and not darkbeardBoss then
                    Tween(CFrame.new(3677.08203125, 62.751937866211, -3144.8332519531))
                elseif darkbeardBoss then
                    repeat
                        task.wait(0.1)
                        if not _G.Auto_Def_DarkCoat or not darkbeardBoss.Parent or darkbeardBoss.Humanoid.Health <= 0 then break end
                        
                        if darkbeardBoss:FindFirstChild("HumanoidRootPart") then
                            Tween(darkbeardBoss.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                        end

                        EnableBuso()
                        EquipTool(_G.CurrentEquippedTool or CurrentSelectWP)
                        VU:CaptureController()
                        VU:Button1Down(Vector2.new(1280, 672))
                    until not _G.Auto_Def_DarkCoat or not darkbeardBoss.Parent or darkbeardBoss.Humanoid.Health <= 0
                elseif not GetBP("Fist of Darkness") and not darkbeardBoss then
                    _G.AutoFarmChest = true
                    repeat
                        task.wait(1)
                    until not _G.Auto_Def_DarkCoat or GetBP("Fist of Darkness") or GetDarkbeard()
                    _G.AutoFarmChest = false
                end
            end)
        end
    end
end)

-- ================= TỰ ĐỘNG BẬT CHIÊU V =================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local equippedTool = char:FindFirstChildOfClass("Tool")
            if equippedTool and (equippedTool.Name == "Black Leg" or equippedTool.Name == "Death Step") then
                local hasDiable = char:FindFirstChild("DiableJambe") or char:FindFirstChild("MaximumOverheat") or equippedTool:FindFirstChild("DiableJambe")
                if not hasDiable then
                    VIM:SendKeyEvent(true, Enum.KeyCode.V, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                end
            end
        end)
    end
end)

-- ================= XÓA HIỆU ỨNG ĐÒN ĐÁNH =================
task.spawn(function()
    local WorldOrigin = workspace:WaitForChild("_WorldOrigin", 10)
    local BlockedEffects = {
        ["SlashHit"] = true, ["CurvedRing"] = true, ["SwordSlash"] = true,
        ["SlashTail"] = true, ["DamageCounter"] = true, ["HitMarker"] = true
    }
    local function CleanEffect(obj)
        if not _G.DistroyHit or not obj then return end
        if BlockedEffects[obj.Name] or string.find(obj.Name:lower(), "slash") or string.find(obj.Name:lower(), "hit") then
            pcall(function() obj:Destroy() end)
        end
    end
    if WorldOrigin then
        WorldOrigin.ChildAdded:Connect(CleanEffect)
        for _, child in ipairs(WorldOrigin:GetChildren()) do CleanEffect(child) end
    end
end)

-- ================= XÓA HIỆU ỨNG KẾT LIỄU / CHẾT =================
local function StripKillEffects(target)
    if not target then return end
    pcall(function()
        for _, desc in ipairs(target:GetDescendants()) do
            if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Explosion") then
                desc.Enabled = false
                desc:Destroy()
            elseif desc:IsA("Sound") and (string.find(desc.Name:lower(), "kill") or string.find(desc.Name:lower(), "hit") or string.find(desc.Name:lower(), "death")) then
                desc:Stop()
                desc.Volume = 0
            end
        end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in ipairs(enemies:GetChildren()) do
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.BreakJointsOnDeath = false
                        if hum.Health <= 0 then
                            StripKillEffects(enemy)
                            enemy:Destroy()
                        end
                    end
                end
            end
        end)
    end
end)

-- ================= SELF HIGHLIGHT =================
task.spawn(function()
    local function ApplyGlow(char)
        if not char or char:FindFirstChild("KaitunSelfGlow") then return end
        local hl = Instance.new("Highlight")
        hl.Name = "KaitunSelfGlow"
        hl.FillColor = Color3.fromRGB(0, 240, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
    end
    if LocalPlayer.Character then ApplyGlow(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(1)
        ApplyGlow(c)
    end)
end)

-- ================= FIX LAG & LOCK FPS =================
local function OptimizeObject(v)
    pcall(function()
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("BlurEffect") then
            v.Enabled = false
        end
    end)
end

task.spawn(function()
    if getgenv().Config.Settings.Lockfps and typeof(setfpscap) == "function" then
        setfpscap(getgenv().Config.Settings.fpslock or 30)
    end
    if getgenv().Config.Settings.Whitescreen then
        RunService:Set3dRenderingEnabled(false)
    end
    if getgenv().Config.Settings.fixlag then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            if settings() and settings().Rendering then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
            end
            for _, obj in ipairs(workspace:GetDescendants()) do OptimizeObject(obj) end
            for _, obj in ipairs(Lighting:GetChildren()) do OptimizeObject(obj) end
            workspace.DescendantAdded:Connect(function(o) task.wait(0.05) OptimizeObject(o) end)
        end)
    end
end)

-- ================= FAST ATTACK =================
local seed
pcall(function() seed = ReplicatedStorage.Modules.Net.seed:InvokeServer() end)
local Net = ReplicatedStorage:WaitForChild("Modules", 10) and ReplicatedStorage.Modules:WaitForChild("Net", 10)
local RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack", 10)
local RegisterHit = Net and Net:WaitForChild("RE/RegisterHit", 10)

local remote, idremote
for _, v in next, ({ReplicatedStorage:FindFirstChild("Util"), ReplicatedStorage:FindFirstChild("Common"), ReplicatedStorage:FindFirstChild("Remotes"), ReplicatedStorage:FindFirstChild("Assets"), ReplicatedStorage:FindFirstChild("FX")}) do
    if v then
        for _, n in next, v:GetChildren() do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remote, idremote = n, n:GetAttribute("Id")
            end
        end
    end
end


_G.FastAttack = true
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")

local seed = 1
pcall(function() seed = ReplicatedStorage.Modules.Net.seed:InvokeServer() end)

local remote, idremote
for _, v in ipairs({ReplicatedStorage:FindFirstChild("Util"), ReplicatedStorage:FindFirstChild("Common"), ReplicatedStorage:FindFirstChild("Remotes"), ReplicatedStorage:FindFirstChild("Assets"), ReplicatedStorage:FindFirstChild("FX")}) do
    if v then
        for _, n in ipairs(v:GetChildren()) do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remote, idremote = n, n:GetAttribute("Id")
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not _G.FastAttack then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end

    local allParts = {}
    local primaryHead = nil

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        
        if humanoid and hrp and humanoid.Health > 0 then
            if (hrp.Position - root.Position).Magnitude <= 70 then
                if not primaryHead then
                    primaryHead = enemy:FindFirstChild("Head") or hrp
                end
                table.insert(allParts, {enemy, hrp})
            end
        end
    end

    if #allParts == 0 or not primaryHead then return end

    pcall(function()
        RegisterAttack:FireServer()
        RegisterHit:FireServer(primaryHead, allParts, {}, tostring(LocalPlayer.UserId):sub(2, 4))
        
        if remote and idremote then
            local obfName = string.gsub("RE/RegisterHit", ".", function(c)
                return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
            end)
            remote:FireServer(obfName, bit32.bxor(idremote + 909090, seed * 2), primaryHead, allParts)
        end
    end)
end)

-- ================= NHẬP CODE =================
task.spawn(function()
    local redeem = {
        "Sub2Fer999", "Enyu_is_Pro", "JCWK", "StarcodeHEO", "MagicBUS",
        "KittGaming", "Sub2CaptainMaui", "Sub2OfficialNoobie", "TheGreatAce",
        "Sub2NoobMaster123", "Sub2Daigrock", "Axiore", "StrawHatMaine",
        "TantaiGaming", "Bluxxy", "SUB2GAMERROBOT_EXP1", "GAMER_ROBOT_1M",
        "SUBGAMERROBOT_RESET", "RESET_5B", "SUB2GAMERROBOT_RESET1",
        "Sub2UncleKizaru", "ADMIN_TROLL", "DRAGONABUSE", "DEVSCOOKING"
    }
    local comm = GetCommF()
    for _, code in ipairs(redeem) do
        pcall(function()
            if comm then comm:InvokeServer("Redeem", string.gsub(code, "%s+", "")) end
        end)
        task.wait(0.2)
    end
end)

-- ================= NOCLIP =================

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Tắt hoàn toàn trọng lực vật lý thuần túy khi đang farm/tween để không bị kẹt va chạm
            root.Velocity = Vector3.zero
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- ================= AUTO STATS & WEAPON SWITCH =================
local MaxStat = 2550
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local data = LocalPlayer:FindFirstChild("Data")
            local comm = GetCommF()
            if not data or not data:FindFirstChild("Points") or data.Points.Value < 1 or not comm then return end
            local meleeVal = data.Stats.Melee.Level.Value
            local defenseVal = data.Stats.Defense.Level.Value
            local statTarget = (meleeVal < MaxStat and "Melee") or (defenseVal < MaxStat and "Defense") or (getgenv().Config.AutoFarm.ThirdStat or "Sword")
            if statTarget then comm:InvokeServer("AddPoint", statTarget, 1) end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            CurrentSelectWP = "Melee"
            local targetMelee, needBuy = GetCurrentMeleeToFarm()
            
            if targetMelee and not needBuy and HasItem(targetMelee.Name) then
                _G.CurrentEquippedTool = targetMelee.Name
                EquipTool(targetMelee.Name)
            else
                local equipped = false
                for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if v:IsA("Tool") and v.ToolTip == "Melee" and not MeleeCache[v.Name] then
                        _G.CurrentEquippedTool = v.Name
                        EquipTool(v.Name)
                        equipped = true
                        break
                    end
                end
            end
        end)
    end
end)

-- ================= LUỒNG TÁC VỤ: FRUIT & GACHA =================
task.spawn(function()
    while task.wait(1.5) do
        pcall(function()
            local comm = GetCommF()
            local function CheckAndStore(container)
                if not container or not comm then return end
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        local origName = tool:GetAttribute("OriginalName") or (tool:FindFirstChild("Handle") and tool.Handle:GetAttribute("OriginalName"))
                        if origName then
                            comm:InvokeServer("StoreFruit", origName, tool)
                            task.wait(0.2)
                        end
                    end
                end
            end
            CheckAndStore(LocalPlayer:FindFirstChild("Backpack"))
            CheckAndStore(LocalPlayer.Character)
        end)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.Active_Fruit then
            pcall(function()
                local root = GetRoot()
                local _, handle = GetSpawnedFruit()
                if root and handle then
                    Tween(handle.CFrame + Vector3.new(0, 1.5, 0))
                    if typeof(firetouchinterest) == "function" then
                        firetouchinterest(root, handle, 0)
                        task.wait(0.05)
                        firetouchinterest(root, handle, 1)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    pcall(function()
        local netModule = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if netModule then
            local prepEvent = netModule:FindFirstChild("RE/PrepClientSpin")
            if prepEvent and prepEvent:IsA("RemoteEvent") then
                prepEvent.OnClientEvent:Connect(function(...) end)
            end

            local spinGachaEvent = netModule:FindFirstChild("RE/SpinGacha")
            if spinGachaEvent and spinGachaEvent:IsA("RemoteEvent") then
                spinGachaEvent.OnClientEvent:Connect(function(data)
                    if data and data.Winners then
                        for _, prize in ipairs(data.Winners) do
                            print(">>> ĐÃ QUAY TRÚNG TRÁI: " .. tostring(prize.DisplayName))
                        end
                    end
                end)
            end
        end
    end)
end)

-- ================= LUỒNG TÁC VỤ: AUTO SEA 2 =================
task.spawn(function()
    while task.wait(0.3) do
        if _G.Active_Sea2 and taodangosea1 then
            pcall(function()
                local mapIce = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ice")
                local door = mapIce and mapIce:FindFirstChild("Door")
                local root = GetRoot()
                local comm = GetCommF()
                if not root or not comm then return end

                local hasKey = HasItem("Key")
                local doorIsOpen = (door and (door.CanCollide == false or door.Transparency > 0.5)) or (not door)

                if not hasKey and not doorIsOpen then
                    Tween(CFrame.new(4855.9, 5.9, 718.3))
                    if (CFrame.new(4855.9, 5.9, 718.3).Position - root.Position).Magnitude <= 20 then
                        comm:InvokeServer("DressrosaQuestProgress", "Detective")
                        task.wait(0.5)
                    end
                elseif hasKey and not doorIsOpen then
                    EquipTool("Key")
                    Tween(CFrame.new(1347.7, 37.3, -1325.6))
                    
                    if door and (door.Position - root.Position).Magnitude <= 15 then
                        local keyTool = LocalPlayer.Character:FindFirstChild("Key")
                        local keyHandle = keyTool and keyTool:FindFirstChild("Handle")
                        if keyHandle and typeof(firetouchinterest) == "function" then
                            firetouchinterest(keyHandle, door, 0)
                            task.wait(0.05)
                            firetouchinterest(keyHandle, door, 1)
                        end
                        task.wait(1)
                    end
                elseif doorIsOpen then
                    local enemies = workspace:FindFirstChild("Enemies")
                    local boss = enemies and enemies:FindFirstChild("Ice Admiral")

                    if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 and boss:FindFirstChild("HumanoidRootPart") then
                        repeat
                            task.wait()
                            if not _G.Active_Sea2 then break end
                            EnableBuso()
                            EquipTool(_G.CurrentEquippedTool or CurrentSelectWP)
                            boss.HumanoidRootPart.CanCollide = false
                            boss.Humanoid.WalkSpeed = 0
                            boss.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                            Tween(boss.HumanoidRootPart.CFrame * CFrame.new(0, 18, 0))
                            VU:CaptureController()
                            VU:Button1Down(Vector2.new(1280, 672))
                        until not _G.Active_Sea2 or not boss.Parent or boss.Humanoid.Health <= 0

                        task.wait(1)
                        comm:InvokeServer("TravelDressrosa")
                    else
                        Tween(CFrame.new(1347.7, 37.3, -1325.6))
                    end
                else
                    comm:InvokeServer("TravelDressrosa")
                end
            end)
        end
    end
end)

-- ================= LUỒNG TÁC VỤ: SUPERHUMAN =================
local isBuyingMelee = false

task.spawn(function()
    while task.wait(1) do
        if _G.Active_Superhuman and not isBuyingMelee then
            pcall(function()
                local hrp = GetRoot()
                local comm = GetCommF()
                if not hrp or not comm then return end
                
                local targetMelee, needBuy = GetCurrentMeleeToFarm()
                if needBuy and targetMelee then
                    isBuyingMelee = true
                    local targetPos = taodangosea1 and targetMelee.NPCPos1 or targetMelee.NPCPos2
                    
                    if targetPos then
                        if taodangosea1 and (targetMelee.Name == "Water Kung Fu" or targetMelee.Name == "Fishman Karate") and hrp.Position.X < 50000 then
                            RequestWarp(Vector3.new(61163.85, 11.68, 1819.78))
                            task.wait(1.5)
                            hrp = GetRoot()
                        end

                        Tween(targetPos)
                        local dist = (targetPos.Position - hrp.Position).Magnitude
                        local waitTime = math.clamp(dist / 300, 1, 12)
                        
                        local startT = tick()
                        while tick() - startT < waitTime do
                            task.wait(0.5)
                            hrp = GetRoot()
                            if not hrp or (targetPos.Position - hrp.Position).Magnitude <= 20 then
                                break
                            end
                        end

                        hrp = GetRoot()
                        if hrp and (targetPos.Position - hrp.Position).Magnitude <= 35 then
                            comm:InvokeServer(unpack(targetMelee.BuyArgs))
                            task.wait(0.5)
                            comm:InvokeServer("BuyWaterKungFu")
                            task.wait(1)
                            MeleeCache[targetMelee.Name] = true
                        end
                    end
                    isBuyingMelee = false
                    return
                end
                
                if not targetMelee and taodangosea2 then
                    isBuyingMelee = true
                    Tween(SuperhumanNPCPos)
                    local dist = (SuperhumanNPCPos.Position - hrp.Position).Magnitude
                    local waitTime = math.clamp(dist / 300, 1, 10)
                    
                    local startT = tick()
                    while tick() - startT < waitTime do
                        task.wait(0.5)
                        hrp = GetRoot()
                        if not hrp or (SuperhumanNPCPos.Position - hrp.Position).Magnitude <= 20 then
                            break
                        end
                    end

                    hrp = GetRoot()
                    if hrp and (SuperhumanNPCPos.Position - hrp.Position).Magnitude <= 30 then
                        comm:InvokeServer("BuySuperhuman")
                        task.wait(1)
                    end
                    isBuyingMelee = false
                end
            end)
            isBuyingMelee = false
        end
    end
end)

-- ================= CHECK NHIỆM VỤ CHI TIẾT =================
local Mob, NumberQuest, NameQuest, NameMob, CFrameQuest, CFrameMob
function Checknhiemvu()
    local data = LocalPlayer:FindFirstChild("Data")
    local levelObj = data and data:FindFirstChild("Level")
    local YourLevel = levelObj and levelObj.Value or 1

    if taodangosea1 then
        if YourLevel == 1 or YourLevel <= 9 then
            Mob = "Bandit"; NumberQuest = 1; NameQuest = "BanditQuest1"; NameMob = "Bandit"
            CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, 0.939700544, -0, -0.341998369, 0, 1, -0, 0.341998369, 0, 0.939700544)
            CFrameMob = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125)
        elseif YourLevel == 10 or YourLevel <= 14 then
            Mob = "Monkey"; NumberQuest = 1; NameQuest = "JungleQuest"; NameMob = "Monkey"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-1448.51806640625, 67.85301208496094, 11.46579647064209)
        elseif YourLevel == 15 or YourLevel <= 29 then
            Mob = "Gorilla"; NumberQuest = 2; NameQuest = "JungleQuest"; NameMob = "Gorilla"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-1129.8836669921875, 40.46354675292969, -525.4237060546875)
        elseif YourLevel == 30 or YourLevel <= 39 then
            Mob = "Pirate"; NumberQuest = 1; NameQuest = "BuggyQuest1"; NameMob = "Pirate"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-1103.513427734375, 13.752052307128906, 3896.091064453125)
        elseif YourLevel == 40 or YourLevel <= 59 then
            Mob = "Brute"; NumberQuest = 2; NameQuest = "BuggyQuest1"; NameMob = "Brute"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-1140.083740234375, 14.809885025024414, 4322.92138671875)
        elseif YourLevel == 60 or YourLevel <= 74 then
            Mob = "Desert Bandit"; NumberQuest = 1; NameQuest = "DesertQuest"; NameMob = "Desert Bandit"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693)
            CFrameMob = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375)
        elseif YourLevel == 75 or YourLevel <= 89 then
            Mob = "Desert Officer"; NumberQuest = 2; NameQuest = "DesertQuest"; NameMob = "Desert Officer"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693)
            CFrameMob = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875)
        elseif YourLevel == 90 or YourLevel <= 99 then
            Mob = "Snow Bandit"; NumberQuest = 1; NameQuest = "SnowQuest"; NameMob = "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMob = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125)
        elseif YourLevel == 100 or YourLevel <= 119 then
            Mob = "Snowman"; NumberQuest = 2; NameQuest = "SnowQuest"; NameMob = "Snowman"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMob = CFrame.new(1201.6412353515625, 144.57958984375, -1550.0670166015625)
        elseif YourLevel == 120 or YourLevel <= 149 then
            Mob = "Chief Petty Officer"; NumberQuest = 1; NameQuest = "MarineQuest2"; NameMob = "Chief Petty Officer"
            CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-4881.23095703125, 22.65204429626465, 4273.75244140625)
        elseif YourLevel == 150 or YourLevel <= 174 then
            Mob = "Sky Bandit"; NumberQuest = 1; NameQuest = "SkyQuest"; NameMob = "Sky Bandit"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-4953.20703125, 295.74420166015625, -2899.22900390625)
        elseif YourLevel == 175 or YourLevel <= 189 then
            Mob = "Dark Master"; NumberQuest = 2; NameQuest = "SkyQuest"; NameMob = "Dark Master"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-5259.8447265625, 391.3976745605469, -2229.035400390625)
        elseif YourLevel == 190 or YourLevel <= 209 then
            Mob = "Prisoner"; NumberQuest = 1; NameQuest = "PrisonerQuest"; NameMob = "Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, 0.995993316, -2.06384709e-09, -0.0894274712)
            CFrameMob = CFrame.new(5098.9736328125, -0.3204058110713959, 474.2373352050781)
        elseif YourLevel == 210 or YourLevel <= 249 then
            Mob = "Dangerous Prisoner"; NumberQuest = 2; NameQuest = "PrisonerQuest"; NameMob = "Dangerous Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, 0.995993316, -2.06384709e-09, -0.0894274712)
            CFrameMob = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375)
        elseif YourLevel == 250 or YourLevel <= 274 then
            Mob = "Toga Warrior"; NumberQuest = 1; NameQuest = "ColosseumQuest"; NameMob = "Toga Warrior"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298)
            CFrameMob = CFrame.new(-1820.21484375, 51.68385696411133, -2740.6650390625)
        elseif YourLevel == 275 or YourLevel <= 299 then
            Mob = "Gladiator"; NumberQuest = 2; NameQuest = "ColosseumQuest"; NameMob = "Gladiator"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298)
            CFrameMob = CFrame.new(-1292.838134765625, 56.380882263183594, -3339.031494140625)
        elseif YourLevel == 300 or YourLevel <= 324 then
            Mob = "Military Soldier"; NumberQuest = 1; NameQuest = "MagmaQuest"; NameMob = "Military Soldier"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
            CFrameMob = CFrame.new(-5411.16455078125, 11.081554412841797, 8454.29296875)
        elseif YourLevel == 325 or YourLevel <= 374 then
            Mob = "Military Spy"; NumberQuest = 2; NameQuest = "MagmaQuest"; NameMob = "Military Spy"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
            CFrameMob = CFrame.new(-5802.8681640625, 86.26241302490234, 8828.859375)
        elseif YourLevel == 375 or YourLevel <= 399 then
            Mob = "Fishman Warrior"; NumberQuest = 1; NameQuest = "FishmanQuest"; NameMob = "Fishman Warrior"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMob = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625)
        elseif YourLevel == 400 or YourLevel <= 449 then
            Mob = "Fishman Commando"; NumberQuest = 2; NameQuest = "FishmanQuest"; NameMob = "Fishman Commando"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMob = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875)
        elseif YourLevel == 450 or YourLevel <= 474 then
            Mob = "God's Guard"; NumberQuest = 1; NameQuest = "SkyExp1Quest"; NameMob = "God's Guard"
            CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643, 0.996191859, -0, -0.0871884301, 0, 1, -0, 0.0871884301, 0, 0.996191859)
            CFrameMob = CFrame.new(-4710.04296875, 845.2769775390625, -1927.3079833984375)
        elseif YourLevel == 475 or YourLevel <= 524 then
            Mob = "Shanda"; NumberQuest = 2; NameQuest = "SkyExp1Quest"; NameMob = "Shanda"
            CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, 0.906319618, 0, 1, 0, -0.906319618, 0, -0.422592998)
            CFrameMob = CFrame.new(-7678.48974609375, 5566.40380859375, -497.2156066894531)
        elseif YourLevel == 525 or YourLevel <= 549 then
            Mob = "Royal Squad"; NumberQuest = 1; NameQuest = "SkyExp2Quest"; NameMob = "Royal Squad"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-7624.25244140625, 5658.13330078125, -1467.354248046875)
        elseif YourLevel == 550 or YourLevel <= 624 then
            Mob = "Royal Soldier"; NumberQuest = 2; NameQuest = "SkyExp2Quest"; NameMob = "Royal Soldier"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-7836.75341796875, 5645.6640625, -1790.6236572265625)
        elseif YourLevel == 625 or YourLevel <= 649 then
            Mob = "Galley Pirate"; NumberQuest = 1; NameQuest = "FountainQuest"; NameMob = "Galley Pirate"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381)
            CFrameMob = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875)
        elseif YourLevel >= 650 then
            Mob = "Galley Captain"; NumberQuest = 2; NameQuest = "FountainQuest"; NameMob = "Galley Captain"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381)
            CFrameMob = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375)
        end
    elseif taodangosea2 then
        if YourLevel == 700 or YourLevel <= 724 then
            Mob = "Raider"; NumberQuest = 1; NameQuest = "Area1Quest"; NameMob = "Raider"
            CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985)
            CFrameMob = CFrame.new(-728.3267211914062, 52.779319763183594, 2345.7705078125)
        elseif YourLevel == 725 or YourLevel <= 774 then
            Mob = "Mercenary"; NumberQuest = 2; NameQuest = "Area1Quest"; NameMob = "Mercenary"
            CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985)
            CFrameMob = CFrame.new(-1004.3244018554688, 80.15886688232422, 1424.619384765625)
        elseif YourLevel == 775 or YourLevel <= 799 then
            Mob = "Swan Pirate"; NumberQuest = 1; NameQuest = "Area2Quest"; NameMob = "Swan Pirate"
            CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898, 0.139203906, 0, 0.99026376, 0, 1, 0, -0.99026376, 0, 0.139203906)
            CFrameMob = CFrame.new(1068.664306640625, 137.61428833007812, 1322.1060791015625)
        elseif YourLevel == 800 or YourLevel <= 874 then
            Mob = "Factory Staff"; NameQuest = "Area2Quest"; NumberQuest = 2; NameMob = "Factory Staff"
            CFrameQuest = CFrame.new(632.698608, 73.1055908, 918.666321, -0.0319722369, 8.96074881e-10, -0.999488771, 1.36326533e-10, 1, 8.92172336e-10, 0.999488771, -1.07732087e-10, -0.0319722369)
            CFrameMob = CFrame.new(73.07867431640625, 81.86344146728516, -27.470672607421875)
        elseif YourLevel == 875 or YourLevel <= 899 then
            Mob = "Marine Lieutenant"; NumberQuest = 1; NameQuest = "MarineQuest3"; NameMob = "Marine Lieutenant"
            CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-2821.372314453125, 75.89727783203125, -3070.089111328125)
        elseif YourLevel == 900 or YourLevel <= 949 then
            Mob = "Marine Captain"; NumberQuest = 2; NameQuest = "MarineQuest3"; NameMob = "Marine Captain"
            CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-1861.2310791015625, 80.17658233642578, -3254.697509765625)
        elseif YourLevel == 950 or YourLevel <= 974 then
            Mob = "Zombie"; NumberQuest = 1; NameQuest = "ZombieQuest"; NameMob = "Zombie"
            CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146)
            CFrameMob = CFrame.new(-5657.77685546875, 78.96973419189453, -928.68701171875)
        elseif YourLevel == 975 or YourLevel <= 999 then
            Mob = "Vampire"; NumberQuest = 2; NameQuest = "ZombieQuest"; NameMob = "Vampire"
            CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146)
            CFrameMob = CFrame.new(-6037.66796875, 32.18463897705078, -1340.6597900390625)
        elseif YourLevel == 1000 or YourLevel <= 1049 then
            Mob = "Snow Trooper"; NumberQuest = 1; NameQuest = "SnowMountainQuest"; NameMob = "Snow Trooper"
            CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
            CFrameMob = CFrame.new(549.1473388671875, 427.3870544433594, -5563.69873046875)
        elseif YourLevel == 1050 or YourLevel <= 1099 then
            Mob = "Winter Warrior"; NumberQuest = 2; NameQuest = "SnowMountainQuest"; NameMob = "Winter Warrior"
            CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
            CFrameMob = CFrame.new(1142.7451171875, 475.6398010253906, -5199.41650390625)
        elseif YourLevel == 1100 or YourLevel <= 1124 then
            Mob = "Lab Subordinate"; NumberQuest = 1; NameQuest = "IceSideQuest"; NameMob = "Lab Subordinate"
            CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, -0, -0.891015649, 0, 1, -0, 0.891015649, 0, 0.453972578)
            CFrameMob = CFrame.new(-5707.4716796875, 15.951709747314453, -4513.39208984375)
        elseif YourLevel == 1125 or YourLevel <= 1174 then
            Mob = "Horned Warrior"; NumberQuest = 2; NameQuest = "IceSideQuest"; NameMob = "Horned Warrior"
            CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, -0, -0.891015649, 0, 1, -0, 0.891015649, 0, 0.453972578)
            CFrameMob = CFrame.new(-6341.36669921875, 15.951770782470703, -5723.162109375)
        elseif YourLevel == 1175 or YourLevel <= 1199 then
            Mob = "Magma Ninja"; NumberQuest = 1; NameQuest = "FireSideQuest"; NameMob = "Magma Ninja"
            CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMob = CFrame.new(-5449.6728515625, 76.65874481201172, -5808.20068359375)
        elseif YourLevel == 1200 or YourLevel <= 1249 then
            Mob = "Lava Pirate"; NumberQuest = 2; NameQuest = "FireSideQuest"; NameMob = "Lava Pirate"
            CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMob = CFrame.new(-5213.33154296875, 49.73788070678711, -4701.451171875)
        elseif YourLevel == 1250 or YourLevel <= 1274 then
            Mob = "Ship Deckhand"; NumberQuest = 1; NameQuest = "ShipQuest1"; NameMob = "Ship Deckhand"
            CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016)
            CFrameMob = CFrame.new(1212.0111083984375, 150.79205322265625, 33059.24609375)
        elseif YourLevel == 1275 or YourLevel <= 1299 then
            Mob = "Ship Engineer"; NumberQuest = 2; NameQuest = "ShipQuest1"; NameMob = "Ship Engineer"
            CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016)
            CFrameMob = CFrame.new(919.4786376953125, 43.54401397705078, 32779.96875)
        elseif YourLevel == 1300 or YourLevel <= 1324 then
            Mob = "Ship Steward"; NumberQuest = 1; NameQuest = "ShipQuest2"; NameMob = "Ship Steward"
            CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125)
            CFrameMob = CFrame.new(919.4385375976562, 129.55599975585938, 33436.03515625)
        elseif YourLevel == 1325 or YourLevel <= 1349 then
            Mob = "Ship Officer"; NumberQuest = 2; NameQuest = "ShipQuest2"; NameMob = "Ship Officer"
            CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125)
            CFrameMob = CFrame.new(1036.0179443359375, 181.4390411376953, 33315.7265625)
        elseif YourLevel == 1350 or YourLevel <= 1374 then
            Mob = "Arctic Warrior"; NumberQuest = 1; NameQuest = "FrostQuest"; NameMob = "Arctic Warrior"
            CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, 0.358349502, 0, -0.933587909)
            CFrameMob = CFrame.new(5966.24609375, 62.97002029418945, -6179.3828125)
        elseif YourLevel == 1375 or YourLevel <= 1424 then
            Mob = "Snow Lurker"; NumberQuest = 2; NameQuest = "FrostQuest"; NameMob = "Snow Lurker"
            CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, 0.358349502, 0, -0.933587909)
            CFrameMob = CFrame.new(5407.07373046875, 69.19437408447266, -6880.88037109375)
        elseif YourLevel == 1425 or YourLevel <= 1449 then
            Mob = "Sea Soldier"; NumberQuest = 1; NameQuest = "ForgottenQuest"; NameMob = "Sea Soldier"
            CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, 0.990270376, -0, -0.13915664, 0, 1, -0, 0.13915664, 0, 0.990270376)
            CFrameMob = CFrame.new(-3028.2236328125, 64.67451477050781, -9775.4267578125)
        elseif YourLevel >= 1450 then
            Mob = "Water Fighter"; NumberQuest = 2; NameQuest = "ForgottenQuest"; NameMob = "Water Fighter"
            CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, 0.990270376, -0, -0.13915664, 0, 1, -0, 0.13915664, 0, 0.990270376)
            CFrameMob = CFrame.new(-3352.9013671875, 285.01556396484375, -10534.841796875)
        end
    elseif taodangosea3 then
        if YourLevel == 1500 or YourLevel <= 1524 then
            Mob = "Pirate Millionaire"; NumberQuest = 1; NameQuest = "PiratePortQuest"; NameMob = "Pirate Millionaire"
            CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-245.9963836669922, 47.30615234375, 5584.1005859375)
        elseif YourLevel == 1525 or YourLevel <= 1574 then
            Mob = "Pistol Billionaire"; NumberQuest = 2; NameQuest = "PiratePortQuest"; NameMob = "Pistol Billionaire"
            CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875)
        elseif YourLevel == 1575 or YourLevel <= 1599 then
            Mob = "Dragon Crew Warrior"; NumberQuest = 1; NameQuest = "AmazonQuest"; NameMob = "Dragon Crew Warrior"
            CFrameQuest = CFrame.new(5832.83594, 51.6806107, -1101.51563, 0.898790359, -0, -0.438378751, 0, 1, -0, 0.438378751, 0, 0.898790359)
            CFrameMob = CFrame.new(6141.140625, 51.35136413574219, -1340.738525390625)
        elseif YourLevel == 1600 or YourLevel <= 1624 then
            Mob = "Dragon Crew Archer"; NameQuest = "AmazonQuest"; NumberQuest = 2; NameMob = "Dragon Crew Archer"
            CFrameQuest = CFrame.new(5833.1147460938, 51.60498046875, -1103.0693359375)
            CFrameMob = CFrame.new(6616.41748046875, 441.7670593261719, 446.0469970703125)
        elseif YourLevel == 1625 or YourLevel <= 1649 then
            Mob = "Female Islander"; NameQuest = "AmazonQuest2"; NumberQuest = 1; NameMob = "Female Islander"
            CFrameQuest = CFrame.new(5446.8793945313, 601.62945556641, 749.45672607422)
            CFrameMob = CFrame.new(4685.25830078125, 735.8078002929688, 815.3425903320312)
        elseif YourLevel == 1650 or YourLevel <= 1699 then
            Mob = "Giant Islander"; NameQuest = "AmazonQuest2"; NumberQuest = 2; NameMob = "Giant Islander"
            CFrameQuest = CFrame.new(5446.8793945313, 601.62945556641, 749.45672607422)
            CFrameMob = CFrame.new(4729.09423828125, 590.436767578125, -36.97627639770508)
        elseif YourLevel == 1700 or YourLevel <= 1724 then
            Mob = "Marine Commodore"; NumberQuest = 1; NameQuest = "MarineTreeIsland"; NameMob = "Marine Commodore"
            CFrameQuest = CFrame.new(2180.54126, 27.8156815, -6741.5498, -0.965929747, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, -0.965929747)
            CFrameMob = CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125)
        elseif YourLevel == 1725 or YourLevel <= 1774 then
            Mob = "Marine Rear Admiral"; NameMob = "Marine Rear Admiral"; NameQuest = "MarineTreeIsland"; NumberQuest = 2
            CFrameQuest = CFrame.new(2179.98828125, 28.731239318848, -6740.0551757813)
            CFrameMob = CFrame.new(3656.773681640625, 160.52406311035156, -7001.5986328125)
        elseif YourLevel == 1775 or YourLevel <= 1799 then
            Mob = "Fishman Raider"; NumberQuest = 1; NameQuest = "DeepForestIsland3"; NameMob = "Fishman Raider"
            CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMob = CFrame.new(-10407.5263671875, 331.76263427734375, -8368.5166015625)
        elseif YourLevel == 1800 or YourLevel <= 1824 then
            Mob = "Fishman Captain"; NumberQuest = 2; NameQuest = "DeepForestIsland3"; NameMob = "Fishman Captain"
            CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.882952213, 0, -0.882952213)
            CFrameMob = CFrame.new(-10994.701171875, 352.38140869140625, -9002.1103515625)
        elseif YourLevel == 1825 or YourLevel <= 1849 then
            Mob = "Forest Pirate"; NumberQuest = 1; NameQuest = "DeepForestIsland"; NameMob = "Forest Pirate"
            CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, 0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247)
            CFrameMob = CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625)
        elseif YourLevel == 1850 or YourLevel <= 1899 then
            Mob = "Mythological Pirate"; NumberQuest = 2; NameQuest = "DeepForestIsland"; NameMob = "Mythological Pirate"
            CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, 0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247)
            CFrameMob = CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125)
        elseif YourLevel == 1900 or YourLevel <= 1924 then
            Mob = "Jungle Pirate"; NumberQuest = 1; NameQuest = "DeepForestIsland2"; NameMob = "Jungle Pirate"
            CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
            CFrameMob = CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625)
        elseif YourLevel == 1925 or YourLevel <= 1974 then
            Mob = "Musketeer Pirate"; NumberQuest = 2; NameQuest = "DeepForestIsland2"; NameMob = "Musketeer Pirate"
            CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
            CFrameMob = CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375)
        elseif YourLevel == 1975 or YourLevel <= 1999 then
            Mob = "Reborn Skeleton"; NumberQuest = 1; NameQuest = "HauntedQuest1"; NameMob = "Reborn Skeleton"
            CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-8763.7236328125, 165.72299194335938, 6159.86181640625)
        elseif YourLevel == 2000 or YourLevel <= 2024 then
            Mob = "Living Zombie"; NumberQuest = 2; NameQuest = "HauntedQuest1"; NameMob = "Living Zombie"
            CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-10144.1318359375, 138.62667846679688, 5838.0888671875)
        elseif YourLevel == 2025 or YourLevel <= 2049 then
            Mob = "Demonic Soul"; NumberQuest = 1; NameQuest = "HauntedQuest2"; NameMob = "Demonic Soul"
            CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-9505.8720703125, 172.10482788085938, 6158.9931640625)
        elseif YourLevel == 2050 or YourLevel <= 2074 then
            Mob = "Posessed Mummy"; NumberQuest = 2; NameQuest = "HauntedQuest2"; NameMob = "Posessed Mummy"
            CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-9582.0224609375, 6.251527309417725, 6205.478515625)
        elseif YourLevel == 2075 or YourLevel <= 2099 then
            Mob = "Peanut Scout"; NumberQuest = 1; NameQuest = "NutsIslandQuest"; NameMob = "Peanut Scout"
            CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-2143.241943359375, 47.72198486328125, -10029.9951171875)
        elseif YourLevel == 2100 or YourLevel <= 2124 then
            Mob = "Peanut President"; NumberQuest = 2; NameQuest = "NutsIslandQuest"; NameMob = "Peanut President"
            CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-1859.35400390625, 38.10316848754883, -10422.4296875)
        elseif YourLevel == 2125 or YourLevel <= 2149 then
            Mob = "Ice Cream Chef"; NumberQuest = 1; NameQuest = "IceCreamIslandQuest"; NameMob = "Ice Cream Chef"
            CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-872.24658203125, 65.81957244873047, -10919.95703125)
        elseif YourLevel == 2150 or YourLevel <= 2199 then
            Mob = "Ice Cream Commander"; NumberQuest = 2; NameQuest = "IceCreamIslandQuest"; NameMob = "Ice Cream Commander"
            CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-558.06103515625, 112.04895782470703, -11290.7744140625)
        elseif YourLevel == 2200 or YourLevel <= 2224 then
            Mob = "Cookie Crafter"; NumberQuest = 1; NameQuest = "CakeQuest1"; NameMob = "Cookie Crafter"
            CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, 0.957576931, -8.80302053e-08, 0.288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.288177818, -5.2032135e-08, 0.957576931)
            CFrameMob = CFrame.new(-2374.13671875, 37.79826354980469, -12125.30859375)
        elseif YourLevel == 2225 or YourLevel <= 2249 then
            Mob = "Cake Guard"; NumberQuest = 2; NameQuest = "CakeQuest1"; NameMob = "Cake Guard"
            CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, 0.957576931, -8.80302053e-08, 0.288177818, 6.9301187e-08, 1, 7.51931211e-08, -0.288177818, -5.2032135e-08, 0.957576931)
            CFrameMob = CFrame.new(-1598.3070068359375, 43.773197174072266, -12244.5810546875)
        elseif YourLevel == 2250 or YourLevel <= 2274 then
            Mob = "Baking Staff"; NumberQuest = 1; NameQuest = "CakeQuest2"; NameMob = "Baking Staff"
            CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, 0.250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.250778586, 2.64211941e-08, -0.96804446)
            CFrameMob = CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375)
        elseif YourLevel == 2275 or YourLevel <= 2299 then
            Mob = "Head Baker"; NumberQuest = 2; NameQuest = "CakeQuest2"; NameMob = "Head Baker"
            CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 4.22142143e-08, 0.250778586, 4.74911062e-08, 1, 1.49904711e-08, -0.250778586, 2.64211941e-08, -0.96804446)
            CFrameMob = CFrame.new(-2216.188232421875, 82.884521484375, -12869.2939453125)
        elseif YourLevel == 2300 or YourLevel <= 2324 then
            Mob = "Cocoa Warrior"; NumberQuest = 1; NameQuest = "ChocQuest1"; NameMob = "Cocoa Warrior"
            CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, -12201.2333984375)
            CFrameMob = CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125)
        elseif YourLevel == 2325 or YourLevel <= 2349 then
            Mob = "Chocolate Bar Battler"; NumberQuest = 2; NameQuest = "ChocQuest1"; NameMob = "Chocolate Bar Battler"
            CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, -12201.2333984375)
            CFrameMob = CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375)
        elseif YourLevel == 2350 or YourLevel <= 2374 then
            Mob = "Sweet Thief"; NumberQuest = 1; NameQuest = "ChocQuest2"; NameMob = "Sweet Thief"
            CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, -12774.5029296875)
            CFrameMob = CFrame.new(165.1884765625, 76.05885314941406, -12600.8369140625)
        elseif YourLevel == 2375 or YourLevel <= 2399 then
            Mob = "Candy Rebel"; NumberQuest = 2; NameQuest = "ChocQuest2"; NameMob = "Candy Rebel"
            CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, -12774.5029296875)
            CFrameMob = CFrame.new(134.86563110351562, 77.2476806640625, -12876.5478515625)
        elseif YourLevel == 2400 or YourLevel <= 2424 then
            Mob = "Candy Pirate"; NumberQuest = 1; NameQuest = "CandyQuest1"; NameMob = "Candy Pirate"
            CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229492, -14446.3349609375)
            CFrameMob = CFrame.new(-1310.5003662109375, 26.016523361206055, -14562.404296875)
        elseif YourLevel == 2425 or YourLevel <= 2449 then
            Mob = "Snow Demon"; NumberQuest = 2; NameQuest = "CandyQuest1"; NameMob = "Snow Demon"
            CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229492, -14446.3349609375)
            CFrameMob = CFrame.new(-880.2006225585938, 71.24776458740234, -14538.609375)
        elseif YourLevel == 2450 or YourLevel <= 2474 then
            Mob = "Isle Outlaw"; NumberQuest = 1; NameQuest = "TikiQuest1"; NameMob = "Isle Outlaw"
            CFrameQuest = CFrame.new(-16545.9355, 55.6863556, -173.230499)
            CFrameMob = CFrame.new(-16120.6035, 116.520554, -103.038849)
        elseif YourLevel == 2475 or YourLevel <= 2524 then
            Mob = "Island Boy"; NumberQuest = 2; NameQuest = "TikiQuest1"; NameMob = "Island Boy"
            CFrameQuest = CFrame.new(-16545.9355, 55.6863556, -173.230499)
            CFrameMob = CFrame.new(-16751.3125, 121.226219, -264.015015)
        else
            Mob = "Isle Champion"; NumberQuest = 2; NameQuest = "TikiQuest2"; NameMob = "Isle Champion"
            CFrameQuest = CFrame.new(-16539.078125, 55.68632888793945, 1051.5738525390625)
            CFrameMob = CFrame.new(-16933.2129, 93.3503036, 999.450989)
        end
    end
end


spawn(function()
    while task.wait(0.1) do
        if _G.BringMob then
            pcall(function()
                Checknhiemvu()
                local enemies = workspace:FindFirstChild("Enemies")
                local root = GetRoot()
                if enemies and root and Mob then
                    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                    
                    -- Tìm mặt đất dưới chân người chơi bằng Raycast
                    local rayOrigin = root.Position + Vector3.new(0, 10, 0)
                    local rayDirection = Vector3.new(0, -100, 0)
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
                    local groundY = root.Position.Y
                    if raycastResult then
                        groundY = raycastResult.Position.Y
                    end

                    for _, v in pairs(enemies:GetChildren()) do
                        if v.Name == Mob and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v.Parent then
                            local hrp = v.HumanoidRootPart
                            local dist = (hrp.Position - root.Position).Magnitude
                            if dist <= 350 then
                                -- Đặt vận tốc về 0
                                hrp.Velocity = Vector3.zero
                                hrp.RotVelocity = Vector3.zero

                                -- Neo phần gốc để quái không bị bay, rơi hay giật
                                hrp.Anchored = true
                                hrp.CanCollide = false
                                hrp.Size = Vector3.new(60, 60, 60)

                                -- Đặt vị trí quái ngay dưới mặt đất trước mặt người chơi
                                local offsetX = 0
                                local offsetZ = -6  -- phía trước
                                local pos = CFrame.new(
                                    root.Position.X + offsetX,
                                    groundY,
                                    root.Position.Z + offsetZ
                                )
                                hrp.CFrame = pos

                                -- Vô hiệu hóa khả năng di chuyển của quái
                                v.Humanoid.WalkSpeed = 0
                                v.Humanoid.JumpPower = 0
                                v.Humanoid.AutoRotate = false

                                -- Hủy Animator nếu có để tránh lỗi
                                if v:FindFirstChild("Head") then
                                    v.Head.CanCollide = false
                                end
                                if v.Humanoid:FindFirstChild("Animator") then
                                    v.Humanoid.Animator:Destroy()
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while task.wait(0.1) do
        if (_G.LevelFarm or _G.Active_FarmLevel) and not _G.Active_Superhuman and not _G.Active_Sea2 and not _G.Active_AutoRaid then
            pcall(function()
                Checknhiemvu()
                if not CFrameQuest or not NameQuest or not Mob then return end

                local root = GetRoot()
                local comm = GetCommF()
                if not root or not comm then return end

                local questUI = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                local questTitle = questUI and questUI:FindFirstChild("Container") and questUI.Container:FindFirstChild("QuestTitle") and questUI.Container.QuestTitle:FindFirstChild("Title")
                local hasQuest = questTitle and questTitle.Text ~= "" and string.find(questTitle.Text, NameMob)

                if not hasQuest then
                    if questTitle and questTitle.Text ~= "" then
                        pcall(function() comm:InvokeServer("AbandonQuest") end)
                        task.wait(0.2)
                    end

                    Tween(CFrameQuest)
                    if (root.Position - CFrameQuest.Position).Magnitude <= 25 then
                        pcall(function() comm:InvokeServer("StartQuest", NameQuest, NumberQuest) end)
                        task.wait(0.5)
                    end
                else
                    local enemies = workspace:FindFirstChild("Enemies")
                    local targetMob = nil
                    
                    if enemies then
                        for _, v in ipairs(enemies:GetChildren()) do
                            if v.Name == Mob and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                                targetMob = v
                                break
                            end
                        end
                    end

                    if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                        -- Treo lơ lửng trên đầu quái 18 studs để né đòn hoàn toàn
                        local holdPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, 18, 0)
                        if (root.Position - holdPos.Position).Magnitude > 10 then
                            Tween(holdPos)
                        else
                            root.CFrame = holdPos
                        end

                        EnableBuso()
                        EquipTool(_G.SelectWP or "Melee")
                        _G.BringMob = true
                    else
                        _G.BringMob = false
                        if CFrameMob then
                            Tween(CFrameMob * CFrame.new(0, 18, 0))
                        end
                    end
                end
            end)
        end
    end
end)
-- ================= AUTO BUY ABILITIES & HAKI =================
local AbilityList = {
    { Name = "Geppo", Price = 10000, ReqLevel = 0, Type = "BuyHaki", Arg = "Geppo" },
    { Name = "Buso",  Price = 25000, ReqLevel = 0, Type = "BuyHaki", Arg = "Buso" },
    { Name = "Soru",  Price = 100000, ReqLevel = 0, Type = "BuyHaki", Arg = "Soru" },
    { Name = "Ken",   Price = 750000, ReqLevel = 200, Type = "KenTalk", Arg = "Buy", ReqItem = "Saber" }
}

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local data = LocalPlayer:FindFirstChild("Data")
            local comm = GetCommF()
            if not data or not comm then return end
            local myLevel = data.Level.Value
            local myBeli = data.Beli.Value
            
            for _, skill in ipairs(AbilityList) do
                if not skill.Bought and myLevel >= skill.ReqLevel and myBeli >= skill.Price then
                    if not skill.ReqItem or HasItem(skill.ReqItem) then
                        if skill.Type == "BuyHaki" then
                            local res = comm:InvokeServer("BuyHaki", skill.Arg)
                            if res == nil or res == true or res == 1 then skill.Bought = true end
                        elseif skill.Type == "KenTalk" then
                            local res = comm:InvokeServer("KenTalk", skill.Arg)
                            if res == nil or res == true or res == 1 then skill.Bought = true end
                        end
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
end)

-- ================= LUỒNG XỬ LÝ AUTO RAID =================
task.spawn(function()
    while task.wait(1) do
        if _G.Active_AutoRaid then
            pcall(function()
                if not HasRaidChip() then
                    if HasFruitForChip() then
                        BuyChipWithFruit()
                    else
                        local data = LocalPlayer:FindFirstChild("Data")
                        if data and data:FindFirstChild("Beli") and data.Beli.Value >= RAID_COST_BELI then
                            BuyChipWithBeli()
                            _G.RaidUsingBeli = true
                        else
                            task.wait(5)
                            return
                        end
                    end
                end
                
                if not HasRaidChip() then return end
                
                StartRaid()
                
                if not IsRaidFinished() then
                    DoRaid()
                end
                
                local timeOut = 0
                while not IsRaidFinished() and timeOut < 120 do
                    task.wait(1)
                    timeOut = timeOut + 1
                end
                
                if _G.RaidUsingBeli then
                    _G.RaidCompleted = true
                end
            end)
        end
    end
end)
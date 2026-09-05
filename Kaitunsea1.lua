-- ====================================================================
-- 1. AUTO REDEEM CODES ON START
-- ====================================================================
task.spawn(function()
    local Codes = {
        "KITTGAMING", "ENYU_IS_PRO", "FUDD10", "BIGNEWS", "THEGREATACE",
        "SUB2GAMERROBOT_EXP1", "STRAWHATMAINE", "SUB2OFFICIALNOOBIE",
        "SUB2NOOBMASTER123", "SUB2DAIGROCK", "AXIORE", "TANTAIGAMING",
        "JCWK", "FUDD10_V2", "SUB2FER999", "MAGICBUS", "TY_FOR_WATCHING",
        "STARCODEHEO", "ADMIN_STRENGTH", "DRAGONABUSE"
    }

    local RedeemRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 10) and game:GetService("ReplicatedStorage").Remotes:WaitForChild("Redeem", 10)
    if RedeemRemote then
        for _, code in ipairs(Codes) do
            pcall(function()
                RedeemRemote:InvokeServer(code)
            end)
            task.wait(0.3)
        end
    end
end)

-- ====================================================================
-- 2. GLOBAL SETTINGS & SEA DETECTOR
-- ====================================================================
local PlaceId = game.PlaceId
if PlaceId == 2753915549 then
    taodangosea1 = true
elseif PlaceId == 4442272183 then
    taodangosea2 = true
elseif PlaceId == 7449423635 then
    taodangosea3 = true
else
    taodangosea1 = true
end

_G.LevelFarm = true
_G.BringMob = true
_G.FastAttack = true
_G.AutoStats = true
_G.StatPriority = "Melee"
_G.AutoStoreFruit = true
_G.SelectWeapon = _G.SelectWeapon or "Combat"
_G.BypassTP = false

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Player = Players.LocalPlayer

-- ====================================================================
-- 3. SUB FUNCTIONS & UTILS
-- ====================================================================
function EnableBuso()
    local char = Player.Character
    if char and not char:FindFirstChild("HasBuso") then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end
end
AutoHaki = EnableBuso

function EquipTool(Toolse)
    if not Toolse then return end
    local char = Player.Character
    local tool = Player.Backpack:FindFirstChild(Toolse)
    if tool and char and char:FindFirstChild("Humanoid") then
        char.Humanoid:EquipTool(tool)
    end
end
EquipWeapon = EquipTool

function UnEquipWeapon(Weapon)
    local char = Player.Character
    if char and char:FindFirstChild(Weapon) then
        _G.NotAutoEquip = true
        task.wait(0.2)
        char:FindFirstChild(Weapon).Parent = Player.Backpack
        task.wait(0.1)
        _G.NotAutoEquip = false
    end
end

function Click()
    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(1280, 672))
end

function GetRealFruit()
    for _, item in ipairs(workspace:GetChildren()) do
        if item:IsA("Tool") and string.find(item.Name, "Fruit") and item:FindFirstChild("Handle") then
            return item.Handle
        end
    end
    return nil
end

function HasItem(itemName)
    local bp = Player.Backpack
    local ch = Player.Character
    return (bp and bp:FindFirstChild(itemName)) or (ch and ch:FindFirstChild(itemName))
end

function HasProtectedItem()
    local containers = {Player.Backpack, Player.Character}
    for _, bag in ipairs(containers) do
        if bag then
            for _, item in ipairs(bag:GetChildren()) do
                if item:IsA("Tool") then
                    local name = item.Name
                    if string.find(name, "Fruit") or string.find(name, "Key") or string.find(name, "Cup") or name == "Torch" or name == "Relic" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ====================================================================
-- 4. TWEEN SYSTEM
-- ====================================================================
local CurrentTween = nil
local CurrentTargetPos = nil
local SafeTweenSpeed = 230

function stopTween()
    CurrentTargetPos = nil
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp then
        hrp.Velocity = Vector3.zero
        if hrp:FindFirstChild("BodyClip") then
            hrp.BodyClip:Destroy()
        end
    end
    if hum then
        hum.PlatformStand = false
    end
end

function Taixiu(Pos)
    local targetPos = typeof(Pos) == "CFrame" and Pos or CFrame.new(Pos)
    repeat 
        task.wait()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.Humanoid.Health = 0
            Player.Character.HumanoidRootPart.CFrame = targetPos
            task.wait(0.5)
            if Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = targetPos
            end
            if Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest") then
                Player.PlayerGui.Main.Quest.Visible = false
            end
        end
    until not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") or (targetPos.Position - Player.Character.HumanoidRootPart.Position).Magnitude <= 2000
end

function Tween(Pos)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 or not Pos then return end

    local targetPos = typeof(Pos) == "CFrame" and Pos.p or Pos
    local targetCFrame = typeof(Pos) == "CFrame" and Pos or CFrame.new(Pos)
    local Distance = (targetPos - hrp.Position).Magnitude

    if _G.BypassTP and Distance > 2000 and not HasProtectedItem() then
        stopTween()
        Taixiu(targetCFrame)
        return
    end

    if hum.Sit then
        hum.Sit = false
    end
    hum.PlatformStand = true

    local direction = Distance > 0 and (targetPos - hrp.Position).Unit or Vector3.zero

    local Noclip = hrp:FindFirstChild("BodyClip") or Instance.new("BodyVelocity")
    Noclip.Name = "BodyClip"
    Noclip.Parent = hrp
    Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
    Noclip.Velocity = direction * SafeTweenSpeed

    if CurrentTargetPos and (CurrentTargetPos - targetPos).Magnitude < 12 and CurrentTween and CurrentTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    CurrentTargetPos = targetPos

    pcall(function()
        if CurrentTween then
            CurrentTween:Cancel()
        end
        CurrentTween = TweenService:Create(
            hrp,
            TweenInfo.new(Distance / SafeTweenSpeed, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame}
        )
        CurrentTween:Play()
    end)
end
topos = Tween

RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in ipairs(enemies:GetChildren()) do
            local mHrp = mob:FindFirstChild("HumanoidRootPart")
            if mHrp then mHrp.CanCollide = false end
        end
    end
end)

-- ====================================================================
-- 5. QUEST CHECKING (FROM DCM.LUA)
-- ====================================================================
function Checknhiemvu()
    YourLevel = Player.Data.Level.Value
    if taodangosea1 then
        if YourLevel >= 1 and YourLevel <= 9 then
            Mob = "Bandit"
            NumberQuest = 1
            NameQuest = "BanditQuest1"
            NameMob = "Bandit"
            CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, 0.939700544, -0, -0.341998369, 0, 1, -0, 0.341998369, 0, 0.939700544)
            CFrameMob = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125)
        elseif YourLevel >= 10 and YourLevel <= 14 then
            Mob = "Monkey"
            NumberQuest = 1
            NameQuest = "JungleQuest"
            NameMob = "Monkey"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-1448.51806640625, 67.85301208496094, 11.46579647064209)
        elseif YourLevel >= 15 and YourLevel <= 29 then
            Mob = "Gorilla"
            NumberQuest = 2
            NameQuest = "JungleQuest"
            NameMob = "Gorilla"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0)
            CFrameMob = CFrame.new(-1129.8836669921875, 40.46354675292969, -525.4237060546875)
        elseif YourLevel >= 30 and YourLevel <= 39 then
            Mob = "Pirate"
            NumberQuest = 1
            NameQuest = "BuggyQuest1"
            NameMob = "Pirate"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-1103.513427734375, 13.752052307128906, 3896.091064453125)
        elseif YourLevel >= 40 and YourLevel <= 59 then
            Mob = "Brute"
            NumberQuest = 2
            NameQuest = "BuggyQuest1"
            NameMob = "Brute"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627)
            CFrameMob = CFrame.new(-1140.083740234375, 14.809885025024414, 4322.92138671875)
        elseif YourLevel >= 60 and YourLevel <= 74 then
            Mob = "Desert Bandit"
            NumberQuest = 1
            NameQuest = "DesertQuest"
            NameMob = "Desert Bandit"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693)
            CFrameMob = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375)
        elseif YourLevel >= 75 and YourLevel <= 89 then
            Mob = "Desert Officer"
            NumberQuest = 2
            NameQuest = "DesertQuest"
            NameMob = "Desert Officer"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693)
            CFrameMob = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875)
        elseif YourLevel >= 90 and YourLevel <= 99 then
            Mob = "Snow Bandit"
            NumberQuest = 1
            NameQuest = "SnowQuest"
            NameMob = "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMob = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125)
        elseif YourLevel >= 100 and YourLevel <= 119 then
            Mob = "Snowman"
            NumberQuest = 2
            NameQuest = "SnowQuest"
            NameMob = "Snowman"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMob = CFrame.new(1201.6412353515625, 144.57958984375, -1550.0670166015625)
        elseif YourLevel >= 120 and YourLevel <= 149 then
            Mob = "Chief Petty Officer"
            NumberQuest = 1
            NameQuest = "MarineQuest2"
            NameMob = "Chief Petty Officer"
            CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-4881.23095703125, 22.65204429626465, 4273.75244140625)
        elseif YourLevel >= 150 and YourLevel <= 174 then
            Mob = "Sky Bandit"
            NumberQuest = 1
            NameQuest = "SkyQuest"
            NameMob = "Sky Bandit"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-4953.20703125, 295.74420166015625, -2899.22900390625)
        elseif YourLevel >= 175 and YourLevel <= 189 then
            Mob = "Dark Master"
            NumberQuest = 2
            NameQuest = "SkyQuest"
            NameMob = "Dark Master"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268)
            CFrameMob = CFrame.new(-5259.8447265625, 391.3976745605469, -2229.035400390625)
        elseif YourLevel >= 190 and YourLevel <= 209 then
            Mob = "Prisoner"
            NumberQuest = 1
            NameQuest = "PrisonerQuest"
            NameMob = "Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, 0.995993316, -2.06384709e-09, -0.0894274712)
            CFrameMob = CFrame.new(5098.9736328125, -0.3204058110713959, 474.2373352050781)
        elseif YourLevel >= 210 and YourLevel <= 249 then
            Mob = "Dangerous Prisoner"
            NumberQuest = 2
            NameQuest = "PrisonerQuest"
            NameMob = "Dangerous Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -5.00292918e-09, -0.995993316, 1.60817859e-09, 1, -5.16744869e-09, 0.995993316, -2.06384709e-09, -0.0894274712)
            CFrameMob = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375)
        elseif YourLevel >= 250 and YourLevel <= 274 then
            Mob = "Toga Warrior"
            NumberQuest = 1
            NameQuest = "ColosseumQuest"
            NameMob = "Toga Warrior"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298)
            CFrameMob = CFrame.new(-1820.21484375, 51.68385696411133, -2740.6650390625)
        elseif YourLevel >= 275 and YourLevel <= 299 then
            Mob = "Gladiator"
            NumberQuest = 2
            NameQuest = "ColosseumQuest"
            NameMob = "Gladiator"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298)
            CFrameMob = CFrame.new(-1292.838134765625, 56.380882263183594, -3339.031494140625)
        elseif YourLevel >= 300 and YourLevel <= 324 then
            Mob = "Military Soldier"
            NumberQuest = 1
            NameQuest = "MagmaQuest"
            NameMob = "Military Soldier"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
            CFrameMob = CFrame.new(-5411.16455078125, 11.081554412841797, 8454.29296875)
        elseif YourLevel >= 325 and YourLevel <= 374 then
            Mob = "Military Spy"
            NumberQuest = 2
            NameQuest = "MagmaQuest"
            NameMob = "Military Spy"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
            CFrameMob = CFrame.new(-5802.8681640625, 86.26241302490234, 8828.859375)
        elseif YourLevel >= 375 and YourLevel <= 399 then
            Mob = "Fishman Warrior"
            NumberQuest = 1
            NameQuest = "FishmanQuest"
            NameMob = "Fishman Warrior"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMob = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625)
            if (CFrameQuest.Position - Player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875))
            end
        elseif YourLevel >= 400 and YourLevel <= 449 then
            Mob = "Fishman Commando"
            NumberQuest = 2
            NameQuest = "FishmanQuest"
            NameMob = "Fishman Commando"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMob = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875)
            if (CFrameQuest.Position - Player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875))
            end
        elseif YourLevel >= 450 and YourLevel <= 474 then
            Mob = "God's Guard"
            NumberQuest = 1
            NameQuest = "SkyExp1Quest"
            NameMob = "God's Guard"
            CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643, 0.996191859, -0, -0.0871884301, 0, 1, -0, 0.0871884301, 0, 0.996191859)
            CFrameMob = CFrame.new(-4710.04296875, 845.2769775390625, -1927.3079833984375)
            if (CFrameQuest.Position - Player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688))
            end
        elseif YourLevel >= 475 and YourLevel <= 524 then
            Mob = "Shanda"
            NumberQuest = 2
            NameQuest = "SkyExp1Quest"
            NameMob = "Shanda"
            CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, 0.906319618, 0, 1, 0, -0.906319618, 0, -0.422592998)
            CFrameMob = CFrame.new(-7678.48974609375, 5566.40380859375, -497.2156066894531)
            if (CFrameQuest.Position - Player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047))
            end
        elseif YourLevel >= 525 and YourLevel <= 549 then
            Mob = "Royal Squad"
            NumberQuest = 1
            NameQuest = "SkyExp2Quest"
            NameMob = "Royal Squad"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-7624.25244140625, 5658.13330078125, -1467.354248046875)
        elseif YourLevel >= 550 and YourLevel <= 624 then
            Mob = "Royal Soldier"
            NumberQuest = 2
            NameQuest = "SkyExp2Quest"
            NameMob = "Royal Soldier"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMob = CFrame.new(-7836.75341796875, 5645.6640625, -1790.6236572265625)
        elseif YourLevel >= 625 and YourLevel <= 649 then
            Mob = "Galley Pirate"
            NumberQuest = 1
            NameQuest = "FountainQuest"
            NameMob = "Galley Pirate"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381)
            CFrameMob = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875)
        elseif YourLevel >= 650 then
            Mob = "Galley Captain"
            NumberQuest = 2
            NameQuest = "FountainQuest"
            NameMob = "Galley Captain"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381)
            CFrameMob = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375)
        end
    end
end

-- ====================================================================
-- 6. BRING MOB SYSTEM (FROM DCM.LUA)
-- ====================================================================
task.spawn(function()
    while task.wait(0.2) do
        if _G.BringMob and PosMon then
            pcall(function()
                Checknhiemvu()
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if _G.LevelFarm and string.find(v.Name, Mob) and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v.Parent then
                            if (v.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude <= 350 then
                                v.HumanoidRootPart.Size = Vector3.new(50, 50, 50)
                                v.HumanoidRootPart.CFrame = PosMon
                                v.Humanoid:ChangeState(14)
                                v.HumanoidRootPart.CanCollide = false
                                v.Head.CanCollide = false
                                if v.Humanoid:FindFirstChild("Animator") then
                                    v.Humanoid.Animator:Destroy()
                                end
                                sethiddenproperty(Player, "SimulationRadius", math.huge)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ====================================================================
-- 7. BACKGROUND AUTOMATIONS
-- ====================================================================
function DoAutoSaber()
    local jungleFinal = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle") and workspace.Map.Jungle:FindFirstChild("Final")
    if not jungleFinal then return false end
    
    if jungleFinal.Part.Transparency == 0 then
        local questPlates = workspace.Map.Jungle:FindFirstChild("QuestPlates")
        if questPlates and questPlates.Door.Transparency == 0 then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for i = 1, 5 do
                    local plate = questPlates:FindFirstChild("Plate" .. i)
                    if plate and plate:FindFirstChild("Button") then
                        hrp.CFrame = plate.Button.CFrame
                        task.wait(0.5)
                    end
                end
            end
            return true
        end

        local desertBurn = workspace.Map:FindFirstChild("Desert") and workspace.Map.Desert:FindFirstChild("Burn")
        if desertBurn and desertBurn.Part.Transparency == 0 then
            if Player.Backpack:FindFirstChild("Torch") or Player.Character:FindFirstChild("Torch") then
                EquipTool("Torch")
                Tween(CFrame.new(1114.6, 5.0, 4350.2))
            else
                Tween(CFrame.new(-1610.0, 11.5, 164.0))
            end
            return true
        end

        local sickManCheck = ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "SickMan")
        if sickManCheck ~= 0 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "GetCup")
            task.wait(0.3)
            EquipTool("Cup")
            task.wait(0.3)
            if Player.Character:FindFirstChild("Cup") then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "FillCup", Player.Character.Cup)
            end
            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "SickMan")
            return true
        end

        local richSonCheck = ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
        if richSonCheck == nil or richSonCheck == 0 then
            local mobLeader = workspace.Enemies:FindFirstChild("Mob Leader")
            if mobLeader and mobLeader:FindFirstChild("Humanoid") and mobLeader.Humanoid.Health > 0 then
                EquipTool(_G.SelectWeapon)
                EnableBuso()
                Tween(mobLeader.HumanoidRootPart.CFrame * CFrame.new(0, 12, 0))
                Click()
                return true
            else
                Tween(CFrame.new(-2967.5, -4.9, 5328.7))
                return true
            end
        elseif richSonCheck == 1 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
            task.wait(0.3)
            EquipTool("Relic")
            Tween(CFrame.new(-1404.9, 29.9, 3.8))
            return true
        end
    else
        local saber = workspace.Enemies:FindFirstChild("Saber Expert")
        if saber and saber:FindFirstChild("Humanoid") and saber.Humanoid.Health > 0 then
            EquipTool(_G.SelectWeapon)
            EnableBuso()
            Tween(saber.HumanoidRootPart.CFrame * CFrame.new(0, 12, 0))
            Click()
            return true
        end
    end
    return false
end

function DoAutoSecondSea()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end

    local iceDoor = workspace.Map:FindFirstChild("Ice") and workspace.Map.Ice:FindFirstChild("Door")
    if iceDoor and iceDoor.CanCollide == true then
        local talkPos = CFrame.new(4849.3, 5.6, 719.6)
        Tween(talkPos)
        if (hrp.Position - talkPos.Position).Magnitude <= 5 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress", "Detective")
            task.wait(0.5)
            EquipTool("Key")
            Tween(CFrame.new(1347.7, 37.3, -1325.6))
        end
        return true
    end

    local admiral = workspace.Enemies:FindFirstChild("Ice Admiral")
    if admiral and admiral:FindFirstChild("Humanoid") and admiral.Humanoid.Health > 0 then
        EquipTool(_G.SelectWeapon)
        EnableBuso()
        Tween(admiral.HumanoidRootPart.CFrame * CFrame.new(0, 12, 0))
        Click()
        return true
    else
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
        return true
    end
end

-- Auto Store Fruit
task.spawn(function()
    while task.wait(1) do
        if _G.AutoStoreFruit then
            pcall(function()
                local char = Player.Character
                local bp = Player.Backpack
                local function checkAndStore(container)
                    if not container then return end
                    for _, item in ipairs(container:GetChildren()) do
                        if item:IsA("Tool") and (string.find(item.Name, "Fruit") or item:GetAttribute("OriginalName")) then
                            local fruitId = item:GetAttribute("OriginalName") or item.Name:gsub(" Fruit", "")
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitId, item)
                        end
                    end
                end
                checkAndStore(char)
                checkAndStore(bp)
            end)
        end
    end
end)

-- Auto Stats
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoStats then
            pcall(function()
                local points = Player.Data.Points.Value
                if points > 0 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.StatPriority, points)
                end
            end)
        end
    end
end)

-- ====================================================================
-- FIXED: BLACK LEG PURCHASE CONTROLLER (PAUSES FARMING DURING BUY)
-- ====================================================================
local BlackLegConfig = {
    Name = "Black Leg",
    BuyArgs = {"BuyBlackLeg"},
    Price = 150000,
    NPCPos1 = CFrame.new(-1246, 12, 3995)
}

_G.BuyingBlackLeg = false

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then 
                return 
            end

            -- 1. Check if we already own Black Leg
            local ownsBlackLeg = HasItem(BlackLegConfig.Name)
            if ownsBlackLeg then
                _G.BuyingBlackLeg = false
                _G.SelectWeapon = BlackLegConfig.Name
                EquipTool(BlackLegConfig.Name)
                return
            end

            -- 2. If we can afford it, lock the farm loop and go purchase it
            local beli = Player.Data.Beli.Value
            if beli >= BlackLegConfig.Price and not ownsBlackLeg then
                _G.BuyingBlackLeg = true
                
                local dist = (hrp.Position - BlackLegConfig.NPCPos1.Position).Magnitude
                if dist > 15 then
                    Tween(BlackLegConfig.NPCPos1)
                else
                    stopTween()
                    UnEquipWeapon("Combat")
                    task.wait(0.3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(BlackLegConfig.BuyArgs))
                    task.wait(0.8)
                    
                    if HasItem(BlackLegConfig.Name) then
                        _G.SelectWeapon = BlackLegConfig.Name
                        EquipTool(BlackLegConfig.Name)
                        _G.BuyingBlackLeg = false
                    end
                end
            else
                _G.BuyingBlackLeg = false
            end
        end)
    end
end)

-- ====================================================================
-- MAXIMUM ULTRA FAST ATTACK (AUTO-RECOVER CRASH & ZERO DELAY)
-- ====================================================================
_G.FastAttack = true
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")

-- Biến lưu trữ an toàn chống vỡ luồng
local seed = 1
local remote, idremote
local lastHitTick = 0
local targetList = {}
local hash = tostring(LocalPlayer.UserId):sub(2, 4)
local HIT_DELAY = 0.015 -- Tốc độ cực hạn (hơn 60 nhịp/giây)

-- Tự động lấy lại Remote & Seed liên tục để không bao giờ bị tịt đánh
local function RefreshRemotes()
    pcall(function()
        seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
        for _, folderName in ipairs({"Util", "Common", "Remotes", "Assets", "FX"}) do
            local f = ReplicatedStorage:FindFirstChild(folderName)
            if f then
                for _, n in ipairs(f:GetChildren()) do
                    if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                        remote, idremote = n, n:GetAttribute("Id")
                        return
                    end
                end
            end
        end
    end)
end
RefreshRemotes()

-- Luồng làm mới seed định kỳ mỗi 15 giây
task.spawn(function()
    while true do
        task.wait(15)
        RefreshRemotes()
    end
end)

-- Vòng lặp tấn công bọc pcall toàn phần: Chống văng luồng tuyệt đối
RunService.Heartbeat:Connect(function()
    local success, err = pcall(function()
        if not _G.FastAttack then return end
        if (tick() - lastHitTick) < HIT_DELAY then return end

        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end

        -- Bắt buộc phải cầm vũ khí trên tay
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool and _G.SelectWeapon then
            local bpTool = LocalPlayer.Backpack:FindFirstChild(_G.SelectWeapon)
            if bpTool then
                hum:EquipTool(bpTool)
            end
            return
        end

        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end

        table.clear(targetList)
        local primaryPart = nil
        local maxRange = 60

        -- Quét quái hợp lệ
        for _, enemy in ipairs(enemies:GetChildren()) do
            local eHum = enemy:FindFirstChildOfClass("Humanoid")
            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
            
            if eHum and eHrp and eHum.Health > 0 and enemy.Parent == enemies and not enemy:FindFirstChildOfClass("ForceField") then
                local dist = (eHrp.Position - root.Position).Magnitude
                if dist <= maxRange then
                    table.insert(targetList, {enemy, eHrp})
                    if not primaryPart then
                        primaryPart = enemy:FindFirstChild("Head") or eHrp
                    end
                end
            end
        end

        if not primaryPart or #targetList == 0 then return end
        lastHitTick = tick()

        -- Tính khóa mã hóa
        local timeKey = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
        local obfuscated = (remote and idremote and seed) and string.gsub("RE/RegisterHit", ".", function(c)
            return string.char(bit32.bxor(string.byte(c), timeKey))
        end)
        local hashedSeed = (remote and idremote and seed) and bit32.bxor(idremote + 909090, seed * 2)

        -- Đánh dồn 3 gói tin cực nhanh
        for _ = 1, 3 do
            RegisterAttack:FireServer(0)
            RegisterHit:FireServer(primaryPart, targetList, {}, hash)

            if obfuscated and remote then
                remote:FireServer(obfuscated, hashedSeed, primaryPart, targetList)
            end
        end
    end)

    -- Tự động phục hồi ngay nếu dính lỗi ngoại lệ từ game
    if not success then
        lastHitTick = tick() + 0.2
        RefreshRemotes()
    end
end)

-- ====================================================================
-- 8. MAIN LEVEL FARM (FIXED FRAME LOCKING LIKE DCM.LUA)
-- ====================================================================
task.spawn(function()
    while task.wait() do
        if _G.LevelFarm then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then 
                    stopTween()
                    return 
                end

                -- 1. Check & pickup Devil Fruits
                local fruitHandle = GetRealFruit()
                if fruitHandle then
                    Tween(fruitHandle.CFrame)
                    return
                end

                local myLevel = Player.Data.Level.Value

                -- 2. Sea 2 check
                if myLevel >= 700 and taodangosea1 then
                    if DoAutoSecondSea() then return end
                end

                -- 3. Saber check
                local hasSaber = (Player.Backpack:FindFirstChild("Saber") or char:FindFirstChild("Saber"))
                if myLevel >= 200 and not hasSaber then
                    if DoAutoSaber() then return end
                end

                Checknhiemvu()

                local questGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local isQuestActive = questGui and questGui.Visible and questGui:FindFirstChild("Container") and questGui.Container:FindFirstChild("QuestTitle") and questGui.Container.QuestTitle:FindFirstChild("Title") and string.find(questGui.Container.QuestTitle.Title.Text, NameMob)

                if not isQuestActive then
                    PosMon = nil
                    if (CFrameQuest.Position - hrp.Position).Magnitude > 15 then
                        Tween(CFrameQuest)
                    else
                        stopTween()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, NumberQuest)
                        task.wait(0.3)
                    end
                else
                    local foundMob = false
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, v in pairs(enemies:GetChildren()) do
                            if v.Name == Mob and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 and v.Parent then
                                foundMob = true
                                repeat
                                    task.wait()
                                    if not _G.LevelFarm or not v.Parent or v.Humanoid.Health <= 0 or not enemies:FindFirstChild(v.Name) or (questGui and not questGui.Visible) then
                                        break
                                    end

                                    EnableBuso()
                                    EquipTool(_G.SelectWeapon)

                                    -- Anchored position directly above the monster[cite: 2]
                                    Tween(v.HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))[cite: 2]

                                    v.HumanoidRootPart.Size = Vector3.new(60, 60, 60)[cite: 2]
                                    v.Humanoid.WalkSpeed = 0[cite: 2]
                                    v.HumanoidRootPart.CanCollide = false[cite: 2]

                                    PosMon = v.HumanoidRootPart.CFrame[cite: 2]
                                    Click()[cite: 1, 2]
                                until not _G.LevelFarm or not v.Parent or v.Humanoid.Health <= 0 or not enemies:FindFirstChild(v.Name) or (questGui and not questGui.Visible)[cite: 2]
                                break
                            end
                        end
                    end

                    if not foundMob then
                        PosMon = nil
                        Tween(CFrameMob)[cite: 2]
                        if ReplicatedStorage:FindFirstChild(Mob) and ReplicatedStorage[Mob]:FindFirstChild("HumanoidRootPart") then
                            Tween(ReplicatedStorage[Mob].HumanoidRootPart.CFrame * CFrame.new(2, 20, 2))[cite: 2]
                        end
                    end
                end
            end)
        end
    end
end)
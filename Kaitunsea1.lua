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
_G.BuyingBlackLeg = false

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
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end
end
AutoHaki = EnableBuso

-- Auto-find valid combat weapon if selected weapon is missing
function GetCurrentWeapon()
    local char = Player.Character
    if not char then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end

    local bp = Player:FindFirstChild("Backpack")
    if not bp then return nil end

    if _G.SelectWeapon and bp:FindFirstChild(_G.SelectWeapon) then
        return bp[_G.SelectWeapon]
    end

    for _, item in ipairs(bp:GetChildren()) do
        if item:IsA("Tool") and (item.ToolTip == "Melee" or item.ToolTip == "Sword" or item.ToolTip == "Blox Fruit" or string.find(item.Name, "Combat") or string.find(item.Name, "Katana") or string.find(item.Name, "Leg")) then
            _G.SelectWeapon = item.Name
            return item
        end
    end
    return nil
end

function EquipTool(Toolse)
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local bp = Player:FindFirstChild("Backpack")
    if not hum or not bp then return end

    local tool = (Toolse and bp:FindFirstChild(Toolse)) or GetCurrentWeapon()
    if tool and tool.Parent == bp then
        hum:EquipTool(tool)
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
-- 4. TWEEN SYSTEM (FIXED RESPAWN LOCKS)
-- ====================================================================
local CurrentTween = nil
local CurrentTargetPos = nil
local CurrentHrp = nil
local SafeTweenSpeed = 230

function stopTween()
    CurrentTargetPos = nil
    CurrentHrp = nil
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp then
        hrp.Velocity = Vector3.zero
        local clip = hrp:FindFirstChild("BodyClip")
        if clip then clip:Destroy() end
    end
    if hum then
        hum.PlatformStand = false
    end
end

-- Clear tween states when player dies and respawns
Player.CharacterAdded:Connect(function()
    stopTween()
    PosMon = nil
end)

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

-- ====================================================================
-- 4. TWEEN SYSTEM (ANTI-ROLLBACK SKYWAY PATHING)
-- ====================================================================
local CurrentTween = nil
local CurrentTargetPos = nil
local isTraveling = false
local TweenSpeed = 190 -- Optimal speed to bypass server distance checks

function stopTween()
    isTraveling = false
    CurrentTargetPos = nil
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if hrp then
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        local clip = hrp:FindFirstChild("BodyClip")
        if clip then clip:Destroy() end
    end
    if hum then
        hum.PlatformStand = false
    end
end

Player.CharacterAdded:Connect(function()
    stopTween()
    PosMon = nil
end)

function Tween(Pos)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 or not Pos then return end

    local targetCFrame = typeof(Pos) == "CFrame" and Pos or CFrame.new(Pos)
    local targetPos = targetCFrame.Position
    local Distance = (targetPos - hrp.Position).Magnitude

    if Distance <= 8 then
        stopTween()
        return
    end

    -- Prevent the while loop from canceling an active cross-sea flight
    if isTraveling and CurrentTargetPos and (CurrentTargetPos - targetPos).Magnitude < 25 then
        return
    end

    -- Keep Humanoid in Running state so the server does not trigger anti-fly checks
    hum.PlatformStand = false
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)

    -- Freeze physics drag
    local Noclip = hrp:FindFirstChild("BodyClip") or Instance.new("BodyVelocity")
    Noclip.Name = "BodyClip"
    Noclip.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    Noclip.Velocity = Vector3.zero
    Noclip.Parent = hrp
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero

    -- Long Distance: Fly via Skyway (Y = 300) to clear water boundaries
    if Distance > 250 then
        isTraveling = true
        CurrentTargetPos = targetPos

        task.spawn(function()
            local skyY = 300

            -- Stage 1: Ascend straight up to clear land & ocean
            if hrp.Position.Y < (skyY - 20) then
                local upPos = CFrame.new(hrp.Position.X, skyY, hrp.Position.Z)
                local upDist = math.abs(skyY - hrp.Position.Y)
                local tUp = TweenService:Create(
                    hrp,
                    TweenInfo.new(upDist / TweenSpeed, Enum.EasingStyle.Linear),
                    {CFrame = upPos}
                )
                CurrentTween = tUp
                tUp:Play()
                tUp.Completed:Wait()
            end

            if not isTraveling then return end

            -- Stage 2: Glide horizontally across the ocean at Y = 300
            local midSkyPos = CFrame.new(targetPos.X, skyY, targetPos.Z)
            local horizontalDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
            local tMid = TweenService:Create(
                hrp,
                TweenInfo.new(horizontalDist / TweenSpeed, Enum.EasingStyle.Linear),
                {CFrame = midSkyPos}
            )
            CurrentTween = tMid
            tMid:Play()
            tMid.Completed:Wait()

            if not isTraveling then return end

            -- Stage 3: Descend directly down to target
            local downDist = math.abs(skyY - targetPos.Y)
            local tDown = TweenService:Create(
                hrp,
                TweenInfo.new(downDist / TweenSpeed, Enum.EasingStyle.Linear),
                {CFrame = targetCFrame}
            )
            CurrentTween = tDown
            tDown:Play()
            tDown.Completed:Wait()

            isTraveling = false
        end)
    else
        -- Short Distance: Direct linear tween on the same island
        CurrentTargetPos = targetPos
        if CurrentTween then CurrentTween:Cancel() end
        CurrentTween = TweenService:Create(
            hrp,
            TweenInfo.new(Distance / TweenSpeed, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame}
        )
        CurrentTween:Play()
    end
end
-- ====================================================================
-- 5. QUEST CHECKING
-- ====================================================================
function Checknhiemvu()
    YourLevel = Player.Data.Level.Value
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if taodangosea1 then
        if YourLevel >= 1 and YourLevel <= 9 then
            Mob = "Bandit"
            NumberQuest = 1
            NameQuest = "BanditQuest1"
            NameMob = "Bandit"
            CFrameQuest = CFrame.new(1059.37, 15.45, 1550.42)
            CFrameMob = CFrame.new(1045.96, 27.00, 1560.82)
        elseif YourLevel >= 10 and YourLevel <= 14 then
            Mob = "Monkey"
            NumberQuest = 1
            NameQuest = "JungleQuest"
            NameMob = "Monkey"
            CFrameQuest = CFrame.new(-1598.08, 35.55, 153.37)
            CFrameMob = CFrame.new(-1448.51, 67.85, 11.46)
        elseif YourLevel >= 15 and YourLevel <= 29 then
            Mob = "Gorilla"
            NumberQuest = 2
            NameQuest = "JungleQuest"
            NameMob = "Gorilla"
            CFrameQuest = CFrame.new(-1598.08, 35.55, 153.37)
            CFrameMob = CFrame.new(-1129.88, 40.46, -525.42)
        elseif YourLevel >= 30 and YourLevel <= 39 then
            Mob = "Pirate"
            NumberQuest = 1
            NameQuest = "BuggyQuest1"
            NameMob = "Pirate"
            CFrameQuest = CFrame.new(-1141.07, 4.10, 3831.54)
            CFrameMob = CFrame.new(-1103.51, 13.75, 3896.09)
        elseif YourLevel >= 40 and YourLevel <= 59 then
            Mob = "Brute"
            NumberQuest = 2
            NameQuest = "BuggyQuest1"
            NameMob = "Brute"
            CFrameQuest = CFrame.new(-1141.07, 4.10, 3831.54)
            CFrameMob = CFrame.new(-1140.08, 14.80, 4322.92)
        elseif YourLevel >= 60 and YourLevel <= 74 then
            Mob = "Desert Bandit"
            NumberQuest = 1
            NameQuest = "DesertQuest"
            NameMob = "Desert Bandit"
            CFrameQuest = CFrame.new(894.48, 5.14, 4392.43)
            CFrameMob = CFrame.new(924.79, 6.44, 4481.58)
        elseif YourLevel >= 75 and YourLevel <= 89 then
            Mob = "Desert Officer"
            NumberQuest = 2
            NameQuest = "DesertQuest"
            NameMob = "Desert Officer"
            CFrameQuest = CFrame.new(894.48, 5.14, 4392.43)
            CFrameMob = CFrame.new(1608.28, 8.61, 4371.00)
        elseif YourLevel >= 90 and YourLevel <= 99 then
            Mob = "Snow Bandit"
            NumberQuest = 1
            NameQuest = "SnowQuest"
            NameMob = "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74, 88.15, -1298.90)
            CFrameMob = CFrame.new(1354.34, 87.27, -1393.94)
        elseif YourLevel >= 100 and YourLevel <= 119 then
            Mob = "Snowman"
            NumberQuest = 2
            NameQuest = "SnowQuest"
            NameMob = "Snowman"
            CFrameQuest = CFrame.new(1389.74, 88.15, -1298.90)
            CFrameMob = CFrame.new(1201.64, 144.57, -1550.06)
        elseif YourLevel >= 120 and YourLevel <= 149 then
            Mob = "Chief Petty Officer"
            NumberQuest = 1
            NameQuest = "MarineQuest2"
            NameMob = "Chief Petty Officer"
            CFrameQuest = CFrame.new(-5039.58, 27.35, 4324.68)
            CFrameMob = CFrame.new(-4881.23, 22.65, 4273.75)
        elseif YourLevel >= 150 and YourLevel <= 174 then
            Mob = "Sky Bandit"
            NumberQuest = 1
            NameQuest = "SkyQuest"
            NameMob = "Sky Bandit"
            CFrameQuest = CFrame.new(-4839.53, 716.36, -2619.44)
            CFrameMob = CFrame.new(-4953.20, 295.74, -2899.22)
        elseif YourLevel >= 175 and YourLevel <= 189 then
            Mob = "Dark Master"
            NumberQuest = 2
            NameQuest = "SkyQuest"
            NameMob = "Dark Master"
            CFrameQuest = CFrame.new(-4839.53, 716.36, -2619.44)
            CFrameMob = CFrame.new(-5259.84, 391.39, -2229.03)
        elseif YourLevel >= 190 and YourLevel <= 209 then
            Mob = "Prisoner"
            NumberQuest = 1
            NameQuest = "PrisonerQuest"
            NameMob = "Prisoner"
            CFrameQuest = CFrame.new(5308.93, 1.65, 475.12)
            CFrameMob = CFrame.new(5098.97, -0.32, 474.23)
        elseif YourLevel >= 210 and YourLevel <= 249 then
            Mob = "Dangerous Prisoner"
            NumberQuest = 2
            NameQuest = "PrisonerQuest"
            NameMob = "Dangerous Prisoner"
            CFrameQuest = CFrame.new(5308.93, 1.65, 475.12)
            CFrameMob = CFrame.new(5654.56, 15.63, 866.29)
        elseif YourLevel >= 250 and YourLevel <= 274 then
            Mob = "Toga Warrior"
            NumberQuest = 1
            NameQuest = "ColosseumQuest"
            NameMob = "Toga Warrior"
            CFrameQuest = CFrame.new(-1580.04, 6.35, -2986.47)
            CFrameMob = CFrame.new(-1820.21, 51.68, -2740.66)
        elseif YourLevel >= 275 and YourLevel <= 299 then
            Mob = "Gladiator"
            NumberQuest = 2
            NameQuest = "ColosseumQuest"
            NameMob = "Gladiator"
            CFrameQuest = CFrame.new(-1580.04, 6.35, -2986.47)
            CFrameMob = CFrame.new(-1292.83, 56.38, -3339.03)
        elseif YourLevel >= 300 and YourLevel <= 324 then
            Mob = "Military Soldier"
            NumberQuest = 1
            NameQuest = "MagmaQuest"
            NameMob = "Military Soldier"
            CFrameQuest = CFrame.new(-5313.37, 10.95, 8515.29)
            CFrameMob = CFrame.new(-5411.16, 11.08, 8454.29)
        elseif YourLevel >= 325 and YourLevel <= 374 then
            Mob = "Military Spy"
            NumberQuest = 2
            NameQuest = "MagmaQuest"
            NameMob = "Military Spy"
            CFrameQuest = CFrame.new(-5313.37, 10.95, 8515.29)
            CFrameMob = CFrame.new(-5802.86, 86.26, 8828.85)
        elseif YourLevel >= 375 and YourLevel <= 399 then
            Mob = "Fishman Warrior"
            NumberQuest = 1
            NameQuest = "FishmanQuest"
            NameMob = "Fishman Warrior"
            CFrameQuest = CFrame.new(61122.65, 18.49, 1569.39)
            CFrameMob = CFrame.new(60878.30, 18.48, 1543.75)
            if hrp and (CFrameQuest.Position - hrp.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.85, 11.67, 1819.78))
            end
        elseif YourLevel >= 400 and YourLevel <= 449 then
            Mob = "Fishman Commando"
            NumberQuest = 2
            NameQuest = "FishmanQuest"
            NameMob = "Fishman Commando"
            CFrameQuest = CFrame.new(61122.65, 18.49, 1569.39)
            CFrameMob = CFrame.new(61922.63, 18.48, 1493.93)
            if hrp and (CFrameQuest.Position - hrp.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.85, 11.67, 1819.78))
            end
        elseif YourLevel >= 450 and YourLevel <= 474 then
            Mob = "God's Guard"
            NumberQuest = 1
            NameQuest = "SkyExp1Quest"
            NameMob = "God's Guard"
            CFrameQuest = CFrame.new(-4721.88, 843.87, -1949.96)
            CFrameMob = CFrame.new(-4710.04, 845.27, -1927.30)
            if hrp and (CFrameQuest.Position - hrp.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82, 872.54, -1667.55))
            end
        elseif YourLevel >= 475 and YourLevel <= 524 then
            Mob = "Shanda"
            NumberQuest = 2
            NameQuest = "SkyExp1Quest"
            NameMob = "Shanda"
            CFrameQuest = CFrame.new(-7859.09, 5544.19, -381.47)
            CFrameMob = CFrame.new(-7678.48, 5566.40, -497.21)
            if hrp and (CFrameQuest.Position - hrp.Position).Magnitude > 10000 then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.61, 5547.14, -380.29))
            end
        elseif YourLevel >= 525 and YourLevel <= 549 then
            Mob = "Royal Squad"
            NumberQuest = 1
            NameQuest = "SkyExp2Quest"
            NameMob = "Royal Squad"
            CFrameQuest = CFrame.new(-7906.81, 5634.66, -1411.99)
            CFrameMob = CFrame.new(-7624.25, 5658.13, -1467.35)
        elseif YourLevel >= 550 and YourLevel <= 624 then
            Mob = "Royal Soldier"
            NumberQuest = 2
            NameQuest = "SkyExp2Quest"
            NameMob = "Royal Soldier"
            CFrameQuest = CFrame.new(-7906.81, 5634.66, -1411.99)
            CFrameMob = CFrame.new(-7836.75, 5645.66, -1790.62)
        elseif YourLevel >= 625 and YourLevel <= 649 then
            Mob = "Galley Pirate"
            NumberQuest = 1
            NameQuest = "FountainQuest"
            NameMob = "Galley Pirate"
            CFrameQuest = CFrame.new(5259.81, 37.35, 4050.02)
            CFrameMob = CFrame.new(5551.02, 78.90, 3930.41)
        elseif YourLevel >= 650 then
            Mob = "Galley Captain"
            NumberQuest = 2
            NameQuest = "FountainQuest"
            NameMob = "Galley Captain"
            CFrameQuest = CFrame.new(5259.81, 37.35, 4050.02)
            CFrameMob = CFrame.new(5441.95, 42.50, 4950.09)
        end
    end
end

function IsQuestActive()
    local pGui = Player:FindFirstChild("PlayerGui")
    local questGui = pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Quest")
    if questGui and questGui.Visible then
        local container = questGui:FindFirstChild("Container")
        local titleObj = container and container:FindFirstChild("QuestTitle") and container.QuestTitle:FindFirstChild("Title")
        if titleObj and NameMob and string.find(titleObj.Text, NameMob) then
            return true
        end
    end
    return false
end

-- ====================================================================
-- 6. BRING MOB SYSTEM
-- ====================================================================
task.spawn(function()
    while task.wait(0.2) do
        if _G.BringMob and PosMon then
            pcall(function()
                local char = Player.Character
                local myHrp = char and char:FindFirstChild("HumanoidRootPart")
                if not myHrp then return end

                Checknhiemvu()
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if _G.LevelFarm and Mob and string.find(v.Name, Mob) and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v.Parent then
                            if (v.HumanoidRootPart.Position - myHrp.Position).Magnitude <= 350 then
                                v.HumanoidRootPart.Size = Vector3.new(50, 50, 50)
                                v.HumanoidRootPart.CFrame = PosMon
                                v.Humanoid:ChangeState(14)
                                v.HumanoidRootPart.CanCollide = false
                                if v:FindFirstChild("Head") then v.Head.CanCollide = false end
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

function DoAutoSaber()
    local jungleFinal = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle") and workspace.Map.Jungle:FindFirstChild("Final")
    if not jungleFinal or not jungleFinal:FindFirstChild("Part") then return false end

    -- Door is closed (Transparency 0)
    if jungleFinal.Part.Transparency == 0 then
        -- 1. Solve 5 Jungle Plates if the underground hatch is still closed
        local questPlates = workspace.Map.Jungle:FindFirstChild("QuestPlates")
        if questPlates and questPlates:FindFirstChild("Door") and questPlates.Door.Transparency == 0 then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for i = 1, 5 do
                    local plate = questPlates:FindFirstChild("Plate" .. i)
                    if plate and plate:FindFirstChild("Button") then
                        if firetouchinterest then
                            firetouchinterest(hrp, plate.Button, 0)
                            task.wait(0.1)
                            firetouchinterest(hrp, plate.Button, 1)
                        else
                            hrp.CFrame = plate.Button.CFrame
                            task.wait(0.4)
                        end
                    end
                end
            end
            return true
        end

        -- 2. Burn Desert House Door
        local desertBurn = workspace.Map:FindFirstChild("Desert") and workspace.Map.Desert:FindFirstChild("Burn")
        if desertBurn and desertBurn:FindFirstChild("Part") and desertBurn.Part.Transparency == 0 then
            if HasItem("Torch") then
                EquipTool("Torch")
                Tween(desertBurn.Part.CFrame)
            else
                Tween(CFrame.new(-1610.0, 11.5, 164.0))
            end
            return true
        end

        -- 3. Sick Man & Water Cup Quest
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

        -- 4. Open the Saber Door if you already hold or own the Relic
        if HasItem("Relic") then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local char = Player.Character
            EquipTool("Relic")
            
            local doorPart = jungleFinal.Part
            local distToDoor = (hrp.Position - doorPart.Position).Magnitude

            if distToDoor > 12 then
                Tween(doorPart.CFrame * CFrame.new(0, 0, -3))
            else
                stopTween()
                -- Push character directly through the door slot
                hrp.CFrame = doorPart.CFrame

                local relic = char:FindFirstChild("Relic")
                local handle = relic and relic:FindFirstChild("Handle")
                if handle and firetouchinterest then
                    firetouchinterest(handle, doorPart, 0)
                    task.wait(0.1)
                    firetouchinterest(handle, doorPart, 1)
                end
                task.wait(0.5)
            end
            return true
        end

        -- 5. Rich Son & Mob Leader Quest
        local richSonCheck = ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
        if richSonCheck == nil or richSonCheck == 0 then
            local mobLeader = workspace.Enemies:FindFirstChild("Mob Leader")
            if mobLeader and mobLeader:FindFirstChild("Humanoid") and mobLeader.Humanoid.Health > 0 then
                EquipTool()
                EnableBuso()
                Tween(mobLeader.HumanoidRootPart.CFrame * CFrame.new(0, 22, 0))
                Click()
                return true
            else
                Tween(CFrame.new(-2967.5, -4.9, 5328.7))
                return true
            end
        elseif richSonCheck == 1 then
            -- Claim the Relic from Rich Son
            ReplicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
            task.wait(0.5)
            return true
        end
    else
        -- 6. Door is open: Kill the Saber Expert
        local saber = workspace.Enemies:FindFirstChild("Saber Expert")
        if saber and saber:FindFirstChild("Humanoid") and saber.Humanoid.Health > 0 then
            EquipTool()
            EnableBuso()
            Tween(saber.HumanoidRootPart.CFrame * CFrame.new(0, 22, 0))
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

-- Black Leg Purchase Controller
local BlackLegConfig = {
    Name = "Black Leg",
    BuyArgs = {"BuyBlackLeg"},
    Price = 150000,
    NPCPos1 = CFrame.new(-1246, 12, 3995)
}

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then 
                return 
            end

            local ownsBlackLeg = HasItem(BlackLegConfig.Name)
            if ownsBlackLeg then
                _G.BuyingBlackLeg = false
                _G.SelectWeapon = BlackLegConfig.Name
                return
            end

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
-- 8. MAIN LEVEL FARM (FIXED DESPAWN & RESPAWN LOCKS)
-- ====================================================================
task.spawn(function()
    while task.wait() do
        if _G.LevelFarm and not _G.BuyingBlackLeg then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then 
                    stopTween()
                    return 
                end

                -- Pickup Devil Fruits
                local fruitHandle = GetRealFruit()
                if fruitHandle then
                    Tween(fruitHandle.CFrame)
                    return
                end

                local myLevel = Player.Data.Level.Value

                if myLevel >= 700 and taodangosea1 then
                    if DoAutoSecondSea() then return end
                end

                local hasSaber = HasItem("Saber")
                if myLevel >= 200 and not hasSaber then
                    if DoAutoSaber() then return end
                end

                Checknhiemvu()

                if not IsQuestActive() then
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
                                    local curChar = Player.Character
                                    local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
                                    local curHum = curChar and curChar:FindFirstChild("Humanoid")

                                    -- Check if player died during combat
                                    if not curChar or not curHrp or not curHum or curHum.Health <= 0 then
                                        stopTween()
                                        break
                                    end

                                    -- Check if mob died or quest ended
                                    if not _G.LevelFarm or not v.Parent or v.Humanoid.Health <= 0 or not enemies:FindFirstChild(v.Name) or not IsQuestActive() then
                                        break
                                    end

                                    EnableBuso()
                                    EquipTool(_G.SelectWeapon)

                                    Tween(v.HumanoidRootPart.CFrame * CFrame.new(0, 22, 0))

                                    v.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                                    v.Humanoid.WalkSpeed = 0
                                    v.HumanoidRootPart.CanCollide = false

                                    PosMon = v.HumanoidRootPart.CFrame
                                    Click()
                                until not _G.LevelFarm or not v.Parent or v.Humanoid.Health <= 0 or not enemies:FindFirstChild(v.Name) or not IsQuestActive() or (Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health <= 0)
                                break
                            end
                        end
                    end

                    -- If all mobs in the area are dead, safely hover at spawn instead of voiding
                    if not foundMob then
                        PosMon = nil
                        if CFrameMob then
                            Tween(CFrameMob * CFrame.new(0, 25, 0))
                        end
                    end
                end
            end)
        end
    end
end)

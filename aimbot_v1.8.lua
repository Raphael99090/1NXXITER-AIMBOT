--[[
    1NXITER AIMBOT - V1.8 FINAL COM BUBBLE CUSTOMIZADO
    - Imagem personalizada na bolinha flutuante
    - ID: 136644425560507
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Raphael99090/1NXXiter-lib/refs/heads/main/1NXXITER%20lib.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    -- AIMBOT
    Aimbot = false,
    AimPart = "Head",
    Smoothness = 0.5,
    FOVSize = 150,
    ShowFOV = true,
    CrosshairX = 0,
    CrosshairY = 0,
    WallCheck = true,
    TeamCheck = true,
    HitboxExpand = false,
    HitboxSize = 5,
    
    -- ESP
    ESP_Enabled = false,
    ESP_Box = false,
    ESP_Skeleton = false,
    ESP_Names = false,
    ESP_Health = false,
    ESP_Lines = false,
    
    -- OTIMIZAÇÃO
    PotatoMode = false,
    RemoveShadows = false,
    MutarSom = false,
    
    -- BUBBLE CUSTOMIZATION
    BubbleIcon = "rbxassetid://136644425560507",
    UseBubbleImage = true,
    
    -- SISTEMA
    ActiveTeams = {},
    Connections = {},
    OriginalHitboxSizes = {},
    OriginalMaterials = {},
    RemoveTexturesActive = false,
    RemoveParticlesActive = false
}

local Drawings = {}
local EspCache = {}

-- ==============================================================================
-- DETECTAR R6 OU R15
-- ==============================================================================

local function IsR6(char)
    return char:FindFirstChild("Torso") ~= nil and char:FindFirstChild("UpperTorso") == nil
end

local function IsR15(char)
    return char:FindFirstChild("UpperTorso") ~= nil
end

-- ==============================================================================
-- FUNÇÕES AUXILIARES
-- ==============================================================================

local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function IsVisible(targetPart)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = Workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

local function IsTeamSelected(plr)
    if not Settings.TeamCheck then return true end
    if not plr.Team then return true end
    return Settings.ActiveTeams[plr.Team.Name] == true
end

-- ==============================================================================
-- FUNÇÕES DE OTIMIZAÇÃO
-- ==============================================================================

function ApplyPotatoMode()
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
                count = count + 1
            end
            
            if obj:IsA("BasePart") then
                if not Settings.OriginalMaterials[obj] then
                    Settings.OriginalMaterials[obj] = obj.Material
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.CanCollide = true
                count = count + 1
            end
            
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
                count = count + 1
            end
            
            if obj:IsA("Light") then
                obj.Brightness = 0
                count = count + 1
            end
        end)
    end
    
    Library:Notificar("🚀 Modo Batata", "Otimizado! (" .. count .. " objetos)", 3)
end

function DisablePotatoMode()
    for obj, material in pairs(Settings.OriginalMaterials) do
        if obj and obj.Parent then
            pcall(function()
                obj.Material = material
            end)
        end
    end
    Settings.OriginalMaterials = {}
    Library:Notificar("🚀 Modo Batata", "Desativado", 2)
end

function RemoveAllTextures()
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
                count = count + 1
            end
        end)
    end
    Settings.RemoveTexturesActive = true
    Library:Notificar("🎨 Texturas", "Removidas! (" .. count .. ")", 2)
end

function RemoveAllParticles()
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
                count = count + 1
            end
        end)
    end
    Settings.RemoveParticlesActive = true
    Library:Notificar("✨ Partículas", "Removidas! (" .. count .. ")", 2)
end

-- ==============================================================================
-- SELETOR DE ALVO
-- ==============================================================================

local function GetClosestToCrosshair()
    local bestTarget = nil
    local shortestDist = Settings.FOVSize
    local crosshairPos = Vector2.new(Settings.CrosshairX, Settings.CrosshairY)
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and IsTeamSelected(plr) then
            local char = plr.Character
            local part = char:FindFirstChild(Settings.AimPart)
            
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (crosshairPos - targetScreenPos).Magnitude
                    
                    if dist < shortestDist and IsVisible(part) then
                        shortestDist = dist
                        bestTarget = part
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- ==============================================================================
-- DESENHOS
-- ==============================================================================

local function NewLine()
    local l = Drawing.new("Line")
    l.Visible = false
    l.Color = Color3.fromRGB(255, 0, 0)
    l.Thickness = 1.5
    l.Transparency = 1
    table.insert(Drawings, l)
    return l
end

local function NewBox()
    local b = Drawing.new("Square")
    b.Visible = false
    b.Color = Color3.fromRGB(255, 40, 40)
    b.Thickness = 1.5
    b.Transparency = 1
    b.Filled = false
    table.insert(Drawings, b)
    return b
end

local function NewText()
    local t = Drawing.new("Text")
    t.Visible = false
    t.Size = 16
    t.Center = true
    t.Outline = true
    t.Color = Color3.fromRGB(255, 255, 255)
    table.insert(Drawings, t)
    return t
end

local function AddESP(plr)
    if EspCache[plr] then return end
    
    local Objects = {
        Box = NewBox(),
        Name = NewText(),
        HealthBar = Drawing.new("Line"),
        Snapline = NewLine(),
        SkeletonLines = {}
    }
    
    Objects.HealthBar.Thickness = 3
    table.insert(Drawings, Objects.HealthBar)
    
    for i = 1, 20 do
        table.insert(Objects.SkeletonLines, NewLine())
    end
    
    EspCache[plr] = Objects
end

local function RemoveESP(plr)
    if EspCache[plr] then
        EspCache[plr].Box:Remove()
        EspCache[plr].Name:Remove()
        EspCache[plr].HealthBar:Remove()
        EspCache[plr].Snapline:Remove()
        
        for _, line in pairs(EspCache[plr].SkeletonLines) do
            line:Remove()
        end
        
        EspCache[plr] = nil
    end
end

-- ==============================================================================
-- DESENHAR ESQUELETO R6
-- ==============================================================================

local function DrawSkeletonR6(char, esp)
    if not Settings.ESP_Skeleton or not char then return end
    
    local joints = {
        {from = "Head", to = "Torso"},
        {from = "Torso", to = "Left Arm"},
        {from = "Torso", to = "Right Arm"},
        {from = "Torso", to = "Left Leg"},
        {from = "Torso", to = "Right Leg"}
    }
    
    local lineIndex = 1
    
    for _, joint in pairs(joints) do
        local part1 = char:FindFirstChild(joint.from)
        local part2 = char:FindFirstChild(joint.to)
        
        if part1 and part2 and lineIndex <= #esp.SkeletonLines then
            local pos1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2 = Camera:WorldToViewportPoint(part2.Position)
            
            if pos1.Z > 0 and pos2.Z > 0 then
                esp.SkeletonLines[lineIndex].From = Vector2.new(pos1.X, pos1.Y)
                esp.SkeletonLines[lineIndex].To = Vector2.new(pos2.X, pos2.Y)
                esp.SkeletonLines[lineIndex].Color = Color3.fromRGB(0, 255, 0)
                esp.SkeletonLines[lineIndex].Thickness = 1.5
                esp.SkeletonLines[lineIndex].Visible = true
            else
                esp.SkeletonLines[lineIndex].Visible = false
            end
            
            lineIndex = lineIndex + 1
        end
    end
    
    for i = lineIndex, #esp.SkeletonLines do
        esp.SkeletonLines[i].Visible = false
    end
end

-- ==============================================================================
-- DESENHAR ESQUELETO R15
-- ==============================================================================

local function DrawSkeletonR15(char, esp)
    if not Settings.ESP_Skeleton or not char then return end
    
    local joints = {
        {from = "Head", to = "UpperTorso"},
        {from = "UpperTorso", to = "LowerTorso"},
        {from = "UpperTorso", to = "LeftUpperArm"},
        {from = "LeftUpperArm", to = "LeftLowerArm"},
        {from = "LeftLowerArm", to = "LeftHand"},
        {from = "UpperTorso", to = "RightUpperArm"},
        {from = "RightUpperArm", to = "RightLowerArm"},
        {from = "RightLowerArm", to = "RightHand"},
        {from = "LowerTorso", to = "LeftUpperLeg"},
        {from = "LeftUpperLeg", to = "LeftLowerLeg"},
        {from = "LeftLowerLeg", to = "LeftFoot"},
        {from = "LowerTorso", to = "RightUpperLeg"},
        {from = "RightUpperLeg", to = "RightLowerLeg"},
        {from = "RightLowerLeg", to = "RightFoot"}
    }
    
    local lineIndex = 1
    
    for _, joint in pairs(joints) do
        local part1 = char:FindFirstChild(joint.from)
        local part2 = char:FindFirstChild(joint.to)
        
        if part1 and part2 and lineIndex <= #esp.SkeletonLines then
            local pos1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2 = Camera:WorldToViewportPoint(part2.Position)
            
            if pos1.Z > 0 and pos2.Z > 0 then
                esp.SkeletonLines[lineIndex].From = Vector2.new(pos1.X, pos1.Y)
                esp.SkeletonLines[lineIndex].To = Vector2.new(pos2.X, pos2.Y)
                esp.SkeletonLines[lineIndex].Color = Color3.fromRGB(0, 255, 0)
                esp.SkeletonLines[lineIndex].Thickness = 1.5
                esp.SkeletonLines[lineIndex].Visible = true
            else
                esp.SkeletonLines[lineIndex].Visible = false
            end
            
            lineIndex = lineIndex + 1
        end
    end
    
    for i = lineIndex, #esp.SkeletonLines do
        esp.SkeletonLines[i].Visible = false
    end
end

local function DrawSkeleton(char, esp)
    if IsR6(char) then
        DrawSkeletonR6(char, esp)
    elseif IsR15(char) then
        DrawSkeletonR15(char, esp)
    end
end

-- ==============================================================================
-- LOOP RENDERSTEPPED
-- ==============================================================================

local renderConnection = RunService.RenderStepped:Connect(function()
    if not Settings.FOVCircle then
        Settings.FOVCircle = Drawing.new("Circle")
        Settings.FOVCircle.Color = Color3.fromRGB(255, 40, 40)
        Settings.FOVCircle.Thickness = 2
        Settings.FOVCircle.Filled = false
        Settings.FOVCircle.Transparency = 0.7
        table.insert(Drawings, Settings.FOVCircle)
    end
    
    Settings.FOVCircle.Position = Vector2.new(Settings.CrosshairX, Settings.CrosshairY)
    Settings.FOVCircle.Radius = Settings.FOVSize
    Settings.FOVCircle.Visible = Settings.ShowFOV and Settings.Aimbot
    
    -- ============ AIMBOT ============
    if Settings.Aimbot then
        local Target = GetClosestToCrosshair()
        
        if Target then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, Target.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
    
    -- ============ HITBOX EXPAND ============
    if Settings.HitboxExpand then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and IsAlive(plr) and IsTeamSelected(plr) then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    if not Settings.OriginalHitboxSizes[plr] then
                        Settings.OriginalHitboxSizes[plr] = root.Size
                    end
                    
                    root.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    root.Transparency = 0.7
                    root.CanCollide = false
                    root.Color = Color3.fromRGB(255, 0, 0)
                    root.Material = Enum.Material.Neon
                end
            end
        end
    else
        for plr, originalSize in pairs(Settings.OriginalHitboxSizes) do
            if plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    pcall(function()
                        root.Size = originalSize
                        root.Transparency = 0
                        root.CanCollide = true
                        root.Material = Enum.Material.Plastic
                    end)
                end
            end
        end
        Settings.OriginalHitboxSizes = {}
    end
    
    -- ============ ESP ============
    local crosshairScreenPos = Vector2.new(Settings.CrosshairX, Settings.CrosshairY)
    
    for plr, esp in pairs(EspCache) do
        if Settings.ESP_Enabled and IsAlive(plr) and IsTeamSelected(plr) then
            local char = plr.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChild("Humanoid")
            
            if root and head and hum then
                local rootScreenPos = Camera:WorldToViewportPoint(root.Position)
                local onScreen = rootScreenPos.Z > 0
                
                if onScreen then
                    local rootPos = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local height = (rootPos.Y - legPos.Y) * -2.2
                    local width = height / 1.8
                    
                    if Settings.ESP_Box then
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                        esp.Box.Visible = true
                        
                        if Settings.ESP_Health then
                            local hpPercent = hum.Health / hum.MaxHealth
                            esp.HealthBar.From = Vector2.new(rootPos.X - width/2 - 5, rootPos.Y + height/2)
                            esp.HealthBar.To = Vector2.new(rootPos.X - width/2 - 5, (rootPos.Y + height/2) - (height * hpPercent))
                            esp.HealthBar.Color = Color3.fromHSV(hpPercent * 0.3, 1, 1)
                            esp.HealthBar.Visible = true
                        else
                            esp.HealthBar.Visible = false
                        end
                    else
                        esp.Box.Visible = false
                        esp.HealthBar.Visible = false
                    end
                    
                    if Settings.ESP_Names then
                        esp.Name.Text = plr.Name
                        esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - 40)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Settings.ESP_Lines then
                        esp.Snapline.From = crosshairScreenPos
                        esp.Snapline.To = rootPos
                        esp.Snapline.Visible = true
                    else
                        esp.Snapline.Visible = false
                    end
                    
                    DrawSkeleton(char, esp)
                    
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Snapline.Visible = false
                    esp.HealthBar.Visible = false
                    for _, line in pairs(esp.SkeletonLines) do
                        line.Visible = false
                    end
                end
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Snapline.Visible = false
            esp.HealthBar.Visible = false
            for _, line in pairs(esp.SkeletonLines) do
                line.Visible = false
            end
        end
    end
end)

table.insert(Settings.Connections, renderConnection)

-- ==============================================================================
-- GERENCIAR PLAYERS
-- ==============================================================================

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        AddESP(p)
    end
end

-- ==============================================================================
-- INTERFACE
-- ==============================================================================

local Janela = Library:CriarJanela("1NXITER AIM & ESP")

local TabCombat = Janela:CriarAba("⚔")
local TabVisual = Janela:CriarAba("👁")
local TabOptimization = Janela:CriarAba("🚀")
local TabTeams = Janela:CriarAba("🛡")
local TabProf = Janela:CriarAba("👤")

-- [COMBAT TAB]
TabCombat:CriarToggle("Ativar Aimbot", false, function(v) Settings.Aimbot = v end)
TabCombat:CriarDropdown("Parte do Corpo", {"Head", "HumanoidRootPart"}, function(v) Settings.AimPart = v end)
TabCombat:CriarSlider("Suavidade", 0.1, 1.0, 0.5, function(v) Settings.Smoothness = v end)
TabCombat:CriarSlider("Tamanho FOV", 50, 500, 150, function(v) Settings.FOVSize = v end)
TabCombat:CriarToggle("Desenhar FOV", true, function(v) Settings.ShowFOV = v end)
TabCombat:CriarToggle("Wallcheck", true, function(v) Settings.WallCheck = v end)

TabCombat:CriarSlider("Posição X do Crosshair", 0, 1920, 960, function(v) 
    Settings.CrosshairX = v
end)
TabCombat:CriarSlider("Posição Y do Crosshair", 0, 1080, 540, function(v) 
    Settings.CrosshairY = v
end)

TabCombat:CriarToggle("Expandir Hitbox", false, function(v) Settings.HitboxExpand = v end)
TabCombat:CriarSlider("Tamanho Hitbox", 2, 10, 5, function(v) Settings.Hitbox

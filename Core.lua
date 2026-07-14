--[[
    Proton Core - Sistema de Cheats
    GitHub: DavizeraXxx/Proton-Cheats
    Versão: 4.3
]]

local ProtonCore = {
    Options = {
        Aimbot = false,
        AimbotFOV = 100,
        ShowFOV = true,
        ESPEnabled = true,
        ESPBox = true,
        ESPSkeleton = false,
        ESPName = true,
        ESPDistance = true,
        Noclip = false,
        ESPGun = false,
    },
    FOVCircle = nil,
    ESPLines = {},
    ESPTexts = {},
    Connections = {},
    Initialized = false,
    UI = nil,
    AimbotHooked = false,
    SilentAIMEnabled = false,
    Roles = {
        Murderer = nil,
        Sheriff = nil
    }
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ======================
-- UTILITÁRIOS
-- ======================
function ProtonCore:Notify(text)
    if self.UI and self.UI.Notify then
        self.UI:Notify(text)
    else
        print("[ProtonCore]", text)
    end
end

function ProtonCore:GetTeam(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    
    if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255, 50, 50)
    elseif (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(50, 100, 255)
    else
        return "Innocent", Color3.fromRGB(50, 255, 50)
    end
end

-- ======================
-- ESP (MANTIDO)
-- ======================
function ProtonCore:GetCorners(part)
    local cf, sz = part.CFrame, part.Size / 2
    local c = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                c[#c + 1] = (cf * CFrame.new(sz * Vector3.new(x, y, z))).Position
            end
        end
    end
    return c
end

function ProtonCore:DrawLine(from, to, color)
    local fs, fv = Camera:WorldToViewportPoint(from)
    local ts, tv = Camera:WorldToViewportPoint(to)
    if not fv and not tv then return end
    
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.From = Vector2.new(fs.X, fs.Y)
    line.To = Vector2.new(ts.X, ts.Y)
    line.Color = color
    line.Transparency = 1
    line.Visible = true
    table.insert(self.ESPLines, line)
end

function ProtonCore:DrawText(pos, text, color, size)
    local sp, ov = Camera:WorldToViewportPoint(pos)
    if not ov then return end
    
    local txt = Drawing.new("Text")
    txt.Position = Vector2.new(sp.X, sp.Y)
    txt.Text = text
    txt.Color = color
    txt.Size = size or 14
    txt.Center = true
    txt.Outline = true
    txt.Visible = true
    table.insert(self.ESPTexts, txt)
end

function ProtonCore:DrawBox(player, color)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local corners = self:GetCorners({CFrame = hrp.CFrame * CFrame.new(0, -0.5, 0), Size = Vector3.new(3, 5, 3)})
    local edges = {{1,2},{2,6},{6,5},{5,1},{1,3},{2,4},{6,8},{5,7},{3,4},{4,8},{8,7},{7,3}}
    
    for _, e in pairs(edges) do
        self:DrawLine(corners[e[1]], corners[e[2]], color)
    end
end

function ProtonCore:DrawSkeleton(player, color)
    local char = player.Character
    if not char then return end
    
    local bones = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    }
    
    for _, b in pairs(bones) do
        local p1 = char:FindFirstChild(b[1])
        local p2 = char:FindFirstChild(b[2])
        if p1 and p2 then
            self:DrawLine(p1.Position, p2.Position, color)
        end
    end
end

function ProtonCore:UpdateESP()
    -- Clear
    for _, l in pairs(self.ESPLines) do if l then l:Remove() end end
    for _, t in pairs(self.ESPTexts) do if t then t:Remove() end end
    self.ESPLines = {}
    self.ESPTexts = {}
    
    if not self.Options.ESPEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            if not hrp or not head then continue end
            
            local teamName, teamColor = self:GetTeam(player)
            local dist = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
            
            if self.Options.ESPBox then
                self:DrawBox(player, teamColor)
            end
            
            if self.Options.ESPSkeleton then
                self:DrawSkeleton(player, teamColor)
            end
            
            if self.Options.ESPName then
                self:DrawText(head.Position + Vector3.new(0, 1.5, 0), player.Name, Color3.new(1,1,1), 16)
            end
            
            if self.Options.ESPDistance then
                self:DrawText(head.Position + Vector3.new(0, 1.1, 0), "[" .. dist .. "m]", Color3.new(1,1,1), 14)
            end
        end
    end
end

-- ======================
-- SILENT AIM (DO SCRIPT QUE VOCÊ ENVIOU)
-- ======================
function ProtonCore:GetClosestPlayer()
    local ClosestPlayer = nil
    local FarthestDistance = self.Options.AimbotFOV or 100

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            pcall(function()
                if v.Character and v.Character:FindFirstChild("PrimaryPart") then
                    local DistanceFromPlayer = (LocalPlayer.Character.PrimaryPart.Position - v.Character.PrimaryPart.Position).Magnitude
                    if DistanceFromPlayer < FarthestDistance then
                        FarthestDistance = DistanceFromPlayer
                        ClosestPlayer = v
                    end
                end
            end)
        end
    end

    return ClosestPlayer
end

function ProtonCore:SetupSilentAim()
    if self.AimbotHooked then return end
    
    -- Raycast Parameters
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.IgnoreWater = true
    RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local RawMetatable = getrawmetatable(game)
    local OldNameCall = RawMetatable.__namecall
    setreadonly(RawMetatable, false)
    
    local selfRef = self
    
    RawMetatable.__namecall = newcclosure(function(Object, ...)
        local NamecallMethod = getnamecallmethod()
        local Arguments = {...}
        
        -- Verificar se o Silent Aim está ativo
        if selfRef.Options.Aimbot then
            RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}
            
            -- Para arremessos (Throw)
            if NamecallMethod == "FireServer" and tostring(Object) == "Throw" then
                local Success, Error = pcall(function()
                    local Closest = selfRef:GetClosestPlayer()
                    if Closest and Closest.Character and Closest.Character:FindFirstChild("PrimaryPart") then
                        local PrimaryPart = Closest.Character.PrimaryPart
                        local Velocity = PrimaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
                        local Magnitude = (PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
                        local Prediction = Velocity * 0.5 * Magnitude / 100
                        local Result = workspace.Raycast(workspace, LocalPlayer.Character.PrimaryPart.Position, (PrimaryPart.Position - (LocalPlayer.Character.PrimaryPart.Position + Prediction)).Unit * 200, RaycastParameters)
                        if Result then
                            Arguments[2] = Result.Position
                        end
                    end
                end)
                if not Success then
                    warn(Error)
                end
                
            -- Para tiros (ShootGun)
            elseif NamecallMethod == "InvokeServer" and tostring(Object) == "ShootGun" then
                -- Encontrar o Murderer
                local Murderer = nil
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local team, _ = selfRef:GetTeam(player)
                        if team == "Murderer" then
                            Murderer = player
                            break
                        end
                    end
                end
                
                if Murderer and Murderer.Character and Murderer.Character:FindFirstChild("PrimaryPart") then
                    local Success, Error = pcall(function()
                        local PrimaryPart = Murderer.Character.PrimaryPart
                        local Prediction = PrimaryPart.AssemblyLinearVelocity / 40
                        if math.abs(PrimaryPart.AssemblyLinearVelocity.Y) < 10 then
                            Arguments[2] = PrimaryPart.Position + Prediction
                        else
                            return "Nullify Remote"
                        end
                    end)
                    if not Success then
                        warn(Error)
                    elseif Success == "Nullify Remote" then
                        return
                    end
                end
            end
        end
        
        return OldNameCall(Object, unpack(Arguments))
    end)
    
    setreadonly(RawMetatable, true)
    self.AimbotHooked = true
    self:Notify("Silent Aim ativado! 🎯")
end

-- ======================
-- FOV CIRCLE
-- ======================
function ProtonCore:UpdateFOV()
    if self.Options.Aimbot and self.Options.ShowFOV then
        if not self.FOVCircle then
            local c = Drawing.new("Circle")
            c.Color = Color3.fromRGB(30, 58, 95)
            c.Thickness = 1.5
            c.Transparency = 0.7
            c.Filled = false
            c.Radius = self.Options.AimbotFOV
            c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            c.Visible = true
            self.FOVCircle = c
        else
            self.FOVCircle.Radius = self.Options.AimbotFOV
            self.FOVCircle.Visible = true
        end
    else
        if self.FOVCircle then
            self.FOVCircle.Visible = false
        end
    end
end

-- ======================
-- TELEPORT
-- ======================
function ProtonCore:TeleportToGun()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name:lower():find("gun") and obj:FindFirstChild("Handle") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = obj.Handle.CFrame + Vector3.new(0, 3, 0)
                self:Notify("Arma encontrada!")
                return
            end
        end
    end
    self:Notify("Arma não encontrada!")
end

function ProtonCore:TeleportToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
        self:Notify("Teleportado para " .. player.Name)
    end
end

-- ======================
-- LOGS
-- ======================
function ProtonCore:CopyLogs()
    local s, m = "Nenhum", "Nenhum"
    for _, p in pairs(Players:GetPlayers()) do
        local t, _ = self:GetTeam(p)
        if t == "Sheriff" then s = p.Name
        elseif t == "Murderer" then m = p.Name end
    end
    
    local log = "Sheriff: " .. s .. " | Murderer: " .. m
    pcall(setclipboard, log)
    pcall(function() syn.write_clipboard(log) end)
    self:Notify("Log copiado: " .. log)
end

-- ======================
-- GUN ESP
-- ======================
function ProtonCore:UpdateGunESP()
    if self.Options.ESPGun then
        if not self.Connections.GunESP then
            self.Connections.GunESP = RunService.Heartbeat:Connect(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Tool") and obj.Name:lower():find("gun") and not obj:FindFirstChild("ProtonGunESP") then
                        local h = Instance.new("Highlight", obj)
                        h.Name = "ProtonGunESP"
                        h.FillColor = Color3.fromRGB(255, 255, 0)
                        h.FillTransparency = 0.3
                        h.Adornee = obj
                    end
                end
            end)
        end
    else
        if self.Connections.GunESP then
            self.Connections.GunESP:Disconnect()
            self.Connections.GunESP = nil
        end
        for _, obj in pairs(workspace:GetChildren()) do
            local h = obj:FindFirstChild("ProtonGunESP")
            if h then h:Destroy() end
        end
    end
end

-- ======================
-- NOCLIP
-- ======================
function ProtonCore:UpdateNoclip()
    if self.Options.Noclip then
        if not self.Connections.Noclip then
            self.Connections.Noclip = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if self.Connections.Noclip then
            self.Connections.Noclip:Disconnect()
            self.Connections.Noclip = nil
        end
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ======================
-- CONECTAR COM UI
-- ======================
function ProtonCore:ConnectUI(ui)
    self.UI = ui
    ui.Callbacks = self
    
    function self:OnToggle(name, value)
        self.Options[name] = value
        
        if name == "Aimbot" or name == "ShowFOV" then
            self:UpdateFOV()
            if name == "Aimbot" then
                self:Notify(value and "Aimbot ativado 🎯" or "Aimbot desativado")
            end
        elseif name == "ESPEnabled" or name == "ESPBox" or name == "ESPSkeleton" or name == "ESPName" or name == "ESPDistance" then
            -- ESP é atualizado no loop
        elseif name == "Noclip" then
            self:UpdateNoclip()
        elseif name == "ESPGun" then
            self:UpdateGunESP()
        end
    end
    
    function self:OnSlider(name, value)
        if name == "AimbotFOV" then
            self.Options.AimbotFOV = value
            self:UpdateFOV()
        end
    end
    
    function self:OnButton(name, data)
        if name == "TeleportToGun" then
            self:TeleportToGun()
        elseif name == "TeleportToPlayer" then
            self:TeleportToPlayer(data)
        elseif name == "CopyLogs" then
            self:CopyLogs()
        end
    end
    
    function self:OnClose()
        self:Cleanup()
    end
    
    self:Notify("Core conectado!")
end

-- ======================
-- INICIAR
-- ======================
function ProtonCore:Start()
    if self.Initialized then return end
    
    self:SetupSilentAim()
    self:UpdateFOV()
    self:UpdateNoclip()
    self:UpdateGunESP()
    
    -- Loop de ESP
    self.Connections.ESPRender = RunService.RenderStepped:Connect(function()
        self:UpdateESP()
    end)
    
    -- Loop do FOV
    self.Connections.FOVUpdate = RunService.RenderStepped:Connect(function()
        if self.FOVCircle then
            self.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
    end)
    
    self.Initialized = true
    self:Notify("Core iniciado!")
end

-- ======================
-- LIMPAR
-- ======================
function ProtonCore:Cleanup()
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
    
    if self.FOVCircle then
        self.FOVCircle:Remove()
        self.FOVCircle = nil
    end
    
    for _, l in pairs(self.ESPLines) do if l then l:Remove() end end
    for _, t in pairs(self.ESPTexts) do if t then t:Remove() end end
    self.ESPLines = {}
    self.ESPTexts = {}
    
    for _, obj in pairs(workspace:GetChildren()) do
        local h = obj:FindFirstChild("ProtonGunESP")
        if h then h:Destroy() end
    end
    
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    self.Initialized = false
    self:Notify("Core limpo!")
end

return ProtonCore
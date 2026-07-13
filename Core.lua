--[[
    Proton Core - Sistema de Cheats
    GitHub: DavizeraXxx/Proton-Cheats
]]

local ProtonCore = {
    Options = {
        Noclip = false,
        ESPSheriff = false,
        ESPMurder = false,
        Aimbot = false,
        AimbotFOV = 100,
        ESPGun = false,
        TargetPlayer = nil
    },
    Connections = {},
    FOVCircle = nil,
    FOVConnection = nil,
    Initialized = false,
    UI = nil
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ======================
-- NOTIFICAÇÕES
-- ======================
function ProtonCore:Notify(text)
    if self.UI then
        self.UI:Notify(text)
    else
        print("[Proton]", text)
    end
end

-- ======================
-- NOCLIP
-- ======================
function ProtonCore:ToggleNoclip()
    self.Options.Noclip = not self.Options.Noclip
    
    if self.Options.Noclip then
        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        self.Connections.Noclip = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        self:Notify("✅ Noclip ativado")
    else
        if self.Connections.Noclip then
            self.Connections.Noclip:Disconnect()
            self.Connections.Noclip = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        self:Notify("❌ Noclip desativado")
    end
    return self.Options.Noclip
end

-- ======================
-- ESP
-- ======================
function ProtonCore:ToggleESP(type)
    if type == "Sheriff" then
        self.Options.ESPSheriff = not self.Options.ESPSheriff
    elseif type == "Murder" then
        self.Options.ESPMurder = not self.Options.ESPMurder
    elseif type == "Gun" then
        self.Options.ESPGun = not self.Options.ESPGun
        self:UpdateGunESP()
        return self.Options.ESPGun
    end
    
    self:UpdateESP()
    return self.Options[type == "Sheriff" and "ESPSheriff" or "ESPMurder"]
end

function ProtonCore:UpdateESP()
    -- Limpar ESP antigo
    for _, player in ipairs(Players:GetPlayers()) do
        local folder = player:FindFirstChild("ProtonESP")
        if folder then folder:Destroy() end
    end
    
    if not self.Options.ESPSheriff and not self.Options.ESPMurder then
        self:Notify("❌ ESP desativado")
        return
    end
    
    -- Aplicar para todos
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = player.Team
            if team then
                local color = nil
                if team.Name == "Sheriff" and self.Options.ESPSheriff then
                    color = Color3.fromRGB(0, 150, 255)
                elseif team.Name == "Murderer" and self.Options.ESPMurder then
                    color = Color3.fromRGB(255, 0, 0)
                end
                
                if color then
                    local char = player.Character
                    if char then
                        local folder = Instance.new("Folder")
                        folder.Name = "ProtonESP"
                        folder.Parent = player
                        
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = color
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.3
                        highlight.Adornee = char
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = folder
                    end
                end
            end
        end
    end
    
    self:Notify("✅ ESP atualizado")
end

function ProtonCore:UpdateGunESP()
    -- Limpar Gun ESP
    for _, tool in ipairs(workspace:GetChildren()) do
        local h = tool:FindFirstChild("ProtonGunESP")
        if h then h:Destroy() end
    end
    
    if not self.Options.ESPGun then
        if self.Connections.GunESP then
            self.Connections.GunESP:Disconnect()
            self.Connections.GunESP = nil
        end
        self:Notify("❌ Gun ESP desativado")
        return
    end
    
    self:Notify("✅ Gun ESP ativado")
    
    if self.Connections.GunESP then
        self.Connections.GunESP:Disconnect()
    end
    
    self.Connections.GunESP = RunService.Heartbeat:Connect(function()
        for _, tool in ipairs(workspace:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                local onGround = true
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and tool:IsDescendantOf(player.Character) then
                        onGround = false
                        break
                    end
                end
                
                if onGround and not tool:FindFirstChild("ProtonGunESP") then
                    local h = Instance.new("Highlight", tool)
                    h.Name = "ProtonGunESP"
                    h.FillColor = Color3.fromRGB(255, 255, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.3
                    h.Adornee = tool
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            end
        end
    end)
end

-- ======================
-- AIMBOT
-- ======================
function ProtonCore:ToggleAimbot()
    self.Options.Aimbot = not self.Options.Aimbot
    
    if self.Options.Aimbot then
        self:Notify("✅ Aimbot ativado 🎯")
        self:CreateFOV()
    else
        self:Notify("❌ Aimbot desativado")
        if self.FOVCircle then
            self.FOVCircle.Visible = false
        end
        if self.FOVConnection then
            self.FOVConnection:Disconnect()
            self.FOVConnection = nil
        end
    end
    return self.Options.Aimbot
end

function ProtonCore:CreateFOV()
    if not self.FOVCircle then
        local success, circle = pcall(function()
            return Drawing.new("Circle")
        end)
        if success and circle then
            circle.Color = Color3.fromRGB(30, 58, 95)
            circle.Thickness = 1.5
            circle.Transparency = 0.7
            circle.Filled = false
            circle.Radius = self.Options.AimbotFOV
            circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            circle.Visible = true
            self.FOVCircle = circle
        end
    end
    
    if self.FOVCircle then
        self.FOVCircle.Visible = true
        self.FOVCircle.Radius = self.Options.AimbotFOV
    end
    
    if not self.FOVConnection then
        self.FOVConnection = RunService.RenderStepped:Connect(function()
            if self.FOVCircle then
                self.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                self.FOVCircle.Radius = self.Options.AimbotFOV
            end
        end)
    end
end

function ProtonCore:SetFOV(value)
    self.Options.AimbotFOV = math.clamp(value, 10, 360)
    if self.FOVCircle then
        self.FOVCircle.Radius = self.Options.AimbotFOV
    end
    return self.Options.AimbotFOV
end

-- ======================
-- TELEPORT
-- ======================
function ProtonCore:TeleportGun()
    self:Notify("🔍 Procurando Sheriff...")
    
    local sheriff = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "Sheriff" then
            sheriff = player
            break
        end
    end
    
    if not sheriff then
        self:Notify("❌ Sheriff não encontrado")
        return
    end
    
    local char = sheriff.Character
    if not char then
        self:Notify("❌ Sheriff sem personagem")
        return
    end
    
    local gun = char:FindFirstChildOfClass("Tool")
    if not gun and sheriff.Backpack then
        gun = sheriff.Backpack:FindFirstChildOfClass("Tool")
    end
    
    if not gun then
        self:Notify("❌ Arma não encontrada")
        return
    end
    
    local myChar = LocalPlayer.Character
    if not myChar then
        self:Notify("❌ Você sem personagem")
        return
    end
    
    gun.Parent = workspace
    if gun:FindFirstChild("Handle") then
        gun.Handle.CFrame = myChar.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    end
    
    self:Notify("🚀 Arma teleportada!")
end

-- ======================
-- LOGS
-- ======================
function ProtonCore:CopyLog()
    local sheriff = "Nenhum"
    local murder = "Nenhum"
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team then
            if player.Team.Name == "Sheriff" then
                sheriff = player.Name
            elseif player.Team.Name == "Murderer" then
                murder = player.Name
            end
        end
    end
    
    local log = "Sheriff: " .. sheriff .. " | Murderer: " .. murder
    pcall(setclipboard, log)
    self:Notify("📋 Log copiado!")
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
    if self.FOVConnection then
        self.FOVConnection:Disconnect()
        self.FOVConnection = nil
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        local folder = player:FindFirstChild("ProtonESP")
        if folder then folder:Destroy() end
    end
    
    for _, tool in ipairs(workspace:GetChildren()) do
        local h = tool:FindFirstChild("ProtonGunESP")
        if h then h:Destroy() end
    end
    
    self:Notify("🧹 Core limpo!")
end

return ProtonCore
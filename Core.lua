--[[
    Proton Core - Sistema de Cheats para Murder Mystery 2
    GitHub: DavizeraXxx/Proton-Cheats
    Versão: 3.1
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
    AimbotHooked = false,
    AimbotRemote = nil,
    AimbotOldFire = nil,
    FOVCircle = nil,
    FOVConnection = nil,
    Initialized = false
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ======================
-- NOTIFICAÇÕES (Múltiplos métodos)
-- ======================
function ProtonCore:Notify(text, duration)
    duration = duration or 3
    
    -- Método 1: Usar a UI se disponível
    if self.UI and self.UI.Notify then
        self.UI:Notify(text, duration)
        return
    end
    
    -- Método 2: Usar StarterGui (funciona na maioria dos executors)
    local success, err = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Proton",
            Text = text,
            Duration = duration
        })
    end)
    
    -- Método 3: Usar CoreGui (fallback)
    if not success then
        pcall(function()
            local gui = Instance.new("ScreenGui")
            gui.Parent = game:GetService("CoreGui")
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 300, 0, 40)
            frame.Position = UDim2.new(0.5, -150, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0
            frame.Parent = gui
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -10, 1, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 14
            label.Text = text
            label.Parent = frame
            
            task.delay(duration, function()
                gui:Destroy()
            end)
        end)
    end
    
    -- Sempre imprimir no console também
    print("[Proton]", text)
end

-- ======================
-- NOCLIP
-- ======================
function ProtonCore:UpdateNoclip()
    self:Notify("Noclip: " .. (self.Options.Noclip and "ativado ✅" or "desativado ❌"))
    
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
    end
end

-- ======================
-- ESP
-- ======================
function ProtonCore:UpdateESP()
    self:Notify("Atualizando ESP...")
    
    -- Limpar ESP antigo
    for _, player in ipairs(Players:GetPlayers()) do
        local folder = player:FindFirstChild("ProtonESP")
        if folder then folder:Destroy() end
    end
    
    if not self.Options.ESPSheriff and not self.Options.ESPMurder then
        self:Notify("ESP desativado")
        return
    end
    
    -- Aplicar para todos os jogadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:ApplyESP(player)
        end
    end
    
    -- Conectar eventos de entrada/saída
    if self.Connections.PlayerAdded then self.Connections.PlayerAdded:Disconnect() end
    if self.Connections.PlayerRemoving then self.Connections.PlayerRemoving:Disconnect() end
    
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(0.5)
        self:ApplyESP(player)
    end)
    
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        local folder = player:FindFirstChild("ProtonESP")
        if folder then folder:Destroy() end
    end)
    
    self:Notify("ESP ativado ✅")
end

function ProtonCore:ApplyESP(player)
    if player == LocalPlayer then return end
    
    local team = player.Team
    if not team then return end
    
    local color = nil
    if team.Name == "Sheriff" and self.Options.ESPSheriff then
        color = Color3.fromRGB(0, 150, 255)
    elseif team.Name == "Murderer" and self.Options.ESPMurder then
        color = Color3.fromRGB(255, 0, 0)
    end
    
    if not color then return end
    
    local char = player.Character
    if not char then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:ApplyESP(player)
        end)
        return
    end
    
    -- Remover ESP antigo
    local folder = player:FindFirstChild("ProtonESP")
    if folder then folder:Destroy() end
    
    folder = Instance.new("Folder")
    folder.Name = "ProtonESP"
    folder.Parent = player
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = folder
end

-- ======================
-- GUN ESP
-- ======================
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
        self:Notify("Gun ESP desativado")
        return
    end
    
    self:Notify("Gun ESP ativado ✅")
    
    if self.Connections.GunESP then
        self.Connections.GunESP:Disconnect()
    end
    
    self.Connections.GunESP = RunService.Heartbeat:Connect(function()
        for _, tool in ipairs(workspace:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                -- Verificar se está no chão
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
-- AIMBOT (SIMPLIFICADO)
-- ======================
function ProtonCore:UpdateAimbotVisual()
    if self.Options.Aimbot then
        self:Notify("Aimbot ativado 🎯")
        
        -- Criar círculo FOV
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
    else
        if self.FOVCircle then
            self.FOVCircle.Visible = false
        end
        if self.FOVConnection then
            self.FOVConnection:Disconnect()
            self.FOVConnection = nil
        end
        self:Notify("Aimbot desativado")
    end
end

function ProtonCore:StartAimbot()
    self:Notify("Procurando RemoteEvent...")
    
    local remote = nil
    local possibleNames = {"Shoot", "Fire", "Gun", "RemoteShoot"}
    
    for _, name in ipairs(possibleNames) do
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and string.lower(obj.Name):find(string.lower(name)) then
                remote = obj
                break
            end
        end
        if remote then break end
    end
    
    if not remote then
        self:Notify("RemoteEvent não encontrado! ❌")
        return
    end
    
    self:Notify("Remote encontrado: " .. remote.Name .. " ✅")
end

-- ======================
-- TELEPORT
-- ======================
function ProtonCore:TeleportSheriffGun()
    self:Notify("Teleportando arma...")
    
    local sheriff = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "Sheriff" then
            sheriff = player
            break
        end
    end
    
    if not sheriff then
        self:Notify("Sheriff não encontrado ❌")
        return
    end
    
    local char = sheriff.Character
    if not char then
        self:Notify("Sheriff sem personagem ❌")
        return
    end
    
    local gun = char:FindFirstChildOfClass("Tool")
    if not gun and sheriff.Backpack then
        gun = sheriff.Backpack:FindFirstChildOfClass("Tool")
    end
    
    if not gun then
        self:Notify("Arma não encontrada ❌")
        return
    end
    
    local myChar = LocalPlayer.Character
    if not myChar then
        self:Notify("Você sem personagem ❌")
        return
    end
    
    gun.Parent = workspace
    if gun:FindFirstChild("Handle") then
        gun.Handle.CFrame = myChar.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    end
    
    self:Notify("Arma teleportada! 🚀")
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
    
    local success = pcall(setclipboard, log)
    if not success then
        success = pcall(function() syn.write_clipboard(log) end)
    end
    
    if success then
        self:Notify("Log copiado! 📋")
    else
        self:Notify("Erro ao copiar log ❌")
    end
end

-- ======================
-- CONECTAR COM UI
-- ======================
function ProtonCore:ConnectUI(ui)
    self.UI = ui
    self:Notify("Conectando ao menu...")
    
    ui.OnToggleChange = function(name, state)
        self.Options[name] = state
        
        if name == "Noclip" then
            self:UpdateNoclip()
        elseif name == "ESPSheriff" or name == "ESPMurder" then
            self:UpdateESP()
        elseif name == "Aimbot" then
            self:UpdateAimbotVisual()
        elseif name == "ESPGun" then
            self:UpdateGunESP()
        end
    end
    
    ui.OnSliderChange = function(name, value)
        if name == "AimbotFOV" then
            self.Options.AimbotFOV = value
            if self.FOVCircle then
                self.FOVCircle.Radius = value
            end
        end
    end
    
    ui.OnButtonClick = function(name)
        if name == "TeleportSheriffGun" then
            self:TeleportSheriffGun()
        elseif name == "CopyLog" then
            self:CopyLog()
        end
    end
    
    ui.OnPlayerSelect = function(player)
        self.Options.TargetPlayer = player
        self:Notify("Alvo: " .. player.Name)
    end
    
    self:Notify("Core conectado! ✅")
end

-- ======================
-- INICIAR
-- ======================
function ProtonCore:Start()
    self:Notify("Iniciando Proton Core...")
    self:StartAimbot()
    self.Initialized = true
    self:Notify("Core pronto! 🚀")
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
    
    self:Notify("Core limpo! 🧹")
end

return ProtonCore
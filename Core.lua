--[[
    Proton Core - Sistema de Cheats para Murder Mystery 2
    GitHub: DavizeraXxx/Proton-Cheats
    Versão: 3.0
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
    Initialized = false,
    ESPActive = false,
    GunESPActive = false
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
function ProtonCore:Notify(text, duration)
    if self.UI and self.UI.Notify then
        self.UI:Notify(text, duration)
    else
        print("[ProtonCore]", text)
    end
end

-- ======================
-- NOCLIP
-- ======================
function ProtonCore:UpdateNoclip()
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
        self:Notify("Noclip ativado", 2)
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
        self:Notify("Noclip desativado", 2)
    end
end

-- ======================
-- ESP
-- ======================
function ProtonCore:UpdateESP()
    -- Limpar ESP antigo
    for _, player in ipairs(Players:GetPlayers()) do
        self:RemoveESP(player)
    end
    
    if not self.Options.ESPSheriff and not self.Options.ESPMurder then
        self.ESPActive = false
        return
    end
    
    self.ESPActive = true
    
    -- Conectar eventos de jogadores
    if self.Connections.PlayerAdded then self.Connections.PlayerAdded:Disconnect() end
    if self.Connections.PlayerRemoving then self.Connections.PlayerRemoving:Disconnect() end
    
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        self:ApplyESP(player)
    end)
    
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemoveESP(player)
    end)
    
    -- Aplicar ESP para todos os jogadores
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            task.wait(0.1)
            self:ApplyESP(player)
        end
    end
    
    self:Notify("ESP atualizado", 2)
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
    
    -- Aguardar personagem
    local char = player.Character
    if not char then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            self:ApplyESP(player)
        end)
        return
    end
    
    -- Remover ESP antigo
    self:RemoveESP(player)
    
    -- Criar Highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Armazenar
    local folder = player:FindFirstChild("ProtonESP")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ProtonESP"
        folder.Parent = player
    end
    highlight.Parent = folder
end

function ProtonCore:RemoveESP(player)
    local folder = player:FindFirstChild("ProtonESP")
    if folder then
        folder:Destroy()
    end
end

-- ======================
-- GUN ESP
-- ======================
function ProtonCore:UpdateGunESP()
    -- Limpar Gun ESP antigo
    for _, tool in ipairs(workspace:GetChildren()) do
        local h = tool:FindFirstChild("ProtonGunESP")
        if h then h:Destroy() end
    end
    
    if not self.Options.ESPGun then
        self.GunESPActive = false
        if self.Connections.GunESP then
            self.Connections.GunESP:Disconnect()
            self.Connections.GunESP = nil
        end
        self:Notify("Gun ESP desativado", 2)
        return
    end
    
    self.GunESPActive = true
    
    if self.Connections.GunESP then
        self.Connections.GunESP:Disconnect()
    end
    
    self.Connections.GunESP = RunService.Heartbeat:Connect(function()
        for _, tool in ipairs(workspace:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                -- Verificar se está no chão (não em um jogador)
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
    
    self:Notify("Gun ESP ativado", 2)
end

-- ======================
-- AIMBOT
-- ======================
function ProtonCore:StartAimbot()
    if self.AimbotHooked then return end
    
    self:Notify("Procurando RemoteEvent...", 3)
    
    -- Procurar o RemoteEvent de tiro
    local remote = nil
    local possibleNames = {
        "ShootEvent", "GunEvent", "Fire", "RemoteShoot", 
        "FireGun", "Shoot", "FireRemote", "GunFire"
    }
    
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
        self:Notify("RemoteEvent não encontrado!", 4)
        return
    end
    
    self:Notify("Remote encontrado: " .. remote.Name, 3)
    self.AimbotRemote = remote
    self.AimbotOldFire = remote.FireServer
    
    -- Hook
    local selfRef = self
    remote.FireServer = function(remoteSelf, ...)
        local args = {...}
        
        if selfRef.Options.Aimbot then
            local target = selfRef.Options.TargetPlayer
            
            -- Auto-target se não tiver alvo específico
            if not target then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Head") then
                    local best = nil
                    local bestDist = math.huge
                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local pChar = player.Character
                            if pChar and pChar:FindFirstChild("Head") then
                                local pos, onScreen = Camera:WorldToScreenPoint(pChar.Head.Position)
                                if onScreen then
                                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                    if dist <= selfRef.Options.AimbotFOV and dist < bestDist then
                                        bestDist = dist
                                        best = player
                                    end
                                end
                            end
                        end
                    end
                    target = best
                end
            end
            
            -- Modificar tiro para acertar a cabeça
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local headPos = target.Character.Head.Position
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = headPos
                        break
                    end
                end
            end
        end
        
        return selfRef.AimbotOldFire(remoteSelf, unpack(args))
    end
    
    self.AimbotHooked = true
    self:Notify("Aimbot pronto! 🎯", 3)
end

-- ======================
-- FOV CIRCLE
-- ======================
function ProtonCore:UpdateAimbotVisual()
    if self.Options.Aimbot then
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
            else
                self:Notify("Drawing não disponível", 3)
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
    end
end

-- ======================
-- TELEPORT
-- ======================
function ProtonCore:TeleportSheriffGun()
    -- Encontrar Sheriff
    local sheriff = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "Sheriff" then
            sheriff = player
            break
        end
    end
    
    if not sheriff then
        self:Notify("Sheriff não encontrado", 2)
        return
    end
    
    local char = sheriff.Character
    if not char then
        self:Notify("Sheriff sem personagem", 2)
        return
    end
    
    -- Procurar arma
    local gun = char:FindFirstChildOfClass("Tool")
    if not gun and sheriff.Backpack then
        gun = sheriff.Backpack:FindFirstChildOfClass("Tool")
    end
    
    if not gun or not gun:FindFirstChild("Handle") then
        self:Notify("Arma não encontrada", 2)
        return
    end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
        self:Notify("Personagem não pronto", 2)
        return
    end
    
    -- Teleportar
    local pos = myChar.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    gun.Handle.CFrame = pos
    gun.Parent = workspace
    
    self:Notify("Arma teleportada! 🚀", 2)
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
    
    -- Copiar para clipboard
    local success = pcall(setclipboard, log)
    if not success then
        success = pcall(function() syn.write_clipboard(log) end)
    end
    if not success then
        pcall(function() writefile("mm2_log.txt", log) end)
        self:Notify("Log salvo em mm2_log.txt", 3)
    else
        self:Notify("Log copiado! 📋", 2)
    end
end

-- ======================
-- CONECTAR COM UI
-- ======================
function ProtonCore:ConnectUI(ui)
    self.UI = ui
    
    ui.OnToggleChange = function(name, state)
        print("[Core] Toggle:", name, state)
        self.Options[name] = state
        
        if name == "Noclip" then
            self:UpdateNoclip()
        elseif name == "ESPSheriff" or name == "ESPMurder" then
            self:UpdateESP()
        elseif name == "Aimbot" then
            self:UpdateAimbotVisual()
            if state then
                self:Notify("Aimbot ativado 🎯", 2)
            else
                self:Notify("Aimbot desativado", 2)
            end
        elseif name == "ESPGun" then
            self:UpdateGunESP()
        end
    end
    
    ui.OnSliderChange = function(name, value)
        print("[Core] Slider:", name, value)
        if name == "AimbotFOV" then
            self.Options.AimbotFOV = value
            self:UpdateAimbotVisual()
        end
    end
    
    ui.OnButtonClick = function(name)
        print("[Core] Button:", name)
        if name == "TeleportSheriffGun" then
            self:TeleportSheriffGun()
        elseif name == "CopyLog" then
            self:CopyLog()
        end
    end
    
    ui.OnPlayerSelect = function(player)
        print("[Core] Player selecionado:", player.Name)
        self.Options.TargetPlayer = player
        self:Notify("Alvo: " .. player.Name, 2)
    end
    
    self.Initialized = true
    self:Notify("Core conectado! ✅", 2)
end

-- ======================
-- INICIAR
-- ======================
function ProtonCore:Start()
    if self.Initialized then
        self:Notify("Core já iniciado", 2)
        return
    end
    
    self:Notify("Iniciando Proton Core...", 2)
    self:StartAimbot()
    self.Initialized = true
    self:Notify("Core pronto! 🚀", 2)
end

-- ======================
-- LIMPAR
-- ======================
function ProtonCore:Cleanup()
    -- Desconectar conexões
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
    
    -- Remover FOV
    if self.FOVCircle then
        self.FOVCircle:Remove()
        self.FOVCircle = nil
    end
    if self.FOVConnection then
        self.FOVConnection:Disconnect()
        self.FOVConnection = nil
    end
    
    -- Restaurar RemoteEvent
    if self.AimbotRemote and self.AimbotOldFire then
        self.AimbotRemote.FireServer = self.AimbotOldFire
        self.AimbotHooked = false
    end
    
    -- Limpar ESP
    for _, player in ipairs(Players:GetPlayers()) do
        self:RemoveESP(player)
    end
    
    -- Limpar Gun ESP
    for _, tool in ipairs(workspace:GetChildren()) do
        local h = tool:FindFirstChild("ProtonGunESP")
        if h then h:Destroy() end
    end
    
    -- Restaurar colisões
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    self.Initialized = false
    self:Notify("Core limpo! 🧹", 2)
end

return ProtonCore
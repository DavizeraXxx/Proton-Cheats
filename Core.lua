--[[
    Proton Core - Sistema de Cheats para Murder Mystery 2
    GitHub: seu-usuario/ProtonCore
    Versão: 2.1
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
    AimbotOldFireServer = nil,
    FOVCircle = nil,
    FOVUpdateConnection = nil,
    Initialized = false
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ======================
-- UTILITÁRIOS
-- ======================
function ProtonCore:Notify(text, duration)
    if self.UI and self.UI.Notify then
        self.UI:Notify(text, duration)
    else
        print("[ProtonCore]", text)
    end
end

local function copyToClipboard(text)
    local ok = pcall(setclipboard, text)
    if not ok then ok = pcall(function() syn.write_clipboard(text) end) end
    if not ok then
        pcall(function() writefile("mm2_log.txt", text) end)
        ProtonCore:Notify("Log salvo em mm2_log.txt", 3)
    else
        ProtonCore:Notify("Copiado para área de transferência!", 2)
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
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then 
                        v.CanCollide = false 
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
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.CanCollide = true 
                end
            end
        end
    end
end

-- ======================
-- ESP
-- ======================
function ProtonCore:UpdateESP()
    -- Limpar ESP antigo
    for _, plr in ipairs(Players:GetPlayers()) do
        self:RemoveHighlights(plr)
    end
    
    if not self.Options.ESPSheriff and not self.Options.ESPMurder then 
        return 
    end

    if self.Connections.ESPPlayerAdded then self.Connections.ESPPlayerAdded:Disconnect() end
    if self.Connections.ESPPlayerRemoving then self.Connections.ESPPlayerRemoving:Disconnect() end

    self.Connections.ESPPlayerAdded = Players.PlayerAdded:Connect(function(plr)
        self:ApplyESPToPlayer(plr)
        plr.CharacterAdded:Connect(function() self:ApplyESPToPlayer(plr) end)
    end)
    
    self.Connections.ESPPlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
        self:RemoveHighlights(plr)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        self:ApplyESPToPlayer(plr)
        plr.CharacterAdded:Connect(function() self:ApplyESPToPlayer(plr) end)
    end
end

function ProtonCore:ApplyESPToPlayer(player)
    if player == LocalPlayer then return end
    
    local team = player.Team
    if not team then return end
    
    local color
    if team.Name == "Sheriff" and self.Options.ESPSheriff then
        color = Color3.fromRGB(0, 100, 255)
    elseif team.Name == "Murderer" and self.Options.ESPMurder then
        color = Color3.fromRGB(255, 0, 0)
    else
        return
    end
    
    local char = player.Character
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.3
    highlight.Adornee = char
    
    local folder = player:FindFirstChild("ProtonESP") or Instance.new("Folder")
    folder.Name = "ProtonESP"
    folder.Parent = player
    highlight.Parent = folder
end

function ProtonCore:RemoveHighlights(player)
    local folder = player:FindFirstChild("ProtonESP")
    if folder then folder:Destroy() end
end

-- ======================
-- GUN ESP
-- ======================
function ProtonCore:UpdateGunESP()
    if self.Options.ESPGun then
        if self.Connections.GunESP then self.Connections.GunESP:Disconnect() end
        self.Connections.GunESP = RunService.Heartbeat:Connect(function()
            for _, tool in ipairs(workspace:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower():find("gun") and not tool:FindFirstChild("ProtonGunESP") then
                    local h = Instance.new("Highlight", tool)
                    h.Name = "ProtonGunESP"
                    h.FillColor = Color3.fromRGB(255, 255, 0)
                    h.OutlineColor = Color3.new(0, 0, 0)
                    h.FillTransparency = 0.3
                    h.Adornee = tool
                end
            end
        end)
    else
        if self.Connections.GunESP then 
            self.Connections.GunESP:Disconnect() 
            self.Connections.GunESP = nil 
        end
        for _, tool in ipairs(workspace:GetChildren()) do
            local h = tool:FindFirstChild("ProtonGunESP")
            if h then h:Destroy() end
        end
    end
end

-- ======================
-- AIMBOT
-- ======================
function ProtonCore:StartAimbotHook()
    if self.AimbotHooked then return end
    
    local remote
    local possibleNames = {"ShootEvent", "GunEvent", "Fire", "RemoteShoot", "FireGun"}
    
    for _, name in ipairs(possibleNames) do
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower():find(name:lower()) then
                remote = obj
                break
            end
        end
        if remote then break end
    end
    
    if not remote then
        self:Notify("Remote de tiro não encontrado. Tente usar a arma primeiro.", 4)
        return
    end
    
    self.AimbotRemote = remote
    local oldFire = remote.FireServer
    self.AimbotOldFireServer = oldFire

    local selfRef = self
    remote.FireServer = function(remoteSelf, ...)
        local args = {...}
        if selfRef.Options.Aimbot then
            local target = selfRef.Options.TargetPlayer
            
            if not target then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("Head") then
                    local best
                    local bestDist = math.huge
                    
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Team then
                            local char = plr.Character
                            if char and char:FindFirstChild("Head") then
                                local pos, onScreen = Camera:WorldToScreenPoint(char.Head.Position)
                                if onScreen then
                                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                                    if d <= selfRef.Options.AimbotFOV and d < bestDist then
                                        bestDist = d
                                        best = plr
                                    end
                                end
                            end
                        end
                    end
                    target = best
                end
            end
            
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
        return oldFire(remoteSelf, unpack(args))
    end
    
    self.AimbotHooked = true
    self:Notify("Aimbot pronto (use a arma para testar)", 3)
end

function ProtonCore:UpdateAimbotVisual()
    if self.Options.Aimbot then
        if not self.FOVCircle then
            local succ, circle = pcall(function() return Drawing.new("Circle") end)
            if succ and circle then
                circle.Color = Color3.fromRGB(30, 58, 95)
                circle.Thickness = 1.5
                circle.Transparency = 0.7
                circle.Filled = false
                circle.Radius = self.Options.AimbotFOV
                circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                self.FOVCircle = circle
            else
                self:Notify("Drawing não disponível", 3)
            end
        end
        if self.FOVCircle then 
            self.FOVCircle.Visible = true 
        end
        
        if not self.FOVUpdateConnection then
            self.FOVUpdateConnection = RunService.RenderStepped:Connect(function()
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
        if self.FOVUpdateConnection then 
            self.FOVUpdateConnection:Disconnect() 
            self.FOVUpdateConnection = nil 
        end
    end
end

-- ======================
-- TELEPORT
-- ======================
function ProtonCore:TeleportSheriffGun()
    local sheriff
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Team and plr.Team.Name == "Sheriff" then 
            sheriff = plr 
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
    
    local gun = char:FindFirstChildOfClass("Tool")
    if not gun or not gun:FindFirstChild("Handle") then 
        self:Notify("Arma não encontrada", 2) 
        return 
    end
    
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then 
        self:Notify("Personagem não pronto", 2) 
        return 
    end
    
    gun.Handle.CFrame = myChar.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    self:Notify("Arma teleportada!", 2)
end

-- ======================
-- LOGS
-- ======================
function ProtonCore:CopyLog()
    local sheriff = "Nenhum"
    local murder = "Nenhum"
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Team then
            if plr.Team.Name == "Sheriff" then 
                sheriff = plr.Name
            elseif plr.Team.Name == "Murderer" then 
                murder = plr.Name
            end
        end
    end
    
    copyToClipboard("Sheriff: " .. sheriff .. " | Murderer: " .. murder)
end

-- ======================
-- CONECTAR COM UI
-- ======================
function ProtonCore:ConnectUI(ui)
    self.UI = ui
    
    -- Conectar eventos da UI com as funções do Core
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
            self:UpdateAimbotVisual()
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
    end
    
    -- Sincronizar estado inicial
    for key, value in pairs(self.Options) do
        if ui.Options then
            ui.Options[key] = value
        end
    end
    
    self.Initialized = true
    self:Notify("Proton Core conectado à UI!", 2)
end

-- ======================
-- INICIAR
-- ======================
function ProtonCore:Start()
    if self.Initialized then
        self:Notify("Proton Core já iniciado!", 2)
        return
    end
    
    -- Iniciar cheats que não dependem da UI
    self:StartAimbotHook()
    
    self.Initialized = true
    print("[ProtonCore] Iniciado com sucesso!")
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
    
    if self.FOVUpdateConnection then 
        self.FOVUpdateConnection:Disconnect() 
        self.FOVUpdateConnection = nil 
    end
    
    -- Restaurar RemoteEvent
    if self.AimbotRemote and self.AimbotOldFireServer then
        self.AimbotRemote.FireServer = self.AimbotOldFireServer
    end
    
    -- Limpar ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        self:RemoveHighlights(plr)
    end
    
    -- Restaurar Collisions
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then 
                v.CanCollide = true 
            end
        end
    end
    
    self.Initialized = false
    self:Notify("Proton Core limpo!", 2)
end

return ProtonCore
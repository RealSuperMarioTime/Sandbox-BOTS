-- =========================================================================
-- CUSTOM DARK-THEMED SANDBOX SCOREBOARD WITH PERSISTENT MUTES & BOT AUDIO CONTROL
-- =========================================================================

local ScoreboardPanel = nil

-- Helper function to fetch bot avatars from data folder or materials folder
local function GetBotAvatarMaterial(ply)
    if not IsValid(ply) or not ply:IsBot() then return nil end
    
    local botName = string.lower(string.PatternSafe(ply:Nick()))
    local dataPath = "profilepictures/" .. botName .. ".png"
    
    if file.Exists(dataPath, "DATA") then
        local mat = Material("data/" .. dataPath, "smooth")
        if mat and not mat:IsError() then return mat end
    end
    
    local relativePath = "profilepictures/" .. botName .. ".png"
    local mat = Material(relativePath, "smooth")
    if mat and not mat:IsError() then
        return mat
    end
    
    return nil
end

-- Function to draw the bot avatar or fallback block
local function DrawBotAvatar(ply, x, y, w, h)
    local mat = GetBotAvatarMaterial(ply)
    
    if mat then
        surface.SetMaterial(mat)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x, y, w, h)
    else
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(x, y, w, h)
    end
end

-- Global hook to intercept and block bot audio/mp3 streams when they are muted
hook.Add("PlayerCanHearPlayersVoice", "SandboxBots_MuteControl", function(listener, talker)
    if IsValid(talker) and talker:IsBot() and talker.IsCustomMuted then
        return false
    end
end)

-- Create and show the custom scoreboard panel
local function CreateCustomScoreboard()
    if IsValid(ScoreboardPanel) then ScoreboardPanel:Remove() end

    ScoreboardPanel = vgui.Create("EditablePanel")
    ScoreboardPanel:SetSize(ScrW() * 0.6, ScrH() * 0.6)
    ScoreboardPanel:Center()
    ScoreboardPanel:MakePopup()
    ScoreboardPanel:SetKeyboardInputEnabled(false)

    -- Background Paint (Dark Theme)
    ScoreboardPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25, 240))
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    -- Header Title
    local title = vgui.Create("DLabel", ScoreboardPanel)
    title:SetText("  Sandbox Server - Players")
    title:SetFont("DermaDefaultBold")
    title:SetColor(Color(240, 240, 240))
    title:Dock(TOP)
    title:SetTall(30)
    title:DockMargin(10, 5, 10, 0)

    -- Column Labels Header Bar
    local headerBar = vgui.Create("Panel", ScoreboardPanel)
    headerBar:Dock(TOP)
    headerBar:SetTall(24)
    headerBar:DockMargin(10, 0, 10, 5)
    headerBar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 45, 255))
    end

    local function AddHeaderLabel(text, width, parent)
        local lbl = vgui.Create("DLabel", parent)
        lbl:SetText(text)
        lbl:SetFont("DermaDefaultBold")
        lbl:SetColor(Color(200, 200, 200))
        lbl:Dock(LEFT)
        lbl:SetWide(width)
        lbl:SetContentAlignment(4)
        return lbl
    end

    AddHeaderLabel("  Name", ScoreboardPanel:GetWide() * 0.35, headerBar)
    AddHeaderLabel("Ping", 60, headerBar)
    AddHeaderLabel("Deaths", 60, headerBar)
    AddHeaderLabel("Kills", 60, headerBar)
    AddHeaderLabel("Mute", 50, headerBar)

    -- Scrollable Player List Container
    local scroll = vgui.Create("DScrollPanel", ScoreboardPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 0, 10, 10)

    -- Populate rows for each player
    for _, ply in ipairs(player.GetAll()) do
        local row = scroll:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(32)
        
        row.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
            
            -- Draw bot avatar if applicable
            if IsValid(ply) and ply:IsBot() then
                DrawBotAvatar(ply, 4, 4, h - 8, h - 8)
            end
        end

        -- Player Name Label (Offset to make room for avatar)
        local nameLbl = vgui.Create("DLabel", row)
        nameLbl:SetText("     " .. ply:Nick())
        nameLbl:SetFont("DermaDefault")
        nameLbl:SetColor(Color(255, 255, 255))
        nameLbl:Dock(LEFT)
        nameLbl:SetWide(ScoreboardPanel:GetWide() * 0.35)

        local function AddStatLabel(val, width)
            local lbl = vgui.Create("DLabel", row)
            lbl:SetText(tostring(val))
            lbl:SetFont("DermaDefault")
            lbl:SetColor(Color(200, 200, 200))
            lbl:Dock(LEFT)
            lbl:SetWide(width)
            lbl:SetContentAlignment(4)
            return lbl
        end

        AddStatLabel(ply:Ping(), 60)
        AddStatLabel(ply:Deaths(), 60)
        AddStatLabel(ply:Frags(), 60)

        -- Mute / Speaker Toggle Button with Persistent State Storage
        local muteBtn = vgui.Create("DButton", row)
        muteBtn:Dock(RIGHT)
        muteBtn:SetWide(40)
        muteBtn:DockMargin(0, 4, 10, 4)
        muteBtn:SetText("")
        
        -- Initialize persistent state on player table safely
        if ply.IsCustomMuted == nil then
            if ply:IsBot() then
                ply.IsCustomMuted = false
            else
                ply.IsCustomMuted = ply:IsMuted()
            end
        end

        muteBtn.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and Color(60, 60, 60, 255) or Color(50, 50, 50, 255))
            
            local textLabel = ply.IsCustomMuted and "OFF" or "ON"
            local textColor = ply.IsCustomMuted and Color(200, 60, 60) or Color(150, 200, 150)
            draw.SimpleText(textLabel, "DermaDefault", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        muteBtn.DoClick = function()
            if not IsValid(ply) then return end
            
            ply.IsCustomMuted = not ply.IsCustomMuted
            
            if not ply:IsBot() then
                ply:SetMuted(ply.IsCustomMuted)
            else
                -- Sync the bot's mute state to the server so it blocks audio playback
                net.Start("SetBotMuteState")
                net.WriteEntity(ply)
                net.WriteBool(ply.IsCustomMuted)
                net.SendToServer()
            end
            
            -- If it's a bot playing active stream channels, handle volume adjustments too
            if ply:IsBot() and IsValid(ply.VoiceChannel) then
                if ply.IsCustomMuted then
                    ply.VoiceChannel:SetVolume(0)
                else
                    ply.VoiceChannel:SetVolume(1)
                end
            end
        end
    end
end

-- Override default scoreboard hooks
hook.Add("ScoreboardShow", "CustomScoreboard_Show", function()
    CreateCustomScoreboard()
    return true
end)

hook.Add("ScoreboardHide", "CustomScoreboard_Hide", function()
    if IsValid(ScoreboardPanel) then
        ScoreboardPanel:Remove()
        ScoreboardPanel = nil
    end
    return true
end)
if IsValid(bot) and bot.CurrentSound then
    bot.CurrentSound:Stop()
    bot.CurrentSound = nil
end
-- ============================================================================
-- UNIFIED CUSTOM VOICE HUD FOR PLAYERS & BOTS (cl_voice_hud_unified.lua)
-- ============================================================================

if SERVER then return end

local activeSpeakers = {}

-- Font Configuration matching clean HUD font
surface.CreateFont("VoiceHudFont", {
    font = "Roboto",
    size = 18,
    weight = 700,
    antialias = true,
})

-- Material setup for speaker icon
local speakerMat = Material("icon16/sound.png")

-- Track real player voice events natively
hook.Add("PlayerStartVoice", "CustomVoiceHUD_Start", function(ply)
    if IsValid(ply) then
        activeSpeakers[ply] = true
    end
end)

hook.Add("PlayerEndVoice", "CustomVoiceHUD_End", function(ply)
    if IsValid(ply) then
        activeSpeakers[ply] = nil
    end
end)

-- Main HUD Paint Hook handling both players and bots unified
local function PaintVoiceHUD()
    local client = LocalPlayer()
    if not IsValid(client) then return end

    -- Aggressively hide/kill default GMod voice VGUI elements so they never pop up
    if g_VoicePanelList and IsValid(g_VoicePanelList) then
        g_VoicePanelList:SetVisible(false)
        g_VoicePanelList:SetSize(0, 0)
    end

    -- Automatically sync bot voice network states into activeSpeakers table
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsBot() then
            local isTalking = ply:GetNWBool("BotIsTalking", false)
            if isTalking then
                activeSpeakers[ply] = true
            else
                activeSpeakers[ply] = nil
            end
        end
    end

    -- Clean up invalid entities from our active list
    for ply, _ in pairs(activeSpeakers) do
        if not IsValid(ply) then
            activeSpeakers[ply] = nil
        end
    end

    -- Layout Dimensions matching your custom design spec
    local startX = ScrW() - 320
    local startY = 100
    local boxWidth = 280
    local boxHeight = 42
    local spacing = 8
    local index = 0

    for ply, _ in pairs(activeSpeakers) do
        if IsValid(ply) and not ply.IsCustomMuted then
            local yPos = startY + (index * (boxHeight + spacing))

            -- 1. Main semi-transparent dark background panel
            surface.SetDrawColor(20, 20, 20, 210)
            surface.DrawRect(startX, yPos, boxWidth, boxHeight)

            -- 2. Outer Accent Border (Bright blue outline box)
            surface.SetDrawColor(50, 150, 255, 255)
            surface.DrawOutlinedRect(startX, yPos, boxWidth, boxHeight, 1)

            -- 3. Inner Dark Box for the Speaker Icon (left side square)
            surface.SetDrawColor(30, 30, 30, 255)
            surface.DrawRect(startX + 6, yPos + 6, 30, 30)

            -- 4. Speaker Icon inside the box
            surface.SetMaterial(speakerMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(startX + 9, yPos + 9, 24, 24)

            -- 5. Player or Bot Name Text (with string length formatting)
            local displayName = ply:Nick()
            if string.len(displayName) > 22 then
                displayName = string.sub(displayName, 1, 20) .. ".."
            end

            draw.SimpleText(displayName, "VoiceHudFont", startX + 48, yPos + 11, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            index = index + 1
        end
    end
end

-- Register to HUDPaint hook
hook.Add("HUDPaint", "RenderCustomVoiceHUD", PaintVoiceHUD)

-- Intercept and destroy default voice panel creations to completely suppress native boxes
hook.Add("CreateVoicePanel", "KillDefaultVoicePanel", function(pnl)
    if IsValid(pnl) then
        pnl:Remove()
    end
    return false
end)
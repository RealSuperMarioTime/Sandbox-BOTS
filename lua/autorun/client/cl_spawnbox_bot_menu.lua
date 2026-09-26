-- =========================================================================
-- SANDBOX BOTS - SPAWN CREATOR MENU & MANAGEMENT SYSTEM
-- =========================================================================

CreateClientConVar("cl_sb_bot_enable_rdm", "1", true, false)
CreateClientConVar("cl_sb_bot_enable_noclip", "1", true, false)
CreateClientConVar("cl_sb_bot_enable_building", "1", true, false)
CreateClientConVar("cl_sb_bot_enable_chat", "0", true, false)
CreateClientConVar("cl_sb_bot_enable_voice", "0", true, false)
CreateClientConVar("cl_sb_bot_enable_crossbow_suspicion", "1", true, false)
CreateClientConVar("cl_sb_bot_enable_ai", "1", true, false)
CreateClientConVar("cl_sb_bot_enable_killbind", "1", true, false)

-- =========================================================================
-- CLIENT-SIDE MENU INTERFACE
-- =========================================================================
if CLIENT then
    -- Network strings and menu creation for spawn customization (GMod Model Selector Style)
    net.Receive("SandboxBots_OpenSpawnMenu", function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(900, 600)
        frame:Center()
        frame:SetTitle("Player Model Selector & Customizer")
        frame:SetVisible(true)
        frame:SetDraggable(true)
        frame:ShowCloseButton(true)
        frame:MakePopup()

        -- Left Side: 3D Model Preview Panel
        local modelPanel = vgui.Create("DModelPanel", frame)
        modelPanel:SetPos(10, 30)
        modelPanel:SetSize(400, 515)
        modelPanel:SetModel("models/player/kleiner.mdl")
        
        if IsValid(modelPanel.Entity) then
            local animMin, animMax = modelPanel.Entity:GetSequenceBounds(modelPanel.Entity:LookupSequence("idle"))
            if animMin and animMax then
                modelPanel:SetCamPos(Vector(50, 0, 60))
                modelPanel:SetLookAt((animMin + animMax) * 0.5)
            end
        end

        -- Right Side: Property Sheet (Tabs Container) - Explicitly positioned to avoid overlap
        local propertySheet = vgui.Create("DPropertySheet", frame)
        propertySheet:SetPos(420, 30)
        propertySheet:SetSize(470, 515)

        -- 1. Model & Name Tab
        local modelTab = vgui.Create("DPanel", propertySheet)
        modelTab.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(240, 240, 240))
        end

        local form = vgui.Create("DForm", modelTab)
        form:Dock(TOP)
        form:SetName("Bot Identity & Model")

        local nameEntry = form:TextEntry("Bot Name")
        nameEntry:SetValue("Sandbox Bot")

        local modelEntry = form:TextEntry("Player Model Path")
        modelEntry:SetValue("models/player/kleiner.mdl")
        
        function modelEntry:OnChange()
            local mdl = self:GetValue()
            if mdl ~= "" and util.IsValidModel(mdl) then
                modelPanel:SetModel(mdl)
            end
        end

        local presetLabel = vgui.Create("DLabel", modelTab)
        presetLabel:SetText("Quick Model Presets:")
        presetLabel:Dock(TOP)
        presetLabel:DockMargin(10, 10, 10, 0)
        presetLabel:SetTextColor(Color(50, 50, 50))

        local scrollPanel = vgui.Create("DScrollPanel", modelTab)
        scrollPanel:Dock(FILL)
        scrollPanel:DockMargin(10, 5, 10, 10)

        local grid = vgui.Create("DGrid", scrollPanel)
        grid:SetPos(0, 0)
        grid:SetCols(6)
        grid:SetColW(70)
        grid:SetRowH(70)

        local sampleModels = {
            "models/player/kleiner.mdl",
            "models/player/barney.mdl",
            "models/player/combine_soldier.mdl",
            "models/player/alyx.mdl",
            "models/player/breen.mdl",
            "models/player/eli.mdl",
            "models/player/monk.mdl",
            "models/player/odessa.mdl",
            "models/player/police.mdl",
            "models/player/zombie_classic.mdl"
        }

        for _, mdlPath in ipairs(sampleModels) do
            local icon = vgui.Create("SpawnIcon")
            icon:SetSize(64, 64)
            icon:SetModel(mdlPath)
            icon.DoClick = function()
                modelEntry:SetValue(mdlPath)
                modelPanel:SetModel(mdlPath)
            end
            grid:AddItem(icon)
        end

        propertySheet:AddSheet("Model", modelTab, "icon16/user.png")

        -- 2. Colors Tab
        local colorTab = vgui.Create("DPanel", propertySheet)
        colorTab.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(240, 240, 240))
        end

        local colorForm = vgui.Create("DForm", colorTab)
        colorForm:Dock(FILL)
        colorForm:SetName("Custom Colors")

        colorForm:Help("Player Color:")
        local pColPicker = vgui.Create("DColorMixer", colorForm)
        pColPicker:SetPalette(true)
        pColPicker:SetAlphaBar(false)
        pColPicker:SetVector(Vector(1, 0.5, 0))
        colorForm:AddItem(pColPicker)

        colorForm:Help("Weapon Color:")
        local wColorPicker = vgui.Create("DColorMixer", colorForm)
        wColorPicker:SetPalette(true)
        wColorPicker:SetAlphaBar(false)
        wColorPicker:SetVector(Vector(0, 0.5, 1))
        colorForm:AddItem(wColorPicker)

        propertySheet:AddSheet("Colors", colorTab, "icon16/color_wheel.png")

        -- Save & Spawn Button spanning the bottom
        local spawnBtn = vgui.Create("DButton", frame)
        spawnBtn:SetText("Save & Spawn Bot")
        spawnBtn:SetSize(880, 35)
        spawnBtn:SetPos(10, 555)
        spawnBtn.DoClick = function()
            local newName = nameEntry:GetValue()
            local newModel = modelEntry:GetValue()
            local pVec = pColPicker:GetVector()
            local wVec = wColorPicker:GetVector()

            net.Start("SandboxBots_SpawnCustomBot")
            net.WriteString(newName)
            net.WriteString(newModel)
            net.WriteVector(pVec)
            net.WriteVector(wVec)
            net.SendToServer()

            frame:Close()
        end
    end)

    hook.Add("PopulateToolMenu", "AddSandboxBotsToUtilities", function()
        spawnmenu.AddToolMenuOption("Utilities", "Sandbox BOTS", "SandboxBOTS_Menu", "Bot Admin Settings", "", "", function(panel)
            if not IsValid(panel) then return end
            panel:ClearControls()

            -- Section: Header and Spawning
            panel:AddControl("Header", { Description = "Configure and control your Sandbox BOTS." })
            
            -- New Bot Customization & Management Section
            local customSpawnCategory = vgui.Create("DForm", panel)
            customSpawnCategory:SetName("Bot Customization & Spawning[WIP]")
            
            local openMenuBtn = customSpawnCategory:Button("Open Model & Appearance Menu...")
            openMenuBtn.DoClick = function()
                net.Start("SandboxBots_OpenSpawnMenuRequest")
                net.SendToServer()
            end
            panel:AddItem(customSpawnCategory)

            local spawnCategory = vgui.Create("DForm", panel)
            spawnCategory:SetName("Bot Management")
            
            spawnCategory:Button("Kick All Custom Bots", "SandboxBots_KickAll")
            spawnCategory:Button("Clear RDM Records", "SandboxBOTS_ClearRdmRecords")
            panel:AddItem(spawnCategory)

            -- Section: Feature Toggles
            local toggleCategory = vgui.Create("DForm", panel)
            toggleCategory:SetName("Bot Feature Toggles")
            
            local function addToggle(label, convarName, commandName)
                local chk = toggleCategory:CheckBox(label, convarName)
                function chk:OnChange(bVal)
                    LocalPlayer():ConCommand(commandName .. " " .. (bVal and "1" or "0"))
                end
            end

            addToggle("Toggle RDM Chaos", "cl_sb_bot_enable_rdm", "SandboxBOTS_EnableRdm")
            addToggle("Toggle Noclip Flying", "cl_sb_bot_enable_noclip", "SandboxBOTS_EnableNoclip")
            addToggle("Toggle Building", "cl_sb_bot_enable_building", "SandboxBOTS_EnableBuilding")
            addToggle("Toggle Bot Chat", "cl_sb_bot_enable_chat", "SandboxBOTS_EnableChat")
            addToggle("Toggle Bot Voicechat", "cl_sb_bot_enable_voice", "SandboxBOTS_EnableVoice")
            addToggle("Toggle Crossbow Suspicion", "cl_sb_bot_enable_crossbow_suspicion", "SandboxBOTS_EnableCrossbowSuspicion")
            addToggle("Toggle Bot AI Logic", "cl_sb_bot_enable_ai", "SandboxBOTS_EnableAI")
            addToggle("Toggle Bot Killbinds", "cl_sb_bot_enable_killbind", "SandboxBOTS_EnableKillbind")
            
            panel:AddItem(toggleCategory)

            -- Section: Advanced Admin Actions / Weapon Forcing
            local weaponCategory = vgui.Create("DForm", panel)
            weaponCategory:SetName("Bot Weapon Control")
            
            local weaponTextEntry = weaponCategory:TextEntry("Weapon Class (e.g. weapon_rpg)")
            weaponTextEntry:SetValue("weapon_rpg")
            
            local applyButton = weaponCategory:Button("Force Equip Weapon")
            applyButton.DoClick = function()
                local weaponClass = weaponTextEntry:GetValue()
                if weaponClass and weaponClass ~= "" then
                    LocalPlayer():ConCommand("SandboxBOTS_ForceWeapon \"" .. weaponClass .. "\"")
                else
                    LocalPlayer():PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Please enter a valid weapon class!")
                end
            end

            panel:AddItem(weaponCategory)
        end)
    end)
end

-- =========================================================================
-- SERVER-SIDE COMMAND HANDLERS
-- =========================================================================
if SERVER then
    -- Global Configuration States
    _G.SB_BOT_RDM_ENABLED = true 
    _G.SB_BOT_NOCLIP_ENABLED = true 
    _G.SB_BOT_BUILDING_ENABLED = true 
    _G.SB_BOT_CHAT_ENABLED = false 
    _G.SB_BOT_VOICE_ENABLED = false 
    _G.SB_BOT_CROSSBOW_SUSPICION_ENABLED = true 

    util.AddNetworkString("SandboxBots_OpenSpawnMenuRequest") 
    util.AddNetworkString("SandboxBots_OpenSpawnMenu") 
    util.AddNetworkString("SandboxBots_SpawnCustomBot") 

    net.Receive("SandboxBots_OpenSpawnMenuRequest", function(len, ply)
        if not ply:IsAdmin() then return end 
        net.Start("SandboxBots_OpenSpawnMenu") 
        net.Send(ply) 
    end)

    net.Receive("SandboxBots_SpawnCustomBot", function(len, ply)
        if not ply:IsAdmin() then return end 
        local name = net.ReadString() 
        local model = net.ReadString() 
        local pColor = net.ReadVector() 
        local wColor = net.ReadVector() 

        RunConsoleCommand("bot") 
        timer.Simple(0.5, function()
            for _, b in ipairs(player.GetBots()) do
                if IsValid(b) and not b.IsCustomConfigured then
                    b.IsCustomConfigured = true 
                    if name ~= "" then
                        b.PersistentName = name 
                        b:SetName(name) 
                    end
                    if model ~= "" and util.IsValidModel(model) then
                        b.PersistentModel = (model ~= "" and util.IsValidModel(model)) and model or "models/player/kleiner.mdl"
                        util.PrecacheModel(model) 
                        b:SetModel(model) 
                    end
                    b.PersistentColor = pColor 
                    b:SetPlayerColor(pColor) 
                    b:SetWeaponColor(wColor) 
                    
                    if IsValid(ply) then
                        ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Spawned and configured custom bot: " .. (name ~= "" and name or "Bot")) 
                    end
                    break
                end
            end
        end)
    end)

    local function IsAdminValid(ply)
        return not IsValid(ply) or ply:IsAdmin() 
    end

    concommand.Add("SandboxBots_KickAll", function(ply)
        if not IsAdminValid(ply) then return end 
        local count = 0
        for _, bot in ipairs(ents.FindByClass("sent_sandbox_bot")) do
            if IsValid(bot) then
                bot:Remove() 
                count = count + 1
            end
        end
        for _, bot in ipairs(player.GetBots()) do
            if IsValid(bot) then
                bot:Kick("Kicked by admin") 
                count = count + 1
            end
        end
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Kicked " .. count .. " bot(s).") 
        end
    end)

    concommand.Add("SandboxBOTS_ClearRdmRecords", function(ply)
        if not IsAdminValid(ply) then return end 
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Cleared RDM records.") 
        end
    end)

    local function RegisterToggleCommand(cmdName, globalKey, labelName)
        concommand.Add(cmdName, function(ply, _, args)
            if not IsAdminValid(ply) then return end 
            local val = tonumber(args[1]) or 0 
            _G[globalKey] = (val == 1) 
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] " .. labelName .. " set to: " .. tostring(_G[globalKey])) 
            end
        end)
    end

    RegisterToggleCommand("SandboxBOTS_EnableRdm", "SB_BOT_RDM_ENABLED", "RDM Chaos") 
    RegisterToggleCommand("SandboxBOTS_EnableNoclip", "SB_BOT_NOCLIP_ENABLED", "Noclip Flying") 
    RegisterToggleCommand("SandboxBOTS_EnableBuilding", "SB_BOT_BUILDING_ENABLED", "Building") 
    RegisterToggleCommand("SandboxBOTS_EnableChat", "SB_BOT_CHAT_ENABLED", "Bot Chat") 
    RegisterToggleCommand("SandboxBOTS_EnableVoice", "SB_BOT_VOICE_ENABLED", "Bot Voicechat") 
    RegisterToggleCommand("SandboxBOTS_EnableCrossbowSuspicion", "SB_BOT_CROSSBOW_SUSPICION_ENABLED", "Crossbow Suspicion") 
    RegisterToggleCommand("SandboxBOTS_EnableAI", "SB_BOT_AI_ENABLED", "Bot AI Logic") 
    RegisterToggleCommand("SandboxBOTS_EnableKillbind", "SB_BOT_KILLBIND_ENABLED", "Bot Killbinds") 

    concommand.Add("SandboxBOTS_ForceWeapon", function(ply, _, args)
        if not IsAdminValid(ply) then return end 
        
        local weaponClass = table.concat(args, " ") 
        if not weaponClass or weaponClass == "" then
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTTALK, "Usage: SandboxBOTS_ForceWeapon <weapon_class>") 
            end
            return
        end

        local count = 0
        for _, bot in ipairs(ents.FindByClass("sent_sandbox_bot")) do
            if IsValid(bot) then
                bot:Give(weaponClass) 
                bot:SelectWeapon(weaponClass) 
                count = count + 1
            end
        end
        
        for _, bot in ipairs(player.GetBots()) do
            if IsValid(bot) then
                bot:Give(weaponClass) 
                bot:SelectWeapon(weaponClass) 
                count = count + 1
            end
        end
        
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Forced weapon '" .. weaponClass .. "' for " .. count .. " bot(s)!") 
        end
    end)
end
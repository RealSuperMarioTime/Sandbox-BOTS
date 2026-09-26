-- ============================================================================
-- ADVANCED SANDBOX BOT FRAMEWORK + PERSISTENT APPEARANCE + CROSSBOW DODGE
-- + SQUAD COORDINATION & FLANKING + LADDER CLIMBING + GRAVITY GUN INTEGRATION
-- + FIXED UNDO SYSTEM FOR SPAWNED ITEMS + PROP OBSTACLE AVOIDANCE & CROUCH-JUMP
-- + MODIFIED TO REPLACE NPC SPAWNING WITH CUSTOM BEHAVIOR/ENTITIES
-- + INTEGRATED SPAWN CUSTOMIZATION MENU
-- ============================================================================

AddCSLuaFile()

-- Fallback definitions for input bitflags if not yet initialized by the engine
IN_ATTACK = IN_ATTACK or 1
IN_ATTACK2 = IN_ATTACK2 or 2048
IN_JUMP = IN_JUMP or 2
IN_DUCK = IN_DUCK or 4
IN_USE = IN_USE or 32
IN_SPEED = IN_SPEED or 131072
IN_WALK = IN_WALK or 262144
IN_CONTEXTMENU = IN_CONTEXTMENU or 1048576

_G.SB_BOT_RDM_ENABLED = true
_G.SB_BOT_CHAT_ENABLED = _G.SB_BOT_CHAT_ENABLED or false
_G.SB_BOT_NOCLIP_ENABLED = _G.SB_BOT_NOCLIP_ENABLED or true
_G.SB_BOT_BUILDING_ENABLED = _G.SB_BOT_BUILDING_ENABLED or true
_G.SB_BOT_VOICE_ENABLED = _G.SB_BOT_VOICE_ENABLED or false
_G.SB_BOT_CROSSBOW_SUSPICION_ENABLED = _G.SB_BOT_CROSSBOW_SUSPICION_ENABLED or true
_G.SB_BOT_AI_ENABLED = _G.SB_BOT_AI_ENABLED or true
_G.SB_BOT_KILLBIND_ENABLED = _G.SB_BOT_KILLBIND_ENABLED or true

-- ============================================================================
-- NETWORK STRINGS
-- ============================================================================
if SERVER then
    util.AddNetworkString("SandboxBots_OpenSpawnMenuRequest")
    util.AddNetworkString("SandboxBots_OpenSpawnMenu")
    util.AddNetworkString("SandboxBots_SpawnCustomBot")
    util.AddNetworkString("SandboxBots_OpenCustomizeMenu")
    util.AddNetworkString("SetBotMuteState")
end

-- ============================================================================
-- CLIENT-SIDE INTERFACE & SPAWN/CUSTOMIZE MENUS
-- ============================================================================
if CLIENT then
    net.Receive("SandboxBots_OpenSpawnMenu", function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 450)
        frame:Center()
        frame:SetTitle("Spawn Custom Sandbox Bot")
        frame:MakePopup()

        local panel = vgui.Create("DPanel", frame)
        panel:Dock(FILL)
        panel:DockMargin(5, 5, 5, 5)

        local form = vgui.Create("DForm", panel)
        form:Dock(FILL)
        form:SetName("New Bot Customization")

        local nameEntry = form:TextEntry("Bot Name")
        nameEntry:SetValue("Sandbox Bot")

        local modelEntry = form:TextEntry("Player Model Path")
        modelEntry:SetValue("models/player/kleiner.mdl")

        local pColPicker = vgui.Create("DColorMixer", form)
        pColPicker:SetPalette(true)
        pColPicker:SetAlphaBar(false)
        pColPicker:SetVector(Vector(1, 0.5, 0))
        form:AddItem(pColPicker)

        local wColorPicker = vgui.Create("DColorMixer", form)
        wColorPicker:SetPalette(true)
        wColorPicker:SetAlphaBar(false)
        wColorPicker:SetVector(Vector(0, 0.5, 1))
        form:AddItem(wColorPicker)

        local spawnBtn = vgui.Create("DButton", form)
        spawnBtn:SetText("Save & Spawn Bot")
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
        form:AddItem(spawnBtn)
    end)

    hook.Add("PopulateToolMenu", "AddSandboxBotsToUtilities", function()
        spawnmenu.AddToolMenuOption("Utilities", "Sandbox BOTS", "SandboxBOTS_Menu", "Bot Admin Settings", "", "", function(panel)
            if not IsValid(panel) then return end
            panel:ClearControls()

            panel:AddControl("Header", { Description = "Configure and control your Sandbox BOTS." })
            
            local spawnCategory = vgui.Create("DForm", panel)
            spawnCategory:SetName("Bot Management")
            
            local openMenuBtn = spawnCategory:Button("Spawn Custom Bot...")
            openMenuBtn.DoClick = function()
                net.Start("SandboxBots_OpenSpawnMenuRequest")
                net.SendToServer()
            end

            spawnCategory:Button("Kick All Custom Bots", "SandboxBOTS_KickAll")
            spawnCategory:Button("Clear RDM Records", "SandboxBOTS_ClearRdmRecords")
            panel:AddItem(spawnCategory)

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

concommand.Add("SandboxBOTS_EnableChat", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then 
        _G.SB_BOT_CHAT_ENABLED = (val > 0)
        print("[SandboxBots] Bot Chat Enabled set to: " .. tostring(_G.SB_BOT_CHAT_ENABLED))
    end
end)

concommand.Add("SandboxBOTS_EnableRdm", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then 
        ply:ChatPrint("You must be an admin to change RDM settings.")
        return 
    end
    
    local val = tonumber(args and args[1] or 0)
    if val then
        _G.SB_BOT_RDM_ENABLED = (val > 0)
        print("[SandboxBots] RDM Mode set to: " .. tostring(_G.SB_BOT_RDM_ENABLED))
    else
        print("[SandboxBots] RDM Mode is currently: " .. tostring(_G.SB_BOT_RDM_ENABLED))
    end
end)

concommand.Add("SandboxBOTS_EnableNoclip", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then _G.SB_BOT_NOCLIP_ENABLED = (val > 0) end
end)

concommand.Add("SandboxBOTS_EnableBuilding", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then _G.SB_BOT_BUILDING_ENABLED = (val > 0) end
end)

concommand.Add("SandboxBOTS_EnableVoice", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then 
        _G.SB_BOT_VOICE_ENABLED = (val > 0)
        print("[SandboxBots] Bot Voice Enabled set to: " .. tostring(_G.SB_BOT_VOICE_ENABLED))
    end
end)

concommand.Add("SandboxBOTS_EnableCrossbowSuspicion", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then 
        _G.SB_BOT_CROSSBOW_SUSPICION_ENABLED = (val > 0)
        print("[SandboxBots] Crossbow Suspicion set to: " .. tostring(_G.SB_BOT_CROSSBOW_SUSPICION_ENABLED))
    end
end)

concommand.Add("SandboxBOTS_EnableAI", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then 
        _G.SB_BOT_AI_ENABLED = (val > 0)
        print("[SandboxBots] Bot AI Enabled set to: " .. tostring(_G.SB_BOT_AI_ENABLED))
    end
end)

concommand.Add("SandboxBOTS_EnableKillbind", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local val = tonumber(args and args[1] or 0)
    if val then 
        _G.SB_BOT_KILLBIND_ENABLED = (val > 0)
        print("[SandboxBots] Bot Killbinds Enabled set to: " .. tostring(_G.SB_BOT_KILLBIND_ENABLED))
    end
end)

-- ============================================================================
-- CUSTOM VOICE CLIP INTEGRATION
-- ============================================================================
local function PlayBotVoiceClip(bot)
    if not _G.SB_BOT_VOICE_ENABLED then return end
    if not IsValid(bot) or not bot:IsPlayer() then return end
    
    if bot.IsCustomMuted then return end
    
    local files, folders = file.Find("sound/bot_voice/*", "GAME")
    local soundPath = "vo/kurtz/vo_lead_on.wav"
    
    if files and #files > 0 then
        local validFiles = {}
        for _, fileName in ipairs(files) do
            if string.match(fileName, "^[%w_%-]+%.mp3$") or not string.find(fileName, "[\\[%s%]]") then
                table.insert(validFiles, fileName)
            end
        end
        
        if #validFiles > 0 then
            local randomClip = validFiles[math.random(#validFiles)]
            soundPath = "bot_voice/" .. randomClip
        else
            local randomClip = files[math.random(#files)]
            soundPath = "bot_voice/" .. randomClip
        end
    end

    local soundDuration = SoundDuration(soundPath)
    if not soundDuration or soundDuration <= 0 then
        soundDuration = 5.0 
    end
    
    bot:EmitSound(soundPath, 75, 100, 1, CHAN_VOICE)
    bot:SetNWBool("BotIsTalking", true)
    
    timer.Remove("BotVoiceReset_" .. bot:EntIndex())
    
    timer.Create("BotVoiceReset_" .. bot:EntIndex(), soundDuration, 1, function()
        if IsValid(bot) then
            bot:SetNWBool("BotIsTalking", false)
        end
    end)
end

local botGuns = {
    "weapon_pistol",
    "weapon_357",
    "weapon_smg1",
    "weapon_ar2",
    "weapon_shotgun",
    "weapon_crossbow",
    "weapon_physcannon"
}

local botTools = {
    "weapon_physgun",
    "gmod_tool",
    "gmod_camera"
}

local botNames = {
    "Shadow", "Gamer", "Builder", "Epic", "Pro", "Cyber", "Nox", "Glitch", 
    "Pixel", "Vortex", "Hyper", "Neo", "Ghost", "Zack", "Aiden", "Kyle", 
    "Blaze", "Titan", "Cortex", "Echo", "Static", "Turbo", "Quantum", "Agent",
    "Sniper", "Slayer", "Construct", "Master", "Dude", "Zero", "Prime", "Wrecker",
    "SuperMarioTime", "Markiplier", "StarFrost", "Dissaor", "Venturian",
    "Homelessgoomba", "ImmortalKyodai", "Flying Pings", "gay", "BOTPlayer", "Dune",
    "Sticker", "matufer15768", "NecrosVideos"
}

local gmodGestureActivities = {
    ACT_GMOD_TAUNT_DANCE,
    ACT_GMOD_TAUNT_LAUGH,
    ACT_GMOD_GESTURE_BOW,
    ACT_GMOD_GESTURE_AGREE,
    ACT_GMOD_GESTURE_DISAGREE,
    ACT_GMOD_GESTURE_WAVE,
    ACT_GMOD_GESTURE_BUMP
}

local randomChatPhrases = {
    "anyone wanna build something?",
    "check out this prop combo lol",
    "who spawned all these items?",
    "lag...",
    "nice build",
    "does anyone have a tool gun?",
    "this map is pretty cool",
    "look at my spawn menu",
    "stop touching my props!!",
    "that really was a skill issue",
    "imagine dying to physics",
    "he thinks he is Gordon Freeman",
    "someone is playing on very high ping",
    "get defeated",
    "wait let him cook"
}

local afkTriggerPhrases = {
    "brb getting a drink",
    "brb",
    "afk for a sec",
    "grabbing snacks brb"
}

local playerReplyPhrases = {
    "true lol",
    "for real",
    "wait what?",
    "nah",
    "lets do it",
    "lol yeah",
    "haha nice",
    "dont look at me",
    "you seein this lag too?"
}

local cameraChatPhrases = {
    "say cheese!",
    "capturing this screenshot for my portfolio",
    "epic photo angle right here",
    "look at the lighting on this!"
}

local rdmTauntPhrases = {
    "It's free real estate... and by that I mean your loot.",
    "Time to test out my aim on you!",
    "Nothing personal, just feeling destructive today.",
    "Free kill spotted!",
    "Prepare to get styled on!"
}

local revengeTauntPhrases = {
    "You shouldn't have done that. Big mistake!",
    "I remember you! Payback time!",
    "You killed me earlier, now it's your turn to drop!",
    "Found you! Time for revenge!",
    "Nobody gets away with killing me!"
}

local PerformBotGesture

local function SimulateTypingAndSay(bot, text, isMidDeathCut, targetEntity)
    if not _G.SB_BOT_CHAT_ENABLED then return end
    if not IsValid(bot) or not bot:IsPlayer() then return end
    if bot.IsAFK then return end

    if #text > 125 then
        text = string.sub(text, 1, 125)
    end

    bot.IsTypingMessage = true
    
    if IsValid(targetEntity) then
        local targetPos = targetEntity:IsPlayer() and targetEntity:GetShootPos() or targetEntity:GetPos()
        local lookAng = (targetPos - bot:GetShootPos()):Angle()
        lookAng.p = math.Clamp(lookAng.p, -45, 45)
        lookAng.r = 0
        bot:SetEyeAngles(lookAng)
    else
        local typingAng = bot:EyeAngles()
        typingAng.p = 25
        bot:SetEyeAngles(typingAng)
    end

    local typingDuration = math.min(#text * 0.04 + math.Rand(0.3, 0.8), 3.5)

    timer.Simple(typingDuration, function()
        if IsValid(bot) and bot:IsPlayer() then
            bot.IsTypingMessage = false
            
            if IsValid(targetEntity) then
                local targetPos = targetEntity:IsPlayer() and targetEntity:GetShootPos() or targetEntity:GetPos()
                local lookAng = (targetPos - bot:GetShootPos()):Angle()
                lookAng.p = math.Clamp(lookAng.p, -45, 45)
                lookAng.r = 0
                bot:SetEyeAngles(lookAng)
            end

            if isMidDeathCut or bot:Alive() then
                bot:Say(text)
                PlayBotVoiceClip(bot)
                if math.random(100) < 35 then
                    PerformBotGesture(bot)
                end
            end
        end
    end)
end

PerformBotGesture = function(bot)
    if not IsValid(bot) or not bot:IsPlayer() or bot.IsAFK then return end
    
    if bot.BotState == "Combat" or bot.BotState == "Retreating" or bot.BotState == "FleeingGrenade" or IsValid(bot.CombatTarget) then
        return
    end

    local chosenActivity = gmodGestureActivities[math.random(#gmodGestureActivities)]
    bot:AddGesture(chosenActivity, true)
end

_G.SB_BOT_RDM_STRIKES = _G.SB_BOT_RDM_STRIKES or {}

local rdmWarningPhrases = {
    "Stop RDMing people, what is wrong with you?",
    "Admin! This guy is RDMing everyone!",
    "Stop killing random players for no reason!",
    "Why are you RDMing? Stop it!"
}

local rdmVengeancePhrases = {
    "That's it, you've been RDMing too much. Retaliation time!",
    "Enjoy getting payback for your RDM spree!",
    "Server justice incoming, stop RDMing!",
    "Time to put an end to your random deathmatching!"
}

concommand.Add("SandboxBOTS_ClearRdmRecords", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then 
        ply:ChatPrint("You must be an admin to clear RDM records.")
        return 
    end
    _G.SB_BOT_RDM_STRIKES = {}
    print("[SandboxBots] All player RDM infraction records have been cleared.")
    if IsValid(ply) then ply:ChatPrint("RDM records cleared.") end
end)

local function ProcessPlayerRDMReport(victim, attacker)
    if not IsValid(victim) or not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker:IsBot() then return end

    _G.SB_BOT_RDM_STRIKES[attacker] = _G.SB_BOT_RDM_STRIKES[attacker] or { count = 0, lastOffense = 0 }
    
    local data = _G.SB_BOT_RDM_STRIKES[attacker]
    data.count = data.count + 1
    data.lastOffense = CurTime()

    timer.Simple(math.Rand(0.5, 1.2), function()
        if IsValid(victim) and victim:IsPlayer() and _G.SB_BOT_CHAT_ENABLED then
            if data.count == 1 then
                victim:Say(rdmWarningPhrases[math.random(#rdmWarningPhrases)])
            elseif data.count >= 3 then
                victim:Say(rdmVengeancePhrases[math.random(#rdmVengeancePhrases)])
                
                for _, bot in ipairs(player.GetAll()) do
                    if IsValid(bot) and bot:IsBot() and bot:GetNWBool("IsCustomSandboxBot", false) and bot:Alive() then
                        if bot:GetPos():Distance(attacker:GetPos()) < 2500 then
                            bot.CombatTarget = attacker
                            bot.LastKnownTargetPos = attacker:GetPos()
                            bot.BotState = "Combat"
                        end
                    end
                end
            end
        end
    end)
end

local retreatPhrases = {
    "Oh no, I'm out of here!",
    "Too low, backing off!",
    "Nope nope nope, retreating!",
    "Need to heal up, cya!"
}

local grenadePanicPhrases = {
    "GRENADE!! Run!",
    "Oh no, get away from that!",
    "Hot potato, see ya!",
    "Bomb! Run away!"
}

local crossbowPanicPhrases = {
    "Woah, a crossbow?! Dodging this!",
    "You picked the wrong weapon, taking evasive action!",
    "Big mistake pulling out that crossbow!",
    "Oh crap, a crossbow! Evade!"
}

local forgivenessPhrases = {
    "Fine, whatever, I'll let it slide...",
    "Watch it next time!",
    "Whatever, we good now.",
    "I'm keeping my eyes on you, though."
}

local postAfkDeathPhrases = {
    "Wait, what happened? Why am I dead?",
    "Who killed me while I was away?!",
    "I literally just stepped away for a second...",
    "Aw man, I got killed while afk?"
}

local noclipFunPhrases = {
    "Wheee, flying around!",
    "Check out my noclip skills!",
    "Taking the high ground via noclip~",
    "Who needs stairs anyway?"
}

local stuckPhrases = {
    "Oof stuck, time to noclip out!",
    "Ugh stuck in a prop again...",
    "Noclipping out of this trap!",
    "Physics engine got me stuck!"
}

local fallAvoidPhrases = {
    "Whoa, almost fell off there!",
    "Almost took heavy fall damage yikes",
    "Good thing I caught that ledge",
    "Who left a massive drop there?!"
}

local ladderClimbPhrases = {
    "Climbing up this ladder!",
    "Taking the ladder shortcut~",
    "Up we go!"
}

local suddenDeathChatCuts = {
    "wait what",
    "oh no",
    "he's right behi",
    "watch out for the",
    "no no no",
    "ah hel",
    "what",
    "where did he shoot from",
    "ugh-"
}

local squadFlankChatter = {
    "Flanking right side, cover me!",
    "Spotted target, moving to a flanking angle!",
    "Pincer maneuver time, I'm going around!",
    "Suppressive fire, I'm changing position!"
}

local function ShareTargetWithNearbyBots(bot, target)
    if not IsValid(bot) or not IsValid(target) then return end
    local botPos = bot:GetPos()
    
    for _, ally in ipairs(player.GetAll()) do
        if IsValid(ally) and ally:IsBot() and ally:GetNWBool("IsCustomSandboxBot", false) and ally:Alive() and ally ~= bot then
            if ally:GetPos():Distance(botPos) < 1200 then
                if not IsValid(ally.CombatTarget) then
                    ally.CombatTarget = target
                    ally.LastKnownTargetPos = target:IsPlayer() and target:GetShootPos() or target:GetPos()
                    ally.BotState = "Combat"
                    
                    if ally:EntIndex() % 2 == 0 then
                        ally.FlankMode = true
                        ally.FlankOffset = Vector(math.random(-300, 300), math.random(-300, 300), 0)
                        if math.random(100) < 35 and _G.SB_BOT_CHAT_ENABLED then
                            SimulateTypingAndSay(ally, squadFlankChatter[math.random(#squadFlankChatter)], false, target)
                        end
                    else
                        ally.FlankMode = false
                    end
                end
            end
        end
    end
end

local function BotTextReply(bot, text, targetEntity)
    if not _G.SB_BOT_CHAT_ENABLED then return end
    SimulateTypingAndSay(bot, text, false, targetEntity)
end

local function HandleBotAmmoAndWeapons(bot)
    if bot.IsAFK then return end
    local activeWep = bot:GetActiveWeapon()
    
    if IsValid(activeWep) and not table.HasValue(botTools, activeWep:GetClass()) and activeWep:GetClass() ~= "weapon_crowbar" then
        if activeWep:GetClass() == "weapon_physcannon" then
            return
        end

        local clip1 = activeWep:Clip1()
        local maxClip1 = activeWep:GetMaxClip1()
        local ammoType = activeWep:GetPrimaryAmmoType()
        local reserveAmmo = bot:GetAmmoCount(ammoType)

        local isShotgunEmpty = (activeWep:GetClass() == "weapon_shotgun" and clip1 <= 0)

        if clip1 <= 0 and reserveAmmo <= 0 and maxClip1 > 0 or isShotgunEmpty then
            if isShotgunEmpty and reserveAmmo > 0 then
                if math.random(100) < 50 then
                    local availableGuns = {}
                    for _, gunClass in ipairs(botGuns) do
                        if bot:HasWeapon(gunClass) and gunClass ~= activeWep:GetClass() then
                            local w = bot:GetWeapon(gunClass)
                            if IsValid(w) and (w:Clip1() > 0 or bot:GetAmmoCount(w:GetPrimaryAmmoType()) > 0 or w:GetClass() == "weapon_physcannon") then
                                table.insert(availableGuns, gunClass)
                            end
                        end
                    end
                    if #availableGuns > 0 then
                        bot:SelectWeapon(availableGuns[math.random(#availableGuns)])
                        return
                    end
                end
            end

            if math.random(100) < 65 then
                bot:GiveAmmo(maxClip1 * 3, ammoType)
            else
                local availableGuns = {}
                for _, gunClass in ipairs(botGuns) do
                    if bot:HasWeapon(gunClass) and gunClass ~= activeWep:GetClass() then
                        local w = bot:GetWeapon(gunClass)
                        if IsValid(w) and (w:Clip1() > 0 or bot:GetAmmoCount(w:GetPrimaryAmmoType()) > 0 or w:GetClass() == "weapon_physcannon") then
                            table.insert(availableGuns, gunClass)
                        end
                    end
                end

                if #availableGuns > 0 then
                    local switchGun = availableGuns[math.random(#availableGuns)]
                    bot:SelectWeapon(switchGun)
                else
                    local randomWeapon = botGuns[math.random(#botGuns)]
                    if not bot:HasWeapon(randomWeapon) then
                        bot:Give(randomWeapon)
                    end
                    bot:SelectWeapon(randomWeapon)
                    local newWep = bot:GetActiveWeapon()
                    if IsValid(newWep) and newWep:GetMaxClip1() > 0 then
                        bot:GiveAmmo(newWep:GetMaxClip1() * 3, newWep:GetPrimaryAmmoType())
                    end
                end
            end
        end
    else
        local chosenWeapon = botGuns[math.random(#botGuns)]
        if not bot:HasWeapon(chosenWeapon) then
            bot:Give(chosenWeapon)
        end
        bot:SelectWeapon(chosenWeapon)
    end
end

local function ForceEquipGun(bot)
    if bot.IsAFK then return end
    HandleBotAmmoAndWeapons(bot)
end

local function HasLineOfSight(bot, target)
    if not IsValid(target) then return false end
    local targetPos = target:IsPlayer() and target:GetShootPos() or target:GetPos()
    
    local tr = util.TraceLine({
        start = bot:GetShootPos(),
        endpos = targetPos,
        filter = {bot, target},
        mask = MASK_SHOT
    })
    
    return tr.Fraction == 1.0
end

local function IsAimingCrossbowAtBot(bot, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "weapon_crossbow" then 
        return false 
    end
    
    if not HasLineOfSight(bot, ply) then return false end
    
    local plyAimDir = ply:GetAimVector()
    local dirToBot = (bot:GetShootPos() - ply:GetShootPos()):GetNormalized()
    local dotProduct = plyAimDir:Dot(dirToBot)
    return dotProduct > 0.85
end

local function CalculateNavPath(startPos, goalPos)
    if not navmesh.IsLoaded() then return nil end

    local startArea = navmesh.GetNearestNavArea(startPos)
    local goalArea = navmesh.GetNearestNavArea(goalPos)

    if not IsValid(startArea) or not IsValid(goalArea) then return nil end
    if startArea == goalArea then return {goalArea:GetCenter()} end

    local openList = {}
    local closedList = {}
    local cameFrom = {}
    
    local gScore = {}
    local fScore = {}

    local function getHScore(area, target)
        return area:GetCenter():Distance(target:GetCenter())
    end

    startArea:ClearSearchLists()
    gScore[startArea] = 0
    fScore[startArea] = getHScore(startArea, goalArea)
    
    table.insert(openList, startArea)

    while #openList > 0 do
        table.sort(openList, function(a, b)
            return (fScore[a] or math.huge) < (fScore[b] or math.huge)
        end)
        
        local val = table.remove(openList, 1)

        if val == goalArea then
            local path = {goalArea:GetCenter()}
            local curr = goalArea
            while cameFrom[curr] do
                curr = cameFrom[curr]
                table.insert(path, 1, curr:GetCenter())
            end
            return path
        end

        closedList[val] = true

        for _, neighbor in ipairs(val:GetAdjacentAreas()) do
            if IsValid(neighbor) and not closedList[neighbor] then
                local tentativeGScore = (gScore[val] or math.huge) + val:GetCenter():Distance(neighbor:GetCenter())

                local isOpen = table.HasValue(openList, neighbor)
                if not isOpen or tentativeGScore < (gScore[neighbor] or math.huge) then
                    cameFrom[neighbor] = val
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = gScore[neighbor] + getHScore(neighbor, goalArea)

                    if not isOpen then
                        table.insert(openList, neighbor)
                    end
                end
            end
        end
    end

    return nil
end

-- ============================================================================
-- NETWORKING & SPAWN COMMAND HANDLERS
-- ============================================================================
if SERVER then
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

        if name == "" then
            name = botNames[math.random(#botNames)]
        end

        _G.PendingCustomBots = _G.PendingCustomBots or {}
        _G.PendingCustomBots[name] = true
        _G.PendingCustomBotConfigs = _G.PendingCustomBotConfigs or {}
        _G.PendingCustomBotConfigs[name] = {
            model = model,
            pColor = pColor,
            wColor = wColor
        }

        local spawnedBot = player.CreateNextBot(name)

        if IsValid(spawnedBot) then
            spawnedBot:SetNWBool("IsCustomSandboxBot", true)
            spawnedBot.PersistentName = name
            spawnedBot.PersistentModel = (model ~= "" and util.IsValidModel(model)) and model or "models/player/kleiner.mdl"
            spawnedBot.PersistentColor = pColor
            
            if util.IsValidModel(spawnedBot.PersistentModel) then
                util.PrecacheModel(spawnedBot.PersistentModel)
                spawnedBot:SetModel(spawnedBot.PersistentModel)
            end
            
            spawnedBot:SetPlayerColor(pColor)
            spawnedBot:SetWeaponColor(wColor)
            
            spawnedBot:Give("weapon_physgun")
            spawnedBot:Give("weapon_physcannon")
            spawnedBot:Give("gmod_tool")
            spawnedBot:SelectWeapon("weapon_physgun")
            
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTTALK, "[Sandbox BOTS] Spawned and configured custom bot: " .. name)
            end
            
            PlayBotVoiceClip(spawnedBot)
        else
            print("[SandboxBots] Failed to create bot. Max player limit reached or error occurred.")
        end
    end)
end

concommand.Add("SandboxBOTS_Add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then 
        ply:ChatPrint("You must be an admin to spawn sandbox bots.")
        return 
    end

    local generatedName = botNames[math.random(#botNames)]
    
    _G.PendingCustomBots = _G.PendingCustomBots or {}
    _G.PendingCustomBots[generatedName] = true

    local spawnedBot = player.CreateNextBot(generatedName)

    if IsValid(spawnedBot) then
        spawnedBot:SetNWBool("IsCustomSandboxBot", true)
        spawnedBot.PersistentName = generatedName
        
        local allModels = player_manager.AllValidModels()
        local modelPaths = {}
        if allModels then
            for _, path in pairs(allModels) do
                table.insert(modelPaths, path)
            end
        end
        
        if #modelPaths > 0 then
            local chosenModel = modelPaths[math.random(#modelPaths)]
            spawnedBot.PersistentModel = chosenModel
            util.PrecacheModel(chosenModel)
            spawnedBot:SetModel(chosenModel)
        end

        spawnedBot.PersistentColor = Vector(math.Rand(0.2, 1), math.Rand(0.2, 1), math.Rand(0.2, 1))
        spawnedBot:SetPlayerColor(spawnedBot.PersistentColor)
        spawnedBot:SetWeaponColor(spawnedBot.PersistentColor)
        
        spawnedBot:Give("weapon_physgun")
        spawnedBot:Give("weapon_physcannon")
        spawnedBot:Give("gmod_tool")
        spawnedBot:SelectWeapon("weapon_physgun")
        
        spawnedBot:ChatPrint("Hello! I'm ready to play.")
        PlayBotVoiceClip(spawnedBot)
        
        timer.Simple(1.0, function()
            if IsValid(spawnedBot) then
                PerformBotGesture(spawnedBot)
            end
        end)
    else
        print("[SandboxBots] Failed to create bot. Max player limit reached or error occurred.")
    end
end, nil, "Spawns one or more sandbox bots into the server.")

hook.Add("PlayerSay", "SandboxBotChatInteraction", function(ply, text, teamOnly)
    if not _G.SB_BOT_CHAT_ENABLED then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end

    timer.Simple(math.Rand(0.8, 2.0), function()
        for _, bot in ipairs(player.GetAll()) do
            if IsValid(bot) and bot:IsPlayer() and bot:IsBot() and bot:GetNWBool("IsCustomSandboxBot", false) and bot:Alive() then
                if bot ~= ply and not bot.IsAFK then
                    if bot:GetPos():Distance(ply:GetPos()) < 1000 then
                        if math.random(100) < 50 then
                            BotTextReply(bot, playerReplyPhrases[math.random(#playerReplyPhrases)])
                            if math.random(100) < 40 then
                                PerformBotGesture(bot)
                            end
                            break 
                        end
                    end
                end
            end
        end
    end)
end)

hook.Add("StartCommand", "SandboxBotFullBehavior", function(ply, cmd)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:IsBot() then return end
    if not ply:GetNWBool("IsCustomSandboxBot", false) or not ply:Alive() then return end

    if not _G.SB_BOT_AI_ENABLED then return end

    local pos = ply:GetPos()
    if math.abs(pos.x) > 16000 or math.abs(pos.y) > 16000 or math.abs(pos.z) > 16000 then
        ply:SetMoveType(MOVETYPE_WALK)
        ply.IsNoclipActive = false
        ply.IsLadderActive = false
        
        local spawnPos = Vector(0, 0, 100)
        local spawnPoints = ents.FindByClass("info_player_start")
        if #spawnPoints == 0 then
            spawnPoints = ents.FindByClass("info_player_deathmatch")
        end
        if #spawnPoints == 0 then
            spawnPoints = ents.FindByClass("gmod_player_start")
        end

        if #spawnPoints > 0 then
            local chosenSpawn = spawnPoints[math.random(#spawnPoints)]
            if IsValid(chosenSpawn) then
                spawnPos = chosenSpawn:GetPos() + Vector(0, 0, 10)
            end
        end

        ply:SetPos(spawnPos)
        ply:SetVelocity(Vector(0, 0, 0))
        ply.BotState = "Wandering"
        ply.CombatTarget = nil
        ply.NavPath = nil
        return
    end

    ply.IsAFK = ply.IsAFK or false
    ply.AfkEndTime = ply.AfkEndTime or 0
    ply.DiedWhileAfk = ply.DiedWhileAfk or false
    ply.IsNoclipActive = ply.IsNoclipActive or false
    ply.NoclipEndTime = ply.NoclipEndTime or 0
    ply.IsLadderActive = ply.IsLadderActive or false
    ply.LadderEndTime = ply.LadderEndTime or 0

    if ply.IsAFK then
        if CurTime() > ply.AfkEndTime then
            ply.IsAFK = false
            
            if ply.DiedWhileAfk then
                timer.Simple(math.Rand(0.8, 1.5), function()
                    if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
                        BotTextReply(ply, postAfkDeathPhrases[math.random(#postAfkDeathPhrases)])
                    end
                end)
                ply.DiedWhileAfk = false
            end
        else
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
            cmd:SetButtons(0)
            return
        end
    end

    if _G.SB_BOT_KILLBIND_ENABLED then
        ply.NextKillBindCheck = ply.NextKillBindCheck or (CurTime() + 10)
        if CurTime() > ply.NextKillBindCheck then
            ply.NextKillBindCheck = CurTime() + math.random(45, 90)
            
            if math.random(100) < 15 then
                local resetPhrases = {
                    "stuck, resetting",
                    "rip me",
                    "oops wrong button",
                    "resetting position lol"
                }
                BotTextReply(ply, resetPhrases[math.random(#resetPhrases)])
                ply:Kill()
                return
            end
        end
    end

    ply.WasFallingFast = ply.WasFallingFast or false
    local velocityZ = ply:GetVelocity().z
    if not ply.IsNoclipActive and not ply.IsLadderActive and not ply:IsOnGround() then
        if velocityZ < -550 then
            ply.WasFallingFast = true
        end
    elseif ply:IsOnGround() and ply.WasFallingFast then
        ply.WasFallingFast = false
        local safeVel = ply:GetVelocity()
        safeVel.z = 0
        ply:SetVelocity(safeVel)
    end

    ply.NextLadderCheck = ply.NextLadderCheck or 0
    if not ply.IsNoclipActive and CurTime() > ply.NextLadderCheck then
        ply.NextLadderCheck = CurTime() + 0.3

        if not ply.IsLadderActive then
            local nearbyLadders = ents.FindInSphere(ply:GetPos(), 60)
            for _, ent in ipairs(nearbyLadders) do
                if IsValid(ent) and (ent:GetClass() == "func_useableladder" or ent:GetClass() == "func_ladder") then
                    ply.IsLadderActive = true
                    ply:SetMoveType(MOVETYPE_LADDER)
                    ply.LadderEndTime = CurTime() + math.random(4, 8)
                    
                    if math.random(100) < 30 and _G.SB_BOT_CHAT_ENABLED then
                        BotTextReply(ply, ladderClimbPhrases[math.random(#ladderClimbPhrases)])
                    end
                    break
                end
            end
        end
    end

    if ply.IsLadderActive then
        local currentButtons = tonumber(cmd:GetButtons() or 0) or 0
        currentButtons = bit.bor(currentButtons, IN_FORWARD)
        
        local ladderAng = ply:EyeAngles()
        ladderAng.p = -30 
        cmd:SetViewAngles(ladderAng)
        ply:SetEyeAngles(ladderAng)

        if ply:IsOnGround() or CurTime() > ply.LadderEndTime or (not (IsValid(ply) and ply.IsOnLadder and ply:IsOnLadder()) and ply:GetVelocity():Length() < 5) then
            if CurTime() > ply.LadderEndTime + 1 then
                ply.IsLadderActive = false
                ply:SetMoveType(MOVETYPE_WALK)
            end
        end

        cmd:SetForwardMove(400)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    ply.NextFallCheck = ply.NextFallCheck or 0
    if _G.SB_BOT_NOCLIP_ENABLED and CurTime() > ply.NextFallCheck and not ply.IsNoclipActive and ply:IsOnGround() and ply.BotState ~= "Combat" and ply.BotState ~= "Retreating" then
        ply.NextFallCheck = CurTime() + 0.2
        
        local forwardPos = ply:GetPos() + ply:GetForward() * 70
        local dropTrace = util.TraceLine({
            start = forwardPos + Vector(0, 0, 20),
            endpos = forwardPos - Vector(0, 0, 400),
            filter = ply
        })

        if not dropTrace.Hit or (ply:GetPos().z - dropTrace.HitPos.z) > 280 then
            if math.random(100) < 50 then
                local currentAng = ply:EyeAngles()
                currentAng.y = currentAng.y + 180
                ply:SetEyeAngles(currentAng)
            else
                ply.IsNoclipActive = true
                ply:SetMoveType(MOVETYPE_NOCLIP)
                ply.NoclipEndTime = CurTime() + 2.0
                
                if math.random(100) < 30 then
                    SimulateTypingAndSay(ply, fallAvoidPhrases[math.random(#fallAvoidPhrases)], false)
                end
            end
        end
    end

    if not IsValid(ply.CombatTarget) then
        ply.CombatTarget = nil
    end

    if _G.SB_BOT_NOCLIP_ENABLED and IsValid(ply.CombatTarget) and not ply.IsNoclipActive then
        local targetPos = ply.CombatTarget:IsPlayer() and ply.CombatTarget:GetShootPos() or ply.CombatTarget:GetPos()
        local heightDiff = targetPos.z - ply:GetPos().z
        local dist2D = Vector(targetPos.x - ply:GetPos().x, targetPos.y - ply:GetPos().y, 0):Length()
        
        if heightDiff > 120 or (dist2D > 300 and not HasLineOfSight(ply, ply.CombatTarget) and math.random(100) < 20) then
            ply.IsNoclipActive = true
            ply:SetMoveType(MOVETYPE_NOCLIP)
            ply.NoclipEndTime = CurTime() + 10
        end
    end

    ply.LastPositionCheck = ply.LastPositionCheck or ply:GetPos()
    ply.NextPosCheckTimer = ply.NextPosCheckTimer or 0

    if _G.SB_BOT_NOCLIP_ENABLED and CurTime() > ply.NextPosCheckTimer then
        ply.NextPosCheckTimer = CurTime() + 1.0
        
        if not ply.IsNoclipActive and ply:GetPos():Distance(ply.LastPositionCheck) < 25 and (ply.BotState == "Wandering" or ply.BotState == "Searching") then
            ply.IsNoclipActive = true
            ply:SetMoveType(MOVETYPE_NOCLIP)
            ply.NoclipEndTime = CurTime() + math.random(3, 6)
            if math.random(100) < 60 then
                BotTextReply(ply, stuckPhrases[math.random(#stuckPhrases)])
            end
        elseif not ply.IsNoclipActive and math.random(1000) < 3 then
            ply.IsNoclipActive = true
            ply:SetMoveType(MOVETYPE_NOCLIP)
            ply.NoclipEndTime = CurTime() + math.random(4, 8)
            if math.random(100) < 40 then
                BotTextReply(ply, noclipFunPhrases[math.random(#noclipFunPhrases)])
            end
        end
        ply.LastPositionCheck = ply:GetPos()
    end

    if ply.IsNoclipActive then
        ply.NoclipRandomDirTimer = ply.NoclipRandomDirTimer or 0
        ply.NoclipTargetDirection = ply.NoclipTargetDirection or ply:GetForward()

        if not IsValid(ply.CombatTarget) and CurTime() > ply.NoclipRandomDirTimer then
            ply.NoclipRandomDirTimer = CurTime() + math.Rand(3, 6)
            local randomOffset = Vector(math.Rand(-500, 500), math.Rand(-500, 500), math.Rand(-200, 300))
            ply.NoclipTargetDirection = (ply:GetPos() + randomOffset - ply:GetPos()):GetNormalized()
        elseif IsValid(ply.CombatTarget) then
            local targetPos = ply.CombatTarget:IsPlayer() and ply.CombatTarget:GetShootPos() or ply.CombatTarget:GetPos()
            ply.NoclipTargetDirection = (targetPos - ply:GetShootPos()):GetNormalized()
        end

        local rawNoclipAngle = ply.NoclipTargetDirection:Angle()
        rawNoclipAngle.r = 0
        
        local smoothNoclipAngle = LerpAngle(0.1, ply:EyeAngles(), rawNoclipAngle)
        cmd:SetViewAngles(smoothNoclipAngle)
        ply:SetEyeAngles(smoothNoclipAngle)

        local currentButtons = tonumber(cmd:GetButtons() or 0) or 0
        currentButtons = bit.bor(currentButtons, IN_SPEED)
        currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))
        
        if IsValid(ply.CombatTarget) and ply:GetPos():Distance(ply.CombatTarget:GetPos()) < 150 then
            ply.IsNoclipActive = false
            ply:SetMoveType(MOVETYPE_WALK)
        elseif CurTime() > ply.NoclipEndTime and not IsValid(ply.CombatTarget) then
            ply.IsNoclipActive = false
            ply:SetMoveType(MOVETYPE_WALK)
        else
            cmd:SetForwardMove(1000)
            cmd:SetSideMove(0)
            cmd:SetButtons(currentButtons)
            return
        end
    end

    ply.BotState = ply.BotState or "Wandering"
    
    if not IsValid(ply.CombatTarget) then
        ply.CombatTarget = nil
    end

    local RETREAT_HP_THRESHOLD = 30 
    local HEALTH_RECOVERY_THRESHOLD = 60 

    ply.NextGrenadeCheck = ply.NextGrenadeCheck or 0
    if CurTime() > ply.NextGrenadeCheck then
        ply.NextGrenadeCheck = CurTime() + 0.15
        
        ply.DetectedGrenade = nil
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 400)) do
            if IsValid(ent) then
                local class = ent:GetClass()
                if class == "npc_grenade_frag" or class == "grenade" or class == "rpg_missile" or class == "satchel_detonate" or class == "combine_mine" then
                    ply.DetectedGrenade = ent
                    break
                end
            end
        end
    end

    if IsValid(ply.DetectedGrenade) then
        ply.BotState = "FleeingGrenade"
        ply.NextGrenadeSay = ply.NextGrenadeSay or 0
        if CurTime() > ply.NextGrenadeSay then
            ply.NextGrenadeSay = CurTime() + 4
            BotTextReply(ply, grenadePanicPhrases[math.random(#grenadePanicPhrases)])
        end
    elseif ply.BotState == "FleeingGrenade" then
        ply.BotState = "Wandering"
    end

    local currentButtons = tonumber(cmd:GetButtons() or 0) or 0

    if ply.BotState == "FleeingGrenade" and IsValid(ply.DetectedGrenade) then
        local grenadePos = ply.DetectedGrenade:GetPos()
        local rawRunAngle = (ply:GetPos() - grenadePos):Angle()
        rawRunAngle.p = 0
        
        local smoothRunAngle = LerpAngle(0.2, ply:EyeAngles(), rawRunAngle)
        cmd:SetViewAngles(smoothRunAngle)
        ply:SetEyeAngles(smoothRunAngle)

        currentButtons = bit.bor(currentButtons, IN_SPEED)
        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
        currentButtons = bit.band(currentButtons, bit.bnot(IN_JUMP))
        currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))

        cmd:SetForwardMove(400)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    ply.NextCrossbowCheck = ply.NextCrossbowCheck or 0
    if _G.SB_BOT_CROSSBOW_SUSPICION_ENABLED and CurTime() > ply.NextCrossbowCheck then
        ply.NextCrossbowCheck = CurTime() + 0.3
        
        for _, potentialThreat in ipairs(player.GetAll()) do
            if IsValid(potentialThreat) and potentialThreat ~= ply and potentialThreat:Alive() then
                if IsAimingCrossbowAtBot(ply, potentialThreat) then
                    ply.CombatTarget = potentialThreat
                    ply.LastKnownTargetPos = potentialThreat:GetPos()
                    
                    if ply.BotState ~= "Combat" then
                        BotTextReply(ply, crossbowPanicPhrases[math.random(#crossbowPanicPhrases)])
                    end
                    
                    ply.BotState = "Combat"
                    ForceEquipGun(ply)
                    break
                end
            end
        end
    end

    if _G.SB_BOT_RDM_ENABLED then
        ply.NextRDMCheck = ply.NextRDMCheck or 0
        if not IsValid(ply.CombatTarget) and ply.BotState == "Wandering" and CurTime() > ply.NextRDMCheck then
            ply.NextRDMCheck = CurTime() + math.random(15, 30)
            
            local possibleTargets = {}
            for _, otherPly in ipairs(player.GetAll()) do
                if IsValid(otherPly) and otherPly ~= ply and otherPly:Alive() then
                    if ply:GetPos():Distance(otherPly:GetPos()) < 3500 and HasLineOfSight(ply, otherPly) then
                        table.insert(possibleTargets, otherPly)
                    end
                end
            end

            if #possibleTargets > 0 then
                local chosenTarget = possibleTargets[math.random(#possibleTargets)]
                if IsValid(chosenTarget) then
                    ply.CombatTarget = chosenTarget
                    ply.LastKnownTargetPos = chosenTarget:GetPos()
                    ply.BotState = "Combat"
                    ForceEquipGun(ply)
                    BotTextReply(ply, rdmTauntPhrases[math.random(#rdmTauntPhrases)])
                    ShareTargetWithNearbyBots(ply, chosenTarget)
                end
            end
        end
    end

    if not IsValid(ply.CombatTarget) and IsValid(ply.RevengeTarget) then
        if ply.RevengeTarget:IsPlayer() and ply.RevengeTarget:Alive() then
            ply.CombatTarget = ply.RevengeTarget
            ply.LastKnownTargetPos = ply.RevengeTarget:GetPos()
            ply.BotState = "Combat"
            ForceEquipGun(ply)
            
            if math.random(100) < 50 then
                BotTextReply(ply, revengeTauntPhrases[math.random(#revengeTauntPhrases)], ply.RevengeTarget)
            end
            
            ply.RevengeTarget = nil
        else
            ply.RevengeTarget = nil
        end
    end

    if not IsValid(ply.CombatTarget) or (ply.CombatTarget:IsNPC() and not ply.CombatTarget:Alive()) or (ply.CombatTarget:IsPlayer() and not ply.CombatTarget:Alive()) then
        ply.CombatTarget = nil
        ply.LastKnownTargetPos = nil
        if ply.BotState == "Combat" or ply.BotState == "Retreating" or ply.BotState == "Searching" then 
            ply.BotState = "Wandering" 
        end

        if ply.KnownAggressors then
            for aggressor, isKnown in pairs(ply.KnownAggressors) do
                if isKnown and IsValid(aggressor) and aggressor:Alive() and ply:GetPos():Distance(aggressor:GetPos()) < 4000 then
                    ply.CombatTarget = aggressor
                    ply.LastKnownTargetPos = aggressor:GetPos()
                    if ply:Health() < RETREAT_HP_THRESHOLD then
                        ply.BotState = "Retreating"
                    else
                        ply.BotState = "Combat"
                    end
                    ForceEquipGun(ply)
                    break
                end
            end
        end

        if not IsValid(ply.CombatTarget) then
            local searchRadius = 3500
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), searchRadius)) do
                if IsValid(ent) and ent:GetClass() == "custom_hostile_dummy" then 
                    local tr = util.TraceLine({
                        start = ply:GetShootPos(),
                        endpos = ent:GetPos(),
                        filter = ply
                    })
                    if tr.Entity == ent or tr.Fraction > 0.8 then
                        ply.CombatTarget = ent
                        ply.LastKnownTargetPos = ent:GetPos()
                        ply.BotState = "Combat"
                        ForceEquipGun(ply)
                        break
                    end
                end
            end
        end
    end

    if IsValid(ply.CombatTarget) and ply.CombatTarget:IsPlayer() then
        local targetWep = ply.CombatTarget:GetActiveWeapon()
        local holdingCrossbowAtBot = IsValid(targetWep) and targetWep:GetClass() == "weapon_crossbow" and IsAimingCrossbowAtBot(ply, ply.CombatTarget)
        
        if not holdingCrossbowAtBot then
            local isOnlyCrossbowThreat = true
            if ply.KnownAggressors and ply.KnownAggressors[ply.CombatTarget] then
                isOnlyCrossbowThreat = false
            end

            if isOnlyCrossbowThreat then
                BotTextReply(ply, forgivenessPhrases[math.random(#forgivenessPhrases)])
                ply.CombatTarget = nil
                ply.LastKnownTargetPos = nil
                ply.BotState = "Wandering"
            else
                ply.LastDamagedByEnemyTime = ply.LastDamagedByEnemyTime or CurTime()
                ply.NextForgivenessCheck = ply.NextForgivenessCheck or (CurTime() + 4)

                if CurTime() - ply.LastDamagedByEnemyTime > 7 then
                    if CurTime() > ply.NextForgivenessCheck then
                        ply.NextForgivenessCheck = CurTime() + 5

                        ply.TotalAttacksReceived = ply.TotalAttacksReceived or 1
                        local grudgeChance = math.Clamp(ply.TotalAttacksReceived * 8, 15, 85)
                        
                        if math.random(100) > grudgeChance then
                            BotTextReply(ply, forgivenessPhrases[math.random(#forgivenessPhrases)])
                            if ply.KnownAggressors then
                                ply.KnownAggressors[ply.CombatTarget] = nil
                            end
                            ply.CombatTarget = nil
                            ply.LastKnownTargetPos = nil
                            ply.BotState = "Wandering"
                        else
                            local targetName = ply.CombatTarget:Nick()
                            BotTextReply(ply, "Alright, no more warnings! Square up, " .. targetName .. "!")
                            ply.BotState = "Combat"
                            ForceEquipGun(ply)
                        end
                    end
                end
            end
        end
    end

    if IsValid(ply.CombatTarget) and ply.CombatTarget:IsPlayer() then
        local targetWep = ply.CombatTarget:GetActiveWeapon()
        local holdingCrossbowAtBot = IsValid(targetWep) and targetWep:GetClass() == "weapon_crossbow" and IsAimingCrossbowAtBot(ply, ply.CombatTarget)
        
        if not holdingCrossbowAtBot then
            local isOnlyCrossbowThreat = true
            if ply.KnownAggressors and ply.KnownAggressors[ply.CombatTarget] then
                isOnlyCrossbowThreat = false
            end

            if isOnlyCrossbowThreat then
                BotTextReply(ply, forgivenessPhrases[math.random(#forgivenessPhrases)])
                ply.CombatTarget = nil
                ply.LastKnownTargetPos = nil
                ply.BotState = "Wandering"
            else
                ply.LastDamagedByEnemyTime = ply.LastDamagedByEnemyTime or CurTime()
                ply.NextForgivenessCheck = ply.NextForgivenessCheck or (CurTime() + 4)

                if CurTime() - ply.LastDamagedByEnemyTime > 7 then
                    if CurTime() > ply.NextForgivenessCheck then
                        ply.NextForgivenessCheck = CurTime() + 5

                        ply.TotalAttacksReceived = ply.TotalAttacksReceived or 1
                        local grudgeChance = math.Clamp(ply.TotalAttacksReceived * 8, 15, 85)
                        
                        if math.random(100) > grudgeChance then
                            BotTextReply(ply, forgivenessPhrases[math.random(#forgivenessPhrases)])
                            if ply.KnownAggressors then
                                ply.KnownAggressors[ply.CombatTarget] = nil
                            end
                            ply.CombatTarget = nil
                            ply.LastKnownTargetPos = nil
                            ply.BotState = "Wandering"
                        else
                            local targetName = ply.CombatTarget:Nick()
                            BotTextReply(ply, "Alright, no more warnings! Square up, " .. targetName .. "!")
                            ply.BotState = "Combat"
                            ForceEquipGun(ply)
                        end
                    end
                end
            end
        end
    end

    if IsValid(ply.CombatTarget) and ply.BotState ~= "Retreating" then
        if ply.CombatTarget:IsPlayer() or ply.CombatTarget:GetClass() == "custom_hostile_dummy" then
            if HasLineOfSight(ply, ply.CombatTarget) then
                ply.LastKnownTargetPos = ply.CombatTarget:GetPos()
                ply.BotState = "Combat"
                ply.LostSightTimer = nil
            else
                ply.LostSightTimer = ply.LostSightTimer or CurTime()
                if CurTime() - ply.LostSightTimer > 1.5 then
                    ply.BotState = "Searching"
                end
            end
        end
    end

    if (ply.BotState == "Combat" or ply.BotState == "Wandering" or ply.BotState == "Searching") and IsValid(ply.CombatTarget) and ply:Health() < RETREAT_HP_THRESHOLD then
        ply.BotState = "Retreating"
        ply.NextRetreatSay = ply.NextRetreatSay or 0
        if CurTime() > ply.NextRetreatSay then
            ply.NextRetreatSay = CurTime() + 10
            BotTextReply(ply, retreatPhrases[math.random(#retreatPhrases)])
        end
    end

    if ply.BotState == "Retreating" then
        if not IsValid(ply.CombatTarget) or ply:Health() >= HEALTH_RECOVERY_THRESHOLD or ply:GetPos():Distance(ply.CombatTarget:GetPos()) > 4000 then
            if ply:Health() < HEALTH_RECOVERY_THRESHOLD and IsValid(ply.CombatTarget) then
                ply.BotState = "Combat"
            else
                ply.BotState = "Wandering"
            end
        end
    end

    currentButtons = tonumber(cmd:GetButtons() or 0) or 0

    if ply.BotState == "Retreating" and IsValid(ply.CombatTarget) then
        ForceEquipGun(ply)

        local targetPos = ply.CombatTarget:IsPlayer() and ply.CombatTarget:GetShootPos() or ply.CombatTarget:GetPos()
        local rawAimAngle = (targetPos - ply:GetShootPos()):Angle()
        local smoothAimAngle = LerpAngle(0.15, ply:EyeAngles(), rawAimAngle)
        smoothAimAngle.p = math.Clamp(smoothAimAngle.p, -75, 75)
        smoothAimAngle.r = 0
        
        cmd:SetViewAngles(smoothAimAngle)
        ply:SetEyeAngles(smoothAimAngle)

        if HasLineOfSight(ply, ply.CombatTarget) then
            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) then
                if activeWep:GetClass() == "weapon_pistol" then
                    ply.NextPistolSpam = ply.NextPistolSpam or 0
                    if CurTime() > ply.NextPistolSpam then
                        ply.PistolSpamToggle = not (ply.PistolSpamToggle or false)
                        ply.NextPistolSpam = CurTime() + math.Rand(0.08, 0.16)
                    end
                    if ply.PistolSpamToggle then
                        currentButtons = bit.bor(currentButtons, IN_ATTACK)
                    else
                        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
                    end
                elseif activeWep:GetClass() == "weapon_shotgun" then
                    currentButtons = bit.bor(currentButtons, IN_ATTACK)
                    if math.random(100) < 30 then
                        currentButtons = bit.bor(currentButtons, IN_ATTACK2)
                    else
                        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
                    end
                else
                    currentButtons = bit.bor(currentButtons, IN_ATTACK)
                end
            end
        else
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
        end

        currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))

        ply.RetreatCycleTimer = ply.RetreatCycleTimer or CurTime()
        ply.RetreatMode = ply.RetreatMode or "Bhop"

        if CurTime() > ply.RetreatCycleTimer then
            ply.RetreatCycleTimer = CurTime() + 1.0
            if ply.RetreatMode == "Bhop" then ply.RetreatMode = "Run" else ply.RetreatMode = "Bhop" end
        end

        if ply.RetreatMode == "Bhop" then
            ply.WasOnGroundLastFrameRetreat = ply.WasOnGroundLastFrameRetreat or false
            local isOnGroundNowRetreat = ply:IsOnGround()

            if isOnGroundNowRetreat then
                if not ply.WasOnGroundLastFrameRetreat then
                    currentButtons = bit.bor(currentButtons, IN_JUMP)
                else
                    currentButtons = bit.band(currentButtons, bit.bnot(IN_JUMP))
                end
                currentButtons = bit.bor(currentButtons, IN_SPEED)
            else
                currentButtons = bit.band(currentButtons, bit.bnot(IN_JUMP))
            end
            ply.WasOnGroundLastFrameRetreat = isOnGroundNowRetreat
        else
            currentButtons = bit.band(currentButtons, bit.bnot(IN_JUMP))
            currentButtons = bit.bor(currentButtons, IN_SPEED)
            ply.WasOnGroundLastFrameRetreat = false
        end

        cmd:SetForwardMove(-400)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    local activeWep = ply:GetActiveWeapon()
    if ply.BotState == "Combat" and IsValid(ply.CombatTarget) and IsValid(activeWep) and activeWep:GetClass() == "weapon_physcannon" then
        local targetPos = ply.CombatTarget:IsPlayer() and ply.CombatTarget:GetShootPos() or ply.CombatTarget:GetPos()
        local rawAimAngle = (targetPos - ply:GetShootPos()):Angle()
        local smoothAimAngle = LerpAngle(0.2, ply:EyeAngles(), rawAimAngle)
        smoothAimAngle.p = math.Clamp(smoothAimAngle.p, -75, 75)
        smoothAimAngle.r = 0
        cmd:SetViewAngles(smoothAimAngle)
        ply:SetEyeAngles(smoothAimAngle)

        if IsValid(ply.HeldProp) then
            currentButtons = bit.bor(currentButtons, IN_ATTACK2)
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
            ply.HeldProp = nil
        else
            local nearbyProps = ents.FindInSphere(ply:GetPos(), 250)
            local foundProp = nil
            for _, prop in ipairs(nearbyProps) do
                if IsValid(prop) and prop:GetClass() == "prop_physics" then
                    local phys = prop:GetPhysicsObject()
                    if IsValid(phys) and phys:IsMoveable() then
                        foundProp = prop
                        break
                    end
                end
            end

            if IsValid(foundProp) then
                local propAim = (foundProp:GetPos() - ply:GetShootPos()):Angle()
                propAim.r = 0
                cmd:SetViewAngles(propAim)
                ply:SetEyeAngles(propAim)

                currentButtons = bit.bor(currentButtons, IN_ATTACK)
                ply.HeldProp = foundProp
            else
                currentButtons = bit.bor(currentButtons, IN_ATTACK2)
                if math.random(100) < 10 then
                    HandleBotAmmoAndWeapons(ply)
                end
            end
        end

        cmd:SetForwardMove(200)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    if ply.BotState == "Combat" and IsValid(ply.CombatTarget) then
        ForceEquipGun(ply)

        local targetPos = ply.CombatTarget:IsPlayer() and ply.CombatTarget:GetShootPos() or ply.CombatTarget:GetPos()
        
        if ply.FlankMode and ply.FlankOffset then
            targetPos = targetPos + ply.FlankOffset
        end

        local rawAimAngle = (targetPos - ply:GetShootPos()):Angle()
        local smoothAimAngle = LerpAngle(0.18, ply:EyeAngles(), rawAimAngle)
        smoothAimAngle.p = math.Clamp(smoothAimAngle.p, -75, 75)
        smoothAimAngle.r = 0
        
        cmd:SetViewAngles(smoothAimAngle)
        ply:SetEyeAngles(smoothAimAngle)

        if HasLineOfSight(ply, ply.CombatTarget) then
            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) then
                if activeWep:GetClass() == "weapon_pistol" then
                    ply.NextPistolSpam = ply.NextPistolSpam or 0
                    if CurTime() > ply.NextPistolSpam then
                        ply.PistolSpamToggle = not (ply.PistolSpamToggle or false)
                        ply.NextPistolSpam = CurTime() + math.Rand(0.08, 0.16)
                    end
                    if ply.PistolSpamToggle then
                        currentButtons = bit.bor(currentButtons, IN_ATTACK)
                    else
                        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
                    end
                elseif activeWep:GetClass() == "weapon_shotgun" then
                    currentButtons = bit.bor(currentButtons, IN_ATTACK)
                    local distToEnemy = ply:GetPos():Distance(targetPos)
                    if distToEnemy < 400 and math.random(100) < 40 then
                        currentButtons = bit.bor(currentButtons, IN_ATTACK2)
                    else
                        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
                    end
                else
                    currentButtons = bit.bor(currentButtons, IN_ATTACK)
                end
            end
        else
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
        end

        currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))

        local distToEnemy = ply:GetPos():Distance(targetPos)
        local forwardVelocity = 0

        local isTargetingWithCrossbow = ply.CombatTarget:IsPlayer() and IsAimingCrossbowAtBot(ply, ply.CombatTarget)
        if isTargetingWithCrossbow then
            currentButtons = bit.bor(currentButtons, IN_SPEED)
            if ply:IsOnGround() and math.random(100) < 25 then
                currentButtons = bit.bor(currentButtons, IN_JUMP)
            end
            if math.random(100) < 20 then
                currentButtons = bit.bor(currentButtons, IN_DUCK)
            end
            forwardVelocity = math.random(-300, 300)
        else
            if distToEnemy > 800 then
                forwardVelocity = 400
                currentButtons = bit.bor(currentButtons, IN_SPEED)
            elseif distToEnemy < 300 then
                forwardVelocity = -250
            end
        end

        ply.StrafeTimer = ply.StrafeTimer or CurTime()
        ply.StrafeDir = ply.StrafeDir or 1
        if CurTime() > ply.StrafeTimer then
            ply.StrafeTimer = CurTime() + math.Rand(0.4, isTargetingWithCrossbow and 1.2 or 3)
            ply.StrafeDir = ply.StrafeDir * -1
            if isTargetingWithCrossbow and math.random(100) < 50 then
                ply.StrafeDir = ply.StrafeDir * -1 
            end
        end

        cmd:SetForwardMove(forwardVelocity)
        cmd:SetSideMove((isTargetingWithCrossbow and 400 or 250) * ply.StrafeDir)
        cmd:SetButtons(currentButtons)
        return
    end

    if ply.BotState == "Searching" then
        ForceEquipGun(ply)

        if not ply.LastKnownTargetPos then
            ply.BotState = "Wandering"
            return
        end

        ply.NextPathUpdate = ply.NextPathUpdate or 0
        if CurTime() > ply.NextPathUpdate then
            ply.NextPathUpdate = CurTime() + 1.0
            ply.NavPath = CalculateNavPath(ply:GetPos(), ply.LastKnownTargetPos)
        end

        local targetWaypoint = ply.LastKnownTargetPos
        if ply.NavPath and #ply.NavPath > 0 then
            targetWaypoint = ply.NavPath[1]
            if ply:GetPos():Distance(targetWaypoint) < 60 then
                table.remove(ply.NavPath, 1)
            end
        end

        local rawAimAngle = (targetWaypoint - ply:GetShootPos()):Angle()
        local smoothAimAngle = LerpAngle(0.1, ply:EyeAngles(), rawAimAngle)
        smoothAimAngle.p = math.Clamp(smoothAimAngle.p, -60, 60)
        smoothAimAngle.r = 0
        
        cmd:SetViewAngles(smoothAimAngle)
        ply:SetEyeAngles(smoothAimAngle)

        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK2))
        currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))

        local distToLastPos = ply:GetPos():Distance(ply.LastKnownTargetPos)
        if distToLastPos < 120 then
            ply.SearchWaitTimer = ply.SearchWaitTimer or (CurTime() + 4)
            if CurTime() > ply.SearchWaitTimer then
                ply.SearchWaitTimer = nil
                ply.BotState = "Wandering"
                ply.CombatTarget = nil
                ply.LastKnownTargetPos = nil
                ply.NavPath = nil
            end
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
            cmd:SetButtons(currentButtons)
            return
        end

        currentButtons = bit.bor(currentButtons, IN_SPEED)
        cmd:SetForwardMove(400)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    ply.NextGestureCheck = ply.NextGestureCheck or (CurTime() + math.Rand(15, 30))
    if CurTime() > ply.NextGestureCheck then
        ply.NextGestureCheck = CurTime() + math.Rand(25, 50)
        if math.random(100) < 40 then
            PerformBotGesture(ply)
        end
    end

    ply.NextItemScan = ply.NextItemScan or 0
    if CurTime() > ply.NextItemScan then
        ply.NextItemScan = CurTime() + 2
        local needsHealth = ply:Health() < 85
        local needsArmor = ply:Armor() < 50
        
        if (needsHealth or needsArmor) and not IsValid(ply.TargetPlayerToApproach) then
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 600)) do
                if IsValid(ent) then
                    local class = ent:GetClass()
                    if ((class == "item_healthvial" or class == "item_healthkit") and needsHealth) or (class == "item_battery" and needsArmor) then
                        ply.TargetItem = ent
                        break
                    end
                end
            end
        else
            ply.TargetItem = nil
        end
    end

    ply.NextMenuCheck = ply.NextMenuCheck or CurTime() + 3
    ply.IsBrowsingMenu = ply.IsBrowsingMenu or false
    ply.MenuEndTime = ply.MenuEndTime or 0

    if ply.IsBrowsingMenu then
        if CurTime() > ply.MenuEndTime then
            ply.IsBrowsingMenu = false
            ply.NextMenuCheck = CurTime() + math.random(10, 25)
        else
            local menuAngle = Angle(25, ply:EyeAngles().y, 0)
            local smoothMenuAngle = LerpAngle(0.1, ply:EyeAngles(), menuAngle)
            cmd:SetViewAngles(smoothMenuAngle)
            ply:SetEyeAngles(smoothMenuAngle)

            currentButtons = bit.bor(currentButtons, IN_CONTEXTMENU)
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
            cmd:SetButtons(currentButtons)
            return
        end
    else
        if CurTime() > ply.NextMenuCheck then
            if math.random(100) < 35 then
                ply.IsBrowsingMenu = true
                ply.MenuEndTime = CurTime() + math.random(3, 7)
            else
                ply.NextMenuCheck = CurTime() + math.random(8, 15)
            end
        end
    end

    ply.NextCameraAction = ply.NextCameraAction or 0
    local activeWep = ply:GetActiveWeapon()
    if IsValid(activeWep) and activeWep:GetClass() == "gmod_camera" then
        if CurTime() > ply.NextCameraAction then
            ply.NextCameraAction = CurTime() + math.random(4, 9)
            currentButtons = bit.bor(currentButtons, IN_ATTACK)
            
            if math.random(100) < 30 then
                BotTextReply(ply, cameraChatPhrases[math.random(#cameraChatPhrases)])
            end
        else
            currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
        end
    else
        currentButtons = bit.band(currentButtons, bit.bnot(IN_ATTACK))
    end

    if _G.SB_BOT_CHAT_ENABLED then
        ply.NextChatTime = ply.NextChatTime or CurTime() + math.Rand(20, 60)
        if CurTime() > ply.NextChatTime then
            ply.NextChatTime = CurTime() + math.Rand(40, 120)
            if math.random(100) < 40 then
                if math.random(100) < 30 then
                    local chosenAfkText = afkTriggerPhrases[math.random(#afkTriggerPhrases)]
                    BotTextReply(ply, chosenAfkText)
                    
                    ply.IsAFK = true
                    ply.AfkEndTime = CurTime() + math.random(15, 30)
                else
                    BotTextReply(ply, randomChatPhrases[math.random(#randomChatPhrases)])
                end
            end
        end
    end

    ply.NextLocomotionSwitch = ply.NextLocomotionSwitch or CurTime()
    ply.CurrentLocomotionState = ply.CurrentLocomotionState or "Walk"

    if CurTime() > ply.NextLocomotionSwitch then
        local randRoll = math.Rand(0, 100)
        if IsValid(ply.TargetItem) or IsValid(ply.TargetPlayerToApproach) then
            ply.CurrentLocomotionState = "Run"
            ply.NextLocomotionSwitch = CurTime() + 4
        elseif randRoll < 30 then
            ply.CurrentLocomotionState = "SlowWalk"
            ply.NextLocomotionSwitch = CurTime() + math.Rand(5, 10)
        elseif randRoll < 55 then
            ply.CurrentLocomotionState = "Walk"
            ply.NextLocomotionSwitch = CurTime() + math.Rand(5, 10)
        elseif randRoll < 75 then
            ply.CurrentLocomotionState = "Run"
            ply.NextLocomotionSwitch = CurTime() + math.Rand(3, 6)
        elseif randRoll < 88 then
            ply.CurrentLocomotionState = "CrouchWalk"
            ply.NextLocomotionSwitch = CurTime() + math.Rand(3, 6)
        else
            ply.CurrentLocomotionState = "Idle"
            ply.NextLocomotionSwitch = CurTime() + math.Rand(4, 9)
        end
    end

    currentButtons = tonumber(cmd:GetButtons() or 0) or 0
    local currentSpeed = 250
    currentButtons = bit.band(currentButtons, bit.bnot(IN_SPEED))
    currentButtons = bit.band(currentButtons, bit.bnot(IN_DUCK))
    currentButtons = bit.band(currentButtons, bit.bnot(IN_WALK))

    if ply.CurrentLocomotionState == "Idle" then
        ply.NextIdleLookShift = ply.NextIdleLookShift or 0
        ply.IdleTargetAngle = ply.IdleTargetAngle or ply:EyeAngles()
        
        if CurTime() > ply.NextIdleLookShift then
            ply.NextIdleLookShift = CurTime() + math.Rand(2, 5)
            local currentAng = ply:EyeAngles()
            ply.IdleTargetAngle = Angle(math.Clamp(currentAng.p + math.Rand(-15, 15), -35, 45), currentAng.y + math.Rand(-40, 40), 0)
        end
        
        local smoothIdleAng = LerpAngle(0.06, ply:EyeAngles(), ply.IdleTargetAngle)
        cmd:SetViewAngles(smoothIdleAng)
        ply:SetEyeAngles(smoothIdleAng)

        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetButtons(currentButtons)
        return
    end

    ply.NextNavCompute = ply.NextNavCompute or 0
    if CurTime() > ply.NextNavCompute or not ply.NavPath or #ply.NavPath == 0 then
        ply.NextNavCompute = CurTime() + math.Rand(5, 10)
        
        local destinationPos = nil
        if IsValid(ply.TargetItem) then
            destinationPos = ply.TargetItem:GetPos()
        elseif IsValid(ply.TargetPlayerToApproach) then
            if ply:GetPos():Distance(ply.TargetPlayerToApproach:GetPos()) < 100 then
                ply.TargetPlayerToApproach = nil
            else
                destinationPos = ply.TargetPlayerToApproach:GetPos()
            end
        else
            if navmesh.IsLoaded() then
                local allAreas = navmesh.GetAllNavAreas()
                if allAreas and #allAreas > 0 then
                    local randomArea = allAreas[math.random(#allAreas)]
                    if IsValid(randomArea) then
                        destinationPos = randomArea:GetCenter()
                    end
                end
            end
        end

        if destinationPos then
            ply.NavPath = CalculateNavPath(ply:GetPos(), destinationPos)
        else
            ply.NavPath = nil
        end
    end

    local targetWaypoint = nil
    if ply.NavPath and #ply.NavPath > 0 then
        targetWaypoint = ply.NavPath[1]
        if ply:GetPos():Distance(targetWaypoint) < 60 then
            table.remove(ply.NavPath, 1)
            if #ply.NavPath > 0 then
                targetWaypoint = ply.NavPath[1]
            end
        end
    end

    if not targetWaypoint then
        ply.FallbackWanderTimer = ply.FallbackWanderTimer or 0
        if CurTime() > ply.FallbackWanderTimer then
            ply.FallbackWanderTimer = CurTime() + math.Rand(3, 6)
            ply.FallbackWanderAngle = (ply:GetAngles() + Angle(0, math.Rand(-90, 90), 0)):Forward()
        end
        targetWaypoint = ply:GetPos() + (ply.FallbackWanderAngle or ply:GetForward()) * 300
    end

    ply.PropAvoidanceDir = ply.PropAvoidanceDir or 0
    ply.PropAvoidanceTimer = ply.PropAvoidanceTimer or 0
    
    local forwardTracePos = ply:GetPos() + Vector(0, 0, 15)
    local traceForward = util.TraceLine({
        start = forwardTracePos,
        endpos = forwardTracePos + ply:GetForward() * 65,
        filter = ply,
        mask = MASK_PLAYERSOLID
    })

    if traceForward.Hit and IsValid(traceForward.Entity) and (traceForward.Entity:GetClass() == "prop_physics" or traceForward.Entity:IsNPC() or traceForward.Entity:IsPlayer()) then
        if CurTime() > ply.PropAvoidanceTimer then
            ply.PropAvoidanceTimer = CurTime() + 0.6
            ply.PropAvoidanceDir = (math.random(1, 2) == 1) and 400 or -400
        end
        
        if ply:IsOnGround() then
            currentButtons = bit.bor(currentButtons, IN_JUMP)
            currentButtons = bit.bor(currentButtons, IN_DUCK)
        end
        
        cmd:SetSideMove(ply.PropAvoidanceDir)
        cmd:SetForwardMove(200)
        cmd:SetButtons(currentButtons)
        return
    end

    local rawMoveAngle = (targetWaypoint - ply:GetShootPos()):Angle()
    
    ply.MovePitchOffset = ply.MovePitchOffset or 0
    ply.NextPitchChange = ply.NextPitchChange or 0
    if CurTime() > ply.NextPitchChange then
        ply.NextPitchChange = CurTime() + math.Rand(2, 4)
        ply.MovePitchOffset = math.Rand(-8, 12)
    end

    rawMoveAngle.p = ply.MovePitchOffset
    rawMoveAngle.r = 0

    local smoothWanderAngle = LerpAngle(0.08, ply:EyeAngles(), rawMoveAngle)

    cmd:SetViewAngles(smoothWanderAngle)
    ply:SetEyeAngles(smoothWanderAngle)

    if ply.CurrentLocomotionState == "Run" then
        currentSpeed = 400
        currentButtons = bit.bor(currentButtons, IN_SPEED)
    elseif ply.CurrentLocomotionState == "Walk" then
        currentSpeed = 250
    elseif ply.CurrentLocomotionState == "SlowWalk" then
        currentSpeed = 200
        currentButtons = bit.bor(currentButtons, IN_WALK)
    elseif ply.CurrentLocomotionState == "CrouchWalk" then
        currentSpeed = 130
        currentButtons = bit.bor(currentButtons, IN_DUCK)
    end

    ply.NextJumpAttempt = ply.NextJumpAttempt or 0
    if ply:IsOnGround() and CurTime() > ply.NextJumpAttempt and ply.CurrentLocomotionState ~= "CrouchWalk" and ply.CurrentLocomotionState ~= "Idle" then
        ply.NextJumpAttempt = CurTime() + math.Rand(2, 6)
        local jumpRoll = math.random(100)
        
        if jumpRoll < 25 then
            currentButtons = bit.bor(currentButtons, IN_JUMP)
            if math.random(100) < 40 then
                currentButtons = bit.bor(currentButtons, IN_DUCK)
            end
        end
    end

    cmd:SetButtons(currentButtons)
    cmd:SetForwardMove(currentSpeed)

    ply.NextButtonInteractionCheck = ply.NextButtonInteractionCheck or 0
    if CurTime() > ply.NextButtonInteractionCheck then
        ply.NextButtonInteractionCheck = CurTime() + 0.5
        ply.TargetInteractable = nil

        local searchRadius = 120
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), searchRadius)) do
            if IsValid(ent) then
                local class = ent:GetClass()
                if class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating" or class == "func_button" then
                    ply.TargetInteractable = ent
                    break
                end
            end
        end
    end

    if IsValid(ply.TargetInteractable) then
        local targetPos = ply.TargetInteractable:GetPos()
        local rawInteractAngle = (targetPos - ply:GetShootPos()):Angle()
        rawInteractAngle.p = math.Clamp(rawInteractAngle.p, -45, 45)
        rawInteractAngle.r = 0

        local smoothInteractAngle = LerpAngle(0.2, ply:EyeAngles(), rawInteractAngle)
        cmd:SetViewAngles(smoothInteractAngle)
        ply:SetEyeAngles(smoothInteractAngle)

        currentButtons = tonumber(cmd:GetButtons() or 0) or 0
        currentButtons = bit.bor(currentButtons, IN_USE)
        
        cmd:SetForwardMove(150)
        cmd:SetButtons(currentButtons)
        return
    end

end)

local function SafeVectorParse(str)
    if not isstring(str) or str == "" then return nil end
    local parts = string.Explode(" ", str)
    if #parts >= 3 then
        local r, g, b = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
        if r and g and b then return Vector(r, g, b) end
    elseif #parts == 1 then
        local v = Vector(str)
        if v then return v end
    end
    return nil
end

hook.Add("PlayerSpawn", "FixRealPlayerCustomizationReset", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if ply:IsBot() then
        if _G.PendingCustomBots and _G.PendingCustomBots[ply:Name()] then
            ply:SetNWBool("IsCustomSandboxBot", true)
            
            if _G.PendingCustomBotConfigs and _G.PendingCustomBotConfigs[ply:Name()] then
                local config = _G.PendingCustomBotConfigs[ply:Name()]
                ply.PersistentModel = config.model
                ply.PersistentColor = config.pColor
                _G.PendingCustomBotConfigs[ply:Name()] = nil
            end
            
            _G.PendingCustomBots[ply:Name()] = nil
        end

        if ply:GetNWBool("IsCustomSandboxBot", false) then
            ply.CurrentLocomotionState = "Walk"
            ply.BotState = "Wandering"
            ply.CombatTarget = nil
            ply.HeldProp = nil
            ply.LastKnownTargetPos = nil
            ply.LostSightTimer = nil
            ply.TargetItem = nil
            ply.TargetPlayerToApproach = nil
            ply.KnownAggressors = {}
            ply.LastDamagedByEnemyTime = 0
            ply.WasOnGroundLastFrameRetreat = false
            ply.RetreatCycleTimer = 0
            ply.RetreatMode = "Bhop"
            ply.TotalAttacksReceived = 0
            ply.DetectedGrenade = nil
            ply.NavPath = nil
            ply.IsAFK = false
            ply.AfkEndTime = 0
            ply.DiedWhileAfk = false
            ply.IsBrowsingMenu = false
            ply.MenuEndTime = 0
            ply.IsNoclipActive = false
            ply.IsLadderActive = false
            ply.WasFallingFast = false
            ply.IsTypingMessage = false
            ply.FlankMode = false
            ply.FlankOffset = nil
            ply:SetMoveType(MOVETYPE_WALK)
            
            if ply.PersistentModel and util.IsValidModel(ply.PersistentModel) then
                util.PrecacheModel(ply.PersistentModel)
                ply:SetModel(ply.PersistentModel)
            end
            
            if ply.PersistentColor then
                ply:SetPlayerColor(ply.PersistentColor)
                ply:SetWeaponColor(ply.PersistentColor)
                timer.Simple(0.05, function()
                    if IsValid(ply) then
                        ply:SetPlayerColor(ply.PersistentColor)
                        ply:SetWeaponColor(ply.PersistentColor)
                    end
                end)
            end
            
            ply:Give("weapon_physgun")
            ply:Give("weapon_physcannon")
            ply:Give("gmod_tool")
            ply:SelectWeapon("weapon_physgun")

            ply:SetNoDraw(false)
            ply:SetNotSolid(false)
            return
        end
    end

    timer.Simple(0.15, function()
        if not IsValid(ply) then return end

        local savedModel = ply:GetInfo("cl_playermodel")
        if isstring(savedModel) and savedModel ~= "" then
            util.PrecacheModel(savedModel)
            if util.IsValidModel(savedModel) then
                ply:SetModel(savedModel)
            end
        end

        local savedColorStr = ply:GetInfo("cl_playercolor")
        local parsedColor = SafeVectorParse(savedColorStr)
        if parsedColor then
            ply:SetPlayerColor(parsedColor)
        end

        local savedWeaponColorStr = ply:GetInfo("cl_weaponcolor")
        local parsedWeaponColor = SafeVectorParse(savedWeaponColorStr)
        if parsedWeaponColor then
            ply:SetWeaponColor(parsedWeaponColor)
        end
    end)
end)

hook.Add("PlayerSetModel", "SandboxBotEnforcePersistentModel", function(ply)
    if IsValid(ply) and ply:IsBot() and ply:GetNWBool("IsCustomSandboxBot", false) then
        if ply.PersistentModel and util.IsValidModel(ply.PersistentModel) then
            ply:SetModel(ply.PersistentModel)
            return true 
        end
    end
end)

hook.Add("PlayerDeath", "SandboxBotAutoRespawn", function(victim, inflictor, attacker)
    if IsValid(victim) and victim:IsPlayer() and victim:IsBot() and victim:GetNWBool("IsCustomSandboxBot", false) then
        if victim.IsAFK then
            victim.DiedWhileAfk = true
        end

        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            victim.RevengeTarget = attacker
            
            victim.KnownAggressors = victim.KnownAggressors or {}
            victim.KnownAggressors[attacker] = true

            if attacker:IsBot() then
                print("[SandboxBots] " .. victim:Nick() .. " was killed by fellow bot " .. attacker:Nick() .. " and is planning revenge!")
            else
                print("[SandboxBots] " .. victim:Nick() .. " was killed by player " .. attacker:Nick() .. " and is planning revenge!")
            end

            ProcessPlayerRDMReport(victim, attacker)
        end

        if _G.SB_BOT_CHAT_ENABLED and victim.IsTypingMessage and math.random(100) < 70 then
            victim.IsTypingMessage = false
            local cutText = suddenDeathChatCuts[math.random(#suddenDeathChatCuts)]
            victim:Say(cutText)
        end

        local randomRespawnDelay = math.Rand(3.0, 9.0)

        timer.Simple(randomRespawnDelay, function()
            if IsValid(victim) and victim:IsPlayer() and not victim:Alive() then
                victim:Spawn()
            end
        end)
    end
end)

hook.Add("EntityTakeDamage", "SandboxBotDefenseTrigger", function(target, dmginfo)
    if IsValid(target) and target:IsPlayer() and target:IsBot() and target:GetNWBool("IsCustomSandboxBot", false) then
        
        if target.IsAFK then return end

        if target.BotState == "Retreating" then
            dmginfo:ScaleDamage(0.5)
        end

        local attacker = dmginfo:GetAttacker()
        
        if IsValid(attacker) and attacker:GetClass() == "custom_hostile_dummy" then
            target.CombatTarget = attacker
            target.LastKnownTargetPos = attacker:GetPos()
            target.LastDamagedByEnemyTime = CurTime()
            if target:Health() < 30 then
                target.BotState = "Retreating"
            else
                target.BotState = "Combat"
                ForceEquipGun(target)
                ShareTargetWithNearbyBots(target, attacker)
            end
            return
        end

        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then
            target.KnownAggressors = target.KnownAggressors or {}
            target.LastDamagedByEnemyTime = CurTime()
            target.TotalAttacksReceived = (target.TotalAttacksReceived or 0) + 1
            
            target.KnownAggressors[attacker] = true
            target.CombatTarget = attacker
            target.LastKnownTargetPos = attacker:GetPos()
            
            if target:Health() < 30 then
                target.BotState = "Retreating"
            else
                target.BotState = "Combat"
                ForceEquipGun(target)
                ShareTargetWithNearbyBots(target, attacker)
            end
        end
    end
end)

concommand.Add("SandboxBOTS_KickAll", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You must be an admin to kick sandbox bots.")
        return
    end

    local count = 0
    for _, bot in ipairs(player.GetAll()) do
        if IsValid(bot) and bot:IsBot() and bot:GetNWBool("IsCustomSandboxBot", false) then
            bot:Kick("Removed by Admin")
            count = count + 1
        end
    end
    print("[SandboxBots] Kicked " .. count .. " custom bots.")
end, nil, "Removes and kicks all active sandbox bots from the server.")

local function ScheduleNextVoice(bot)
    if not IsValid(bot) or not bot:IsPlayer() then return end
    
    local randomDelay = math.random(10, 30)
    
    timer.Create("BotVoiceInterval_" .. bot:EntIndex(), randomDelay, 1, function()
        if not IsValid(bot) then return end
        PlayBotVoiceClip(bot)
        ScheduleNextVoice(bot)
    end)
end

hook.Add("PlayerSpawn", "BotRandomVoiceSpawn", function(ply)
    if ply:IsBot() and ply:GetNWBool("IsCustomSandboxBot", false) then
        timer.Remove("BotVoiceInterval_" .. ply:EntIndex())
        
        timer.Create("BotVoiceInterval_" .. ply:EntIndex(), 5, 1, function()
            if IsValid(ply) then
                PlayBotVoiceClip(ply)
                ScheduleNextVoice(ply)
            end
        end)
    end
end)

hook.Add("PlayerDisconnected", "BotVoiceCleanup", function(ply)
    if ply:IsBot() then
        timer.Remove("BotVoiceInterval_" .. ply:EntIndex())
        timer.Remove("BotVoiceReset_" .. ply:EntIndex())
    end
end)

hook.Add("PlayerInitialSpawn", "SandboxBotAutoConvertVanillaBots", function(ply)
    if not IsValid(ply) or not ply:IsBot() then return end
    
    if not ply:GetNWBool("IsCustomSandboxBot", false) then
        ply:SetNWBool("IsCustomSandboxBot", true)
        
        if not botNames or #botNames == 0 then
            botNames = {"Bot"}
        end
        
        local letters = {"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
        local generatedName = botNames[math.random(#botNames)] .. "_" .. letters[math.random(#letters)]
        
        ply.PersistentName = generatedName
        
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            ply:SetName(ply.PersistentName)
            
            local allModels = player_manager.AllValidModels()
            local modelPaths = {}
            if allModels then
                for _, path in pairs(allModels) do
                    table.insert(modelPaths, path)
                end
            end
            
            if #modelPaths > 0 then
                local chosenModel = modelPaths[math.random(#modelPaths)]
                ply.PersistentModel = chosenModel
                util.PrecacheModel(chosenModel)
                ply:SetModel(chosenModel)
            end

            ply.PersistentColor = Vector(math.Rand(0.2, 1), math.Rand(0.2, 1), math.Rand(0.2, 1))
            ply:SetPlayerColor(ply.PersistentColor)
            ply:SetWeaponColor(ply.PersistentColor)
            
            ply:Give("weapon_physgun")
            ply:Give("weapon_physcannon")
            ply:Give("gmod_tool")
            ply:SelectWeapon("weapon_physgun")
            
            print("[SandboxBots] Successfully forced custom name and setup for: " .. ply.PersistentName)
        end)
    end
end)

hook.Add("Think", "SandboxBotEnforceCustomNames", function()
    for _, ply in ipairs(player.GetBots()) do
        if IsValid(ply) and ply:GetNWBool("IsCustomSandboxBot", false) and ply.PersistentName then
            if ply:GetName() ~= ply.PersistentName then
                ply:SetName(ply.PersistentName)
            end
        end
    end
end)

timer.Create("SandboxBotFullAssetSpawner", 5, 0, function()
    if not _G.SB_BOT_BUILDING_ENABLED then return end

    for _, bot in ipairs(player.GetAll()) do
        if IsValid(bot) and bot:IsBot() and bot:GetNWBool("IsCustomSandboxBot", false) and bot:Alive() then
            local spawnPos = bot:GetPos() + bot:GetForward() * 120 + Vector(0, 0, 10)
            local categoryChoice = math.random(1, 4)
            local isBotAdmin = bot:IsAdmin()

            if categoryChoice == 1 then
                local propModel = "models/props_junk/wood_crate001a.mdl"
                if spawnlist and spawnlist.GetCache then
                    local cachedProps = spawnlist.GetCache("models")
                    if cachedProps and #cachedProps > 0 then
                        local validModels = {}
                        for _, item in ipairs(cachedProps) do
                            local isAdminOnly = item.admin or item.AdminOnly
                            if item and item.model and util.IsValidModel(item.model) and (not isAdminOnly or isBotAdmin) then
                                table.insert(validModels, item.model)
                            end
                        end
                        if #validModels > 0 then
                            propModel = validModels[math.random(#validModels)]
                        end
                    end
                end

                if util.IsValidModel(propModel) then
                    util.PrecacheModel(propModel)
                    local prop = ents.Create("prop_physics")
                    if IsValid(prop) then
                        prop:SetModel(propModel)
                        prop:SetPos(spawnPos)
                        prop:Spawn()
                        local phys = prop:GetPhysicsObject()
                        if IsValid(phys) then phys:Wake() end
                        
                        undo.Create("Prop")
                            undo.SetPlayer(bot)
                            undo.AddEntity(prop)
                        undo.Finish()

                        if cleanup then cleanup.Add(bot, "props", prop) end
                    end
                end

            elseif categoryChoice == 2 then
                local ragdollModel = "models/player/kleiner.mdl"
                local allModels = player_manager.AllValidModels()
                local modelPaths = {}
                if allModels then
                    for _, path in pairs(allModels) do table.insert(modelPaths, path) end
                end
                
                if #modelPaths > 0 then
                    ragdollModel = modelPaths[math.random(#modelPaths)]
                end

                if util.IsValidModel(ragdollModel) then
                    util.PrecacheModel(ragdollModel)
                    local ragdoll = ents.Create("prop_ragdoll")
                    if IsValid(ragdoll) then
                        ragdoll:SetModel(ragdollModel)
                        ragdoll:SetPos(spawnPos)
                        ragdoll:Spawn()
                        local phys = ragdoll:GetPhysicsObject()
                        if IsValid(phys) then phys:Wake() end

                        undo.Create("Ragdoll")
                            undo.SetPlayer(bot)
                            undo.AddEntity(ragdoll)
                        undo.Finish()

                        if cleanup then cleanup.Add(bot, "ragdolls", ragdoll) end
                    end
                end

            elseif categoryChoice == 3 then
                local validEnts = {}
                if scripted_ents and scripted_ents.GetList then
                    for class, entTable in pairs(scripted_ents.GetList()) do
                        if entTable and entTable.t and entTable.t.Spawnable then
                            local isAdminOnly = entTable.t.AdminOnly or entTable.t.AdminSpawnable
                            if not isAdminOnly or isBotAdmin then
                                table.insert(validEnts, class)
                            end
                        end
                    end
                end

                if #validEnts > 0 then
                    local entClass = validEnts[math.random(#validEnts)]
                    local ent = ents.Create(entClass)
                    if IsValid(ent) then
                        ent:SetPos(spawnPos)
                        ent:Spawn()

                        undo.Create("Entity")
                            undo.SetPlayer(bot)
                            undo.AddEntity(ent)
                        undo.Finish()

                        if cleanup then cleanup.Add(bot, "entities", ent) end
                    end
                end

            elseif categoryChoice == 4 then
                local dummyModel = "models/props_combine/breenclock.mdl"
                util.PrecacheModel(dummyModel)
                local dummy = ents.Create("prop_physics")
                if IsValid(dummy) then
                    dummy:SetModel(dummyModel)
                    dummy:SetPos(spawnPos)
                    dummy:Spawn()
                    dummy:SetColor(Color(255, 100, 100))
                    
                    local phys = dummy:GetPhysicsObject()
                    if IsValid(phys) then phys:Wake() end

                    undo.Create("Training Dummy")
                        undo.SetPlayer(bot)
                        undo.AddEntity(dummy)
                    undo.Finish()

                    if cleanup then cleanup.Add(bot, "props", dummy) end
                end
            end
        end
    end
end)

local function GetAnyValidBotWeapon(bot)
    local weapons = bot:GetWeapons()
    if #weapons > 0 then
        local chosenWep = weapons[math.random(#weapons)]
        if IsValid(chosenWep) then
            return chosenWep:GetClass()
        end
    end
    return "weapon_pistol"
end

net.Receive("SetBotMuteState", function(len, ply)
    local targetBot = net.ReadEntity()
    local muteState = net.ReadBool()
    
    if IsValid(targetBot) and targetBot:IsBot() then
        targetBot.IsCustomMuted = muteState
        
        if muteState then
            targetBot:SetNWBool("BotIsTalking", false)
            timer.Remove("BotVoiceReset_" .. targetBot:EntIndex())
        end
    end
end)

concommand.Add("SandboxBOTS_ForceWeapon", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You must be an admin to use this command.")
        return
    end

    local weaponClass = args[1]
    local targetName = args[2]

    if not weaponClass or weaponClass == "" then
        local usageMsg = "Usage: SandboxBOTS_ForceWeapon <weapon_class> [optional_bot_name]"
        if IsValid(ply) then ply:ChatPrint(usageMsg) else print(usageMsg) end
        return
    end

    local count = 0
    for _, v in ipairs(player.GetAll()) do
        if v:IsBot() and v:GetNWBool("IsCustomSandboxBot", false) then
            if targetName and targetName ~= "" and not string.find(string.lower(v:Nick()), string.lower(targetName)) then
                continue
            end

            v:StripWeapons()
            v:Give(weaponClass)
            v:SelectWeapon(weaponClass)
            
            count = count + 1
        end
    end

    local msg = "Forced " .. count .. " bot(s) to equip weapon: " .. weaponClass
    if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
end, nil, "Forces all or a specific sandbox bot to equip a weapon.")

concommand.Add("sandboxbots_menu[WIP]", function(ply, cmd, args)
    net.Start("SandboxBots_OpenSpawnMenuRequest")
    net.SendToServer()
end, nil, "Opens the Sandbox Bot Customization & Spawn Menu")
-- Function to make a bot enter and drive a vehicle toward a target vector
function BotDriveTo(bot, vehicle, targetPos)
    if not IsValid(bot) or not IsValid(vehicle) then return end

    -- 1. Ensure the bot is inside the vehicle seat
    if vehicle:GetDriver() ~= bot then
        bot:EnterVehicle(vehicle)
    end

    -- 2. Calculate direction from vehicle to target position
    local vehPos = vehicle:GetPos()
    local dirToTarget = (targetPos - vehPos):GetNormalized()
    local forward = vehicle:GetForward()
    local right = vehicle:GetRight()

    -- 3. Determine Steering (-1 for full left, 1 for full right)
    local steerValue = right:Dot(dirToTarget)
    steerValue = math.Clamp(steerValue * 2.0, -1, 1) -- Adjust sensitivity

    -- 4. Determine Throttle (forward vs reverse)
    local forwardValue = forward:Dot(dirToTarget)
    local throttleValue = 0

    if forwardValue > 0.2 then
        throttleValue = 1 -- Drive forward
    elseif forwardValue < -0.2 then
        throttleValue = -1 -- Reverse if facing away
    end

    vehicle:SetSteering(steerValue, 0)
    vehicle:SetThrottle(throttleValue)
    
    vehicle:SetHandbrake(false)
end

hook.Add("Think", "BotVehicleAIUpdate", function()
    for _, bot in ipairs(player.GetBots()) do
        if IsValid(bot.MyAssignedVehicle) and IsValid(bot.MyTargetPosition) then
            BotDriveTo(bot, bot.MyAssignedVehicle, bot.MyTargetPosition)
        end
    end
end)
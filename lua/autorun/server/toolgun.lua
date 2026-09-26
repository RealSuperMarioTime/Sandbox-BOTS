-- ============================================================================
-- AUTONOMOUS BOT TOOL-GUN BEHAVIOR (WELD & REMOVE MODULE)
-- ============================================================================

local function RunBotToolActions(bot)
    if not IsValid(bot) or not bot:IsBot() or not bot:Alive() then return end
    
    local activeWep = bot:GetActiveWeapon()
    if not IsValid(activeWep) then return end
    
    local wepClass = activeWep:GetClass()
    if wepClass ~= "gmod_tool" and wepClass ~= "weapon_physgun" then return end

    bot.NextToolActionTime = bot.NextToolActionTime or 0
    if CurTime() < bot.NextToolActionTime then return end
    bot.NextToolActionTime = CurTime() + 1.5

    local startPos = bot:GetShootPos()
    local forward = bot:GetAimVector()
    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + forward * 200,
        filter = bot
    })

    if tr.Hit and IsValid(tr.Entity) then
        local targetEnt = tr.Entity
        
        if targetEnt:IsWorld() or targetEnt:IsPlayer() then return end

        bot:SetAnimation(PLAYER_ATTACK1)
        activeWep:EmitSound("weapons/airboat/airboat_gun_energy1.wav")

        local actionChoice = math.random(1, 2)
        
        if actionChoice == 1 then
            targetEnt:Remove()
        elseif actionChoice == 2 then
            local secondTr = util.TraceLine({
                start = tr.HitPos + Vector(0, 0, 20),
                endpos = tr.HitPos + Vector(0, 0, -100),
                filter = {bot, targetEnt}
            })
            
            if secondTr.Hit and IsValid(secondTr.Entity) and not secondTr.Entity:IsWorld() then
                constraint.Weld(targetEnt, secondTr.Entity, 0, 0, 0, true, false)
            end
        end
    end
end

hook.Add("StartCommand", "BotToolExecutionHook", function(ply, cmd)
    if IsValid(ply) and ply:IsBot() and ply:GetNWBool("IsCustomSandboxBot", false) then
        RunBotToolActions(ply)
    end
end)
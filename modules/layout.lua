local addonName, ns = ...

-- Función para posicionar los beneficios (buffs) del Objetivo y Foco
function ns.PositionTargetBuffs(self)
    if not self then self = TargetFrame end
    local frameName = self:GetName()
    if frameName ~= "TargetFrame" and frameName ~= "FocusFrame" then return end
    
    local healthBar = _G[frameName.."HealthBar"]
    if not healthBar then return end

    local AURA_SIZE = 22
    local SPACING = 2
    local MAX_PER_ROW = math.floor(ns.BAR_WIDTH / (AURA_SIZE + SPACING))
    
    local currentY = 18 -- Altura inicial por encima del nombre

    -- Posicionar Buffs
    local shownBuffs = 0
    local buffIndex = 1
    while _G[frameName.."Buff"..buffIndex] do
        local buff = _G[frameName.."Buff"..buffIndex]
        if buff:IsShown() then
            buff:ClearAllPoints()
            buff:SetSize(AURA_SIZE, AURA_SIZE) -- Estandarizar tamaño
            
            local col = shownBuffs % MAX_PER_ROW
            local row = math.floor(shownBuffs / MAX_PER_ROW)
            
            local currentX = col * (AURA_SIZE + SPACING)
            local yOffset = currentY + (row * (AURA_SIZE + SPACING))
            
            buff:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2 + currentX, yOffset)
            shownBuffs = shownBuffs + 1
        end
        buffIndex = buffIndex + 1
    end
    
    -- Calcular espacio para los debuffs
    if shownBuffs > 0 then
        local rowsUsed = math.ceil(shownBuffs / MAX_PER_ROW)
        currentY = currentY + (rowsUsed * (AURA_SIZE + SPACING)) + 5 -- gap de 5px
    end
    
    -- Posicionar Debuffs
    local shownDebuffs = 0
    local debuffIndex = 1
    while _G[frameName.."Debuff"..debuffIndex] do
        local debuff = _G[frameName.."Debuff"..debuffIndex]
        if debuff:IsShown() then
            debuff:ClearAllPoints()
            debuff:SetSize(AURA_SIZE + 4, AURA_SIZE + 4) -- Debuffs ligeramente más grandes
            
            local col = shownDebuffs % MAX_PER_ROW
            local row = math.floor(shownDebuffs / MAX_PER_ROW)
            
            -- Compensar el tamaño extra en el espaciado
            local currentX = col * (AURA_SIZE + 4 + SPACING)
            local yOffset = currentY + (row * (AURA_SIZE + 4 + SPACING))
            
            debuff:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2 + currentX, yOffset)
            shownDebuffs = shownDebuffs + 1
        end
        debuffIndex = debuffIndex + 1
    end
end

-- Función para reposicionar los marcos debajo del personaje
function ns.RepositionFrames()
    if PlayerFrame then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -10, 160)
    end
    
    if TargetFrame then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 10, 160)
    end
    
    if FocusFrame then
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 0, 45)
    end
end

-- Función para personalizar tamaños, posiciones y ocultar bordes por defecto
function ns.CustomStyleFrames()
    -- --- JUGADOR ---
    ns.SafeHide(PlayerFrameTexture)
    ns.SafeHide(PlayerFrameBackground)
    ns.SafeHide(PlayerFrameFlash)
    ns.SafeHide(PlayerPortrait)
    ns.SafeHide(PlayerFramePortrait)
    ns.SafeHide(PlayerStatusTexture)
    ns.SafeHide(PlayerRestGlow)
    
    ns.CleanDefaultTextures(PlayerFrame)
    
    if PlayerRestIcon then PlayerRestIcon:Hide() end
    if PlayerAttackIcon then PlayerAttackIcon:Hide() end
    if PlayerPVPIcon then PlayerPVPIcon:Hide() end
    
    if PlayerFrame then
        PlayerFrame:SetWidth(ns.BAR_WIDTH)
        PlayerFrame:SetHeight(ns.HEALTH_HEIGHT + ns.MANA_HEIGHT + 2)
    end
    
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:ClearAllPoints()
        PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
        PlayerFrameHealthBar:SetWidth(ns.BAR_WIDTH)
        PlayerFrameHealthBar:SetHeight(ns.HEALTH_HEIGHT)
        PlayerFrameHealthBar:EnableMouse(false)
        ns.ClearBarBackgrounds(PlayerFrameHealthBar)
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:ClearAllPoints()
        PlayerFrameManaBar:SetPoint("TOPLEFT", PlayerFrameHealthBar, "BOTTOMLEFT", 0, -2)
        PlayerFrameManaBar:SetWidth(ns.BAR_WIDTH)
        PlayerFrameManaBar:SetHeight(ns.MANA_HEIGHT)
        PlayerFrameManaBar:EnableMouse(false)
        ns.ClearBarBackgrounds(PlayerFrameManaBar)
    end

    ns.ApplyCustomBackground(PlayerFrame, PlayerFrameHealthBar, PlayerFrameManaBar, ns.BAR_WIDTH)
    
    if PlayerName then
        PlayerName:ClearAllPoints()
        PlayerName:SetPoint("BOTTOMLEFT", PlayerFrameHealthBar, "TOPLEFT", 2, 4)
        PlayerName:SetJustifyH("LEFT")
    end
    
    if PlayerLevelText then
        PlayerLevelText:ClearAllPoints()
        PlayerLevelText:SetPoint("BOTTOMLEFT", PlayerFrameHealthBar, "TOPLEFT", 2, 4)
        PlayerName:ClearAllPoints()
        PlayerName:SetPoint("LEFT", PlayerLevelText, "RIGHT", 4, 0)
        PlayerLevelText:SetFontObject(SystemFont_Outline_Small)
        PlayerLevelText:SetJustifyH("LEFT")
        PlayerLevelText:Show()
    end
    ns.AlignPlayerTexts()

    -- --- OBJETIVO ---
    ns.SafeHide(TargetFrameTextureFrameTexture)
    ns.SafeHide(TargetFrameBackground)
    ns.SafeHide(TargetFrameFlash)
    ns.SafeHide(TargetFramePortrait)
    
    ns.CleanDefaultTextures(TargetFrame)
    
    if TargetFrameTextureFramePVPIcon then TargetFrameTextureFramePVPIcon:Hide() end
    if TargetFrameTextureFrame then TargetFrameTextureFrame:EnableMouse(false) end
    
    if TargetFrame then
        TargetFrame:SetWidth(ns.BAR_WIDTH)
        TargetFrame:SetHeight(ns.HEALTH_HEIGHT + ns.MANA_HEIGHT + 2)
    end
    
    if TargetFrameHealthBar then
        TargetFrameHealthBar:ClearAllPoints()
        TargetFrameHealthBar:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 0, 0)
        TargetFrameHealthBar:SetWidth(ns.BAR_WIDTH)
        TargetFrameHealthBar:SetHeight(ns.HEALTH_HEIGHT)
        TargetFrameHealthBar:EnableMouse(false)
        ns.ClearBarBackgrounds(TargetFrameHealthBar)
    end
    if TargetFrameManaBar then
        TargetFrameManaBar:ClearAllPoints()
        TargetFrameManaBar:SetPoint("TOPLEFT", TargetFrameHealthBar, "BOTTOMLEFT", 0, -2)
        TargetFrameManaBar:SetWidth(ns.BAR_WIDTH)
        TargetFrameManaBar:SetHeight(ns.MANA_HEIGHT)
        TargetFrameManaBar:EnableMouse(false)
        ns.ClearBarBackgrounds(TargetFrameManaBar)
    end

    ns.ApplyCustomBackground(TargetFrame, TargetFrameHealthBar, TargetFrameManaBar, ns.BAR_WIDTH)
    
    if TargetFrameTextureFrameName then
        TargetFrameTextureFrameName:ClearAllPoints()
        TargetFrameTextureFrameName:SetJustifyH("RIGHT")
    end
    
    if TargetFrameTextureFrameLevelText then
        TargetFrameTextureFrameLevelText:ClearAllPoints()
        TargetFrameTextureFrameLevelText:SetPoint("BOTTOMRIGHT", TargetFrameHealthBar, "TOPRIGHT", -2, 4)
        TargetFrameTextureFrameLevelText:SetFontObject(SystemFont_Outline_Small)
        TargetFrameTextureFrameLevelText:SetJustifyH("RIGHT")
        TargetFrameTextureFrameLevelText:Show()
        
        -- El nombre se alinea a la izquierda del nivel
        TargetFrameTextureFrameName:SetPoint("RIGHT", TargetFrameTextureFrameLevelText, "LEFT", -4, 0)
    else
        if TargetFrameTextureFrameName then
            TargetFrameTextureFrameName:SetPoint("BOTTOMRIGHT", TargetFrameHealthBar, "TOPRIGHT", -2, 4)
        end
    end
    ns.AlignTargetTexts()
    ns.PositionTargetBuffs()

    -- Ocultamos el ToT nativo porque es un Secure Frame 
    if TargetFrameToT then
        TargetFrameToT:SetAlpha(0)
        TargetFrameToT:EnableMouse(false)
        if TargetFrameToTTextureFrame then TargetFrameToTTextureFrame:EnableMouse(false) end
        if TargetFrameToTHealthBar then TargetFrameToTHealthBar:EnableMouse(false) end
        if TargetFrameToTManaBar then TargetFrameToTManaBar:EnableMouse(false) end
    end

    -- --- FOCO ---
    ns.SafeHide(FocusFrameTextureFrameTexture)
    ns.SafeHide(FocusFrameBackground)
    ns.SafeHide(FocusFrameFlash)
    ns.SafeHide(FocusFramePortrait)
    
    ns.CleanDefaultTextures(FocusFrame)
    
    if FocusFrameTextureFrameLevelText then FocusFrameTextureFrameLevelText:Hide() end
    if FocusFrameTextureFramePVPIcon then FocusFrameTextureFramePVPIcon:Hide() end
    if FocusFrameTextureFrame then FocusFrameTextureFrame:EnableMouse(false) end
    
    if FocusFrame then
        FocusFrame:SetWidth(ns.BAR_WIDTH)
        FocusFrame:SetHeight(ns.HEALTH_HEIGHT + ns.MANA_HEIGHT + 2)
    end
    
    if FocusFrameHealthBar then
        FocusFrameHealthBar:ClearAllPoints()
        FocusFrameHealthBar:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 0, 0)
        FocusFrameHealthBar:SetWidth(ns.BAR_WIDTH)
        FocusFrameHealthBar:SetHeight(ns.HEALTH_HEIGHT)
        FocusFrameHealthBar:EnableMouse(false)
        ns.ClearBarBackgrounds(FocusFrameHealthBar)
    end
    if FocusFrameManaBar then
        FocusFrameManaBar:ClearAllPoints()
        FocusFrameManaBar:SetPoint("TOPLEFT", FocusFrameHealthBar, "BOTTOMLEFT", 0, -2)
        FocusFrameManaBar:SetWidth(ns.BAR_WIDTH)
        FocusFrameManaBar:SetHeight(ns.MANA_HEIGHT)
        FocusFrameManaBar:EnableMouse(false)
        ns.ClearBarBackgrounds(FocusFrameManaBar)
    end

    ns.ApplyCustomBackground(FocusFrame, FocusFrameHealthBar, FocusFrameManaBar, ns.BAR_WIDTH)
    
    if FocusFrameTextureFrameName then
        FocusFrameTextureFrameName:ClearAllPoints()
        FocusFrameTextureFrameName:SetPoint("BOTTOMLEFT", FocusFrameHealthBar, "TOPLEFT", 2, 4)
    end
    ns.AlignFocusTexts()
end

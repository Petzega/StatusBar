local addonName, ns = ...

function ns.PositionTargetBuffs(self)
    if not self then self = TargetFrame end
    local frameName = self:GetName()
    if frameName ~= "TargetFrame" and frameName ~= "FocusFrame" then return end
    
    local healthBar = _G[frameName.."HealthBar"]
    if not healthBar then return end

    local AURA_SIZE = 22
    local SPACING = 2
    local currentWidth = healthBar:GetWidth() or ns.BAR_WIDTH
    
    local MAX_BUFFS_PER_ROW = math.floor(currentWidth / (AURA_SIZE + SPACING))
    if MAX_BUFFS_PER_ROW < 1 then MAX_BUFFS_PER_ROW = 1 end
    
    local MAX_DEBUFFS_PER_ROW = math.floor(currentWidth / (AURA_SIZE + 4 + SPACING))
    if MAX_DEBUFFS_PER_ROW < 1 then MAX_DEBUFFS_PER_ROW = 1 end
    
    local currentY = 18 -- Altura inicial por encima del nombre

    -- Posicionar Buffs
    local shownBuffs = 0
    local buffIndex = 1
    while _G[frameName.."Buff"..buffIndex] do
        local buff = _G[frameName.."Buff"..buffIndex]
        if buff:IsShown() then
            buff:ClearAllPoints()
            buff:SetSize(AURA_SIZE, AURA_SIZE) -- Estandarizar tamaño
            
            local col = shownBuffs % MAX_BUFFS_PER_ROW
            local row = math.floor(shownBuffs / MAX_BUFFS_PER_ROW)
            
            local currentX = col * (AURA_SIZE + SPACING)
            local yOffset = currentY + (row * (AURA_SIZE + SPACING))
            
            buff:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2 + currentX, yOffset)
            shownBuffs = shownBuffs + 1
        end
        buffIndex = buffIndex + 1
    end
    
    -- Calcular espacio para los debuffs
    if shownBuffs > 0 then
        local rowsUsed = math.ceil(shownBuffs / MAX_BUFFS_PER_ROW)
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
            
            local col = shownDebuffs % MAX_DEBUFFS_PER_ROW
            local row = math.floor(shownDebuffs / MAX_DEBUFFS_PER_ROW)
            
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
        PlayerFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -100, 160)
    end
    
    if TargetFrame then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 100, 160)
    end
    
    if FocusFrame then
        FocusFrame:ClearAllPoints()
        -- Anclado a la izquierda del jugador, con la misma separación y altura que el ToT
        FocusFrame:SetPoint("TOPRIGHT", PlayerFrameHealthBar, "TOPLEFT", -10, ns.TOT_ANCHOR_Y)
    end
end

-- Función para personalizar tamaños, posiciones y ocultar bordes por defecto
function ns.CustomStyleFrames()
    -- --- JUGADOR ---
    ns.SafeHide(PlayerFrameTexture)
    ns.SafeHide(PlayerFrameBackground)
    ns.SafeHide(PlayerFrameFlash)
    ns.SafeHide(PlayerStatusTexture)
    ns.SafeHide(PlayerRestGlow)
    ns.SafeHide(PlayerAttackBackground)
    ns.SafeHide(PlayerAttackGlow)
    ns.SafeHide(PlayerStatusGlow)
    
    -- Ocultar permanentemente la pestaña de Grupo de Banda
    if PlayerFrameGroupIndicator then
        PlayerFrameGroupIndicator:SetAlpha(0)
        if not PlayerFrameGroupIndicator.isKilled then
            PlayerFrameGroupIndicator.isKilled = true
            hooksecurefunc(PlayerFrameGroupIndicator, "Show", function(self) self:Hide() end)
        end
        PlayerFrameGroupIndicator:Hide()
    end
    
    if PlayerFrameVehicleTexture and not PlayerFrameVehicleTexture.isKilled then
        PlayerFrameVehicleTexture.isKilled = true
        PlayerFrameVehicleTexture:SetAlpha(0)
        hooksecurefunc(PlayerFrameVehicleTexture, "Show", function(self) self:Hide() end)
        hooksecurefunc(PlayerFrameVehicleTexture, "SetTexture", function(self) self:SetAlpha(0) end)
    end
    
    ns.CleanDefaultTextures(PlayerFrame)
    -- Jugador: Separación limpia para evitar que la barra corte la imagen
    ns.StylePortrait(PlayerFrameHealthBar, PlayerPortrait, "LEFT", "RIGHT", 0, 68)
    
    if PlayerRestIcon then PlayerRestIcon:Hide() end
    if PlayerAttackIcon then PlayerAttackIcon:Hide() end
    if PlayerPVPIcon then
        PlayerPVPIcon:ClearAllPoints()
        PlayerPVPIcon:SetPoint("CENTER", PlayerPortrait, "BOTTOMLEFT", 15, -5)
    end
    
    if PlayerFrame then
        PlayerFrame:SetWidth(ns.BAR_WIDTH)
        PlayerFrame:SetHeight(ns.HEALTH_HEIGHT + ns.MANA_HEIGHT + 2)
        PlayerFrame:SetHitRectInsets(0, -70, -20, -20) -- Expandir hitbox a la derecha y verticalmente para el retrato
    end
    
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:ClearAllPoints()
        PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
        PlayerFrameHealthBar:SetWidth(ns.BAR_WIDTH)
        PlayerFrameHealthBar:SetHeight(ns.HEALTH_HEIGHT)
        PlayerFrameHealthBar:EnableMouse(false)
        ns.ClearBarBackgrounds(PlayerFrameHealthBar)
        
        -- Bloquear dimensiones para que el vehículo no lo achique
        if not PlayerFrameHealthBar.isLocked then
            PlayerFrameHealthBar.isLocked = true
            hooksecurefunc(PlayerFrameHealthBar, "SetWidth", function(self, w)
                if w ~= ns.BAR_WIDTH then self:SetWidth(ns.BAR_WIDTH) end
            end)
            hooksecurefunc(PlayerFrameHealthBar, "SetPoint", function(self, point, relTo, relPoint, x, y)
                if point ~= "TOPLEFT" or x ~= 0 then
                    self:ClearAllPoints()
                    self:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
                end
            end)
        end
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:ClearAllPoints()
        PlayerFrameManaBar:SetPoint("TOPLEFT", PlayerFrameHealthBar, "BOTTOMLEFT", 0, -2)
        PlayerFrameManaBar:SetWidth(ns.BAR_WIDTH)
        PlayerFrameManaBar:SetHeight(ns.MANA_HEIGHT)
        PlayerFrameManaBar:EnableMouse(false)
        ns.ClearBarBackgrounds(PlayerFrameManaBar)
        
        -- Bloquear dimensiones
        if not PlayerFrameManaBar.isLocked then
            PlayerFrameManaBar.isLocked = true
            hooksecurefunc(PlayerFrameManaBar, "SetWidth", function(self, w)
                if w ~= ns.BAR_WIDTH then self:SetWidth(ns.BAR_WIDTH) end
            end)
            hooksecurefunc(PlayerFrameManaBar, "SetPoint", function(self, point, relTo, relPoint, x, y)
                if point ~= "TOPLEFT" or y ~= -2 then
                    self:ClearAllPoints()
                    self:SetPoint("TOPLEFT", PlayerFrameHealthBar, "BOTTOMLEFT", 0, -2)
                end
            end)
        end
    end

    ns.ApplyCustomBackground(PlayerFrame, PlayerFrameHealthBar, PlayerFrameManaBar, ns.BAR_WIDTH)
    
    ns.AlignPlayerTexts()

    -- --- OBJETIVO ---
    ns.SafeHide(TargetFrameTextureFrameTexture)
    ns.SafeHide(TargetFrameBackground)
    ns.SafeHide(TargetFrameFlash)
    
    ns.CleanDefaultTextures(TargetFrame)
    -- Objetivo: Separación limpia, con la cara invertida (mirando al jugador)
    ns.StylePortrait(TargetFrameHealthBar, TargetFramePortrait, "RIGHT", "LEFT", 0, 68, true)
    
    if TargetFrameTextureFramePVPIcon then
        TargetFrameTextureFramePVPIcon:ClearAllPoints()
        TargetFrameTextureFramePVPIcon:SetPoint("CENTER", TargetFramePortrait, "BOTTOMRIGHT", 10, -5)
    end
    if TargetFrameTextureFrame then TargetFrameTextureFrame:EnableMouse(false) end
    
    if TargetFrame then
        TargetFrame:SetWidth(ns.BAR_WIDTH)
        TargetFrame:SetHeight(ns.HEALTH_HEIGHT + ns.MANA_HEIGHT + 2)
        TargetFrame:SetHitRectInsets(-70, 0, -20, -20) -- Expandir hitbox a la izquierda y verticalmente para el retrato
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

    -- Ocultamos el ToT nativo del Foco porque el foco en sí ya es pequeño
    if FocusFrameToT then
        FocusFrameToT:SetAlpha(0)
        FocusFrameToT:EnableMouse(false)
        if FocusFrameToTTextureFrame then FocusFrameToTTextureFrame:EnableMouse(false) end
        if FocusFrameToTHealthBar then FocusFrameToTHealthBar:EnableMouse(false) end
        if FocusFrameToTManaBar then FocusFrameToTManaBar:EnableMouse(false) end
    end

    -- --- FOCO ---
    ns.SafeHide(FocusFrameTextureFrameTexture)
    ns.SafeHide(FocusFrameBackground)
    ns.SafeHide(FocusFrameFlash)
    
    ns.CleanDefaultTextures(FocusFrame)
    -- Foco: Estilo pequeño tipo ToT (Retrato a la izquierda, barra a la derecha)
    ns.StylePortrait(FocusFrameHealthBar, FocusFramePortrait, "RIGHT", "LEFT", -5, 42, false)
    
    if FocusFrameTextureFramePVPIcon then
        FocusFrameTextureFramePVPIcon:SetSize(32, 32)
        FocusFrameTextureFramePVPIcon:ClearAllPoints()
        FocusFrameTextureFramePVPIcon:SetPoint("CENTER", FocusFramePortrait, "BOTTOMRIGHT", 0, 0)
    end
    if FocusFrameTextureFrame then FocusFrameTextureFrame:EnableMouse(false) end
    
    if FocusFrame then
        FocusFrame:SetWidth(ns.TOT_WIDTH)
        FocusFrame:SetHeight(ns.TOT_HEALTH_HEIGHT + ns.TOT_MANA_HEIGHT + 2)
        FocusFrame:SetHitRectInsets(-50, 0, -15, -15) -- Expandir hitbox a la izquierda para el retrato miniatura
    end
    
    if FocusFrameHealthBar then
        FocusFrameHealthBar:ClearAllPoints()
        FocusFrameHealthBar:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 0, 0)
        FocusFrameHealthBar:SetWidth(ns.TOT_WIDTH)
        FocusFrameHealthBar:SetHeight(ns.TOT_HEALTH_HEIGHT)
        FocusFrameHealthBar:EnableMouse(false)
        ns.ClearBarBackgrounds(FocusFrameHealthBar)
    end
    if FocusFrameManaBar then
        FocusFrameManaBar:ClearAllPoints()
        FocusFrameManaBar:SetPoint("TOPLEFT", FocusFrameHealthBar, "BOTTOMLEFT", 0, -1)
        FocusFrameManaBar:SetWidth(ns.TOT_WIDTH)
        FocusFrameManaBar:SetHeight(ns.TOT_MANA_HEIGHT)
        FocusFrameManaBar:EnableMouse(false)
        ns.ClearBarBackgrounds(FocusFrameManaBar)
    end

    ns.ApplyCustomBackground(FocusFrame, FocusFrameHealthBar, FocusFrameManaBar, ns.TOT_WIDTH)
    
    ns.AlignFocusTexts()
    ns.StyleComboPoints()
end

-- Función para dar estilo a los Puntos de Combo (Arco limpio sobre el retrato)
function ns.StyleComboPoints()
    if not ComboFrame then return end
    
    local CP_SIZE = 14
    local RADIUS = 40
    
    -- Ángulos para un arco superior (130 grados a 50 grados, un poco más separados)
    local angles = {
        math.rad(130),
        math.rad(110),
        math.rad(90),
        math.rad(70),
        math.rad(50)
    }
    
    if ComboFrameBackground then ComboFrameBackground:Hide() end
    
    for i = 1, 5 do
        local cp = _G["ComboPoint"..i]
        if cp then
            cp:SetSize(CP_SIZE, CP_SIZE)
            
            local bg = _G["ComboPoint"..i.."BG"]
            local highlight = _G["ComboPoint"..i.."Highlight"]
            local tex = _G["ComboPoint"..i.."ComboPoint"]
            
            if cp.customTex then cp.customTex:Hide() end
            if cp.customBg then cp.customBg:Hide() end
            if cp.bgBorder then cp.bgBorder:Hide() end
            
            -- Estado Desactivado (Socket circular PERFECTAMENTE LIMPIO)
            if bg and bg.SetTexture then 
                -- UI-Minimap-Background es un círculo sólido y perfecto sin bordes dentados
                bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
                bg:SetVertexColor(0, 0, 0, 0.7) -- Negro transparente limpio
                bg:SetAlpha(1)
                bg:Show()
                bg:SetAllPoints(cp)
            end
            
            -- Brillo de ganancia
            if highlight and highlight.SetTexture then 
                highlight:SetTexture("Interface\\ComboFrame\\ComboPoint")
                highlight:SetBlendMode("ADD")
                highlight:SetVertexColor(1, 1, 1, 0.5) 
                highlight:SetAllPoints(cp)
            end
            
            -- Estado Activo (Orbe rojo nativo)
            if tex and tex.SetTexture then 
                tex:SetTexture("Interface\\ComboFrame\\ComboPoint")
                tex:SetVertexColor(1, 1, 1, 1) -- Color rojo original y limpio
                tex:SetAlpha(1)
                tex:Show()
                tex:SetAllPoints(cp)
            end
            
            cp:ClearAllPoints()
            local offsetX = RADIUS * math.cos(angles[i])
            local offsetY = RADIUS * math.sin(angles[i])
            cp:SetPoint("CENTER", ComboFrame, "CENTER", offsetX, offsetY)
        end
    end
    
    if not ns.comboHooked then
        ns.comboHooked = true
        hooksecurefunc("ComboFrame_Update", function()
            if ComboFrame and TargetFramePortrait then
                ComboFrame:ClearAllPoints()
                -- Anclamos el marco base al centro del retrato del Objetivo
                ComboFrame:SetPoint("CENTER", TargetFramePortrait, "CENTER", 0, 0)
                ComboFrame:SetSize(1, 1)
            end
        end)
    end
end


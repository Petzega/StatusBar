-- Frame principal para escuchar eventos del juego
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Ruta a nuestra textura estilo Dota 2
local TEXTURE_PATH = "Interface\\AddOns\\StatusBar\\dota_bar"

local function ApplyBarTextures()
    -- Jugador
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:SetStatusBarTexture(TEXTURE_PATH)
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:SetStatusBarTexture(TEXTURE_PATH)
    end
    
    -- Objetivo
    if TargetFrameHealthBar then
        TargetFrameHealthBar:SetStatusBarTexture(TEXTURE_PATH)
    end
    if TargetFrameManaBar then
        TargetFrameManaBar:SetStatusBarTexture(TEXTURE_PATH)
    end
    
    -- Foco
    if FocusFrameHealthBar then
        FocusFrameHealthBar:SetStatusBarTexture(TEXTURE_PATH)
    end
    if FocusFrameManaBar then
        FocusFrameManaBar:SetStatusBarTexture(TEXTURE_PATH)
    end
end

-- Función para ocultar de forma segura texturas/iconos nativos de WoW sin causar errores de Lua
local function SafeHide(tex)
    if tex then
        tex:SetTexture(nil)
        tex:SetAlpha(0)
        tex:Hide()
    end
end

-- Función para limpiar texturas por defecto de un marco
local function CleanDefaultTextures(f)
    if not f then return end
    for i = 1, f:GetNumRegions() do
        local region = select(i, f:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            if region ~= f.customBg then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end
    -- Limpiar también el TextureFrame secundario si existe (común en Target/Focus)
    local texFrame = _G[f:GetName().."TextureFrame"]
    if texFrame then
        for i = 1, texFrame:GetNumRegions() do
            local region = select(i, texFrame:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end
end

-- Función para limpiar texturas de fondo internas de las barras
local function ClearBarBackgrounds(bar)
    if not bar then return end
    for i = 1, bar:GetNumRegions() do
        local region = select(i, bar:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            if region ~= bar:GetStatusBarTexture() then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end
end

-- Función para crear un fondo oscuro personalizado detrás de las barras
local function ApplyCustomBackground(parentFrame, topAnchor, bottomAnchor, barWidth)
    if not parentFrame then return end
    
    if not parentFrame.customBg then
        parentFrame.customBg = parentFrame:CreateTexture(nil, "BACKGROUND")
    end
    
    parentFrame.customBg:SetTexture(0.05, 0.05, 0.05, 0.8) -- Color gris oscuro casi negro
    parentFrame.customBg:ClearAllPoints()
    parentFrame.customBg:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -2, 2)
    parentFrame.customBg:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", 2, -2)
end

local lockingTexts = {}

-- Función para estandarizar la fuente, tamaño y estilo de los textos de las barras
local function StandardizeText(textString, parentBar, fontSize)
    if not textString or not parentBar then return end
    
    fontSize = fontSize or 11
    -- Usamos la fuente estándar de WoW, con contorno (OUTLINE) grueso para alta legibilidad
    textString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    textString:SetTextColor(1, 1, 1, 1)
    textString:SetShadowOffset(0, 0)
    textString:SetWidth(0)               -- Elimina cualquier ancho fijo para evitar desalineaciones
    textString:SetJustifyH("CENTER")     -- Justificación al centro absoluto
    
    -- Bloquear posición al centro absoluto de su barra correspondiente para evitar que WoW lo mueva
    if not lockingTexts[textString] then
        lockingTexts[textString] = true
        local isLocking = false
        hooksecurefunc(textString, "SetPoint", function(self)
            if isLocking then return end
            isLocking = true
            self:ClearAllPoints()
            self:SetPoint("CENTER", parentBar, "CENTER", 0, 0)
            isLocking = false
        end)
    end
    
    -- Aplicamos la posición inicialmente
    textString:ClearAllPoints()
    textString:SetPoint("CENTER", parentBar, "CENTER", 0, 0)
end

-- Función para alinear los textos del Objetivo
local function AlignTargetTexts()
    local hpText = TargetFrameHealthBar and TargetFrameHealthBar.TextString or TargetFrameTextureFrameHealthBarText
    local manaText = TargetFrameManaBar and TargetFrameManaBar.TextString or TargetFrameTextureFrameManaBarText
    if hpText then
        StandardizeText(hpText, TargetFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        StandardizeText(manaText, TargetFrameManaBar)
        manaText:Show()
    end
end

-- Función para alinear los textos del Foco
local function AlignFocusTexts()
    local hpText = FocusFrameHealthBar and FocusFrameHealthBar.TextString or FocusFrameTextureFrameHealthBarText
    local manaText = FocusFrameManaBar and FocusFrameManaBar.TextString or FocusFrameTextureFrameManaBarText
    if hpText then
        StandardizeText(hpText, FocusFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        StandardizeText(manaText, FocusFrameManaBar)
        manaText:Show()
    end
end

-- Función para alinear los textos del Jugador
local function AlignPlayerTexts()
    local hpText = PlayerFrameHealthBar and PlayerFrameHealthBar.TextString or PlayerFrameHealthBarText
    local manaText = PlayerFrameManaBar and PlayerFrameManaBar.TextString or PlayerFrameManaBarText
    if hpText then
        StandardizeText(hpText, PlayerFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        StandardizeText(manaText, PlayerFrameManaBar)
        manaText:Show()
    end
end

-- Función para posicionar los beneficios (buffs) del Objetivo y Foco
local function PositionTargetBuffs(self)
    if not self then self = TargetFrame end
    local frameName = self:GetName()
    if frameName ~= "TargetFrame" and frameName ~= "FocusFrame" then return end
    
    local buff1 = _G[frameName.."Buff1"]
    local debuff1 = _G[frameName.."Debuff1"]
    local healthBar = _G[frameName.."HealthBar"]
    
    if buff1 and healthBar then
        buff1:ClearAllPoints()
        buff1:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 18) -- Posicionado bien arriba de la barra de vida/nombre
    end
    if debuff1 and healthBar then
        debuff1:ClearAllPoints()
        if buff1 and buff1:IsShown() then
            debuff1:SetPoint("BOTTOMLEFT", buff1, "TOPLEFT", 0, 5)
        else
            debuff1:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 18)
        end
    end
end

-- Función para personalizar tamaños, posiciones y ocultar bordes por defecto
local function CustomStyleFrames()
    local BAR_WIDTH = 320     -- Ancho largo estilo Dota 2
    local HEALTH_HEIGHT = 22  -- Más alto
    local MANA_HEIGHT = 10    -- Barra de maná/poder

    -- --- JUGADOR ---
    SafeHide(PlayerFrameTexture)
    SafeHide(PlayerFrameBackground)
    SafeHide(PlayerFrameFlash)
    SafeHide(PlayerPortrait)
    SafeHide(PlayerFramePortrait)
    SafeHide(PlayerStatusTexture)
    SafeHide(PlayerRestGlow)
    
    CleanDefaultTextures(PlayerFrame)
    
    if PlayerRestIcon then PlayerRestIcon:Hide() end
    if PlayerAttackIcon then PlayerAttackIcon:Hide() end
    if PlayerPVPIcon then PlayerPVPIcon:Hide() end
    
    if PlayerFrame then
        PlayerFrame:SetWidth(BAR_WIDTH)
        PlayerFrame:SetHeight(HEALTH_HEIGHT + MANA_HEIGHT + 2)
    end
    
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:ClearAllPoints()
        PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
        PlayerFrameHealthBar:SetWidth(BAR_WIDTH)
        PlayerFrameHealthBar:SetHeight(HEALTH_HEIGHT)
        PlayerFrameHealthBar:EnableMouse(false)
        ClearBarBackgrounds(PlayerFrameHealthBar)
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:ClearAllPoints()
        PlayerFrameManaBar:SetPoint("TOPLEFT", PlayerFrameHealthBar, "BOTTOMLEFT", 0, -2)
        PlayerFrameManaBar:SetWidth(BAR_WIDTH)
        PlayerFrameManaBar:SetHeight(MANA_HEIGHT)
        PlayerFrameManaBar:EnableMouse(false)
        ClearBarBackgrounds(PlayerFrameManaBar)
    end

    ApplyCustomBackground(PlayerFrame, PlayerFrameHealthBar, PlayerFrameManaBar, BAR_WIDTH)
    
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
    AlignPlayerTexts()

    -- --- OBJETIVO ---
    SafeHide(TargetFrameTextureFrameTexture)
    SafeHide(TargetFrameBackground)
    SafeHide(TargetFrameFlash)
    SafeHide(TargetFramePortrait)
    
    CleanDefaultTextures(TargetFrame)
    
    if TargetFrameTextureFramePVPIcon then TargetFrameTextureFramePVPIcon:Hide() end
    if TargetFrameTextureFrame then TargetFrameTextureFrame:EnableMouse(false) end
    
    if TargetFrame then
        TargetFrame:SetWidth(BAR_WIDTH)
        TargetFrame:SetHeight(HEALTH_HEIGHT + MANA_HEIGHT + 2)
    end
    
    if TargetFrameHealthBar then
        TargetFrameHealthBar:ClearAllPoints()
        TargetFrameHealthBar:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 0, 0)
        TargetFrameHealthBar:SetWidth(BAR_WIDTH)
        TargetFrameHealthBar:SetHeight(HEALTH_HEIGHT)
        TargetFrameHealthBar:EnableMouse(false)
        ClearBarBackgrounds(TargetFrameHealthBar)
    end
    if TargetFrameManaBar then
        TargetFrameManaBar:ClearAllPoints()
        TargetFrameManaBar:SetPoint("TOPLEFT", TargetFrameHealthBar, "BOTTOMLEFT", 0, -2)
        TargetFrameManaBar:SetWidth(BAR_WIDTH)
        TargetFrameManaBar:SetHeight(MANA_HEIGHT)
        TargetFrameManaBar:EnableMouse(false)
        ClearBarBackgrounds(TargetFrameManaBar)
    end

    ApplyCustomBackground(TargetFrame, TargetFrameHealthBar, TargetFrameManaBar, BAR_WIDTH)
    
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
    AlignTargetTexts()
    PositionTargetBuffs()
    -- --- TARGET OF TARGET (Objetivo del Objetivo) ---
    if TargetFrameToT then
        CleanDefaultTextures(TargetFrameToT)
        SafeHide(TargetFrameToTPortrait)
        
        local TOT_WIDTH = 180
        local TOT_HEALTH_HEIGHT = 14
        local TOT_MANA_HEIGHT = 6
        
        TargetFrameToT:SetWidth(TOT_WIDTH)
        TargetFrameToT:SetHeight(TOT_HEALTH_HEIGHT + TOT_MANA_HEIGHT + 2)
        if TargetFrameToTTextureFrame then TargetFrameToTTextureFrame:EnableMouse(false) end
        
        if TargetFrameToTHealthBar then
            TargetFrameToTHealthBar:ClearAllPoints()
            TargetFrameToTHealthBar:SetPoint("TOPLEFT", TargetFrameToT, "TOPLEFT", 225, 15)
            TargetFrameToTHealthBar:SetWidth(TOT_WIDTH)
            TargetFrameToTHealthBar:SetHeight(TOT_HEALTH_HEIGHT)
            TargetFrameToTHealthBar:EnableMouse(false)
            TargetFrameToTHealthBar:SetStatusBarTexture(TEXTURE_PATH)
            ClearBarBackgrounds(TargetFrameToTHealthBar)
        end
        
        if TargetFrameToTManaBar then
            TargetFrameToTManaBar:ClearAllPoints()
            TargetFrameToTManaBar:SetPoint("TOPLEFT", TargetFrameToTHealthBar, "BOTTOMLEFT", 0, -1)
            TargetFrameToTManaBar:SetWidth(TOT_WIDTH)
            TargetFrameToTManaBar:SetHeight(TOT_MANA_HEIGHT)
            TargetFrameToTManaBar:EnableMouse(false)
            TargetFrameToTManaBar:SetStatusBarTexture(TEXTURE_PATH)
            ClearBarBackgrounds(TargetFrameToTManaBar)
        end
        
        ApplyCustomBackground(TargetFrameToT, TargetFrameToTHealthBar, TargetFrameToTManaBar, TOT_WIDTH)
        
        if TargetFrameToTTextureFrameName then
            TargetFrameToTTextureFrameName:ClearAllPoints()
            TargetFrameToTTextureFrameName:SetPoint("BOTTOMLEFT", TargetFrameToTHealthBar, "TOPLEFT", 2, 2)
            TargetFrameToTTextureFrameName:SetJustifyH("LEFT")
        end
    end

    -- --- FOCO ---
    SafeHide(FocusFrameTextureFrameTexture)
    SafeHide(FocusFrameBackground)
    SafeHide(FocusFrameFlash)
    SafeHide(FocusFramePortrait)
    
    CleanDefaultTextures(FocusFrame)
    
    if FocusFrameTextureFrameLevelText then FocusFrameTextureFrameLevelText:Hide() end
    if FocusFrameTextureFramePVPIcon then FocusFrameTextureFramePVPIcon:Hide() end
    if FocusFrameTextureFrame then FocusFrameTextureFrame:EnableMouse(false) end
    
    if FocusFrame then
        FocusFrame:SetWidth(BAR_WIDTH)
        FocusFrame:SetHeight(HEALTH_HEIGHT + MANA_HEIGHT + 2)
    end
    
    if FocusFrameHealthBar then
        FocusFrameHealthBar:ClearAllPoints()
        FocusFrameHealthBar:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 0, 0)
        FocusFrameHealthBar:SetWidth(BAR_WIDTH)
        FocusFrameHealthBar:SetHeight(HEALTH_HEIGHT)
        FocusFrameHealthBar:EnableMouse(false)
        ClearBarBackgrounds(FocusFrameHealthBar)
    end
    if FocusFrameManaBar then
        FocusFrameManaBar:ClearAllPoints()
        FocusFrameManaBar:SetPoint("TOPLEFT", FocusFrameHealthBar, "BOTTOMLEFT", 0, -2)
        FocusFrameManaBar:SetWidth(BAR_WIDTH)
        FocusFrameManaBar:SetHeight(MANA_HEIGHT)
        FocusFrameManaBar:EnableMouse(false)
        ClearBarBackgrounds(FocusFrameManaBar)
    end

    ApplyCustomBackground(FocusFrame, FocusFrameHealthBar, FocusFrameManaBar, BAR_WIDTH)
    
    if FocusFrameTextureFrameName then
        FocusFrameTextureFrameName:ClearAllPoints()
        FocusFrameTextureFrameName:SetPoint("BOTTOMLEFT", FocusFrameHealthBar, "TOPLEFT", 2, 4)
    end
    AlignFocusTexts()
end

-- Función para actualizar textos del ToT (Nivel, Vida y Maná/Energía)
local function UpdateToTTexts()
    if not TargetFrameToT or not TargetFrameToT:IsShown() then return end
    
    -- 1. Nivel del ToT
    local level = UnitLevel("targettarget")
    local name = UnitName("targettarget")
    if name and TargetFrameToTTextureFrameName then
        local levelText
        if level and level > 0 then
            levelText = tostring(level)
        elseif level == -1 then
            levelText = "??"
        end
        
        if levelText then
            TargetFrameToTTextureFrameName:SetText(name .. " " .. levelText)
        else
            TargetFrameToTTextureFrameName:SetText(name)
        end
    end
    
    -- 2. Valores de Vida
    if TargetFrameToTHealthBar then
        local hp = UnitHealth("targettarget")
        local hpMax = UnitHealthMax("targettarget")
        if not TargetFrameToTHealthBar.TextString then
            TargetFrameToTHealthBar.TextString = TargetFrameToTHealthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            StandardizeText(TargetFrameToTHealthBar.TextString, TargetFrameToTHealthBar, 10)
        end
        if hpMax > 0 then
            TargetFrameToTHealthBar.TextString:SetText(hp .. " / " .. hpMax)
        else
            TargetFrameToTHealthBar.TextString:SetText("")
        end
        TargetFrameToTHealthBar.TextString:Show()
    end
    
    -- 3. Valores de Poder (Maná, Ira, Energía, Poder Rúnico)
    if TargetFrameToTManaBar then
        local power = UnitPower("targettarget")
        local powerMax = UnitPowerMax("targettarget")
        if not TargetFrameToTManaBar.TextString then
            TargetFrameToTManaBar.TextString = TargetFrameToTManaBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            StandardizeText(TargetFrameToTManaBar.TextString, TargetFrameToTManaBar, 8)
        end
        if powerMax > 0 then
            TargetFrameToTManaBar.TextString:SetText(power .. " / " .. powerMax)
        else
            TargetFrameToTManaBar.TextString:SetText("")
        end
        TargetFrameToTManaBar.TextString:Show()
    end
end

-- Flag para evitar loops infinitos
local totHooked = false

-- Función para reposicionar los marcos debajo del personaje
local function RepositionFrames()
    if PlayerFrame then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -10, 160)
        PlayerFrame:SetUserPlaced(true)
    end
    
    if TargetFrame then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 10, 160)
        TargetFrame:SetUserPlaced(true)
    end
    
    if FocusFrame then
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 0, 45)
        FocusFrame:SetUserPlaced(true)
    end
    
    -- Posicionamos el ToT (Objetivo del Objetivo) a la derecha de la barra del objetivo
    if TargetFrameToT and TargetFrame then
        if not totHooked then
            totHooked = true
            hooksecurefunc(TargetFrameToT, "SetPoint", function(self, point, relativeTo, relativePoint, x, y)
                if x ~= 390 or y ~= 100 or point ~= "BOTTOMLEFT" then
                    self:ClearAllPoints()
                    self:SetPoint("BOTTOMLEFT", TargetFrame, "BOTTOMRIGHT", 390, 100)
                end
            end)
        end
        TargetFrameToT:ClearAllPoints()
        TargetFrameToT:SetPoint("BOTTOMLEFT", TargetFrame, "BOTTOMRIGHT", 390, 100)
        TargetFrameToT:SetUserPlaced(true)
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ApplyBarTextures()
        CustomStyleFrames()
        RepositionFrames()
        
        -- Volvemos a aplicar estilos y posiciones en los hooks de actualización
        hooksecurefunc("PlayerFrame_UpdateArt", function()
            CustomStyleFrames()
            ApplyBarTextures()
            RepositionFrames()
        end)
        hooksecurefunc("TargetFrame_Update", function()
            CustomStyleFrames()
            ApplyBarTextures()
            RepositionFrames()
        end)
        hooksecurefunc("FocusFrame_Update", function()
            CustomStyleFrames()
            ApplyBarTextures()
            RepositionFrames()
        end)
        
        hooksecurefunc("TargetFrame_UpdateTextString", AlignTargetTexts)
        hooksecurefunc("FocusFrame_UpdateTextString", AlignFocusTexts)
        hooksecurefunc("PlayerFrame_UpdateTextString", AlignPlayerTexts)
        
        hooksecurefunc("TargetFrame_UpdateAuras", function(self)
            PositionTargetBuffs(self)
            RepositionFrames()
        end)
        hooksecurefunc("TargetFrame_UpdateAuraPositions", function(self)
            PositionTargetBuffs(self)
            RepositionFrames()
        end)
        
        hooksecurefunc("PlayerFrame_ResetPosition", RepositionFrames)
        hooksecurefunc("TargetFrame_ResetPosition", RepositionFrames)
        
        -- Hook seguro para mover el ToT cada vez que el juego lo actualice
        hooksecurefunc("TargetFrameToT_Update", function(self)
            RepositionFrames()
            CustomStyleFrames()
            ApplyBarTextures()
            UpdateToTTexts()
        end)
    end
end)

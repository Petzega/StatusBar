local addonName, ns = ...

-- Función para ocultar de forma segura texturas/iconos nativos de WoW sin causar errores de Lua
function ns.SafeHide(tex)
    if tex then
        if tex.SetTexture then tex:SetTexture(nil) end
        tex:SetAlpha(0)
        tex:Hide()
    end
end

-- Función para limpiar texturas por defecto de un marco
function ns.CleanDefaultTextures(f)
    if not f then return end
    for i = 1, f:GetNumRegions() do
        local region = select(i, f:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            local isPortrait = (region == PlayerPortrait) or (region == TargetFramePortrait) or (region == FocusFramePortrait)
            local isPVP = (region == PlayerPVPIcon) or (region == TargetFrameTextureFramePVPIcon) or (region == FocusFrameTextureFramePVPIcon)
            if region ~= f.customBg and not isPortrait and not isPVP then
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
                local isPVP = (region == PlayerPVPIcon) or (region == TargetFrameTextureFramePVPIcon) or (region == FocusFrameTextureFramePVPIcon)
                if not isPVP then
                    region:SetTexture(nil)
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
    end
end

-- Función para limpiar texturas de fondo internas de las barras
function ns.ClearBarBackgrounds(bar)
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
function ns.ApplyCustomBackground(parentFrame, topAnchor, bottomAnchor, barWidth)
    if not parentFrame then return end
    
    if not parentFrame.customBg then
        parentFrame.customBg = parentFrame:CreateTexture(nil, "BACKGROUND")
    end
    
    parentFrame.customBg:SetTexture(0.05, 0.05, 0.05, 0.8) -- Color gris oscuro casi negro
    parentFrame.customBg:ClearAllPoints()
    parentFrame.customBg:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -2, 2)
    parentFrame.customBg:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", 2, -2)
end

ns.lockingTexts = {}

-- Función para estandarizar la fuente, tamaño y estilo de los textos de las barras
function ns.StandardizeText(textString, parentBar, fontSize)
    if not textString or not parentBar then return end
    
    fontSize = fontSize or 11
    textString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    textString:SetTextColor(1, 1, 1, 1)
    textString:SetShadowOffset(0, 0)
    textString:SetWidth(0)
    textString:SetJustifyH("CENTER")
    
    if not ns.lockingTexts[textString] then
        ns.lockingTexts[textString] = true
        local isLocking = false
        hooksecurefunc(textString, "SetPoint", function(self)
            if isLocking then return end
            isLocking = true
            self:ClearAllPoints()
            self:SetPoint("CENTER", parentBar, "CENTER", 0, 0)
            isLocking = false
        end)
    end
    
    textString:ClearAllPoints()
    textString:SetPoint("CENTER", parentBar, "CENTER", 0, 0)
end

-- Función para dar estilo cuadrado 2D a los retratos y anclarlos a las barras
function ns.StylePortrait(anchorBar, portrait, point, relativePoint, offsetX, size, flipX)
    if not portrait or not anchorBar then return end
    
    size = size or 31
    portrait:ClearAllPoints()
    portrait:SetSize(size, size)
    portrait:SetPoint(point, anchorBar, relativePoint, offsetX, -5)
    
    -- Ajustar zoom para mostrar levemente el borde curvo nativo (esquinas redondeadas)
    if flipX then
        portrait:SetTexCoord(0.95, 0.05, 0.05, 0.95) -- Invertido horizontalmente
    else
        portrait:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    end
    portrait:SetDrawLayer("ARTWORK")
    portrait:Show()
    
    -- Ocultar fondo oscuro antiguo si existe
    if portrait.customBg then
        portrait.customBg:Hide()
    end
    
    -- Crear un marco de borde moderno
    if not portrait.bgBorder then
        portrait.bgBorder = portrait:GetParent():CreateTexture(nil, "BACKGROUND")
        portrait.bgBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        portrait.bgBorder:SetVertexColor(0, 0, 0, 0.9) -- Borde negro limpio
    end
    
    portrait.bgBorder:ClearAllPoints()
    portrait.bgBorder:SetPoint("TOPLEFT", portrait, "TOPLEFT", -2, 2)
    portrait.bgBorder:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", 2, -2)
    portrait.bgBorder:Show()
end

local addonName, ns = ...

-- Función para ocultar de forma segura texturas/iconos nativos de WoW sin causar errores de Lua
function ns.SafeHide(tex)
    if tex then
        tex:SetTexture(nil)
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

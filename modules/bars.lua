local addonName, ns = ...

function ns.ApplyBarTextures()
    -- Jugador
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
    
    -- Objetivo
    if TargetFrameHealthBar then
        TargetFrameHealthBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
    if TargetFrameManaBar then
        TargetFrameManaBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
    
    -- Foco
    if FocusFrameHealthBar then
        FocusFrameHealthBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
    if FocusFrameManaBar then
        FocusFrameManaBar:SetStatusBarTexture(ns.TEXTURE_PATH)
    end
end

function ns.AlignTargetTexts()
    local hpText = TargetFrameHealthBar and TargetFrameHealthBar.TextString or TargetFrameTextureFrameHealthBarText
    local manaText = TargetFrameManaBar and TargetFrameManaBar.TextString or TargetFrameTextureFrameManaBarText
    if hpText then
        ns.StandardizeText(hpText, TargetFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        ns.StandardizeText(manaText, TargetFrameManaBar)
        manaText:Show()
    end
    
    if TargetFrameTextureFrameName and TargetFrameHealthBar then
        TargetFrameTextureFrameName:ClearAllPoints()
        TargetFrameTextureFrameName:SetPoint("BOTTOM", TargetFrameHealthBar, "TOP", 0, 8)
        local font, _, flags = TargetFrameTextureFrameName:GetFont()
        TargetFrameTextureFrameName:SetFont(font, 14, "OUTLINE")
        TargetFrameTextureFrameName:SetJustifyH("CENTER")
    end
    
    if TargetFrameTextureFrameLevelText and TargetFramePortrait then
        TargetFrameTextureFrameLevelText:ClearAllPoints()
        TargetFrameTextureFrameLevelText:SetPoint("BOTTOMLEFT", TargetFramePortrait, "BOTTOMLEFT", -5, -5)
        local font, _, flags = TargetFrameTextureFrameLevelText:GetFont()
        TargetFrameTextureFrameLevelText:SetFont(font, 12, "OUTLINE")
        TargetFrameTextureFrameLevelText:SetJustifyH("CENTER")
        TargetFrameTextureFrameLevelText:SetTextColor(1, 0.82, 0)
        TargetFrameTextureFrameLevelText:Show()
    end
end

function ns.AlignFocusTexts()
    local hpText = FocusFrameHealthBar and FocusFrameHealthBar.TextString or FocusFrameTextureFrameHealthBarText
    local manaText = FocusFrameManaBar and FocusFrameManaBar.TextString or FocusFrameTextureFrameManaBarText
    if hpText then
        ns.StandardizeText(hpText, FocusFrameHealthBar, 10)
        hpText:Show()
    end
    if manaText then
        ns.StandardizeText(manaText, FocusFrameManaBar, 8)
        manaText:Show()
    end
    
    if FocusFrameTextureFrameName and FocusFrameHealthBar then
        FocusFrameTextureFrameName:ClearAllPoints()
        FocusFrameTextureFrameName:SetPoint("BOTTOM", FocusFrameHealthBar, "TOP", 0, 5)
        local font, _, flags = FocusFrameTextureFrameName:GetFont()
        FocusFrameTextureFrameName:SetFont(font, 12, "OUTLINE")
        FocusFrameTextureFrameName:SetJustifyH("CENTER")
    end

    if FocusFrameTextureFrameLevelText and FocusFramePortrait then
        FocusFrameTextureFrameLevelText:ClearAllPoints()
        FocusFrameTextureFrameLevelText:SetPoint("BOTTOMLEFT", FocusFramePortrait, "BOTTOMLEFT", -2, -2)
        local font, _, flags = FocusFrameTextureFrameLevelText:GetFont()
        FocusFrameTextureFrameLevelText:SetFont(font, 10, "OUTLINE")
        FocusFrameTextureFrameLevelText:SetJustifyH("CENTER")
        FocusFrameTextureFrameLevelText:SetTextColor(1, 0.82, 0)
        FocusFrameTextureFrameLevelText:Show()
    end
end

function ns.AlignPlayerTexts()
    local hpText = PlayerFrameHealthBar and PlayerFrameHealthBar.TextString or PlayerFrameHealthBarText
    local manaText = PlayerFrameManaBar and PlayerFrameManaBar.TextString or PlayerFrameManaBarText
    if hpText then
        ns.StandardizeText(hpText, PlayerFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        ns.StandardizeText(manaText, PlayerFrameManaBar)
        manaText:Show()
    end
    
    if PlayerName and PlayerFrameHealthBar then
        PlayerName:ClearAllPoints()
        PlayerName:SetPoint("BOTTOM", PlayerFrameHealthBar, "TOP", 0, 8)
        local font, _, flags = PlayerName:GetFont()
        PlayerName:SetFont(font, 14, "OUTLINE")
        PlayerName:SetJustifyH("CENTER")
    end
    
    if PlayerLevelText and PlayerPortrait then
        PlayerLevelText:ClearAllPoints()
        PlayerLevelText:SetPoint("BOTTOMRIGHT", PlayerPortrait, "BOTTOMRIGHT", 5, -5)
        local font, _, flags = PlayerLevelText:GetFont()
        PlayerLevelText:SetFont(font, 12, "OUTLINE")
        PlayerLevelText:SetJustifyH("CENTER")
        PlayerLevelText:SetTextColor(1, 0.82, 0) -- Color dorado
        PlayerLevelText:Show()
    end
end

function ns.ApplyHealthBarColors()
    if ns.colorsHooked then return end
    ns.colorsHooked = true
    
    local function GetUnitForBar(statusbar)
        if statusbar == PlayerFrameHealthBar then return "player" end
        if statusbar == TargetFrameHealthBar then return "target" end
        if statusbar == FocusFrameHealthBar then return "focus" end
        if statusbar == TargetFrameToTHealthBar then return "targettarget" end
        if statusbar == FocusFrameToTHealthBar then return "focustarget" end
        return statusbar.unit or (statusbar:GetParent() and statusbar:GetParent().unit)
    end

    local function ForceBarColor(statusbar)
        if not statusbar or statusbar.isForcingColor then return end
        
        -- Ignorar barras que no son de vida
        local name = statusbar:GetName()
        if name and not name:match("HealthBar") and not name:match("HP") then return end
        
        local unitToUse = GetUnitForBar(statusbar)
        if not unitToUse or not UnitExists(unitToUse) then return end
        
        local r, g, b
        if not UnitIsPlayer(unitToUse) and UnitIsTapped(unitToUse) and not UnitIsTappedByPlayer(unitToUse) then
            r, g, b = 0.5, 0.5, 0.5 -- Gris para tapeado
        elseif UnitIsPlayer(unitToUse) then
            local _, class = UnitClass(unitToUse)
            local color = RAID_CLASS_COLORS[class]
            if color then
                r, g, b = color.r, color.g, color.b
            end
        else
            local reaction = UnitReaction(unitToUse, "player")
            if reaction then
                if reaction <= 4 then r, g, b = 1, 0.2, 0.2 -- Hostil
                elseif reaction == 5 then r, g, b = 1, 1, 0.2 -- Neutral
                else r, g, b = 0.2, 1, 0.2 end -- Amistoso
            end
        end
        
        if r and g and b then
            statusbar.isForcingColor = true
            statusbar:SetStatusBarColor(r, g, b)
            if statusbar.bg then
                statusbar.bg:SetVertexColor(r * 0.25, g * 0.25, b * 0.25, 0.8)
            end
            statusbar.isForcingColor = false
        end
    end

    local bars = {
        PlayerFrameHealthBar,
        TargetFrameHealthBar,
        FocusFrameHealthBar,
        TargetFrameToTHealthBar,
        FocusFrameToTHealthBar
    }
    
    for _, bar in ipairs(bars) do
        if bar then
            hooksecurefunc(bar, "SetStatusBarColor", function(self)
                ForceBarColor(self)
            end)
            ForceBarColor(bar)
        end
    end
    
    hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar)
        ForceBarColor(statusbar)
    end)
    hooksecurefunc("HealthBar_OnValueChanged", function(statusbar)
        ForceBarColor(statusbar)
    end)
end


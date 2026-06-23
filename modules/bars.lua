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
        ns.StandardizeText(hpText, FocusFrameHealthBar)
        hpText:Show()
    end
    if manaText then
        ns.StandardizeText(manaText, FocusFrameManaBar)
        manaText:Show()
    end
    
    if FocusFrameTextureFrameName and FocusFrameHealthBar then
        FocusFrameTextureFrameName:ClearAllPoints()
        FocusFrameTextureFrameName:SetPoint("BOTTOM", FocusFrameHealthBar, "TOP", 0, 8)
        local font, _, flags = FocusFrameTextureFrameName:GetFont()
        FocusFrameTextureFrameName:SetFont(font, 14, "OUTLINE")
        FocusFrameTextureFrameName:SetJustifyH("CENTER")
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

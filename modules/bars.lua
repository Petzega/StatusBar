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
end

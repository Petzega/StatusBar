local addonName, ns = ...

function ns.InitCustomToT()
    local customToT = CreateFrame("Button", "StatusBar_CustomToT", UIParent, "SecureUnitButtonTemplate")
    customToT:SetAttribute("unit", "targettarget")
    customToT:SetAttribute("type1", "target")        -- Clic izquierdo = seleccionar como target
    customToT:SetAttribute("type2", "togglemenu")    -- Clic derecho = menu contextual
    customToT:RegisterForClicks("AnyUp")
    customToT:SetWidth(ns.TOT_WIDTH)
    customToT:SetHeight(ns.TOT_HEALTH_HEIGHT + ns.TOT_MANA_HEIGHT + 2)
    
    -- ANCLAJE ESTATICO: Se fija una sola vez al TargetFrame, evitando SetPoint durante el combate
    if TargetFrameHealthBar then
        customToT:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", ns.TOT_ANCHOR_X, ns.TOT_ANCHOR_Y)
    else
        customToT:SetPoint("TOPLEFT", TargetFrame, "TOPRIGHT", ns.TOT_ANCHOR_X, ns.TOT_ANCHOR_Y)
    end
    
    customToT:EnableMouse(true)

    local cTotHP = CreateFrame("StatusBar", "StatusBar_CToTHP", customToT)
    cTotHP:SetPoint("TOPLEFT", customToT, "TOPLEFT", 0, 0)
    cTotHP:SetWidth(ns.TOT_WIDTH)
    cTotHP:SetHeight(ns.TOT_HEALTH_HEIGHT)
    cTotHP:SetStatusBarTexture(ns.TEXTURE_PATH)
    cTotHP:EnableMouse(false)

    local cTotMana = CreateFrame("StatusBar", "StatusBar_CToTMana", customToT)
    cTotMana:SetPoint("TOPLEFT", cTotHP, "BOTTOMLEFT", 0, -1)
    cTotMana:SetWidth(ns.TOT_WIDTH)
    cTotMana:SetHeight(ns.TOT_MANA_HEIGHT)
    cTotMana:SetStatusBarTexture(ns.TEXTURE_PATH)
    cTotMana:EnableMouse(false)

    ns.ApplyCustomBackground(customToT, cTotHP, cTotMana, ns.TOT_WIDTH)

    local cTotPortrait = customToT:CreateTexture(nil, "ARTWORK")
    cTotPortrait:SetPoint("LEFT", cTotHP, "RIGHT", 0, -5)
    cTotPortrait:SetSize(42, 42)
    cTotPortrait:SetTexCoord(0.95, 0.05, 0.05, 0.95) -- Cuadrado con esquinas redondeadas (invertido)

    if customToT.portraitBg then
        customToT.portraitBg:Hide()
    end

    local cTotName = customToT:CreateFontString(nil, "OVERLAY")
    cTotName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    cTotName:SetPoint("BOTTOM", cTotHP, "TOP", 0, 5)
    cTotName:SetJustifyH("CENTER")
    cTotName:SetTextColor(1, 1, 1, 1)

    local cTotLevel = customToT:CreateFontString(nil, "OVERLAY")
    cTotLevel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    cTotLevel:SetPoint("BOTTOMLEFT", cTotPortrait, "BOTTOMLEFT", -2, -2)
    cTotLevel:SetTextColor(1, 0.82, 0) -- Dorado como el Target

    local cTotPVPIcon = customToT:CreateTexture(nil, "OVERLAY")
    cTotPVPIcon:SetSize(32, 32)
    cTotPVPIcon:SetPoint("CENTER", cTotPortrait, "BOTTOMRIGHT", 0, 0)
    cTotPVPIcon:Hide()

    local cTotHPText = cTotHP:CreateFontString(nil, "OVERLAY")
    cTotHPText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    cTotHPText:SetPoint("CENTER", cTotHP, "CENTER", 0, 0)
    cTotHPText:SetJustifyH("CENTER")
    cTotHPText:SetTextColor(1, 1, 1, 1)
    cTotHPText:SetShadowOffset(0, 0)

    local cTotManaText = cTotMana:CreateFontString(nil, "OVERLAY")
    cTotManaText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    cTotManaText:SetPoint("CENTER", cTotMana, "CENTER", 0, 0)
    cTotManaText:SetJustifyH("CENTER")
    cTotManaText:SetTextColor(1, 1, 1, 1)
    cTotManaText:SetShadowOffset(0, 0)

    customToT:SetAlpha(0)

    local function UpdateCustomToT()
        if not UnitExists("targettarget") or not TargetFrameHealthBar or not TargetFrameHealthBar:IsVisible() then
            customToT:SetAlpha(0)
            return
        end

        customToT:SetAlpha(1)
        SetPortraitTexture(cTotPortrait, "targettarget")

        local factionGroup = UnitFactionGroup("targettarget")
        if UnitIsPVPFreeForAll("targettarget") then
            cTotPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
            cTotPVPIcon:Show()
        elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("targettarget") then
            cTotPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)
            cTotPVPIcon:Show()
        else
            cTotPVPIcon:Hide()
        end

        local name = UnitName("targettarget") or ""
        local level = UnitLevel("targettarget")
        if level and level > 0 then
            cTotLevel:SetText(level)
        elseif level == -1 then
            cTotLevel:SetText("??")
        else
            cTotLevel:SetText("")
        end
        cTotName:SetText(name)

        local hp = UnitHealth("targettarget")
        local hpMax = UnitHealthMax("targettarget")
        cTotHP:SetMinMaxValues(0, math.max(1, hpMax))
        cTotHP:SetValue(hp)
        if hpMax > 0 then
            cTotHPText:SetText(hp .. " / " .. hpMax)
        else
            cTotHPText:SetText("")
        end

        -- Color de la barra de vida (verde por defecto)
        cTotHP:SetStatusBarColor(0, 1, 0)

        local power = UnitPower("targettarget")
        local powerMax = UnitPowerMax("targettarget")
        cTotMana:SetMinMaxValues(0, math.max(1, powerMax))
        cTotMana:SetValue(power)

        local powerType = UnitPowerType("targettarget")
        local pc = ns.TOT_POWER_COLORS[powerType] or {0, 0, 1}
        cTotMana:SetStatusBarColor(pc[1], pc[2], pc[3])

        if powerMax > 0 then
            cTotManaText:SetText(power .. " / " .. powerMax)
            cTotMana:Show()
        else
            cTotManaText:SetText("")
        end
    end

    local cTotUpdater = CreateFrame("Frame")
    local cTotElapsed = 0
    cTotUpdater:SetScript("OnUpdate", function(self, elapsed)
        cTotElapsed = cTotElapsed + elapsed
        if cTotElapsed < 0.1 then return end
        cTotElapsed = 0
        UpdateCustomToT()
    end)

    cTotUpdater:RegisterEvent("PLAYER_TARGET_CHANGED")
    cTotUpdater:RegisterEvent("UNIT_TARGET")
    cTotUpdater:RegisterEvent("UNIT_HEALTH")
    cTotUpdater:RegisterEvent("UNIT_MANA")
    cTotUpdater:RegisterEvent("UNIT_ENERGY")
    cTotUpdater:RegisterEvent("UNIT_RAGE")
    cTotUpdater:RegisterEvent("UNIT_RUNIC_POWER")
    cTotUpdater:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" then
            UpdateCustomToT()
        elseif unit == "targettarget" then
            UpdateCustomToT()
        end
    end)
end

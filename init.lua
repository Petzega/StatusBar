local addonName, ns = ...

-- Debug visual seguro para la fase de carga
ns.debugFrame = CreateFrame("Frame", nil, UIParent)
ns.debugFrame:SetWidth(600)
ns.debugFrame:SetHeight(20)
ns.debugFrame:SetPoint("TOP", UIParent, "TOP", 0, -10)
ns.debugFrame:SetFrameStrata("TOOLTIP")
ns.debugText = ns.debugFrame:CreateFontString(nil, "OVERLAY")
ns.debugText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ns.debugText:SetPoint("CENTER")
ns.debugText:SetTextColor(1, 1, 0, 1)
ns.debugText:SetText("[StatusBar] Cargando módulos...")

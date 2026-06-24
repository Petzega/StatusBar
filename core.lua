local addonName, ns = ...

if ns.debugText then
    local missing = {}
    if not ns.TEXTURE_PATH then table.insert(missing, "constants") end
    if not ns.SafeHide then table.insert(missing, "helpers") end
    if not ns.CustomStyleFrames then table.insert(missing, "layout") end
    if not ns.ApplyBarTextures then table.insert(missing, "bars") end
    if not ns.InitCustomToT then table.insert(missing, "tot") end
    
    if #missing > 0 then
        ns.debugText:SetText("ERROR: WoW no encontró los archivos: " .. table.concat(missing, ", "))
        ns.debugText:SetTextColor(1, 0, 0, 1)
    else
        ns.debugText:SetText("[StatusBar] Core y módulos cargados OK")
        ns.debugText:SetTextColor(1, 1, 0, 1)
    end
end

-- Función para atrapar errores y mostrarlos en el texto de debug en pantalla
local function safeCall(func, ...)
    if type(func) ~= "function" then return end
    local success, err = pcall(func, ...)
    if not success and ns.debugText then
        ns.debugText:SetText("ERROR: " .. tostring(err))
        ns.debugText:SetTextColor(1, 0, 0, 1) -- Rojo brillante para errores
    end
end

-- Función auxiliar para los hooks
local function SafeUpdateHook()
    safeCall(ns.CustomStyleFrames)
    safeCall(ns.ApplyBarTextures)
    safeCall(ns.RepositionFrames)
end

-- Frame principal para escuchar eventos del juego
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

if PlayerFrame_UpdateArt then hooksecurefunc("PlayerFrame_UpdateArt", SafeUpdateHook) end
if PlayerFrame_ToVehicleArt then hooksecurefunc("PlayerFrame_ToVehicleArt", SafeUpdateHook) end
if PlayerFrame_ToPlayerArt then hooksecurefunc("PlayerFrame_ToPlayerArt", SafeUpdateHook) end
if TargetFrame_Update then hooksecurefunc("TargetFrame_Update", SafeUpdateHook) end
if FocusFrame_Update then hooksecurefunc("FocusFrame_Update", SafeUpdateHook) end

if TargetFrame_UpdateTextString then 
    hooksecurefunc("TargetFrame_UpdateTextString", function() safeCall(ns.AlignTargetTexts) end) 
end
if FocusFrame_UpdateTextString then 
    hooksecurefunc("FocusFrame_UpdateTextString", function() safeCall(ns.AlignFocusTexts) end) 
end
if PlayerFrame_UpdateTextString then 
    hooksecurefunc("PlayerFrame_UpdateTextString", function() safeCall(ns.AlignPlayerTexts) end) 
end

if TargetFrame_UpdateAuras then
    hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        safeCall(ns.PositionTargetBuffs, self)
        safeCall(ns.RepositionFrames)
    end)
end

if TargetFrame_UpdateAuraPositions then
    hooksecurefunc("TargetFrame_UpdateAuraPositions", function(self)
        safeCall(ns.PositionTargetBuffs, self)
        safeCall(ns.RepositionFrames)
    end)
end

if PlayerFrame_ResetPosition then hooksecurefunc("PlayerFrame_ResetPosition", function() safeCall(ns.RepositionFrames) end) end
if TargetFrame_ResetPosition then hooksecurefunc("TargetFrame_ResetPosition", function() safeCall(ns.RepositionFrames) end) end

-- Hook para mantener el ToT nativo oculto
if TargetFrameToT_Update then
    hooksecurefunc("TargetFrameToT_Update", function(self)
        if TargetFrameToT then
            TargetFrameToT:SetAlpha(0)
            TargetFrameToT:EnableMouse(false)
        end
    end)
end

-- Eventos principales
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        SafeUpdateHook()
        
        if not ns.totInitialized then
            safeCall(ns.InitCustomToT)
            safeCall(ns.ApplyHealthBarColors) -- Hooks globales de colores de salud
            ns.totInitialized = true
        end
    end
end)

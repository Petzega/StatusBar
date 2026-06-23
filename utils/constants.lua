local addonName, ns = ...

ns.TEXTURE_PATH = "Interface\\AddOns\\StatusBar\\dota_bar"

ns.BAR_WIDTH = 320     -- Ancho largo estilo Dota 2
ns.HEALTH_HEIGHT = 22  -- Más alto
ns.MANA_HEIGHT = 10    -- Barra de maná/poder

ns.TOT_WIDTH = 180
ns.TOT_HEALTH_HEIGHT = 14
ns.TOT_MANA_HEIGHT = 6
ns.TOT_ANCHOR_X = 10
ns.TOT_ANCHOR_Y = -7

ns.TOT_POWER_COLORS = {
    [0] = {0, 0, 1},        -- Mana (azul)
    [1] = {1, 0, 0},        -- Ira (rojo)
    [2] = {1, 0.5, 0.25},   -- Foco (naranja)
    [3] = {1, 1, 0},        -- Energia (amarillo)
    [6] = {0, 0.82, 1},     -- Poder Runico (celeste)
}

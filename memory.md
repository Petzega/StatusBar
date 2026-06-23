# Memoria del Proyecto StatusBar — Guía de Modificaciones

Este archivo sirve como el "mapa de memoria" del proyecto. Consulta esta guía para saber exactamente en qué archivo y en qué línea modificar los tamaños, posiciones y estilos de cada elemento visual del addon.

## 1. Retratos (Fotos de los Personajes)
* **Tamaño y Recorte (Zoom) Principal:**
  * **Archivo:** `utils/helpers.lua` -> Función `ns.StylePortrait`.
  * **Tamaño Base:** `portrait:SetSize(size, size)` (El valor por defecto enviado desde `layout.lua` es `68`).
  * **Zoom / Esquinas:** Instrucción `portrait:SetTexCoord(0.05, 0.95, 0.05, 0.95)`. Cambiar el `0.05` por `0.10` o `0.15` recorta más los bordes (zoom-in) y vuelve las esquinas más cuadradas. Usar `0.05` deja asomar la transparencia nativa para dar un efecto de **esquinas redondeadas**.
* **Altura (Posición Y) Principal:**
  * **Archivo:** `utils/helpers.lua` -> Función `ns.StylePortrait`.
  * **Posición:** `portrait:SetPoint(point, anchorBar, relativePoint, offsetX, -10)`. El valor `-10` baja el retrato para centrarlo respecto a las dos barras apiladas (vida + maná).
* **Retrato del ToT (Target of Target):**
  * **Archivo:** `modules/tot.lua`.
  * **Tamaño:** `cTotPortrait:SetSize(42, 42)`. Mantiene la regla matemática de oro del proyecto: *El tamaño del retrato es el doble de la suma del alto de las barras de vida y maná.* (21px de barras = 42px de retrato).
  * **Altura:** `cTotPortrait:SetPoint("LEFT", cTotHP, "RIGHT", 0, -5)`.

## 2. Íconos de Facción / JcJ (Escudos Horda/Alianza)
El diseño exige **simetría**. El ícono de JcJ siempre se ancla en la esquina inferior horizontalmente opuesta al texto del Nivel del personaje.
* **Jugador, Objetivo y Foco:**
  * **Archivo:** `modules/layout.lua` -> Función `ns.CustomStyleFrames`.
  * **Jugador:** `PlayerPVPIcon:SetPoint("CENTER", PlayerPortrait, "BOTTOMLEFT", 0, 0)` (El nivel está a la derecha).
  * **Objetivo / Foco:** `TargetFrameTextureFramePVPIcon:SetPoint("CENTER", TargetFramePortrait, "BOTTOMRIGHT", 0, 0)` (El nivel está a la izquierda).
* **ToT (Target of Target):**
  * **Archivo:** `modules/tot.lua` (Fue creado manualmente ya que WoW no provee ícono JcJ nativo para el ToT).
  * **Posición:** `cTotPVPIcon:SetPoint("CENTER", cTotPortrait, "BOTTOMRIGHT", 0, 0)`.

## 3. Barras de Vida y Maná (Tamaños Base)
* **Configuración Global (Marcos Grandes):**
  * **Archivo:** `utils/constants.lua`.
  * `ns.BAR_WIDTH = 320` (Ancho total).
  * `ns.HEALTH_HEIGHT = 22` (Alto de la vida).
  * `ns.MANA_HEIGHT = 10` (Alto del maná).
* **Configuración del ToT:**
  * **Archivo:** `utils/constants.lua`.
  * `ns.TOT_WIDTH = 120`.
  * `ns.TOT_HEALTH_HEIGHT = 14`.
  * `ns.TOT_MANA_HEIGHT = 6`.

## 4. Textos (Nombres y Niveles)
* **Nivel Dorado (Badge en la esquina de la foto):**
  * **Objetivo:** `modules/layout.lua` -> `ns.AlignTargetTexts`. Instrucción: `TargetFrameTextureFrameLevelText:SetPoint(...)`.
  * **ToT:** `modules/tot.lua` -> `cTotLevel:SetPoint(...)`.
* **Nombre de Unidad:**
  * **Objetivo:** `modules/layout.lua` -> `TargetFrameNameBackground:Hide()` (limpia el fondo nativo) y reposicionamiento de la fuente nativa.
  * **ToT:** `modules/tot.lua` -> `cTotName:SetPoint("BOTTOM", cTotHP, "TOP", 0, 5)`.

## 5. Limpieza de Interfaz (CleanDefaultTextures)
* **Texturas Nativas:**
  * **Archivo:** `utils/helpers.lua` -> `ns.CleanDefaultTextures`.
  * Este bucle oculta iterativamente todos los marcos y bordes artísticos antiguos de Blizzard. 
  * **Cuidado:** Si un ícono original de WoW que necesitamos (ej. JcJ, Portrait, etc.) desaparece por accidente, debes añadirlo como una "excepción" dentro del bucle (`isPVP` / `isPortrait`) para que el limpiador lo ignore.

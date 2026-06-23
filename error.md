# Registro de Errores y Lecciones Aprendidas — StatusBar Addon

Este documento registra los errores encontrados durante el desarrollo del addon, sus causas raíz y las soluciones aplicadas, para evitar repetirlos en el futuro.

---

## Error 1: Intentar mover `TargetFrameToT` con `SetPoint` relativo a `TargetFrame`

### Síntoma
Se cambió el anclaje del ToT de coordenadas absolutas (`UIParent`) a relativas (`TargetFrame`), pero el ToT seguía apareciendo **encima** del Target en vez de al costado derecho.

### Causa Raíz
`TargetFrame` tiene un **ancho nativo mucho mayor** que el ancho visual de las barras de vida (320px). WoW internamente mantiene el ancho original del marco (que incluye espacio para retrato, bordes decorativos, etc.), por lo que el punto `TOPRIGHT` de `TargetFrame` **no coincide** con el borde visual derecho de la barra de vida.

### Intento de Solución (Fallido)
Anclar el ToT a `TargetFrameHealthBar` en vez de `TargetFrame`:
```lua
TargetFrameToT:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", 10, 0)
```

### Por Qué Falló
Ver Error 2.

### Lección
> **Nunca asumir que el ancho de un marco padre de Blizzard coincide con el ancho visual de sus barras hijas.** El `TargetFrame` nativo contiene texturas de retrato, bordes y marcos adicionales que amplían su tamaño real más allá de lo visible tras la personalización.

---

## Error 2: Intentar forzar la posición del ToT nativo con `OnUpdate` y hooks

### Síntoma
Se implementaron hasta **tres mecanismos simultáneos** para forzar la posición del `TargetFrameToT`:
1. `hooksecurefunc(TargetFrameToT, "SetPoint", ...)` — interceptar cada `SetPoint`
2. `hooksecurefunc("TargetFrameToT_Update", ...)` — forzar posición tras cada actualización
3. `OnUpdate` en cada frame renderizado

A pesar de todo, el ToT **nunca se movió** de su posición original encima del Target.

### Causa Raíz
`TargetFrameToT` es un **Secure Unit Frame** (marco de unidad seguro). WoW 3.3.5a tiene dos protecciones que lo hacen inamovible:

1. **Posición controlada desde C++ (no Lua):** La función interna `TargetFrameToT_Update` de WoW recalcula la posición del ToT desde código C++ compilado del cliente. Los hooks de Lua (`hooksecurefunc`) se ejecutan **después** de la función original, pero el motor C++ puede volver a aplicar la posición en el mismo ciclo de renderizado, **después** de que nuestro hook termine.

2. **Zona de clic (hit rect) inamovible:** Incluso si lográramos mover visualmente el marco, la zona donde WoW registra los clics del ratón permanece en la posición original determinada por el código C++. Esto significa que:
   - El usuario ve el ToT en la nueva posición
   - Pero al hacer clic ahí, **no pasa nada**
   - El clic solo funciona en la posición original (donde ya no se ve el ToT)

### Intento de Solución (Fallido)
Hook agresivo en `SetPoint` con guard de recursión:
```lua
local totPositionLock = false
hooksecurefunc(TargetFrameToT, "SetPoint", function(self)
    if totPositionLock then return end
    totPositionLock = true
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", 10, 0)
    totPositionLock = false
end)
```

### Por Qué Falló
- El hook de `SetPoint` en un Secure Frame puede causar **taint** (contaminación del entorno seguro), lo que silenciosamente bloquea las llamadas o causa errores no visibles.
- Incluso sin taint, WoW re-aplica la posición desde C++ **después** de que todos los hooks de Lua terminan.

### Solución Correcta
**No intentar mover el `TargetFrameToT` nativo.** En su lugar:
1. Ocultar el ToT nativo: `SetAlpha(0)` + `EnableMouse(false)`
2. Crear un marco **completamente nuevo** con `SecureUnitButtonTemplate` parented a `UIParent`
3. Posicionar el marco nuevo donde se desee
4. Actualizar los datos (vida, maná, nombre) manualmente vía `OnUpdate` y eventos

```lua
-- Marco propio que SÍ se puede posicionar libremente
local customToT = CreateFrame("Button", "StatusBar_CustomToT", UIParent, "SecureUnitButtonTemplate")
customToT:SetAttribute("unit", "targettarget")
customToT:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", 10, 0)
```

### Lección
> **Nunca intentar mover un Secure Unit Frame nativo de WoW (TargetFrameToT, TargetFrame, PlayerFrame como hijos seguros, etc.).** Su posición y zona de clic están controladas desde código C++ del cliente. La única solución fiable es **ocultarlo y reemplazarlo con un marco propio**.

---

## Error 3: Usar `SecureActionButtonTemplate` con macro `/target targettarget`

### Síntoma
Se creó un botón overlay con `SecureActionButtonTemplate` usando una macro para seleccionar al targettarget:
```lua
totClickOverlay:SetAttribute("type", "macro")
totClickOverlay:SetAttribute("macrotext", "/target targettarget")
```

### Problema Potencial
El comando `/target` en WoW busca unidades **por nombre**, no por unit ID. Escribir `/target targettarget` intenta buscar un jugador/NPC literalmente llamado "targettarget", no la unidad `targettarget`.

### Solución Correcta
Usar `SecureUnitButtonTemplate` con el atributo `unit` directamente:
```lua
local customToT = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate")
customToT:SetAttribute("unit", "targettarget")
customToT:RegisterForClicks("AnyUp")
```
Esto le dice a WoW: "cuando el usuario haga clic en este botón, selecciona la unidad `targettarget`". El unit ID es interpretado correctamente por el sistema seguro.

### Lección
> **Para seleccionar unidades por unit ID al hacer clic, usar `SecureUnitButtonTemplate` con `SetAttribute("unit", "unitId")`, NO macros con `/target`.** Las macros de `/target` buscan por nombre textual, no por unit ID del API.

---

## Error 4: Parenting el botón de clic al marco nativo que estamos ocultando

### Síntoma
El botón de clic se creó como hijo de `TargetFrameToT`:
```lua
local totClickOverlay = CreateFrame("Button", "...", TargetFrameToT, "SecureActionButtonTemplate")
totClickOverlay:SetAllPoints(TargetFrameToT)
```

### Problema
Como `TargetFrameToT` tiene su posición controlada por WoW (C++), el botón hijo hereda esa posición. La zona de clic del overlay está en la posición **del ToT nativo** (que no podemos mover), no en la posición visual donde queremos que esté.

### Solución Correcta
El marco personalizado (que reemplaza al ToT nativo) debe ser parented a `UIParent`, no a `TargetFrameToT`:
```lua
local customToT = CreateFrame("Button", "StatusBar_CustomToT", UIParent, "SecureUnitButtonTemplate")
```
Así el marco y su zona de clic están donde nosotros los posicionamos, independientes de `TargetFrameToT`.

### Lección
> **Nunca hacer hijos de marcos seguros nativos que no puedes controlar.** Si necesitas un botón clickeable en una posición personalizada, hazlo hijo de `UIParent` y posiciónalo manualmente.

---

## Error 5: Ocultar o Mostrar manualmente un Secure Unit Frame (`customToT:Show()`)

### Síntoma
El ToT personalizado, a pesar de estar correctamente creado, desapareció por completo y ya no se mostraba bajo ninguna circunstancia.

### Causa Raíz
El nuevo ToT es un `SecureUnitButtonTemplate`. En WoW, llamar a `:Show()` o `:Hide()` manualmente sobre un frame de unidad seguro desde Lua (ej. en un `OnUpdate`) puede causar fallos de visibilidad porque **el motor de la UI (C++) espera gestionar el ciclo de vida visual de ese botón** de acuerdo con la existencia de la unidad asociada. Además, hacerlo en combate causa *taint* y bloqueos, pero incluso fuera de combate, el motor de estado del frame seguro se dessincroniza con los intentos manuales de forzar su visibilidad.

### Intento de Solución (Fallido)
Verificar si el targettarget existe en un `OnUpdate` y forzar `:Show()` o `:Hide()`:
```lua
if not UnitExists("targettarget") then
    customToT:Hide()
else
    customToT:Show()
end
```

### Por Qué Falló
La visibilidad del estado seguro es sobreescrita por el motor C++ o resulta en un estado corrupto si el frame no está registrado en el sistema nativo de watch.

### Solución Correcta
Delegar completamente la gestión de la visibilidad al motor interno de WoW usando **`RegisterUnitWatch()`**, que ata automáticamente la visibilidad del marco a la existencia de la unidad asignada a su atributo `unit`:
```lua
-- Al momento de crear el customToT
customToT:SetAttribute("unit", "targettarget")
RegisterUnitWatch(customToT) -- WoW lo oculta si no hay targettarget, y lo muestra si lo hay

-- Y en UpdateCustomToT quitamos las llamadas manuales y solo actualizamos valores:
local function UpdateCustomToT()
    if not customToT:IsVisible() then return end
    -- ... (actualizar barras y texto)
end
```

### Lección
> **No uses `:Show()` o `:Hide()` directamente en marcos Secure Unit.** Configura su atributo `unit` y utiliza `RegisterUnitWatch(frame)` para que WoW muestre y oculte el marco automáticamente de forma segura.

---

## Resumen de Reglas de Oro

| # | Regla | Razón |
|---|-------|-------|
| 1 | **No mover Secure Unit Frames nativos** | Posición y hit rect controlados desde C++ |
| 2 | **Ocultar + Reemplazar** en vez de mover | Único enfoque fiable para marcos seguros |
| 3 | **Usar `SecureUnitButtonTemplate`** para clicks en unidades | `SetAttribute("unit", "unitId")` funciona correctamente, macros no |
| 4 | **Parent a `UIParent`**, no al marco nativo | Evita heredar restricciones de posición del marco seguro |
| 5 | **Usar `RegisterUnitWatch` para visibilidad** *(solo unidades base)* | `Show()`/`Hide()` manuales fallan/taintean los Secure Unit Frames |
| 6 | **No asumir que el ancho del frame padre = ancho visual** | WoW mantiene dimensiones originales internamente |
| 7 | **Hookear `SetPoint` en frames seguros puede causar taint** | Los hooks en métodos de frames seguros son peligrosos |
| 8 | **No usar `RegisterUnitWatch` con unidades derivadas** | Solo acepta tokens base (`target`, `focus`, `player`, etc.) |

---

## Error 6: `RegisterUnitWatch` no funciona con unidades derivadas como `"targettarget"`

### Síntoma
El ToT personalizado (creado con `SecureUnitButtonTemplate` y `SetAttribute("unit", "targettarget")`) dejó de mostrarse por completo. Ni `RegisterUnitWatch` ni la eliminación de `:Hide()` restauraron la visibilidad.

### Causa Raíz
`RegisterUnitWatch` internamente llama a `RegisterStateDriver` con la condición macro `[@targettarget,exists]`. En WoW 3.3.5, el sistema de state drivers seguros solo acepta **unit tokens base** (`"player"`, `"target"`, `"focus"`, `"pet"`, `"party1-4"`, `"raid1-40"`, etc.). Las unidades derivadas/compuestas como `"targettarget"`, `"focustarget"`, `"pettarget"` **no son tokens válidos** para el state driver.

Esto causa que `RegisterUnitWatch` falle silenciosamente:
- No registra ningún state driver
- El frame queda en un estado indefinido (ni mostrado ni ocultado por el sistema)
- Combinado con una llamada anterior a `:Hide()`, el frame quedaba permanentemente oculto

### Intento de Solución (Fallido)
Quitar la llamada a `:Hide()` y confiar en `RegisterUnitWatch`:
```lua
-- Creación sin Hide()
local customToT = CreateFrame("Button", "StatusBar_CustomToT", UIParent, "SecureUnitButtonTemplate")
customToT:SetAttribute("unit", "targettarget")
RegisterUnitWatch(customToT) -- Falla silenciosamente
```

### Por Qué Falló
Sin `Hide()`, el frame se creaba como "shown" pero sin posición (`SetPoint`), por lo que no se renderizaba. Y `RegisterUnitWatch` no hacía nada porque `"targettarget"` no es un unit token válido.

### Solución Correcta
No usar `RegisterUnitWatch` para unidades derivadas. En su lugar, gestionar la visibilidad **exclusivamente vía `SetAlpha`** en la función de actualización, y fijar `EnableMouse(true)` **una sola vez** durante la creación del marco:

```lua
-- Al crear el marco:
customToT:EnableMouse(true) -- NUNCA CAMBIAR ESTO DESDE UN ONUPDATE

-- En el OnUpdate:
local function UpdateCustomToT()
    if not UnitExists("targettarget") then
        customToT:SetAlpha(0)       -- Visualmente invisible (el clic sigue activo, pero sin unit no hace nada grave)
        return
    end
    
    customToT:SetAlpha(1)       -- Visible
    -- ... actualizar barras y textos ...
end
```

**¿Por qué NO alternar `EnableMouse()` en el OnUpdate?**
Porque `UpdateCustomToT` es ejecutado desde una ruta de ejecución insegura (el script de `OnUpdate`). Llamar a `EnableMouse(true/false)` en un Secure Frame desde una ruta insegura causa **Taint**, lo que rompe los clics silenciosamente (los clics dejan de seleccionar la unidad).

### Lección
> **`RegisterUnitWatch` solo funciona con unit tokens base.** Para unidades derivadas como `targettarget`, fija `EnableMouse(true)` UNA sola vez al crearlo, y usa exclusivamente `SetAlpha(0)` o `SetAlpha(1)` en un `OnUpdate` para controlar la visibilidad visual sin causar taint ni romper el ciclo de vida seguro del frame.

---

## Error 7: Usar `SetPoint` en un Secure Frame desde un OnUpdate durante el Combate

### Síntoma
El ToT personalizado, tras estar funcionando correctamente, se quedaba atascado en el centro de la pantalla (su posición inicial) cuando el jugador entraba en combate con un enemigo, en vez de reposicionarse al costado de la barra del objetivo.

### Causa Raíz
El ToT es un `SecureUnitButtonTemplate`. En World of Warcraft, cambiar la posición (`SetPoint`, `ClearAllPoints`) o el tamaño de un frame seguro mediante código de UI normal (inseguro) está **bloqueado por el motor** mientras el jugador está en estado de combate (`InCombatLockdown()`). 
Si se intenta, la acción falla silenciosamente o lanza un error de acción bloqueada (`Action Blocked by Blizzard UI`).

### Intento de Solución (Fallido)
Actualizar la posición en la función constante `UpdateCustomToT` (llamada desde `OnUpdate`):
```lua
customToT:ClearAllPoints()
customToT:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", 10, -7)
```

### Por Qué Falló
Fuera de combate funcionaba, pero en combate el engine bloqueaba el `SetPoint` por seguridad, dejando el frame huérfano en su posición inicial (centro).

### Solución Correcta
**Anclar el frame de forma estática una sola vez en la inicialización.** 
En vez de intentar recalcular la posición en cada frame, hacemos que el ToT sea "hijo posicional" del TargetFrame:

```lua
function ns.InitCustomToT()
    -- ...
    -- ANCLAJE ESTATICO: Se fija una sola vez. Cuando TargetFrame se mueve, el ToT se mueve con él.
    customToT:SetPoint("TOPLEFT", TargetFrameHealthBar, "TOPRIGHT", 10, -7)
    -- ...
end
```
Con esto, no es necesario tocar el `SetPoint` dinámicamente; el sistema de renderizado del cliente lo moverá junto a la barra del objetivo.

### Lección
> **Los Secure Frames no pueden cambiar de posición o tamaño por código mientras el jugador está en combate.** Para marcos UI anclados a otros elementos dinámicos, usa anclajes estáticos (`SetPoint`) durante el evento de inicialización en vez de reposicionamientos dinámicos por frame o temporizador.

---

## Error 8: Llamar `SetUserPlaced(true)` en TargetFrame lanza error

### Síntoma
Aparece el error rojo: `ERROR: modules\layout.lua:XX: Frame TargetFrame is not movable or resizable`.

### Causa Raíz
Se usó `TargetFrame:SetUserPlaced(true)` al momento de definir su nueva ubicación en pantalla en la función de inicialización. Por defecto, los marcos base de la interfaz como `PlayerFrame`, `TargetFrame` o `FocusFrame` **no están marcados internamente como `movable`** (`frame:IsMovable() == false`) por Blizzard, y llamar `SetUserPlaced` sobre un marco inamovible lanza una excepción inmediata.

### Intento de Solución (Fallido)
Ignorar la excepción, lo que provocaba que el hook de `PLAYER_ENTERING_WORLD` abortara prematuramente e impidiera la ejecución del resto del código de rediseño (los estilos dejaban de cargar).

### Solución Correcta
**No llamar a `SetUserPlaced(true)` en marcos nativos a menos que les hagas `SetMovable(true)` previamente.** En nuestro caso, dado que ya estamos usando hooks en `TargetFrame_ResetPosition` para mantener nuestra posición forzada tras cambios de interfaz, basta con simplemente omitir la llamada a `SetUserPlaced(true)`.

```lua
    if TargetFrame then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 10, 160)
        -- TargetFrame:SetUserPlaced(true) -- ELIMINADO para evitar crash
    end
```

### Lección
> **Nunca uses `SetUserPlaced(true)` en marcos creados por Blizzard sin confirmar primero que sean "Movable".** Si tu propio código de addon re-aplica sistemáticamente los anclajes visuales mediante hooks, no necesitas decirle a WoW que guarde la posición usando `SetUserPlaced`.

---

## Error 9: Íconos de JcJ nativos invisibles por limpieza agresiva de texturas

### Síntoma
Los íconos de Horda/Alianza del Target y del Foco dejaron de renderizarse en pantalla, a pesar de usar `SetPoint` correctamente. El ícono del jugador sí se veía.

### Causa Raíz
La función utilitaria `ns.CleanDefaultTextures(frame)` recorría recursivamente todos los objetos de tipo `"Texture"` dentro de los TextureFrames de los marcos nativos, asignándoles `SetTexture(nil)` y `SetAlpha(0)` para ocultar el arte por defecto de Blizzard. Esto borraba silenciosamente los objetos `TargetFrameTextureFramePVPIcon` y `FocusFrameTextureFramePVPIcon`.

### Solución Correcta
Se añadieron exclusiones matemáticas y explícitas en el bucle iterativo para proteger objetos visuales vitales:
```lua
local isPVP = (region == PlayerPVPIcon) or (region == TargetFrameTextureFramePVPIcon) or (region == FocusFrameTextureFramePVPIcon)
if not isPVP then
    -- Ocultar textura...
end
```

### Lección
> **Nunca ejecutar una limpieza en bucle a ciegas.** Al limpiar la interfaz de WoW iterando sobre `GetRegions()`, siempre documenta y preserva (vía condicionales `if`) los frames/texturas nativas que usarás posteriormente para la UI, o la limpieza será destructiva.

---

## Error 10: Fondos cuadrados duros detrás de retratos con esquinas redondeadas

### Síntoma
Al reducir el recorte de la textura del retrato (`SetTexCoord(0.05, 0.95)`) para revelar las esquinas redondeadas nativas, unas puntas afiladas oscuras seguían asomándose por las esquinas del retrato.

### Causa Raíz
Se había asignado un `customBg` (textura gris muy oscura con 2px de margen) detrás de cada retrato para imitar el marco de las barras. Sin embargo, las texturas en WoW 3.3.5 no soportan "border-radius". El fondo era un cuadrado duro, y las esquinas transparentes redondeadas del retrato de adelante simplemente dejaban ver las puntas afiladas del cuadrado de atrás.

### Solución Correcta
Ocultar y eliminar completamente los fondos `customBg` de los retratos. El retrato con zoom (0.05) debe descansar directamente "desnudo" sobre la UI principal del juego; de ese modo, las esquinas transparentes mostrarán el terreno del juego 3D, creando una ilusión óptica perfecta de borde redondeado.

### Lección
> **No colocar fondos rectangulares oscuros detrás de texturas que requieren bordes suaves o redondeados por transparencia.** En UI flat, si una textura superior tiene esquinas suaves, su fondo no debe ser sólido si excede o iguala su tamaño.

---

## Error 11: Renderizado (Z-Index) cortado al superponer Barras y Retratos nativos

### Síntoma
Al poner un offset horizontal negativo para que el retrato se superpusiera con la barra de vida (creando un efecto de junte/suavizado), el motor de WoW dibujaba la barra de vida "cortando" por completo la imagen del retrato con una línea recta inestética.

### Causa Raíz
En el árbol jerárquico y motor de renderizado de WoW, los objetos tipo `Frame` (`StatusBar`, `PlayerFrameHealthBar`) siempre se dibujan en niveles de Z-Index (`FrameStrata` / `FrameLevel`) muy superiores a los de una textura básica (`PlayerPortrait` = `Texture`) que pertenece a un frame padre inferior.

### Solución Correcta
Se descartó la idea de solapamiento manual nativo, manteniendo el offset en `0` (separación de cero pixeles exactos). Al ser cajas de texturas en diferentes profundidades, se deben construir adjuntas una al lado de la otra sin sobreposición, y confiar en el diseño plano (Dota 2) para que se vean compactas.

### Lección
> **Los Frames nativos siempre cortarán visualmente a las Texturas simples en un superposición.** Evitar superponer elementos de distintos tipos (StatusBar vs Texture) para crear integraciones de diseño si no puedes reestructurar sus `FrameLevel`. Es mejor alinearlos con offset 0.

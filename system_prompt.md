# Contexto del Proyecto: StatusBar (WoW Addon)

Este documento sirve como un prompt del sistema y guía de referencia técnica para que cualquier Inteligencia Artificial o desarrollador continúe con el desarrollo del addon **StatusBar**.

## 1. Información General
* **Nombre del Addon:** StatusBar
* **Objetivo:** Rediseñar visualmente (reskin) y reposicionar los marcos de unidad predeterminados de World of Warcraft (Jugador, Objetivo, Foco y Objetivo del Objetivo) para darles un aspecto plano, moderno y minimalista al estilo del HUD de **Dota 2**, ubicados en la parte inferior-central de la pantalla.
* **Versión de WoW Soportada:** Wrath of the Lich King (WotLK / Parche 3.3.5a / Versión de Interfaz `30300`).
* **Lenguaje:** Lua (WoW API 3.3.5).
* **Estructura del Proyecto:**
  * `StatusBar.toc`: Archivo de metadatos para que el cliente de WoW cargue el addon.
  * `init.lua`: Define el namespace compartido del addon.
  * `utils/`: Contiene `constants.lua` y `helpers.lua` con configuraciones y funciones utilitarias.
  * `modules/`: Contiene `layout.lua`, `bars.lua` y `tot.lua` con la lógica separada.
  * `core.lua`: Archivo principal ultraligero que registra eventos y llama a los módulos.
  * `dota_bar.tga`: Textura plana y sin bordes.

---

## 2. Decisiones de Diseño y Reglas Críticas

Para evitar errores comunes de la interfaz de WoW y mantener la jugabilidad, se han establecido las siguientes reglas de implementación en `core.lua`:

### A. Ocultar Texturas Nativas de Forma Segura
El juego base tiene muchas texturas complejas (bordes decorativos de plata/oro, retratos 3D, íconos de combate/PvP, etc.). Para eliminarlas sin provocar errores en los scripts internos de Blizzard:
* Se usan funciones seguras como `SafeHide(texture)` (que remueve la textura, pone la transparencia a 0 y la oculta) y `CleanDefaultTextures(frame)` (que recorre los elementos hijos del marco para limpiarlos).
* Se evita borrar o hacer `nil` de marcos interactivos directamente para no generar fallos de "tinte" (tainting) ni romper los clics del ratón.

### B. Centrado y Bloqueo de Textos de Vida y Maná
Por defecto, WoW intenta posicionar y mover los textos de salud y recurso (maná, ira, energía) según su propio flujo. 
* Se utiliza la función `StandardizeText(textString, parentBar, fontSize)`.
* Dicha función aplica una fuente clara (`Fonts\\FRIZQT__.TTF`), un tamaño uniforme y un borde (`OUTLINE`) para máxima legibilidad.
* **Importante:** Se usa un hook seguro (`hooksecurefunc`) sobre el método `SetPoint` de cada texto para forzar su posición en el centro exacto de la barra correspondiente (`CENTER`, `parentBar`, `CENTER`, 0, 0) de manera persistente, bloqueando cualquier intento del juego de moverlo.

### C. Interactividad con Clic (Mouse Click Area)
En versiones previas, al mover componentes visuales internos (como cambiar el `SetPoint` de la barra de salud respecto a su marco padre), la zona donde el usuario hace clic para seleccionar al objetivo se desalineaba de la representación visual.
* **Regla de Oro:** La barra de salud (`HealthBar`) de todos los marcos debe permanecer exactamente en la posición `(0, 0)` (ej. `TargetFrameToTHealthBar:SetPoint("TOPLEFT", TargetFrameToT, "TOPLEFT", 0, 0)`). 
* Si se desea mover la barra de salud, se debe mover el **marco contenedor principal** (ej. `TargetFrameToT`), nunca mover la barra de salud de forma independiente usando offsets altos, para garantizar que la colisión de clics coincida exactamente con la barra visualizada.

---

## 3. Arquitectura Modular del Código

El addon utiliza el patrón **Addon Namespace** para evitar contaminar el entorno global, dividiendo las responsabilidades:

* **`init.lua`**: Crea la tabla `ns` compartida entre archivos.
* **`utils/constants.lua`**: Variables visuales (colores, tamaños `TOT_WIDTH`, anclajes `TOT_ANCHOR_X`).
* **`utils/helpers.lua`**: Funciones reutilizables (`SafeHide`, `ApplyCustomBackground`, `StandardizeText`).
* **`modules/layout.lua`**: Lógica de redimensionamiento de marcos (`CustomStyleFrames`) y reposicionamiento físico en pantalla (`RepositionFrames`).
* **`modules/bars.lua`**: Texturizado de las barras de vida/maná (`ApplyBarTextures`) y centrado de textos.
* **`modules/tot.lua`**: Archivo exclusivo para instanciar y actualizar el Target-of-Target personalizado.
* **`core.lua`**: Módulo centralizado. **Sólo** se encarga de escuchar eventos de WoW (`PLAYER_ENTERING_WORLD`, etc.) y aplicar hooks seguros (`hooksecurefunc`), delegando el trabajo real a los módulos.

---

## 4. Estado Actual: Target-of-Target (ToT) Personalizado

La necesidad del ToT es que sea movible a y este el lado derecho del target y no anclado por encima del target mismo. Adicionalmente es importante que el ToT sea clickeable para que cada vez que yo de click al ToT se vuelva el nuevo Target.

### El Problema del ToT Nativo
El marco `TargetFrameToT` es un **Secure Unit Frame** hijo directo de `TargetFrame`. Esto causa dos problemas irresolubles:
1. **Posición controlada desde C++**: WoW recalcula internamente la posición del ToT desde código C++, no solo Lua. Los intentos de moverlo con `ClearAllPoints()` / `SetPoint()` son revertidos silenciosamente.
2. **Zona de clic inamovible (hit rect)**: Incluso si el marco se mueve visualmente, la zona donde se registran los clics permanece en la posición original.

### La Solución: ToT Completamente Personalizado
Se oculta el ToT nativo (`SetAlpha(0)`, `EnableMouse(false)`) y se crea un marco nuevo con `SecureUnitButtonTemplate`:

* **Marco principal (`StatusBar_CustomToT`)**: Botón seguro parented a `UIParent`, con `unit = "targettarget"`. Al hacer clic, selecciona al Target-of-Target como nuevo objetivo.
* **Barras personalizadas**: `StatusBar_CToTHP` (vida) y `StatusBar_CToTMana` (poder), con textura Dota 2 y fondo oscuro.
* **Posicionamiento**: Anclado al costado derecho de `TargetFrameHealthBar` con offsets configurables.
* **Actualización**: Vía `OnUpdate` (throttled a ~10fps) y eventos clave (`PLAYER_TARGET_CHANGED`, `UNIT_TARGET`, `UNIT_HEALTH`, etc.).

* **Configuración del Usuario:**
  ```lua
  local TOT_ANCHOR_X = 10    -- Separación horizontal desde la barra de vida del Target
  local TOT_ANCHOR_Y = 0     -- Ajuste vertical (0 = alineado arriba)
  ```

---

## 5. Instrucciones para Continuar el Desarrollo

Si vas a realizar modificaciones en este addon:
1. **No modifiques posiciones ni tamaños por defecto de forma arbitraria** a menos que el usuario lo solicite directamente.
2. **Cómo probar cambios:** Guarda los archivos modificados y escribe `/reload` o `/reloadui` en el chat del juego para volver a cargar la interfaz y ver los efectos inmediatamente.
3. Si los textos no se muestran, verifica que los hooks secure funcionen correctamente y que no existan errores silenciosos de Lua (se recomienda usar addons como *BugSack* y *BugGrabber* en el cliente de prueba).
4. Recuerda mantener la coherencia en las coordenadas: el PlayerFrame está a la izquierda (`-10` en X) y TargetFrame a la derecha (`10` en X) respecto al centro. El Foco está encima de TargetFrame. El ToT personalizado está anclado al costado derecho de `TargetFrameHealthBar`.
5. **No intentes mover el `TargetFrameToT` nativo.** Es un Secure Unit Frame cuya posición y zona de clic son controladas internamente por WoW desde C++. Siempre usa el marco personalizado `StatusBar_CustomToT`.
6. El lenguaje de comentarios preferido por el usuario en el código es el **Español**.

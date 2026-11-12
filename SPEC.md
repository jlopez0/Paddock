# SPEC — App de juegos de fiesta (reconstrucción)

> Basado en el análisis de `app-release.apk` (v1.0.0, build 1). No se ha copiado código decompilado: solo se ha usado para entender el comportamiento.
> Leyenda: **[visto]** = comprobado ejecutando la app en el emulador · **[inferido]** = deducido de nombres/cadenas, sin confirmar.

## 1. Datos técnicos del APK

| Campo | Valor |
|---|---|
| Tecnología | **Flutter** (Dart AOT en `libapp.so`, Material 3). El código Java/Kotlin es solo el *embedding* estándar de Flutter. |
| Paquete | `com.example.flutter_application_1` (nombre por defecto, sin cambiar) |
| Nombre visible | `flutter_application_1` |
| minSdk / targetSdk | 21 / 35 |
| ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| Paquetes Dart | solo `flutter`, `cupertino_icons` (+ dependencias internas). **Sin** red, analítica, anuncios ni persistencia. |
| Permisos | **Ninguno real.** Solo `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, que AndroidX añade automáticamente. |
| Backend / SDK externos | **Ninguno.** App 100 % offline; no hay nada que "siga vivo" o no. |
| Persistencia | **Ninguna.** Jugadores y apuestas se pierden al salir de cada pantalla. |
| Icono | Icono por defecto de Flutter. |
| Orientación | Menús en vertical; carrera y preguntas en **horizontal** [visto]. |
| Tema | Material 3 por defecto (semilla morada), fondo claro. Tarjeta de preguntas rosa sobre degradado morado [visto]. |

### Estructura del código original (de las rutas en el binario)
```
lib/main.dart, routes.dart
lib/screens/home_screen.dart            menú principal
lib/screens/player_input_screen.dart    nombres de jugadores (preguntas)
lib/screens/game_screen.dart            juego de preguntas
lib/screens/horse_betting_screen.dart   apuestas de la carrera
lib/screens/horse_race_screen.dart      carrera
lib/models/pregunta.dart
lib/utils/game_manager.dart             carga preguntas, genera castigos, reemplaza {player}
lib/widgets/question_card.dart          color según dificultad
lib/assets/cards/*.png                  baraja española 48 cartas + reverso
lib/data/preguntas_normales.json        50 preguntas
lib/data/preguntas_hot.json             50 preguntas
```

## 2. Assets extraídos → `apk_assets/`

| Carpeta | Contenido |
|---|---|
| `cards/` | Baraja española: `{oros,copas,espadas,bastos}_{1..12}.png` + `reverso.png` (49 PNG) |
| `data/` | `preguntas_normales.json`, `preguntas_hot.json` |
| `icons/` | `ic_launcher` en 5 densidades (icono genérico de Flutter) |
| `strings/textos_ui.md` | Todos los textos de la UI y la lista de castigos |
| `screenshots/` | Capturas de la app original |

No hay sonidos, fuentes propias ni animaciones en Lottie/Rive.

> ⚠️ **Licencia de las cartas**: no consta su origen. Antes de publicar en las tiendas hay que confirmar que se pueden usar o sustituirlas por una baraja propia o con licencia libre.

## 3. Pantallas y flujo

```
Inicio ──► Jugadores ──► Juego de preguntas (horizontal)
   └────► Apuestas ──► Carrera (horizontal) ──► Diálogo resultado ──► Inicio
```

### 3.1 Inicio [visto]
- Título "¿Listos para jugar?"
- Desplegable **Modo de juego**: Normal / Fiesta / Hardcore [visto]. Probablemente ajusta la dureza de los castigos [inferido].
- Checkbox **Modo Hot 🔥**: añade `preguntas_hot.json` al mazo [inferido por `isHotMode`].
- Botones "🎉 Empezar" (preguntas) y "🏇 Carrera de Caballos".

### 3.2 Juego de preguntas [visto]
- Jugadores: campo de nombre + "Añadir" → chips con los nombres. Botón "Empezar".
- Una tarjeta a pantalla completa; **tocar la tarjeta** pasa a la siguiente. Botón ✕ para salir.
- Modelo de pregunta: `{ texto, categoria, tipo: normal|hot, dificultad: 1..4 }`.
- Plantillas: `{player}` → jugador aleatorio; `{castigo}` → castigo aleatorio (ver `apk_assets/strings`).
- Categorías: `bebe_si` (≈ "Yo nunca": *"Quien haya…, {castigo}"*), `reto`, `pregunta_hot`, `parejas`, `votacion`, `juego_rapido`, `reaccion`.
- El color de la tarjeta depende de la dificultad [inferido por `_colorPorDificultad`].

### 3.3 Apuestas (carrera) [visto]
- Por jugador: nombre, **palo** (Oros/Copas/Espadas/Bastos) y **tragos** (slider 1–10).
- Lista de apuestas añadidas (`Ana - oros / 4 tragos`), se pueden eliminar.
- "🏁 Iniciar carrera". No hay mínimo ni máximo de jugadores explícito.

### 3.4 Carrera de caballos [visto]
Es la versión de la clásica "carrera de caballos" con baraja española:

1. **Preparación**
   - Los 4 **caballos** (el 11 de cada palo) se colocan en la casilla de salida, uno por fila/palo.
   - Pista: salida + **5 casillas**.
   - **5 cartas obstáculo** boca abajo encima de las columnas 1–5.
   - Mazo = las 39 cartas restantes, barajadas (`shuffle`).
2. **Turno**: se toca el mazo → se descubre la carta superior → el caballo de **ese palo avanza 1**.
3. **Obstáculos**: cuando **todos** los caballos han alcanzado la columna *k*, se descubre el obstáculo *k* y el caballo de su palo **retrocede 1**.
4. **Victoria**: gana el primer caballo que avanza más allá de la última casilla (6 avances netos).
5. **Resultado** (diálogo):
   - "¡Ganador: COPAS!"
   - "🎉 Reparten tragos:" — quienes apostaron al ganador reparten lo apostado [inferido; en la prueba nadie acertó].
   - "🍺 Beben lo apostado:" — los demás beben lo que apostaron [visto].
   - "Volver a inicio" (no hay revancha).
- Aleatoriedad: solo el barajado inicial. Sin animaciones, sonido ni vibración; los caballos "saltan" de casilla.
- Caso no visto: qué ocurre si se agota el mazo.

## 4. Puntos débiles del original (a mejorar)
- Sin persistencia: hay que reescribir nombres y apuestas en cada carrera; sin historial ni marcador.
- Sin revancha ni "misma apuesta otra vez".
- Carrera sin animación, sin *feedback* (sonido/háptica) y sin tensión (no hay cuenta atrás, ni resaltado del líder ni de la carta sacada).
- Diseño Material por defecto, sin identidad visual; icono y nombre de paquete por defecto.
- Contenido de preguntas pequeño (100) y con el castigo siempre ligado a beber.
- No hay modo sin alcohol.

---

# FASE 2 — Propuesta

## Stack recomendado: **Flutter**

| | Flutter | Kotlin + Jetpack Compose |
|---|---|---|
| iOS | ✅ Un solo código para Android + iOS | ❌ Solo Android (Compose Multiplatform en iOS es posible, pero menos maduro en animación/ecosistema) |
| Animación 60/120 fps | ✅ Motor propio (Impeller), ideal para la pista animada | ✅ Muy bueno |
| Continuidad | ✅ El original ya era Flutter; los assets y el formato JSON encajan directamente | Habría que adaptarlo todo |
| Tamaño APK | ➖ ~8–10 MB más | ✅ Más ligero |
| Integración nativa | ➖ Vía plugins (suficiente: háptica, audio, almacenamiento) | ✅ Total |
| Entorno | ✅ Ya tienes Flutter 3.43 y Android SDK instalados | ✅ Android Studio instalado |

**Conclusión**: Flutter. Es el único que cubre Android + iOS con un único código y es muy bueno en animaciones 2D a medida, que es justo lo que pide la nueva carrera. (Para compilar y publicar en iOS hará falta un Mac o un servicio de CI como Codemagic.)

### Librerías
- **flutter_riverpod**: estado y dependencias, simple y fácil de probar.
- **go_router**: navegación.
- **drift** (SQLite): jugadores persistentes, historial de carreras y estadísticas. Si se prefiere algo más simple: `shared_preferences` + JSON (suficiente al principio, peor para estadísticas).
- **flutter_animate**: microanimaciones de la UI; la pista con `AnimatedPositioned`/`CustomPainter` (sin motor de juego: Flame es innecesario aquí).
- **audioplayers** + `HapticFeedback`: sonido y vibración.
- **google_fonts** (o una fuente incluida), y tema propio claro/oscuro.

## Arquitectura (simple, por *features*)

```
lib/
  app/            app.dart, router.dart, theme/ (colores, tipografía)
  core/           players/ (jugadores persistentes, repos), db/, audio/, widgets comunes
  games/
    game_module.dart        contrato de un juego
    registry.dart           lista de módulos → genera el menú
    horse_race/             domain/ (motor puro, testeable) · ui/ · horse_race_module.dart
    never_have_i_ever/      "Yo nunca"
    would_you_rather/       "¿Qué preferirías?"
assets/
  cards/                    baraja
  content/es/
    yo_nunca.json
    que_preferirias.json
    castigos.json
```

### Modularidad
Cada juego implementa un contrato mínimo:
```dart
abstract class GameModule {
  String get id; String get title; String get description;
  IconData get icon; Color get color;
  int get minPlayers;
  Widget buildEntry(BuildContext ctx);   // pantalla de entrada del juego
}
```
`registry.dart` es una lista de módulos; el menú principal se genera a partir de ella. **Añadir un juego = crear su carpeta + una línea en el registro.**

### Contenido en datos (no hardcodeado)
Formato JSON común para los juegos de cartas/preguntas:
```json
{ "id": "yn_001", "texto": "Yo nunca he fingido estar ocupado para evitar una videollamada",
  "nivel": "suave|picante|hot", "tags": ["social"] }
```
`¿Qué preferirías?` usa `{ "id", "a", "b", "nivel" }`. Los castigos van en `castigos.json`, con intensidad, y el modo **"sin alcohol"** sustituye los tragos por retos o puntos. Un `ContentRepository` carga los ficheros por idioma, de modo que más adelante se podrían descargar paquetes remotos sin tocar el código.

## Carrera de caballos renovada — propuesta
- **Jugadores persistentes**: lista global (nombre, color/avatar) que se reutiliza en todos los juegos; se eligen con chips en lugar de reescribirlos.
- **Apuestas ágiles**: tarjeta por jugador → toca un palo y ajusta los tragos con −/+; "Repetir apuestas" para la revancha.
- **Pista animada** (horizontal): calles con el color del palo, caballos que se deslizan con un pequeño rebote, carta sacada que "vuela" desde el mazo, obstáculo que se voltea en 3D con un retroceso visible, el líder resaltado, cámara lenta y confeti en la meta.
- **Ritmo**: tocar para sacar carta o **modo automático** (velocidad ajustable), además de vibración y sonido (galope, volteo, meta) que se pueden desactivar.
- **Ajustes de la partida**: longitud de la pista (5–8), obstáculos sí/no, multiplicador para quien acierta.
- **Resultado y marcador**: podio, quién bebe/reparte y cuánto, botón **Revancha**; historial y estadísticas por jugador (victorias, aciertos, tragos bebidos/repartidos) que se guardan entre carreras.
- **Motor puro en Dart** (`RaceEngine`), separado de la UI, con semilla para tests: reglas comprobadas con tests unitarios (avance, obstáculos, mazo agotado → se rebaraja el descarte, victoria).
- Estética: tema oscuro tipo "hipódromo nocturno" (verde césped/negro con acentos dorados), tipografía redondeada y cartas con sombras suaves; también tema claro.

## Decisiones tomadas en la implementación
- **Persistencia**: `shared_preferences` + JSON en vez de drift. Los datos son pocos (jugadores, últimas apuestas, ajustes y estadísticas) y así no hace falta generar código. Todo pasa por controladores Riverpod, por lo que migrar a SQLite más adelante solo afecta a esos archivos.
- **Cartas**: baraja "Naipes Libres" de Wikimedia Commons (CC BY-SA 3.0, Basquetteur / Germarquezm). Las cartas 1–9 y el reverso salen del SVG y las figuras del PNG completo. La atribución está en la pantalla de Créditos.
- **Sin modo "sin alcohol"** (por decisión del usuario).
- **Pendiente**: sonidos (no hay assets con licencia elegidos), tema claro, icono y nombre definitivos (provisional: "Paddock", `com.paddock.paddock`).

## Plan de implementación (Fase 3, commits pequeños)
1. Proyecto Flutter + tema + router + menú generado desde el registro.
2. Jugadores persistentes (drift) + pantalla de gestión.
3. Motor de la carrera + tests.
4. UI de apuestas → pista animada → resultado/revancha → estadísticas.
5. Motor genérico de "cartas de preguntas" + Yo nunca + ¿Qué preferirías? con banco inicial en español.
6. Sonido/háptica, icono provisional, pruebas en el emulador en cada paso.

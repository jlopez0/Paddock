# Paddock: diseño con alma

Fecha: 2026-11-24. Solo investigación; no se ha tocado código ni assets.
Las licencias marcadas "verificada" se leyeron en la página oficial del recurso durante esta investigación. Lo que no se pudo verificar se dice expresamente.

## (a) Diagnóstico: por qué se ve genérico

Causas, con datos del repo:

1. **Emoji de sistema como único sistema gráfico.** 46 líneas de `lib/` con emoji. Cada plataforma los dibuja distinto (Samsung, Pixel, iOS, Windows), así que la app nunca tiene el mismo aspecto en dos móviles. En Windows las banderas emoji (🇺🇸 🇲🇽 🇪🇸 🇯🇵) salen como letras ("US").
2. **Mezcla de dos lenguajes sin criterio.** 52 usos de `Icons.*_rounded` (Material redondeado, el aspecto por defecto de Flutter) conviven con los emoji. No hay una familia de iconos.
3. **Cero tipografía propia.** No hay `fontFamily` ni fuentes en `pubspec.yaml`. Todo es Roboto/SF con `fontWeight` 700/800. Los títulos de juego y el podio se leen igual que cualquier ajuste.
4. **La paleta es buena pero el material no.** El verde #0B1611 y el dorado #E8B84A dan "hipódromo nocturno" (`lib/app/theme.dart`), pero las tarjetas son rectángulos redondeados con degradado, el patrón que más se ve en apps generadas.
5. **Cero ilustración y cero microanimación.** El único elemento propio es el icono de la P dorada.
6. **El emoji hace de ilustración en pantallas de ceremonia** (podio, resultado, revelar al infiltrado) a 56-72 px. Ahí se nota más lo genérico.

### Inventario de emoji (archivo:línea, a fecha de hoy con el árbol de trabajo sin commitear)

| Archivo:línea | Emoji | Función |
|---|---|---|
| `app/cup_screen.dart:45-47` | 🥇🥈🥉 | Medalla del puesto en el podio de la Copa |
| `app/cup_screen.dart:59` | 🏆 | Cabecera del texto que se comparte (sale de la app) |
| `app/cup_screen.dart:131` | 🏆 | Icono de cabecera de la tarjeta de la Copa |
| `app/cup_screen.dart:254` | 🏆 | Ilustración principal (56 px) de la pantalla de la Copa |
| `app/cup_screen.dart:346` | 📉 | Icono del "peor de la noche" |
| `core/content/prompts.dart:7-9` | 😇🌶️🔥 | Niveles Suave/Picante/Atrevido (chips y etiqueta de carta) |
| `games/game_module.dart` + 5 módulos | 🏇🕵️🧠🌍🔤 | Icono de juego en el menú (`String get emoji`) |
| `games/registry.dart:22,33,44` | 👉🤔🙊 | Icono de juego: ¿Quién es más probable?, ¿Qué preferirías?, Yo nunca |
| `app/home_screen.dart:135` | (campo `emoji`) | Pinta el icono del juego en la tarjeta del menú (44 px) |
| `games/prompt_deck/prompt_deck_screens.dart:73` | (campo `emoji`) | Hero del juego en la pantalla de reglas (72 px) |
| `games/prompt_deck/prompt_deck_screens.dart:572` | nivel | Etiqueta de nivel en la carta |
| `games/prompt_deck/prompt_deck_screens.dart:723` | 🎉 | Pantalla de fin de mazo (64 px) |
| `games/prompt_deck/level_chips.dart:72`, `infiltrado_setup_screen.dart:196` | nivel | Chips de nivel |
| `games/abecedario/ui/abecedario_play_screen.dart:540` | 🔤 | Ilustración de la pantalla de fin (64 px) |
| `games/geography/domain/quiz.dart:29-37` | 🏳️🏛️📍🗺️🎲🇺🇸🇲🇽🇪🇸🇯🇵 | Icono de cada categoría de Geografía |
| `games/geography/ui/geo_quiz_screen.dart:278` | 🔥 | Contador de racha |
| `games/geography/ui/geo_result_screen.dart:25,45` | 🌍 🏆 | Texto de resultado "¡Perfecto! 🌍" y "¡Nuevo récord!" |
| `games/trivia/trivia_data.dart:13-19` | 🏛️🔬🌿🎨⚽🎬🧩 | Icono de cada categoría de Trivia (chips y cabecera de pregunta) |
| `games/trivia/ui/trivia_result_screen.dart:19` | 🧠 | Texto de resultado perfecto |
| `games/horse_race/ui/race_setup_screen.dart:167` | 🏁 | Icono del botón de empezar carrera |
| `games/horse_race/ui/race_screen.dart:678` | 🏆 | Cartel de "¡GANA!" |
| `games/horse_race/ui/race_result_screen.dart:127,140` | 🎉 💸 | Cabeceras "Reparten" y "Pagan" |
| `games/horse_race/ui/race_stats_screen.dart:98` | 🥇🥈🥉 | Medallas del ranking de estadísticas |
| `games/infiltrado/ui/infiltrado_reveal_screen.dart:140` | 🕵️ | Hero de revelar rol (56 px) |
| `games/infiltrado/ui/infiltrado_widgets.dart:137` | 📱 | "Pasa el móvil" (64 px) |
| `games/infiltrado/ui/infiltrado_widgets.dart:179` | 🕵️ | Hero de la pantalla de espera |
| `games/infiltrado/ui/infiltrado_vote_screen.dart:118` | ⚖️ | Hero de votación |
| `games/infiltrado/ui/infiltrado_result_screen.dart:127,207` | 🎯 🕵️/🎉 | Hero de resultado y estado ganan impostores / ganan los demás |

Resumen por función: 10 iconos de juego, 17 iconos de categoría y nivel, 5 medallas y trofeos, 9 héroes o ilustraciones de pantalla a 56-72 px, 5 emoji dentro de texto, 1 en texto de compartir.

## (b) Dirección de arte

**Una frase:** *"Casa de apuestas de hipódromo de los años 30 de noche: fieltro verde, latón dorado y cartelería de madera, con fichas, boletos y medallas dibujados en vez de emoji."*

Material coherente: todo lo "físico" (ficha, boleto, medalla, trofeo) se dibuja con la paleta, y los iconos son de línea o duotono dorado.

### Paleta

Se mantiene la actual y se añaden pocos tokens, en `AppColors`:

| Token | Valor | Uso |
|---|---|---|
| background / surface / outline | #0B1611 / #13241B / #2B4636 | Ya existen |
| gold | #E8B84A | Acento principal, iconos duotono (capa principal) |
| brass (nuevo) | #B8862B | Bordes de ficha, filetes, sombra de medalla |
| paper (nuevo) | #F3EFE0 (= `text`) | Boletos y tarjetas de carta |
| burgundy (nuevo) | #7A2430 | Fondo de la Copa y del podio, cinta de "ganador" |
| medal gold / silver / bronze (nuevos) | #E8B84A / #C9D1CC / #C98B5A | Medallas de puesto |
| Colores por juego | los actuales (#3FA796, #B57BEE, #E5575C...) | Capa secundaria del icono duotono de cada juego |

### Tipografía (empaquetada, ver sección c)

- **Títulos y números de ceremonia: Alfa Slab One, peso único (400).** Slab muy pesada, de cartelería y programa de carreras. Para títulos de pantalla, nombre del juego, puesto del podio, cifras de fichas y "¡GANA!". Solo desde ~20 px. Nunca para texto corrido.
- **Texto e interfaz: Figtree variable, ejes 300-900.** Usar 400 en cuerpo, 700 en botones y 800 en etiquetas en mayúsculas con `letterSpacing` 1.2. Alternativa con más personalidad y más peso: Bricolage Grotesque variable (408 KB).
- Las 3 fuentes cubren á é í ó ú ü ñ ¿ ¡ « » € … (comprobado leyendo la tabla `cmap` de cada TTF descargado).
- Reserva opcional: **Rye** (madera estilo oeste) solo para la pantalla de la Copa. Probablemente sobra; con dos fuentes basta.

## (c) Recursos recomendados

Presupuesto de peso añadido: **menos de 1 MB** en lo recomendado (tope pedido: 5 MB).

| Recurso | Enlace | Licencia verificada | Qué cubre | Peso | Integración | Atribución |
|---|---|---|---|---|---|---|
| **Phosphor Icons** (`phosphor_flutter` 2.1.0, 6 estilos: thin, light, regular, bold, fill, duotone) | https://github.com/phosphor-icons/flutter, https://pub.dev/packages/phosphor_flutter | MIT, "MIT © Phosphor Icons" (README del repo) | Casi todos los iconos del inventario (comprobado en el código fuente del paquete que existen: horse, trophy, medal, crown, detective, scales, flagCheckered, brain, globeHemisphereWest, flame, pepper, confetti, coins, handPointing, fingerprint, flask, plant, paintBrush, soccerBall, filmSlate, puzzlePiece, bank, mapPin, mapTrifold, shuffle, textAa, deviceMobile, target, trendDown, smiley, maskHappy, ranking, etc.). El duotono permite oro + color del juego | Fuentes de iconos dentro del paquete; **medir** el APK de release porque no se verificó si hace tree-shaking de los 6 estilos | `flutter pub add phosphor_flutter`; `PhosphorIcon(PhosphorIcons.duotone.horse, duotoneSecondaryColor: ...)`. Importar por estilo (`PhosphorIconsDuotone`) | La licencia MIT exige conservar el aviso: añadirlo en Créditos / `LicenseRegistry` |
| **Alfa Slab One** | https://github.com/google/fonts/tree/main/ofl/alfaslabone ; texto: https://raw.githubusercontent.com/google/fonts/main/ofl/alfaslabone/OFL.txt | SIL OFL 1.1 (OFL.txt leído). Nombre reservado "Alfa Slab": no renombrar ni modificar la fuente | Títulos y ceremonia | `AlfaSlabOne-Regular.ttf`, 97 KB (descargado y medido) | `assets/fonts/` + sección `fonts:` en `pubspec.yaml`. No usar el paquete `google_fonts` en modo red (la app es offline) | OFL: incluir copyright y texto de licencia con la app (Créditos). No hay que compartir nada más |
| **Figtree** (variable) | https://github.com/google/fonts/tree/main/ofl/figtree ; https://raw.githubusercontent.com/google/fonts/main/ofl/figtree/OFL.txt | SIL OFL 1.1 (Copyright 2022 The Figtree Project Authors) | Texto de interfaz | `Figtree[wght].ttf`, 63 KB | Igual; usar `FontVariation('wght', 700)` o declarar pesos | OFL, igual que la anterior |
| **Bricolage Grotesque** (alternativa a Figtree, opcional) | https://github.com/google/fonts/tree/main/ofl/bricolagegrotesque | SIL OFL 1.1 (Copyright 2022 The Bricolage Grotesque Project Authors) | Texto con más carácter | 408 KB (ejes opsz, wdth, wght) | Igual | OFL |
| **Rye** (opcional, solo Copa) | https://github.com/google/fonts/tree/main/ofl/rye ; https://raw.githubusercontent.com/google/fonts/main/ofl/rye/OFL.txt | SIL OFL 1.1 (Sorkin Type Co). Nombre reservado "Rye" | Cartelería de madera | 183 KB | Igual | OFL |
| **Kenney Casino Audio** | https://kenney.nl/assets/casino-audio | CC0 (página del pack). Política general: https://kenney.nl/support ("Attribution is not required", uso comercial permitido) | 50 sonidos de ficha, carta y dado | No listado en la página. Se cogerían 5-8 .ogg, estimado < 300 KB (**sin verificar**) | `assets/audio/` + `audioplayers` (ya en `pubspec.yaml`) | Ninguna (cortesía opcional) |
| **Kenney UI Audio** | https://kenney.nl/assets/ui-audio | CC0 | 50 clics y toggles | No listado | Igual | Ninguna |
| **Kenney Music Jingles** | https://kenney.nl/assets/music-jingles | CC0 (85 archivos) | Fanfarria corta de victoria y podio | No listado | Igual. No he oído el contenido: elegir a oído | Ninguna |
| **confetti** (paquete pub 0.8.0) | https://pub.dev/packages/confetti | MIT | Confeti en podio y victoria | Solo código | `ConfettiWidget`. Alternativa sin dependencia: `CustomPainter` propio (~60 líneas) | MIT: aviso en Créditos |
| **game-icons.net** (opcional) | https://game-icons.net/about.html ; ej. https://game-icons.net/1x1/delapouite/horse-head.html | CC BY 3.0 (página "about" y ficha del icono horse-head, autor Delapouite). Hay que dar crédito al autor y la web | Siluetas más ilustrativas (cabeza de caballo, etc.). Más "fantasía" que Phosphor, pero disponibles en SVG | KB por icono | SVG descargable (ej. `.../icons/ffffff/transparent/1x1/delapouite/horse-head.svg`) con `flutter_svg` (ya en el proyecto) | **Sí, CC BY**: cabe en Créditos con una línea "Icons made by {autor}. game-icons.net". Solo usarlo si hace falta un icono que Phosphor no tenga |

### Descartados o con reservas (verificado salvo indicación)

| Recurso | Licencia verificada | Motivo |
|---|---|---|
| OpenMoji | CC BY-SA 4.0 (pie de https://openmoji.org/about/) | Compartir igual: descartado por criterio del dueño |
| Twemoji (fork jdecked) | Gráficos CC BY 4.0, código MIT (https://github.com/jdecked/twemoji) | Válido legalmente, pero sigue siendo "emoji": no resuelve el problema de estilo |
| Fluent Emoji | MIT (README y LICENSE de https://github.com/microsoft/fluentui-emoji) | Válido, pero visualmente son emoji 3D de Microsoft; solo valdría para 1-2 hitos. No lo uso |
| Noto Emoji | Fuentes de emoji OFL; "la mayoría de las imágenes" Apache 2.0; banderas de dominio público o exentas (README de https://github.com/googlefonts/noto-emoji). **La licencia exacta de la variante monocroma no se pudo verificar** | Las banderas ya están en `assets/geo/flags`; no hace falta |
| Lucide | ISC, con parte MIT para los iconos derivados de Feather (https://lucide.dev/license) | Válido; no hay paquete Flutter oficial verificado. Phosphor ya cubre lo necesario y tiene duotono |
| Tabler Icons | MIT, 6.563 iconos (https://github.com/tabler/tabler-icons) | Válido; solo línea, sin duotono. Reserva si falta un icono |
| Lottie / LottieFiles | "Lottie Simple License": uso comercial permitido, atribución no obligatoria, pero las modificaciones son obras derivadas bajo la misma licencia y no se puede imponer otros términos (https://lottiefiles.com/page/license). Hay licencias mixtas por archivo | Descartado: licencia por archivo y animaciones de estilo ajeno. Mejor animación propia en Flutter |
| Rive | Runtime `rive` 0.14.11 MIT (pub.dev). **Licencia de los archivos de la comunidad: no se pudo verificar** (https://rive.app/community/doc/licensing/ no lo aclara) | Descartado por incertidumbre y por añadir un motor |
| Kenney Boardgame Pack / Playing Cards / Game Icons | CC0, pero el contenido no encaja: Game Icons son iconos de mando (105 archivos); Boardgame Pack no confirma fichas de casino | No necesarios: ficha y boleto se dibujan con `CustomPainter` en la paleta de la app |
| Material Symbols, Iconoir, undraw, Open Peeps, Humaaans, OpenGameArt | **No verificados en esta investigación** | No recomendados |

**Sobre las fichas, cartas y caballos:** no he encontrado un pack con licencia verificada y estilo coherente con verde y dorado. Se recomienda **dibujarlos con código** (ficha = círculo + aro punteado + valor en Alfa Slab One; boleto = rectángulo con muescas laterales y línea de puntos). Es pequeño, no pesa nada y es lo que da identidad propia.

### Obligaciones de atribución y empaquetado

- Añadir una sección "Diseño" en `lib/app/credits_screen.dart` con: Phosphor Icons (MIT), Alfa Slab One y Figtree (SIL OFL 1.1) y, si se usa, confetti (MIT) y game-icons.net (CC BY 3.0, con autor).
- Guardar los textos de licencia en `assets/licenses/` y registrarlos con `LicenseRegistry.addLicense`, para que salgan en la pantalla de licencias de Flutter.
- **No hay nada con compartir igual**: las atribuciones CC BY-SA de Trivia y la baraja no aumentan.
- Fuentes offline (la app no usa red):
  1. Copiar los `.ttf` a `assets/fonts/` junto con cada `OFL.txt`.
  2. En `pubspec.yaml`:
     ```yaml
     fonts:
       - family: AlfaSlabOne
         fonts: [{asset: assets/fonts/AlfaSlabOne-Regular.ttf}]
       - family: Figtree
         fonts: [{asset: "assets/fonts/Figtree[wght].ttf"}]
     ```
  3. En `theme.dart`: `ThemeData(fontFamily: 'Figtree')` y un `TextTheme` donde `displayLarge/Medium/Small` y `headlineLarge` usen `AlfaSlabOne`.
  4. No usar `google_fonts` con descarga en runtime.

## (d) Mapa de sustitución (emoji actual a icono)

Se propone un único `lib/app/app_icons.dart` con constantes que devuelvan un `Widget` (`GameIcon`, `MedalIcon`, `LevelIcon`...). Así las pantallas no importan Phosphor directamente. Los nombres son los del paquete `phosphor_flutter` (todos comprobados en su código fuente salvo indicación). Estilo por defecto: `duotone`, capa principal en oro, capa secundaria en el color del juego.

**Menú (`home_screen.dart`, `registry.dart`, módulos)**: cambiar `String emoji` por `Widget icon(double size)` o `IconData icon`.

| Juego | Emoji | Icono |
|---|---|---|
| Carrera de caballos | 🏇 | `horse` |
| El Infiltrado | 🕵️ | `detective` |
| Trivia | 🧠 | `brain` |
| Geografía | 🌍 | `globeHemisphereWest` |
| Abecedario | 🔤 | `textAa` |
| ¿Quién es más probable? | 👉 | `handPointing` |
| ¿Qué preferirías? | 🤔 | `scales` |
| Yo nunca | 🙊 | `fingerprint` (confesar) |
| Copa de la noche | 🏆 | `trophy` |

**Podio y medallas (`cup_screen.dart`, `race_stats_screen.dart`)**: 🥇🥈🥉 pasan a `medal` en fill, con colores medal gold/silver/bronze, y el número del puesto en Alfa Slab One encima. La 🏆 de la cabecera y la de 56 px pasan a `trophy` duotono; la grande (línea 254) se dibuja como ilustración propia (trofeo de latón sobre fondo burdeos) más confeti. 📉 pasa a `trendDown` (rojo). En el texto de compartir (línea 59) **se mantiene el 🏆**: sale de la app hacia WhatsApp y ahí sí funciona como emoji.

**Carrera (`horse_race/ui`)**: 🏁 pasa a `flagCheckered`; 🏆 de "¡GANA!" a `crown` o `trophy` con la fuente de título; 🎉 "Reparten" a `confetti` (verde); 💸 "Pagan" a `coins` (rojo). Las fichas de apuesta, ficha dibujada.

**Infiltrado**: hero revelar y espera `detective` (56 px, duotono con gesto de entrada), 📱 pasa a `deviceMobile` (con animación de "pasar"), ⚖️ a `scales`, 🎯 de resultado a `target`, y el estado ganan impostores / ganan los demás a `detective` / `confetti`.

**Mazos (`prompt_deck`, `prompts.dart`)**:
- Niveles: 😇 pasa a `smiley` (verde), 🌶️ a `pepper` (naranja) y 🔥 a `flame` (rojo). El modelo `PromptLevel` guarda un `IconData` en vez de un `String`. En los chips y la etiqueta de la carta se muestra el icono pequeño y el texto.
- 🎉 de fin de mazo pasa a `confetti`.
- Hero del juego, `game.icon` a 72 px.

**Geografía (`quiz.dart:29-37`, `geo_setup_screen.dart`)**:

| Categoría | Emoji | Icono |
|---|---|---|
| Banderas | 🏳️ | `flag` |
| Capitales | 🏛️ | `bank` |
| Capital a país | 📍 | `mapPin` |
| Siluetas | 🗺️ | `mapTrifold` |
| Mezcla | 🎲 | `shuffle` |
| EE. UU. / México / España / Japón | emoji de bandera | **la bandera real** ya existente en `assets/geo/flags/<flagIso>` (el modelo ya tiene `flagIso`). Con eso se evita el fallo de Windows |

Racha: 🔥 pasa a `flame`. Resultado: quitar el emoji de "¡Perfecto! 🌍"; el icono grande de la pantalla ya cumple. "¡Nuevo récord!" lleva `trophy` en oro.

**Trivia (`trivia_data.dart:13-19`)**:

| Categoría | Emoji | Icono |
|---|---|---|
| Historia | 🏛️ | `bank` |
| Ciencia | 🔬 | `flask` |
| Naturaleza | 🌿 | `plant` |
| Arte y letras | 🎨 | `paintBrush` |
| Deporte | ⚽ | `soccerBall` |
| Cine y música | 🎬 | `filmSlate` |
| Curiosidades | 🧩 | `puzzlePiece` |

En el resultado perfecto se quita el 🧠 del texto.

**Abecedario (`abecedario_play_screen.dart:540`)**: 🔤 pasa a `textAa`, o mejor a una letra grande en Alfa Slab One dentro de una ficha dibujada: es la ilustración más barata y más propia.

**Iconos Material `Icons.*_rounded` (52 usos)**: opcional y de segunda prioridad. Sustitución 1 a 1 (`close_rounded` a `x`, `ios_share_rounded` a `shareNetwork`, `help_outline_rounded` a `question`, `settings_rounded` a `gear`, etc.). Hacerlo al final y por zonas.

## (e) Cinco ideas de "alma" baratas y de alto impacto

| # | Idea | Coste |
|---|---|---|
| 1 | **Voz propia (microcopy de casa de apuestas):** "Haced vuestras apuestas", "Boleto", "Cuadra", "Se abre el paddock", "Fotocheck", "Pagan los de la minoría". Empezar por botones principales, resultados y vacíos. Delegar en `redactor-es` | Bajo: ~1 día, solo textos |
| 2 | **Ficha y boleto dibujados con código** (`CustomPainter`): ficha de apuesta con aro punteado, boleto con muescas para el resultado de la carrera y el "puesto" del podio. Aparecen en todas las pantallas de apuestas | Bajo-medio: 1-2 días |
| 3 | **Podio de la Copa animado:** medallas que caen una a una, confeti (`confetti` o propio) y háptico. Es el momento que se comparte, así que merece el esfuerzo | Medio: 1-2 días |
| 4 | **Sonido de mesa:** ficha al apostar, carta al girar, fanfarria corta en el podio (Kenney Casino Audio + Music Jingles, CC0). Respetar el ajuste de volumen que ya existe (`Icons.volume_up_rounded`). Máximo 6-8 .ogg | Bajo: medio día |
| 5 | **Mascota "el Jockey" o cabeza de caballo con monóculo**: una sola ilustración vectorial propia (SVG, ~10 KB) que sale en carga, estados vacíos y fin de carrera con 2 poses. Se parte de la silueta `horse` de Phosphor para el trazo. Es lo que más cambia la sensación de marca. Coste real: la ilustración, que hay que dibujarla o encargarla (se hace dueño de los derechos) | Medio-alto: 2-4 días |

## (f) Orden de implementación (paralelizable por zonas de archivos)

**Paso 0, secuencial (medio día, un solo agente).** Antes de nada: commitear o cerrar los cambios pendientes del árbol (hay 15 archivos modificados que coinciden con las zonas de abajo; evitaría conflictos).
1. `pubspec.yaml`: `phosphor_flutter`, fuentes, `assets/fonts/`, `assets/licenses/`.
2. `lib/app/theme.dart`: tokens nuevos y `TextTheme` con las dos fuentes.
3. Crear `lib/app/app_icons.dart` (iconos, medalla, ficha, boleto) y comprobar que el build de release no pesa más de ~1 MB extra.
4. Cambiar `GameModule.emoji` (`lib/games/game_module.dart`) por `icon`. Es el único cambio de interfaz compartida; hasta que no esté, las zonas siguientes no compilan.

**Paso 1, en paralelo (cada zona toca archivos distintos, un agente `implementador` por zona):**

| Zona | Archivos | Tarea |
|---|---|---|
| A. Menú y registro | `app/home_screen.dart`, `games/registry.dart`, los 5 `*_module.dart` | Iconos de juego, tarjetas del menú |
| B. Trivia y Geografía | `games/trivia/**`, `games/geography/**` | Categorías, resultados, banderas reales |
| C. Infiltrado | `games/infiltrado/**` | Héroes y estados |
| D. Carrera | `games/horse_race/**` | Ficha dibujada, cabeceras, ranking |
| E. Mazos y niveles | `games/prompt_deck/**`, `core/content/prompts.dart`, `games/abecedario/**` | Niveles con icono, fin de mazo y Abecedario |
| F. Copa y Créditos | `app/cup_screen.dart`, `app/credits_screen.dart` | Podio, medallas, atribuciones y licencias |
| G. Sonido | `assets/audio/`, el servicio de audio | Elegir 6-8 sonidos Kenney (a oído) y engancharlos |

**Paso 2, en paralelo con el 1 (no toca `lib/`):**
- `redactor-es`: microcopy (idea 1).
- Quien dibuje: mascota y trofeo (idea 5).

**Paso 3, cierre:**
1. Sustitución opcional de los `Icons.*_rounded` por zonas.
2. `revisor`: capturas en 3 anchos, comprobar contraste del dorado sobre verde, que no queda emoji (`grep` de rangos Unicode) y el tamaño del APK.
3. Registrar la decisión en `docs/decisions.md` (fuentes y icono: fecha, motivo).
4. Ejecutar `flutter analyze` y `flutter test`. Hay tests que buscan emoji o textos (`test/cup_screen_test.dart`, `test/geography_test.dart`) y habrá que actualizarlos.

### Riesgos y cosas por confirmar
- Tamaño real de los .ogg de Kenney y de la fuente de iconos de Phosphor en release: no verificado, medir en el paso 0.
- Phosphor 2.1.0 es de mayo de 2024; los iconos mencionados existen en el código fuente de esa versión, pero conviene comprobarlo con `flutter analyze` al usarlos (algún nombre puede variar).
- Fuentes con OFL: no se pueden vender por separado ni renombrar; bundleadas en la app, sin problema.
- Game-icons.net y confetti son opcionales: si se prescinde de ellos, las atribuciones nuevas se quedan en Phosphor (MIT) y las dos fuentes (OFL).
- No se ha revisado la licencia de fuentes ni iconos con un abogado; esto no es asesoría legal. El agente `cumplimiento` puede repasar la lista antes de publicar.

# Fases 1 y 3: desglose en subtareas

Fecha: 24/11/2026 · Base: rama `fase-0-publicacion` (fd222c5) · Decisiones en `docs/decisions.md` (24/11/2026).

Origen: `docs/PLAN_PUBLICACION.md` (Fase 1, sistema de consecuencias; Fase 3, Copa y juegos nuevos).

## Coordinación con el trabajo en curso

- **Fase 2** (otro agente) está editando `assets/content/es/` (ficheros existentes) y probablemente `test/content_test.dart`. Puede que también toque `lib/core/content/prompts.dart` y `lib/games/prompt_deck/prompt_deck_screens.dart` (nivel "Atrevido" con confirmación +18).
- **Fase 4** (otro agente) está renombrando `lib/games/rosco/` a `lib/games/abecedario/` y **tiene `lib/games/registry.dart` modificado sin commit**.
- Todos trabajáis en el **mismo árbol de trabajo y la misma rama**. Hasta que Fase 2 y Fase 4 hagan commit:
  - No tocar `lib/games/registry.dart`, `lib/games/abecedario/`, `test/abecedario_test.dart` ni `test/content_test.dart`.
  - En `assets/content/es/` solo se crean ficheros **nuevos** (`retos.json`, `quien_es_mas_probable.json`, `infiltrado.json`). `que_preferirias.json` se amplía cuando Fase 2 termine.
  - Si Fase 2 toca `prompt_deck_screens.dart`, la 3.4 espera a su commit.
- Los tests de los ficheros nuevos van en `test/extra_content_test.dart`, no en `content_test.dart`.

## Reglas de todas las subtareas

- Criterio común de hecho: `flutter analyze` sin avisos y `flutter test` en verde. Para compilar en esta máquina, usar `--no-tree-shake-icons`.
- Ningún texto de juego habla de alcohol. La única excepción es el modo Sorbos, cuyo texto se genera solo en `lib/core/consequences/`.
- Los textos visibles los escribe `redactor-es` o se dejan como `TODO-CONTENIDO`. Las cartas las escribe `contenido-fiesta`.
- Commit por subtarea, con el id en el mensaje (p. ej. `feat(1.1): modo de consecuencias`).
- Antes de cerrar las subtareas 1.4, 3.1 y 3.3 (formato de datos guardados en el dispositivo), pasa `revisor`.

---

## Fase 1 · Sistema de consecuencias

### 1.1 Núcleo de consecuencias (modelo puro y ajuste)
- **Qué**: enum `ConsequenceMode { puntos, retos, sorbos }` y lógica pura: `resolveLoss(int fichas, ConsequenceMode)`, que devuelve qué paga el jugador (puntos = fichas; retos = `min(fichas, 3)`; sorbos = `min(fichas, 3)` con la alternativa "agua o reto"). Constantes `kMaxChipsPerBet = 5` y `kRoundCap = 3`. Se añaden `consequenceMode` (por defecto `puntos`) y `adultConfirmed` (por defecto `false`) a `AppSettings`, con `setConsequenceMode()` y `confirmAdult()`. Si `adultConfirmed` es `false`, `setConsequenceMode(sorbos)` no hace nada.
- **Archivos**: crear `lib/core/consequences/consequences.dart` y `test/consequences_test.dart`; modificar `lib/core/settings/settings_controller.dart` y `test/settings_controller_test.dart`.
- **Hecho cuando**: hay tests de los topes (0, 1, 3, 5 y 10 fichas en cada modo), del valor por defecto `puntos`, de la persistencia de los dos ajustes nuevos y de que no se pueden activar los sorbos sin `adultConfirmed`.
- **Agente**: `juego-flutter` (Sonnet, medio).
- **Depende de**: nada.

### 1.2 Ajustes: selector del modo de consecuencias
- **Qué**: sustituir el hueco "Fase 1" de Ajustes por un selector de tres opciones. Al elegir Sorbos sin haber confirmado la edad, se abre un diálogo +18 ("Nadie está obligado a beber"); si se cancela, se queda el modo anterior.
- **Archivos**: modificar `lib/app/settings_screen.dart`.
- **Hecho cuando**: en el emulador, Puntos es el modo por defecto; Sorbos pide la confirmación una sola vez y el modo elegido se mantiene al reiniciar la app.
- **Agente**: `implementador` (Sonnet, medio). Textos del diálogo: `redactor-es`.
- **Depende de**: 1.1.

### 1.3 Widget `ConsequenceBanner`
- **Qué**: widget que recibe `{jugador: fichas perdidas}` y lo muestra según el modo activo: "−2 en la Copa", "2 retos" (sacados de `retos.json`) o "2 sorbos · o agua o reto" (la alternativa siempre visible). Si `retos.json` aún no existe, usa una lista mínima de reserva.
- **Archivos**: crear `lib/core/consequences/consequence_banner.dart` y `test/consequence_banner_test.dart` (widget test con los tres modos).
- **Hecho cuando**: el widget test pasa en los tres modos y en Sorbos nunca aparece un número mayor que 3.
- **Agente**: `juego-flutter` (Sonnet, medio).
- **Depende de**: 1.1. La 1.5 no bloquea gracias a la lista de reserva.

### 1.4 Carrera en fichas
- **Qué**:
  - `Bet.sips` pasa a `Bet.chips` (de 1 a 5) y `hidalgo` pasa a `allIn` (vale 10 fichas, ver decisiones). `BetOutcome.label` muestra fichas, sin 🍺 ni 💀.
  - Migración de `race.setup.v1`: se sigue leyendo la clave `sips`, los valores se recortan a 1–5 y el 0 se convierte en all-in. La clave de preferencias no cambia.
  - `PlayerRaceStats`: renombrar `sipsDrunk`/`sipsGiven` a `chipsLost`/`chipsWon`, manteniendo las claves JSON `d`/`g`.
  - Textos: "Palo y fichas", "¿Quién paga?", "Pagan", "¡Todos pagan!", "fichas perdidas", "All-in".
  - La pantalla de resultado usa `ConsequenceBanner`.
- **Archivos**: `lib/games/horse_race/domain/bets.dart`, `lib/games/horse_race/race_store.dart`, `lib/games/horse_race/ui/race_setup_screen.dart`, `lib/games/horse_race/ui/race_screen.dart` (solo el botón del final), `lib/games/horse_race/ui/race_result_screen.dart`, `lib/games/horse_race/ui/race_stats_screen.dart` y `test/race_engine_test.dart`.
- **Hecho cuando**:
  - los tests de `settleBets` están adaptados a fichas y all-in;
  - hay un test de migración que lee un JSON antiguo con `sips: 8` y `sips: 0`;
  - `grep -ri "trago\|beb\|🍺\|hidalgo\|💀" lib/games/horse_race` no da resultados;
  - una carrera completa funciona en el emulador.
- **Agente**: `juego-flutter` (Sonnet, alto: cruza 7 archivos y toca datos guardados). Después, `revisor`.
- **Depende de**: 1.1 y 1.3.

### 1.5 Mazo de retos
- **Qué**: unos 80 retos sin riesgo físico, sin alcohol y sin humillar a nadie, con formato `{id: "rt_001", nivel, texto}` (compatible con `parsePrompts`).
- **Archivos**: crear `assets/content/es/retos.json` y `test/extra_content_test.dart` (ids únicos, campo `texto` no vacío y lista negra de palabras local).
- **Hecho cuando**: `flutter test test/extra_content_test.dart` pasa y hay 80 retos o más.
- **Agente**: `contenido-fiesta` (Opus, medio).
- **Depende de**: nada (es un archivo nuevo).

### 1.6 Textos de "Yo nunca"
- **Qué**: en el registro, el subtítulo de "Yo nunca" pasa a "Confiesa… o paga" y la regla a "Quien lo haya hecho, pierde una ficha".
- **Archivos**: `lib/games/registry.dart` (dos líneas).
- **Hecho cuando**: `grep -n "bebe" lib/games/registry.dart` no da resultados y los tests pasan.
- **Agente**: `mecanico` (Haiku, bajo).
- **Depende de**: el commit de Fase 4 (que hoy tiene `registry.dart` modificado).

### 1.7 Bienvenida la primera vez (+18)
- **Qué**: pantalla que se ve una sola vez con "+18 · Juega con responsabilidad · Nadie está obligado a beber" y un enlace a la privacidad (`kPrivacyUrl`). El indicador va en su propio provider (`onboarding.welcome.v1`), no en `AppSettings`, para no pisar la 1.1. Se añade un `redirect` en el router.
- **Archivos**: crear `lib/app/welcome_screen.dart` y `lib/core/settings/onboarding_controller.dart`; modificar `lib/app/router.dart`; crear `test/onboarding_test.dart`.
- **Hecho cuando**: el test comprueba que el indicador se guarda; en el emulador, la primera vez sale la bienvenida y la segunda no.
- **Agente**: `implementador` (Sonnet, medio). Texto: `redactor-es`.
- **Depende de**: nada.

### 1.8 Guardia contra el alcohol en el código
- **Qué**: test que recorre `lib/**/*.dart` y falla si encuentra `beb`, `trago`, `🍺`, `hidalgo` o `borrach`. Se excluyen `lib/core/consequences/` (modo Sorbos) y `lib/app/credits_screen.dart` (aviso legal).
- **Archivos**: crear `test/no_alcohol_text_test.dart`.
- **Hecho cuando**: el test está en verde y, si se mete a propósito un "bebe" en un juego, falla.
- **Agente**: `mecanico` (Haiku, bajo).
- **Depende de**: 1.4 y 1.6.

---

## Fase 3 · Copa Paddock y juegos nuevos

### 3.1 `SessionScoreController` (núcleo de la Copa)
- **Qué**:
  - Modelo puro `Session { id, startedAt, events: List<ScoreEvent> }`, con `ScoreEvent { roundId, gameId, playerId, delta, at }`. La clasificación, las estadísticas por juego y "el que más ha perdido" se calculan a partir de los eventos.
  - El `Notifier` expone `award(roundId, gameId, Map<playerId, delta>)`, que no hace nada si el `roundId` ya está registrado, además de `newNight()` y `undoLastRound()`.
  - Persistencia en `shared_preferences`, clave `session.v1`. La partida no caduca sola: si tiene más de 12 h, `isStale` es `true` y la home lo indica.
- **Archivos**: crear `lib/core/session/session_score.dart` (modelo y cálculo), `lib/core/session/session_controller.dart` (provider) y `test/session_score_test.dart`.
- **Hecho cuando**: hay tests de la clasificación con empates, de que un mismo `roundId` no se cuenta dos veces, de deshacer, de guardar y recuperar, de un JSON corrupto (debe dar una sesión vacía) y de `isStale`.
- **Agente**: `juego-flutter` (Sonnet, alto). Después, `revisor`.
- **Depende de**: nada. **Se puede empezar ya**, en paralelo con la Fase 1.

### 3.2 Copa: clasificación en la home, podio y compartir
- **Qué**:
  - En la home, una tarjeta con el top 3 y el botón "Ver Copa". Si no hay eventos, se oculta.
  - Pantalla `/copa` con la clasificación completa, un podio animado (reutilizando `Confetti` de `effects.dart`), estadísticas por juego, "Nueva noche" con confirmación y "Compartir resultado".
  - Para compartir se usa `share_plus`, solo con texto.
- **Archivos**: crear `lib/app/cup_screen.dart`; modificar `lib/app/home_screen.dart`, `lib/app/router.dart` (ruta `copa`) y `pubspec.yaml` (`share_plus`).
- **Hecho cuando**: en el emulador, tras registrar eventos, la home muestra el top 3, el podio coincide con la clasificación, al compartir se abre la hoja del sistema y "Nueva noche" lo vacía todo. El AAB compila.
- **Agente**: `juego-flutter` (Sonnet, medio).
- **Depende de**: 3.1 y 1.7 (las dos tocan `router.dart`).

### 3.3 Carrera → Copa
- **Qué**: al terminar la carrera, en el mismo sitio donde hoy se llama a `raceStatsProvider.record`, se llama a `award(roundId, 'carrera', {jugador: +ganadas / −perdidas})`. El `roundId` es la marca de tiempo de la carrera, así la revancha cuenta como otra ronda.
- **Archivos**: `lib/games/horse_race/ui/race_screen.dart` (función de cierre) y quizá `lib/games/horse_race/race_result.dart` (añadir `roundId`).
- **Hecho cuando**: en el emulador, una carrera seguida de una revancha da dos rondas en la Copa, y salir y volver a entrar en el resultado no duplica nada.
- **Agente**: `juego-flutter` (Sonnet, medio). Después, `revisor`.
- **Depende de**: 1.4 y 3.1.

### 3.4 Mazo de cartas: "¿Quién paga?" y estilo pregunta
- **Qué**:
  - En `PromptDeckModule` se añade `payMode`: `none`, `multi` (Yo nunca: se marcan quienes lo hayan hecho) o `single` (¿Quién es más probable?: se marca al más votado; ¿Qué preferirías?: se marca a la minoría, que puede ser más de uno).
  - Fila de chips de jugadores bajo la carta. Al pasar de carta se registra `award(cardId+índice, game.id, {marcados: −1})`.
  - Nuevo estilo `PromptCardStyle.question`: prefijo "¿Quién es más probable que" y cierre con "?" en lugar del punto.
  - Sin jugadores, la fila no aparece y el juego funciona igual que ahora.
- **Archivos**: `lib/games/prompt_deck/prompt_deck_module.dart` y `lib/games/prompt_deck/prompt_deck_screens.dart`.
- **Hecho cuando**: en el emulador, marcar a 2 jugadores en Yo nunca resta 1 a cada uno en la Copa; el botón deshacer de la carta no duplica; sin jugadores no cambia nada. Los tests existentes siguen en verde.
- **Agente**: `juego-flutter` (Sonnet, alto).
- **Depende de**: 3.1 y 1.3, y del commit de Fase 2 si toca `prompt_deck_screens.dart`.

### 3.5 Contenido de "¿Quién es más probable…?"
- **Qué**: unas 120 cartas con formato `{id: "qmp_001", nivel, texto}` (texto sin el prefijo ni la "?"). Debe haber cartas de los tres niveles, porque `content_test` lo exige.
- **Archivos**: crear `assets/content/es/quien_es_mas_probable.json` y ampliar `test/extra_content_test.dart`.
- **Hecho cuando**: hay 120 cartas o más, con 50 o más en Suave, y el test pasa.
- **Agente**: `contenido-fiesta` (Opus, medio).
- **Depende de**: 1.5, solo si se reparte el mismo `extra_content_test.dart`. Si no, de nada.

### 3.6 Ampliar "¿Qué preferirías?" (de 45 a ~120 cartas)
- **Qué**: ampliar el mazo manteniendo los ids existentes y aplicando los criterios de la Fase 2.
- **Archivos**: `assets/content/es/que_preferirias.json`.
- **Hecho cuando**: hay 120 cartas o más y `flutter test test/content_test.dart` pasa (ya incluye el mazo cuando se registra en la 3.10).
- **Agente**: `contenido-fiesta` (Opus, medio).
- **Depende de**: el commit de Fase 2 (mismo directorio y misma lista negra).

### 3.7 Motor de El Infiltrado
- **Qué**: motor puro con semilla.
  - `deal(players, word, category, impostors: 1|2)` reparte los roles.
  - El orden de revelación es pasar el móvil de mano en mano.
  - `vote(Map<voter, target>)` produce el resultado: si se pilla al infiltrado, este pierde 2 fichas; si no, los demás pierden 1 cada uno. Hay una última oportunidad: si el infiltrado acierta la palabra, gana igualmente.
  - Los empates en la votación se resuelven con una segunda ronda entre los empatados.
  - El infiltrado solo ve la categoría (ver decisiones).
- **Archivos**: crear `lib/games/infiltrado/domain/infiltrado_engine.dart` y `test/infiltrado_engine_test.dart`.
- **Hecho cuando**: hay tests del reparto con semilla, de 1 y 2 infiltrados, de los empates, del acierto final y del mínimo de 3 jugadores.
- **Agente**: `juego-flutter` (Sonnet, medio).
- **Depende de**: nada.

### 3.8 El Infiltrado: módulo y pantallas
- **Qué**:
  - Configuración con jugadores, número de infiltrados y nivel.
  - Revelación: tarjeta tapada → "pasa el móvil a X", con `PopScope` y confirmación al salir.
  - Temporizador de debate opcional, votación y resultado con `ConsequenceBanner` y `award` a la Copa.
  - Estados vacíos: menos de 3 jugadores y palabras agotadas.
- **Archivos**: crear `lib/games/infiltrado/infiltrado_module.dart`, `lib/games/infiltrado/infiltrado_store.dart` (configuración en `infiltrado.setup.v1`), `lib/games/infiltrado/ui/infiltrado_setup_screen.dart`, `lib/games/infiltrado/ui/infiltrado_reveal_screen.dart`, `lib/games/infiltrado/ui/infiltrado_vote_screen.dart` y `lib/games/infiltrado/ui/infiltrado_result_screen.dart`.
- **Hecho cuando**: una partida completa con 4 jugadores en el emulador, la Copa actualizada y `Semantics` en los botones que solo tienen icono.
- **Agente**: `juego-flutter` (Sonnet, alto).
- **Depende de**: 3.7, 3.1 y 1.3. El contenido (3.9) no bloquea: se usa una lista de 10 palabras de prueba marcada `TODO-CONTENIDO`.

### 3.9 Contenido de El Infiltrado
- **Qué**: unas 150 palabras con formato `{id: "inf_001", nivel, categoria, palabra}`, en 10 o más categorías (comida, lugares, profesiones, objetos…), casi todas en Suave.
- **Archivos**: crear `assets/content/es/infiltrado.json` y ampliar `test/extra_content_test.dart` (palabra y categoría no vacías, palabras sin duplicar).
- **Hecho cuando**: el test pasa con 150 palabras o más.
- **Agente**: `contenido-fiesta` (Opus, medio).
- **Depende de**: nada (aparte de compartir `extra_content_test.dart` con 1.5 y 3.5: el mismo agente las hace seguidas).

### 3.10 Registro y orden del menú
- **Qué**:
  - Registrar `InfiltradoModule`, el `PromptDeckModule` de "¿Quién es más probable?" (`style: question`, `payMode: single`) y reactivar "¿Qué preferirías?" (`payMode: single`). A "Yo nunca" se le pone `payMode: multi`.
  - Orden: Carrera · Infiltrado · Trivia · Geografía · Abecedario · ¿Quién es más probable? · ¿Qué preferirías? · Yo nunca.
  - Las reglas se escriben en fichas.
- **Archivos**: `lib/games/registry.dart`.
- **Hecho cuando**: la home muestra los 8 juegos en ese orden y `content_test.dart` valida los tres mazos de cartas.
- **Agente**: `mecanico` (Haiku, bajo).
- **Depende de**: 1.6, 3.4, 3.5, 3.8 y el commit de Fase 4.

### 3.11 (Opcional, v1.1) Trivia y Geografía → Copa
- **Qué**: en la pantalla de resultado, un selector "¿Quién ha jugado?" que suma los aciertos a ese jugador. Hoy son juegos de un solo jugador sin jugadores asociados.
- **Archivos**: `lib/games/trivia/ui/trivia_result_screen.dart` y `lib/games/geography/ui/geo_result_screen.dart`.
- **Agente**: `implementador` (Sonnet, medio).
- **Depende de**: 3.1. Abecedario → Copa queda para cuando se cierre la Fase 4.

---

## Paralelismo

Las subtareas de una misma ola no comparten archivos entre sí ni con Fase 2 o Fase 4 (salvo lo indicado).

| Ola | Subtareas en paralelo | Notas |
|---|---|---|
| A (ya) | **1.1**, **1.7**, **3.1**, **3.7** · contenido: **1.5 → 3.5 → 3.9** (un solo `contenido-fiesta`, en secuencia porque comparten `extra_content_test.dart`) | Todo son archivos nuevos, salvo `settings_controller.dart` (1.1) y `router.dart` (1.7). |
| B | **1.2**, **1.3**, **3.2**, **3.8** | 3.2 necesita 1.7 (router); 3.8 necesita 3.7 + 3.1 (y 1.3 para el banner: si no está, se deja un hueco). |
| C | **1.4**, **3.4** | 1.4 = carpeta `horse_race/`; 3.4 = carpeta `prompt_deck/` (esperar al commit de Fase 2 si la toca). |
| D | **3.3**, **1.6**, **3.6** | 1.6 y 3.6 esperan a los commits de Fase 4 y Fase 2. |
| E | **3.10** → **1.8** | `registry.dart` lo toca un solo agente; la guardia se ejecuta al final. |
| Cierre | `revisor` sobre 1.4, 3.1 y 3.3; prueba en el emulador; marcar las Fases 1 y 3 en `PLAN_PUBLICACION.md` | |

**Archivos conflictivos** (nunca dos agentes a la vez):
- `lib/games/registry.dart`: Fase 4, 1.6, 3.10.
- `lib/app/router.dart`: 1.7 y 3.2.
- `lib/games/horse_race/ui/race_screen.dart`: 1.4 y 3.3.
- `lib/games/prompt_deck/*`: Fase 2 (posible) y 3.4.
- `test/extra_content_test.dart`: 1.5, 3.5, 3.9.

## Qué no se puede deshacer fácilmente

Una vez publicada la app, estos formatos ya están en los móviles de la gente:
- `session.v1`: formato de eventos.
- `race.setup.v1`: migración de `sips` a fichas.
- `infiltrado.setup.v1`: configuración del Infiltrado.

Para cambiarlos más adelante hace falta una clave nueva (`.v2`) y código de migración. Los ids de las cartas (`rt_`, `qmp_`, `inf_`) deben ser estables desde la primera versión. `share_plus` añade un plugin nativo, pero no pide permisos y se puede quitar.

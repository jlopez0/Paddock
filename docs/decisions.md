# Decisiones

Formato: fecha · decisión · motivo. Las más recientes van al final.

## 2026-11-24 · Fases 1 y 3 (consecuencias y Copa)

Desglose completo en `docs/FASES_1_3.md`.

### D1. El modo de consecuencias es un ajuste global, guardado en `AppSettings`
Opciones que se compararon:

| Opción | Coste | Riesgo | Reversibilidad |
|---|---|---|---|
| **A. Ajuste global en `AppSettings` (Ajustes)** | Bajo | Bajo | Alta |
| B. Se elige al empezar cada noche, dentro de la sesión | Medio | Medio: un paso más antes de jugar | Alta |
| C. Se elige en cada juego | Alto | Alto: se repite en 8 pantallas | Media |

Elegida la **A**:
- `ConsequenceMode { puntos, retos, sorbos }` vive en `AppSettings`, con valor por defecto `puntos`.
- Los juegos lo leen con `ref.watch(settingsProvider.select((s) => s.consequenceMode))` y nunca muestran la consecuencia por su cuenta: siempre pasan por `ConsequenceBanner`.
- La lógica de topes está en Dart puro, en `lib/core/consequences/consequences.dart`, para poder probarla con tests.

**Motivo**: hay una sola fuente de verdad, ya existe la pantalla de Ajustes y es lo más simple. Si más adelante se quiere elegir el modo por noche, basta con mostrar el modo actual en la Copa con un enlace a Ajustes.

### D2. Los sorbos solo se activan con `adultConfirmed`, y la bienvenida +18 va aparte
- `setConsequenceMode(sorbos)` no hace nada si `adultConfirmed` es `false`. Los sorbos tienen un tope de 3 por ronda y la alternativa "agua o reto" siempre está a la vista.
- La bienvenida de la primera vez usa su propio indicador (`onboarding.welcome.v1`), en `lib/core/settings/onboarding_controller.dart`.

**Motivo**: cumplir las normas de las tiendas (nada de competir bebiendo y beber nunca es obligatorio). Tener la bienvenida en su propio archivo permite hacerla en paralelo con el núcleo de consecuencias sin tocar el mismo fichero.

### D3. La Copa (`SessionScoreController`) guarda eventos, no totales
- Se guardan los eventos: `ScoreEvent { roundId, gameId, playerId, delta, at }`. La clasificación y las estadísticas se calculan a partir de ellos.
- `award()` es idempotente por `roundId`.
- Persistencia en `shared_preferences`, clave `session.v1`. Vive en `lib/core/session/`.
- La noche no caduca sola: pasadas 12 h se marca `isStale` y la home ofrece "Nueva noche".

**Motivo**:
- Con los eventos se pueden sacar estadísticas por juego, deshacer la última ronda y evitar contar dos veces una ronda en las revanchas o al reconstruirse una pantalla.
- `shared_preferences` es la misma decisión que ya se tomó en el SPEC: hay pocos datos y no hace falta generar código.
- La sesión se guarda porque en una fiesta la app se cierra o el sistema la mata.

**No reversible tras publicar**: el formato `session.v1`. Cambiarlo exige una clave `.v2` con migración.

### D4. La Copa siempre cuenta en fichas, sea cual sea el modo
El modo de consecuencias solo decide qué pasa "en la vida real" (retos o sorbos). El marcador de la noche siempre suma y resta fichas: en la Carrera, quien acierta gana lo apostado y quien falla lo pierde.

**Motivo**: el marcador es comparable entre juegos y modos, y el "núcleo" de la app no es beber.

### D5. Carrera: apuestas de 1 a 5 fichas, y all-in = 10 fichas
- El "hidalgo" pasa a llamarse "All-in" y vale el doble de la apuesta máxima, solo en la Copa. En los modos Retos y Sorbos se aplica el tope de 3 por ronda.
- Migración de `race.setup.v1`: se sigue leyendo la clave `sips`, los valores se recortan a 1–5 y el 0 se convierte en all-in.
- Las claves de las estadísticas (`d`, `g`) no cambian, solo los nombres en Dart.

**Motivo**: quitar el binge drinking que bloquea la publicación sin perder la emoción del todo o nada, y sin romper los datos guardados de quien ya tenga la app instalada.

Pendiente de que lo valide Javier: el valor de 10 fichas.

### D6. La Copa en los mazos de cartas se registra desde `PromptDeckModule`, con `payMode`
- `PromptDeckModule` gana un parámetro `payMode` (`none`, `multi` o `single`) y una fila de chips de jugadores bajo la carta.
- "¿Quién es más probable…?" reutiliza el mazo con un estilo nuevo, `question`, en lugar de ser un módulo propio.

**Motivo**: una sola pieza integra Yo nunca, ¿Quién es más probable? y ¿Qué preferirías? con la Copa, que es lo que pide el agente `juego-flutter` ("reutilizar `PromptDeckModule`"). Sin jugadores, el juego funciona igual que ahora.

### D7. El Infiltrado es un módulo propio, con motor puro y contenido en JSON compatible con `parsePrompts`
- Formato del contenido: `{id, nivel, categoria, palabra}`.
- El infiltrado solo ve la categoría.
- Se juega pasando el móvil de mano en mano. Mínimo 3 jugadores.

**Motivo**:
- La mecánica (roles secretos y votación) no encaja en el mazo de cartas.
- Ver la categoría hace que el juego sea posible para quien no sabe la palabra, sin necesitar parejas de palabras parecidas, que son más difíciles de escribir.
- Reutilizar el parser evita escribir otro cargador.

### D8. Compartir el resultado con `share_plus`, solo texto
**Motivo**: es lo que dice el plan, no pide permisos y se puede quitar. Compartir una imagen del podio queda para la v1.1.

### D9. Coordinación con el trabajo en curso de las Fases 2 y 4
- `lib/games/registry.dart` lo modifica la Fase 4 (sin commit). Solo lo tocan 1.6 y 3.10, en secuencia y después del commit de la Fase 4.
- Los tests del contenido nuevo van en `test/extra_content_test.dart`, para no chocar con `test/content_test.dart` (Fase 2).

**Motivo**: todos los agentes trabajan en el mismo árbol de trabajo y en la misma rama.

### D10. Reglas del motor del Infiltrado (2026-11-24)
- Con 2 infiltrados hacen falta al menos 5 jugadores.
- Con 2 infiltrados basta con pillar a uno: los dos pierden 2 fichas.
- La palabra se compara sin tildes ni mayúsculas, y la ñ cuenta como n.

**Motivo**: con menos de 5 jugadores dos infiltrados son casi la mitad de la mesa y la votación no se sostiene. Pillar a uno es más ágil y evita rondas de caza. Comparar sin tildes ni mayúsculas evita fallos injustos al escribir en el móvil.

### D11. All-in en la Carrera (2026-11-24)
- Las apuestas de la Carrera van de 1 a 5 fichas. El antiguo "hidalgo" pasa a llamarse **All-in** y vale **10 fichas** en la Copa. Es un supuesto del producto: se puede ajustar en `kAllInChips` (`lib/games/horse_race/domain/bets.dart`).
- All-in perdido: paga 10 fichas. En los modos Retos y Sorbos `resolveLoss` lo limita al tope de 3.
- All-in ganado: reparte siempre 2 All-in a 2 personas distintas que elige quien lo apostó (con menos de 3 jugadores, a los que haya, sin repetir y sin incluirse). Cada una paga 10 fichas y quien repartió gana 10 por cada persona elegida (20 si son dos). La opción "Acertar reparte el doble" no cambia esto.
- Las fichas de la carrera van a la Copa con una sola llamada a `award` por ronda, desde la pantalla de resultado, cuando se sale de ella (o al entrar, si no hay All-in ganadores). El `roundId` se fija al terminar la carrera: la revancha es otra ronda y volver a entrar no cuenta doble.
- `race.setup.v1` conserva la clave de preferencias. Se leen las apuestas antiguas (`sips`): de 1 a 10 se recortan a 1-5 y 0 pasa a All-in. Al guardar se escribe `chips`.

**Motivo**: decisión del dueño del producto. Elegir a quién se reparte el All-in necesita una interacción en el resultado, por eso las fichas se envían a la Copa al salir y no al terminar la carrera. El valor 10 y las 20 fichas de ganancia son supuestos sin validar con partidas reales.

### D12. Limitaciones asumidas de las estadísticas de la Carrera (2026-11-24)
- Las estadísticas antiguas guardadas como tragos (`d`/`g` en `race.stats.v1`) ahora se leen como fichas, sin conversión.
- Un All-in ganado suma 20 fichas a `chipsWon` aunque se reparta a menos de dos personas.

**Motivo**: migrar o recalcular no compensa para estadísticas locales de bajo valor; no se cambia la lógica.

- 2026-11-24 · Sin i18n con ARB en la v1 · La v1 sale solo en español; los textos siguen en el código. Se aborda en v1.1 si se añaden idiomas.

- 2026-11-24 · Copia de seguridad de Android desactivada · `allowBackup="false"` y reglas `dataExtractionRules`/`fullBackupContent` que excluyen todo. Motivo: la política dice que los datos nunca salen del dispositivo y la copia automática de Google los subiría a la nube.
- 2026-11-24 · Pistas del Abecedario reformuladas · "Empieza por X"/"Contiene la X" pasan a "Arranca con la X"/"Lleva una X dentro". Motivo: riesgo de propiedad intelectual con "El Rosco" (mitigación parcial; la mecánica sigue siendo similar). Si se quiere conservar la mecánica, recomendable consulta legal.
- 2026-11-24 · iOS (enero): pendiente decidir si se retira el modo Sorbos y el texto "Nadie está obligado a beber" · Motivo: posible choque con Apple 4.3(b)/1.4.3 (contenido relacionado con alcohol).

- 2026-11-24 · Primer toque ignorado tras el arranque en frío: no se encontró causa en el código · `main()` solo espera `SharedPreferences` antes de `runApp`, no hay providers asíncronos ni carga de assets antes de pintar, y el `redirect` del router es síncrono. Se atribuye al emulador (compilación de shaders / JIT en el primer fotograma en modo debug, sin Impeller precalentado). Pendiente de confirmar en un dispositivo real con build `--release`; si persiste, medir con DevTools el primer fotograma.

- 2026-11-24 · Iconos Phosphor empaquetados como fuente propia, sin `phosphor_flutter` · El paquete 2.1.0 (última versión) no compila con Flutter 3.50 (`IconData` es `final`). Se copian `Phosphor-Duotone.ttf` y `Phosphor-Fill.ttf` (MIT) a `assets/fonts/` y `lib/app/app_icons.dart` usa los códigos de glifo directamente. Con `--no-tree-shake-icons` pesan 1,0 MB; en release el tree-shaking los reduce a los glifos usados. Las pantallas no importan nada de Phosphor.
- 2026-11-24 · Tipografía: Alfa Slab One (títulos ≥20 px) y Figtree variable (texto), ambas SIL OFL 1.1, offline en `assets/fonts/`. Licencias en `assets/licenses/`, registradas con `registerExtraLicenses()`.

- 2026-11-25 · Sonido de mesa con 7 efectos Kenney (CC0) y API `AppSound`/`playSound` · `lib/core/audio/app_sound.dart`, sin `ref`: lee `AppFeedback.soundEnabled` (Ajustes > Sonido), un `AudioPlayer` por tipo para limitar la superposición y captura cualquier error de audio. Sonidos en `assets/audio/` (chip, chip_soft, card, correct, wrong, tap, podium; ~58 KB en total) de Kenney Casino Audio, UI Audio y Music Jingles. Licencia CC0 verificada en el `License.txt` de cada pack (atribución no obligatoria); texto en `assets/audio/LICENSE-Kenney-CC0.txt`. Motivo: dar sensación de mesa de casino sin añadir dependencias ni peso. Selección hecha sin escuchar: revisar a oído `correct`, `wrong` y `podium` (jingles HIT00/HIT13/HIT15).

- 2026-11-25 · Rediseño "casa de apuestas de hipódromo de los años 30 de noche" · Identidad visual con verdes oscuros, latón y burdeos; titulares en Alfa Slab One (≥20 px) y texto en Figtree. Iconos Phosphor como fuentes TTF propias porque `phosphor_flutter` no compila con Flutter 3.50. Ficha, boleto, Jockey y trofeo se dibujan por código. Sin emojis ni `Icons` de Material (vigilado por test). Audio Kenney CC0. Motivo: dar a la app personalidad propia y coherente sin dependencias pesadas ni recursos con licencias complejas. Aplazado: unificar las dos implementaciones de confeti y partir `cup_screen`, `prompt_deck_screens` y `race_screen` (demasiado grandes).

- 2026-11-25 · Pistas del Abecedario: "Con X al principio" / "Lleva una X" · Segunda reformulación (antes "Arranca con la X"/"Lleva una X dentro"). Motivo: COMPLIANCE #2, alejar la redacción del juego original. "Letra X" no se usa como pista: la letra ya se ve en el chip y en la etiqueta de accesibilidad. La mecánica sigue siendo similar: sigue recomendada la consulta legal.
- 2026-11-25 · `assets/CREDITS.md` marca lo no verificado (versión upstream de Phosphor, commit de google/fonts, URL del Guillermo Tell, fecha de Natural Earth/flagcdn) en vez de inventarlo · El único origen de Phosphor comprobado por hash es `phosphor_flutter` 2.1.0 de pub.dev. Créditos enlaza ahora "Baraja española completa.png" y la autoría de Basquetteur y Germarquezm en Commons (URLs comprobadas con HTTP 200).

- 2026-11-25 · Equipo habin-agents-gang como plugin `habin` en un marketplace `habin-agents` (mismo repo `jlopez0/habin-agents-config`, plugin en `plugins/habin/`), sin `version` para seguir commits; reglas globales por import `@~/.claude/plugins/marketplaces/habin-agents/reglas/equipo.md` en `~/.claude/CLAUDE.md` · Propuesta pendiente de OK (ver `docs/PLUGIN_EQUIPO.md`). Motivo: las copias en `~/.claude/agents` y en cada repo ya se han desfasado (al CLAUDE.md global le faltan 3 filas); los plugins no cargan CLAUDE.md, y el import desde el clon del marketplace se actualiza junto a los agentes. Las copias de usuario y de proyecto tienen prioridad sobre el plugin y conviven con otro nombre, así que hay que borrarlas tras verificar. `initialPrompt` no funciona en agentes de plugin: el arranque del jefe pasa a su cuerpo.

- 2026-11-25 · `juego-flutter` precarga `habin:verification-before-completion` y sigue pautas de TDD (solo lógica del motor), depuración al primer fallo y estado final HECHO / HECHO_CON_DUDAS / BLOQUEADO · Depende del plugin `habin` (si no está instalado, la skill no se precarga y el agente sigue funcionando sin ella). Motivo: menos afirmaciones sin evidencia; ver `habin-agents-gang/docs/ANALISIS_COMBINAR_PLUGINS.md`.

- 2026-11-25 · Trivia y Geografía suman a la Copa (plan 3.11) · Al terminar una vuelta, si hay jugadores en la cuadra, aparece "¿Quién ha jugado?" (`QuizCupSection`, `lib/games/trivia/ui/quiz_cup_section.dart`): se elige a una persona y "Anotar N fichas" hace una sola llamada a `award` (`roundId` = `trivia-<µs>` o `geografia-<µs>`, fijado al terminar la vuelta; volver a entrar o repetir el toque no duplica y deja los chips bloqueados). Regla de fichas, la misma para los dos juegos y alineada con los escalones que ya muestra el resultado (`QuizTier.chips`): **Pleno 3, Gran carrera (≥ 80 %) 2, Colocado (≥ 50 %) 1, menos de la mitad 0**. Siempre es una proporción, así que vale igual con 10 preguntas que con "todas". Solo suma, **nunca resta**: estos juegos no generan retos ni sorbos y no usan `ConsequenceBanner`. Sin jugadores no aparece nada y el juego va como antes. Motivo: es la regla más simple que cabe en la unidad "fichas" (3 como máximo, del orden de las demás rondas: −1 de las cartas, −1/−2 del Infiltrado) y reutiliza escalones que el jugador ya ve. Decisiones ambiguas resueltas por la opción más simple (revisables): (1) no se pondera por dificultad ni por modo de respuesta de Geografía (en "Mental" el acierto es de palabra); (2) una vuelta = una persona (para otra, "Otra vuelta"); (3) sin confirmación al salir sin anotar (no se pierde nada importante: es opcional); (4) fichas según el mejor escalón mostrado, no por número de aciertos. Si más adelante Trivia por equipos pide repartir entre varias personas, basta con permitir varias selecciones y dividir. Abecedario sigue sin sumar a la Copa.

- 2026-11-25 · Etiqueta de resultado "Colocado" renombrada a "En el podio" (Trivia y Geografía; `QuizTier.colocado` pasa a `QuizTier.enElPodio`) · "Colocado" es jerga de hípica pero también de intoxicación, y la lista negra anti-alcohol de `test/content_test.dart` lo rechaza (debe seguir en ella). La regla de fichas no cambia: 50 % de aciertos = 1 ficha. Cabe en la UI: es más corta que "Hoy no era tu carrera" y los tests de desborde a letra 2.0 en 320x568 siguen pasando.
- 2026-11-25 · Cartas de oros y caballos de obra propia · La cabeza de GNU (Free Art License, posible marca) era la moneda de todas las cartas de oros y el caballo (posible GPL, GnuBond) estaba en las cuatro cartas 11; se sustituyen por dibujos propios hechos por código con `tools/gen_cartas_propias.ps1` (oros 1 a 9, moneda de oros 10 y 12, y los cuatro caballos con jinete). Motivo: quitar material de licencia dudosa dentro de la obra CC BY-SA 3.0 sin depender de terceros. El caballo se distingue por palo en el pelaje, la ropa del jinete, la manta y el objeto que sostiene.
- 2026-11-26 · Pistas del Abecedario vuelven a "Comienza por la X" / "Contiene la X" · Tercera redacción (antes "Con X al principio" / "Lleva una X"). Motivo: elección del dueño; son frases descriptivas genéricas y quiere una pista más clara para el jugador. Riesgo legal (COMPLIANCE #2, mecánica de "El Rosco") aceptado por el dueño. Mitigación: sin las marcas ("Rosco", "Pasapalabra" siguen prohibidos en app, ficha y capturas), y el test `abecedario_test.dart` vigila que las pistas no los nombren. Sigue recomendada la consulta legal si la app crece.

### D13. Solo suma a la Copa lo que decide la app; un solo modo, con la home agrupada (2026-11-26, propuesta pendiente de OK de Javier)
- Suman a la Copa: Carrera, El Infiltrado, Trivia y Geografía. No suman: Abecedario, ¿Quién es más probable?, ¿Qué preferirías? y Yo nunca. El motivo es que la opinión y la confesión no se pueden comprobar, y el Abecedario no registra aciertos.
- Se elige la opción B: no hay pantalla de "Noche con Copa / Noche libre". La home agrupa los juegos en "Suman a la Copa" y "Sin marcador" e insignia los que suman; la Copa lista qué juegos cuentan. Lo marca `GameModule.scoresCup` (propiedad de código).
- Matiza **D4**: la Copa sigue contando en fichas sea cual sea el modo, pero solo recoge rondas que decide la app. En los juegos sin marcador, las fichas son solo la unidad de la consecuencia (retos o sorbos) y no se anotan.
- `session.v1` no cambia: no hace falta `.v2`. Si algún día se quiere una noche sin marcador, será un interruptor en `AppSettings` (en línea con D1), no un dato de la sesión.

**Motivo**: la pantalla previa (opción A) añade un paso en cada noche para apagar algo que ya es opcional, y contradice D1. B cuesta poco, se puede deshacer y no toca datos guardados. Diseño y fases en `docs/DISENO_COPA.md`. Pendiente: Yo nunca aún anota −1 por persona en el código (fase 0).

- 2026-11-26 · "¿Quién es más probable?" y "¿Qué preferirías?" dejan de tocar la Copa; ¿Quién es más probable? pasa a `PromptPayMode.stake` · Cada carta anuncia una apuesta aleatoria de 1 a 3 fichas ("¡Por 2 fichas!", `rollStakes`, tope = `kRoundCap`) sobre la pregunta y la mesa la resuelve sola: sin selección de jugadores, sin `award`, sin "−1 en la Copa". En Retos y Sorbos se muestra además un `ConsequenceBanner` para "El más señalado" (tope de 3 y, en Sorbos, "o agua o reto" siempre visible; Sorbos solo con `adultConfirmed`). El modo `single` desaparece del enum (solo quedan `none`, `multi` y `stake`); ¿Qué preferirías? pasa a `none`. Solo Yo nunca (`multi`) sigue restando 1 ficha por jugador marcado. Regla aprobada: "A la de tres, todos señalan. El más señalado paga la apuesta de la carta". Motivo: el −1 premiaba o castigaba la opinión de los demás, no una apuesta ni un acierto; la Copa lo mostraba como "El que más ha pagado" (señalar a una persona) y las cartas rápidas, sin tope por noche, podían decidir la clasificación frente a Trivia/Geografía (máx. 3 por vuelta). El diseño final de la Copa para juegos con y sin apuestas se decide aparte: no se ha tocado `cup_screen.dart` ni el modelo `session.v1`.
  - **Actualización (opción C, D14)**: `PromptPayMode` ahora es `none`/`stake`/`fixed` (el `multi` de Yo nunca desaparece). Yo nunca ya no resta ficha ni va a la Copa: solo muestra un banner fijo "Quien lo haya hecho" (1 reto / 1 sorbo, nada en Fichas). La Copa muestra solo el podio (top 3, sin cola, sin saldos negativos en rojo ni "Menos fichas perdidas"); lo anterior sobre `multi` y "−1 en la Copa" queda superado.
- 2026-11-26 · Sin barra de progreso ni total en ningún juego · Cabeceras: `Carta N` (mazos) y `Pregunta N` (Trivia y Geografía); nunca "n / total". Los botones de setup pasan a "Jugar" (sin "N cartas" ni "N preguntas"); el setup de Geografía muestra "Tu récord: N" sin total; el Infiltrado ya no cuenta las palabras del mazo (solo avisa al agotarse). El Abecedario solo pierde el contador (la cuadrícula A-Z y los temporizadores son el juego). Se mantiene la opción "Todas" de Trivia y Geografía por decisión del dueño (el resultado final sí muestra aciertos/total de la vuelta jugada). "Voto 2 de 4" y "Roles 1/4" del Infiltrado cuentan jugadores, no contenido, y se quedan. Motivo: no revelar cuántas preguntas o cartas hay guardadas.
- 2026-11-26 · Partidas de cartas de duración fija · `PromptDeckModule.rounds` (por defecto `kPromptDefaultRounds` = 15; Yo nunca 20). `drawDeck` reparte una partida de `rounds` cartas sin repetir las ya vistas en la pantalla; si quedan menos sin jugar que `rounds`, rebaraja todo. Al terminar: "Fin de la partida" y "Otra partida". Motivo: duración predecible y sin revelar el tamaño del mazo. 15/20 son un supuesto sin validar con partidas reales.
- 2026-11-26 · `flutter test` no se puede ejecutar en esta máquina · Windows Code Integrity (registro `Microsoft-Windows-CodeIntegrity/Operational`) bloquea `flutter_tester.exe` (sin firma; mismo mecanismo que `font-subset.exe`). Hay que permitir esa ruta o ejecutar los tests en otra máquina o en CI. Los cambios del 2026-11-26 (cartas, Trivia, Geografía, Infiltrado, Abecedario) se verificaron solo con `flutter analyze`.

### D14. UX de previa: "una ficha solo aparece si se anota o se paga" (2026-11-26, propuesta pendiente de OK de Javier)
- Recomendada la alternativa A ("Copa de apuestas"): la Copa solo recoge Carrera e Infiltrado (`scoresCup`). Trivia y Geografía pierden "¿Quién ha jugado?". Yo nunca deja de marcar personas (en Retos/Sorbos, banner fijo "Quien lo haya hecho"). "¡Por N fichas!" se oculta en modo Puntos. Sin cabeceras "Suman / Sin marcador" en la home; insignia y línea "Cuentan: …" en la Copa.
- El modo "Puntos" se muestra como "Fichas" (el enum `puntos` no cambia: está guardado por nombre en `settings.consequenceMode.v1`). El selector de modo también se ve en la home (sigue siendo ajuste global, D1).
- Se quita "El que más ha pagado" de la Copa: en Sorbos se lee como ranking de bebida (pendiente de `habin:cumplimiento`).
- Matiza D13 (home agrupada) y deshace en parte la 3.11 del 2026-11-25. Alternativa B si se quiere mantener la 3.11: 4 juegos en la Copa, con Trivia y Geografía en selección múltiple.

**Motivo**: en una previa la palabra "ficha" tiene hoy cuatro significados según el juego y el modo, y marcar personas en cada carta corta el ritmo. Con A, una noche tiene 5 conceptos propios en vez de unos 12. `session.v1` no cambia y todo se puede deshacer. Detalle y fases en `docs/research/ux_previa.md`.

### D14 · Implementación de las fases 2 y 3 (opción C, 2026-11-26)
- Etiqueta "Fichas" (enum `puntos` intacto), textos de `docs/research/textos_copa_c.md`. El selector Fichas/Retos/Sorbos vive en `lib/core/consequences/consequence_mode_selector.dart` (widget + diálogo +18 compartidos); Ajustes lo muestra completo y la home solo ofrece Sorbos con `adultConfirmed` (riesgo Apple 4.3(b)).
- La Copa sale de la home. Entrada: icono de trofeo en la cabecera de la home, "Ver Copa" al cerrar Carrera e Infiltrado y ayuda propia (`copa` en `ayuda.json`). `CupCard` se borra. Compartir = solo podio (puestos ≤ 3), sin cifras; "El que más ha pagado" desaparece.
- "Cuentan: …" se genera desde `gameModules.where(scoresCup)` y solo se ve dentro de la Copa. Sin insignias en la home.
- En Sorbos, "Pagan/¿Quién paga?/PAGA" pasan a "Les toca/¿A quién le toca?/LE TOCA" (sello añadido por el mismo motivo que el resto: `RaceStamp.leToca`). `stakeHeadline(stake, mode)` devuelve null en Fichas.

### D15. Compilar sin modo Sorbos (iOS) con un `dart-define` (2026-11-26)
- **Decisión**: `const bool kSorbosEnabled = bool.fromEnvironment('SORBOS', defaultValue: true);` en `lib/core/consequences/sorbos_flag.dart`. Android no pasa nada (Sorbos activo, comportamiento actual). iOS: `flutter build ipa --dart-define=SORBOS=false` (en `codemagic.yaml` cuando exista).
- **Inyección para poder probarlo**: un `const` de entorno no se cambia en un test, así que la app lee `sorbosEnabledProvider` (valor por defecto `kSorbosEnabled`); los tests lo sobrescriben (`test/sorbos_flag_test.dart`).
- **Con el flag apagado**: el selector (home y Ajustes) solo ofrece Fichas y Retos; `setConsequenceMode(sorbos)` y `selectConsequenceMode(sorbos)` no hacen nada (ni diálogo +18 de Sorbos); un `sorbos` guardado en preferencias se lee como `puntos` (la preferencia no se borra: si se instala una compilación con Sorbos, vuelve); la bienvenida y los créditos dicen "Nadie está obligado a nada" en vez de "a beber"; la ayuda usa `pasosLite` en las dos entradas que citaban "agua o reto" (`quien-es-mas-probable`, `yo-nunca`). El +18 de Atrevido no cambia.
- **Intacto**: el enum `ConsequenceMode.sorbos` (el formato `session.v1` y `settings.consequenceMode.v1` no cambian) y todo el código de Sorbos de los juegos: con el modo imposible esas ramas no se ejecutan, así que nunca se ve su texto. Los literales siguen en el binario; si Apple los objeta, habría que extraerlos con `if (kSorbosEnabled)` (el compilador los elimina).
- **`ayuda.json`**: `pasosLite` es opcional por entrada y sustituye a `pasos` solo sin Sorbos. La clave no usa palabras de la lista negra (`content_test`, `no_alcohol_text_test`).
- **Motivo**: el revisor de Apple puede ver Sorbos en Ajustes o en la ayuda (4.3(b), 1.4.3; `docs/research/cumplimiento_copa.md` y COMPLIANCE #3).
- **Pendiente (no es código)**: rehacer la ficha iOS y las capturas sin Sorbos, y revisar las respuestas del cuestionario de edad de Apple (alcohol) con esta compilación.

### D16. El nombre público pasa de "Paddock" a "Habinson" (2026-11-26, decisión de Javier)
- **Cambia (lo que ve el usuario o la tienda)**: `kAppName` (título de la app, cabecera de la home, Ajustes, texto de compartir de la Copa), pantalla de licencias, `android:label`, `CFBundleDisplayName`, `description` de `pubspec.yaml`, cinta del as de oros (ahora "HABINSON", regenerada con `tools/gen_cartas_propias.ps1`; solo cambia `oros_1.png`, en `assets/cards/` y `docs/cartas/`), `assets/CREDITS.md`, páginas de `docs/` (privacidad, soporte, créditos, índice), ficha y documentos de `docs/store/`, y documentación del repo. Título de tienda: "Habinson: Juegos de fiesta" (26/30).
- **Lema de la home**: "Se abre el paddock" pasa a "Se abre la noche" (`paddock` ya no es el nombre de la casa). Anotado en `docs/MICROCOPY.md`.
- **No cambia (identificadores técnicos)**: `applicationId`/bundle id `es.jlopez0.paddock` (CLAUDE.md prohíbe cambiarlo tras publicar), `namespace com.paddock.paddock`, paquete Dart `paddock` y sus `import 'package:paddock/...'`, clase `PaddockApp`, `CFBundleName`, nombres de artefactos de CI (`Paddock.ipa`), `paddock-upload.jks`, la carpeta del repo y las URLs `https://jlopez0.github.io/Paddock/...`.
- **Motivo**: cambiar el nombre visible es gratis y reversible; cambiar IDs rompe actualizaciones y firma. Las URLs de privacidad/soporte dependen del nombre del repo en GitHub: si se renombra el repo, hay que actualizar `kPrivacyUrl`, `kSupportUrl`, las fichas y los enlaces de `docs/`.
- **Pendiente**: búsqueda de disponibilidad y marca de "Habinson" (COMPLIANCE #11, antes sobre "Paddock"); rehacer icono/splash e imágenes de tienda si llevan el texto "Paddock"; los informes de `docs/research/`, `DISENO_COPA.md` y `FASES_1_3.md` conservan el nombre antiguo (históricos).

### D18. Identificadores técnicos pasan de "paddock" a "habinson" (2026-11-26, decisión de Javier)
- **Cambia**: `applicationId` y bundle id `es.jlopez0.paddock` pasan a `es.jlopez0.habinson` (incluido `.RunnerTests`); `namespace` y paquete Kotlin `com.paddock.paddock` pasan a `com.habinson.habinson` (carpeta movida con `git mv`); paquete Dart `paddock` pasa a `habinson` (`package:habinson/...`); clase `PaddockApp` pasa a `HabinsonApp`; `CFBundleName` = `habinson`; artefactos de CI `Habinson.ipa` / `Habinson-ipa`; clave de subida documentada como `habinson-upload.jks`; URLs `https://jlopez0.github.io/Habinson/...` (el repo de GitHub ya se renombró a `jlopez0/Habinson`).
- **Motivo**: la app aún no está publicada, así que cambiar el ID no rompe actualizaciones ni firma; hacerlo ahora evita arrastrar el nombre antiguo. Sustituye al "No cambia" de D16 en lo técnico.
- **Intacto**: `docs/research/*` (históricos), la carpeta local del repo (la renombra Javier a mano), `.gitignore` conserva las rutas `Paddock-ipa*` y añade las de Habinson, y la variable de entorno de test `PADDOCK_ICON_SHEET_DIR`.
- **Pendiente (fuera del repo)**: crear la clave `habinson-upload.jks` (no se ha tocado ninguna real), registrar el ID `es.jlopez0.habinson` en Play Console / App Store Connect / Firebase si ya había algo con el ID antiguo, y desinstalar del emulador/dispositivos la build `es.jlopez0.paddock`.

### D17. Correcciones de la Copa tras el QA de emulador (2026-11-26)
- **All-in ganador sin repartir (I1)**: `_leave` ya enviaba `award` antes de navegar; el fallo era que un ganador que no reparte tiene delta 0 y `Session.withRound` descarta los ceros, así que no entraba en la clasificación. `award` y `withRound` ganan `recordZeros` (por defecto `false`, el resto de juegos no cambia) y la Carrera lo activa: el ganador queda en la Copa **con 0 fichas**. Supuesto: un All-in no repartido no genera fichas de nadie (sin pagadores no hay a quién restar), así que no suma nada; solo se evita que el ganador desaparezca. Sigue habiendo un único `award` por ronda con el `roundId` fijado al terminar la carrera; tras salir, la elección queda bloqueada (`settled`), así que volver y entrar de nuevo no cuenta doble. Si se prefiere obligar a repartir antes de salir, bastaría un aviso al pulsar "Ver Copa" con All-in pendiente.
- **Empates en el podio (I3)**: el podio muestra todos los puestos 1 a 3 con sus empatados (puede haber más de 3 columnas); la cola (puesto 4 o peor) sigue sin salir. Con más de 3 columnas se usa el orden de puesto en vez de 2-1-3.
- **Cuándo se celebra (M4)**: trofeo, Jockey que celebra, medallas, confeti, háptico, sonido y "Va en cabeza"/"Ganador" solo si quien manda tiene más de 0 fichas. Con 0 o negativo: "Nadie va en positivo" (cerrada la noche, "Nadie ha acabado en positivo") y debajo "Los que menos han perdido: …"; las plazas se rotulan con "1.º", "2.º"... en vez de medallas. En "Por juego", "Líder: …" pasa a "Nadie en positivo" si el líder del juego no tiene fichas a favor. El texto compartido sigue sin cifras: sustituye "Va en cabeza: …" por la misma frase neutra. Motivo: la Copa no debe celebrar pérdidas.
- Copa vacía: "Aún no hay rondas que cuenten" (valía "corrido" solo para la Carrera) y la lista de juegos se toma del registro.
- Resultado del Infiltrado: si la Copa ya no tiene la ronda (Nueva noche), no dice "en la Copa"; la pérdida se muestra como "−2 fichas".

### D19. Vocabulario de dos capas: la consecuencia en la unidad del modo, la Copa en fichas (2026-11-26)
- **Decisión**: los textos se rigen por dos capas. (1) **Consecuencia**: lo que se juega en la vida real va en la unidad del modo: `reto(s)` en Retos y `sorbo(s) · o agua o reto` en Sorbos. (2) **Copa**: el marcador sigue en fichas en los tres modos (D4, D13; `session.v1` no cambia) y se presenta como marcador, no como "lo que pagas". Fuera de la Copa, "ficha(s)" solo aparece en modo Fichas. "Paga/Pagan/PAGA/¿Quién paga?" y "Cobran/COBRA/cobra N fichas" también quedan solo en Fichas; en Retos y Sorbos se dice `Les toca` / `LE TOCA` / `¿A quién le toca?` y `Aciertan` / `ACIERTA` / `Ana acierta`. Fuente de los textos: `docs/research/textos_vocabulario.md`; mapa: `docs/research/auditoria_sorbos.md`.
- **Aplicado**: resultado de la Carrera (cabeceras, boletos, sellos, motivos, "Nadie acertó", botón `¿A quién le toca?`), selector de apuesta (tooltips `Bajar apuesta` / `Subir apuesta`, etiqueta `Apuesta de N`, All-in `All-in · 3 retos` / `3 sorbos`), nota `Ya cuenta en la Copa de la noche.` en Carrera e Infiltrado, sin `−N en la Copa` por boleto ni `En la Copa, cada All-in vale 10 fichas` (solo Fichas), reglas del Infiltrado en Retos, estadísticas `a favor` / `en contra`, subtítulo de la home de la Carrera, texto de "Acertar gana el doble", Copa (`Sin perder nada: …`, `Quien menos ha perdido: …`, `Quienes menos han perdido: …`), `ayuda.json` (sin "sorbo": `content_test` lo veta en JSON) y la carta `qp043`.
- **Rango de la apuesta sin tocar** (decisión pendiente de Javier): sigue siendo 1 a 5, con el All-in a 10 y el tope de `resolveLoss` a 3. Para que no se lea "apuesto 5" junto a "3 sorbos", en Retos y Sorbos el selector enseña el número sin unidad (rótulo `apuesta`) y una nota bajo `Boletos` con el tope: `Hasta 3 por ronda` (Retos) o `Hasta 3 por ronda · o agua o reto` (Sorbos). El botón All-in dice `3 retos` / `3 sorbos` porque es lo que se juega de verdad. Si Javier fija 1 a 3, basta cambiar `Bet.maxChips` y la nota se puede retirar.
- **Pendiente de diseño**: la ficha dibujada del All-in (`RaceChip`, `ChipToken`) sigue pintando "10" junto a "3 sorbos / 3 retos". En Retos y Sorbos convendría dibujarla sin cifra.
- **Ayuda estática**: `ayuda.json` no depende del modo, así que usa redacciones neutras ("te toca lo que apostaste", "El modo elegido decide qué se juega").

### D20. Intensidad 1–3 en los mazos y Retos = un solo reto por nivel (2026-11-26, decisión de Javier)
- **Decisión** (sobre la propuesta `docs/research/sistema_consecuencias.md`): (1) **Yo nunca** deja de tener 1 fija: cada carta lleva una intensidad aleatoria de 1 a 3 (`rollStakes`, como ¿Quién es más probable?). El banner "Quien lo haya hecho" usa esa intensidad (Sorbos: "N sorbos · o agua o reto", tope 3; Fichas: nada) y no duplica titular: el titular de la carta solo existe en `PromptPayMode.stake`. (2) **Retos**: nunca "N retos". Cada evento con consecuencia muestra UN reto de `retos.json` cuyo nivel depende de la intensidad: 1 suave, 2 picante, 3 o más atrevido con +18 (sin +18, picante); si el pool queda vacío, cualquier reto permitido y, al final, `kFallbackRetos`. Cantidad en Retos: "Un reto"; titular de apuesta: "¡Por un reto!". (3) **Sorbos y Fichas no cambian** (tope 3, +18, "o agua o reto" visible). La **Carrera sigue con apuesta 1–9 + All-in** (`Bet.maxChips` intacto) y solo cambia lo mostrado en Retos: un reto de nivel `min(fichas, 3)`, el All-in = nivel máximo. Los quizzes siguen sin consecuencia.
- **Código**: `RetoPools` (`lib/core/consequences/retos_filter.dart`, lógica pura con `forIntensity(n)` y `pick(n, offset)`; `kFallbackRetos` se mueve ahí y `consequence_banner.dart` lo reexporta); `ConsequenceBanner` gana `retoPools` y `retoOffset` (conserva `retos` plano); `amountText` en Retos devuelve `kUnReto`; `_Payers` de la Carrera y el resultado del Infiltrado usan `RetoPools`; `PromptPayMode.fixed` ya no usa `kPromptFixedChips` (borrada). Textos: `race_texts.dart` (`retosText` eliminada), selector de modo, reglas del Infiltrado, `ayuda.json`, `docs/MICROCOPY.md`, ficha de tienda.
- **Motivo**: un reto es un acto único; sumar retos obliga a acumular y nadie decide cuándo se cumplen. La intensidad elige el nivel del reto y la app decide, no el grupo.
- **Sin cambios de formato**: `session.v1` y la apuesta guardada de la Carrera no se tocan (no hay migración).

### D21. Sin Carrera de caballos en modo Retos; Abecedario con aciertos y fallos (2026-11-26, decisión de Javier)
- **Carrera**: con `consequenceMode == retos` la Carrera no se ofrece. `GameModule.availableIn(mode)` (por defecto `true`; `HorseRaceModule` devuelve `mode != retos`) y `gamesFor(mode)` en `registry.dart` filtran la lista. La home oculta su cartel (el resto conserva el orden y se numera desde 1; en Fichas y Sorbos sigue siendo la primera). El router reevalúa sus redirecciones al cambiar el modo y manda a `/` desde `/game/carrera` y sus subrutas (`race`, `result`, `stats`), también si el modo cambia con la Carrera abierta. Motivo: en Retos la apuesta de 1 a 5 fichas obligaba a reglas propias (nivel del reto por apuesta, All-in = reto máximo) que no se explican bien.
- **Copa y sesión**: no se tocan los datos. Las rondas de Carrera ya anotadas siguen contando y se muestran en "Por juego" si se cambia a Retos a mitad de noche. Solo cambian los textos: "Cuentan: …" y el estado vacío salen de `gamesFor(mode)` ("Cuentan: El Infiltrado", "Aquí cuentan los votos. Manda quien acaba con más fichas."). `session.v1` y el enum `ConsequenceMode` no cambian.
- **Código de Retos retirado** (solo servía a la Carrera): ramas `retos` de `race_texts.dart` (All-in, "Un reto", nota del tope, botón y etiqueta del All-in) y la carga de `retos.json`/`RetoPools` en `race_result_screen.dart`. En la Carrera todo lo que no es Fichas se trata como Sorbos. **Se conserva** lo compartido: `RetoPools`, `retos_filter.dart`, `kUnReto`, `ConsequenceBanner`, mazos e Infiltrado (D20).
- **Efecto sobre D20**: la frase "la Carrera sigue con apuesta 1–9 + All-in y en Retos muestra un reto de nivel `min(fichas, 3)`" queda superada; en Retos no hay Carrera. El resto de D20 sigue igual.
- **Abecedario**: tras desvelar cada letra salen los botones de solo icono "Fallo" y "Acierto" (`AppIcon.cancel`/`AppIcon.check`, con tooltip y `Semantics(selected)`) junto a "Siguiente". Pulsar la misma marca la quita y la contraria la sustituye. Es solo un registro: sin fichas, sin consecuencia y sin Copa. La lógica vive en `lib/games/abecedario/abecedario_review.dart` (`AbecedarioReview`, inmutable, con tests). Al terminar, el resultado muestra aciertos, fallos y (si hay) sin marcar; "Para repasar" con cada letra fallada, su pista, su definición y la respuesta destacada; y "Todas las letras" con la palabra y su resultado. Si no se marcó nada, avisa en vez de listar. Salir sigue yendo a `/` (con confirmación en mitad de la partida). Nada se guarda: el registro vive solo durante la vuelta.

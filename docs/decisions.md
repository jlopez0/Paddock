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

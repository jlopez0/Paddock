# Diseño · Qué juegos suman a la Copa (2026-11-26)

> **SUPERADA por D14 / opción C (2026-11-26).** Ver `docs/research/validacion_copa.md`. Este documento se conserva como historial: lo que aquí se lee como vigente (4 juegos con Copa, "Sin marcador") ya no aplica.

Estado: **propuesta, pendiente de OK de Javier**. Decisión registrada como D13 en `docs/decisions.md`.

## 1. Clasificación de los juegos actuales

Regla: **solo suma a la Copa lo que decide la app** (sorteo, votación registrada o respuesta comprobable). Lo que depende de la opinión o de la confesión de la mesa no se anota.

| Juego | ¿Suma? | Por qué | Estado del código (árbol actual) |
|---|---|---|---|
| Carrera de caballos | Sí (±) | Apuestas resueltas por el mazo | `race_result_screen.dart` llama a `award` |
| El Infiltrado | Sí (solo resta) | Votación hecha en la app y palabra comparada por el motor | `infiltrado_store.dart` |
| Trivia | Sí (0 a 3) | Respuesta comprobada por la app | `quiz_cup_section.dart` |
| Geografía | Sí (0 a 3) | Igual que Trivia. En modo "Mental" el acierto es de palabra ("Acerté"): se acepta (D 3.11) | `quiz_cup_section.dart` |
| Abecedario | No | La app no registra aciertos: se lee, se desvela y se pasa | Sin `award` |
| ¿Quién es más probable? | No | Se señala a viva voz; la apuesta de la carta solo es consecuencia | `PromptPayMode.stake`, sin `award` |
| ¿Qué preferirías? | No | No hay respuesta correcta | `PromptPayMode.none` |
| Yo nunca | No (según la decisión de hoy) | Confesión: no se puede comprobar | **Aún anota** −1 por persona (`payMode: multi` en `registry.dart`). Hay que alinearlo (fase 0) |

Resultado: 4 juegos con Copa y 4 sin marcador. El orden de `registry.dart` ya los agrupa: los 4 primeros suman y los 4 últimos no.

Consecuencia que no se ve a simple vista: en modo **Puntos** (el modo por defecto), las fichas de los juegos de opinión ("¡Por 2 fichas!") no tienen ningún efecto. Solo valen en Retos o Sorbos, como unidad de consecuencia. Hay que decirlo o aceptarlo (pregunta 2).

## 2. Opciones

| Opción | Coste | Riesgo | Reversibilidad |
|---|---|---|---|
| A. Pantalla "Noche con Copa / Noche libre" al empezar | Medio-alto: pantalla nueva, estado de modo, un momento de "empezar noche" que hoy no existe (la noche arranca sola con la primera ronda) | Medio: un paso más justo cuando la mesa tiene prisa, se repite cada noche, casos al cambiar de modo a mitad | Alta, si el modo va fuera de `session.v1` |
| **B. Un solo modo, con los juegos agrupados en la home ("Suman a la Copa" / "Sin marcador") e insignia de Copa** | Bajo: un getter, dos cabeceras, una insignia y una línea en la Copa | Bajo | Alta |
| C. Copa por defecto y los de opinión como "Interludio" | Igual que B | Bajo, pero "Interludio" es jerga que hay que explicar | Alta |

**Crítica de A.** "Noche libre" solo apaga algo que ya es opcional: la tarjeta de la Copa no aparece en la home hasta la primera ronda anotada, Trivia y Geografía piden "¿Quién ha jugado?" y quien no quiera competir puede no mirar la Copa. La pantalla extra cobra fricción a todas las noches para un beneficio que casi nadie necesita. Además contradice D1, que ya descartó elegir cosas al empezar cada noche ("un paso más antes de jugar"). Tendríamos un ajuste global (consecuencias) y otro por noche (Copa), y eso no es coherente. Si "Con Copa" ocultase los juegos de opinión, rompería la mezcla real de una fiesta. Si no los oculta, A se queda en B más un interruptor.

**Recomendación: B.** C es B con otro nombre, y peor. Si alguien pide de verdad "noche sin marcador", se añade como interruptor en Ajustes (fase 4, opcional), en línea con D1, y no como pantalla.

## 3. Flujo con B

```
Home
+--------------------------------------+
| Paddock                     [Ajustes]|
| [La cuadra: 5 jugadores        >]    |
| [Copa de la noche · top 3  Ver Copa] |  <- solo si hay rondas anotadas
|                                      |
| SUMAN A LA COPA                      |
| [1 Carrera de caballos     (trofeo)] |
| [2 El Infiltrado           (trofeo)] |
| [3 Trivia                  (trofeo)] |
| [4 Geografía               (trofeo)] |
| SIN MARCADOR                         |
| [5 Abecedario                      ] |
| [6 ¿Quién es más probable?         ] |
| [7 ¿Qué preferirías?               ] |
| [8 Yo nunca                        ] |
+--------------------------------------+
        | toca un juego (igual que hoy, sin pasos nuevos)
        v
   Juego -> resultado -> award() solo si game.scoresCup
        v
Copa de la noche
  Clasificación · Por juego · Compartir · Nueva noche
  "Suman: Carrera, El Infiltrado, Trivia y Geografía."  <- generado desde el registro
```

**Cambiar de modo a mitad de noche.** Con B no hay modo, así que el caso no existe. Con el interruptor opcional (fase 4): al apagarlo, `award` no anota nada y la tarjeta de la Copa se oculta, pero los eventos se conservan; al encenderlo se sigue sumando donde se dejó. "Nueva noche" sigue siendo la única forma de borrar. No se pide confirmación porque no se pierde nada.

## 4. Impacto en `session.v1`, D4 y la ficha

- **`session.v1`: no hace falta `.v2`.** B no guarda nada nuevo: `scoresCup` es una propiedad de código de cada `GameModule`. Si se hace la fase 4, el interruptor va en `AppSettings`, no en la sesión. Las rondas antiguas de Yo nunca o de los mazos que haya en móviles de prueba se quedan como están (son eventos válidos) y desaparecen con "Nueva noche" o al pasar 12 h. No se filtran. Nota: la app aún no está publicada, así que hoy esto solo afecta a quien la esté probando.
- **D4** se matiza (ver D13): la Copa sigue contando en fichas sea cual sea el modo, pero **solo recoge rondas que decide la app**. En los juegos sin marcador, las fichas son solo la unidad de la consecuencia (retos o sorbos) y no se anotan.
- **Ficha de tienda** (`docs/store/ficha_es.md`): la sección de la Copa pasa a "Carrera de caballos, El Infiltrado, Trivia y Geografía suman o restan fichas…". Hay que quitar "La minoría paga" de ¿Qué preferirías? (ya no es la regla), actualizar el párrafo "Pendiente de decidir" y revisar `notas_version_1_0.md`. Las notas para Apple ("several games") siguen siendo válidas. Las capturas, con la home agrupada.

## 5. Fases

| Fase | Qué cambia · archivos | Hecho cuando | TDD | Agente |
|---|---|---|---|---|
| 0. Yo nunca deja de anotar | `registry.dart` y `prompt_deck_*`: sin `award` en ningún mazo. "¿Quién paga?" solo se ve en Retos y Sorbos (en Puntos no haría nada). Se actualizan `prompt_deck_pay_test.dart` y el texto de la regla | Ningún mazo llama a `award` (test). En Retos, marcar a 2 personas muestra sus retos. analyze y test en verde | sí | `juego-flutter` (Sonnet medio) |
| 1. `GameModule.scoresCup` | `game_module.dart` (getter, `false` por defecto), `true` en los 4 módulos que suman. Sustituye al getter actual de `PromptDeckModule`. Test de guardia: el conjunto de ids que suman es exactamente {carrera, infiltrado, trivia, geografía}, y en el registro los que suman van antes que los que no | Tests nuevos en verde | sí | `implementador` (Sonnet medio) |
| 2. Home agrupada y línea en la Copa | `home_screen.dart` (2 cabeceras + insignia con `AppIcon.trophy`), `cup_screen.dart` (`_howItWorks` + "Suman: …" desde el registro). Textos antes con `redactor-es` | Widget test: cabeceras presentes, sin desborde a letra 2.0 en 320x568, `no_emoji_test` en verde. Revisión en emulador | no | `redactor-es` para los textos y luego `implementador` |
| 3. Documentación y ficha | `ficha_es.md`, `notas_version_1_0.md`, `MICROCOPY.md` (glosario: "Sin marcador"), nota en `COMPLIANCE.md` R11, `FASES_1_3.md` | Ninguna frase dice que los juegos de cartas suman | no | `mecanico` (Haiku), con revisión de `redactor-es` en la ficha |
| 4. (Opcional, solo si se pide) Interruptor "Copa de la noche" en Ajustes | `AppSettings` + `award` sin efecto si está apagado + `CupCard` oculta | Tests del controlador: apagado no anota y al encender se conservan los eventos | sí | `implementador` |

Riesgos: (1) con las dos cabeceras, los últimos juegos bajan más en pantallas pequeñas; hay que comprobarlo en 320x568. (2) Tests que buscan textos de la regla de Yo nunca o de "¿Quién paga?". (3) Si más adelante el Abecedario puntúa, hará falta una mecánica nueva (contar aciertos de palabra); queda para la v1.1 y bastará con cambiar su `scoresCup`. Las fases 0 y 1 tocan qué datos se anotan, así que pasan por `habin:revisor`.

## 6. Preguntas para Javier

1. **Yo nunca**: el código aún resta 1 ficha por confesión. ¿Confirmas que deja de anotar en la Copa, igual que los otros dos mazos?
2. **Modo Puntos en los juegos de opinión**: la apuesta "¡Por 2 fichas!" de ¿Quién es más probable? no tiene efecto. ¿Se deja como adorno de la carta o se oculta en Puntos y solo se muestra en Retos y Sorbos?
3. **"Noche libre"**: ¿la necesitas para la v1.0? Mi recomendación es que no; si algún tester la pide, se añade como interruptor en Ajustes (fase 4).

# UX en una previa: auditoría de conceptos y marcador (2026-11-26)

Estado: **propuesta, pendiente de OK de Javier** (D14 en `docs/decisions.md`). Revisa `DISENO_COPA.md` (D13) antes de que se implemente.
Escenario: 4-8 amigos, un móvil que pasa de mano en mano, ruido, poca atención. Las fichas son simbólicas y nadie las audita. Éxito = se entiende en unos 10 s y no corta la conversación.

## 1. Carga cognitiva

**Por noche.** Hoy la app reparte unos 12 términos propios: ficha, Copa de la noche, cuadra, Puntos/Retos/Sorbos, All-in, reparto de All-in, Cobran/Pagan, Pleno/Gran carrera/En el podio, "¿Quién ha jugado?", "¿Quién paga?", apuesta de carta ("¡Por 2 fichas!") y Nueva noche. D13 añadiría "Suman a la Copa / Sin marcador". Objetivo: **5 o menos** (ficha, Copa, cuadra, modo, All-in). El resto debe ser propio de cada juego.

**El problema de fondo: "ficha" significa cuatro cosas** según el juego y el modo.

| Caso | Qué hace una ficha |
|---|---|
| Carrera e Infiltrado | Se anota en la Copa (y en Retos/Sorbos, además se paga) |
| Trivia y Geografía | Solo se anota en la Copa (solo suma; nunca es reto ni sorbo) |
| Yo nunca (hoy) | −1 en la Copa por persona marcada a mano |
| ¿Quién es más probable?, modo Puntos | **Nada**: "¡Por 2 fichas!" no va a ninguna parte |

**Por juego** (conceptos que hay que entender antes de la 1ª ronda).

| Juego | Propios del juego | Añadidos por el sistema de fichas | Toques de gestión por ronda | Veredicto |
|---|---|---|---|---|
| Carrera | palo, apuesta, obstáculo | All-in = 10, reparto de 2 All-in, Cobran/Pagan | 2 por jugador + girar el móvil | Carga alta, pero es el espectáculo. Se queda |
| El Infiltrado | palabra/categoría, pasar el móvil, debate, voto, última oportunidad | −2/−1 | 1 por jugador (voto) | Bien: las fichas caen solas |
| Trivia | 4 opciones | escalones a fichas, "¿Quién ha jugado?", Anotar | 2 al final | **El sistema pesa más que el juego** |
| Geografía | tipo y dificultad | lo mismo que Trivia, más el récord | 2 al final, con 5 bloques de ajustes | Lo mismo que Trivia, con más ajustes |
| Abecedario | letra, definición, reloj | ninguno | 0 | Bien |
| ¿Quién es más probable? | señalar | apuesta que no hace nada en Puntos | 0 | Ruido en Puntos |
| ¿Qué preferirías? | elegir | ninguno | 0 | Bien |
| Yo nunca | confesar | "¿Quién paga?" y −1 en la Copa | **hasta 8 por carta**, 20 cartas | Rompe el ritmo: el que tiene el móvil marca en vez de reírse |

## 2. Dónde sobra o confunde el marcador

1. **"Puntos" es el modo por defecto, pero es el único modo sin consecuencia real.** En los mazos significa "no pasa nada", y sin embargo la carta sigue anunciando fichas. Además "puntos" choca con el glosario ("ficha" en todas partes). El selector está escondido en Ajustes, que es justo donde una mesa no mira.
2. **"¿Quién ha jugado?" en Trivia y Geografía.** En una previa se responde en grupo a gritos y nadie "ha jugado" solo. La pregunta no encaja con cómo se juega. Además pesa poco: 3 fichas como máximo, frente a los ±10/20 del All-in. Cuesta un concepto (escalones a fichas) y no mueve la clasificación.
3. **Agrupar la home en "Suman / Sin marcador"** (D13) pone el marcador como primer criterio para elegir juego. Nadie elige así en una fiesta. Además baja a la parte de abajo los juegos de previa por excelencia (Yo nunca, ¿Quién es más probable?) y añade dos filas en 320x568. La pregunta "¿por qué no ha contado?" surge en la Copa, así que es allí donde hay que responderla.
4. **Riesgo de cumplimiento.** "El que más ha pagado" en la Copa, en modo Sorbos, se lee como "el que más ha bebido", y eso es un ranking ligado a beber. Lo tiene que revisar `habin:cumplimiento`. Propuesta: quitarlo (el podio ya basta).
5. El orden actual empieza por la Carrera, que es el juego con más preparación: nombres, palo y apuesta de cada uno, y girar el móvil. La primera experiencia de un grupo nuevo es la más lenta.

## 3. El primer minuto ideal

Meta: **de abrir la app a la 1ª carta, en 4 toques o menos, en menos de 15 s y sin teclear.**

```
Abrir -> (solo la 1ª vez) +18 "Entendido" -> Home
Home:  [Cuadra: Forma la cuadra >]   (opcional, no bloquea)
       Se paga con: [Fichas | Retos | Sorbos]   <- visible; Sorbos sigue pidiendo +18
       1 ¿Quién es más probable?   2 Yo nunca   3 Carrera ...
-> toca un mazo -> nivel ya marcado (Suave+Picante) -> "Jugar" -> carta 1
```
La cuadra se pide solo cuando el juego la necesita (Carrera e Infiltrado ya la piden dentro del setup, con campo de alta). Hoy, quitando la bienvenida, el mismo recorrido ya son 3 toques. Lo que falla es que el primer cartel sea la Carrera y que el modo no se vea.

## 4. Propuesta

Principio: **una ficha solo aparece en pantalla si se anota en la Copa o se convierte en reto o sorbo.**

| Alternativa | Qué es | Conceptos por noche | Coste | Riesgo | Reversible |
|---|---|---|---|---|---|
| **A. "Copa de apuestas" (recomendada)** | La Copa solo recoge Carrera e Infiltrado. Sin cabeceras en la home. Fichas visibles solo cuando significan algo | 5 | ~1,5 días | Bajo (no toca `session.v1`) | Alta: `scoresCup` es código |
| B. D13 pulido | La Copa recoge 4 juegos, Trivia y Geografía con selección múltiple ("¿Quién la ha clavado?"), insignia en vez de cabeceras | 7-8 | ~1,5 días | Bajo | Alta |

Por qué A: los dos juegos que quedan son los únicos en los que la app sabe quién gana y quién pierde **por persona** (apuesta y voto). Encaja con la casa de apuestas: en la Copa cuenta lo que se apuesta o se vota. Contra A: deshace la 3.11 del 25/11 (Trivia y Geografía suman). Si Javier quiere mantenerla, la B es la salida.

Cambios de A (esfuerzo: XS < 30 min, S de 1 a 2 h, M medio día):

| # | Acción | Cambio | Archivos | Esfuerzo |
|---|---|---|---|---|
| 1 | Quitar | Yo nunca deja de marcar personas. En Retos/Sorbos, banner fijo "Quien lo haya hecho: 1 reto / 1 sorbo · o agua o reto". En Fichas, nada | `registry.dart`, `prompt_deck_module.dart`, `prompt_deck_screens.dart`, `prompt_deck_pay_test.dart`, `ayuda.json` | S |
| 2 | Quitar | "¡Por N fichas!" oculto en modo Fichas; se ve en Retos/Sorbos | `prompt_deck_screens.dart`, tests de mazos | XS |
| 3 | Quitar | Trivia y Geografía sin "¿Quién ha jugado?". Los escalones (Pleno...) se quedan como titular, sin fichas | `trivia_result_screen.dart`, `geo_result_screen.dart`, `quiz_cup_section.dart` (se borra o se aparca), `quiz_cup_*_test.dart`, `ayuda.json` | S |
| 4 | Quitar | "El que más ha pagado" fuera de la Copa y del texto que se comparte | `cup_screen.dart`, `cup_screen_test.dart` | XS |
| 5 | Renombrar | Modo "Puntos" pasa a "**Fichas**". Solo cambia la etiqueta: **el enum `puntos` no se toca** porque está guardado en preferencias | `settings_screen.dart`, `MICROCOPY.md` | XS |
| 6 | Fusionar | Selector de modo visible en la home (fila compacta bajo la cuadra), con la misma lógica y el mismo diálogo +18 que Ajustes (se saca a un helper). Ajustes lo conserva | `home_screen.dart`, `settings_screen.dart` | S-M |
| 7 | Dejar y ajustar | `GameModule.scoresCup` (true solo en Carrera e Infiltrado), una insignia pequeña de trofeo en su cartel y en la Copa la línea "Cuentan: Carrera de caballos y El Infiltrado", generada desde el registro. **Sin cabeceras** | `game_module.dart`, 2 módulos, `home_screen.dart`, `cup_screen.dart` | S |
| 8 | Reordenar | Home: ¿Quién es más probable?, Yo nunca, Carrera, El Infiltrado, ¿Qué preferirías?, Abecedario, Trivia, Geografía. Hay que rehacer la captura `01_home.png` | `registry.dart` | XS |
| 9 | Dejar | All-in y su reparto (es un momento social, de señalar a amigos), Infiltrado, Nueva noche y caducidad de 12 h, +18 de Atrevido | — | 0 |
| 10 | Opcional | Carrera: bloque "Reglas" plegado bajo "Más opciones" | `race_setup_screen.dart` | S |

## 5. Respuestas a DISENO_COPA §6

1. **Yo nunca:** sí, deja de anotar en la Copa. Y además deja de pedir marcar a nadie (cambio 1). Marcar persona por persona en 20 cartas es el mayor freno de la app en una previa.
2. **"¡Por 2 fichas!" en Puntos:** se oculta en Puntos (Fichas) y solo se ve en Retos y Sorbos, donde se traduce en 1-3 retos o sorbos con el tope de 3 y "o agua o reto". Dejarlo como adorno contradice el principio de §4.
3. **"Noche libre":** no para la v1.0, ni como pantalla ni como interruptor. La Copa ya no aparece hasta la primera ronda que puntúa, y con la A solo puntúan dos juegos. Solo se añade si la piden los testers.

## 6. Fases

| Fase | Contenido | Hecho cuando | TDD | Agente |
|---|---|---|---|---|
| 0 | Javier elige A o B y valida el orden de la home. `habin:cumplimiento` revisa el punto 2.4 | OK por escrito en D14 | — | Javier, `habin:cumplimiento` |
| 1. Qué se anota | Cambios 1, 3 y 7 (sin la insignia). Test de guardia: el conjunto de `scoresCup` es exactamente {carrera, infiltrado}, y ningún mazo ni ningún juego de preguntas llama a `award` | analyze limpio y tests en verde (en CI o en otra máquina, por D 2026-11-26), y pasa por `habin:revisor` (datos) | sí | `juego-flutter` (Sonnet medio) |
| 2. Fichas con sentido | Cambios 2, 4 y 5, y la insignia y la línea del 7 | Widget tests: sin texto de apuesta en Fichas, y con el banner y "o agua o reto" en Sorbos. `no_emoji_test` en verde | no | `redactor-es` (textos) y luego `implementador` (Sonnet medio) |
| 3. Primer minuto | Cambios 6, 8 y (opcional) 10 | Widget test: el selector de la home pide el +18 antes de Sorbos, sin desborde a letra 2.0 en 320x568. Comprobación en emulador: 1ª carta en 4 toques o menos | no | `implementador` (Sonnet medio) |
| 4. Docs y tienda | `ayuda.json`, `ficha_es.md`, `notas_version_1_0.md`, `MICROCOPY.md`, `DISENO_COPA.md` (pasa a superada) y captura de la home | Ninguna frase dice que suman Trivia, Geografía o los mazos | no | `mecanico` (Haiku), con revisión de `redactor-es` en la ficha |

Nada de esto es irreversible: `session.v1` no cambia. Los eventos antiguos de Trivia, Geografía o Yo nunca siguen siendo válidos y se van con Nueva noche o al pasar 12 h. El enum `ConsequenceMode` no se renombra.

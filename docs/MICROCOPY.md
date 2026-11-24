# Paddock: microcopy con voz propia

Fecha: 2026-11-24. Rama `diseno-alma`. Origen: `docs/DISENO_ALMA.md`, sección (e), idea 1.
Solo propuesta: no se ha tocado `lib/`. Lo que no aparece en las tablas se queda como está.

## Voz de la casa

- Casa de apuestas de hipódromo de los años 30, de noche. Castellano de España, adulto y cómplice. Humor seco.
- Frases cortas. Botones de 1 a 3 palabras. Como mucho un signo de exclamación por pantalla, y nunca en cadena.
- Nada de "¡Genial!", "¡Ups!", "¡Vaya!" ni tono de asistente. La casa no se disculpa ni anima: constata.
- Sin emoji en los textos (los iconos los pone la zona de diseño). Donde había un emoji dentro de una cadena, se quita del texto nuevo.
- Nada de beber fuera del modo Sorbos (`test/no_alcohol_text_test.dart`). Nada de "previa", "ronda" en el sentido de copas, "brindis" ni similares.
- Longitud: cada texto nuevo cabe en ±20 % del actual, salvo donde se indica.

Columna "Test": si pone un archivo, ese test busca el texto literal y hay que actualizarlo en el mismo commit.

## Menú y registro

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `app/home_screen.dart:35` | Juegos para la previa | Se abre el paddock | Lema de la casa; además "previa" remite a beber | |
| `app/home_screen.dart:63` | Añade jugadores | Forma la cuadra | Cuadra = grupo de jugadores (glosario) | |
| `games/horse_race/horse_race_module.dart:18` | Apuesta por un palo y que gane el mejor caballo | Elige palo, suelta fichas y que corra tu caballo | Introduce "fichas" desde el menú | |
| `games/infiltrado/infiltrado_module.dart:19` | Todos saben la palabra menos uno | Todos saben la palabra. Uno, no | Más seco, mismo dato | |
| `games/trivia/trivia_module.dart:18` | Cultura general en 4 opciones | Cuatro opciones, una buena | Rima con "Dos opciones, ninguna buena" | |
| `games/abecedario/abecedario_module.dart:17` | Adivina la palabra de cada letra | Una palabra por letra, de la A a la Z | Más concreto (+16 %) | |
| `games/registry.dart:21` | Señala al más probable | Señalad sin piedad | Cómplice, plural de grupo | |
| `games/registry.dart:26` | A la de tres, todos señalan. El más señalado pierde una ficha | A la de tres, todos señalan. El más señalado paga una ficha | "Pagar" es el verbo de la casa | |
| `games/registry.dart:37` | A la de tres, todos eligen. La minoría pierde una ficha | A la de tres, todos eligen. Pagan los de la minoría: una ficha | Frase de la casa (+11 %) | |
| `games/registry.dart:49` | Quien lo haya hecho, pierde una ficha | Quien lo haya hecho, paga una ficha | Coherencia con "pagar" | |

Se mantienen: títulos de juego, "Dos opciones, ninguna buena", "Confiesa… o paga", "Banderas, capitales, siluetas y mapas", tooltip "Ajustes".

## Trivia y Geografía

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `games/trivia/ui/trivia_result_screen.dart:19` | ¡Perfecto! 🧠 | Pleno | Término de apuestas; sin emoji ni exclamación | |
| `games/trivia/ui/trivia_result_screen.dart:20` | ¡Gran nivel! | Gran carrera | Voz de hipódromo | |
| `games/trivia/ui/trivia_result_screen.dart:21` | Nada mal | Colocado | En apuestas, "colocado" es entrar en puestos de pago | |
| `games/trivia/ui/trivia_result_screen.dart:22` | A seguir practicando | Hoy no era tu carrera | Resultado con carácter, sin sermón | |
| `games/geography/ui/geo_result_screen.dart:25-28` | ¡Perfecto! 🌍 / ¡Gran nivel! / Nada mal / A seguir practicando | Pleno / Gran carrera / Colocado / Hoy no era tu carrera | Mismo criterio que Trivia | |
| `games/geography/ui/geo_result_screen.dart:45` | 🏆 ¡Nuevo récord! | Nuevo récord | El trofeo lo pone el icono; sobra la exclamación | |
| `games/trivia/ui/trivia_result_screen.dart:15` y `geo_result_screen.dart:19` | No hay ninguna partida | Aquí no hay partida | Más corto y natural | |
| `games/trivia/ui/trivia_result_screen.dart:59` | Otra partida | Otra vuelta | Un solo verbo para repetir en los juegos de preguntas | |
| `games/geography/ui/geo_result_screen.dart:76` | Otra vez | Otra vuelta | Igual | |
| `games/trivia/ui/trivia_result_screen.dart:66` | FALLADAS | FALLOS | Igual que Geografía | |
| `games/trivia/ui/trivia_result_screen.dart:79` | Respondiste: ${m.given} | Dijiste: ${m.given} | Igual que Geografía (`geo_result_screen.dart:144`) | |

Se mantienen: "Jugar · N preguntas", "1 / 10", "¿Salir de la partida?", "Seguir", "Salir", "Ver resultado", "Siguiente", "Ni idea", "Fallé", "Acerté", "Comprobar", "Cambiar ajustes", "Tu récord", "Sin respuesta", la línea de fuente de Open Trivia DB y todos los errores de carga.

## Infiltrado

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `games/infiltrado/ui/infiltrado_setup_screen.dart:112-114` | Todos reciben la misma palabra menos el infiltrado, que solo conoce la categoría. Debatid y votad: si lo pilláis, pierde 2 fichas; si se escapa, los demás pierden 1 cada uno. | Todos reciben la misma palabra salvo el infiltrado, que solo sabe la categoría. Debatid y votad: si lo pilláis, paga 2 fichas; si se escapa, los demás pagan 1 cada uno. | "Pagar"; mismas cifras | |
| `infiltrado_setup_screen.dart:94` | Cargando palabras… | Barajando palabras… | Voz de mesa | |
| `infiltrado_setup_screen.dart:122` | Añade jugadores para empezar. | Forma la cuadra para empezar. | Cuadra | |
| `infiltrado_setup_screen.dart:187` | ${n} palabras disponibles | ${n} palabras en el mazo | Voz de mesa | |
| `infiltrado_setup_screen.dart:196` | Volver a empezar con todas | Barajar todas de nuevo | Más corto; mismo efecto (recupera las usadas) | |
| `infiltrado_setup_screen.dart:206` | Sin temporizador | Sin reloj | Cabe mejor en el segmento | |
| `ui/infiltrado_reveal_screen.dart:150` | No conoces la palabra. Disimula y averigua cuál es. | No sabes la palabra. Escucha, disimula y adivínala. | Más directo | |
| `ui/infiltrado_reveal_screen.dart:171` | Da pistas sin decirla. Cuidado: el infiltrado escucha. | Da pistas sin decirla. El infiltrado tiene la oreja puesta. | Humor seco | |
| `ui/infiltrado_vote_screen.dart:207` | Pasar a votar | A votar | Botón de 2 palabras | |
| `ui/infiltrado_vote_screen.dart:226-227` | Cada uno da una pista sobre la palabra sin decirla. Descubrid quién no la conoce. | Una pista por cabeza, sin decir la palabra. Descubrid quién va de farol. | Mismo giro que la ayuda ("ir de farol") | |
| `ui/infiltrado_result_screen.dart:123` | No lo sé | Ni idea | Igual que Geografía | |
| `ui/infiltrado_result_screen.dart:137` | Que los demás no miren. | Los demás, mirad a otro lado. | Más vivo | |
| `ui/infiltrado_result_screen.dart:175` | Empate en la votación: nadie fue acusado. | Empate a votos: nadie se sienta en el banquillo. | Humor seco (+15 %) | |
| `ui/infiltrado_result_screen.dart:176` | Acusasteis a ${x}, pero era inocente. | Acusasteis a ${x}, pero pasaba por allí. | Humor seco | |
| `ui/infiltrado_result_screen.dart:178` | ${x} estaba pillado, pero adivinó la palabra y gana igualmente. | ${x} estaba cazado, pero adivinó la palabra y gana igualmente. | Variación; mismo resultado | |
| `ui/infiltrado_result_screen.dart:180` | Acusasteis a ${x} y era infiltrado. | Acusasteis a ${x} y era el infiltrado. Buen ojo. | Resultado con carácter | |
| `ui/infiltrado_widgets.dart:183` | No hay ninguna partida en curso. | Nadie está disimulando ahora mismo. | Vacío con gracia | `infiltrado_screens_test.dart` |
| `ui/infiltrado_widgets.dart:190` | Preparar una partida | Preparar partida | Botón más corto | |

Se mantienen (algunos fijados por test): "Elige al menos 3 jugadores", "Repartir roles", "Pasa el móvil a", "Eres el infiltrado", "LA PALABRA", "¡Empate!", "Última oportunidad", "¡Lo habéis pillado!", "¡Acertó la palabra!", "El infiltrado se escapa", "Fichas anotadas en la Copa de la noche.", "Otra ronda", "Ver la Copa", "Confirmar voto", "Voto secreto: pasa el móvil a".

## Carrera

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `games/horse_race/ui/race_setup_screen.dart:95` | Añade jugadores para apostar.\nEscribe un nombre abajo y toca «Añadir». | Sin jugadores no hay apuestas.\nEscribe un nombre abajo y toca «Añadir». | Vacío con gracia; misma instrucción | `race_chips_test.dart` (`textContaining('Añade jugadores para apostar.')`) |
| `race_setup_screen.dart:117` | Palo y fichas | Boletos | Cada fila es el boleto de un jugador | |
| `race_setup_screen.dart:185` | Elige quién apuesta | Haced vuestras apuestas | Frase de la casa. +21 %: el botón ocupa todo el ancho y cabe | `race_chips_test.dart` |
| `ui/race_result_screen.dart:159` | 🎉 Ganan | Cobran | Pareja natural de "Pagan"; el icono va aparte | |
| `ui/race_result_screen.dart:171` | chipsLine('Ganan', …) | chipsLine('Cobran', …) | Igual que la cabecera | `race_chips_test.dart` ("Ganan: Ana (+3)") |
| `ui/race_result_screen.dart:174` | 💸 Pagan | Pagan | Solo se quita el emoji del texto | |
| `ui/race_result_screen.dart:193` | Nadie acertó. ¡Todos pagan! | Nadie acertó. Pagan todos. | Seco, sin exclamación | `race_chips_test.dart` |
| `ui/race_result_screen.dart:319` | ${name} gana ${chipsText(n)} | ${name} cobra ${chipsText(n)} | Coherente con "Cobran" | `race_chips_test.dart` ("Ana gana 3 fichas") |
| `ui/race_result_screen.dart:93` | No hay ninguna carrera terminada | Aún no ha cruzado nadie la meta | Vacío con gracia | |
| `ui/race_stats_screen.dart:53` | Aún no hay carreras | Pista sin estrenar | Vacío con gracia | |
| `ui/race_screen.dart:745` | 🏆 ¡GANA! | ¡GANA! | Solo se quita el emoji; el trofeo es icono | |

Se mantienen: "Carrera de caballos", "¿Quién apuesta?", "¡A correr!", "Revancha", "Cambiar apuestas", "¿Quién paga?", "Toca el mazo", "Mazo agotado: se baraja de nuevo", "¡Obstáculo! X retrocede", "Acertar gana el doble", "Casillas hasta la meta", "Gira el móvil…", "Apostó X a Y y falló", "Le reparte un All-in X", todo `race_texts.dart` salvo lo indicado, "All-in · 10 fichas" y "En la Copa, cada All-in vale 10 fichas".

## Mazos, niveles y Abecedario

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `games/prompt_deck/prompt_deck_screens.dart:112` | Empezar · $count cartas | Jugar · $count cartas | Mismo patrón que "Jugar · N preguntas" y "Jugar · 27 letras" | |
| `prompt_deck_screens.dart:201-202` | Se pierde el punto por el que ibas en el mazo. Las fichas que ya has marcado se quedan en la Copa. | Pierdes el sitio en el mazo. Las fichas ya marcadas se quedan en la Copa. | Más corto, mismo aviso | |
| `prompt_deck_screens.dart:463` | Ya registrado en la Copa | Ya anotado en la Copa | Mismo verbo que el Infiltrado ("Fichas anotadas") | `prompt_deck_pay_test.dart` |
| `prompt_deck_screens.dart:726` | ¡Se acabaron las cartas! | Se acabó el mazo | Sin exclamación; voz de mesa | |
| `prompt_deck/level_chips.dart:89` | Puedes combinar varios niveles. | Se pueden mezclar niveles. | Más corto | |
| `games/abecedario/ui/abecedario_play_screen.dart:543` | ¡Abecedario completo! | Llegasteis a la Z | Resultado con carácter, sin exclamación | |
| `abecedario_play_screen.dart:563` | Otra vez | Otra vuelta | Igual que Trivia y Geografía | |

Se mantienen: diálogo +18 del nivel Atrevido (`level_chips.dart:24-36`, significado legal), "Suave / Picante / Atrevido", "NIVEL", "Elige al menos un nivel", "¿Quién paga? · 1 ficha", las cuatro pistas "Marca a…", "−1 en la Copa: …", "Toca o desliza para la siguiente", "Barajar otra vez", "— o —", "Jugar · 27 letras", "Desvelar ya", "Siguiente", "Terminar" y los textos de ajustes de Abecedario.

## Copa y Créditos

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `app/cup_screen.dart:42` | Cada ronda suma las fichas ganadas y resta las perdidas: va ganando quien más ha ganado o menos ha perdido. | Cada ronda suma las fichas ganadas y resta las perdidas. Manda quien más ha ganado o menos ha perdido. | Mismo cálculo, más seco | `cup_screen_test.dart` (`textContaining('va ganando quien más ha ganado')`) |
| `cup_screen.dart:66` y `:396` | Va ganando | Va en cabeza | Lenguaje de carrera; neutro en género | `cup_screen_test.dart` ("Va ganando: Luis") |
| `cup_screen.dart:70` y `:343` | El que más ha perdido | El que más ha pagado | "Pagar" es el verbo de la casa | `cup_screen_test.dart` |
| `cup_screen.dart:95` y `:100` | Jugador eliminado | Jugador retirado | Como un caballo retirado de la carrera | |
| `cup_screen.dart:147` | Es de hace más de 12 horas. Puedes empezar una noche nueva desde la Copa. | Lleva más de 12 horas abierta. Puedes empezar otra noche desde la Copa. | Más claro | |
| `cup_screen.dart:203` | Se borrará la clasificación y las estadísticas de esta noche. No se puede deshacer. | Se borran la clasificación y las estadísticas de esta noche. No hay vuelta atrás. | Mismo aviso, menos burocrático | |
| `cup_screen.dart:223` y `:371` | Compartir resultado | Compartir la Copa | Dice qué se comparte | |
| `cup_screen.dart:256` | Todavía no hay puntuaciones | Aún no ha corrido nadie | Vacío con gracia | `cup_screen_test.dart` |
| `cup_screen.dart:260` | Juega unas rondas y aquí aparecerá la clasificación de la noche. | Jugad unas rondas y aquí saldrá quién manda esta noche. | Plural de grupo, más corto | |

Se mantienen: "Copa de la noche", "Ver Copa", "Clasificación", "Por juego", "Líder", "Ganador", "Nueva noche", "¿Empezar una noche nueva?", "Cancelar", el texto que se comparte (salvo "Va ganando" y "El que más ha perdido", que deben coincidir con la pantalla) y **toda la pantalla de Créditos** (`app/credits_screen.dart`): atribuciones, licencias y "Juega con responsabilidad" no se tocan.

## Ajustes y bienvenida

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `app/settings_screen.dart:92` | Qué pasa cuando alguien pierde fichas | Cómo se pagan las fichas perdidas | Coincide con la ayuda de la Carrera ("El modo de Ajustes decide cómo se pagan") | |

Se mantienen a propósito:
- Bienvenida (`app/welcome_screen.dart`): "+18", "Juega con responsabilidad", "Nadie está obligado a beber", "Política de privacidad" y "Entendido". Es un aviso legal; "Entendido" es el acuse de recibo y no debe sonar a broma.
- Diálogo de Sorbos (`settings_screen.dart:34-43`): sin cambios. Es el aviso +18 y la frase "obligado a beber" ya está permitida por el test.
- "Puntos / Retos / Sorbos", "Consecuencias", "Sonido", "Música y efectos", "Vibración", "Soporte", "Créditos", "Versión", "No se pudo abrir el enlace".

## Jugadores y vacíos

| Archivo:línea | Texto actual | Texto nuevo | Motivo | Test |
|---|---|---|---|---|
| `core/players/players_screen.dart:62` | Jugadores | La cuadra | Coherente con "Forma la cuadra" del menú | |
| `players_screen.dart:72` | Añade a la gente con la que juegas.\nSe guardan para las próximas partidas. | Apunta a quien juega esta noche.\nLa cuadra se guarda para la próxima. | Vacío con gracia, mismo dato (se guardan) | |
| `players_screen.dart:38` | El nombre no puede estar vacío | Escribe un nombre | Igual que el campo de alta (`player_widgets.dart:62`) | |
| `players_screen.dart:40` y `core/players/player_widgets.dart:67` | Ya hay un jugador con ese nombre | Ese nombre ya está en la cuadra | Voz de la casa, misma longitud | `players_ui_test.dart` |
| `players_screen.dart:53` | ${p.name} eliminado | ${p.name} se retira | Neutro en género ("eliminado" era masculino) | |

Se mantienen: "Escribe un nombre", "Nombre del jugador", "Añadir", "Renombrar", "Guardar", "Cancelar", "Deshacer", "Eliminar", "1 jugador / N jugadores".

Resto de vacíos y errores ya cubiertos en sus zonas: Copa (`cup_screen.dart:256-260`), estadísticas de Carrera, resultado de Carrera, Infiltrado sin partida, Trivia y Geografía sin partida. Los errores de carga ("No se pudo cargar el contenido…") se quedan como están: en un error, claridad antes que gracia.

## Ayuda (`assets/content/es/ayuda.json`)

Solo cambia la entrada `carrera` (mismo esquema y mismos ids):
- Paso 4: "Si aciertas, repartes tus fichas; si fallas, las pierdes." pasa a "Si aciertas, cobras fichas; si fallas, pagas lo apostado." Lo anterior no coincidía con la pantalla de resultado ("Ana gana 3 fichas"); el reparto solo existe con All-in (paso 5).
- Consejo: citaba «Acertar reparte el doble», pero el interruptor se llama «Acertar gana el doble» (`race_setup_screen.dart:147`). Corregido.

## Glosario de la casa

| Término | Uso | No usar |
|---|---|---|
| **Ficha / fichas** | Unidad de todo lo que se gana o se pierde. "1 ficha", "3 fichas" | puntos (salvo el modo "Puntos" de Ajustes), créditos, monedas |
| **All-in** | Apuesta máxima. Vale **10 fichas** en la Copa. Plural invariable: "2 All-in" | "×2", all in, allin |
| **Pagar / pagan** | Perder fichas. "El más señalado paga una ficha", "Pagan los de la minoría" | "bebe", "le toca beber" (fuera del modo Sorbos) |
| **Cobrar / cobran** | Ganar fichas en la Carrera. "Ana cobra 3 fichas" | "reparte" cuando no hay All-in |
| **Repartir** | Solo para All-in y para roles del Infiltrado. "Reparte 2 All-in" | Para ganancias normales |
| **Anotar** | Registrar fichas en la Copa. "Ya anotado en la Copa" | registrar, guardar |
| **Copa de la noche** | Clasificación de toda la sesión. Siempre con mayúscula en "Copa" | ranking, marcador |
| **Nueva noche** | Reiniciar la Copa | reset, reiniciar |
| **Cuadra** | El grupo de jugadores guardado. "Forma la cuadra", "La cuadra" | equipo, plantilla |
| **Boleto** | La apuesta de un jugador en la Carrera (palo + fichas) | ticket |
| **Paddock** | La app y su arranque. "Se abre el paddock" | |
| **Haced vuestras apuestas** | Invitación a apostar antes de la carrera | "¡Apostad ya!" |
| **Colocado / Pleno / Gran carrera** | Escala de resultado en los juegos de preguntas: perfecto = Pleno; 80 % = Gran carrera; 50 % = Colocado; menos = Hoy no era tu carrera | "¡Genial!", "¡Perfecto!" |
| **Retirado / se retira** | Jugador borrado | eliminado (además es masculino) |
| **Otra vuelta** | Repetir en Trivia, Geografía y Abecedario. Carrera usa "Revancha"; Infiltrado, "Otra ronda" | Otra vez, Otra partida |
| **Jugar · N preguntas / cartas / letras** | Botón de inicio con recuento. Separador " · " | Empezar · |
| **1 / 10** | Progreso en preguntas, con espacios alrededor de la barra | 1/10, 1 de 10 (salvo "Jugador 1 de 4" y "Voto 1 de 4", que se leen en voz alta) |
| **Suave / Picante / Atrevido** | Niveles de los mazos y del Infiltrado | |
| **Puntos / Retos / Sorbos** | Modos de consecuencias. "Sorbos" es el único sitio donde se habla de beber, siempre con "o agua o reto" | |
| **Ni idea** | Rendirse en una pregunta | No lo sé |
| **Seguir / Salir** | Botones del diálogo "¿Salir de la partida?" en todos los juegos | |

Reglas de estilo para cualquier texto nuevo:
- Tuteo al jugador que tiene el móvil; vosotros cuando se habla al grupo ("Jugad", "Debatid").
- Nada de emoji dentro de cadenas de interfaz. Excepción: el texto que se comparte fuera de la app.
- Sin punto final en botones, chips ni títulos. Con punto en frases completas de ayuda o aviso.
- Avisos +18, privacidad, créditos y ayuda: se puede pulir el tono, nunca quitar información.

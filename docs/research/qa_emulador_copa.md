# QA manual en emulador: Copa, carrera, Infiltrado, Trivia y Geografía (2026-11-26)

Entorno: emulator-5554 (1080x2400), build debug de `es.jlopez0.paddock`, 4 jugadores (Ana, Luis, Marta, Pepe), +18 confirmado. La app arrancó en modo **Sorbos**, así que la primera carrera salió en Sorbos y las siguientes en Fichas (y una última en Sorbos con letra 2.0). No se editó código ni se reinstaló. `font_scale` restaurado a 1.0 (comprobado con `settings get`). Capturas en el scratchpad de la sesión (`s*.png`, ver rutas al final).

## Resumen

- **Bloqueantes: ninguno.** Sin crashes ni excepciones de Dart en `logcat -s flutter`.
- Lo que se pidió comprobar, resultado:
  - Podio de la Copa: solo top 3, sin cola, sin "el que más ha pagado", con la línea "Cuentan: Carrera de caballos y El Infiltrado". Correcto.
  - Modo Sorbos: no aparece "paga/pagan" en la pantalla de resultado; usa "Les toca" / "LE TOCA". Tope de 3 y "o agua o reto" visibles en cada sorbo. Correcto.
  - Compartir: sale solo top 3 sin cifras. Correcto.
  - Nueva noche: diálogo de confirmación y Copa vacía. Correcto.
  - Trivia y Geografía: ya no aparece "¿Quién ha jugado?". Correcto. Tampoco suman a la Copa.

## Importantes

### I1. El ganador de un All-in puede quedar fuera de la Copa si no reparte
Pasos: Sorbos, Ana y Marta con All-in a Oros y Espadas, ganar Espadas (Marta), pulsar "Ver Copa" sin elegir a quién reparte ("Reparte 2 All-in … (0/2)").
Resultado: Marta (la ganadora) no aparece en el podio. `_settle(force: true)` anota delta 0 para ella (los -10 de Ana no se le trasladan) y la Copa dice "Empate a -2 fichas · Luis y Pepe" en un podio con trofeo. La ganadora de la carrera ni sale, y el texto compartido lo repite ("Va en cabeza: Luis y Pepe").
Causa probable: `lib/games/horse_race/ui/race_result_screen.dart`, `_settle` / `_leave`.
Sugerencia: avisar antes de salir ("Aún no has repartido el All-in") o no dejar salir con All-in pendiente. Capturas: `s19.png`, `s22.png`, `s24.png`.

### I2. Letra grande (2.0): título cortado y "Espadas" partido
- Setup de la Carrera: título "Carrera de ca…" truncado; en el boleto, la etiqueta "Espadas" se parte en "Espad / as" y se corta por abajo; las letras de los avatares en las fichas de jugador (A, L, M, P) quedan recortadas. Captura: `s86.png`.
- Copa: título "Copa de la n…" truncado. Captura: `s93.png`.
- Resultado de la Carrera en Sorbos: el texto "2 sorbos · o agua o reto" queda en una columna estrecha junto al nombre ("Pepe" a la izquierda, texto en 3 líneas a la derecha) y se lee mal. Captura: `s91.png`.
Se entiende y no hay desborde rojo, pero la maquetación se rompe con letra grande.

### I3. Empate en el tercer puesto oculta a un jugador sin decirlo
Con Ana y Marta a -10, el podio muestra solo a Ana con "Empate" y a Marta no (top 3 estricto). Se ve "Empate" y falta la pareja. Captura: `s93.png`.
Sugerencia: "Empate con Marta" o mostrar a los empatados en 3.er puesto.

## Menores

- **M1. "Paga/Pagan" en modo Fichas.** Es el modo sin sorbos, así que es lo previsto, pero conviene confirmarlo con `habin:cumplimiento`: el resultado en Fichas dice "Pagan / PAGA" y el botón "¿Quién paga?" (`s40.png`, `s43.png`), y la ayuda del Infiltrado dice "paga 2 fichas… los demás pagan 1 cada uno" (`s47.png`). En Sorbos se dice "¿A quién le toca?" y "Les toca" (`s17.png`, `s19.png`).
- **M2. Texto duplicado en el resultado de la Carrera.** Debajo de cada cabecera hay una línea suelta que repite los boletos: "Cobran: Pepe (+2)", "Pagan: Ana (-10), Luis (-2)…", "Les toca: Ana (3 sorbos · o agua o reto), …". Parece texto de accesibilidad visible (`s31.png`, `s43.png`, `s20.png`).
- **M3. Boleto en Sorbos (letra 1.0).** "3 sorbos · o agua o reto" va centrado en una columna de unos 190 px entre el nombre y la carta, con salto raro ("3 sorbos · o / agua o reto") (`s20.png`).
- **M4. Copa con negativos.** "Empate a -2 fichas" con trofeo y confeti (`s22.png`); en Infiltrado "Líder: Ana, Luis y Pepe" con -1 cada uno (`s56.png`).
- **M5. Estado viejo tras "Nueva noche".** Al volver atrás desde la Copa vacía, el resultado del Infiltrado sigue mostrando "-1 en la Copa" y "Fichas anotadas en la Copa de la noche" aunque la Copa se borró (`s62.png`).
- **M6. Copa vacía.** "Aún no ha corrido nadie" tras jugar solo a otro juego: "corrido" solo vale para la Carrera (`s61.png`).
- **M7. Resultado de Trivia y Geografía** usa icono de bandera a cuadros y "Hoy no era tu carrera" (copy de la Carrera) (`s70.png`, `s80.png`).
- **M8. Home con letra 2.0.** La cabecera aguanta (subtítulo en dos líneas, sin desborde). La fila "4 jugadores" deja los avatares pegados al texto (`s83.png`). Los carteles crecen pero sin desborde (`s82.png`).
- **M9. Registro de Flutter.** Con letra 2.0, en el resultado de la Carrera: varios `E flutter: [ERROR:flutter/impeller/entity/contents/text_contents.cc(211)] Frame bounds are not present in the atlas` (validación de Impeller, build debug; el texto se pinta bien). Ninguna excepción de Dart ni "RenderFlex overflowed".
- **M10. Home sin insignia de trofeo** en Carrera e Infiltrado (`s2.png`, `s35.png`). Coherente con `ux_previa.md` (la insignia es de la fase 2), pero ojo si se esperaba ya.

## Lo que funciona (comprobado)

- Carrera: boletos, All-in (10 fichas), reparto de All-in, resultado, "Ver Copa", Revancha y Cambiar apuestas (las apuestas se conservan entre rondas). El avance rápido funciona.
- Fichas: "Cobran / Pagan", "-N en la Copa". Sorbos: tope 3 sorbos y "o agua o reto" en cada boleto y en el reparto del All-in ("hasta 3 sorbos cada uno · o agua o reto (0/2)").
- Copa tras 3 rondas: Luis -6, Pepe +2, Marta -20 en el podio; Ana (-30) fuera, sin cola; "Por juego" con rondas y líder; sin "el que más ha pagado".
- Compartir (hoja de Android): "Copa de la noche · Paddock (26/11/2026) / 1.º Luis y Pepe (empate) / 3.º Ana / Va en cabeza: Luis y Pepe". Solo top 3, sin cifras.
- Infiltrado: reparto de roles, tarjeta (categoría + palabra), voto secreto uno por uno, resultado ("El infiltrado se escapa", votos, -1 por jugador), Ver Copa, Otra ronda, Menú.
- Nueva noche: diálogo "¿Empezar una noche nueva?" con Cancelar / Nueva noche; tras confirmar, Copa vacía.
- Trivia (10 preguntas) y Geografía (Banderas, 10 preguntas): sin "¿Quién ha jugado?" ni sección de Copa; Geografía guarda récord ("Tu récord: 2/10").

## Capturas clave (scratchpad)

Ruta base: `C:\Users\javie\AppData\Local\Temp\claude\77e34b3e76a3fc0a\4ca5416b-a726-4ce6-8a2e-55688a5f8109\scratchpad\`
- `s19.png`, `s20.png`: resultado Carrera en Sorbos ("Les toca").
- `s22.png`, `s24.png`: Copa con All-in sin repartir (I1) y hoja de compartir.
- `s33.png`, `s45.png`, `s56.png`: Copa con 2 y 3 rondas y tras el Infiltrado.
- `s43.png`: resultado en Fichas ("Pagan").
- `s86.png`, `s91.png`, `s93.png`: letra 2.0 (I2).
- `s70.png`, `s80.png`: resultados de Trivia y Geografía.

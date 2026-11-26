# Auditoría de vocabulario por modo (Fichas / Retos / Sorbos) · 2026-11-26

Solo lectura. Código revisado: estado actual del árbol de trabajo (ya trae `textos_copa_c.md` aplicado en Yo nunca, ¿Quién es más probable?, Trivia/Geografía y "Pagan/Les toca"). Emulador: build anterior; solo se verificaron la Copa y el resultado de la Carrera en Sorbos (capturas en `%TEMP%\aud\s0.png` y `s1.png`). Carrera (setup/All-in), Infiltrado, mazos y modo Retos se auditaron solo por código: no se recorrieron en el emulador.

## Diagnóstico en una línea

La app resolvió el vocabulario en los textos de consecuencia (banner, "Les toca", titular de carta), pero la **unidad de cuenta** sigue siendo "ficha" en todo lo que rodea: apuesta de la Carrera, líneas "en la Copa", Copa, ayuda, estadísticas. Con Sorbos se ve en la misma pantalla "3 sorbos · o agua o reto" junto a "Apostó All-in … −10 en la Copa" y "Fichas anotadas…" (captura s1). Además el "Pagan" de Retos no cuadra con "Les toca".

## 1. Hallazgos de código (archivo:línea, alcance, propuesta)

### Importante

| # | Dónde | Texto actual | Modos | Propuesta |
|---|---|---|---|---|
| I1 | `race_setup_screen.dart:404-405,435,416,448,472,501` selector de apuesta y All-in | `1 ficha`, `fichas`, tooltips `Una ficha menos/más`, `All-in · 10 fichas` | Retos, Sorbos | Ver sección 3: la apuesta se elige en "puntos de apuesta" neutros o en la unidad del modo. Recomendado: Retos `1 reto`, Sorbos `1 sorbo` (tope 3), All-in sin cifra. Ver nota de tope. |
| I2 | `race_result_screen.dart:684` + `race_texts.dart:73` `cupLineFor` | `−10 en la Copa` bajo cada boleto | Retos, Sorbos | Quitar la línea en Retos y Sorbos (la Copa ya aparece al final). Es la incongruencia más visible de la captura s1 (3 sorbos y a la vez −10). |
| I3 | `race_result_screen.dart:276-280` y `infiltrado_result_screen.dart:338-342` | `Fichas anotadas en la Copa de la noche.` | Retos, Sorbos | `Anotado en la Copa de la noche.` (neutro; vale en los tres modos). |
| I4 | `race_result_screen.dart:509,165,173` | `Apostó 2 fichas a Bastos y falló`, `Apostó All-in a Oros y falló`, `Le reparte un All-in X` | Retos, Sorbos | Con apuesta en unidad del modo: `Apostó 2 sorbos a Bastos y falló` / `Apostó 2 retos…`. All-in se mantiene. |
| I5 | `race_result_screen.dart:219,241,475` `Cobran`, `cobra 3 fichas`, `chipsLine('Cobran', …, +n)` | Ganar fichas | Retos, Sorbos | En Retos y Sorbos quien acierta no bebe ni cumple: `Aciertan` / `Ana acierta` y la línea sin cifra en fichas (`Aciertan: Ana, Luis`). En Fichas se queda `Cobran`. |
| I6 | `race_texts.dart:42,48` `Pagan` y sello `PAGA` (`race_result_screen.dart:645`), `whoPaysLabel` `¿Quién paga?` (`race_texts.dart:69`), `nobodyWonText` `Pagan todos` (`:65`) | "Pagan/PAGA/¿Quién paga?" | Retos | Está permitido por el criterio actual, pero en Retos se lee a coste. Sugerido: Retos usa también `Les toca` / `LE TOCA` / `¿A quién le toca?`. Así "Pagan" queda solo en Fichas. |
| I7 | `infiltrado_setup_screen.dart:145` | Retos y Fichas: `si lo pilláis, paga 2 fichas; si se escapa, los demás pagan 1 cada uno.` | Retos | Retos: `si lo pilláis, le tocan 2 retos; si se escapa, 1 a cada uno de los demás.` Fichas: `pierde 2 fichas… pierden 1 cada uno` (ya no hay transferencia). |
| I8 | `ayuda.json:7,9,10,12` Carrera | `Apuesta de 1 a 5 fichas… el All-in, que vale 10`, `cobras lo apostado; si fallas, lo pierdes` | Retos, Sorbos | Redactar neutro: `Apuesta de 1 a 5 o ve a por todas con el All-in.` y `Si aciertas, ganas; si fallas, te toca lo que apostaste.` Quitar "vale 10" si se cambia I1. |
| I9 | `ayuda.json:22` Infiltrado | `pierde 2 fichas… los demás pierden 1` | Retos, Sorbos | `…le toca lo más duro del modo elegido; si se escapa, algo menos a los demás.` o remitir a "el modo elegido decide qué se juega" (ya usado en Carrera). |
| I10 | `ayuda.json:111` Copa | `Cada ronda suma o resta fichas.` | todos | Ver sección 3 (Copa): se mantiene "fichas" como unidad del marcador, pero explicarlo una vez como "puntos de la noche". |
| I11 | `cup_screen.dart:38,54,532,748` y captura s0: `+2 fichas`, `-10 fichas`, `Manda quien acaba con más fichas`, `Empate a +3 fichas`, label semántico `…, N fichas` | Todos | En Sorbos y Retos la Copa habla de fichas mientras todo lo demás habla de sorbos/retos. Ver sección 3: se mantiene la unidad pero se **presenta como marcador de la Copa**, nunca como lo que se bebe/cumple. |

### Menor

| # | Dónde | Texto actual | Propuesta |
|---|---|---|---|
| M1 | `race_stats_screen.dart:186,192` | `fichas perdidas` / `fichas ganadas` | Es estadística de la Copa/Carrera: dejar `fichas` o pasar a `perdidas` / `ganadas` sin unidad. Alcanzable en todos los modos. |
| M2 | `horse_race_module.dart:18` | `Elige palo, suelta fichas y que corra tu caballo` (visible en la home) | `Elige palo, haz tu apuesta y que corra tu caballo` (neutro en los tres modos). |
| M3 | `race_texts.dart:29` `allInCupNote` | `En la Copa, cada All-in vale 10 fichas` | Mantener solo si se mantiene la cifra; en Retos y Sorbos ocultarla (alcanzable en el boleto ganador de All-in). |
| M4 | `race_texts.dart:20-25` `allInShareText` | Fichas: `Reparte 2 All-in a 2 personas distintas`; Retos: `Reparte un reto a …` (incoherente: dice "un reto" pero reparte N All-in); Sorbos: `Reparte 2 All-in · hasta 3 sorbos cada uno · o agua o reto` | Retos: `Reparte 2 All-in · 1 reto a cada uno`. Fichas y Sorbos están bien. |
| M5 | `consequence_banner.dart:47` `inCup=false` en Fichas | `−1 ficha` | Correcto en Fichas; no es alcanzable en otros modos. Nada que cambiar. |
| M6 | `que_preferirias.json:43` | opción `Perder tres fichas` | Contenido de la carta (nivel atrevido). Mantener o cambiar a `Perder tres puntos`; es una opción de broma, no una consecuencia. Decisión de contenido. |
| M7 | `credits_screen.dart:161,187` | `Sonidos de mesa (fichas…)`, `mascota, fichas y medallas` | Son objetos dibujados, no unidad de juego. Sin cambios. |
| M8 | `app_icons.dart:351` semántica `Ficha de $value` | Etiqueta de accesibilidad de la ficha dibujada | Aparece en el selector de apuesta y los boletos. Si cambia I1, hacer que la etiqueta use la unidad del modo (`Apuesta de 2`). |
| M9 | `ayuda.json:12` consejo `Activa «Acertar gana el doble»…` y `race_setup_screen.dart:172` `Acertar gana el doble` | Habla de ganar, nada de fichas | En Sorbos/Retos "gana el doble" = que la apuesta cuenta doble para la Copa. Aclarar o mostrar solo en Fichas. |
| M10 | `race_screen.dart:874` `¡GANA!` (caballo ganador) | Es el caballo, no un jugador. Correcto en todos los modos. |

### Ya correcto (verificado en código)
Selector y descripciones de modo (`consequence_mode_selector.dart`), `ConsequenceBanner` (`1 reto`, `1 sorbo · o agua o reto`, tope 3), titulares de carta `stakeHeadline`, Yo nunca/¿Quién es más probable? (registro y ayuda; `pasosLite` sin Sorbos), Trivia/Geografía (sin "¿Quién ha jugado?", ayuda "Aquí no se apuntan fichas"), `Les toca`/`LE TOCA`/`¿A quién le toca?` en Sorbos, ayuda Carrera paso 4 "El modo elegido decide qué se juega". No quedan "paga/pagan" en Sorbos fuera del código muerto de `race_result_screen.dart:587` (doc comment).

## 2. Capturas del emulador (build anterior, Sorbos +18)

- `s0.png` Copa de la noche: `+2 fichas`, `-2 fichas`, `-10 fichas`, `Manda quien acaba con más fichas`, `Cuentan: Carrera de caballos y El Infiltrado`, sección `Por juego` aún visible (el mensaje `textos_copa_c` pedía solo podio). En Sorbos la Copa habla de fichas: I11.
- `s1.png` Resultado de Carrera en Sorbos: cabecera `Les toca` y sellos `LE TOCA` correctos, pero cada boleto trae `Apostó All-in a Oros y falló`, `Apostó 2 fichas a Bastos y falló`, `-10 en la Copa`, `-2 en la Copa` y debajo `Fichas anotadas en la Copa de la noche.` (I2, I3, I4). Además "Ana 3 sorbos" con All-in de 10 fichas: el jugador ve 3 sorbos pero la ficha del boleto dice 10 y la Copa dice -10.
- No recorrido por falta de tiempo/de estabilidad: setup de Carrera, All-in, Infiltrado, mazos, Trivia/Geografía, modo Retos y compartir. Para esos, ver tabla de código.

## 3. Criterio propuesto

### Principio
Hay dos capas y no deben mezclarse:
1. **Lo que se juega en la vida real** (consecuencia): `reto(s)` o `sorbo(s) · o agua o reto`. Solo en Retos/Sorbos. Lo ven banners, boletos y titulares.
2. **El marcador de la Copa**: se mantiene en **fichas** (D4, D13; `session.v1` no cambia). La Copa es un marcador interno de la app, no una consecuencia: no se traduce a sorbos (sería un ranking de beber, riesgo ya anotado en D14). Pero se enuncia como marcador, no como "lo que pagas".

Regla práctica: la palabra "ficha(s)" solo aparece (a) en modo Fichas en todo, (b) en la Copa y su ayuda/compartir, (c) en Estadísticas. Fuera de eso, en Retos y Sorbos, nunca junto a una consecuencia. El apuesta de la Carrera y sus boletos usan **la unidad del modo**.

### Carrera: apuesta en Retos y Sorbos
- Recomendado (coste bajo): mantener el selector de 1 a 5 como valor interno pero **mostrarlo con la unidad del modo y el tope visible**: en Retos `1 reto … 3 retos` (el 4 y el 5 muestran `3 retos`, o limitar el rango a 1-3 en Retos y Sorbos); en Sorbos `1 sorbo … 3 sorbos · o agua o reto`. El All-in se muestra solo como `All-in` (sin "10 fichas"). Los 10 puntos del All-in quedan como dato de la Copa.
- Alternativa más fiel a D4: dejar "fichas" en el selector (es la apuesta de la Copa) y quitar solo las líneas `en la Copa` y los `Apostó N fichas` del resultado. Menos limpia: el jugador apuesta fichas y paga sorbos sin ver la conversión.
- Decisión que necesita Javier: rango 1-3 en Retos/Sorbos (más honesto: lo apostado es lo que pierdes) o 1-5 con tope 3 al pagar (actual; el jugador pierde "5" y paga "3").

### Tabla modo × pantalla

| Pantalla | Fichas | Retos | Sorbos |
|---|---|---|---|
| Selector (Ajustes/home) | `Se juega por honor…` (sin cambio) | sin cambio | sin cambio (`Hasta 3 por ronda · o agua o reto`) |
| Carrera, apuesta | `2 fichas`, `All-in · 10 fichas` | `2 retos`, `All-in` | `2 sorbos · o agua o reto`, `All-in` |
| Carrera, tooltips `Una ficha menos/más` | igual | `Un reto menos/más` | `Un sorbo menos/más` |
| Carrera, caballo ganador | `¡GANA!` (sin cambio) | igual | igual |
| Carrera, botón tras carrera | `¿Quién paga?` | `¿A quién le toca?` | `¿A quién le toca?` |
| Carrera, cabecera de quien acierta | `Cobran` | `Aciertan` | `Aciertan` |
| Carrera, boleto ganador | `Ana cobra 3 fichas` | `Ana acierta` | `Ana acierta` |
| Carrera, cabecera de quien falla | `Pagan` | `Les toca` | `Les toca` |
| Carrera, sello | `PAGA` | `LE TOCA` | `LE TOCA` |
| Carrera, motivo | `Apostó 2 fichas a Bastos y falló` | `Apostó 2 retos a Bastos y falló` | `Apostó 2 sorbos a Bastos y falló` |
| Carrera, línea Copa por boleto | (nada; ya dice `−2`) | (quitar) | (quitar) |
| Carrera, nadie acierta | `Nadie acertó. Pagan todos.` | `Nadie acertó. Les toca a todos.` | `Nadie acertó. Les toca a todos · o agua o reto.` |
| Carrera/Infiltrado, nota inferior | `Fichas anotadas en la Copa de la noche.` | `Anotado en la Copa de la noche.` | `Anotado en la Copa de la noche.` |
| Infiltrado, setup | `…si lo pilláis, pierde 2 fichas; si se escapa, los demás pierden 1 cada uno.` | `…le tocan 2 retos; si se escapa, 1 a cada uno de los demás.` | `…le tocan 2 sorbos; si se escapa, 1 a cada uno de los demás. Siempre o agua o reto.` (ya hecho) |
| Infiltrado, resultado (banner) | `−2 en la Copa` | `2 retos` + reto | `2 sorbos · o agua o reto` (ya hecho) |
| Copa, marcador | `+2 fichas` | `+2 fichas` | `+2 fichas` |
| Copa, `_howItWorks` | `Aquí cuentan las apuestas y los votos. Manda quien acaba con más fichas.` | igual | igual |
| Copa, compartir | solo podio sin cifras (ya) | igual | igual |
| Copa, sección `Por juego` | quitar si solo hay dos juegos (opción C) | igual | igual |
| Ayuda Carrera | paso 2 con fichas | `Apuesta de 1 a 5 o ve a por todas con el All-in.` | igual (neutro) |
| Ayuda Infiltrado | `pierde 2 fichas` | `El modo elegido decide qué os toca.` | igual |
| Ayuda Copa | `Cada ronda suma o resta fichas. Manda quien acaba con más.` | igual | igual |
| Estadísticas Carrera | `fichas perdidas/ganadas` | igual | igual (es un histórico de la Copa) |

### Restricciones comprobadas
- Sorbos solo con `adultConfirmed` y tope 3: se respeta; las propuestas siguen usando `resolveLoss` y `· o agua o reto`.
- Sin "paga/pagan" en Sorbos: se mantiene. Propuesta adicional: tampoco en Retos.
- Ningún texto propuesto usa "beb…", "trago", "borrach…", "alcohol" (guardia `no_alcohol_text_test.dart`); `sorbo` está permitido. Fuera de `lib/core/consequences/` y las excepciones ya vigentes (`consequence_mode_selector.dart`, `welcome_screen.dart`, `credits_screen.dart`) no se añade ninguna.
- Los cambios de `race_texts.dart` y de los mensajes de pantalla no tocan `session.v1`: los puntos (10 por All-in) siguen yendo a la Copa.

### Tests a actualizar
`race_chips_test.dart` (`Cobran`, `fichas`, `Apostó N fichas`, `Pagan todos`), `cup_screen_test.dart` (si se retira `Por juego`), los tests de `race_texts` y de ayuda que citan "fichas", más `no_alcohol_text_test.dart` si se añade texto con "sorbo" fuera de las excepciones (no debería).

## Prioridad de ejecución

1. I2 + I3 (quitar `−N en la Copa` y `Fichas anotadas…` en Retos y Sorbos): 10 minutos, quita lo más visible.
2. I1 + I4 + I5 + I6 (apuesta y resultado de la Carrera con la unidad del modo): decidir primero el rango 1-3 vs 1-5.
3. I7 + I8 + I9 (Infiltrado y ayuda).
4. Menores M1-M9.

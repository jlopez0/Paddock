# Textos finales de vocabulario por modo · 2026-11-26

Estado: **cerrado por `redactor-es`**, listo para pegar. Origen: `auditoria_sorbos.md`, `textos_copa_c.md`, `MICROCOPY.md`, D14, D15 y D17. Líneas comprobadas contra el árbol actual (algunas no coinciden con la auditoría).

Reglas que cumplen todos:
- Dos capas: la consecuencia va en la unidad del modo (`reto(s)` o `sorbo(s) · o agua o reto`); la Copa sigue en fichas. Fuera de la Copa, "ficha(s)" solo en modo Fichas.
- Sin "paga/pagan/PAGA" en Retos ni en Sorbos: `Les toca`. "Pagar" y "Cobrar" quedan solo en Fichas.
- Sin "beb…", "trago" ni "alcohol" fuera de `lib/core/consequences/`. Tope 3 por ronda. En Sorbos, `o agua o reto` siempre visible. Sin rankings de consumo ni emoji.
- Botones, sellos y títulos sin punto final; frases completas con punto.

Supuesto de rango: en Retos y Sorbos la apuesta va de **1 a 3** (lo que apuestas es lo que te toca). Si Javier mantiene 1-5, el 4 y el 5 se muestran como `3 retos` / `3 sorbos` (el tope) y nada más cambia.

## 1. Carrera de caballos

### Preparación (`race_setup_screen.dart`)

| Archivo:línea | Fichas | Retos | Sorbos |
|---|---|---|---|
| `race_setup_screen.dart:172` interruptor, título | `Acertar gana el doble` | `Acertar gana el doble` | `Acertar gana el doble` |
| `race_setup_screen.dart:172` interruptor, subtítulo (nuevo) | `Quien acierta suma el doble en la Copa` | igual | igual |
| `race_setup_screen.dart:409-411` etiqueta accesible del selector | `1 ficha` / `$n fichas` / `All-in, 10 fichas` | `1 reto` / `$n retos` / `All-in, 3 retos` | `1 sorbo` / `$n sorbos` / `All-in, 3 sorbos, o agua o reto` |
| `race_setup_screen.dart:422` tooltip | `Bajar apuesta` | `Bajar apuesta` | `Bajar apuesta` |
| `race_setup_screen.dart:454` tooltip | `Subir apuesta` | `Subir apuesta` | `Subir apuesta` |
| `race_setup_screen.dart:441` rótulo bajo la ficha | `ficha` / `fichas` | `reto` / `retos` | `sorbo` / `sorbos` |
| `race_setup_screen.dart:478` etiqueta accesible del All-in | `All-in, 10 fichas` | `All-in, 3 retos` | `All-in, 3 sorbos, o agua o reto` |
| `race_setup_screen.dart:507` botón All-in | `All-in  ·  10 fichas` | `All-in  ·  3 retos` | `All-in  ·  3 sorbos` |
| Línea nueva bajo la cabecera `Boletos` (solo Sorbos) | (nada) | (nada) | `Hasta 3 por ronda · o agua o reto` |

Notas:
- Los tooltips pasan a `Bajar apuesta` / `Subir apuesta` en los tres modos: "Un sorbo más" fuera de contexto suena a invitar a beber.
- El All-in en Retos y Sorbos vale 3 porque `resolveLoss` recorta los 10 de la Copa al tope.

### Resultado (`race_result_screen.dart`, `race_texts.dart`, `race_widgets.dart`)

| Archivo:línea | Fichas | Retos | Sorbos |
|---|---|---|---|
| `race_texts.dart:69` `whoPaysLabel` (botón) | `¿Quién paga?` | `¿A quién le toca?` | `¿A quién le toca?` |
| `race_result_screen.dart:211` cabecera de quien acierta | `Cobran` | `Aciertan` | `Aciertan` |
| `race_result_screen.dart:455` título del boleto ganador | `$nombre cobra 3 fichas` | `$nombre acierta` | `$nombre acierta` |
| `race_result_screen.dart:454` ganador con All-in | `$nombre reparte 2 All-in` | igual | igual |
| `race_widgets.dart:97` sello del ganador | `COBRA` | `ACIERTA` | `ACIERTA` |
| `race_result_screen.dart:489` motivo del ganador | `Apostó 3 fichas a Oros` | `Apostó a Oros` | `Apostó a Oros` |
| `race_result_screen.dart:489` ganador con All-in | `Apostó All-in a Oros` | igual | igual |
| `race_texts.dart:42` `losersTitle` | `Pagan` | `Les toca` | `Les toca` |
| `race_texts.dart:48` `losersLine` | `Pagan: Ana (−2)` | `Les toca: Ana (2 retos)` | `Les toca: Ana (2 sorbos · o agua o reto)` |
| `race_widgets.dart:101` / `race_result_screen.dart:625` sello de quien falla | `PAGA` | `LE TOCA` | `LE TOCA` |
| `race_result_screen.dart:165` motivo de quien falla | `Apostó 2 fichas a Bastos y falló` | `Apostó a Bastos y falló` | `Apostó a Bastos y falló` |
| `race_result_screen.dart:165` falla con All-in | `Apostó All-in a Bastos y falló` | igual | igual |
| `race_result_screen.dart:173` le reparten un All-in | `$nombre le reparte un All-in` | igual | igual |
| `race_texts.dart:73` `cupLineFor` | (nada; ya dice `−2`) | (nada) | (nada) |
| `race_texts.dart:20-24` `allInShareText` | `Reparte 2 All-in a 2 personas distintas` | `Reparte 2 All-in · hasta 3 retos cada uno` | `Reparte 2 All-in · hasta 3 sorbos cada uno · o agua o reto` (sin cambios) |
| `race_texts.dart:29` `allInCupNote` | `En la Copa, cada All-in vale 10 fichas` | (nada) | (nada) |
| `race_texts.dart:63-65` `nobodyWonText` | `Nadie acertó. Pagan todos.` | `Nadie acertó. Les toca a todos.` | `Nadie acertó. Les toca a todos · o agua o reto.` (sin cambios) |
| `race_result_screen.dart:257` nota encima de `Ver Copa` | `Fichas anotadas en la Copa de la noche.` | `Ya cuenta en la Copa de la noche.` | `Ya cuenta en la Copa de la noche.` |

Notas:
- El motivo de quien falla ya no repite la cantidad: va al lado del nombre (`2 sorbos · o agua o reto`). Así no se lee "apostó 5" junto a "3 sorbos" ni "apostar sorbos".
- `Le reparte un All-in Ana` tenía el sujeto al final; ahora es `Ana le reparte un All-in`.
- Ojo de diseño (no es texto): la ficha dibujada del All-in pinta "10" al lado de `3 sorbos`. En Retos y Sorbos convendría dibujarla sin cifra.

### Accesibilidad y home

| Archivo:línea | Fichas | Retos | Sorbos |
|---|---|---|---|
| `app_icons.dart:351` `ChipToken` (solo la usa la Carrera) | `Apuesta de $value` | igual | igual |
| `horse_race_module.dart:18` subtítulo en la home | `Elige palo, apuesta y que corra tu caballo` | igual | igual |

### Estadísticas (`race_stats_screen.dart`)

| Archivo:línea | Todos los modos |
|---|---|
| `race_stats_screen.dart:186` | `en contra` |
| `race_stats_screen.dart:192` | `a favor` |

Neutro en los tres modos: no suena a "lo que has perdido bebiendo".

## 2. El Infiltrado

| Archivo:línea | Fichas | Retos | Sorbos |
|---|---|---|---|
| `infiltrado_setup_screen.dart:145` (cola de la frase) | `si lo pilláis, paga 2 fichas; si se escapa, los demás pagan 1 cada uno.` (sin cambios) | `si lo pilláis, le tocan 2 retos; si se escapa, 1 reto a cada uno de los demás.` | `si lo pilláis, le tocan 2 sorbos; si se escapa, 1 a cada uno de los demás. Siempre o agua o reto.` (sin cambios) |
| `infiltrado_result_screen.dart:339` nota encima de `Ver Copa` | `Fichas anotadas en la Copa de la noche.` | `Ya cuenta en la Copa de la noche.` | `Ya cuenta en la Copa de la noche.` |

## 3. Copa de la noche (en fichas en los tres modos)

| Archivo:línea | Texto final | Veredicto |
|---|---|---|
| `cup_screen.dart:51` en curso | `Nadie va en positivo` | Validado |
| `cup_screen.dart:51` noche cerrada | `Nadie ha acabado en positivo` | Validado |
| `cup_screen.dart:535` líder con 0 fichas | `Sin perder nada: $nombres` | Nuevo: con 0 nadie ha perdido |
| `cup_screen.dart:535` líder en negativo, una persona | `Quien menos ha perdido: $nombre` | Ajustado: "Los que" no casa con un solo nombre y es masculino |
| `cup_screen.dart:535` líder en negativo, empate | `Quienes menos han perdido: $nombres` | Ajustado: neutro en género |
| `cup_screen.dart:208` Copa vacía | `Aún no hay rondas que cuenten` | Validado |
| `cup_screen.dart:363` `Por juego`, líder sin fichas a favor | `Nadie en positivo` | Validado |
| `cup_screen.dart:54` `_howItWorks` | `Aquí cuentan las apuestas y los votos. Manda quien acaba con más fichas.` | Sin cambios |
| `cup_screen.dart:532` empate en positivo | `Empate a +3 fichas` | Sin cambios |

El texto compartido usa la misma frase neutra que la pantalla: `Nadie va en positivo` o `Nadie ha acabado en positivo`, sin cifras.

## 4. Ayuda (`assets/content/es/ayuda.json`)

Sin "sorbo": `content_test` lo veta en el JSON. Mismo esquema; solo cambian estas líneas.

Carrera, línea 7:
```json
      "Haz tu apuesta o ve a por todas con el All-in.",
```

Carrera, línea 9:
```json
      "Si aciertas, sumas en la Copa; si fallas, te toca lo que apostaste. El modo elegido decide qué se juega.",
```

Carrera, línea 10:
```json
      "¿Aciertas con All-in? Repartes hasta 2 All-in, cada uno a una persona distinta."
```

Carrera, línea 12:
```json
    "consejo": "Activa «Acertar gana el doble» y quien acierte sumará el doble en la Copa."
```

Infiltrado, línea 22:
```json
      "Si pilláis al infiltrado, le tocan 2 salvo que adivine la palabra. Si se escapa, le toca 1 a cada uno de los demás. El modo elegido decide qué se juega."
```

Copa, línea 111:
```json
      "La Copa cuenta en fichas, sea cual sea el modo: cada ronda suma o resta. Manda quien acaba con más.",
```

La línea 7 no da cifras para que valga con 1-5 en Fichas y 1-3 en Retos y Sorbos.

## 5. Contenido (`assets/content/es/que_preferirias.json`)

La carta está en la línea **46** (id `qp043`), no en la 43.

| Archivo:línea | Antes | Ahora |
|---|---|---|
| `que_preferirias.json:46` `qp043`, opción `b` | `Perder tres fichas` | `Confesar a quién de aquí besarías` |

Motivo: "fichas" no significa nada en Retos ni en Sorbos, y Qué preferirías no apunta nada. La opción nueva hace pareja con la `a` ("Besar a alguien de este grupo") y sigue en el nivel atrevido, sin contenido explícito.

## Tests que tocan estos textos
`race_chips_test.dart` (`Cobran`, `cobra N fichas`, `Apostó N fichas`, `Pagan todos`, tooltips), `cup_screen_test.dart` (`Los que menos han perdido`), los tests de `race_texts` y de ayuda que citan "fichas" o "cobras", y `content_test.dart` (repasar `qp043` y `ayuda.json`).

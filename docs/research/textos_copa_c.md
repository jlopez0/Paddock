# Textos de la opción C (Copa sin escaparate) · 2026-11-26

Estado: **propuesta de `redactor-es`, pendiente de OK de Javier**. Origen: `validacion_copa.md` (C), `ux_previa.md` (cambios 1-5 y 7), `cumplimiento_copa.md` (riesgos 3 y 5, redacción que hay que evitar). Sin tocar código.

Reglas que siguen todos los textos:
- "Sorbos" es el único modo que habla de beber, y siempre con `o agua o reto`. Tope de 3 por ronda.
- Ninguna cadena de `lib/` fuera de `lib/core/consequences/` ni de `ayuda.json` lleva "beb…", "trago" ni "borrach…" (`no_alcohol_text_test.dart`). "Sorbo" no está vetado, pero tampoco se usa como verbo.
- En Sorbos no se dice "pagar", "fichas" ni nada en cabeza o a la cola. Nada de fondo, chupito, sin límite, €, cuota ni emoji.
- Botones y títulos sin punto final. Frases completas con punto.

Separador: ` · ` (punto medio con espacios), como en el resto de la app.

## 1. Modo de consecuencias

Etiqueta del selector (Ajustes y, si se hace, la home). Antes: `Cómo se pagan las fichas perdidas`.

| Clave | Texto |
|---|---|
| Título del selector | `Qué hay en juego` |
| Etiqueta `puntos` (antes `Puntos`; el enum no se toca) | `Fichas` |
| Etiqueta `retos` | `Retos` |
| Etiqueta `sorbos` | `Sorbos` |

Descripción corta (una línea, debajo del selector, cambia según el modo):

| Modo | Texto |
|---|---|
| Fichas | `Se juega por honor. Nadie cumple nada fuera de la app.` |
| Retos | `Lo que pierdes se cumple con retos. Hasta 3 por ronda.` |
| Sorbos | `Opcional y solo +18. Hasta 3 por ronda · o agua o reto.` |

Notas:
- En la home, con el riesgo 1 de `cumplimiento_copa.md`, solo `Fichas` y `Retos` (o `Sorbos` solo tras `adultConfirmed`). Los textos valen igual.
- El diálogo +18 de Sorbos no cambia.

## 2. Yo nunca: banner fijo

Ya no se marca a nadie. El banner usa `ConsequenceBanner.amountText` con quién = `Quien lo haya hecho` y cantidad 1.

| Modo | Texto en pantalla |
|---|---|
| Fichas | (nada) |
| Retos | `Quien lo haya hecho` · `1 reto` (+ el reto de la lista, como hoy) |
| Sorbos | `Quien lo haya hecho` · `1 sorbo · o agua o reto` |

Cadena lista: `static const who = 'Quien lo haya hecho';`

Textos de Yo nunca que dejan de tener sentido y su sustituto:

| Dónde | Antes | Ahora |
|---|---|---|
| `registry.dart:45` (regla) | `Quien lo haya hecho, paga una ficha` | `Quien lo haya hecho, que lo confiese` |
| `registry.dart:40` (subtítulo) | `Confiesa… o paga` | `Aquí se confiesa todo` |
| `prompt_deck_screens.dart:531` | `¿Quién paga? · 1 ficha` | (se quita: no hay chips) |
| `prompt_deck_screens.dart:230-231` | `Pierdes el sitio en la partida. Las fichas ya marcadas se quedan en la Copa.` | `Pierdes el sitio en la partida.` (la variante corta, siempre) |

El subtítulo cambia porque en Sorbos "paga" se lee "bebe" y en Fichas ya no se paga nada.

## 3. Apuesta de la carta (¿Quién es más probable?)

En Fichas no se ve (cambio 2). En Retos y Sorbos se traduce, con el tope de 3 ya aplicado (`resolveLoss`).

Titular sobre la pregunta:

| Modo | n = 1 | n = 2 o 3 |
|---|---|---|
| Fichas | (nada) | (nada) |
| Retos | `¡Por 1 reto!` | `¡Por $n retos!` |
| Sorbos | `Por 1 sorbo · o agua o reto` | `Por $n sorbos · o agua o reto` |

En Sorbos no hay exclamación: no se anima a beber, se dice lo que hay.

Banner (`_StakeSection`, sin cambios de lógica): quién = `El más señalado`; cantidad la de `amountText` (`2 retos` / `2 sorbos · o agua o reto`).

Regla del registro (`registry.dart:25`), que es igual en todos los modos:
- Antes: `A la de tres, todos señalan. El más señalado paga la apuesta de la carta`
- Ahora: `A la de tres, todos señalan. Al más señalado le toca lo que diga la carta`

## 4. Copa de la noche

### Cabecera (solo podio)

| Dónde | Texto |
|---|---|
| Título | `Copa de la noche` (sin cambios) |
| Cómo funciona (`_howItWorks`) | `Aquí cuentan las apuestas y los votos. Manda quien acaba con más fichas.` |
| Línea de fuentes (solo dentro de la Copa, generada desde el registro) | `Cuentan: Carrera de caballos y El Infiltrado` |
| Líder | `Va en cabeza: $nombres` / al cerrar la noche `Ganador: $nombres` (sin cambios) |
| Título de la sección de podio | `Podio` |
| Sección `El que más ha pagado` | (se quita, en pantalla y al compartir) |
| Vacío, título | `Aún no ha corrido nadie` (sin cambios) |
| Vacío, texto | `Jugad a la Carrera o a El Infiltrado y aquí saldrá quién manda.` |

Cadena lista para la línea de fuentes: `'Cuentan: ${joinNames(cupGames.map((g) => g.title).toList())}'` (con `joinNames` sale "A y B").

Ojo: la opción C de `validacion_copa.md` dice "sin línea Cuentan". Aquí va solo dentro de la Copa, como pide el encargo, nunca en la home ni en los carteles. Que lo confirme Javier.

### Texto de compartir

Solo el podio (como mucho 3 puestos), sin cifras: así no salen saldos negativos ni nadie a la cola.

```
Copa de la noche · Paddock (26/11/2026)
1.º Luis
2.º Ana y Marta (empate)

Va en cabeza: Luis
```

Plantilla por línea: `'${ordinal(g.rank)} $names${g.isTie ? ' (empate)' : ''}'`, solo para `g.rank <= 3`. Se quitan `El que más ha pagado: …` y el bloque `Por juego:` (con dos juegos no aporta y alarga el mensaje). Al cerrar la noche, `Ganador:` en lugar de `Va en cabeza:`.

### Al cerrar Carrera o Infiltrado

| Dónde | Texto |
|---|---|
| Botón (Carrera e Infiltrado) | `Ver Copa` (el Infiltrado decía `Ver la Copa`: se unifica) |
| Línea encima del botón | `Fichas anotadas en la Copa de la noche.` (sin cambios) |

## 5. Trivia y Geografía (sin fichas)

Se va todo el bloque "¿Quién ha jugado?" y la anotación. El titular se queda, con una línea debajo opcional:

| Resultado | Titular | Línea debajo (opcional) |
|---|---|---|
| Todas bien | `Pleno` | `Ni un tropiezo.` |
| 80 % o más | `Gran carrera` | `Casi sin tocar valla.` |
| 50 % o más | `En el podio` | `Media pista bien corrida.` |
| Menos | `Hoy no era tu carrera` | `Otra vuelta y se arregla.` |

### Ayuda (`assets/content/es/ayuda.json`, mismo esquema)

Trivia, paso 5 se quita y el 4 queda así:
```json
"Al final verás tu titular, de Pleno a «Hoy no era tu carrera», y la respuesta buena de cada fallo. Aquí no se apuntan fichas."
```

Geografía, paso 5 se quita y el 4 queda así:
```json
"Al terminar verás tu titular, tus fallos y si has batido tu récord. Aquí no se apuntan fichas."
```

Yo nunca, pasos 3 y 4:
```json
"Quien lo haya hecho, lo confiesa. La app no apunta a nadie.",
"Con Retos o Sorbos, la carta dice lo que le toca a quien lo haya hecho. En Sorbos siempre vale agua o un reto."
```

¿Quién es más probable?, paso 4 (hoy cita «¡Por 2 fichas!», que en Fichas ya no sale):
```json
"Con Retos o Sorbos, la carta dice lo que se juega, por ejemplo «¡Por 2 retos!». Le toca al más señalado. La app no apunta nada."
```

Copa, entrada nueva:
```json
{
  "id": "copa",
  "titulo": "¿Cómo funciona la Copa de la noche?",
  "pasos": [
    "Solo cuentan la Carrera de caballos y El Infiltrado: lo que se apuesta y lo que se vota.",
    "Cada ronda suma o resta fichas. Manda quien acaba con más.",
    "Los demás juegos no se apuntan: se juegan por el gusto de jugar.",
    "Pasadas 12 horas, la Copa os ofrece empezar otra noche. También podéis tocar «Nueva noche» cuando queráis."
  ],
  "consejo": "Al terminar una carrera o una votación, toca «Ver Copa» para ver quién manda."
}
```

Carrera, final del paso 4: `El modo de Ajustes decide cómo se pagan.` pasa a `El modo elegido decide qué se juega.`

Ninguno de estos textos lleva palabras vetadas por `no_alcohol_text_test.dart` (ni "beb…" ni "alcohol").

## 6. "Pagar" en modo Sorbos

En Fichas y Retos se queda "pagar". En Sorbos se cambia así:

| Dónde | Fichas / Retos | Sorbos |
|---|---|---|
| `race_result_screen.dart:242` (título) | `Pagan` | `Les toca` |
| `race_result_screen.dart:248` (línea) | `Pagan: Ana (−2)` | `Les toca: Ana (2 sorbos · o agua o reto)` |
| `race_result_screen.dart:265` | `Nadie acertó. Pagan todos.` | `Nadie acertó. Les toca a todos · o agua o reto.` |
| `race_screen.dart:895` (botón) | `¿Quién paga?` | `¿A quién le toca?` |
| Fila de un jugador | `Ana paga 2 fichas` | `Le toca a Ana: 2 sorbos · o agua o reto` |
| All-in en Sorbos | `Reparte 2 All-in` | `Reparte 2 All-in · hasta 3 sorbos cada uno · o agua o reto` |
| `infiltrado_setup_screen.dart:142-143` | `…si lo pilláis, paga 2 fichas; si se escapa, los demás pagan 1 cada uno.` | `…si lo pilláis, le tocan 2 sorbos; si se escapa, 1 a cada uno de los demás. Siempre o agua o reto.` |
| `registry.dart` y ayuda | (ver 2 y 3: ya son neutros en todos los modos) | |

`Cobran` se queda en todos los modos: es ganar fichas, no beber.

## Pendiente o a decidir
- La línea `Cuentan` dentro de la Copa choca con la definición de C en `validacion_copa.md`.
- Si iOS se compila sin Sorbos (COMPLIANCE #3), la ayuda de Yo nunca y de ¿Quién es más probable? debería decir solo `Con Retos, …`. Hay que hacer una variante o quitar "o Sorbos".
- Tests que buscan textos literales y habrá que actualizar: `cup_screen_test.dart` (`El que más ha pagado`, `va ganando quien más ha ganado`), `prompt_deck_pay_test.dart`, `race_chips_test.dart` (`Pagan todos`), tests de mazos con `¡Por N fichas!`.

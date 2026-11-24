# Contenido (`assets/content/es/`)

Lo validan `test/content_test.dart` y `test/extra_content_test.dart` (leen el JSON en crudo; `content_test.dart` solo usa `gameModules` de `lib/games/registry.dart` para saber qué mazos hay y con qué estilo).

## Niveles (todos los mazos con `nivel`)

`suave` | `picante` | `atrevido` (antes `hot`; ya no existe).

- **Suave 😇**: apto para cualquier grupo; modo por defecto. Sin ligues, cuernos, ex, citas ni besos.
- **Picante 🌶️**: pícaro (ligues, ex, cuernos, celos), sin nada sexual.
- **Atrevido 🔥**: sugerente, nunca explícito. Desactivado por defecto, con confirmación +18. Sin actos sexuales descritos, genitales, desnudos ni insultos fuertes; se insinúa ("momento íntimo", "acabar en la cama", "subido de tono").
- Picante y Atrevido: nada de contexto escolar ni de menores (profesores, curso, clase, colegio, instituto…).
- Nada de alcohol como objetivo en ningún fichero: ni "borracho", ni resacas, ni tragos, ni nombres de bebidas. Las consecuencias se expresan en fichas ("pierde una ficha", "paga").

## Mazos de cartas: `yo_nunca.json`, `que_preferirias.json`, `quien_es_mas_probable.json`

```json
{ "version": 1, "items": [
  { "id": "yn001", "nivel": "suave", "texto": "he buscado mi propio nombre en Google" },
  { "id": "yn065", "nivel": "picante", "texto": "me han puesto los cuernos", "prefijo": "A mí nunca" },
  { "id": "qp001", "nivel": "suave", "a": "Poder volar", "b": "Ser invisible" },
  { "id": "qmp_001", "nivel": "suave", "texto": "se pierda en su propia ciudad" }
] }
```

- Solo campos de texto (`parsePrompts` no admite otros tipos).
- `id`: `yn` + 3 cifras (Yo nunca), `qp` + 3 cifras (¿Qué preferirías?), `qmp_` + 3 cifras (¿Quién es más probable?). Únicos y estables. Un id borrado no se reutiliza nunca: va a `idsRetirados` en el test. Siguiente libre: `yn427`, `qp121`, `qmp_129`.
- Campos según el estilo del módulo en `registry.dart`: `statement` y `question` → `texto`; `choice` → `a` y `b`.
- `prefijo` (opcional, Yo nunca): sustituye a "Yo nunca" (p. ej. "A mí nunca").
- ¿Quién es más probable?: `texto` sin el prefijo "¿Quién es más probable que", sin "¿?" y sin punto final.

Cifras (suave · picante · atrevido):
- Yo nunca: 100 · 100 · 80 (280).
- ¿Qué preferirías?: 65 · 33 · 22 (120).
- ¿Quién es más probable?: 64 · 40 · 24 (128). Mínimo del test: 120 y 50 en Suave.

## Retos: `retos.json`

`{ "id": "rt_001", "nivel": "suave", "texto": "Imita a alguien del grupo hasta que adivinen quién es" }`

- `id`: `rt_` + 3 cifras. Siguiente libre: `rt_091`.
- Cifras: 58 · 20 · 12 (90). Mínimo del test: 80 y 40 en Suave.
- Además de la lista negra común, sin riesgo físico, sin comer ni beber nada y sin humillar (lista propia en `extra_content_test.dart`).

## El Infiltrado: `infiltrado.json`

`{ "id": "inf_001", "nivel": "suave", "categoria": "Comida", "palabra": "Paella" }`

- `id`: `inf_` + 3 cifras. Siguiente libre: `inf_174`.
- Cifras: 160 · 8 · 5 (173). Suave en 13 categorías (~12 palabras cada una); Picante = "Amor y ligue", Atrevido = "Subido de tono". Mínimo del test: 150 en Suave y 10 categorías.
- Palabras sin repetir; solo campos de texto.

## Trivia: `trivia.json`

`{ "id", "cat", "q", "a", "w": [3 incorrectas], "dif"?: "dificil", "fuente"?, "licencia"? }`

- Las preguntas de Open Trivia DB (traducidas y adaptadas) tienen id `ot-…` y llevan `"fuente": "opentdb"` y `"licencia": "CC BY-SA 4.0"`. El resto son originales y no llevan esos campos. El test exige que coincidan.
- Atribución obligatoria en la app: "Preguntas de Open Trivia DB (opentdb.com), CC BY-SA 4.0, traducidas y adaptadas al español".

## Lista negra

En `test/content_test.dart`:
- Alcohol/borracheras, nombres de bebidas, drogas e insultos: en **todos** los JSON de `assets/content/es/` (trivia, abecedario y geografía incluidos).
- Términos explícitos: mazos de cartas, retos e infiltrado.
- Contexto escolar o de menores: Picante y Atrevido.
- Vocabulario de ligue: solo Suave.

Si aparece algo nuevo que no debería estar, se añade a la lista (no se debilita).

## Ficha de tienda y clasificación por edades

El nivel Atrevido (Yo nunca, ¿Qué preferirías?, ¿Quién es más probable?, Retos, El Infiltrado) contiene **referencias sexuales sugeridas** (sin contenido explícito), desactivadas por defecto y tras confirmación +18. Debe declararse así en el cuestionario IARC de Google Play ("referencias sexuales" / humor sugerente) y en el de Apple ("Temas sexuales o desnudez leves/poco frecuentes"), además de las referencias a alcohol si el modo de consecuencias lo menciona. No declararlo puede suponer la retirada de la ficha.

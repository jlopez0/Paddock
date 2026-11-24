# Cuestionarios de clasificación por edad · Paddock v1.0

Objetivo: **Apple 18+** y **PEGI 16–18** en Google Play (IARC).
Base: `docs/CONTENIDO.md` (sección "Ficha de tienda y clasificación por edades"), `docs/decisions.md` (D2, D4, D5, D11), `docs/privacidad.html` y el código de `lib/`.

> Aviso: el texto exacto de las preguntas y cómo se traduce cada respuesta en una edad lo deciden IARC y Apple, y cambian. Antes de enviar, compara cada pregunta con el formulario real. Lo marcado con ❓ hay que confirmarlo en pantalla. No es asesoría legal.

## Hechos que se declaran

| Hecho | Dónde está | Declaración |
|---|---|---|
| Referencias sexuales **sugeridas**, nunca explícitas | Nivel Atrevido de Yo nunca, ¿Qué preferirías?, ¿Quién es más probable?, Retos y El Infiltrado ("Subido de tono") | Sí, leves y poco frecuentes. Desactivado por defecto y tras confirmar +18 |
| Temas pícaros (ligues, ex, cuernos, celos) | Nivel Picante (activo por defecto en los mazos de cartas, junto a Suave) | Temas maduros o sugerentes, leves |
| Mención de alcohol (sorbos) | Solo el modo opcional **Sorbos**: diálogo +18, banner de consecuencias y bienvenida ("Nadie está obligado a beber") | Referencias a alcohol, poco frecuentes. Nunca se anima a beber: tope 3 por ronda, alternativa "agua o reto" visible, sin nombres de bebidas en el contenido |
| Apuestas con fichas sin valor | Carrera de caballos (1–5 fichas, All-in = 10) | Juego de azar **simulado**, sin dinero real ni compras |
| Lenguaje | Lista negra de insultos en todo el contenido (`test/content_test.dart`) | Sin palabrotas |
| Violencia, terror, drogas, tabaco | No hay | No |
| Contenido de usuarios, chat, web abierta | No hay. Solo se escriben nombres de jugadores, que no salen del móvil | No |
| Compras, anuncios, datos | No hay compras, anuncios ni recogida de datos | No |

---

## Google Play · Cuestionario IARC

**Categoría:** Juego.

| Bloque | Respuesta sugerida | Justificación |
|---|---|---|
| Violencia | No | Ningún juego la muestra |
| Miedo / terror | No | — |
| Sexualidad | **Sí: referencias o insinuaciones sexuales (sin desnudos ni actos explícitos)** | Nivel Atrevido. Lo exige `docs/CONTENIDO.md`; no declararlo puede suponer la retirada |
| Lenguaje | No a palabrotas. ❓ Humor sugerente/grosero: **Sí** si el formulario lo pregunta aparte | Picante y Atrevido son pícaros, sin insultos |
| Sustancias controladas | **Sí: alcohol (referencia y uso representado).** No: drogas, tabaco | Modo Sorbos opcional: el banner dice "N sorbos · o agua o reto". Es texto, sin imágenes ni nombres de bebidas. Aunque esté desactivado de serie, la app contiene la mecánica; marcar "No" sería una declaración incorrecta y Google puede retirar la app |
| ¿Fomenta o instruye a consumir alcohol? | **Sí, si el formulario lo pregunta así** (recomendado). Matiz: opcional, +18, tope 3 por ronda, "agua o reto" siempre visible | El modo indica cuántos sorbos tomar: es una mecánica de beber, no una simple mención. Responder Sí sube la edad (PEGI 18), que ya es el objetivo (público 18+); responder No arriesga una declaración incorrecta |
| Juegos de azar | **Sí: azar simulado.** No: dinero real, premios ni compras | Carrera: se apuestan fichas sin valor |
| Interacción entre usuarios, chat | No | Todo en un móvil, sin red |
| Comparte ubicación | No | — |
| Compras digitales | No | — |
| Contenido generado por usuarios | No | Los nombres de jugadores son locales y no se publican |
| Navegador web sin restricciones | No | Solo abre enlaces fijos (privacidad, soporte y licencia CC BY-SA de Créditos) en el navegador del sistema |

**Resultado esperado:** PEGI 18 probable (alcohol con instrucción de beber + azar simulado + insinuaciones sexuales); PEGI 16 como mínimo. Ambos encajan con el objetivo. ❓ Si sale menos de 16, revisar las respuestas de sexualidad y alcohol: no hay que inflar nada, pero tampoco quedarse corto.

### Otras secciones de Play Console

- **Público objetivo y contenido:** solo "18 años o más". ¿Atrae a menores? No.
- **Seguridad de los datos:** no se recogen ni se comparten datos. Los datos se quedan en el dispositivo. No hay cifrado en tránsito porque no hay envío.
- **Anuncios:** no contiene anuncios.
- **Acceso a la app:** todas las funciones están disponibles sin restricciones (no hay cuenta).
- **Política de privacidad:** `https://jlopez0.github.io/Paddock/privacidad.html` (antes, poner el correo y activar Pages).

---

## App Store · Clasificación por edad (App Store Connect)

Escala de Apple: 4+, 9+, 13+, 16+, 18+. Opciones por tema: Ninguno / Poco frecuente / Frecuente.

| Pregunta | Respuesta sugerida | Justificación |
|---|---|---|
| Violencia de dibujos o fantasía | Ninguno | — |
| Violencia realista | Ninguno | — |
| Violencia realista prolongada | Ninguno | — |
| Sangre / Terror | Ninguno | — |
| Tratamientos médicos | Ninguno | — |
| Palabrotas o humor grosero | Poco frecuente | Humor pícaro de Picante y Atrevido, sin insultos |
| Temas maduros o sugerentes | **Poco frecuente** | Picante (ligues, cuernos) y Atrevido |
| Contenido sexual o desnudez | **Poco frecuente** (no "explícito") | Referencias sexuales sugeridas tras +18. Equivale a "temas sexuales o desnudez leves/poco frecuentes" de `docs/CONTENIDO.md` |
| Contenido sexual explícito y desnudez | Ninguno | El contenido nunca es explícito |
| Alcohol, tabaco o drogas (consumo o referencias) | **Poco frecuente** | Modo Sorbos, opcional y +18 |
| Juego de azar simulado | **Poco frecuente** ❓ (o Frecuente si la Carrera se considera el núcleo) | Apuestas de fichas en la Carrera |
| Concursos | Ninguno | No hay premios |
| Apuestas con dinero real | No | — |
| Acceso web sin restricciones | No | Solo enlaces fijos a privacidad y soporte |
| Contenido generado por usuarios | No | — |
| Mensajes y chat | No | — |
| Publicidad | No | — |
| Controles parentales / verificación de edad en la app | No ❓ | Solo hay una confirmación +18 declarativa, no verificación |

**Resultado esperado:** 16+ o 18+. ❓ Si las respuestas dan menos de 18+, usar la opción de App Store Connect para subir la clasificación (comprobar que existe en el formulario actual). El objetivo es 18+ porque la app se dirige a mayores de edad (`docs/privacidad.html`) y lo anuncia en la bienvenida.

### Otras secciones de App Store Connect

- **Privacidad de la app:** "No se recopilan datos".
- **Cifrado:** `ITSAppUsesNonExemptEncryption = false` (ya en `Info.plist`).
- **Notas para el revisor:** `docs/store/notas_revisor_apple_en.md`.

---

## Coherencia con la ficha y las capturas

- Capturas sin nivel Atrevido ni modo Sorbos (Fase 6).
- La ficha (`docs/store/ficha_es.md`) no nombra el alcohol como objetivo y menciona que el modo para adultos es opcional y está desactivado de serie, igual que estas respuestas.
- Si se añade contenido o un modo nuevo (p. ej. Patata caliente en v1.1), volver a revisar este archivo antes de publicar.
